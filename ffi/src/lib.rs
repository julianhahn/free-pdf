//! The C surface the phone links against.
//!
//! Two functions, and between them the order the engine's tools are used in for a
//! photo of a document. That order lives here and not in the engine, because the
//! engine offers single tools and the client owns the order
//! ([`../AGENTS.md`](../AGENTS.md)). This crate is a client - the smallest one
//! there is, and the only one that has to speak C.
//!
//! What crosses the boundary: C strings, a size, and an int32. What never crosses:
//! a pixel buffer, an image handle, an allocation the caller has to free, a struct,
//! a callback. The rules of this crate are in [`AGENTS.md`](./AGENTS.md).

// Edition 2024's rule, asked for early: an `unsafe fn` does not quietly make its whole
// body unsafe, so every read of a caller's pointer is marked where it happens.
#![deny(unsafe_op_in_unsafe_fn)]

use core_engine::{
    apply_levels, deskew, find_paper, load_image, pages_to_pdf, save_page, sharpen, straighten,
    suggest_levels, suggest_straightening,
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

    img = sharpen(&img, SCAN_SHARPEN, 0)?;
    save_page(&img, page)
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
