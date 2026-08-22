//! Checks on the engine's public surface.
//!
//! The PDF tests read the written file back with a PDF parser instead of only
//! looking at the byte count: a file that starts with "%PDF" can still be
//! broken, and this is the part a client cannot work around.

use core_engine::{
    apply_levels, crop, deskew, find_paper, images_to_pdf, load_image, pages_to_pdf, rotate,
    save_page, sharpen, straighten, suggest_levels, suggest_straightening, to_grayscale,
    DynamicImage, Levels,
};
use image::codecs::jpeg::JpegEncoder;
use image::{ColorType, Rgb, RgbImage};
use std::ops::Range;
use std::path::PathBuf;

/// A gradient, not one flat colour: a flat image compresses to almost nothing
/// and would still look fine if the pixel buffer were handed over wrongly.
fn test_image(width: u32, height: u32) -> DynamicImage {
    let mut img = RgbImage::new(width, height);
    for (x, y, pixel) in img.enumerate_pixels_mut() {
        *pixel = Rgb([(x % 256) as u8, (y % 256) as u8, 128]);
    }
    DynamicImage::ImageRgb8(img)
}

/// Every test writes into its own file, so a failing test cannot break another.
fn temp_path(name: &str) -> PathBuf {
    let dir = std::env::temp_dir().join("core_engine_tests");
    std::fs::create_dir_all(&dir).expect("could not create the temp directory");
    dir.join(name)
}

fn parse_pdf(bytes: &[u8]) -> printpdf::PdfDocument {
    printpdf::PdfDocument::parse(bytes, &Default::default(), &mut Vec::new())
        .expect("the PDF the engine just wrote does not parse")
}

#[test]
fn writes_one_page_per_image() {
    let out = temp_path("three_pages.pdf");
    let images = vec![
        test_image(200, 300),
        test_image(200, 300),
        test_image(200, 300),
    ];

    images_to_pdf(&images, &out).expect("writing the PDF failed");

    let bytes = std::fs::read(&out).expect("the PDF was not written");
    assert!(bytes.starts_with(b"%PDF-"), "the file is not a PDF");
    assert_eq!(parse_pdf(&bytes).pages.len(), 3);
}

#[test]
fn page_follows_the_image_orientation() {
    let out = temp_path("orientation.pdf");
    // Page 1 upright, page 2 on its side.
    let images = vec![test_image(200, 300), test_image(300, 200)];

    images_to_pdf(&images, &out).expect("writing the PDF failed");

    let doc = parse_pdf(&std::fs::read(&out).expect("the PDF was not written"));
    let portrait = &doc.pages[0].media_box;
    let landscape = &doc.pages[1].media_box;

    assert!(
        portrait.height.0 > portrait.width.0,
        "page 1 is not portrait"
    );
    assert!(
        landscape.width.0 > landscape.height.0,
        "page 2 is not landscape"
    );
}

#[test]
fn embedded_scans_are_compressed() {
    let out = temp_path("compressed.pdf");
    let image = test_image(1000, 1400);
    // Raw RGB of this image is 4.2 MB, so anything near that means the images
    // went into the PDF uncompressed.
    let raw_size = 1000 * 1400 * 3;

    images_to_pdf(&[image], &out).expect("writing the PDF failed");

    let written = std::fs::metadata(&out)
        .expect("the PDF was not written")
        .len();
    assert!(
        written < raw_size / 4,
        "the PDF is {written} bytes, the raw pixels are {raw_size} - not compressed"
    );
}

#[test]
fn grayscale_does_not_grow_the_pdf() {
    // Left to itself printpdf compresses grey images losslessly, which made a
    // greyed scan three times larger than the colour original. Dropping the
    // colour must never cost size, that is what the tool is for.
    let colour_out = temp_path("colour.pdf");
    let grey_out = temp_path("grey.pdf");
    let image = test_image(800, 1000);

    images_to_pdf(std::slice::from_ref(&image), &colour_out)
        .expect("writing the colour PDF failed");
    images_to_pdf(&[to_grayscale(&image)], &grey_out).expect("writing the grey PDF failed");

    let colour_size = std::fs::metadata(&colour_out).expect("no colour PDF").len();
    let grey_size = std::fs::metadata(&grey_out).expect("no grey PDF").len();
    assert!(
        grey_size <= colour_size,
        "the grey PDF is {grey_size} bytes, the colour one only {colour_size}"
    );
}

#[test]
fn refuses_to_write_a_pdf_without_pages() {
    let out = temp_path("empty.pdf");
    let _ = std::fs::remove_file(&out);

    assert!(images_to_pdf(&[], &out).is_err());
    assert!(!out.exists(), "an empty PDF was written anyway");
}

/// Pseudo-random pixels, because a page has to be able to *fail* the check that
/// it went into the PDF untouched.
///
/// A JPEG of a smooth picture survives being decoded and encoded again byte for
/// byte, so the same test on [`test_image`] passes on exactly the mistake it is
/// there to catch. Measured on one round trip: of this page's 3,034,201 bytes
/// 3,018,895 change, of a gradient's not one.
fn noise_page(width: u32, height: u32) -> DynamicImage {
    let mut img = RgbImage::new(width, height);
    // xorshift, so the picture is the same on every run without a dependency.
    let mut seed = 0x2545_F491_u32;
    for pixel in img.pixels_mut() {
        seed ^= seed << 13;
        seed ^= seed >> 17;
        seed ^= seed << 5;
        *pixel = Rgb([(seed >> 8) as u8, (seed >> 16) as u8, (seed >> 24) as u8]);
    }
    DynamicImage::ImageRgb8(img)
}

#[test]
fn page_files_go_into_the_pdf_without_being_decoded() {
    let dir = temp_path("pages");
    std::fs::create_dir_all(&dir).expect("could not create the page directory");
    let (mut pages, mut jpeg_bytes) = (Vec::new(), 0u64);
    for n in 0..12 {
        // Page 0 is the one read back byte for byte below. Page 11 is grey,
        // which is the other colour space the PDF can be told about.
        let img = match n {
            0 => noise_page(400, 500),
            11 => to_grayscale(&test_image(1200, 1600)),
            _ => test_image(1200, 1600),
        };
        let page = dir.join(format!("{n:04}.jpg"));
        save_page(&img, &page).expect("writing the page failed");
        jpeg_bytes += std::fs::metadata(&page).expect("no page written").len();
        pages.push(page);
    }
    let out = temp_path("pages.pdf");

    pages_to_pdf(&pages, &out).expect("writing the PDF failed");

    let pdf = std::fs::read(&out).expect("the PDF was not written");
    let page = std::fs::read(&pages[0]).expect("no page written");
    // Find where the page sits by a slice out of its middle, then compare the
    // whole page against it. Not the first bytes: those are the header, and two
    // pages of the same size share their sizes and their quantisation tables, so
    // a header slice can match the wrong page. (`save_page` builds each page its
    // own Huffman tables, so the headers are no longer all the same the way they
    // once were - but they are still not what tells the pages apart.)
    let probe = &page[page.len() / 2..page.len() / 2 + 32];
    let found = pdf
        .windows(32)
        .position(|window| window == probe)
        .expect("the page is not in the PDF at all");
    assert_eq!(
        &pdf[found - page.len() / 2..found - page.len() / 2 + page.len()],
        &page[..],
        "the page was re-encoded on the way into the PDF"
    );
    assert!(
        pdf.windows(10).any(|window| window == b"DeviceGray"),
        "the grey page did not stay grey"
    );
    // 12 raw RGB pages would be 69 MB. What may sit on top of the pages
    // themselves is a few kilobytes of PDF structure, nothing more.
    let pdf_size = pdf.len() as u64;
    assert!(
        pdf_size > jpeg_bytes && pdf_size < jpeg_bytes + 16 * 1024,
        "the PDF is {pdf_size} bytes, its 12 pages together {jpeg_bytes}"
    );
    assert!(pdf.ends_with(b"%%EOF"), "the PDF was cut off");
    assert_eq!(parse_pdf(&pdf).pages.len(), 12);
}

/// How much smaller a written page has to be than the same image handed to the
/// encoder alone.
///
/// `save_page` rebuilds the page's Huffman tables from the page's own symbol
/// counts, which changes the code words and not one pixel. Measured on
/// `test_image(1200, 1600)`: 174,229 bytes become 136,069, so 21.90% goes. Real
/// photographed pages measure 27.98% over a 40 page scan and 6.47% on the hardest
/// one, a detailed grey page. The bound sits below the 21.90% rather than on it,
/// because the exact figure moves with the `image` crate's encoder; under this,
/// the rebuild has stopped happening.
const LEAST_PAGE_SAVING: f64 = 0.15;

#[test]
fn a_written_page_holds_the_same_pixels_in_fewer_bytes() {
    let path = temp_path("recoded_page.jpg");
    let image = test_image(1200, 1600);
    let mut by_hand = Vec::new();
    image
        .write_with_encoder(JpegEncoder::new_with_quality(&mut by_hand, 85))
        .expect("encoding the page by hand failed");

    save_page(&image, &path).expect("writing the page failed");

    let written = std::fs::read(&path).expect("no page written");
    let from_page = image::load_from_memory(&written).expect("the written page does not decode");
    let from_hand =
        image::load_from_memory(&by_hand).expect("the hand written page does not decode");
    assert_eq!(
        from_page.color(),
        from_hand.color(),
        "the written page came back in a different colour space"
    );
    assert_eq!(
        from_page.as_bytes(),
        from_hand.as_bytes(),
        "the written page decodes to different pixels than the same image at quality 85"
    );
    let saved = 1.0 - written.len() as f64 / by_hand.len() as f64;
    assert!(
        saved >= LEAST_PAGE_SAVING,
        "the page is {} bytes against the {} the encoder alone writes, only {:.2}% smaller",
        written.len(),
        by_hand.len(),
        saved * 100.0
    );
}

#[test]
fn a_greyed_page_stays_grey_all_the_way_into_the_pdf() {
    // If a written page came back as three channels, the PDF would say DeviceRGB
    // and a greyed scan would grow again - which is what to_grayscale is for.
    let page = temp_path("grey_page.jpg");
    let out = temp_path("grey_page.pdf");
    let grey = to_grayscale(&photographed_document());

    save_page(&grey, &page).expect("writing the page failed");
    pages_to_pdf(std::slice::from_ref(&page), &out).expect("writing the PDF failed");

    let written = std::fs::read(&page).expect("no page written");
    let decoded = image::load_from_memory(&written).expect("the written page does not decode");
    assert_eq!(
        decoded.color(),
        ColorType::L8,
        "the page came back as colour, so the PDF would call it DeviceRGB"
    );
    let pdf = std::fs::read(&out).expect("the PDF was not written");
    assert!(
        pdf.windows(10).any(|window| window == b"DeviceGray"),
        "the grey page did not reach the PDF as DeviceGray"
    );
    assert_eq!(parse_pdf(&pdf).pages.len(), 1);
}

#[test]
fn reports_a_missing_file_instead_of_panicking() {
    let missing = temp_path("does_not_exist.jpeg");
    let _ = std::fs::remove_file(&missing);

    assert!(load_image(&missing).is_err());
}

#[test]
fn reports_a_corrupted_file_instead_of_panicking() {
    let broken = temp_path("broken.jpeg");
    std::fs::write(&broken, b"this is not an image").expect("could not write the test file");

    assert!(load_image(&broken).is_err());
}

#[test]
fn a_quarter_turn_swaps_width_and_height() {
    let turned = rotate(&test_image(200, 300), 90).expect("rotating failed");

    assert_eq!((turned.width(), turned.height()), (300, 200));
}

#[test]
fn rotating_by_a_free_angle_is_refused() {
    // Straightening a scan by 3 degrees is a different tool, and quietly
    // rounding the angle to 0 would look like the button did nothing.
    assert!(rotate(&test_image(200, 300), 3).is_err());
}

#[test]
fn grayscale_leaves_no_colour_behind() {
    let grey = to_grayscale(&test_image(20, 20)).to_rgb8();

    let pixel = grey.get_pixel(7, 11);
    assert_eq!(pixel[0], pixel[1]);
    assert_eq!(pixel[1], pixel[2]);
}

#[test]
fn crop_cuts_to_the_requested_box() {
    let cut = crop(&test_image(200, 300), 10, 20, 50, 60).expect("cropping failed");

    assert_eq!((cut.width(), cut.height()), (50, 60));
}

#[test]
fn a_crop_that_does_not_fit_is_refused() {
    let img = test_image(200, 300);

    assert!(
        crop(&img, 180, 0, 50, 10).is_err(),
        "box runs past the right edge"
    );
    assert!(
        crop(&img, 0, 280, 10, 50).is_err(),
        "box runs past the bottom edge"
    );
    assert!(crop(&img, 0, 0, 0, 10).is_err(), "box has no width");
    // x + width overflows u32 and would pass an unchecked comparison.
    assert!(
        crop(&img, u32::MAX, 0, 10, 10).is_err(),
        "box overflows u32"
    );
}

/// A stand-in for a photographed document: paper that is grey rather than white
/// and warmer on one side, because the room light was, plus a block of writing.
fn photographed_document() -> DynamicImage {
    let mut img = RgbImage::new(200, 200);

    for (x, _y, pixel) in img.enumerate_pixels_mut() {
        // Paper, unevenly lit from 150 to 200, and warm: more red than blue.
        let brightness = 150 + (x / 4) as u8;
        *pixel = Rgb([brightness + 12, brightness, brightness - 10]);
    }
    for y in 80..120 {
        for x in 40..160 {
            img.put_pixel(x, y, Rgb([58, 55, 52])); // writing
        }
    }

    DynamicImage::ImageRgb8(img)
}

fn average_pixel(img: &DynamicImage, x: u32, y: u32) -> [u8; 3] {
    img.to_rgb8().get_pixel(x, y).0
}

#[test]
fn suggested_levels_separate_the_writing_from_the_paper() {
    let levels = suggest_levels(&photographed_document());

    for channel in 0..3 {
        assert!(
            levels.black[channel] > 40 && levels.black[channel] < 80,
            "the black end should land on the writing, but was {:?}",
            levels.black
        );
        assert!(
            levels.white[channel] > 100 && levels.white[channel] < 190,
            "the white end should land below the darkest paper, but was {:?}",
            levels.white
        );
    }

    // Warm light means more red than blue, so red needs the higher white end.
    assert!(
        levels.white[0] > levels.white[2],
        "the colour cast was not measured: {:?}",
        levels.white
    );
}

#[test]
fn levels_turn_the_paper_white_and_the_writing_black() {
    let document = photographed_document();

    let cleaned = apply_levels(&document, suggest_levels(&document));

    let paper = average_pixel(&cleaned, 10, 10);
    let writing = average_pixel(&cleaned, 100, 100);
    assert_eq!(paper, [255, 255, 255], "the paper did not come out white");
    assert!(
        writing.iter().all(|&channel| channel < 40),
        "the writing did not come out black: {writing:?}"
    );
}

#[test]
fn levels_remove_the_colour_cast_from_the_paper() {
    let document = photographed_document();
    let warmth_before = {
        let paper = average_pixel(&document, 10, 10);
        paper[0] as i16 - paper[2] as i16
    };

    let cleaned = apply_levels(&document, suggest_levels(&document));

    let paper = average_pixel(&cleaned, 10, 10);
    let warmth_after = paper[0] as i16 - paper[2] as i16;
    assert!(
        warmth_before > 15,
        "the test paper was not warm to begin with"
    );
    assert_eq!(warmth_after, 0, "the paper is still tinted: {paper:?}");
}

#[test]
fn an_image_without_paper_is_left_alone() {
    // A photo that is not a document has no paper hump to find. Guessing one
    // would wreck the picture, so the suggestion is to change nothing.
    let flat = DynamicImage::ImageRgb8(RgbImage::from_pixel(50, 50, Rgb([130, 130, 130])));

    let levels = suggest_levels(&flat);

    assert!(
        levels.are_unchanged(),
        "a flat image was stretched: {levels:?}"
    );
    assert_eq!(
        apply_levels(&flat, levels).to_rgb8().into_raw(),
        flat.to_rgb8().into_raw()
    );
}

#[test]
fn unchanged_levels_change_nothing() {
    let document = photographed_document();

    let untouched = apply_levels(&document, Levels::unchanged());

    assert_eq!(
        untouched.to_rgb8().into_raw(),
        document.to_rgb8().into_raw(),
        "applying neutral levels altered the image"
    );
}

#[test]
fn sharpening_makes_edges_stronger() {
    let document = photographed_document();
    let edge_before = edge_strength(&document);

    let sharpened = sharpen(&document, 1.0).expect("sharpening failed");

    assert!(
        edge_strength(&sharpened) > edge_before,
        "the edge did not get stronger: {} -> {}",
        edge_before,
        edge_strength(&sharpened)
    );
}

#[test]
fn a_useless_sharpening_radius_is_refused() {
    let document = photographed_document();

    assert!(sharpen(&document, 0.0).is_err(), "radius zero");
    assert!(sharpen(&document, -1.0).is_err(), "negative radius");
    assert!(sharpen(&document, 50.0).is_err(), "radius past any use");
}

/// How hard the brightness jumps across the top edge of the writing.
fn edge_strength(img: &DynamicImage) -> i32 {
    let rgb = img.to_rgb8();
    let above = rgb.get_pixel(100, 78)[0] as i32;
    let below = rgb.get_pixel(100, 82)[0] as i32;
    (above - below).abs()
}

/// A JPEG APP1 block holding nothing but "orientation: 6", which means the
/// camera was held so that the picture has to be turned a quarter turn to look
/// upright. Written by hand so the test needs no prepared photo on disk.
const EXIF_ROTATED_QUARTER_TURN: &[u8] = &[
    0xFF, 0xE1, 0x00, 0x22, // APP1, 34 bytes long including this length
    0x45, 0x78, 0x69, 0x66, 0x00, 0x00, // "Exif\0\0"
    0x4D, 0x4D, 0x00, 0x2A, 0x00, 0x00, 0x00, 0x08, // big endian, first tag at byte 8
    0x00, 0x01, // one tag follows
    0x01, 0x12, 0x00, 0x03, 0x00, 0x00, 0x00, 0x01, 0x00, 0x06, 0x00, 0x00, // orientation = 6
    0x00, 0x00, 0x00, 0x00, // no further tag block
];

#[test]
fn a_sideways_photo_is_turned_upright_when_loaded() {
    let path = temp_path("sideways.jpeg");
    let mut jpeg = Vec::new();
    test_image(40, 60)
        .write_to(
            &mut std::io::Cursor::new(&mut jpeg),
            image::ImageFormat::Jpeg,
        )
        .expect("could not encode the test photo");
    // The metadata block goes right behind the two start-of-image bytes.
    jpeg.splice(2..2, EXIF_ROTATED_QUARTER_TURN.iter().copied());
    std::fs::write(&path, &jpeg).expect("could not write the test photo");

    let loaded = load_image(&path).expect("loading the photo failed");

    assert_eq!(
        (loaded.width(), loaded.height()),
        (60, 40),
        "the camera rotation in the metadata was not applied"
    );
}

#[test]
fn loads_an_image_it_can_read() {
    let path = temp_path("readable.png");
    test_image(40, 60)
        .save(&path)
        .expect("could not write the test image");

    let loaded = load_image(&path).expect("loading the image failed");

    assert_eq!((loaded.width(), loaded.height()), (40, 60));
}

/// A photograph rather than a scan: a sheet on a dark table, its corners cut off
/// the way a sheet lying at an angle leaves table showing in the corners of its
/// box, plus a bright reflection off to one side.
///
/// Both of those are there to be tripped over. The cut corners are dark and sit
/// inside the box around the sheet, so measuring the box instead of the sheet puts
/// the black end on the table. The reflection is as bright as the paper, so taking
/// every bright pixel gives a box stretching from the reflection to the sheet.
fn document_on_a_dark_table() -> DynamicImage {
    let mut img = RgbImage::from_pixel(600, 800, Rgb([30, 22, 16])); // dark table

    for y in 120..640 {
        for x in 100..480 {
            let (from_left, from_right) = (x - 100, 479 - x);
            let (from_top, from_bottom) = (y - 120, 639 - y);
            let corner = from_left.min(from_right) + from_top.min(from_bottom);
            if corner < 60 {
                continue; // corner of the box, still table
            }
            // Paper, unevenly lit across the sheet, and warm: more red than blue.
            let brightness = 150 + ((x - 100) / 8) as u8;
            img.put_pixel(x, y, Rgb([brightness + 12, brightness, brightness - 10]));
        }
    }
    for y in 300..380 {
        for x in 160..420 {
            img.put_pixel(x, y, Rgb([58, 55, 52])); // writing
        }
    }
    for y in 20..80 {
        for x in 20..80 {
            img.put_pixel(x, y, Rgb([200, 200, 200])); // reflection on the table
        }
    }

    DynamicImage::ImageRgb8(img)
}

#[test]
fn the_sheet_is_found_on_a_dark_table() {
    let sheet = find_paper(&document_on_a_dark_table())
        .expect("no sheet was found")
        .bounds;

    // The search runs on a shrunk copy, so the box is a few pixels off at most.
    let off_by = |found: u32, expected: u32| (found as i64 - expected as i64).abs();
    for (name, found, expected) in [
        ("x", sheet.x, 100),
        ("y", sheet.y, 120),
        ("width", sheet.width, 380),
        ("height", sheet.height, 520),
    ] {
        assert!(
            off_by(found, expected) <= 15,
            "{name} should be about {expected}, but the box was {sheet:?}"
        );
    }
}

#[test]
fn levels_measure_the_paper_and_not_the_table() {
    let photo = document_on_a_dark_table();
    let sheet_only = crop(&photo, 100, 120, 380, 520).expect("the reference crop did not fit");

    let whole_photo = suggest_levels(&photo);
    let cropped_by_hand = suggest_levels(&sheet_only);

    for channel in 0..3 {
        // The table is darker than the writing. Measured across everything, the
        // black end lands on the table and the writing stays grey.
        assert!(
            whole_photo.black[channel] > 45,
            "the black end fell onto the table instead of the writing: {:?}",
            whole_photo.black
        );
        let difference =
            (whole_photo.black[channel] as i64 - cropped_by_hand.black[channel] as i64).abs();
        assert!(
            difference <= 10,
            "finding the sheet should give what cropping to it by hand gives, but {:?} and {:?} disagree",
            whole_photo,
            cropped_by_hand
        );
    }
}

#[test]
fn a_scan_is_all_paper_with_nothing_to_cut_away() {
    let sheet = find_paper(&photographed_document()).expect("a scan is a sheet too");

    // Paper edge to edge. The writing has to end up on the sheet rather than
    // outside it, otherwise a measurement of the paper would never see any ink.
    assert!(sheet.is_the_whole_image(), "{:?}", sheet.bounds);
    assert!(
        sheet.contains(100, 100),
        "the writing was left off the sheet"
    );
}

#[test]
fn a_page_that_fills_the_frame_is_still_one_whole_sheet() {
    let sheet = find_paper(&photographed_document()).expect("a page is a sheet even edge to edge");

    // There is no edge of the paper anywhere in this picture, so the search for the
    // four sides has nothing to find and has to hand back the whole page instead of
    // a shape it made up - or worse, nothing at all. A client reads nothing as
    // "leave this photo alone", and one page answered that way stops a whole scan.
    assert!(sheet.is_the_whole_image(), "{:?}", sheet.bounds);
    assert!(sheet.contains(10, 10) && sheet.contains(190, 190));
    let corners = sheet.corners();
    assert!(
        corners[0].x < 5.0 && corners[2].x > 195.0,
        "the corners are not the corners of the picture: {corners:?}"
    );
}

/// A sheet on a table with a patch of sheen beside it, exactly as bright as the
/// paper and touching the sheet along a run of a hundred and forty rows, out to the
/// right edge of the picture.
///
/// This is the photograph the whole search is built for. Being as bright as the
/// paper, the patch cannot be told from it by brightness, so it joins the sheet as
/// one shape; being one shape with it, it drags the outermost corner of that shape
/// out to the corner of the frame; and reaching the edge of the picture, it makes
/// the sheet look as if it ran off the photo, which stops the page being straightened
/// at all. Only the edge of the paper between the two says where the sheet ends.
fn document_beside_a_patch_of_sheen() -> DynamicImage {
    let mut img = document_lying_on_a_table();
    let table = img.as_mut_rgb8().expect("the fixture is an rgb image");

    for y in 560..700 {
        for x in 480..600 {
            table.put_pixel(x, y, Rgb([196, 196, 196])); // sheen on the table
        }
    }

    img
}

/// A sheet on a dark table with nothing else the matter with it: the picture the two
/// fixtures below each add one difficulty to.
fn document_lying_on_a_table() -> DynamicImage {
    let mut img = RgbImage::from_pixel(600, 800, Rgb([28, 24, 20])); // dark table

    for y in 100..700 {
        for x in 100..480 {
            let brightness = 190 + ((y - 100) / 60) as u8; // paper, lit unevenly
            img.put_pixel(x, y, Rgb([brightness, brightness, brightness]));
        }
    }
    for y in 200..260 {
        for x in 160..420 {
            img.put_pixel(x, y, Rgb([54, 52, 50])); // writing
        }
    }

    DynamicImage::ImageRgb8(img)
}

#[test]
fn a_patch_of_sheen_beside_the_sheet_is_not_part_of_it() {
    let sheet = find_paper(&document_beside_a_patch_of_sheen()).expect("no sheet was found");

    let found = sheet.corners();
    for (found, expected) in found.iter().zip([
        core_engine::Point { x: 100.0, y: 100.0 },
        core_engine::Point { x: 480.0, y: 100.0 },
        core_engine::Point { x: 480.0, y: 700.0 },
        core_engine::Point { x: 100.0, y: 700.0 },
    ]) {
        // The search runs on a shrunk copy and leans every side a little outwards on
        // purpose, so a corner lands within a few pixels rather than exactly.
        let off_by = (found.x - expected.x).hypot(found.y - expected.y);
        assert!(
            off_by < 8.0,
            "corner {found:?} is {off_by:.1} pixels away from {expected:?}, so the sheen moved it"
        );
    }
    assert!(
        !sheet.contains(550, 650),
        "the patch of sheen was measured as paper"
    );
    // The patch reaches the right edge of the picture. Once it is off the sheet, the
    // sheet plainly does not run off the photo, and straightening is offered again.
    assert!(!sheet.runs_off_the_picture());
}

/// The same sheet, with a dark thing lying on it and running off it onto the table: a
/// hand holding the page down, a phone, a pen, the shadow of any of them.
///
/// It is dark, it is as dark as the table, it is thicker than a line of writing, and
/// because it runs off the paper onto the table it can be walked to from the edge of the
/// picture just like the table can. So every test a ray has for "this is where the paper
/// ends" says yes to its edge, the rays that stop on it are the majority of that side,
/// and the whole side jumps onto the page. Nothing about the shape that comes out looks
/// wrong; what is wrong is the paper left outside it.
fn document_with_a_dark_thing_on_it(across: Range<u32>, down: Range<u32>) -> DynamicImage {
    let mut img = document_lying_on_a_table();
    let sheet = img.as_mut_rgb8().expect("the fixture is an rgb image");

    for y in down {
        for x in across.clone() {
            sheet.put_pixel(x, y, Rgb([30, 26, 22]));
        }
    }

    img
}

/// That the whole page is still there, however the sheet was arrived at: nothing may cut
/// a page short, because everything below the cut is page and whatever is written there
/// is gone.
fn the_page_was_not_cut_short(sheet: &core_engine::Paper) {
    let bottom = sheet.bounds.y + sheet.bounds.height;
    assert!(
        bottom > 660,
        "the page was cut off at {bottom} instead of about 700: {:?}",
        sheet.bounds
    );
    for corner in sheet.corners() {
        assert!(
            corner.y < 160.0 || corner.y > 660.0,
            "corner {corner:?} sits in the middle of the page, so a side was fitted to the thing lying on it"
        );
    }
    assert!(
        sheet.contains(140, 680) && sheet.contains(440, 680),
        "the page below the thing lying on it was left off the sheet"
    );
}

#[test]
fn a_dark_thing_lying_on_the_page_does_not_shorten_it() {
    let photo = document_with_a_dark_thing_on_it(180..420, 600..760);

    let sheet = find_paper(&photo).expect("no sheet was found");

    // It covers two thirds of the bottom side and hides a hundred pixels of paper, so
    // the shape it leads to is still nearly all of the sheet by area. What gives it away
    // is the paper carrying on past the fitted side, on both sides of the thing.
    the_page_was_not_cut_short(&sheet);
}

#[test]
fn a_dark_bar_right_across_the_page_does_not_halve_it() {
    let photo = document_with_a_dark_thing_on_it(0..450, 400..430);

    let sheet = find_paper(&photo).expect("no sheet was found");

    // This one leaves almost no paper beside it to give it away - it reaches the edge of
    // the picture - but it abandons half the sheet, which the shape's area shows.
    the_page_was_not_cut_short(&sheet);
}

#[test]
fn a_bright_speck_is_not_mistaken_for_a_sheet() {
    // A lamp, a reflection, a white cup: bright and clearly separate, but far too
    // small to be the document someone is photographing.
    let mut img = RgbImage::from_pixel(400, 400, Rgb([30, 22, 16]));
    for y in 50..130 {
        for x in 50..130 {
            img.put_pixel(x, y, Rgb([220, 220, 220]));
        }
    }

    assert_eq!(find_paper(&DynamicImage::ImageRgb8(img)), None);
}

/// The four corners in light tints, so each one can be found again in the result.
/// Tints rather than saturated colours: a dark blue corner would read as table and
/// be cut off, which says nothing about the straightening.
const CORNER_TINTS: [Rgb<u8>; 4] = [
    Rgb([235, 120, 120]),
    Rgb([120, 235, 120]),
    Rgb([120, 120, 235]),
    Rgb([235, 235, 120]),
];
const PAPER: Rgb<u8> = Rgb([235, 235, 235]);

/// A sheet photographed at an angle: the near edge wider than the far one, which is
/// what a photo taken over a document looks like.
fn photo_of_a_tilted_sheet() -> (DynamicImage, [core_engine::Point; 4]) {
    let corner = |x: f32, y: f32| core_engine::Point { x, y };
    let corners = [
        corner(60.0, 20.0),
        corner(140.0, 20.0),
        corner(180.0, 180.0),
        corner(20.0, 180.0),
    ];

    let mut img = RgbImage::from_pixel(200, 200, Rgb([20, 15, 10])); // dark table
    for y in 20..=180 {
        let share = (y - 20) as f32 / 160.0;
        let left = 60.0 + (20.0 - 60.0) * share;
        let right = 140.0 + (180.0 - 140.0) * share;
        for x in left.ceil() as u32..=right.floor() as u32 {
            let near_corner = corners
                .iter()
                .zip(CORNER_TINTS)
                .find(|(c, _)| (c.x - x as f32).hypot(c.y - y as f32) < 14.0)
                .map(|(_, tint)| tint);
            img.put_pixel(x, y, near_corner.unwrap_or(PAPER));
        }
    }

    (DynamicImage::ImageRgb8(img), corners)
}

/// Which of the marks a pixel is closest to, so a slightly mixed edge pixel still
/// counts as the mark it came from.
fn nearest_mark(pixel: &Rgb<u8>) -> usize {
    let distance = |to: &Rgb<u8>| {
        (0..3)
            .map(|c| (i32::from(pixel[c]) - i32::from(to[c])).pow(2))
            .sum::<i32>()
    };

    let mut marks: Vec<Rgb<u8>> = CORNER_TINTS.to_vec();
    marks.push(PAPER);
    (0..marks.len())
        .min_by_key(|&index| distance(&marks[index]))
        .unwrap()
}

#[test]
fn a_tilted_sheet_is_pulled_into_a_rectangle() {
    let (photo, corners) = photo_of_a_tilted_sheet();

    let straight = deskew(&photo, corners)
        .expect("straightening failed")
        .to_rgb8();

    // Every corner of the sheet has to arrive in the matching corner of the result.
    // Turning, scaling and shearing together cannot do that for a trapezoid - they
    // can hit three corners at most - so wrong arithmetic shows up right here.
    let (right, bottom) = (straight.width() - 3, straight.height() - 3);
    for (mark, (x, y), name) in [
        (0, (3, 3), "top left"),
        (1, (right, 3), "top right"),
        (2, (right, bottom), "bottom right"),
        (3, (3, bottom), "bottom left"),
    ] {
        let found = straight.get_pixel(x, y);
        assert_eq!(
            nearest_mark(found), mark,
            "the {name} corner of the sheet did not arrive in the {name} corner, it came out {found:?}"
        );
    }
}

#[test]
fn straightening_leaves_the_table_out() {
    let (photo, corners) = photo_of_a_tilted_sheet();

    let straight = deskew(&photo, corners)
        .expect("straightening failed")
        .to_rgb8();

    // The rectangle is exactly the sheet, so none of the dark table around it may
    // show up inside - that is the whole difference to cutting to a box.
    let table = straight
        .pixels()
        .filter(|p| p[0] < 100 && p[1] < 100 && p[2] < 100)
        .count();
    let pixels = (straight.width() * straight.height()) as usize;
    assert!(table * 100 < pixels, "{table} of {pixels} pixels are table");
}

#[test]
fn the_corners_of_the_sheet_are_found() {
    let (photo, corners) = photo_of_a_tilted_sheet();

    let found = find_paper(&photo).expect("no sheet was found").corners();

    for (found, expected) in found.iter().zip(corners) {
        let off_by = (found.x - expected.x).hypot(found.y - expected.y);
        assert!(
            off_by < 6.0,
            "corner {found:?} is {off_by:.1} pixels away from {expected:?}"
        );
    }
}

#[test]
fn a_sheet_running_off_the_photo_says_so() {
    let (photo, _) = photo_of_a_tilted_sheet();
    let whole_sheet = find_paper(&photo).expect("no sheet was found");
    let cut_off = find_paper(&photographed_document()).expect("no sheet was found");

    // The corners of a sheet that leaves the frame are not corners of the paper, so a
    // page cut on them is a piece of the sheet. The caller has to be able to tell the
    // two apart to say that on screen.
    assert!(!whole_sheet.runs_off_the_picture());
    assert!(cut_off.runs_off_the_picture());
}

#[test]
fn four_corners_in_a_line_are_refused() {
    let flat = [
        core_engine::Point { x: 10.0, y: 10.0 },
        core_engine::Point { x: 20.0, y: 10.0 },
        core_engine::Point { x: 30.0, y: 10.0 },
        core_engine::Point { x: 40.0, y: 10.0 },
    ];

    assert!(deskew(&test_image(100, 100), flat).is_err());
}

#[test]
fn levels_leave_out_colour_that_was_never_meant() {
    // The two ends measured off a real photo. They differ per channel, which is
    // what removes the warm cast - and what turns a barely cool shadow on the
    // paper into a coloured blotch if nothing is done about it.
    let levels = Levels {
        black: [17, 16, 11],
        white: [152, 141, 126],
    };
    let mut img = RgbImage::new(2, 1);
    img.put_pixel(0, 0, Rgb([130, 128, 130])); // paper, a shade cooler in the shade
    img.put_pixel(1, 0, Rgb([150, 40, 40])); // a red heading

    let stretched = apply_levels(&DynamicImage::ImageRgb8(img), levels).to_rgb8();

    let colour_spread = |pixel: &Rgb<u8>| {
        i32::from(pixel.0.iter().copied().max().unwrap())
            - i32::from(pixel.0.iter().copied().min().unwrap())
    };
    let shadow = stretched.get_pixel(0, 0);
    let heading = stretched.get_pixel(1, 0);
    assert!(
        colour_spread(shadow) <= 6,
        "the shadow on the paper came out coloured: {shadow:?}"
    );
    assert!(
        colour_spread(heading) > 100,
        "the red heading lost its colour: {heading:?}"
    );
}

/// A page of writing, photographed crooked: lines of text running downhill to the
/// right by a known angle.
fn crooked_page(tilt_degrees: f32) -> DynamicImage {
    let mut img = RgbImage::from_pixel(400, 400, Rgb([225, 222, 215]));
    let slope = tilt_degrees.to_radians().tan();

    for line in 1..12 {
        for x in 30..370 {
            let y = line as f32 * 30.0 + x as f32 * slope;
            for thickness in 0..5 {
                let y = y as u32 + thickness;
                if y < 400 {
                    img.put_pixel(x, y, Rgb([55, 52, 50]));
                }
            }
        }
    }

    DynamicImage::ImageRgb8(img)
}

/// How much of the darkest row is dark all the way across. A line of writing that
/// is straight fills its row; a crooked one only crosses it for a stretch.
fn darkest_row_coverage(img: &DynamicImage) -> f32 {
    let gray = img.to_luma8();
    (0..gray.height())
        .map(|y| {
            (0..gray.width())
                .filter(|&x| gray.get_pixel(x, y)[0] < 128)
                .count()
        })
        .max()
        .unwrap_or(0) as f32
        / gray.width() as f32
}

#[test]
fn crooked_writing_is_measured_from_the_writing_itself() {
    // No sheet to be found in this picture, no background darker than the paper -
    // the angle comes from the lines of text alone.
    let suggestion = suggest_straightening(&crooked_page(3.0));

    assert!(
        (suggestion + 3.0).abs() < 0.4,
        "the page is 3 degrees clockwise, so it should be turned back by -3, not {suggestion}"
    );
}

#[test]
fn a_page_tilted_past_the_limit_is_told_an_angle_straighten_takes() {
    // The coarse pass can peak at the very edge of the range and the refinement
    // then searches a degree past it, so the answer could come back further than
    // `straighten` turns. That page would fail on every retry and never finish.
    let crooked = crooked_page(10.5);

    straighten(&crooked, suggest_straightening(&crooked))
        .expect("the suggested angle was one straighten refuses");
}

#[test]
fn straightening_puts_the_lines_of_writing_back_in_their_rows() {
    let crooked = crooked_page(3.0);
    let before = darkest_row_coverage(&crooked);

    let straight = straighten(&crooked, suggest_straightening(&crooked)).expect("turning failed");

    let after = darkest_row_coverage(&straight);
    assert!(
        before < 0.5,
        "the crooked page already had a full row of writing, so this proves nothing: {before}"
    );
    assert!(
        after > 0.8,
        "after straightening a line of writing should fill its row, but the best row is {after}"
    );
}

#[test]
fn a_picture_without_writing_is_left_straight() {
    assert_eq!(suggest_straightening(&test_image(200, 200)), 0.0);
}

#[test]
fn turning_further_than_a_crooked_photo_is_refused() {
    // Ten degrees is a shaky hand; ninety is a page held sideways, which is the
    // rotate tool's job and does not need resampling at all.
    assert!(straighten(&test_image(100, 100), 45.0).is_err());
}

#[test]
fn a_blank_sheet_lit_unevenly_is_left_straight() {
    // Nothing to line up, only light falling off across the page. Read at a slant
    // that looks like the faintest striping, and the reading gets stripier the more
    // it is slanted - so the sharpest angle alone would say "turn by ten degrees".
    let blank = RgbImage::from_fn(400, 500, |x, _| {
        Rgb([
            200 + (x / 40) as u8,
            195 + (x / 40) as u8,
            185 + (x / 40) as u8,
        ])
    });

    assert_eq!(
        suggest_straightening(&DynamicImage::ImageRgb8(blank)),
        0.0,
        "a blank sheet was turned as if it had crooked writing on it"
    );
}
