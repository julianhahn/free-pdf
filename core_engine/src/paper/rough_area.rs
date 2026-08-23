//! The rough area: where the sheet is, from brightness alone, on a 400 pixel wide copy
//! of the photo.
//!
//! This is the first of the six steps and the only one that can say `None`. It shrinks
//! the photo, splits it into bright and dark, floods in from the border to find the
//! background, and keeps the largest area that is not background. Everything here
//! counts in pixels of that shrunk copy, and the levels it reads off the picture are
//! what the next two steps ask a step in brightness to clear.

use super::Rect;
use image::DynamicImage;

/// The size the search runs at. Small on purpose: it is fast, and shrinking the
/// image averages single letters away, so a page of text reads as one bright
/// surface instead of hundreds of dark specks.
const WORK_WIDTH: u32 = 400;

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

/// What the picture itself says paper and table look like, and the three levels a
/// ray needs to tell them apart.
pub(super) struct EdgeLevels {
    /// The smallest step from paper to table worth stopping on.
    pub(super) step: f32,
    /// The inside of an edge has to be at least this bright, or it is not paper.
    pub(super) paper: f32,
    /// The outside of an edge has to be at most this bright, or it is not the table.
    pub(super) table: f32,
}

/// The levels, read off this picture rather than fixed: the middle brightness of the
/// rough area and the middle brightness of everything else. Nothing is fixed for the
/// same reason [`otsu_threshold`] exists - a dark wood desk and a grey desk want
/// different numbers and the picture says which.
///
/// Nothing comes back when there is no outside to compare with, or when the outside
/// is not darker than the inside. A picture that is all paper is the honest case of
/// that, and it wants the rough area as the answer, not a set of lines.
pub(super) fn paper_and_table_levels(
    small: &image::GrayImage,
    rough: &[bool],
) -> Option<EdgeLevels> {
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

pub(super) fn brightness_histogram(gray: &image::GrayImage) -> [u32; 256] {
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
pub(super) fn otsu_threshold(counts: &[u32; 256]) -> u8 {
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
pub(super) fn dark_area_reaching_the_border(bright: &[bool], width: u32, height: u32) -> Vec<bool> {
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
pub(super) fn largest_blob(
    inside: &[bool],
    width: u32,
    height: u32,
) -> Option<(u32, Rect, Vec<bool>)> {
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
pub(super) fn scale_up(
    sheet: Rect,
    width: u32,
    height: u32,
    image_width: u32,
    image_height: u32,
) -> Rect {
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
