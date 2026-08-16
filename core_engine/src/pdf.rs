//! Writing finished pages, and stitching them into one PDF file.
//!
//! One image becomes one page. The page takes the orientation of the image, so
//! a photo held sideways gets a landscape page instead of a portrait page with
//! wide empty borders. Inside the page the image is scaled to fit and centred,
//! and its aspect ratio never changes.
//!
//! There are two ways in, for two different callers. [`images_to_pdf`] takes the
//! images themselves, which is what a caller holding them all already has.
//! [`save_page`] and [`pages_to_pdf`] take one page at a time and then a list of
//! paths: a phone cannot hold forty decoded pages at once, so each page waits on
//! disk as a JPEG and is handed to the PDF without ever being decoded again.

use image::codecs::jpeg::{JpegDecoder, JpegEncoder};
use image::{ColorType, DynamicImage, ImageDecoder};
use printpdf::{
    DictItem, ExternalStream, ExternalXObject, ImageCompression, ImageOptimizationOptions, Mm, Op,
    PdfDocument, PdfPage, PdfSaveOptions, Pt, Px, RawImage, RawImageData, RawImageFormat,
    XObjectId, XObjectTransform,
};
use std::collections::BTreeMap;
use std::fs::{File, OpenOptions};
use std::io::{BufWriter, Cursor, Read, Seek, SeekFrom, Write};
use std::path::{Path, PathBuf};

/// A4, the short and the long edge in millimetres.
const A4_SHORT_MM: f32 = 210.0;
const A4_LONG_MM: f32 = 297.0;

/// JPEG quality of the images inside the PDF, from 0.0 to 1.0.
const JPEG_QUALITY: f32 = 0.85;

/// JPEG quality of a page written by [`save_page`], from 0 to 100.
///
/// The same 85 as [`JPEG_QUALITY`], in the scale this encoder counts in. The two
/// have to agree: a page written here is the stream the PDF embeds, so a
/// document built page by page must not come out visibly different from the
/// same document built by [`images_to_pdf`].
const PAGE_JPEG_QUALITY: u8 = 85;

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

    let mut doc = PdfDocument::new(title_of(out_path));

    let pages: Vec<PdfPage> = images.iter().map(|img| build_page(&mut doc, img)).collect();

    let bytes = doc.with_pages(pages).save(&save_options(), &mut Vec::new());

    std::fs::write(out_path, bytes)
        .map_err(|e| format!("Failed to write the PDF to {}: {}", out_path.display(), e))
}

/// Writes one finished page to disk, as the JPEG that will go into the PDF.
///
/// These bytes are the exact stream [`pages_to_pdf`] embeds, so a page is
/// compressed once instead of twice. The engine has to be the one writing it: a
/// PDF ignores the camera rotation tag, so a page written by the client's own
/// image code would land sideways, and a progressive JPEG cannot be embedded at
/// all.
///
/// The bytes go to `<path>.part` and are renamed only once they are on disk, so
/// a client that is killed mid-write finds either no file or a finished one -
/// never half a page under a name that says it is done.
///
/// - Parameters:
///   img: The finished page.
///   path: Where to write it. An existing file is overwritten.
/// - Returns:
///   Nothing on success, or a message naming the file and what went wrong.
pub fn save_page(img: &DynamicImage, path: &Path) -> Result<(), String> {
    // JPEG takes 8-bit grey or 8-bit RGB and nothing else. Grey stays grey, so a
    // page the user greyed keeps its smaller size instead of being blown back up
    // to three channels.
    let converted;
    let src = match img {
        DynamicImage::ImageLuma8(_) | DynamicImage::ImageRgb8(_) => img,
        other => {
            converted = DynamicImage::ImageRgb8(other.to_rgb8());
            &converted
        }
    };

    let mut jpeg = Vec::new();
    src.write_with_encoder(JpegEncoder::new_with_quality(&mut jpeg, PAGE_JPEG_QUALITY))
        .map_err(|e| format!("Failed to encode the page for {}: {}", path.display(), e))?;

    let part = path.with_extension("part");
    let mut file = File::create(&part).map_err(|e| failed(&part, e))?;
    file.write_all(&jpeg).map_err(|e| failed(&part, e))?;
    file.sync_all().map_err(|e| failed(&part, e))?;
    std::fs::rename(&part, path).map_err(|e| failed(path, e))
}

/// Writes the page files as a single PDF, one page per file, in the order given.
///
/// Each file's JPEG header is read for its size and whether it is grey, and the
/// bytes themselves go into the PDF untouched - no page is ever decoded. That is
/// what keeps a long scan inside a phone's memory: forty pages through
/// [`images_to_pdf`] peak around 3.1 GB, well past what iOS kills an app for,
/// and this way around 140 MB.
///
/// Only hand it files written by [`save_page`], for the reasons given there.
///
/// The PDF is written as `<out_path>.part` and renamed once it is whole, because
/// a client reads this file existing as "the scan is finished".
///
/// ponytail: the peak is twice the total size of the page JPEGs, because
/// printpdf holds every stream and lopdf clones it again when saving - about
/// 80 MB for forty pages. If a scan ever gets long enough to feel that, write the
/// page objects and the xref by hand (~120 lines): the peak drops to one page,
/// and the step becomes resumable.
///
/// - Parameters:
///   pages: The page files, in page order.
///   out_path: Where to write the PDF. An existing file is overwritten.
/// - Returns:
///   Nothing on success, or a message describing what went wrong.
pub fn pages_to_pdf(pages: &[PathBuf], out_path: &Path) -> Result<(), String> {
    // An empty list would otherwise write a nought-page PDF, which is exactly the
    // file a client takes as proof that the scan finished.
    if pages.is_empty() {
        return Err("No pages given, so the PDF would have no pages.".to_string());
    }

    let mut doc = PdfDocument::new(title_of(out_path));

    let mut built = Vec::with_capacity(pages.len());
    for page in pages {
        let jpeg = std::fs::read(page)
            .map_err(|e| format!("Failed to read the page {}: {}", page.display(), e))?;
        let (width, height, grey) = jpeg_shape(&jpeg)
            .map_err(|e| format!("{} could not be read as a page: {}", page.display(), e))?;
        built.push(jpeg_page(&mut doc, jpeg, width, height, grey));
    }

    let part = out_path.with_extension("part");
    // Opened for reading as well as writing: the %%EOF check below reads the file
    // back, and a write-only handle fails that with "Bad file descriptor".
    let file = OpenOptions::new()
        .read(true)
        .write(true)
        .create(true)
        .truncate(true)
        .open(&part)
        .map_err(|e| failed(&part, e))?;
    let mut writer = BufWriter::new(file);
    doc.with_pages(built)
        .save_writer(&mut writer, &PdfSaveOptions::default(), &mut Vec::new());
    let mut file = writer
        .into_inner()
        .map_err(|e| failed(&part, e.into_error()))?;
    file.flush().map_err(|e| failed(&part, e))?;

    // printpdf's save_writer returns nothing and drops write errors, so this is
    // the only place a full disk can still be caught. Every PDF ends in "%%EOF",
    // so a file without it was cut off, and renaming that into place would tell
    // the client a half-written scan is finished.
    let mut tail = [0u8; 5];
    file.seek(SeekFrom::End(-5)).map_err(|e| failed(&part, e))?;
    file.read_exact(&mut tail).map_err(|e| failed(&part, e))?;
    if &tail != b"%%EOF" {
        return Err(format!(
            "The PDF was cut off while writing {}.",
            part.display()
        ));
    }

    file.sync_all().map_err(|e| failed(&part, e))?;
    std::fs::rename(&part, out_path).map_err(|e| failed(out_path, e))
}

/// The name the document carries inside itself: the file it is being written to,
/// without its extension. Both ways into a PDF name it the same way, so the two
/// cannot drift apart. A path with no readable stem falls back to a name rather
/// than to nothing, because a reader shows this in its title bar.
fn title_of(out_path: &Path) -> &str {
    out_path
        .file_stem()
        .and_then(|stem| stem.to_str())
        .unwrap_or("FreePDF Document")
}

/// One shape for every write error, because the sentence goes on screen as it is.
/// No full stop: the cause ends the sentence.
fn failed(path: &Path, e: std::io::Error) -> String {
    format!("Failed to write {}: {}", path.display(), e)
}

/// Width, height, and whether the JPEG is grey, read from its header.
///
/// Building the decoder reads the header and stops there, so no pixel of the page
/// is ever touched - which is the whole point of the path-based PDF.
fn jpeg_shape(jpeg: &[u8]) -> Result<(usize, usize, bool), String> {
    let decoder = JpegDecoder::new(Cursor::new(jpeg)).map_err(|e| e.to_string())?;
    let (width, height) = decoder.dimensions();

    Ok((
        width as usize,
        height as usize,
        decoder.color_type() == ColorType::L8,
    ))
}

/// Adds one JPEG to the document exactly as it is, and builds its page.
///
/// The image object is written by hand because printpdf's own image type can only
/// hold decoded pixels. `/DCTDecode` is what tells a reader the stream is a JPEG,
/// and `BitsPerComponent` is 8 for every JPEG this engine writes.
fn jpeg_page(
    doc: &mut PdfDocument,
    jpeg: Vec<u8>,
    width: usize,
    height: usize,
    grey: bool,
) -> PdfPage {
    let colour_space = if grey {
        b"DeviceGray".to_vec()
    } else {
        b"DeviceRGB".to_vec()
    };
    let dict = BTreeMap::from([
        ("Type".to_string(), DictItem::Name(b"XObject".to_vec())),
        ("Subtype".to_string(), DictItem::Name(b"Image".to_vec())),
        ("Width".to_string(), DictItem::Int(width as i64)),
        ("Height".to_string(), DictItem::Int(height as i64)),
        ("BitsPerComponent".to_string(), DictItem::Int(8)),
        ("ColorSpace".to_string(), DictItem::Name(colour_space)),
        ("Filter".to_string(), DictItem::Name(b"DCTDecode".to_vec())),
    ]);

    let id = doc.add_xobject(&ExternalXObject {
        // compress: false - the bytes are already JPEG. Deflating them again
        // would contradict the /Filter and produce a file no reader accepts.
        // printpdf 0.12.5 never acts on the flag (its doc.compress() call is
        // commented out), so flipping it changes nothing today. It says what is
        // meant, and it is what keeps this right when printpdf wires it up.
        stream: ExternalStream {
            dict,
            content: jpeg,
            compress: false,
        },
        width: Some(Px(width)),
        height: Some(Px(height)),
        dpi: None,
    });

    place(id, width as f32, height as f32)
}

/// Builds one page holding one image, scaled to fit and centred.
fn build_page(doc: &mut PdfDocument, img: &DynamicImage) -> PdfPage {
    let image_id = doc.add_image(&to_raw_image(img));

    place(image_id, img.width() as f32, img.height() as f32)
}

/// Puts an image already added to the document on its own page, scaled to fit and
/// centred.
///
/// Both ways into a PDF end here - decoded pixels through [`build_page`], a JPEG
/// handed over untouched through [`jpeg_page`] - so the fit and centre maths
/// exists once and the two cannot drift apart.
fn place(id: XObjectId, px_width: f32, px_height: f32) -> PdfPage {
    let (page_width_mm, page_height_mm) = page_size_for(px_width, px_height);
    let (page_width, page_height) = (page_width_mm.into_pt(), page_height_mm.into_pt());

    // A dpi of 72 makes one image pixel exactly one PDF point. The fit factor
    // below is then simply "how much the image has to shrink to fit the page".
    let fit = (page_width.0 / px_width).min(page_height.0 / px_height);
    let (drawn_width, drawn_height) = (px_width * fit, px_height * fit);

    let ops = vec![Op::UseXobject {
        id,
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
