//! Finding the sheet of paper inside a photograph.
//!
//! Everything else in the engine works on brightness alone. That is enough for a
//! scan, where the whole image is paper, but not for a photo: on a table the
//! darkest thing in the frame can be the table rather than the writing, and a
//! brightness stretch measured over the whole image then comes out wrong. Telling
//! the two apart needs to know *where* the paper is, which is what this does.

use image::{DynamicImage, GenericImageView};

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
#[derive(Debug, Clone, PartialEq)]
pub struct Paper {
    /// The smallest box that holds the whole sheet.
    pub bounds: Rect,
    /// Which pixels are paper, on the shrunk copy the search ran on.
    on_paper: Vec<bool>,
    /// The corners of the four sides that were fitted to the edges of the sheet,
    /// on the shrunk copy, when they could be fitted. Nothing when only brightness
    /// found the sheet, and then [`Self::corners`] falls back to reading the mask.
    corners: Option<[Point; 4]>,
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
    /// Normally these are the four places where the fitted sides of the sheet
    /// cross, and they have to come from the sides rather than from any point of
    /// the mask. A real photographed sheet has rounded or turned-up corners, and
    /// even the `document_on_a_dark_table` fixture cuts sixty pixels off each
    /// corner on purpose, so the corner of the paper is often not a pixel of the
    /// paper at all. Two lines crossing find it anyway.
    ///
    /// When no sides could be fitted the answer falls back to the outermost pixel
    /// of the mask along each diagonal, which for any convex shape is a corner. A
    /// sheet turned by roughly 45 degrees still gets its four corners in the right
    /// order round the shape, so straightening still works - the result simply
    /// comes out turned by the same 45 degrees, since nothing here knows which way
    /// up the writing is.
    pub fn corners(&self) -> [Point; 4] {
        if let Some(corners) = self.corners {
            return corners.map(|corner| self.point_in_full_size(corner));
        }

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
        self.point_in_full_size(Point {
            x: x as f32,
            y: y as f32,
        })
    }

    /// The same for a point that fell between pixels of the shrunk copy, which a
    /// corner found by crossing two fitted lines always does.
    fn point_in_full_size(&self, point: Point) -> Point {
        Point {
            x: (point.x + 0.5) * self.image_width as f32 / self.width as f32,
            y: (point.y + 0.5) * self.image_height as f32 / self.height as f32,
        }
    }

    /// Whether the sheet runs off the edge of the photo.
    ///
    /// A true report about the photo, not a veto: [`Self::corners`] then returns the
    /// points where the paper leaves the frame instead of the corners of the sheet, so
    /// the straightened page is a piece of the sheet rather than the whole of it. A
    /// caller that shows pages tells the user that, and offers a new photo.
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

/// Finds the sheet of paper in a photograph.
///
/// It looks twice, and the second look is the answer. The first is brightness: the
/// paper is brighter than what it lies on, and the background reaches the edge of
/// the picture while the paper does not have to, so the dark pixels that can be
/// reached from the border are the background and the largest area that is not
/// background is roughly where the sheet is. Going by "not background" rather than
/// "bright" is what puts the writing back on the paper: letters are dark, but they
/// are surrounded by paper and never touch the border, so they end up inside the
/// sheet where they belong. Without that a measurement inside the sheet would never
/// see any ink.
///
/// Roughly is not enough, though. A desk with any shine on it has patches as bright
/// as the paper lying against the sheet, and they join that area as one lobe. So
/// the second look asks where the paper *stops*: from inside the rough area it
/// marches outward along every row and every column until it crosses a step from
/// paper to table, fits a straight line through where those marches stopped on each
/// of the four sides, and takes the sheet to be the quadrilateral those four lines
/// make. A patch of sheen cannot bend one of those lines much and cannot move a
/// corner at all, because a corner is now where two lines cross rather than the
/// outermost pixel of a blob.
///
/// The two looks stay tied together. The lines are only believed while they agree
/// with the rough area, the mask is the quadrilateral **and** the rough area, so
/// neither can claim what the other calls table, and when no line can be fitted the
/// rough area is the answer on its own, exactly as it was before.
///
/// The result is a **suggestion**, like [`crate::suggest_levels`]: the client is
/// meant to show the box as a rectangle the user can drag before anything is cut.
///
/// Returns `None` when nothing sheet-like is there: a bright area too small or too
/// thin to be a document. It does not judge whether what it found is really paper
/// - on a picture of something else it returns the largest bright thing in it.
///
/// Nothing about the sides can turn a sheet into `None`: a client reads `None` as
/// "leave this photo alone", so a side that cannot be fitted has to fall back to the
/// rough area rather than refuse the page.
///
/// ponytail: the rough area is still brightness only, so a document on a white desk
/// is still not found - paper and desk are then the same brightness and there is no
/// step for a ray to stop on either. Fixing that needs the sides to be found from
/// gradients across the whole picture instead of from inside a blob; worth doing
/// when someone actually photographs a page on white.
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

    let (area, bounds, on_paper) = largest_blob(&candidate, width, height)?;

    if !believable(area, bounds, width, height) {
        return None;
    }

    let fitted = paper_and_table_levels(&small, &on_paper)
        .and_then(|levels| {
            let sides = sides_of_the_sheet(&small, &on_paper, &background, bounds, &levels)?;
            Some(sides_read_again_in_the_photo(
                img, sides, &levels, width, height,
            ))
        })
        .and_then(|sides| the_sheet_between_the_sides(&sides, &on_paper, width, height));
    let (bounds, on_paper, corners) = match fitted {
        Some((bounds, mask, corners)) => (bounds, mask, Some(corners)),
        None => (bounds, on_paper, None),
    };

    Some(Paper {
        bounds: scale_up(bounds, width, height, image_width, image_height),
        on_paper,
        corners,
        width,
        height,
        image_width,
        image_height,
    })
}

/// Whether something of this size and shape can be the document someone
/// photographed. Asked of the rough area, where it decides between a sheet and
/// `None`, and again of the quadrilateral, where it only decides whether the four
/// fitted lines are worth believing.
fn believable(area: u32, bounds: Rect, width: u32, height: u32) -> bool {
    area as f32 >= (width * height) as f32 * SMALLEST_SHARE
        && bounds.width as f32 >= width as f32 * THINNEST_SIDE
        && bounds.height as f32 >= height as f32 * THINNEST_SIDE
}

/// How much of the picture's own paper-to-table contrast a step has to cross before
/// it counts as the edge of the sheet. Well under half, because a shadow along one
/// side of the paper softens the step there, and well above nothing, because a fold
/// or a shaded half of the page is a step too.
const EDGE_SHARE_OF_CONTRAST: f32 = 0.4;

/// The smallest step in brightness that is not simply noise. Shrinking and JPEG
/// leave a couple of levels of wobble on a flat surface, so a picture of paper on
/// almost-paper is refused rather than answered from noise.
const SMALLEST_EDGE_STEP: f32 = 14.0;

/// How far above the table's own level the outside of an edge may still be. The
/// point of measuring it against the table rather than against the inside is that a
/// fold or a shadow gives a large step with paper still on both sides of it: the
/// step alone says nothing, the level the step lands on does.
const TABLE_SHARE_OF_CONTRAST: f32 = 0.25;

/// How many pixels of the shrunk copy are averaged on each side of a candidate edge.
/// Three, so a single speck cannot make an edge, and no more, because the shrunk
/// copy has the whole edge in about two pixels.
const EDGE_SAMPLES: i32 = 3;

/// How far outward it has to stay table-dark for a step to be the edge of the sheet
/// rather than something written on it. This is the whole difference between the two:
/// a line of writing is at most three pixels thick on the shrunk copy and paper comes
/// back after it, while the table does not come back. Without this the rays down the
/// columns stop on a block of bold text and every top and bottom line is nonsense.
const STAYS_DARK: i32 = 10;

/// The share of a side skipped at each end. Corners are where a sheet is rounded,
/// turned up or cut off, and a ray there stops on the wrong side of the paper, so
/// the middle four sixths of each side are what the line is fitted through.
const CORNER_SHARE: f32 = 1.0 / 6.0;

/// How far apart two points have to be along a side before the slope between them is
/// worth anything. Twenty pixels of the four hundred wide copy: closer than that and
/// a pixel of wobble at either end swings the slope wildly.
const SLOPE_SPAN: f32 = 20.0;

/// How far off the line a point may be and still be taken for the edge of the sheet,
/// in pixels of the shrunk copy. A sheet is never quite flat, so a real edge bows by
/// a pixel or two along its length and all of it has to be kept. A ray that stopped
/// somewhere else altogether misses by tens of pixels: on the chamfered corner of the
/// `document_on_a_dark_table` fixture, or on the side next to the one it was fitting.
/// Measured on the real photos: anything from six to twenty gives the same four
/// corners, because nothing lands in between.
const TRIM_ALLOWANCE: f32 = 12.0;

/// The fewest rays that have to have stopped on a side before a line through them
/// means anything.
const FEWEST_EDGE_POINTS: usize = 8;

/// How far from square two crossing sides have to stay. The crossing of a near
/// vertical and a near horizontal line is a stable point; as the two turn towards
/// each other the crossing runs off to infinity long before the arithmetic notices,
/// so a shape that flat is refused instead.
const SQUARE_ENOUGH: f32 = 0.5;

/// The share of the quadrilateral that has to lie inside the rough area before the
/// four lines are believed. A sheet fills its own quadrilateral, so anything much
/// short of all of it means at least one line was fitted to something else.
const QUAD_INSIDE_THE_ROUGH_AREA: f32 = 0.85;

/// The two ways a quadrilateral can abandon the sheet instead of reaching out onto the
/// table, which is what [`QUAD_INSIDE_THE_ROUGH_AREA`] catches. Both are needed for one
/// mistake: a side fitted to something lying *on the page*.
///
/// A dark thing across the sheet that also runs off onto the table - a hand holding the
/// page down, a pen, a phone, the shadow of any of them - passes every test a ray has
/// for the end of the paper, including being reachable from the edge of the picture, so
/// the rays through it stop on it, they are the majority of that side, and the whole
/// side jumps onto the page. Nothing is wrong with the shape that comes out: it is a
/// clean rectangle well inside the rough area. What is wrong is the bright area left
/// outside it. Cutting a page short loses writing, which is the one failure this file
/// may not have, so such a quadrilateral is dropped and the rough area answers instead
/// - an uncut page is complete.
///
/// The first number is the share of one side's *length* that has bright area carrying on
/// past it, which is what the paper beside the thing shows. Measured: at most 19 % on the
/// twelve real photos, 23.2 % on the `document_beside_a_patch_of_sheen` fixture, where a
/// lobe of sheen leans against the sheet and is meant to be left out, and 36 % on the
/// thing lying across two thirds of the bottom side.
///
/// The second is the share of the rough area the shape keeps, which catches the thing
/// that covers nearly the whole of a side, so that hardly any paper is left beside it to
/// show: 95.5 % to 100 % on the real photos, 93.2 % on the sheen fixture, and 52.4 % on a
/// bar right across the page and out to the edge of the picture, whose own length share
/// is only 7.8 %.
///
/// ponytail: between the two there is still room for a thing that covers nearly the
/// whole of one side and hides only a little paper behind it. What it hides is behind
/// the thing itself, so nothing readable is lost, and closing that gap needs the page's
/// real edge to be found through the object, which no arithmetic here can do.
const SHEET_CARRYING_ON_PAST_A_SIDE: f32 = 0.3;
const ROUGH_AREA_INSIDE_THE_QUAD: f32 = 0.9;

/// How far past a fitted side the bright area is looked at, in pixels of the shrunk
/// copy. Not from the line itself, where the edge's own wobble and the outward lean
/// decide it, and not far, because a side's whole distance from the next one is only a
/// few hundred.
const JUST_PAST_A_SIDE: i32 = 4;
const WELL_PAST_A_SIDE: i32 = 10;

/// How far inward a fitted side is moved when it could not be read again in the photo
/// ([`sides_read_again_in_the_photo`]), in pixels of the shrunk copy - about four
/// pixels of a photograph from a phone.
///
/// A straight line through slightly wavy edge points misses by a pixel or two either
/// way, and the miss is pushed into the harmless direction on purpose. Which
/// direction that is was decided by Julian on 2026-08-18, on scans off a real phone,
/// against the earlier reading: outward left every page with a hair of desk along all
/// four sides - visible, and it is what a straightening then has to work around.
/// Inward costs the outer pixels of the sheet, and a sheet of paper carries a white
/// margin there, so on a page of writing there is nothing in them to lose.
///
/// Do not turn it back outward to protect a page whose writing runs to the very edge
/// of the paper. That page needs Adjust, which sends its own corners, and no bias in
/// either direction saves it.
const INWARD_BIAS: f32 = 0.5;

/// How many places along each side are measured again in the full sized photo, spread
/// evenly between its two ends and none of them at an end. Nine, over the whole side: a
/// photographed sheet is never flat, so its edge bows by up to twenty pixels along its
/// length and the places have to be spread over the whole of it for the middle of them to
/// be the middle of the edge. The ends are left out because a corner is where two edges
/// meet and neither is clean there.
const PLACES_READ_AGAIN: usize = 9;

/// How far either way the true edge is looked for, in pixels of the photograph. Sixty,
/// because a real sheet is not flat: on `extra_4`, a letter with a fold in it, the bottom
/// edge wanders far enough from the fitted side that at thirty two most of its places
/// found no edge at all, the side fell back on the rough fit, and the page was cut
/// fourteen pixels into the sheet.
const LOOK_FOR_THE_EDGE: i32 = 60;

/// How many pixels of the photograph are averaged on each side of a candidate step, and
/// how far off the step itself they start. Averaging kills the film grain, and the gap
/// keeps the samples out of the two or three pixels the edge itself is smeared over.
const PHOTO_EDGE_SAMPLES: i32 = 3;
const PHOTO_EDGE_GAP: i32 = 2;

/// The fewest places along a side that have to find an edge before the side is moved
/// onto them. Below that the side keeps the position the rough fit gave it: a page cut
/// by two or three readings on a shadow is worse than a page cut a few pixels wide.
const FEWEST_PLACES_READ_AGAIN: usize = 5;

/// How far inward the refined side is put, in pixels of the photograph.
///
/// A hair, now that the side sits on the measured edge rather than on a guess. Inward
/// rather than outward because a sliver of desk in the page bends the
/// straightening while a hair off the white margin
/// costs nothing. Measured with `examples/edge_error.rs`: at this value the middle of all
/// four sides of all twelve real photos reads 0 to +3 pixels inside the paper; at 1.0 three
/// middles read a pixel outside it, and at 2.0 one read +4.
///
/// Do not raise it to cover a bowed edge. That was tried, on the reading that six pixels
/// would put the worst place of a left or right side inside the paper too: it does, and it
/// then cuts six pixels off a flat sheet, which two synthetic tests caught. A straight side
/// on a bowed edge is the ceiling here, not this number - see `sides_read_again_in_the_photo`.
const INWARD_HAIR: f32 = 1.5;

/// Moves each fitted side onto the edge of the paper as the full sized photo shows it.
///
/// The rough fit runs on a 400 pixel wide copy, where one pixel is about eight pixels of
/// the photo, so its four sides are only ever right to within a pixel or two of that
/// copy - and the miss is not the same on all four, which is why no single bias can take
/// it out. So each side is read again where it matters: at [`PLACES_READ_AGAIN`] places
/// along it the photo is walked across the side, the steepest step from paper to table
/// is taken as the true edge, and the whole side is moved onto the middle of those
/// readings. The slope stays as the rough fit found it, because the slope is an average
/// over the whole length of the side and is already as good as the edge is straight.
///
/// Only these few lines of the photo are ever read - a page is a few thousand pixels,
/// not the twelve million of the picture, which the phone has no room for.
///
/// Where a place finds no clear step it is left out, and where fewer than
/// [`FEWEST_PLACES_READ_AGAIN`] places answer the side is returned untouched: an invented
/// edge cuts writing off the page.
///
/// ponytail: the side stays straight, so on a bowed edge it sits inside the paper in the
/// middle and outside it towards the ends - a local strip of desk that the middle reading
/// cannot see. Ceiling of moving a straight line. The way up is a corner of its own for
/// each end, or four sides that may bend; both are more than a constant, and neither is
/// worth building until someone has looked at a page and said the strip still shows.
fn sides_read_again_in_the_photo(
    img: &DynamicImage,
    sides: [Side; 4],
    levels: &EdgeLevels,
    width: u32,
    height: u32,
) -> [Side; 4] {
    let [left, right, top, bottom] = &sides;
    // Where the side begins and ends: the corners the rough fit already implies, so the
    // places are spread over the side itself and not over the box around the sheet.
    let (Some(top_left), Some(top_right), Some(bottom_right), Some(bottom_left)) = (
        crossing(left, top),
        crossing(right, top),
        crossing(right, bottom),
        crossing(left, bottom),
    ) else {
        return sides;
    };
    let ends = [
        (top_left.y, bottom_left.y),
        (top_right.y, bottom_right.y),
        (top_left.x, top_right.x),
        (bottom_left.x, bottom_right.x),
    ];
    let (across_x, across_y) = (
        img.width() as f32 / width as f32,
        img.height() as f32 / height as f32,
    );
    // Each side, as: does it run along the rows, and which way across it points off the
    // paper. The same order and the same directions as the rays that fitted it.
    let shape = [(true, -1.0), (true, 1.0), (false, -1.0), (false, 1.0)];

    std::array::from_fn(|index| {
        let (along_the_rows, outward) = shape[index];
        let side = &sides[index];
        let scale = if along_the_rows { across_x } else { across_y };
        let (first, last) = ends[index];

        let mut misses = Vec::new();
        for place in 1..=PLACES_READ_AGAIN {
            let along = first + (last - first) * place as f32 / (PLACES_READ_AGAIN + 1) as f32;
            let across = side.across(along);
            let at = if along_the_rows {
                Point {
                    x: (across + 0.5) * across_x,
                    y: (along + 0.5) * across_y,
                }
            } else {
                Point {
                    x: (along + 0.5) * across_x,
                    y: (across + 0.5) * across_y,
                }
            };
            if let Some(miss) = edge_across_the_side(img, at, along_the_rows, outward, levels.step)
            {
                misses.push(miss);
            }
        }

        // The rough side, moved inward by the hair that used to be the whole
        // correction. Left and top move down the axis, right and bottom up it, so every
        // side moves towards the middle of the sheet.
        let unmoved = Side {
            slope: side.slope,
            offset: side.offset - outward * INWARD_BIAS,
        };
        if misses.len() < FEWEST_PLACES_READ_AGAIN {
            return unmoved;
        }
        match middle_of(&mut misses) {
            Some(middle) => Side {
                offset: side.offset + outward * (middle - INWARD_HAIR) / scale,
                ..unmoved
            },
            None => unmoved,
        }
    })
}

/// How far off the fitted side the real edge of the paper lies at one place, in pixels of
/// the photograph, walking across the side. Positive means further out, so the side is
/// standing inside the paper.
///
/// The steepest step from bright to dark within [`LOOK_FOR_THE_EDGE`] wins, and nothing
/// comes back unless that step is as big as the edge of a sheet in this picture -
/// otherwise it is a line of writing, a shadow, or the grain of a flat surface.
fn edge_across_the_side(
    img: &DynamicImage,
    at: Point,
    along_the_rows: bool,
    outward: f32,
    step: f32,
) -> Option<f32> {
    let brightness = |offset: f32| -> Option<f32> {
        let moved = outward * offset;
        let (x, y) = if along_the_rows {
            (at.x + moved, at.y)
        } else {
            (at.x, at.y + moved)
        };
        if x < 0.0 || y < 0.0 || x >= img.width() as f32 || y >= img.height() as f32 {
            return None;
        }
        let pixel = img.get_pixel(x as u32, y as u32).0;
        // The same grey the rest of the file works in.
        Some(0.299 * pixel[0] as f32 + 0.587 * pixel[1] as f32 + 0.114 * pixel[2] as f32)
    };
    let mean = |from: f32, step: f32| -> Option<f32> {
        let mut total = 0.0;
        for sample in 0..PHOTO_EDGE_SAMPLES {
            total += brightness(from + step * sample as f32)?;
        }
        Some(total / PHOTO_EDGE_SAMPLES as f32)
    };

    let mut steepest = (0.0, 0.0);
    for offset in -LOOK_FOR_THE_EDGE..=LOOK_FOR_THE_EDGE {
        let offset = offset as f32;
        let (Some(inside), Some(outside)) = (
            mean(offset - PHOTO_EDGE_GAP as f32, -1.0),
            mean(offset + PHOTO_EDGE_GAP as f32, 1.0),
        ) else {
            continue;
        };
        if inside - outside > steepest.0 {
            steepest = (inside - outside, offset);
        }
    }

    (steepest.0 >= step).then_some(steepest.1)
}

/// One side of the sheet, as a straight line across the shrunk copy: `across` is
/// where the side is at the position `along` down it.
///
/// The left and right side run `along` the rows and the top and bottom side along
/// the columns, so that neither pair ever has to answer for a line that is straight
/// up and down. One `y = a * x + b` for all four would, and its slope would be
/// infinite exactly where a photographed page usually is.
struct Side {
    slope: f32,
    offset: f32,
}

impl Side {
    fn across(&self, along: f32) -> f32 {
        self.slope * along + self.offset
    }
}

/// What the picture itself says paper and table look like, and the three levels a
/// ray needs to tell them apart.
struct EdgeLevels {
    /// The smallest step from paper to table worth stopping on.
    step: f32,
    /// The inside of an edge has to be at least this bright, or it is not paper.
    paper: f32,
    /// The outside of an edge has to be at most this bright, or it is not the table.
    table: f32,
}

/// The levels, read off this picture rather than fixed: the middle brightness of the
/// rough area and the middle brightness of everything else. Nothing is fixed for the
/// same reason [`otsu_threshold`] exists - a dark wood desk and a grey desk want
/// different numbers and the picture says which.
///
/// Nothing comes back when there is no outside to compare with, or when the outside
/// is not darker than the inside. A picture that is all paper is the honest case of
/// that, and it wants the rough area as the answer, not a set of lines.
fn paper_and_table_levels(small: &image::GrayImage, rough: &[bool]) -> Option<EdgeLevels> {
    let mut inside = [0u32; 256];
    let mut outside = [0u32; 256];
    for (index, pixel) in small.pixels().enumerate() {
        let counts = if rough[index] {
            &mut inside
        } else {
            &mut outside
        };
        counts[pixel[0] as usize] += 1;
    }

    let paper = middle_brightness(&inside)?;
    let table = middle_brightness(&outside)?;
    let contrast = paper - table;
    if contrast <= 0.0 {
        return None;
    }

    Some(EdgeLevels {
        step: (contrast * EDGE_SHARE_OF_CONTRAST).max(SMALLEST_EDGE_STEP),
        paper: table + contrast / 2.0,
        table: table + contrast * TABLE_SHARE_OF_CONTRAST,
    })
}

/// The brightness half the counted pixels are below. The middle rather than the
/// average, so the writing on the paper and a shadow on the table pull neither
/// level towards themselves.
fn middle_brightness(counts: &[u32; 256]) -> Option<f32> {
    let total: u64 = counts.iter().map(|&count| u64::from(count)).sum();
    if total == 0 {
        return None;
    }

    let mut seen = 0u64;
    for (value, &count) in counts.iter().enumerate() {
        seen += u64::from(count);
        if seen * 2 >= total {
            return Some(value as f32);
        }
    }

    None
}

/// Casts one ray per row and one per column and fits a line through where the rays
/// stopped, giving the left, right, top and bottom side of the sheet.
///
/// Each ray starts in the middle of the rough area on its own scanline, so it starts
/// on paper, and walks outward. The first place it can honestly call the end of the
/// paper is the one that counts: further out there may be a second step where the
/// sheen beside the sheet ends, and that one is not the sheet.
fn sides_of_the_sheet(
    small: &image::GrayImage,
    rough: &[bool],
    background: &[bool],
    bounds: Rect,
    levels: &EdgeLevels,
) -> Option<[Side; 4]> {
    let (width, height) = (small.width() as i32, small.height() as i32);
    let brightness = |x: i32, y: i32| f32::from(small.get_pixel(x as u32, y as u32)[0]);
    let set = |x: i32, y: i32| rough[(y * width + x) as usize];
    let table = |x: i32, y: i32| background[(y * width + x) as usize];

    let inner = |start: u32, size: u32| {
        let skipped = (size as f32 * CORNER_SHARE) as i32;
        (start as i32 + skipped)..(start as i32 + size as i32 - skipped)
    };

    let (mut left, mut right) = (Vec::new(), Vec::new());
    for y in inner(bounds.y, bounds.height) {
        let Some(start) = middle_of_the_scanline((0..width).filter(|&x| set(x, y))) else {
            continue;
        };
        let along_the_row = |x: i32| (brightness(x, y), table(x, y));

        if let Some(x) = where_the_paper_stops(along_the_row, width, start, -1, levels) {
            left.push((y as f32, x));
        }
        if let Some(x) = where_the_paper_stops(along_the_row, width, start, 1, levels) {
            right.push((y as f32, x));
        }
    }

    let (mut top, mut bottom) = (Vec::new(), Vec::new());
    for x in inner(bounds.x, bounds.width) {
        let Some(start) = middle_of_the_scanline((0..height).filter(|&y| set(x, y))) else {
            continue;
        };
        let down_the_column = |y: i32| (brightness(x, y), table(x, y));

        if let Some(y) = where_the_paper_stops(down_the_column, height, start, -1, levels) {
            top.push((x as f32, y));
        }
        if let Some(y) = where_the_paper_stops(down_the_column, height, start, 1, levels) {
            bottom.push((x as f32, y));
        }
    }

    let mut sides = Vec::with_capacity(4);
    for points in [left, right, top, bottom].iter() {
        sides.push(fit_a_side(points)?);
    }

    sides.try_into().ok()
}

/// The middle of what the rough area covers on one scanline, as the place to start a
/// ray from. The middle rather than an end, because an end of the rough area is
/// exactly where a lobe of sheen hangs off it.
fn middle_of_the_scanline(set: impl Iterator<Item = i32>) -> Option<i32> {
    let places: Vec<i32> = set.collect();
    places.get(places.len() / 2).copied()
}

/// Where the paper stops along one scanline: the innermost place that really looks
/// like the edge of the sheet, or nothing when the ray never finds one.
///
/// Five things have to hold at once, and the last two are the ones that make the
/// method work. The step has to be big enough, the inside of it has to be bright
/// enough to be paper, the outside dark enough to be the table, it has to *stay*
/// that dark for [`STAYS_DARK`] pixels further out, and what lies out there has to
/// be background - dark and connected to the edge of the picture, which is what
/// [`dark_area_reaching_the_border`] already worked out.
///
/// A block of writing is why both are needed. A shrunk line of writing is thinner
/// than [`STAYS_DARK`], so the fourth test throws it out, but a whole paragraph is
/// not, and looked at from below its lower edge is a perfect step from paper into
/// something dark. What it is not is connected to the edge of the picture: ink is
/// enclosed by paper and the table is not, and that is the difference the fifth test
/// reads. Measured on the `document_on_a_dark_table` fixture, whose block of writing
/// is a fifth of the way from the table's own level to the paper's and fifty rows
/// thick on the shrunk copy: without the fifth test the top of the sheet came out
/// under the writing, two hundred and fifty pixels down the page.
///
/// The ray also stops at the frame: the samples it needs have to be inside the
/// picture, so a sheet that leaves the frame simply gives no point for that side
/// instead of an invented one.
fn where_the_paper_stops(
    brightness_and_table: impl Fn(i32) -> (f32, bool),
    span: i32,
    start: i32,
    outward: i32,
    levels: &EdgeLevels,
) -> Option<f32> {
    let brightness = |at: i32| brightness_and_table(at).0;
    let mean = |first: i32, step: i32, count: i32| {
        (0..count)
            .map(|sample| brightness(first + sample * step))
            .sum::<f32>()
            / count as f32
    };
    let all_background = |first: i32, count: i32| {
        (0..count).all(|sample| brightness_and_table(first + sample * outward).1)
    };

    let mut position = start;
    let innermost_sample = |position: i32| position - (EDGE_SAMPLES - 1) * outward;
    let outermost_sample = |position: i32| position + (EDGE_SAMPLES + STAYS_DARK) * outward;
    while (0..span).contains(&innermost_sample(position))
        && (0..span).contains(&outermost_sample(position))
    {
        let inside = mean(position, -outward, EDGE_SAMPLES);
        let outside = mean(position + outward, outward, EDGE_SAMPLES);
        let further_out = mean(position + (EDGE_SAMPLES + 1) * outward, outward, STAYS_DARK);

        if inside - outside >= levels.step
            && inside >= levels.paper
            && outside <= levels.table
            && further_out <= levels.table
            && all_background(position + (EDGE_SAMPLES + 1) * outward, STAYS_DARK)
        {
            // Between the last pixel of paper and the first of table.
            return Some(position as f32 + 0.5 * outward as f32);
        }
        position += outward;
    }

    None
}

/// Fits one straight side through the places the rays stopped, as `(along, across)`
/// pairs.
///
/// Some of those places are wrong: where sheen lies against the sheet a ray runs
/// past the edge and stops at the far side of the sheen instead, and near a corner
/// a ray down a column can stop on the left or right edge of the paper. So the fit
/// has to ignore a minority of the points rather than average them in. It starts
/// with Theil-Sen - the middle of the slopes of all pairs of points - which is not
/// moved at all until more than half the points are wrong, then drops the points that
/// line does not explain and fits the rest properly. One such round is enough: on the
/// real photos two, four and eight gave the same four corners to the pixel.
///
/// Do not turn the Theil-Sen start into a plain least squares fit. That was tried:
/// the fitted lines were quietly dragged sideways by the rays that had run past the
/// edge, and the numbers still looked perfectly reasonable. It only showed up when
/// the mask was painted over the photo.
fn fit_a_side(points: &[(f32, f32)]) -> Option<Side> {
    if points.len() < FEWEST_EDGE_POINTS {
        return None;
    }

    let mut slopes = Vec::new();
    for (index, &(along, across)) in points.iter().enumerate() {
        for &(other_along, other_across) in &points[index + 1..] {
            if (other_along - along).abs() >= SLOPE_SPAN {
                slopes.push((other_across - across) / (other_along - along));
            }
        }
    }

    let mut side = Side {
        slope: middle_of(&mut slopes)?,
        offset: 0.0,
    };
    let mut offsets: Vec<f32> = points
        .iter()
        .map(|&(along, across)| across - side.slope * along)
        .collect();
    side.offset = middle_of(&mut offsets)?;

    let miss = |&(along, across): &(f32, f32)| (across - side.across(along)).abs();
    let kept: Vec<(f32, f32)> = points
        .iter()
        .filter(|point| miss(point) <= TRIM_ALLOWANCE)
        .copied()
        .collect();
    if kept.len() * 2 < points.len() {
        return None;
    }

    straight_through(&kept)
}

/// The middle value, which is what makes a fit ignore a minority of wrong points
/// instead of being pulled by them.
fn middle_of(values: &mut [f32]) -> Option<f32> {
    values.sort_by(|one, other| one.total_cmp(other));
    values.get(values.len() / 2).copied()
}

/// The line that passes closest to all of these points at once.
fn straight_through(points: &[(f32, f32)]) -> Option<Side> {
    let count = points.len() as f32;
    let mean_along = points.iter().map(|&(along, _)| along).sum::<f32>() / count;
    let mean_across = points.iter().map(|&(_, across)| across).sum::<f32>() / count;

    let mut spread = 0.0;
    let mut together = 0.0;
    for &(along, across) in points {
        spread += (along - mean_along) * (along - mean_along);
        together += (along - mean_along) * (across - mean_across);
    }
    if spread <= 0.0 {
        return None;
    }

    let slope = together / spread;
    Some(Side {
        slope,
        offset: mean_across - slope * mean_along,
    })
}

/// The sheet the four sides enclose: the box to cut to, which pixels are paper, and
/// the four corners, all on the shrunk copy. Nothing comes back when the four lines
/// do not describe a sheet, and then the rough area is the answer on its own.
///
/// The mask is the quadrilateral **and** the rough area, both ways round on purpose.
/// The quadrilateral takes the sheen off the rough area, and the rough area takes the
/// table out of the quadrilateral's corners, where a real sheet is rounded or the
/// fitted line passes a pixel wide of it. Keeping them tied together is also what
/// stops the stored corners from ever meaning something else than the mask does.
///
/// The two are also checked against each other both ways round: a quadrilateral that
/// reaches out onto the table is wrong ([`QUAD_INSIDE_THE_ROUGH_AREA`]), and so is one
/// that abandons a piece of the sheet ([`SHEET_CARRYING_ON_PAST_A_SIDE`] and
/// [`ROUGH_AREA_INSIDE_THE_QUAD`]).
fn the_sheet_between_the_sides(
    sides: &[Side; 4],
    rough: &[bool],
    width: u32,
    height: u32,
) -> Option<(Rect, Vec<bool>, [Point; 4])> {
    let [left, right, top, bottom] = sides;
    let corners = [
        crossing(left, top)?,
        crossing(right, top)?,
        crossing(right, bottom)?,
        crossing(left, bottom)?,
    ];

    // A corner outside the picture was never seen, so it was invented, and a shape
    // that is not convex is not a photographed sheet.
    let inside_the_picture = |corner: &Point| {
        (0.0..=(width - 1) as f32).contains(&corner.x)
            && (0.0..=(height - 1) as f32).contains(&corner.y)
    };
    if !corners.iter().all(inside_the_picture) || !convex(&corners) {
        return None;
    }

    let mut mask = vec![false; rough.len()];
    let (mut quad_area, mut shared_area) = (0u32, 0u32);
    let (mut min_x, mut min_y) = (width - 1, height - 1);
    let (mut max_x, mut max_y) = (0u32, 0u32);

    for y in 0..height {
        let (from, to) = (left.across(y as f32), right.across(y as f32));
        for x in 0..width {
            let across = x as f32;
            let down = y as f32;
            if across < from
                || across > to
                || down < top.across(across)
                || down > bottom.across(across)
            {
                continue;
            }

            quad_area += 1;
            let index = (y * width + x) as usize;
            if !rough[index] {
                continue;
            }
            shared_area += 1;
            mask[index] = true;
            min_x = min_x.min(x);
            max_x = max_x.max(x);
            min_y = min_y.min(y);
            max_y = max_y.max(y);
        }
    }

    let carries_on = |side: &Side, down_the_rows: bool, outward: f32, span: (f32, f32)| {
        sheet_carries_on_past(side, down_the_rows, outward, span, rough, width, height)
    };
    let too_much_left_out = carries_on(left, true, -1.0, (corners[0].y, corners[3].y))
        .max(carries_on(right, true, 1.0, (corners[1].y, corners[2].y)))
        .max(carries_on(top, false, -1.0, (corners[0].x, corners[1].x)))
        .max(carries_on(bottom, false, 1.0, (corners[3].x, corners[2].x)));
    if too_much_left_out > SHEET_CARRYING_ON_PAST_A_SIDE {
        return None;
    }

    let rough_area = rough.iter().filter(|&&set| set).count();
    if shared_area == 0
        || (shared_area as f32) < quad_area as f32 * QUAD_INSIDE_THE_ROUGH_AREA
        || (shared_area as f32) < rough_area as f32 * ROUGH_AREA_INSIDE_THE_QUAD
    {
        return None;
    }

    let bounds = Rect {
        x: min_x,
        y: min_y,
        width: max_x - min_x + 1,
        height: max_y - min_y + 1,
    };
    if !believable(shared_area, bounds, width, height) {
        return None;
    }

    Some((bounds, mask, corners))
}

/// Over how much of one side's length the bright area plainly carries on past it,
/// which is a side fitted in the wrong place.
///
/// `down_the_rows` says which way the side runs - `across` of a row for the left and
/// right side, of a column for the top and bottom one - and `outward` which way is off
/// the sheet. A place counts when every pixel from [`JUST_PAST_A_SIDE`] to
/// [`WELL_PAST_A_SIDE`] beyond the line is bright area: near the line a pixel of wobble
/// and the outward lean would decide it, and past that only more paper is left out
/// there.
fn sheet_carries_on_past(
    side: &Side,
    down_the_rows: bool,
    outward: f32,
    span: (f32, f32),
    rough: &[bool],
    width: u32,
    height: u32,
) -> f32 {
    let (first, last) = (span.0.min(span.1) as i32, span.0.max(span.1) as i32);
    let bright_at = |along: i32, offset: i32| {
        let across = side.across(along as f32) + outward * offset as f32;
        let (x, y) = if down_the_rows {
            (across, along as f32)
        } else {
            (along as f32, across)
        };
        if x < 0.0 || y < 0.0 || x >= width as f32 || y >= height as f32 {
            // Off the picture is not paper left out, it is nothing to see.
            return false;
        }
        rough[(y as u32 * width + x as u32) as usize]
    };

    let carries_on = (first..=last)
        .filter(|&along| {
            (JUST_PAST_A_SIDE..=WELL_PAST_A_SIDE).all(|offset| bright_at(along, offset))
        })
        .count();

    carries_on as f32 / (last - first + 1).max(1) as f32
}

/// Where two sides cross, or nothing when they are too near parallel for the
/// crossing to mean anything.
fn crossing(vertical: &Side, horizontal: &Side) -> Option<Point> {
    let turned = 1.0 - vertical.slope * horizontal.slope;
    if turned.abs() < SQUARE_ENOUGH {
        return None;
    }

    let x = (vertical.slope * horizontal.offset + vertical.offset) / turned;
    Some(Point {
        x,
        y: horizontal.across(x),
    })
}

/// Whether these four corners, taken in order, turn the same way at every one of
/// them. A quadrilateral that does not is a bow tie, and no sheet of paper is one.
fn convex(corners: &[Point; 4]) -> bool {
    let turn = |at: usize| {
        let (from, corner, to) = (corners[at], corners[(at + 1) % 4], corners[(at + 2) % 4]);
        (corner.x - from.x) * (to.y - corner.y) - (corner.y - from.y) * (to.x - corner.x)
    };

    (0..4).all(|at| turn(at) > 0.0) || (0..4).all(|at| turn(at) < 0.0)
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
