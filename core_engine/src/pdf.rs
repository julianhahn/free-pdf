//! Stitching processed images into one PDF file.
//!
//! One image becomes one page. The page takes the orientation of the image, so
//! a photo held sideways gets a landscape page instead of a portrait page with
//! wide empty borders. Inside the page the image is scaled to fit and centred,
//! and its aspect ratio never changes.

use image::DynamicImage;
use printpdf::{
    ImageCompression, ImageOptimizationOptions, Mm, Op, PdfDocument, PdfPage, PdfSaveOptions, Pt,
    RawImage, RawImageData, RawImageFormat, XObjectTransform,
};
use std::path::Path;

/// A4, the short and the long edge in millimetres.
const A4_SHORT_MM: f32 = 210.0;
const A4_LONG_MM: f32 = 297.0;

/// JPEG quality of the images inside the PDF, from 0.0 to 1.0.
const JPEG_QUALITY: f32 = 0.85;

/// Writes the images as a single PDF, one page per image.
///
/// - Parameters:
///   images: The finished images, in page order.
///   out_path: Where to write the PDF. An existing file is overwritten.
/// - Returns:
///   Nothing on success, or a message describing what went wrong.
pub fn images_to_pdf(images: &[DynamicImage], out_path: &Path) -> Result<(), String> {
    if images.is_empty() {
        return Err("No images given, so the PDF would have no pages.".to_string());
    }

    let title = out_path
        .file_stem()
        .and_then(|stem| stem.to_str())
        .unwrap_or("FreePDF Document");
    let mut doc = PdfDocument::new(title);

    let pages: Vec<PdfPage> = images.iter().map(|img| build_page(&mut doc, img)).collect();

    let bytes = doc.with_pages(pages).save(&save_options(), &mut Vec::new());

    std::fs::write(out_path, bytes)
        .map_err(|e| format!("Failed to write the PDF to {}: {}", out_path.display(), e))
}

/// Builds one page holding one image, scaled to fit and centred.
fn build_page(doc: &mut PdfDocument, img: &DynamicImage) -> PdfPage {
    let (px_width, px_height) = (img.width() as f32, img.height() as f32);
    let (page_width_mm, page_height_mm) = page_size_for(px_width, px_height);
    let (page_width, page_height) = (page_width_mm.into_pt(), page_height_mm.into_pt());

    // A dpi of 72 makes one image pixel exactly one PDF point. The fit factor
    // below is then simply "how much the image has to shrink to fit the page".
    let fit = (page_width.0 / px_width).min(page_height.0 / px_height);
    let (drawn_width, drawn_height) = (px_width * fit, px_height * fit);

    let image_id = doc.add_image(&to_raw_image(img));
    let ops = vec![Op::UseXobject {
        id: image_id,
        transform: XObjectTransform {
            translate_x: Some(Pt((page_width.0 - drawn_width) / 2.0)),
            translate_y: Some(Pt((page_height.0 - drawn_height) / 2.0)),
            scale_x: Some(fit),
            scale_y: Some(fit),
            dpi: Some(72.0),
            ..Default::default()
        },
    }];

    PdfPage::new(page_width_mm, page_height_mm, ops)
}

/// A4, turned landscape when the image is wider than it is tall.
fn page_size_for(px_width: f32, px_height: f32) -> (Mm, Mm) {
    if px_width > px_height {
        (Mm(A4_LONG_MM), Mm(A4_SHORT_MM))
    } else {
        (Mm(A4_SHORT_MM), Mm(A4_LONG_MM))
    }
}

/// Hands the pixels over to printpdf.
///
/// `to_rgb8` drops an alpha channel if the image has one: a scan is opaque, and
/// a plain RGB buffer is what the JPEG stream in the PDF needs anyway.
fn to_raw_image(img: &DynamicImage) -> RawImage {
    let rgb = img.to_rgb8();
    let (width, height) = (rgb.width() as usize, rgb.height() as usize);

    RawImage {
        pixels: RawImageData::U8(rgb.into_raw()),
        width,
        height,
        data_format: RawImageFormat::RGB8,
        tag: Vec::new(),
    }
}

/// JPEG-compresses the embedded images. Without this printpdf stores raw
/// pixels, and one phone photo alone already makes a PDF of several megabytes.
fn save_options() -> PdfSaveOptions {
    PdfSaveOptions {
        image_optimization: Some(ImageOptimizationOptions {
            quality: Some(JPEG_QUALITY),
            // printpdf would otherwise shrink anything above 2 MB. Scans are
            // the whole product here, so they are never downscaled silently.
            max_image_size: None,
            // Left to itself, printpdf picks JPEG for colour but lossless LZW
            // for grey images, which made a greyed scan 3x *larger* than the
            // colour original (measured: 107 KB -> 347 KB). Photos of paper
            // compress badly without JPEG, grey or not.
            format: Some(ImageCompression::Jpeg),
            ..Default::default()
        }),
        ..Default::default()
    }
}
