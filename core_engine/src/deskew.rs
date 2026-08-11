//! Pulling a sheet photographed at an angle back into a rectangle.
//!
//! A photo taken over a document is a trapezoid: the near edge is wider than the
//! far one. Straightening that looks like tilting the sheet in space, but no depth
//! information is needed, and that is the whole reason it works from a single
//! photo. A flat surface seen by two different cameras is always related by one
//! 3x3 matrix with eight free numbers, and four corner pairs pin those eight
//! numbers down exactly.

use crate::paper::Point;
use image::{DynamicImage, Rgb, RgbImage};

/// Straightens a sheet, given where its four corners are.
///
/// The corners go clockwise from the top left, which is the order
/// [`crate::Paper::corners`] returns. They are taken as given rather than looked
/// for, so a client can show them as four handles and let the user drag them
/// before anything is resampled.
///
/// The output is a rectangle sized from the sheet itself: the two opposite edges
/// of the quadrilateral are averaged, so a receipt stays a receipt instead of
/// being forced into A4.
///
/// Every output pixel is worked out backwards - where did this come from in the
/// photo - and read with bilinear sampling. Going forwards would leave holes
/// wherever the stretch pulls pixels apart.
///
/// - Parameters:
///   img: The photo.
///   corners: The four corners of the sheet, clockwise from the top left.
/// - Returns:
///   The straightened rectangle, or a message if the four corners do not
///   describe a sheet.
pub fn deskew(img: &DynamicImage, corners: [Point; 4]) -> Result<DynamicImage, String> {
    let (width, height) = output_size(&corners);
    if width < 2 || height < 2 {
        return Err(format!(
            "The four corners {corners:?} are too close together to be a sheet."
        ));
    }

    let map = SquareToQuad::new(&corners).ok_or_else(|| {
        format!("The four corners {corners:?} do not describe a sheet: three of them are in line.")
    })?;

    let source = img.to_rgb8();
    let mut out = RgbImage::new(width, height);
    for (x, y, pixel) in out.enumerate_pixels_mut() {
        // The middle of the output pixel, as a share of the way across the sheet.
        let across = (x as f32 + 0.5) / width as f32;
        let down = (y as f32 + 0.5) / height as f32;
        let (from_x, from_y) = map.apply(across, down);
        *pixel = sample(&source, from_x, from_y);
    }

    Ok(DynamicImage::ImageRgb8(out))
}

/// How big the straightened sheet should be, in pixels.
///
/// Each side of the output is the average of the two opposite edges of the
/// quadrilateral. The far edge of a tilted sheet is shorter than the near one, and
/// the average keeps the result close to the real proportions of the paper without
/// having to know how far away the camera was.
fn output_size(corners: &[Point; 4]) -> (u32, u32) {
    let [top_left, top_right, bottom_right, bottom_left] = corners;
    let width = (distance(top_left, top_right) + distance(bottom_left, bottom_right)) / 2.0;
    let height = (distance(top_left, bottom_left) + distance(top_right, bottom_right)) / 2.0;

    (
        width.round().max(0.0) as u32,
        height.round().max(0.0) as u32,
    )
}

fn distance(from: &Point, to: &Point) -> f32 {
    ((to.x - from.x).powi(2) + (to.y - from.y).powi(2)).sqrt()
}

/// The map from a point on the finished sheet, given as a share of the way across
/// and down, to the point in the photo it came from.
///
/// This is a homography, and the reason it can do what turning and scaling cannot:
/// an affine map keeps parallel lines parallel, so it can never make the far edge
/// of a sheet as wide as the near one. The two extra numbers `across_weight` and
/// `down_weight` are what let lines converge - they divide the result, so a point
/// further into the picture is pulled in more.
///
/// The numbers come from a closed form for the unit square, which avoids solving
/// an eight by eight system. It is written for exactly the direction needed here:
/// output to photo, which is the direction backwards sampling asks for.
struct SquareToQuad {
    across: (f32, f32),
    down: (f32, f32),
    origin: (f32, f32),
    across_weight: f32,
    down_weight: f32,
}

impl SquareToQuad {
    /// Builds the map, or nothing if the four corners are degenerate - three
    /// points in a line have no perspective to undo.
    fn new(corners: &[Point; 4]) -> Option<SquareToQuad> {
        let [c0, c1, c2, c3] = corners;

        // The two directions the far corner is pulled in, and how much the quad
        // fails to be a parallelogram. When it does not fail at all there is no
        // perspective and the weights are zero.
        let (dx1, dy1) = (c1.x - c2.x, c1.y - c2.y);
        let (dx2, dy2) = (c3.x - c2.x, c3.y - c2.y);
        let (dx3, dy3) = (c0.x - c1.x + c2.x - c3.x, c0.y - c1.y + c2.y - c3.y);

        let (across_weight, down_weight) = if dx3 == 0.0 && dy3 == 0.0 {
            (0.0, 0.0)
        } else {
            let shear = dx1 * dy2 - dx2 * dy1;
            if shear.abs() < f32::EPSILON {
                return None;
            }
            (
                (dx3 * dy2 - dx2 * dy3) / shear,
                (dx1 * dy3 - dx3 * dy1) / shear,
            )
        };

        Some(SquareToQuad {
            across: (
                c1.x - c0.x + across_weight * c1.x,
                c1.y - c0.y + across_weight * c1.y,
            ),
            down: (
                c3.x - c0.x + down_weight * c3.x,
                c3.y - c0.y + down_weight * c3.y,
            ),
            origin: (c0.x, c0.y),
            across_weight,
            down_weight,
        })
    }

    fn apply(&self, across: f32, down: f32) -> (f32, f32) {
        let weight = self.across_weight * across + self.down_weight * down + 1.0;

        (
            (self.across.0 * across + self.down.0 * down + self.origin.0) / weight,
            (self.across.1 * across + self.down.1 * down + self.origin.1) / weight,
        )
    }
}

/// Reads a colour from between four pixels, mixed by how close it is to each.
///
/// Taking the nearest pixel instead would turn every straight line in the
/// document into a staircase, because the straightening moves pixels by fractions.
fn sample(img: &RgbImage, x: f32, y: f32) -> Rgb<u8> {
    let last_x = (img.width() - 1) as f32;
    let last_y = (img.height() - 1) as f32;
    let x = x.clamp(0.0, last_x);
    let y = y.clamp(0.0, last_y);

    let (left, top) = (x.floor(), y.floor());
    let (right, bottom) = ((left + 1.0).min(last_x), (top + 1.0).min(last_y));
    let (share_right, share_bottom) = (x - left, y - top);

    let corner = |cx: f32, cy: f32| *img.get_pixel(cx as u32, cy as u32);
    let (top_left, top_right) = (corner(left, top), corner(right, top));
    let (bottom_left, bottom_right) = (corner(left, bottom), corner(right, bottom));

    let mut mixed = [0u8; 3];
    for (channel, out) in mixed.iter_mut().enumerate() {
        let above = f32::from(top_left[channel])
            + (f32::from(top_right[channel]) - f32::from(top_left[channel])) * share_right;
        let below = f32::from(bottom_left[channel])
            + (f32::from(bottom_right[channel]) - f32::from(bottom_left[channel])) * share_right;
        *out = (above + (below - above) * share_bottom)
            .round()
            .clamp(0.0, 255.0) as u8;
    }

    Rgb(mixed)
}

/// Turning by more than this is not a crooked photo any more, it is a page held
/// sideways - which is what [`crate::rotate`] is for.
const MOST_TILT: f32 = 10.0;

/// How striped the picture has to be before it is believed to have lines of writing
/// at all, in average grey levels of bend per line.
///
/// An absolute figure rather than a comparison with reading straight along the rows:
/// a page one degree crooked scores nearly the same at zero as at one, so comparing
/// the two would throw a correct answer away. Nor a comparison with the middling
/// angles, because on a picture with no lines at all that is one piece of noise
/// divided by another and can come out as anything.
///
/// Measured, which is what makes four a safe place to stand: a photographed invoice
/// scores 91, a handwritten letter 16, while a smooth brightness ramp scores 0.6 and
/// a blank sheet lit unevenly 0.007. Between the loudest noise and the quietest real
/// writing there is a factor of twenty five.
const CLEAR_LINES: f64 = 4.0;

/// Measures how crooked the writing is, and by how much to turn the picture to fix
/// it. Clockwise is positive, the same direction [`crate::rotate`] turns.
///
/// This asks the writing rather than the paper, which is the point of it: it needs
/// neither the corners of the sheet nor a background darker than the paper. So it
/// still works on the two photos where finding the sheet does not - a document on a
/// white desk, and one that runs off the edge of the frame.
///
/// Lines of writing are found by projecting the whole picture onto a slanted axis:
/// at the angle the lines really run at, all the letters of one line fall into the
/// same bin, so the profile comes out sharply striped. At any other angle they
/// smear across bins. The angle with the sharpest stripes is how crooked the page
/// is.
///
/// Returns zero when the picture has no clear lines to go by - a blank sheet, a
/// photograph of something else - rather than turning it on the strength of noise.
///
/// ponytail: this only measures turning, not perspective. A page photographed at an
/// angle needs [`deskew`], and this cannot replace it - it can only make the more
/// obvious half of the problem go away when the corners are not to be had.
pub fn suggest_straightening(img: &DynamicImage) -> f32 {
    let small = crate::paper::shrink_to_gray(img);
    if small.width() < 8 || small.height() < 8 {
        return 0.0;
    }

    // A rough pass first, keeping every score: how far the sharpest angle stands out
    // from the middling ones is what says whether there is writing to go by at all.
    let mut sharpness: Vec<(f32, f64)> = Vec::new();
    let mut tilt = -MOST_TILT;
    while tilt <= MOST_TILT {
        sharpness.push((tilt, line_sharpness(&small, tilt)));
        tilt += 1.0;
    }

    let peak = (0..sharpness.len())
        .filter(|&at| sharpness[at].0.abs() <= MOST_TILT)
        .max_by(|&one, &other| sharpness[one].1.total_cmp(&sharpness[other].1))
        .unwrap_or(0);

    if sharpness[peak].1 < CLEAR_LINES {
        return 0.0;
    }

    let (tilt, _) = sharpest_tilt(
        &small,
        sharpness[peak].0 - 1.0,
        sharpness[peak].0 + 1.0,
        0.1,
    );

    // The writing runs downhill to the right, so the picture has to go the other
    // way to put it straight.
    -tilt
}

/// Turns the picture by a free angle, to put crooked writing straight.
///
/// The result is cut in slightly rather than left with empty corners: the picture
/// is read from the largest turned rectangle that still fits inside it. Straighten
/// is meant to be invisible, and a white triangle in every corner is not.
///
/// - Parameters:
///   img: The picture.
///   degrees: How far to turn clockwise. At most ten degrees either way.
/// - Returns:
///   The turned picture, or a message if the angle is outside that range.
pub fn straighten(img: &DynamicImage, degrees: f32) -> Result<DynamicImage, String> {
    if degrees == 0.0 {
        return Ok(img.clone());
    }
    if !degrees.is_finite() || degrees.abs() > MOST_TILT {
        return Err(format!(
            "Straightening turns by at most {MOST_TILT} degrees either way, but was given {degrees}. \
             A quarter turn is what rotate is for."
        ));
    }

    let (width, height) = (img.width() as f32, img.height() as f32);
    let (sin, cos) = (-degrees).to_radians().sin_cos();

    // How far the turned rectangle has to shrink to stay inside the picture.
    let fits = (width / (width * cos.abs() + height * sin.abs()))
        .min(height / (height * cos.abs() + width * sin.abs()));

    let (half_width, half_height) = (width / 2.0, height / 2.0);
    let corner = |across: f32, down: f32| Point {
        x: half_width + (across * cos - down * sin) * fits,
        y: half_height + (across * sin + down * cos) * fits,
    };

    deskew(
        img,
        [
            corner(-half_width, -half_height),
            corner(half_width, -half_height),
            corner(half_width, half_height),
            corner(-half_width, half_height),
        ],
    )
}

/// Tries every angle in a range and keeps the one where the lines of writing come
/// out sharpest.
fn sharpest_tilt(gray: &image::GrayImage, from: f32, to: f32, step: f32) -> (f32, f64) {
    let mut best = (0.0, 0.0);
    let mut tilt = from;

    while tilt <= to + step / 2.0 {
        let sharpness = line_sharpness(gray, tilt);
        if sharpness > best.1 {
            best = (tilt, sharpness);
        }
        tilt += step;
    }

    best
}

/// How sharply the picture is striped when read along lines at this angle.
///
/// Every pixel is dropped into the bin for the line it would sit on, adding up how
/// dark it is. Neighbouring bins that differ a lot mean the bins have caught the
/// lines: one full of letters, the next empty paper between them.
fn line_sharpness(gray: &image::GrayImage, tilt: f32) -> f64 {
    let (sin, cos) = tilt.to_radians().sin_cos();
    let (width, height) = (gray.width() as f32, gray.height() as f32);

    // A line is the set of points where y*cos - x*sin stays the same. Shifted so
    // the leftmost line still lands on bin zero.
    let shift = if sin > 0.0 { width * sin } else { 0.0 };
    let bins = (height * cos + width * sin.abs()).ceil() as usize + 1;
    let mut darkness = vec![0f64; bins];
    let mut pixels = vec![0u32; bins];

    for (x, y, pixel) in gray.enumerate_pixels() {
        let bin = ((y as f32 * cos - x as f32 * sin + shift) as usize).min(bins - 1);
        darkness[bin] += f64::from(255 - pixel[0]);
        pixels[bin] += 1;
    }

    // Only bins whose line crosses the whole picture are compared. Those at either
    // end catch a corner and hold less and less, and the last one can be empty
    // altogether - a drop to zero that outweighs any real writing and that only a
    // reading straight along the rows would be scored for.
    let complete = (pixels.iter().copied().max().unwrap_or(0) * 9 / 10).max(1);
    // How dark a bin is on average, not in total. A slanted reading catches a pixel
    // more in one bin than the next simply from where the rounding falls, and on a
    // picture that gets steadily brighter across the page that alone looks like fine
    // striping - one that grows the more the reading is slanted.
    let average = |bin: usize| darkness[bin] / f64::from(pixels[bin].max(1));

    let mut stripes = 0.0;
    let mut compared = 0u32;
    for bin in 1..bins - 1 {
        if pixels[bin - 1] >= complete && pixels[bin] >= complete && pixels[bin + 1] >= complete {
            // How much the profile bends, not how much it rises. A sheet lit unevenly
            // rises steadily from one side to the other, which counts as striping if
            // plain differences are added up and counts as nothing here, because a
            // steady rise does not bend. Lines of writing bend sharply.
            stripes += (average(bin + 1) - 2.0 * average(bin) + average(bin - 1)).powi(2);
            compared += 1;
        }
    }

    if compared < 3 {
        return 0.0;
    }
    stripes / f64::from(compared)
}
