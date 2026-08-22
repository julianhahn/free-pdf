//! FreePDF core engine.
//!
//! All image and PDF logic lives here. Clients (Windows, iOS, Android) only
//! load an image, call one tool at a time, and finally ask for a PDF.

pub mod deskew;
pub mod paper;
pub mod pdf;
pub mod tools;

// Private on purpose. Rebuilding a JPEG's Huffman tables is a detail of how a
// page is written, not a tool a client picks: nothing outside `pdf.rs` has a
// reason to call it, and every name in the `pub use` block below is a name the C
// wrapper has to keep working for good.
mod rehuff;

pub use deskew::{deskew, straighten, suggest_straightening};
pub use paper::{find_paper, Paper, Point, Rect};
pub use pdf::{images_to_pdf, pages_to_pdf, save_page, PageQuality};
pub use tools::{
    apply_levels, crop, fit_within, rotate, sharpen, suggest_levels, to_grayscale, Levels,
};

// `PageQuality` and `fit_within` are two names, and a public name is a promise
// kept for good. They earn it because a steerable page size cannot be built
// anywhere else: the quality is the number `save_page`'s encoder is handed, and
// the resampling filter that goes with it cannot even be named outside this
// crate, which is the one crate that depends on `image`. A client left to shrink
// the page itself reaches for the cheapest call it has and gets the box filter,
// which measured worse pictures for more bytes (`tools::fit_within`).

/// Re-exported so clients do not have to depend on the `image` crate themselves,
/// and can never end up with a different version of it than the engine.
pub use image::DynamicImage;

use std::path::Path;

/// Loads a photo or scan from the local file system.
///
/// The camera rotation stored in the file's metadata is applied to the pixels.
/// Phones write that rotation as a tag instead of turning the image, so without
/// this a photo taken sideways stays sideways all the way into the PDF.
///
/// The format is taken from the file contents, not from the file name, so a
/// photo saved as `.jpg` that is really a PNG still loads.
///
/// - Parameters:
///   path: Path to the image file (JPEG or PNG).
/// - Returns:
///   The decoded image, upright, or a message describing what went wrong.
pub fn load_image(path: &Path) -> Result<DynamicImage, String> {
    use image::ImageDecoder;

    if !path.exists() {
        return Err(format!("No file found at {}.", path.display()));
    }

    let describe = |e: image::ImageError| match e {
        image::ImageError::Unsupported(_) => {
            format!("{} is not a supported image format.", path.display())
        }
        other => format!("Failed to read {}: {}", path.display(), other),
    };

    let mut decoder = image::ImageReader::open(path)
        .map_err(|e| format!("Failed to open {}: {}", path.display(), e))?
        .with_guessed_format()
        .map_err(|e| format!("Failed to read {}: {}", path.display(), e))?
        .into_decoder()
        .map_err(describe)?;

    let orientation = decoder.orientation().map_err(describe)?;
    let mut img = DynamicImage::from_decoder(decoder).map_err(describe)?;
    img.apply_orientation(orientation);

    Ok(img)
}
