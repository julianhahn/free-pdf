//! Finding the sheet of paper inside a photograph.
//!
//! Everything else in the engine works on brightness alone. That is enough for a
//! scan, where the whole image is paper, but not for a photo: on a table the
//! darkest thing in the frame can be the table rather than the writing, and a
//! brightness stretch measured over the whole image then comes out wrong. Telling
//! the two apart needs to know *where* the paper is, which is what this does.
//!
//! The search runs in six steps, in this order, and each has its own file: `rough_area`
//! finds the sheet by brightness alone on a 400 pixel wide copy, `sides` fits four
//! straight sides to it there, `read_again` reads each of those sides again in the full
//! sized photo, `where_a_side_goes` turns the readings of one side into a lean and a
//! place, and `quadrilateral` turns the four sides into four corners, a mask and a box.
//! `find_paper` below is what drives them. Which raster each file counts its pixels in,
//! and what may never change, is the `AGENTS.md` beside this one.

mod quadrilateral;
mod read_again;
mod rough_area;
mod sides;
mod where_a_side_goes;

/// `deskew` shrinks a photo to the same copy this search runs on, so the two agree
/// about which pixel is which.
pub(crate) use rough_area::shrink_to_gray;

use image::DynamicImage;
use quadrilateral::the_sheet_between_the_sides;
use read_again::sides_read_again_in_the_photo;
use rough_area::{
    brightness_histogram, dark_area_reaching_the_border, largest_blob, otsu_threshold,
    paper_and_table_levels, scale_up,
};
use sides::sides_of_the_sheet;

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
    ///
    /// ponytail: watch item, not a bug anybody has seen. This reads the border of the mask, and
    /// after a successful fit that mask is the quadrilateral of the four MOVED sides cut against
    /// the rough area ([`the_sheet_between_the_sides`]), so every pixel the sides are pulled
    /// inward shrinks what this looks at: about 1.5 pixels of the shrunk copy from
    /// [`MOST_INWARD`] and up to another 1.6 at a corner from [`MOST_LEAN`]. A sheet whose four
    /// fitted corners are all inside the frame while its edge still touches it could therefore
    /// stop reporting itself incomplete, and the user would not be offered a new photo. None of
    /// the thirteen real photos shows it, and `runs_off_1.jpg` cannot: its corners fall outside
    /// the frame, so the fit is dropped and this reads the untouched rough mask - which is why
    /// its answer has not moved through either round of `TASKS.md` 36. The way up is to keep the
    /// rough mask for this one question instead of the fitted one.
    ///
    /// [`MOST_INWARD`]: where_a_side_goes::MOST_INWARD
    /// [`MOST_LEAN`]: where_a_side_goes::MOST_LEAN
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
