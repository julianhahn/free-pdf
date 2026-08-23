//! What one side does with its nine readings: how far it leans, and where it is laid.
//!
//! No image is touched here - it is arithmetic on plain slices of numbers, which is why
//! it can be read on its own. The readings come in as pixels of the photograph, so the
//! two caps in this file are pixels of the photograph too, and a number measured on the
//! 400 pixel wide copy means nothing to them.

use super::sides::middle_of;

/// How far past the middle of one side's own readings that side may be laid, in pixels of
/// the photograph.
///
/// What this buys is not a constant margin: it is whatever that one side bows by, so a flat
/// edge pays nothing at all and a bowed edge pays exactly its bow, up to here. That is why
/// the synthetic fixtures of a drawn straight sheet come through with corners unchanged to
/// the last decimal - every reading of such a side is the same, so its innermost is its
/// middle.
///
/// Ten, because a page may lose about a millimetre of its white margin and no more
/// (Julian, 2026-08-18). A millimetre of these photos is 11.7 pixels: the twelve pages come
/// out 2318 to 2590 pixels across, mean 2460, for the 210 mm of an A4 sheet. Ten plus
/// [`INWARD_HAIR`] is 11.5 pixels, a hair under that millimetre, and measured with
/// `examples/edge_error.rs` it is also the largest value at which no middle of any side of
/// the twelve reads past +12 - two of the forty-eight read exactly +12, `extra_4`'s right
/// side and `sheen_6`'s, so the ceiling is reached but not crowded.
///
/// It is also the only guard a misread place needs where the PLACING of a side is concerned. A
/// misread also swings the lean, and there the guard is [`MOST_LEAN`] - see
/// [`how_the_side_leans`], which measures how far one real misread swings one real side.
/// `extra_2`'s LEFT side reads 50 pixels out at one of its nine places. A walk of a hundred
/// and one places across it reads +0 to +15 at ninety-eight of them and dives at three single
/// places, -50, -55 and -43, whose neighbours read +11 to +14 - so those three are something
/// on the desk touching the sheet and not the sheet. Laid on the plain innermost reading that
/// page would be cut 55 pixels short; capped here it is cut the same 11.5 as every other
/// bowed side.
///
/// [`INWARD_HAIR`]: super::read_again::INWARD_HAIR
pub(super) const MOST_INWARD: f32 = 10.0;

/// How much further inward one end of a side may be moved than the other, in pixels of the
/// photograph across the whole side ([`how_the_side_leans`]).
///
/// Twelve, and NOT for the reason [`MOST_INWARD`] is ten. The +12 middle cannot bound a
/// lean at all: a side bowing further than [`MOST_INWARD`] has its middle pinned at
/// [`MOST_INWARD`] plus [`INWARD_HAIR`] whatever it leans, and for any other side a wider
/// search can only leave LESS bow, so a lower middle. What twelve rests on is the collapse
/// measured below at thirty-two, and nothing between thirteen and thirty-two was measured -
/// so a change here is a measuring job, not a knob to turn.
///
/// Nor is it a rare guard. Replayed on the nine readings of all forty-eight sides of the
/// twelve real photos, twenty-three of them came out sitting exactly on this cap and not one
/// wanted a lean of nought. A drawn flat sheet does, which is why the fixtures pass; a
/// photographed sheet never quite does. That replay used readings taken while the ruler still
/// loaded the photo lying on its side, so the count has not been taken again in the frame the
/// app runs - the claim it makes has not moved, the number in it is unchecked.
///
/// What a lean costs the MIDDLE of a side is nothing, because it re-aims the side instead of
/// pushing it in. Measured on the finished JPEGs of the twelve against the same code with no
/// lean at all, a page came out 13 pixels wider to 11 narrower and 17 taller to 5 shorter -
/// mean half a pixel narrower and four pixels taller - so on average a page keeps MORE of its
/// margin than before. The middle of all forty-eight sides averages +7.2 pixels today.
///
/// What it costs a CORNER is this whole number, and no reading covers a corner: the ruler
/// reads between a tenth and nine tenths of a side, so the deepest cut a lean makes lands
/// where nothing measures it. Adding the two caps gives 23 pixels, 2 mm of A4 - the whole
/// lean on top of the 11.5 that [`MOST_INWARD`] and [`INWARD_HAIR`] spend - but no corner can
/// reach that sum. The lean is fitted between a tenth and nine tenths of the side
/// ([`PLACES_READ_AGAIN`]), so a corner lies only a tenth of a span past the last reading, and
/// the deepest cut it can take is nine tenths of this cap plus [`INWARD_HAIR`], or
/// [`MOST_INWARD`] plus [`INWARD_HAIR`] plus a tenth of this cap: 12.3 to 12.7 pixels, 1.05 to
/// 1.09 mm. This constant is still the only thing bounding it. Measured on the corners
/// `backend-core-runner --deskew` prints, the twelve use about half that ceiling: against the
/// same code with no lean, the corner that moved furthest moved 11.7 pixels (`sheen_5`'s bottom
/// left) and the one cut deepest was cut 11.0 pixels - just under the millimetre - further into
/// the paper (`sheen_6`'s bottom right).
///
/// So do not raise it far to chase the last bowed sides. At thirty-two `extra_4`'s left side -
/// a letter with a fold in it - collapses from -25 to -60: the lean grows until the places read
/// the fold instead of the edge, and the reading is no more monotone in this constant than in
/// [`MOST_INWARD`].
///
/// [`INWARD_HAIR`]: super::read_again::INWARD_HAIR
/// [`PLACES_READ_AGAIN`]: super::read_again::PLACES_READ_AGAIN
pub(super) const MOST_LEAN: i32 = 12;

/// How much further inward the far end of one side is moved than its near end, in pixels of
/// the photograph, given the readings as `(how far down the side, how far off it)`.
///
/// The nine readings of a side are often one smooth run rather than a bow, `sheen_7`'s bottom
/// going -10, -5, -1, 0, +1, +3, +4, +6, +10 from end to end. That is not the paper bowing, it
/// is the rough fit's slope being off: it is measured on a 400 pixel wide copy where one pixel
/// is about eight of the photo, so a line straight to within a pixel there leans by eight here.
/// A side that may lean has two numbers for its nine readings instead of one, and the second
/// is what lets it sit on the edge along its whole length rather than only in its middle.
///
/// The lean chosen is the one that leaves the LEAST bow behind - the smallest gap between the
/// middle of the levelled readings and the innermost of them - because that gap is exactly what
/// [`where_the_side_goes`] then has to pay for out of [`MOST_INWARD`]. Whole pixels, because
/// the readings themselves are whole pixels of the photograph, and the smallest lean wins a
/// tie: a flat sheet reads the same at all nine places, wants no lean at all, and keeps the
/// corners the rough fit gave it.
///
/// ONE reading can decide the lean, and one does. The gap is measured to the INNERMOST reading,
/// so a place that misreads far out of the paper pulls the whole line towards itself. On
/// `extra_2`'s left side, one of whose nine places lands on the dark mark `TASKS.md` 36 proves
/// is not the sheet, the lean comes out at the cap, -12, with that place in and +7 without it:
/// nineteen pixels of swing at the far corner, and the end furthest from the mark goes from
/// +1.5 to -0.1, back onto the paper's edge. Only [`MOST_LEAN`] and the cap in [`where_the_side_goes`] hold it there.
///
/// ponytail: that gap IS the worst column of `examples/edge_error.rs`, read at the same nine
/// places, so the ruler cannot check this independently - it agrees by construction. What checks
/// a lean from outside is where the four corners end up, which `backend-core-runner --deskew`
/// prints, and nothing in `tests/` reaches it: a drawn sheet is straight, so its lean is nought.
/// The way up is a fixture with one edge bowed, asserting the corner follows it and the middle
/// of the side moves no further than [`MOST_INWARD`].
pub(super) fn how_the_side_leans(readings: &[(f32, f32)]) -> f32 {
    let bow_at = |lean: f32| -> Option<f32> {
        let mut levelled: Vec<f32> = readings
            .iter()
            .map(|&(part, miss)| miss - lean * part)
            .collect();
        let innermost = levelled.iter().copied().reduce(f32::min)?;

        Some(middle_of(&mut levelled)? - innermost)
    };

    // Outward from nothing, so that of two leans leaving the same bow the smaller is kept:
    // the corners move less, and a corner is the part no reading covers.
    let mut best = (f32::INFINITY, 0.0);
    for step in 0..=MOST_LEAN {
        for lean in [step as f32, -(step as f32)] {
            if let Some(bow) = bow_at(lean) {
                if bow < best.0 {
                    best = (bow, lean);
                }
            }
        }
    }

    best.1
}

/// Which of one side's readings that side is laid on, in pixels of the photograph. A
/// reading further out means the side stands further inside the paper.
///
/// The readings handed in are LEVELLED - each one less what the side's lean already gives it
/// at that place ([`how_the_side_leans`]) - so this only has to answer where the levelled side
/// sits, and each of the two questions stays one line of arithmetic.
///
/// The middle of them was the wrong answer, and wrong by definition: half the places of a
/// side end up outside the paper, and a place outside the paper is a strip of desk in the
/// finished page. So the side goes on the INNERMOST reading, and no further in than
/// [`MOST_INWARD`] past the middle, so that one place reading nonsense can never eat the
/// page. A side bowing within that cap then has no measured place outside the paper at all;
/// one bowing further is laid at the cap and keeps the rest of its bow outside, which is the
/// `ponytail:` note on [`sides_read_again_in_the_photo`].
///
/// [`sides_read_again_in_the_photo`]: super::read_again::sides_read_again_in_the_photo
pub(super) fn where_the_side_goes(readings: &mut [f32]) -> Option<f32> {
    let innermost = readings.iter().copied().reduce(f32::min)?;

    Some(innermost.max(middle_of(readings)? - MOST_INWARD))
}
