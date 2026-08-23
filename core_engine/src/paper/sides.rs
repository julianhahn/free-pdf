//! The four sides of the sheet, fitted on the 400 pixel wide copy.
//!
//! The rough area says roughly where the paper is; a patch of sheen lying against the
//! sheet joins it as one lobe, so the second step asks where the paper *stops*. One ray
//! per row and one per column marches outward from inside the rough area until it
//! crosses a step from paper to table, and a straight line is fitted through where the
//! rays of each side stopped. Every number here is in pixels of the shrunk copy.

use super::rough_area::EdgeLevels;
use super::Rect;

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

/// One side of the sheet, as a straight line across the shrunk copy: `across` is
/// where the side is at the position `along` down it.
///
/// The left and right side run `along` the rows and the top and bottom side along
/// the columns, so that neither pair ever has to answer for a line that is straight
/// up and down. One `y = a * x + b` for all four would, and its slope would be
/// infinite exactly where a photographed page usually is.
pub(super) struct Side {
    pub(super) slope: f32,
    pub(super) offset: f32,
}

impl Side {
    pub(super) fn across(&self, along: f32) -> f32 {
        self.slope * along + self.offset
    }
}

/// Casts one ray per row and one per column and fits a line through where the rays
/// stopped, giving the left, right, top and bottom side of the sheet.
///
/// Each ray starts in the middle of the rough area on its own scanline, so it starts
/// on paper, and walks outward. The first place it can honestly call the end of the
/// paper is the one that counts: further out there may be a second step where the
/// sheen beside the sheet ends, and that one is not the sheet.
pub(super) fn sides_of_the_sheet(
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
///
/// [`dark_area_reaching_the_border`]: super::rough_area::dark_area_reaching_the_border
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
pub(super) fn middle_of(values: &mut [f32]) -> Option<f32> {
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
