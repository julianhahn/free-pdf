//! Measures how far the found corners miss the real edge of the sheet, in pixels of
//! the photograph - the number the phone shows as a strip of desk.
//!
//! Not a test and not shipped: a ruler. It loads the photo with `load_image`, the way the app
//! does, so the turn the phone wrote into the file is applied and the side names it prints are
//! the sides a page has on screen. It reads the edge in the FULL sized picture the same way the
//! search now does, and it is what `sides_read_again_in_the_photo` was judged with - keep it, or
//! the next change to that code has nothing to measure against.
//!
//! Positive means the side sits inside the paper, negative means outside it - desk left
//! in the page, which is the bug. Of the forty-eight sides of the twelve photos in
//! `test_images/phone`, thirty-three have no place outside the paper and thirty-seven are within
//! three pixels of it, and no middle reads past +12, which is the millimetre of margin a page
//! may lose. Eleven read worse than -3, every one of them a left or a right side; which of those
//! are this tool misreading rather than table is named in `TASKS.md` 36, with the walk along the
//! side that proves it.
//!
//! `runs_off_1.jpg` is not one of the twelve, its lower corners are where the paper leaves the
//! frame and not a fitted side.
//!
//! This ruler cannot check a side's LEAN, only its placing: `how_the_side_leans` fits the lean on
//! these same nine places, so the two agree by construction. What checks a lean from outside is
//! the four corners `backend-core-runner --deskew` prints.
//!
//!     cargo run --release --example edge_error -- test_images/phone/*.jpg

use core_engine::{find_paper, load_image, Point};
use std::path::Path;

/// How far either way the true edge is looked for, in pixels of the photograph.
const LOOK: i32 = 60;

fn main() {
    println!(
        "{:<16} {:>7} {:>7} {:>7} {:>7}",
        "photo", "left", "right", "top", "bottom"
    );
    for path in std::env::args().skip(1) {
        let Ok(image) = load_image(Path::new(&path)) else {
            continue;
        };
        let Some(paper) = find_paper(&image) else {
            println!("{:<16}  no sheet found", short(&path));
            continue;
        };
        let gray = image.to_luma8();
        let [top_left, top_right, bottom_right, bottom_left] = paper.corners();
        // Each side, as the two corners it runs between, and the direction that points
        // out of the sheet across it.
        let sides = [
            (top_left, bottom_left, (-1.0, 0.0)),
            (top_right, bottom_right, (1.0, 0.0)),
            (top_left, top_right, (0.0, -1.0)),
            (bottom_left, bottom_right, (0.0, 1.0)),
        ];
        print!("{:<16}", short(&path));
        for (from, to, outward) in sides {
            let mut misses = Vec::new();
            // Nine places along the side, the ends left out: a corner is where two
            // edges meet and neither is clean there.
            for step in 1..10 {
                let along = step as f32 / 10.0;
                let at = Point {
                    x: from.x + (to.x - from.x) * along,
                    y: from.y + (to.y - from.y) * along,
                };
                if let Some(miss) = miss_at(&gray, at, outward) {
                    misses.push(miss);
                }
            }
            // The WORST place along the side, not the middle of them: a straight side on
            // a bowed edge is outside the paper wherever it is worst, and that is the
            // strip of desk a person sees. The median hid exactly that.
            match (middle(&mut misses), worst(&mut misses)) {
                (Some(mid), Some(bad)) => print!(" {:>+7.0}/{:<5.0}", mid, bad),
                _ => print!(" {:>13}", "-"),
            }
        }
        println!();
    }
}

/// Where the real edge is, relative to the fitted side, by walking across it in the
/// full sized picture and taking the steepest step from paper to table.
fn miss_at(gray: &image::GrayImage, at: Point, outward: (f32, f32)) -> Option<f32> {
    let read = |offset: i32| -> Option<f32> {
        let x = at.x + outward.0 * offset as f32;
        let y = at.y + outward.1 * offset as f32;
        if x < 0.0 || y < 0.0 || x >= gray.width() as f32 || y >= gray.height() as f32 {
            return None;
        }
        Some(gray.get_pixel(x as u32, y as u32)[0] as f32)
    };
    let mut steepest = (0.0, 0);
    for offset in -LOOK..LOOK {
        // Over four pixels rather than one, so film grain and a letter's ink do not
        // out-shout the edge itself.
        let (Some(inside), Some(outside)) = (read(offset - 2), read(offset + 2)) else {
            continue;
        };
        let drop = inside - outside;
        if drop > steepest.0 {
            steepest = (drop, offset);
        }
    }
    // A real paper edge is a big step. Anything less is writing, or nothing at all.
    (steepest.0 >= 30.0).then_some(steepest.1 as f32)
}

fn worst(values: &mut [f32]) -> Option<f32> {
    values.sort_by(|a, b| a.partial_cmp(b).unwrap());
    values.first().copied()
}

fn middle(values: &mut [f32]) -> Option<f32> {
    values.sort_by(|a, b| a.partial_cmp(b).unwrap());
    (!values.is_empty()).then(|| values[values.len() / 2])
}

fn short(path: &str) -> String {
    path.rsplit('/').next().unwrap_or(path).to_string()
}
