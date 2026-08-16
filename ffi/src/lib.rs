//! The C surface the phone links against.
//!
//! Four functions, and between them the order the engine's tools are used in for a
//! photo of a document. That order lives here and not in the engine, because the
//! engine offers single tools and the client owns the order
//! ([`../AGENTS.md`](../AGENTS.md)). This crate is a client - the smallest one
//! there is, and the only one that has to speak C.
//!
//! What crosses the boundary: C strings, a size, an int32, and two structs of plain
//! numbers - `FreepdfAdjustments` in, `FreepdfSuggestion` out, both copied at the
//! boundary. What never crosses: a pixel buffer, an image
//! handle, an allocation the caller has to free, a callback. The rules of this crate are in [`AGENTS.md`](./AGENTS.md).

// Edition 2024's rule, asked for early: an `unsafe fn` does not quietly make its whole
// body unsafe, so every read of a caller's pointer is marked where it happens.
#![deny(unsafe_op_in_unsafe_fn)]

use core_engine::{
    apply_levels, crop, deskew, find_paper, load_image, pages_to_pdf, rotate, save_page, sharpen,
    straighten, suggest_levels, suggest_straightening, to_grayscale, Levels, Point,
};
use std::ffi::{c_char, CStr};
use std::panic::{catch_unwind, UnwindSafe};
use std::path::{Path, PathBuf};

/// The longest edge a finished page may keep, in pixels - about 257 dpi on A4.
///
/// ponytail: this is a memory cap, not a quality choice. `sharpen` is the peak of
/// the whole scan, and it costs 33 bytes per pixel: image 0.25's `unsharpen` calls
/// `blur_advanced`, which allocates **two** f32 planes of `w * h * 3 * 4` bytes
/// (sample.rs:1437 and :1464), on top of the `to_rgb8` clone and the output. A 12 MP
/// photo would peak near 400 MB there, and iOS kills a foreground app around 1.4 GB
/// on a 3 GB phone. At this cap the peak is about 223 MB. Raise the number if fine
/// print comes out soft; the cost is 33 bytes of peak per pixel added.
const LONGEST_EDGE: u32 = 3000;

/// How much a scanned page is sharpened by, in pixels of radius. The same value the
/// command line runner's `--scan` uses, measured there against a hand edit of the
/// same photo: more starts to draw halos around the letters. The two are separate
/// constants because each client owns its own order of tools, but a change to one is
/// worth making in both.
const SCAN_SHARPEN: f32 = 0.6;

/// Turns one photo into one finished page file.
///
/// The page is written by [`save_page`], so it wears its real name only once it is
/// whole, and its bytes are exactly what [`freepdf_pages_to_pdf`] later embeds.
///
/// Returns 0 on success. Anything else means nothing was written and `error` holds a
/// sentence for the user.
///
/// # Safety
/// Each path is either null or a NUL-terminated C string, and `error` is either null
/// or `error_size` bytes the caller owns. C cannot express that, which is why the
/// header says nothing about it: the app's Swift wrapper is the only caller, and it
/// passes `URL.path` and its own buffer.
#[no_mangle]
pub unsafe extern "C" fn freepdf_scan_page(
    photo_path: *const c_char,
    out_page_path: *const c_char,
    error: *mut c_char,
    error_size: usize,
) -> i32 {
    // Read outside the guard: this is the only place that touches the caller's
    // pointers, and it cannot panic, so nothing unsafe happens under catch_unwind.
    let photo = unsafe { path_from(photo_path, "The photo") };
    let page = unsafe { path_from(out_page_path, "The page to write") };

    guard(error, error_size, move || scan_page(&photo?, &page?))
}

/// Every value the Adjust screen can move, in the order the recipe uses them.
///
/// One struct rather than seven functions, Julian's decision of 2026-08-12
/// (`user-flows.md` DECISIONS point 12): the tools are only ever set together, and
/// seven crossings would be seven chances to run them in the wrong order. It is read
/// only, it is copied out at the boundary, and it holds no pointer, so the app never
/// manages the engine's memory.
#[repr(C)]
#[derive(Clone, Copy)]
pub struct FreepdfAdjustments {
    /// The four paper corners as x, y pairs, in the photo's own pixels.
    pub corners: [f32; 8],
    pub pull_the_sheet_flat: i32,
    /// -10 to +10 degrees. 0 turns nothing.
    pub straighten_degrees: f32,
    pub black: [u8; 3],
    pub white: [u8; 3],
    pub adjust_the_tones: i32,
    /// 0 sharpens nothing: the engine refuses radius 0, so the call is skipped.
    pub sharpen_radius: f32,
    /// The cut, as fractions 0…1 of the image this recipe holds right before cropping
    /// - after the corners, the straightening, the 3000 px cap and the turn. Fractions
    /// and not pixels because that image is made here and the app never sees its size;
    /// the same fraction then means the same piece on every page. A width or height of
    /// 0, or one too thin to reach one pixel, cuts nothing.
    pub crop_x: f32,
    pub crop_y: f32,
    pub crop_width: f32,
    pub crop_height: f32,
    /// Quarter turns clockwise, 0 to 3.
    pub quarter_turns: u32,
    pub grey: i32,
}

/// What the engine would have chosen by itself for one photo.
///
/// One struct so the Adjust screen can open every control on the engine's own
/// answer instead of a neutral default (`user-flows.md` section 7, "suggest, then
/// apply"). `values` is handed straight back to [`freepdf_adjust_page`] once the
/// user has fine-tuned it; the three flags are what the screen says about the sheet
/// and cannot be worked out from `values` alone.
#[repr(C)]
#[derive(Clone, Copy)]
pub struct FreepdfSuggestion {
    /// The engine's own values, ready to be shown, changed, and handed back.
    pub values: FreepdfAdjustments,
    /// 0 when no sheet was found at all, and `values.corners` are then all zero.
    pub found_a_sheet: i32,
    /// The sheet fills the whole photo, so there is nothing to cut away.
    pub fills_the_whole_photo: i32,
    /// The sheet leaves the frame, so pulling it flat would bend the picture.
    pub runs_off_the_picture: i32,
}

/// Asks the engine what it would do with this photo on its own.
///
/// Writes nothing to disk. The corners in `out_suggestion.values.corners` are in
/// **the photo's own upright full size pixels** - the photo after its EXIF
/// orientation has been applied, which is the space the app draws the photo in.
/// They are not page pixels: the finished page has been pulled flat, straightened
/// and capped, and none of that is a straight scaling.
///
/// `sheet` is the caller's own sheet, or null for "your own sheet". Only two of its
/// fields are read - the corners and their switch - which is why it is not called
/// `values`: nothing else the user set changes the answer. It changes one thing:
/// which corners the picture is pulled flat with before the tilt and the tone
/// points are read off it. Everything handed back - the corners and the three notes -
/// is still the engine's own answer, so "Back to the suggestion" reads the same
/// numbers whichever way it was asked. A straightening angle is only meaningful
/// against a particular set of corners, which is why the caller can hand its own in.
///
/// Returns 0 on success. Anything else means nothing was written and `error` holds a
/// sentence for the user.
///
/// # Safety
/// `photo_path` is either null or a NUL-terminated C string, `sheet` is either null
/// or one readable [`FreepdfAdjustments`], `out_suggestion` is either null or one
/// writable [`FreepdfSuggestion`], and `error` is either null or `error_size` bytes
/// the caller owns.
#[no_mangle]
pub unsafe extern "C" fn freepdf_suggest_adjustments(
    photo_path: *const c_char,
    sheet: *const FreepdfAdjustments,
    out_suggestion: *mut FreepdfSuggestion,
    error: *mut c_char,
    error_size: usize,
) -> i32 {
    let photo = unsafe { path_from(photo_path, "The photo") };
    let chosen = if sheet.is_null() {
        None
    } else {
        Some(unsafe { *sheet })
    };
    let out = if out_suggestion.is_null() {
        Err("The app gave nowhere to put the suggestion.".to_string())
    } else {
        Ok(out_suggestion)
    };

    guard(error, error_size, move || {
        let suggestion = suggest_adjustments(&photo?, chosen)?;
        unsafe { *out? = suggestion };
        Ok(())
    })
}

/// Turns one photo into one finished page file, with the user's own values.
///
/// The same recipe as [`freepdf_scan_page`] and the same error contract; it replaces
/// that call once the user has adjusted something. The page is written by
/// [`save_page`], so it wears its real name only once it is whole.
///
/// Returns 0 on success. Anything else means nothing was written and `error` holds a
/// sentence for the user.
///
/// # Safety
/// Each path is either null or a NUL-terminated C string, `values` is either null or
/// one readable [`FreepdfAdjustments`], and `error` is either null or `error_size`
/// bytes the caller owns.
#[no_mangle]
pub unsafe extern "C" fn freepdf_adjust_page(
    photo_path: *const c_char,
    out_page_path: *const c_char,
    values: *const FreepdfAdjustments,
    error: *mut c_char,
    error_size: usize,
) -> i32 {
    let photo = unsafe { path_from(photo_path, "The photo") };
    let page = unsafe { path_from(out_page_path, "The page to write") };
    // Copied here, next to the other reads of the caller's pointers, so nothing
    // unsafe happens under catch_unwind.
    let values = if values.is_null() {
        Err("The app did not say what to adjust.".to_string())
    } else {
        Ok(unsafe { *values })
    };

    guard(error, error_size, move || {
        adjust_page(&photo?, &page?, &values?)
    })
}

/// Writes the finished pages as one PDF, in the order given.
///
/// The pages are handed over as paths and never decoded, which is what lets a forty
/// page scan happen inside a phone's memory ([`pages_to_pdf`]).
///
/// Returns 0 on success. Anything else means no PDF was written and `error` holds a
/// sentence for the user.
///
/// # Safety
/// `page_paths` is either null or an array of `page_count` NUL-terminated C strings,
/// and `error` is either null or `error_size` bytes the caller owns.
#[no_mangle]
pub unsafe extern "C" fn freepdf_pages_to_pdf(
    page_paths: *const *const c_char,
    page_count: usize,
    out_pdf_path: *const c_char,
    error: *mut c_char,
    error_size: usize,
) -> i32 {
    let pages = unsafe { paths_from(page_paths, page_count) };
    let pdf = unsafe { path_from(out_pdf_path, "The PDF to write") };

    guard(error, error_size, move || pages_to_pdf(&pages?, &pdf?))
}

/// The order of tools a photograph of a document wants, and the one place it is
/// written down for the phone.
///
/// Two steps are allowed to do nothing rather than fail: a sheet that cannot be
/// found or that runs off the frame is left alone, and writing that is already level
/// is not turned. That is not politeness. One awkward photo that returned an error
/// would make the whole scan unfinishable, and resuming would retry that same photo
/// for ever.
fn scan_page(photo: &Path, page: &Path) -> Result<(), String> {
    let mut img = load_image(photo)?;

    if let Some(sheet) = find_paper(&img) {
        if !sheet.runs_off_the_picture() {
            img = deskew(&img, sheet.corners())?;
        }
    }

    let degrees = suggest_straightening(&img);
    if degrees != 0.0 {
        img = straighten(&img, degrees)?;
    }

    img = apply_levels(&img, suggest_levels(&img));

    // Shrunk before sharpening, because sharpening is where the memory goes.
    // `thumbnail` is the integer box filter and needs no f32 scratch of its own,
    // unlike `resize`, which would allocate exactly what this cap exists to avoid.
    if img.width().max(img.height()) > LONGEST_EDGE {
        img = img.thumbnail(LONGEST_EDGE, LONGEST_EDGE);
    }

    img = sharpen(&img, SCAN_SHARPEN)?;
    save_page(&img, page)
}

/// The values [`scan_page`] would have picked for itself, without writing a page.
///
/// It walks the same chain in the same order, because a suggestion measured on a
/// different image is a different suggestion: the tone points are read off the sheet
/// after it was pulled flat and straightened, exactly as the automatic run reads them.
/// Only the steps that change what a later step sees are actually applied here.
///
/// `chosen` is the caller's own sheet: the picture is pulled flat with those corners
/// instead of the found ones before the tilt is measured, because an angle read off
/// the engine's frame is the wrong angle for the user's. What comes back is still the
/// engine's own answer - the found corners and the three notes are untouched.
fn suggest_adjustments(
    photo: &Path,
    chosen: Option<FreepdfAdjustments>,
) -> Result<FreepdfSuggestion, String> {
    let mut img = load_image(photo)?;

    let sheet = find_paper(&img);
    let runs_off = sheet.as_ref().is_some_and(|s| s.runs_off_the_picture());
    let mut corners = [0.0f32; 8];
    if let Some(sheet) = &sheet {
        for (slot, point) in sheet.corners().iter().enumerate() {
            corners[slot * 2] = point.x;
            corners[slot * 2 + 1] = point.y;
        }
    }
    match &chosen {
        Some(chosen) => {
            if chosen.pull_the_sheet_flat != 0 {
                img = deskew(&img, corners_of(chosen))?;
            }
        }
        None => {
            if let Some(sheet) = &sheet {
                if !runs_off {
                    img = deskew(&img, sheet.corners())?;
                }
            }
        }
    }

    let degrees = suggest_straightening(&img);
    if degrees != 0.0 {
        img = straighten(&img, degrees)?;
    }

    let levels = suggest_levels(&img);

    Ok(FreepdfSuggestion {
        values: FreepdfAdjustments {
            corners,
            pull_the_sheet_flat: i32::from(sheet.is_some() && !runs_off),
            straighten_degrees: degrees,
            black: levels.black,
            white: levels.white,
            adjust_the_tones: i32::from(!levels.are_unchanged()),
            sharpen_radius: SCAN_SHARPEN,
            // The automatic run cuts nothing and turns nothing, so neither does the
            // suggestion: 0 width and 0 turns are what those controls call "off".
            crop_x: 0.0,
            crop_y: 0.0,
            crop_width: 0.0,
            crop_height: 0.0,
            quarter_turns: 0,
            grey: 0,
        },
        found_a_sheet: i32::from(sheet.is_some()),
        fills_the_whole_photo: i32::from(sheet.as_ref().is_some_and(|s| s.is_the_whole_image())),
        runs_off_the_picture: i32::from(runs_off),
    })
}

/// The same order of tools as [`scan_page`], with the user's values instead of the
/// suggested ones, and the three tools the automatic run never uses: crop, turn, grey.
///
/// Two differences to [`scan_page`], both because the user chose the values here: a
/// step that was switched off is skipped rather than suggested, and a step that fails
/// - an angle that is not a quarter turn - is reported instead of quietly left alone.
/// The crop is fractions of the image this function holds at that moment, so it is
/// cut after the 3000 px cap and after the turn, not before.
fn adjust_page(photo: &Path, page: &Path, values: &FreepdfAdjustments) -> Result<(), String> {
    let mut img = load_image(photo)?;

    if values.pull_the_sheet_flat != 0 {
        img = deskew(&img, corners_of(values))?;
    }

    if values.straighten_degrees != 0.0 {
        img = straighten(&img, values.straighten_degrees)?;
    }

    if values.adjust_the_tones != 0 {
        img = apply_levels(
            &img,
            Levels {
                black: values.black,
                white: values.white,
            },
        );
    }

    if img.width().max(img.height()) > LONGEST_EDGE {
        img = img.thumbnail(LONGEST_EDGE, LONGEST_EDGE);
    }

    if values.sharpen_radius > 0.0 {
        img = sharpen(&img, values.sharpen_radius)?;
    }

    // The turn comes first, so the fractions are of the picture the user drew the box
    // on: the app shows the page turned as this recipe will turn it.
    if values.quarter_turns % 4 != 0 {
        img = rotate(&img, (values.quarter_turns % 4) * 90)?;
    }

    if let Some((x, y, width, height)) = crop_box(img.width(), img.height(), values) {
        img = crop(&img, x, y, width, height)?;
    }

    if values.grey != 0 {
        img = to_grayscale(&img);
    }

    save_page(&img, page)
}

/// The crop fractions as pixels of the image they are cut from, or `None` when there is
/// nothing to cut.
///
/// Each edge is rounded and then held inside the image, so a box the app already keeps
/// inside the picture can never be refused for one pixel of rounding. Held on both
/// ends - the start against the size, the length against what is left - so no box that
/// comes out of here is one `crop` can refuse. A box too thin to reach one pixel cuts
/// nothing, which is what a zero width already means.
fn crop_box(width: u32, height: u32, values: &FreepdfAdjustments) -> Option<(u32, u32, u32, u32)> {
    let edge = |start: f32, length: f32, size: u32| {
        let at = ((start.max(0.0) * size as f32).round() as u32).min(size);
        let long = (length.max(0.0) * size as f32).round() as u32;
        (at, long.min(size - at))
    };
    let (x, cut_width) = edge(values.crop_x, values.crop_width, width);
    let (y, cut_height) = edge(values.crop_y, values.crop_height, height);
    (cut_width > 0 && cut_height > 0).then_some((x, y, cut_width, cut_height))
}

/// The eight numbers the app sends read as the four corners the engine takes.
fn corners_of(values: &FreepdfAdjustments) -> [Point; 4] {
    std::array::from_fn(|corner| Point {
        x: values.corners[corner * 2],
        y: values.corners[corner * 2 + 1],
    })
}

/// Runs one piece of work and turns its outcome into what C understands: a status,
/// and a sentence in the caller's buffer.
///
/// Every entry point goes through here, so a panic can never leave this crate.
/// Unwinding out of an `extern "C"` function is undefined behaviour, and the engine
/// forbids `panic!` in its own code precisely because of this boundary
/// ([`core_engine/AGENTS.md`](../core_engine/AGENTS.md)) - this is the net under
/// that rule, not a second way of reporting errors.
fn guard(
    error: *mut c_char,
    error_size: usize,
    work: impl FnOnce() -> Result<(), String> + UnwindSafe,
) -> i32 {
    let outcome = catch_unwind(work).unwrap_or_else(|_| {
        // ponytail: a panic here is a bug in the engine, not something the user did,
        // so there is no truer sentence to offer him. The way up is to fix whatever
        // panicked; nothing about this branch can be improved.
        Err("The engine hit an internal error.".to_string())
    });

    match outcome {
        Ok(()) => 0,
        Err(message) => {
            put(&message, error, error_size);
            1
        }
    }
}

/// Copies the sentence into the caller's buffer with its closing NUL, keeping what
/// fits. A caller that passes no buffer only wants the status, which is allowed.
///
/// ponytail: a sentence longer than the buffer is cut by bytes, so a very long path
/// can be cut inside a character. Swift's `String(cString:)` repairs that into one
/// replacement character, and the sentence is already unreadable at that length. The
/// way up is a bigger buffer, not code here.
fn put(message: &str, error: *mut c_char, error_size: usize) {
    if error.is_null() || error_size == 0 {
        return;
    }

    let fits = message.len().min(error_size - 1);
    unsafe {
        std::ptr::copy_nonoverlapping(message.as_ptr().cast::<c_char>(), error, fits);
        *error.add(fits) = 0;
    }
}

/// Reads one path argument.
///
/// A missing or unreadable path is a mistake in the calling app, but it is answered
/// with a sentence like any other failure: the alternative is a crash in the user's
/// hands, and the app has a place to show a sentence.
///
/// `name` starts the sentence, so it is written as it would be read: "The photo",
/// "Page 3 of the PDF".
///
/// # Safety
/// `path` is either null or a NUL-terminated C string.
unsafe fn path_from(path: *const c_char, name: &str) -> Result<PathBuf, String> {
    if path.is_null() {
        return Err(format!("{name} was not given."));
    }

    unsafe { CStr::from_ptr(path) }
        .to_str()
        .map(PathBuf::from)
        .map_err(|_| format!("{name} is not a readable file name."))
}

/// Reads the list of page paths.
///
/// An empty list is passed on rather than refused here, so the sentence the user
/// sees comes from [`pages_to_pdf`] and exists in one place only.
///
/// # Safety
/// `paths` is either null or an array of `count` NUL-terminated C strings.
unsafe fn paths_from(paths: *const *const c_char, count: usize) -> Result<Vec<PathBuf>, String> {
    if paths.is_null() {
        return Err("The app did not say which pages to put in the PDF.".to_string());
    }

    (0..count)
        .map(|page| unsafe {
            path_from(*paths.add(page), &format!("Page {} of the PDF", page + 1))
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sentence(buffer: &[c_char]) -> String {
        unsafe { CStr::from_ptr(buffer.as_ptr()) }
            .to_string_lossy()
            .into_owned()
    }

    /// No input reaches the panic branch of [`guard`]: the engine has no `panic!`,
    /// `unwrap` or `expect` in it, and a whole afternoon of odd inputs - a 1x1 photo,
    /// a 2x1 one, a missing file, a directory as the output - all came back as
    /// sentences. So the only honest way to check that branch is to panic on purpose.
    /// Without it a panic would unwind out of an `extern "C"` function, which is
    /// undefined behaviour rather than a crash.
    #[test]
    fn a_panic_becomes_a_status_and_a_sentence() {
        let mut error = [0 as c_char; 64];

        let previous = std::panic::take_hook();
        std::panic::set_hook(Box::new(|_| {})); // the panic below is meant, so keep it quiet
        let status = guard(error.as_mut_ptr(), error.len(), || panic!("on purpose"));
        std::panic::set_hook(previous);

        assert_eq!(status, 1);
        assert_eq!(sentence(&error), "The engine hit an internal error.");
    }

    /// The adjusted case has to reach the page: the same photo, values the automatic
    /// run would never choose, and a different page file out of it. A page that came
    /// back byte for byte the same would mean the struct never arrived.
    #[test]
    fn adjusting_a_page_writes_something_else_than_the_automatic_run() {
        let folder = std::env::temp_dir().join("freepdf_ffi_adjust");
        std::fs::create_dir_all(&folder).expect("the temp folder");
        let photo = folder.join("photo.jpg");
        let automatic = folder.join("automatic.jpg");
        let adjusted = folder.join("adjusted.jpg");
        save_page(&a_photographed_sheet(), &photo).expect("the photo");
        let values = FreepdfAdjustments {
            corners: [0.0; 8],
            pull_the_sheet_flat: 0,
            straighten_degrees: 3.5,
            black: [20, 20, 20],
            white: [200, 200, 200],
            adjust_the_tones: 1,
            sharpen_radius: 4.0,
            crop_x: 0.1,
            crop_y: 0.1,
            crop_width: 0.5,
            crop_height: 0.4,
            quarter_turns: 1,
            grey: 1,
        };

        let scanned = unsafe {
            freepdf_scan_page(c_path(&photo).as_ptr(), c_path(&automatic).as_ptr(), std::ptr::null_mut(), 0)
        };
        let status = unsafe {
            freepdf_adjust_page(
                c_path(&photo).as_ptr(),
                c_path(&adjusted).as_ptr(),
                &values,
                std::ptr::null_mut(),
                0,
            )
        };

        assert_eq!(scanned, 0, "the automatic run failed");
        assert_eq!(status, 0, "the adjusted run failed");
        assert_ne!(
            std::fs::read(&automatic).expect("the automatic page"),
            std::fs::read(&adjusted).expect("the adjusted page"),
            "the adjusted page is byte for byte the automatic one"
        );
    }

    /// Paper with lines of writing on it, built here rather than read from
    /// `test_images/`: no test reads a file it did not write itself.
    fn a_photographed_sheet() -> core_engine::DynamicImage {
        let (width, height) = (600u32, 400u32);
        let mut img = core_engine::DynamicImage::new_rgb8(width, height);
        // Written through the raw samples, because this crate keeps no `image`
        // dependency of its own - the engine owns that version.
        let samples: &mut [u8] = img.as_mut_rgb8().expect("an rgb image");
        for pixel in 0..(width * height) as usize {
            let (x, y) = (pixel as u32 % width, pixel as u32 / width);
            let writing = y % 40 < 6 && (30..width - 30).contains(&x);
            let colour = if writing { [30, 30, 30] } else { [230, 227, 218] };
            samples[pixel * 3..pixel * 3 + 3].copy_from_slice(&colour);
        }
        img
    }

    fn c_path(path: &Path) -> std::ffi::CString {
        std::ffi::CString::new(path.to_str().expect("a readable path")).expect("no NUL in the path")
    }

    /// The buffer is the app's, and the sentence is whatever a path made it. Writing
    /// one byte past it would be a memory bug in someone else's process.
    #[test]
    fn a_sentence_too_long_for_the_buffer_is_cut_to_fit() {
        let mut error = [0x7f as c_char; 8];

        put("a sentence that does not fit", error.as_mut_ptr(), 8);

        assert_eq!(sentence(&error), "a sente");
        assert_eq!(error[7], 0, "the closing NUL has to be inside the buffer");
    }
}
