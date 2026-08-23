//! Four sides in, four corners out: the sheet the fitted sides enclose.
//!
//! The last of the six steps. It crosses the four lines, keeps the quadrilateral only
//! while it agrees with the rough area both ways round, and gives back the box to cut
//! to, which pixels are paper, and the four corners a straightening needs. Nothing here
//! may turn a found sheet into `None`: when the quadrilateral is not believed, the
//! rough area answers on its own. Everything is in pixels of the 400 pixel wide copy.

use super::sides::Side;
use super::{believable, Point, Rect};

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
pub(super) fn the_sheet_between_the_sides(
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
pub(super) fn crossing(vertical: &Side, horizontal: &Side) -> Option<Point> {
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
