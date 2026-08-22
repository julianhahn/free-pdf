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

use crate::rehuff;
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

/// JPEG quality of a page written at [`PageQuality::UNCHANGED`], from 0 to 100.
///
/// The same 85 as [`JPEG_QUALITY`], in the scale this encoder counts in. The two
/// agree at this one setting, and only here: a page written at 85 is the stream
/// the PDF embeds, so a document built page by page must not come out visibly
/// different from the same document built by [`images_to_pdf`]. A client that
/// asks for a smaller page hands [`save_page`] a lower number, and then the two
/// are meant to differ - so do not re-align them, and do not read a lower page
/// quality as a bug. [`images_to_pdf`] has no such setting: it is the runner's
/// path, and the runner has no page size to steer.
///
/// On top of the quality, a page written here also loses the bytes its own
/// Huffman tables save ([`crate::rehuff`]) - which changes the code words, not
/// one pixel. How much that is depends on the page: see [`save_page`].
const PAGE_JPEG_QUALITY: u8 = 85;

/// The [`PageQuality::longest_edge`] that means "keep every pixel".
///
/// Zero rather than a large number, so the do-nothing answer is one value a
/// client can write down and not a bound it has to guess.
const KEEP_EVERY_PIXEL: u32 = 0;

/// The quality range this encoder counts in. Outside it the encoder would either
/// be handed a number it does not understand or write a page nobody can read, so
/// [`save_page`] refuses instead of pulling the number back into range.
const QUALITY_RANGE: std::ops::RangeInclusive<u8> = 1..=100;

/// How small a written page should be: the JPEG quality, and the longest edge the
/// page may keep.
///
/// A struct rather than a bare number, because a bare `45` at a call site cannot
/// be found again - nobody can grep for it, and nobody reading the call knows
/// which of the two numbers it is. A struct rather than an enum of rung names
/// ("Small", "Smallest"), because the rungs and the numbers behind them are the
/// client's product decision: the names live on the screen the user reads and
/// must not freeze inside this file, where changing them would be an engine
/// change.
///
/// [`UNCHANGED`](PageQuality::UNCHANGED) is what the engine wrote before there
/// was a setting, and a page written with it is byte for byte the same page.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PageQuality {
    /// JPEG quality from 1 to 100. Higher is a bigger, better looking page.
    pub jpeg_quality: u8,
    /// The longest edge the page may keep, in pixels, or zero to keep every
    /// pixel. [`save_page`] refuses anything else here; see its doc comment for
    /// why the resampling is the client's step and not this one's.
    pub longest_edge: u32,
}

impl PageQuality {
    /// Today's page: quality 85, every pixel kept.
    ///
    /// A page written with this is byte for byte the page the engine wrote
    /// before the setting existed, which is what lets a client offer a smaller
    /// page without changing the one it already ships.
    pub const UNCHANGED: PageQuality = PageQuality {
        jpeg_quality: PAGE_JPEG_QUALITY,
        longest_edge: KEEP_EVERY_PIXEL,
    };
}

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
/// image code would land sideways, and a client's encoder may well write a
/// progressive JPEG. A progressive page does in fact go into the PDF and render
/// (measured: byte for byte through [`pages_to_pdf`], and poppler draws it to the
/// same picture), but `/DCTDecode` is specified around baseline JPEG, progressive
/// has a long history of failing in real readers, and nobody here can test
/// Apple's PDFKit. So the engine writes baseline and does not find out.
///
/// The page's Huffman tables are then rebuilt from the page's own symbol counts
/// ([`crate::rehuff`]). That is free: the quantised coefficients are copied over
/// untouched, so the file decodes to the same pixels, and the page comes out
/// smaller because `image`'s encoder writes the fixed example tables out of the
/// JPEG standard's Annex K instead of tables that fit this page.
///
/// How much smaller depends on what is on the page, and the spread is wide, so
/// no single figure is honest: measured about 6% on a dense page of small text
/// (four probes on photographed text pages: 5.1%, 7.7 to 8.9%, 8.1%, 8.9%), 2.5
/// to 5.0% on grey text, about 16% on grainy paper or a page with a photograph
/// on it, and up to 28% over a mixed scan of forty pages. The share grows the
/// noisier the page and the lower the quality (42 to 44% at quality 30), and a
/// document scanner's usual page is text - so expect the small end. The PDF
/// shrinks by whatever share the pages did, and so does [`pages_to_pdf`]'s peak
/// memory, which is about twice the total size of the page streams.
///
/// `quality.longest_edge` is refused unless it is zero, rather than ignored: an
/// ignored field is a lie about what the call did. Resampling has to happen
/// earlier in the chain, where the client's own size cap already is, for three
/// measured reasons. It would pay `sharpen`'s full peak - 234 MB at 3000 px
/// against 116 MB at 1754 px - because sharpening has already run by the time a
/// page is written. It would blur away the sharpening that was just paid for.
/// And a crop is documented as fractions of the image *after* the cap, so moving
/// the cap moves what every stored crop box means. Shrink with
/// [`crate::fit_within`] before sharpening and leave this field at zero.
///
/// The bytes go to `<path>.part` and are renamed only once they are on disk, so
/// a client that is killed mid-write finds either no file or a finished one -
/// never half a page under a name that says it is done.
///
/// - Parameters:
///   img: The finished page.
///   path: Where to write it. An existing file is overwritten.
///   quality: How small the page should be. [`PageQuality::UNCHANGED`] writes
///   the page the engine has always written, byte for byte.
/// - Returns:
///   Nothing on success, or a message naming the file and what went wrong - or
///   naming the quality, when it is outside 1 to 100 or asks for a resampling
///   this step cannot do.
pub fn save_page(img: &DynamicImage, path: &Path, quality: PageQuality) -> Result<(), String> {
    if !QUALITY_RANGE.contains(&quality.jpeg_quality) {
        return Err(format!(
            "The page quality must be between {} and {}, but was {}.",
            QUALITY_RANGE.start(),
            QUALITY_RANGE.end(),
            quality.jpeg_quality
        ));
    }

    if quality.longest_edge != KEEP_EVERY_PIXEL {
        return Err(format!(
            "The page cannot be shrunk to {} pixels while it is written, because it is already \
             sharpened by then. Shrink it before sharpening and leave the longest edge at {}.",
            quality.longest_edge, KEEP_EVERY_PIXEL
        ));
    }

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
    src.write_with_encoder(JpegEncoder::new_with_quality(
        &mut jpeg,
        quality.jpeg_quality,
    ))
    .map_err(|e| format!("Failed to encode the page for {}: {}", path.display(), e))?;

    // Smaller by about 6% on a text page and up to 28% over a mixed scan, same
    // pixels either way. `unwrap_or` and never `unwrap`: a JPEG
    // the recoder refuses - a restart marker, a progressive scan, anything it did
    // not expect - keeps its original bytes. So this call cannot fail, a page is
    // never lost, and a scan is never left unfinishable by it.
    let jpeg = rehuff::rehuff(&jpeg).unwrap_or(jpeg);

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
///
/// This is [`images_to_pdf`]'s path only. On the [`pages_to_pdf`] path all four
/// `PdfSaveOptions` fields do nothing at all: `ExternalXObject` never reaches
/// `image_optimization` (printpdf/src/xobject.rs:54-88), and `optimize` only
/// wraps a `doc.compress()` call that is commented out. Measured: the same file
/// size at every setting, which is why that path passes the plain default.
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
