//! Finding the sheet of paper inside a photograph.
//!
//! Everything else in the engine works on brightness alone. That is enough for a
//! scan, where the whole image is paper, but not for a photo: on a table the
//! darkest thing in the frame can be the table rather than the writing, and a
//! brightness stretch measured over the whole image then comes out wrong. Telling
//! the two apart needs to know *where* the paper is, which is what this does.

use image::DynamicImage;

/// A box inside an image, in pixels from the top left corner.
///
/// The same four numbers [`crate::crop`] takes, so a found sheet can be handed
/// straight to it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Rect {
    pub x: u32,
    pub y: u32,
    pub width: u32,
    pub height: u32,
}

/// A point in an image, in pixels from the top left corner.
///
/// Fractional, because a corner found on a shrunk copy lands between full sized
/// pixels, and because a client handing back a dragged handle has no reason to
/// round it.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Point {
    pub x: f32,
    pub y: f32,
}

/// The sheet of paper found in a photograph.
///
/// Two answers in one, because they are needed for different things. [`Self::bounds`]
/// is the box to cut to. [`Self::contains`] answers, for a single pixel, whether it
/// is on the paper - which the box cannot do: a sheet photographed at even a
/// slight angle has background in the corners of its box, and a handful of dark
/// table pixels in there is enough to ruin a measurement.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Paper {
    /// The smallest box that holds the whole sheet.
    pub bounds: Rect,
    /// Which pixels are paper, on the shrunk copy the search ran on.
    on_paper: Vec<bool>,
    width: u32,
    height: u32,
    image_width: u32,
    image_height: u32,
}

impl Paper {
    /// Whether the pixel at these coordinates of the full sized image is on the
    /// sheet.
    ///
    /// The search runs on a shrunk copy, so this answers to within a few pixels
    /// along the edge of the sheet. That is fine for measuring and would not be
    /// for cutting, which is what [`Self::bounds`] is for.
    pub fn contains(&self, x: u32, y: u32) -> bool {
        let column = (x * self.width / self.image_width.max(1)).min(self.width - 1);
        let row = (y * self.height / self.image_height.max(1)).min(self.height - 1);

        self.on_paper[(row * self.width + column) as usize]
    }

    /// The four corners of the sheet, clockwise from the top left.
    ///
    /// This is what [`crate::deskew`] needs: a photo taken at an angle has a sheet
    /// whose corners are not the corners of any box, and pulling those four points
    /// into a rectangle is what undoes the perspective.
    ///
    /// Found as the outermost pixel of the sheet along each diagonal, which for any
    /// convex shape is a corner. A sheet turned by roughly 45 degrees still gets
    /// its four corners in the right order round the shape, so straightening still
    /// works - the result simply comes out turned by the same 45 degrees, since
    /// nothing here knows which way up the writing is.
    pub fn corners(&self) -> [Point; 4] {
        let mut top_left = (i32::MAX, 0u32, 0u32);
        let mut top_right = (i32::MIN, 0u32, 0u32);
        let mut bottom_right = (i32::MIN, 0u32, 0u32);
        let mut bottom_left = (i32::MAX, 0u32, 0u32);

        for (index, on_paper) in self.on_paper.iter().enumerate() {
            if !on_paper {
                continue;
            }
            let (x, y) = (index as u32 % self.width, index as u32 / self.width);
            let (sum, difference) = (x as i32 + y as i32, x as i32 - y as i32);

            if sum < top_left.0 {
                top_left = (sum, x, y);
            }
            if sum > bottom_right.0 {
                bottom_right = (sum, x, y);
            }
            if difference > top_right.0 {
                top_right = (difference, x, y);
            }
            if difference < bottom_left.0 {
                bottom_left = (difference, x, y);
            }
        }

        [top_left, top_right, bottom_right, bottom_left].map(|(_, x, y)| self.to_full_size(x, y))
    }

    /// A pixel of the shrunk copy, as a point in the full sized image: its middle,
    /// so the error is spread evenly instead of always falling outwards onto the
    /// table.
    fn to_full_size(&self, x: u32, y: u32) -> Point {
        Point {
            x: (x as f32 + 0.5) * self.image_width as f32 / self.width as f32,
            y: (y as f32 + 0.5) * self.image_height as f32 / self.height as f32,
        }
    }

    /// Whether the sheet runs off the edge of the photo.
    ///
    /// Worth asking before straightening, because [`Self::corners`] then returns
    /// the points where the paper leaves the frame instead of the corners of the
    /// sheet. Pulling those into a rectangle bends the picture rather than
    /// straightening it, and drags whatever lies along the edge inwards.
    pub fn runs_off_the_picture(&self) -> bool {
        let on_paper = |x: u32, y: u32| self.on_paper[(y * self.width + x) as usize];

        (0..self.width).any(|x| on_paper(x, 0) || on_paper(x, self.height - 1))
            || (0..self.height).any(|y| on_paper(0, y) || on_paper(self.width - 1, y))
    }

    /// Whether the sheet fills the picture, so there is nothing to cut away. True
    /// for a scan, and for a photo the user already cropped.
    pub fn is_the_whole_image(&self) -> bool {
        self.bounds
            == Rect {
                x: 0,
                y: 0,
                width: self.image_width,
                height: self.image_height,
            }
    }
}

/// The size the search runs at. Small on purpose: it is fast, and shrinking the
/// image averages single letters away, so a page of text reads as one bright
/// surface instead of hundreds of dark specks.
const WORK_WIDTH: u32 = 400;

/// A sheet smaller than this share of the picture is not believed. Someone
/// photographing a document fills the frame with it; a small bright patch is
/// more likely a lamp or a reflection.
const SMALLEST_SHARE: f32 = 0.15;

/// A sheet thinner than this share of a side is not believed either, which rules
/// out a bright strip along one edge.
const THINNEST_SIDE: f32 = 0.25;

/// How far the mask is pulled in, and pushed back out again, before the sheet is
/// picked out of it. In pixels of the [`WORK_WIDTH`] wide copy, so 3 px is 0.75%
/// of the width of the picture.
///
/// Measured on seven photos of a letter on a metal table. On one of them the sheen
/// down the right of the frame hangs on the sheet by 2 px: at 2 it comes off and the
/// bottom right corner moves from the corner of the frame back onto the paper, at 1
/// it stays. So this is one pixel of margin over what was needed. The other way
/// round, the corners of the tilted sheet in `the_corners_of_the_sheet_are_found`
/// move 1.6 px at 2, 2.5 px at 3 and 4.5 px at 8, of the 6 px that test allows - and
/// that picture is 200 px wide, so it is not shrunk at all and the same radius costs
/// a full sized photo half as much. On five of the seven the box moves by at most one
/// pixel of this copy, 7 px of a 4032 px high photo. On the other two a piece of
/// reflection leaves the box with the mask: one loses 310 px of height, the other
/// 279 px of width and 378 px of height. Neither is the sheet giving anything up -
/// the sides of the sheet come back where they were, which is what the opening is
/// built to do.
const OPENING_RADIUS: u32 = 3;

/// Finds the sheet of paper in a photograph.
///
/// It works from two ideas. The paper is brighter than what it lies on, and the
/// background reaches the edge of the picture while the paper does not have to.
/// So the dark pixels that can be reached from the border are the background, and
/// the largest area that is not background is the sheet.
///
/// Going by "not background" rather than "bright" is what puts the writing back on
/// the paper: letters are dark, but they are surrounded by paper and never touch
/// the border, so they end up inside the sheet where they belong. Without that a
/// measurement inside the sheet would never see any ink.
///
/// Bright is not the same as paper, though - a lit table is bright as well - so
/// what is not background is opened before the largest area is taken from it
/// ([`without_thin_bridges`]). That cuts the thin bridge a reflection hangs onto the
/// sheet by, which leaves the reflection as an area of its own for the largest one
/// to beat, and leaves the sides of the sheet where they were.
///
/// The result is a **suggestion**, like [`crate::suggest_levels`]: the client is
/// meant to show the box as a rectangle the user can drag before anything is cut.
///
/// Returns `None` when nothing sheet-like is there: a bright area too small or too
/// thin to be a document. It does not judge whether what it found is really paper
/// - on a picture of something else it returns the largest bright thing in it.
///
/// ponytail: brightness only, and the opening is a thin fix on top of it. A document
/// on a white desk breaks it outright, because paper and desk are then the same
/// brightness. A table lit brightly right beside the sheet breaks it whenever the
/// sheen touches the paper over more than twice [`OPENING_RADIUS`], because then the
/// two are not joined by a bridge the opening can cut but by a broad front. Measured on
/// seven photos of a letter on a metal table: one had no sheen in the mask at all,
/// one hangs it on a 2 px bridge and the opening takes it off, and the remaining five
/// need a radius of 20, 21, 22, 24 and more than 24 before the sheet comes off the
/// frame - a twentieth of the width of the picture, where the tilted sheet loses its
/// corners altogether. So those five keep a bottom right corner that is the corner of
/// the frame, and no radius that leaves a real corner alive will change that. Nothing
/// is straightened wrongly there, because
/// [`Paper::runs_off_the_picture`] sees it and the client then skips the deskew, so
/// the cost is a page that stays uncut rather than a page bent out of shape.
/// Following the edges of the sheet instead would fix all of it, and would also give
/// the four corners a deskew needs - that, not a bigger radius, is the way up.
pub fn find_paper(img: &DynamicImage) -> Option<Paper> {
    let (image_width, image_height) = (img.width(), img.height());
    if image_width == 0 || image_height == 0 {
        return None;
    }

    let small = shrink_to_gray(img);
    let (width, height) = (small.width(), small.height());

    let threshold = otsu_threshold(&brightness_histogram(&small));
    let bright: Vec<bool> = small.pixels().map(|pixel| pixel[0] > threshold).collect();
    let background = dark_area_reaching_the_border(&bright, width, height);
    let candidate: Vec<bool> = background.iter().map(|outside| !outside).collect();
    let candidate = without_thin_bridges(&candidate, width, height);

    let (area, bounds, on_paper) = largest_blob(&candidate, width, height)?;

    let believable = area as f32 >= (width * height) as f32 * SMALLEST_SHARE
        && bounds.width as f32 >= width as f32 * THINNEST_SIDE
        && bounds.height as f32 >= height as f32 * THINNEST_SIDE;
    if !believable {
        return None;
    }

    Some(Paper {
        bounds: scale_up(bounds, width, height, image_width, image_height),
        on_paper,
        width,
        height,
        image_width,
        image_height,
    })
}

/// Shrinks the image to [`WORK_WIDTH`] and drops the colour, since only
/// brightness is looked at. A picture already that small is used as it is.
pub(crate) fn shrink_to_gray(img: &DynamicImage) -> image::GrayImage {
    let gray = img.to_luma8();
    if gray.width() <= WORK_WIDTH {
        return gray;
    }

    let height = (gray.height() * WORK_WIDTH / gray.width()).max(1);
    image::imageops::resize(
        &gray,
        WORK_WIDTH,
        height,
        image::imageops::FilterType::Triangle,
    )
}

fn brightness_histogram(gray: &image::GrayImage) -> [u32; 256] {
    let mut counts = [0u32; 256];
    for pixel in gray.pixels() {
        counts[pixel[0] as usize] += 1;
    }
    counts
}

/// Otsu's method: the brightness that splits the picture into a dark and a bright
/// group that are as far apart as possible.
///
/// This is what keeps the split out of a hard-coded number. A document on dark
/// wood and one on a grey desk need different cuts, and the picture itself says
/// where it lies.
fn otsu_threshold(counts: &[u32; 256]) -> u8 {
    let total: u64 = counts.iter().map(|&count| u64::from(count)).sum();
    let all_brightness: u64 = counts
        .iter()
        .enumerate()
        .map(|(value, &count)| value as u64 * u64::from(count))
        .sum();
    if total == 0 {
        return 128;
    }

    let (mut best_split, mut best_distance) = (128u8, 0.0f64);
    let (mut dark_count, mut dark_brightness) = (0u64, 0u64);

    for (value, &count) in counts.iter().enumerate() {
        dark_count += u64::from(count);
        dark_brightness += value as u64 * u64::from(count);
        let bright_count = total - dark_count;
        if dark_count == 0 || bright_count == 0 {
            continue;
        }

        let dark_mean = dark_brightness as f64 / dark_count as f64;
        let bright_mean = (all_brightness - dark_brightness) as f64 / bright_count as f64;
        // The two groups weighed by size, so a handful of outliers cannot pull
        // the split towards themselves.
        let distance = dark_count as f64 * bright_count as f64 * (dark_mean - bright_mean).powi(2);

        if distance > best_distance {
            best_distance = distance;
            best_split = value as u8;
        }
    }

    best_split
}

/// The background: every dark pixel that can be walked to from the edge of the
/// picture without crossing anything bright.
///
/// Starting from the border is the whole trick. It separates the table, which
/// runs off the edge of the frame, from the writing, which is dark as well but
/// enclosed by paper.
fn dark_area_reaching_the_border(bright: &[bool], width: u32, height: u32) -> Vec<bool> {
    let mut outside = vec![false; bright.len()];
    let mut to_visit: Vec<usize> = Vec::new();

    let border = (0..width)
        .map(|x| x as usize)
        .chain((0..width).map(|x| ((height - 1) * width + x) as usize))
        .chain((0..height).map(|y| (y * width) as usize))
        .chain((0..height).map(|y| (y * width + width - 1) as usize));
    for seed in border {
        if !bright[seed] && !outside[seed] {
            outside[seed] = true;
            to_visit.push(seed);
        }
    }

    while let Some(index) = to_visit.pop() {
        visit_neighbours(index, width, height, |neighbour| {
            if !bright[neighbour] && !outside[neighbour] {
                outside[neighbour] = true;
                to_visit.push(neighbour);
            }
        });
    }

    outside
}

/// The mask with everything narrower than [`OPENING_RADIUS`] taken out of it.
///
/// A morphological opening: pull every edge in by the radius, then push it back
/// out again. An edge wider than the radius comes back exactly where it was, so the
/// sheet keeps its own sides; what was narrower than the radius is gone after the
/// first pass and has nothing left to grow back from. Only a corner pays, because
/// the square cannot reach into a wedge: the corners of the tilted sheet in
/// `the_corners_of_the_sheet_are_found` come back 2.5 px short of where they were,
/// at an [`OPENING_RADIUS`] of 3, which is why that number has to stay small.
///
/// That is what stops a reflection on the table from being counted as paper. A
/// sheen next to the sheet is bright, so it is not background, and where it
/// touches the sheet the two are one shape - and the corner of that shape is not
/// a corner of the paper.
fn without_thin_bridges(mask: &[bool], width: u32, height: u32) -> Vec<bool> {
    let mut pulled_in = vec![false; mask.len()];
    let mut pushed_out = vec![false; mask.len()];

    square_pass(mask, &mut pulled_in, width, height, false);
    square_pass(&pulled_in, &mut pushed_out, width, height, true);

    pushed_out
}

/// One pass over every pixel, looking at the square of [`OPENING_RADIUS`] around
/// it: `grow` set means a pixel comes out set when any pixel of the square is,
/// unset means only when all of them are.
///
/// Off the edge of the picture counts as nothing at all: the square is cut to the
/// picture and only the pixels that exist are looked at. It has to stay that way.
/// Counting the missing pixels as unset instead pulls the mask in from the frame as
/// though the frame were table, and that cuts a page apart. On a picture that is all
/// paper the lines of writing reach the border, so the background walks in along them
/// and leaves the rows of the page joined only by the paper between a line's end and
/// the frame - which is exactly the strip this rule would take away. The picture
/// `../ffi/bridge_check.sh` draws, turned six degrees, then falls from one area of
/// 99078 pixels to seventeen of 5600, each one too thin for [`THINNEST_SIDE`], and the
/// sheet comes back as `None`. It buys nothing either: on the seven photos of a letter
/// on a metal table, pulling in from the frame as well changed no corner and no box.
fn square_pass(from: &[bool], into: &mut [bool], width: u32, height: u32, grow: bool) {
    let radius = OPENING_RADIUS;

    for y in 0..height {
        for x in 0..width {
            let across = x.saturating_sub(radius)..=(x + radius).min(width - 1);
            let down = y.saturating_sub(radius)..=(y + radius).min(height - 1);
            let mut square = down.flat_map(|row| {
                across
                    .clone()
                    .map(move |column| (row * width + column) as usize)
            });

            into[(y * width + x) as usize] = if grow {
                square.any(|neighbour| from[neighbour])
            } else {
                square.all(|neighbour| from[neighbour])
            };
        }
    }
}

/// The biggest run of pixels that are set and touch each other: its size, the box
/// it sits in, and which pixels belong to it.
///
/// Connected rather than simply "all of them": a reflection off to one side and
/// the sheet in the middle are both not-background, and taking them together
/// would give a box that spans the two. Walking outwards from a pixel keeps them
/// apart.
fn largest_blob(inside: &[bool], width: u32, height: u32) -> Option<(u32, Rect, Vec<bool>)> {
    let mut seen = vec![false; inside.len()];
    let mut to_visit: Vec<usize> = Vec::new();
    let mut blob: Vec<usize> = Vec::new();
    let mut largest: Option<(u32, Rect, Vec<bool>)> = None;

    for start in 0..inside.len() {
        if !inside[start] || seen[start] {
            continue;
        }

        seen[start] = true;
        to_visit.push(start);
        blob.clear();
        let (mut left, mut top) = (width - 1, height - 1);
        let (mut right, mut bottom) = (0u32, 0u32);

        while let Some(index) = to_visit.pop() {
            blob.push(index);
            let (x, y) = (index as u32 % width, index as u32 / width);
            left = left.min(x);
            right = right.max(x);
            top = top.min(y);
            bottom = bottom.max(y);

            visit_neighbours(index, width, height, |neighbour| {
                if inside[neighbour] && !seen[neighbour] {
                    seen[neighbour] = true;
                    to_visit.push(neighbour);
                }
            });
        }

        let area = blob.len() as u32;
        if largest
            .as_ref()
            .is_none_or(|(biggest, _, _)| area > *biggest)
        {
            let mut mask = vec![false; inside.len()];
            for &index in &blob {
                mask[index] = true;
            }
            largest = Some((
                area,
                Rect {
                    x: left,
                    y: top,
                    width: right - left + 1,
                    height: bottom - top + 1,
                },
                mask,
            ));
        }
    }

    largest
}

/// The four pixels up, down, left and right of this one, skipping those off the
/// edge.
fn visit_neighbours(index: usize, width: u32, height: u32, mut visit: impl FnMut(usize)) {
    let (x, y) = (index as u32 % width, index as u32 / width);

    if x > 0 {
        visit(index - 1);
    }
    if x + 1 < width {
        visit(index + 1);
    }
    if y > 0 {
        visit(index - width as usize);
    }
    if y + 1 < height {
        visit(index + width as usize);
    }
}

/// Puts a box found on the shrunk image back onto the full sized one.
///
/// It rounds outwards, so the box holds all of the paper rather than shaving a
/// line off it, and stays inside the image.
fn scale_up(sheet: Rect, width: u32, height: u32, image_width: u32, image_height: u32) -> Rect {
    let across = image_width as f32 / width as f32;
    let down = image_height as f32 / height as f32;

    let x = ((sheet.x as f32 * across) as u32).min(image_width - 1);
    let y = ((sheet.y as f32 * down) as u32).min(image_height - 1);

    Rect {
        x,
        y,
        width: ((sheet.width as f32 * across).ceil() as u32).min(image_width - x),
        height: ((sheet.height as f32 * down).ceil() as u32).min(image_height - y),
    }
}
