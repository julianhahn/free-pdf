//! The second look, in the full sized photo.
//!
//! A side fitted on a 400 pixel wide copy is only right to a pixel or two of that copy,
//! which is eight or sixteen pixels of the photograph, and the miss is not the same on
//! all four sides. So each side is read again where it matters: at nine places along it
//! the photo itself is walked across the side and the steepest step from paper to table
//! is taken as the true edge. Only these few lines of the photo are ever read. Every
//! number in this file is in pixels of the photograph, not of the shrunk copy.

use super::quadrilateral::crossing;
use super::rough_area::EdgeLevels;
use super::sides::Side;
use super::where_a_side_goes::{how_the_side_leans, where_the_side_goes};
use super::Point;
use image::{DynamicImage, GenericImageView};

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
/// evenly between its two ends and none of them at an end: a photographed sheet is never
/// flat, so its edge bows along its length and the places have to be spread over the whole of
/// it for the innermost of them to be the innermost of the edge - see [`where_the_side_goes`].
/// How far a real edge bows is measured in the `ponytail:` note on
/// [`sides_read_again_in_the_photo`]. The ends are left out because a corner is where two
/// edges meet and neither is clean there.
///
/// These places fix two numbers, not one: where the side sits and how it leans
/// ([`how_the_side_leans`]).
///
/// **Twenty-nine, and it is half of a pair - see [`MOST_INWARD`], which carries the sweep.**
/// `part = place / (PLACES_READ_AGAIN + 1)`, so this number alone decides how close to a
/// corner anything is read at all: nine reads a tenth to nine tenths of a side and leaves the
/// outer tenths blind, which is exactly where a bow is worst and where Julian's page kept its
/// desk (2026-08-24). Twenty-nine reads a thirtieth to twenty-nine thirtieths. Raising this
/// while [`MOST_INWARD`] was still ten changed nothing at all - the readings found the corner
/// and the cap refused to go there - which is why the two must be swept together and why a
/// result from moving one of them alone means nothing.
///
/// It is not free and it is not a knob to keep turning: it multiplies the full sized reads,
/// the most expensive part of the search, by more than three. At twenty-nine and sixty the
/// twelve gain nothing further from more places (a hundred was measured and moved no corner).
///
/// [`MOST_INWARD`]: super::where_a_side_goes::MOST_INWARD
pub(super) const PLACES_READ_AGAIN: usize = 29;

/// How far either way the true edge is looked for, in pixels of the photograph. Sixty,
/// because a real sheet is not flat: on `extra_4`, a letter with a fold in it, the left
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

/// How far inward every side is put on top of the reading it is laid on, in pixels of the
/// photograph.
///
/// A hair, because the side sits on a measured edge rather than on a guess, and inward
/// rather than outward because a sliver of desk in the page bends the straightening while a
/// hair off the white margin costs nothing. Measured with `examples/edge_error.rs` before
/// task 36, when a side was still laid on the middle of its readings: at this value the
/// middle of all four sides of all twelve real photos read 0 to +3 pixels inside the paper,
/// at 1.0 three middles read a pixel outside it, and at 2.0 one read +4. Those middles read
/// +2 to +12 today - that is [`MOST_INWARD`] and [`MOST_LEAN`] moving the side, not this
/// hair, so do not re-measure the three numbers above and conclude the hair drifted.
///
/// Do not raise it to cover a bowed edge. That was tried at 6.0, on the reading that six
/// pixels would put the worst place of a left or right side inside the paper too: it does,
/// and it then cuts six pixels off a *flat* sheet as well, which two synthetic tests caught.
/// A bow is not the same on two sides and it is not the same on two photos, so it is
/// covered by [`MOST_INWARD`], which is what each side bows by, and never by a constant
/// every side pays.
///
/// [`MOST_INWARD`]: super::where_a_side_goes::MOST_INWARD
/// [`MOST_LEAN`]: super::where_a_side_goes::MOST_LEAN
pub(super) const INWARD_HAIR: f32 = 1.5;

/// Moves each fitted side onto the edge of the paper as the full sized photo shows it.
///
/// The rough fit runs on a 400 pixel wide copy, where one pixel is about eight pixels of
/// the photo, so its four sides are only ever right to within a pixel or two of that
/// copy - and the miss is not the same on all four, which is why no single bias can take
/// it out. So each side is read again where it matters: at [`PLACES_READ_AGAIN`] places
/// along it the photo is walked across the side, the steepest step from paper to table
/// is taken as the true edge, and the whole side is then TURNED and moved onto those
/// readings: [`how_the_side_leans`] says how much further one end of it goes than the other,
/// and [`where_the_side_goes`] then lays the turned side on its innermost reading.
///
/// The slope does NOT stay as the rough fit found it, and that was the last thing wrong here.
/// A slope measured on a 400 pixel wide copy is only right to a pixel of that copy, which is
/// eight of the photo, so a side that keeps it has one number to satisfy nine readings.
/// `sheen_7`'s bottom side read -10, -5, -1, 0, +1, +3, +4, +6, +10 from one end to the other:
/// that is a slope off by a pixel of the copy and not a bow, and no placing of such a side can
/// sit on the edge at both of its ends. Turned, it reads +7 in the middle and +2 at worst.
///
/// Only these few lines of the photo are ever read - a page is a few thousand pixels,
/// not the twelve million of the picture, which the phone has no room for.
///
/// Where a place finds no clear step it is left out, and where fewer than
/// [`FEWEST_PLACES_READ_AGAIN`] places answer the side is returned untouched: an invented
/// edge cuts writing off the page. Two numbers now come off as few as five readings, so a
/// turn can be a guess about a side rather than a measurement of it, and [`MOST_LEAN`] is the
/// only thing bounding that guess.
///
/// ponytail: the side stays STRAIGHT, and a straight line has two numbers to spend where a
/// bowed edge wants a curve. So an edge whose readings still spread further than
/// [`MOST_INWARD`] after the best turn keeps a wedge of desk near one end, and no placing or
/// turning of a straight line takes it out. Nine of the forty-eight sides of the twelve real
/// photos are like that, -5 to -57 pixels, and every one of them is a LEFT or a RIGHT side: a
/// page's top and bottom now read no worse than -1. Two more read far outside the paper and are
/// not sides at all but the ruler misreading a mark or a corner. `TASKS.md` 36 names all eleven
/// and carries the walk along the side that tells the two kinds apart; the header of
/// `examples/edge_error.rs` carries the count.
///
/// The way up is four sides that may bend, or a corner of its own for each end - both more than
/// a constant. How far a straight side could ever get was worked out in the first two rounds,
/// but on the readings of a raster the app never processes, so those figures said nothing about
/// this code and are gone.
///
/// Do not revive picking the lean from the middle of the pairwise slopes of the readings. It
/// was measured this round and it made two pages WORSE - `sheen_3`'s left side -6 to -14 and
/// `sheen_5`'s left -7 to -21 - because a side humped in its middle has no honest lean and
/// that fit invents one. It is not rejected for aiming at a misread place: this code does that
/// too, see [`how_the_side_leans`].
///
/// [`MOST_INWARD`]: super::where_a_side_goes::MOST_INWARD
/// [`MOST_LEAN`]: super::where_a_side_goes::MOST_LEAN
pub(super) fn sides_read_again_in_the_photo(
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

        let span = last - first;
        let mut misses = Vec::new();
        for place in 1..=PLACES_READ_AGAIN {
            // How far down the side this place sits, nought at the first corner and one at
            // the second, so that a lean means the same on a short side and on a long one.
            let part = place as f32 / (PLACES_READ_AGAIN + 1) as f32;
            let along = first + span * part;
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
                misses.push((part, miss));
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
        // How much of the lean falls on one pixel along the side. A side shorter than a
        // pixel of the shrunk copy has no two ends to lean between, and dividing by its
        // span is what would break.
        let (lean, turn) = if span.abs() >= 1.0 {
            let lean = how_the_side_leans(&misses);
            (lean, lean / span)
        } else {
            (0.0, 0.0)
        };
        let mut levelled: Vec<f32> = misses
            .iter()
            .map(|&(part, miss)| miss - lean * part)
            .collect();
        match where_the_side_goes(&mut levelled) {
            // The turn swings the side about its first corner and the place slides the
            // whole of it across, both in pixels of the photograph, so both are divided by
            // `scale` to land in the shrunk copy the sides live in.
            Some(place) => Side {
                slope: side.slope + outward * turn / scale,
                offset: side.offset + outward * (place - INWARD_HAIR - turn * first) / scale,
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
        // The same grey the rest of the search works in.
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
