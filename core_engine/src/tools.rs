//! The single-purpose tools the user applies by hand, one at a time.
//!
//! Every tool takes an image and returns a new one. Nothing is chained here on
//! purpose: the client decides the order and shows the result after each step,
//! which is the whole point of the manual workflow.

use crate::paper::{find_paper, Paper};
use image::DynamicImage;

/// Turns the image clockwise.
///
/// Quarter turns only. Straightening a photo by a few degrees needs pixel
/// interpolation and an opinion about the new borders, so that is its own tool
/// rather than a special case in here.
///
/// - Parameters:
///   img: The image to turn.
///   degrees: 0, 90, 180 or 270.
/// - Returns:
///   The turned image, or a message if the angle is not a quarter turn.
pub fn rotate(img: &DynamicImage, degrees: u32) -> Result<DynamicImage, String> {
    match degrees % 360 {
        0 => Ok(img.clone()),
        90 => Ok(img.rotate90()),
        180 => Ok(img.rotate180()),
        270 => Ok(img.rotate270()),
        _ => Err(format!(
            "Rotation must be 0, 90, 180 or 270 degrees, but was {degrees}."
        )),
    }
}

/// Drops the colour, keeping the brightness of every pixel.
///
/// Grey scans of text are smaller in the PDF and easier to read than colour
/// photos of paper.
pub fn to_grayscale(img: &DynamicImage) -> DynamicImage {
    img.grayscale()
}

/// Makes edges stand out, by adding back the difference between the image and a
/// blurred copy of itself. This is what every photo editor calls sharpness.
///
/// Sharpening cannot recover detail the camera did not capture. What it does is
/// make the detail that is there easier to see, at the price of a light halo
/// along strong edges. On a photographed document that trade is usually worth
/// it, because the edges are letters.
///
/// - Parameters:
///   img: The image to sharpen.
///   radius: How far the effect reaches, in pixels. Around 1 suits text.
///   threshold: How large a brightness difference has to be before it is
///   touched at all. Above zero this leaves paper grain and sensor noise alone.
/// - Returns:
///   The sharpened image, or a message if the radius is outside a useful range.
pub fn sharpen(img: &DynamicImage, radius: f32, threshold: i32) -> Result<DynamicImage, String> {
    if !(radius > 0.0 && radius <= 20.0) {
        return Err(format!(
            "The sharpening radius must be greater than 0 and at most 20 pixels, but was {radius}."
        ));
    }

    let sharpened = image::imageops::unsharpen(&img.to_rgb8(), radius, threshold);
    Ok(DynamicImage::ImageRgb8(sharpened))
}

/// The two ends of a brightness stretch, per colour channel.
///
/// `black` is the brightness that becomes fully black, `white` the one that
/// becomes fully white. Keeping the three channels apart is what removes a
/// colour cast: warm light lifts red more than blue, so red needs a higher
/// white end than blue to make the paper come out neutral.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Levels {
    pub black: [u8; 3],
    pub white: [u8; 3],
}

impl Levels {
    /// Levels that change nothing.
    pub fn unchanged() -> Self {
        Levels {
            black: [0; 3],
            white: [255; 3],
        }
    }

    /// Whether applying these levels would leave the image as it is.
    pub fn are_unchanged(&self) -> bool {
        *self == Self::unchanged()
    }
}

/// Below this distance between the two ends, a stretch would blow the image
/// apart rather than clean it up.
const SMALLEST_USEFUL_RANGE: u16 = 16;

/// Reads the image and proposes where the brightness stretch should start and
/// end, so that the paper comes out white and the writing black.
///
/// A photograph of a document has two humps in its brightness: a small one for
/// the ink and a wide one for the paper. The paper hump is wide because the
/// light across a sheet is never even. This looks for the lower edge of that
/// hump and puts the white end there, which is what pulls the whole sheet to
/// white instead of only its brightest corner.
///
/// The result is a **suggestion**. The client is meant to show it and let the
/// user move it, which is why measuring and applying are two functions.
///
/// If the image has no clear paper hump - a photo that is not a document, or a
/// blank sheet - the suggestion is to change nothing, rather than to guess.
///
/// Only the paper is measured, not the whole picture. On a photo the table can be
/// darker than the writing, and measuring across everything then puts the black
/// end on the table and leaves the writing grey. So the sheet is looked for first
/// and the numbers come from the pixels on it - not from the box around it, since
/// a sheet lying at an angle has table in the corners of its box.
pub fn suggest_levels(img: &DynamicImage) -> Levels {
    let rgb = img.to_rgb8();
    let paper = find_paper(img);
    let histograms = channel_histograms(&rgb, paper.as_ref());
    let mut levels = Levels::unchanged();

    for (channel, counts) in histograms.iter().enumerate() {
        let black = darkest_ink(counts);
        let white = paper_floor(counts);

        if u16::from(white).saturating_sub(u16::from(black)) >= SMALLEST_USEFUL_RANGE {
            levels.black[channel] = black;
            levels.white[channel] = white;
        }
    }

    levels
}

/// Stretches the brightness so that `black` becomes 0 and `white` becomes 255.
///
/// Everything darker than `black` is solid black afterwards and everything
/// brighter than `white` is solid white. That loss is the point: on a document
/// it turns the uneven grey of a photographed sheet into paper white, and the
/// shadow of the camera holder's hand into nothing.
///
/// A stretch this steep also multiplies whatever colour is in the image, because
/// it pulls the three channels apart by different amounts, so faint colour is
/// taken back out afterwards. See [`calm_faint_colour`] for why that is needed
/// rather than merely nice.
pub fn apply_levels(img: &DynamicImage, levels: Levels) -> DynamicImage {
    if levels.are_unchanged() {
        return img.clone();
    }

    let mut rgb = img.to_rgb8();
    let tables: Vec<[u8; 256]> = (0..3)
        .map(|c| stretch_table(levels.black[c], levels.white[c]))
        .collect();

    for pixel in rgb.pixels_mut() {
        for channel in 0..3 {
            pixel[channel] = tables[channel][pixel[channel] as usize];
        }
        calm_faint_colour(pixel);
    }

    DynamicImage::ImageRgb8(rgb)
}

/// Colour weaker than this was not meant to be there.
const FAINT_COLOUR: f32 = 0.20;
/// Colour this strong is part of the document: a red heading, a blue signature.
const REAL_COLOUR: f32 = 0.30;

/// Takes out colour too weak to have been meant, and leaves the rest alone.
///
/// A photographed sheet is usually lit by two lights at once - the lamp above it
/// and whatever comes in through the window - and the shadowed parts get more of
/// the cooler one. In the photo that is a difference of about two values out of
/// 255, invisible. The stretch multiplies each channel by a different amount,
/// around 1.7 to 2.0 on a real photo, and those two values become forty: the paper
/// comes out in pale pink and blue blotches, which is the one thing that still
/// gave these away as photographs.
///
/// The blotches are not made up. They are real information about the light in the
/// room, amplified until it is visible. On a document it is noise all the same,
/// because paper is white whatever light happened to fall on which part of it.
///
/// Weak against strong is what separates the two, and the gap is wide: a blotch
/// sits around 15% colour, a red heading around 70%, even a yellow highlighter
/// around 50%. So everything below [`FAINT_COLOUR`] goes fully neutral, everything
/// above [`REAL_COLOUR`] is untouched, and in between it fades.
fn calm_faint_colour(pixel: &mut image::Rgb<u8>) {
    let strongest = pixel[0].max(pixel[1]).max(pixel[2]);
    let weakest = pixel[0].min(pixel[1]).min(pixel[2]);
    if strongest == 0 {
        return;
    }

    let colourfulness = f32::from(strongest - weakest) / f32::from(strongest);
    let take_out =
        1.0 - ((colourfulness - FAINT_COLOUR) / (REAL_COLOUR - FAINT_COLOUR)).clamp(0.0, 1.0);
    if take_out <= 0.0 {
        return;
    }

    // Towards its own brightness rather than towards the average of the three, so
    // the pixel keeps how light it looks while losing its tint.
    let grey =
        0.299 * f32::from(pixel[0]) + 0.587 * f32::from(pixel[1]) + 0.114 * f32::from(pixel[2]);
    for channel in 0..3 {
        let value = f32::from(pixel[channel]);
        pixel[channel] = (value + (grey - value) * take_out)
            .round()
            .clamp(0.0, 255.0) as u8;
    }
}

/// The stretch worked out once per possible value instead of once per pixel.
fn stretch_table(black: u8, white: u8) -> [u8; 256] {
    let mut table = [0u8; 256];
    let span = f32::from(white) - f32::from(black);

    for (value, out) in table.iter_mut().enumerate() {
        let stretched = (value as f32 - f32::from(black)) / span * 255.0;
        *out = stretched.clamp(0.0, 255.0) as u8;
    }

    table
}

/// Counts how often every brightness turns up, per colour channel, over the paper
/// only - or over the whole image when no sheet was found.
fn channel_histograms(rgb: &image::RgbImage, paper: Option<&Paper>) -> [[u32; 256]; 3] {
    let mut counts = [[0u32; 256]; 3];

    for (x, y, pixel) in rgb.enumerate_pixels() {
        if paper.is_some_and(|sheet| !sheet.contains(x, y)) {
            continue;
        }
        for channel in 0..3 {
            counts[channel][pixel[channel] as usize] += 1;
        }
    }

    counts
}

/// The brightness of the darkest ink worth keeping: dark enough to be writing,
/// not so dark that a single sensor speck decides the black end.
fn darkest_ink(counts: &[u32; 256]) -> u8 {
    let total: u32 = counts.iter().sum();
    let ignore = total / 100; // the darkest one percent may be noise
    let mut seen = 0;

    for (value, count) in counts.iter().enumerate() {
        seen += count;
        if seen > ignore {
            return value as u8;
        }
    }

    0
}

/// The lower edge of the paper hump: start at the most common bright value and
/// walk down until the image runs out of paper.
fn paper_floor(counts: &[u32; 256]) -> u8 {
    let (peak, peak_count) = counts
        .iter()
        .enumerate()
        .skip(64) // below this it is ink or background, not paper
        .max_by_key(|(_, &count)| count)
        .map(|(value, &count)| (value, count))
        .unwrap_or((255, 0));

    let hump_edge = peak_count / 10;
    let mut floor = peak;
    while floor > 0 && counts[floor - 1] > hump_edge {
        floor -= 1;
    }

    floor as u8
}

/// Cuts the image down to the box the user drew, measured in pixels from the
/// top left corner.
///
/// A box that does not fit is an error instead of being clamped to the edge: a
/// silently shrunk crop looks like the tool ignored the user.
///
/// - Parameters:
///   img: The image to cut.
///   x, y: Top left corner of the box, in pixels.
///   width, height: Size of the box, in pixels.
/// - Returns:
///   The cut image, or a message if the box does not fit inside the image.
pub fn crop(
    img: &DynamicImage,
    x: u32,
    y: u32,
    width: u32,
    height: u32,
) -> Result<DynamicImage, String> {
    if width == 0 || height == 0 {
        return Err("The crop box must be wider and taller than zero pixels.".to_string());
    }

    // Checked addition: x + width can wrap around on u32 and would then pass a
    // plain "fits inside the image" comparison.
    let fits_horizontally = x
        .checked_add(width)
        .is_some_and(|right| right <= img.width());
    let fits_vertically = y
        .checked_add(height)
        .is_some_and(|bottom| bottom <= img.height());

    if !fits_horizontally || !fits_vertically {
        return Err(format!(
            "A {}x{} crop at ({}, {}) does not fit inside the {}x{} image.",
            width,
            height,
            x,
            y,
            img.width(),
            img.height()
        ));
    }

    Ok(img.crop_imm(x, y, width, height))
}
