# FreePDF Scan — iPhone client

One scan is one directory. The files in it are the only state. Nothing can disagree with
the disk after a crash, because there is nothing else to disagree.

Goal: photograph the pages of a document, get a clean PDF he can share wherever he wants,
and be able to stop at any moment without losing a thing. Offline, no network calls
anywhere.

---

## 1. Vocabulary (settled — use these words everywhere)

A **scan** is the thing being worked on. It is made of **pages**. Each page starts as a
**photo** and becomes a page by **scanning**. The finished scan is a **PDF**.

"Document" appears in exactly one place — the camera permission text — where it means the
paper in his hand. The output is always "the PDF".

| Concept | On disk | Swift | C |
| --- | --- | --- | --- |
| the scan | `Documents/Scans/2026-08-11_201403_8F3A/` | `Scan` | — |
| camera photo | `photo/0001.jpg` | `Scan.photos`, `photoURL(_:)` | — |
| processed page | `page/0001.jpg` | `Scan.pages`, `pageURL(_:)` | — |
| the PDF | `scan.pdf` | `Scan.pdf` | — |
| current step | (derived) | `Scan.State` | — |
| scan one page | — | `Engine.scanPage(_:into:)` | `freepdf_scan_page` |
| build the PDF | — | `Engine.pagesToPDF(_:out:)` | `freepdf_pages_to_pdf` |

UI copy, EN / DE:

```
New scan                     / Neuer Scan
Page 7                       / Seite 7
Scan 8 pages                 / 8 Seiten scannen
Scanning page 12 of 40       / Seite 12 von 40 wird gescannt
You can close the app. It carries on from here.
                             / Du kannst die App schließen. Es geht danach weiter.
Page 5 of 40                 / Seite 5 von 40
Retake this page             / Diese Seite neu fotografieren
Make PDF                     / PDF erstellen
PDF ready                    / PDF fertig
Open PDF                     / PDF öffnen
Change pages                 / Seiten ändern
Delete the 40 photos (78 MB) / Die 40 Fotos löschen (78 MB)
The PDF stays. Deleted photos cannot be brought back.
                             / Das PDF bleibt. Gelöschte Fotos kann man nicht zurückholen.
Page 7 was not saved: the iPhone is out of storage. Nothing already photographed is lost.
                             / Seite 7 wurde nicht gespeichert: Auf dem iPhone ist kein
                               Speicherplatz mehr frei. Nichts, was schon fotografiert
                               ist, geht verloren.
```

Row subtitles: `No pages yet` / `8 pages - keep shooting` / `12 of 40 pages scanned` /
`40 pages - ready to check` / `40 pages - PDF ready` (`, photos deleted`).

---

## 2. Storage

Built, and its rules now live next to the code in [`ios/AGENTS.md`](./ios/AGENTS.md): the
folder layout, the three rules that carry it (append-only, a real name only by rename,
debris invisible and swept), the step derived from the files rather than stored, and every
field a manifest would have held together with what killed it.

What the rest of this plan leans on is only this: one scan is one directory, the files in
it are the only state, and `Scan` in
[`ios/FreePDF/Scan.swift`](./ios/FreePDF/Scan.swift) is the whole of it — the names are in
the table in section 1, and what a kill costs at each moment is section 8.

---

## 3. Screens

Built, and the rules of what happens on them now live next to the code in
[`ios/AGENTS.md`](./ios/AGENTS.md): the way from the list into a scan, the one piece of
view state there is, the drain, why a refused page has to land on the pages rather than a
progress bar, what makes changing the pages after Make PDF safe, and the camera. One screen
in this section is not built yet, and it is what is left of it.

One thing this section had wrong is worth carrying forward as a warning: portrait lock does
**not** make the EXIF rotation come out right by itself. `videoRotationAngle` defaults to 0,
the sensor's own landscape, so every page would have come out on its side; the angle has to
be set, and on the preview's connection as well as the photo output's.

### Getting the PDF out

A `ShareLink` on `scan.pdf`, and that is the whole of it. The system sheet already has Save
to Files - iCloud Drive included, in the folder he picks - plus AirDrop and Mail.

The earlier plan uploaded every finished scan into the app's own iCloud container by
itself. **Julian's call, 2026-08-12: this is a tool, not an opinion about where his PDFs
live** - so nothing is uploaded unasked. That deleted the container, the iCloud entitlement
(which a free personal team may not even have), the copy-to-temp-then-rename dance, the
`-2` suffix loop for two scans finished in the same minute, the signed-out branch, and a
check that needed a Mac with iCloud on it.

Then, and only then, the quiet destructive button: **Delete the 40 photos (78 MB)**, size
measured with `attributesOfItem`, asked every time, never remembered. Doing nothing is the
other half of the choice, so "keep the photos" needs no button.

---

## 4. Engine changes

All additive. `backend-core-runner` calls every public engine function and is **not
affected by any of them**.

| Change | Why the goal is unreachable without it | Breaks the runner |
| --- | --- | --- |
| ADD `pdf::save_page(img, path)` (it took a third argument, a `PageQuality`, on 2026-08-22 — the engine's own rules are now [`core_engine/AGENTS.md`](./core_engine/AGENTS.md) and this table is the record of what was planned, not of today's signature) | The resume rule is "page 7 exists = page 7 is done", which is only true if a page can never appear under its real name half-written. Its bytes must also be the exact stream the PDF embeds, or every page is compressed twice. It must be the engine that writes it: a PDF ignores EXIF rotation, so a page written by Swift's ImageIO lands sideways, and a progressive JPEG is not readable as `/DCTDecode`. | no |
| ADD `pdf::pages_to_pdf(pages, out)` + private `jpeg_shape`, `jpeg_page` | Today 40 pages cost ~3.1 GB against a ~2.0 GB jetsam limit. `RawImage` can only hold decoded pixels and printpdf clones the buffer three more times at save; printpdf cannot stream. `XObject::External` is the only escape hatch in 0.12.5, and a path list is the only signature under which the phone can name 40 pages without holding them. | no |
| EXTRACT `place(id, px_w, px_h)` from `build_page` | Otherwise 20 lines of fit/centre maths get copied into the new path and drift. Pure extraction; the five existing PDF tests prove it by staying green. | no |
| `lib.rs`: `pub use pdf::{images_to_pdf, pages_to_pdf, save_page};` | The ffi crate calls them by name. | no |
| APPEND one test to `tests/engine.rs` | Verbatim embedding is the trick the whole memory fix rests on, and it is invisible to every other assertion — a silently re-encoded page still opens. | no |
| **NOT touched: `images_to_pdf`, `to_raw_image`, `save_options`, `JPEG_QUALITY`** | Not unavoidable, so it is out. The phone never calls `images_to_pdf`. Re-pointing it changes the CLI's output bytes, and two of the five PDF tests assert that output's size. Symmetry does not count. | no |

Sketch of the new code, all in `/Users/julianhahn/free-pdf/core_engine/src/pdf.rs`:

```rust
// Beyond what pdf.rs already imports: std::fs::OpenOptions, std::io::{Cursor, Read, Seek,
// SeekFrom}, image::{codecs::jpeg::{JpegDecoder, JpegEncoder}, ColorType, ImageDecoder},
// printpdf::{ExternalStream, ExternalXObject, Px}.
const PAGE_JPEG_QUALITY: u8 = 85;

/// Writes one finished page where the PDF step picks it up later.
/// These bytes ARE the stream that ends up in the PDF, so a page is compressed once,
/// not twice. Temp file + rename, so a kill leaves either no file or a finished one -
/// that is what makes "page 7 is done" a fact when the app comes back.
pub fn save_page(img: &DynamicImage, path: &Path) -> Result<(), String> {
    // JPEG takes 8-bit grey or RGB. Grey stays grey, so a greyed page stays smaller.
    let owned;
    let src = match img {
        DynamicImage::ImageLuma8(_) | DynamicImage::ImageRgb8(_) => img,
        other => { owned = DynamicImage::ImageRgb8(other.to_rgb8()); &owned }
    };
    let mut jpeg = Vec::new();
    src.write_with_encoder(JpegEncoder::new_with_quality(&mut jpeg, PAGE_JPEG_QUALITY))
        .map_err(|e| e.to_string())?;

    let part = path.with_extension("part");
    let mut f = File::create(&part).map_err(|e| failed(&part, e))?;
    f.write_all(&jpeg).map_err(|e| failed(&part, e))?;
    f.sync_all().map_err(|e| failed(&part, e))?;
    std::fs::rename(&part, path).map_err(|e| failed(path, e))
}

/// Every write error names the file and what happened, because these sentences go
/// straight onto the phone's screen.
fn failed(path: &Path, e: std::io::Error) -> String {
    format!("Failed to write {}: {}", path.display(), e)
}

/// Width, height and grey-or-colour from the JPEG header. Building the decoder reads
/// the header and stops there - no pixels are touched, which is the whole point.
fn jpeg_shape(jpeg: &[u8]) -> Result<(usize, usize, bool), String> {
    let decoder = JpegDecoder::new(Cursor::new(jpeg)).map_err(|e| e.to_string())?;
    let (w, h) = decoder.dimensions();
    Ok((w as usize, h as usize, decoder.color_type() == ColorType::L8))
}

/// One page per file, in page order. Reads each file's JPEG header for size and colour
/// and hands the bytes to the PDF unchanged - no page is ever decoded.
///
/// Only pass files written by `save_page`: a PDF ignores the EXIF rotation, so a camera
/// JPEG would come out sideways, and a progressive JPEG is not readable as /DCTDecode.
///
/// ponytail: peak is 2x the total of all page JPEGs, because printpdf holds each stream
/// and lopdf clones it at save (xobject.rs:143) - about 80 MB for 40 pages. If a scan
/// ever gets long enough to feel that, write the page objects and xref by hand (~120
/// lines): peak becomes one page, and the step becomes resumable.
pub fn pages_to_pdf(pages: &[PathBuf], out_path: &Path) -> Result<(), String> {
    // Like images_to_pdf. An empty list would otherwise write a nought-page scan.pdf,
    // and scan.pdf existing is what the app reads as "finished".
    if pages.is_empty() {
        return Err("No pages given, so the PDF would have no pages.".to_string());
    }
    // ... per page: fs::read, jpeg_shape (header only), jpeg_page(&mut doc, bytes, w, h, grey)
    let part = out_path.with_extension("part");
    // read as well as write: the %%EOF check below reads the file back, and File::create
    // opens write-only, so read_exact on it fails with "Bad file descriptor".
    let file = OpenOptions::new()
        .read(true)
        .write(true)
        .create(true)
        .truncate(true)
        .open(&part)
        .map_err(|e| failed(&part, e))?;
    let mut w = BufWriter::new(file);
    doc.with_pages(built).save_writer(&mut w, &PdfSaveOptions::default(), &mut Vec::new());
    let mut f = w.into_inner().map_err(|e| failed(&part, e.into_error()))?;
    f.flush().map_err(|e| failed(&part, e))?;
    // printpdf::save_writer returns () and drops io errors (serialize.rs:100), so this is
    // the only place a full disk or a failed serialisation is caught. lopdf ends every
    // document with "%%EOF" (writer.rs:81); no %%EOF means the file is cut off - and
    // scan.pdf existing is the app's ONLY definition of "finished".
    let mut tail = [0u8; 5];
    f.seek(SeekFrom::End(-5)).map_err(|e| failed(&part, e))?;
    f.read_exact(&mut tail).map_err(|e| failed(&part, e))?;
    if &tail != b"%%EOF" {
        return Err("The PDF was cut off while writing.".to_string());
    }
    f.sync_all().map_err(|e| failed(&part, e))?;
    std::fs::rename(&part, out_path).map_err(|e| failed(out_path, e))
}

fn jpeg_page(doc: &mut PdfDocument, jpeg: Vec<u8>, w: usize, h: usize, grey: bool) -> PdfPage {
    let dict = BTreeMap::from([
        ("Type".into(),             DictItem::Name(b"XObject".into())),
        ("Subtype".into(),          DictItem::Name(b"Image".into())),
        ("Width".into(),            DictItem::Int(w as i64)),
        ("Height".into(),           DictItem::Int(h as i64)),
        ("BitsPerComponent".into(), DictItem::Int(8)),
        ("ColorSpace".into(),       DictItem::Name(
            if grey { b"DeviceGray".into() } else { b"DeviceRGB".into() })),
        ("Filter".into(),           DictItem::Name(b"DCTDecode".into())),
    ]);
    let id = doc.add_xobject(&ExternalXObject {
        // compress: false - the bytes are already JPEG. Deflating them again would
        // contradict the /Filter and produce a file no reader accepts.
        stream: ExternalStream { dict, content: jpeg, compress: false },
        width: Some(Px(w)), height: Some(Px(h)), dpi: None,
    });
    place(id, w as f32, h as f32)          // the same maths build_page already uses
}
```

Verified against the vendored sources: `add_xobject` exists (printpdf lib.rs:386),
`XObject::get_width_height` reads External's width/height (xobject.rs:45), `into_lopdf`
honours `compress` (xobject.rs:124), printpdf's parser branches on `DCTDecode`
(deserialize.rs:1378), lopdf's writer ends with `%%EOF` (writer.rs:81), and the
header-only read `jpeg_shape` needs is `JpegDecoder::new` (image decoder.rs:30) plus
`ImageDecoder::dimensions` and `color_type` (image io/decoder.rs:9 and :12).

The one new test:

```rust
#[test]
fn page_files_go_into_the_pdf_without_being_decoded() {
    let dir = temp_path("pages"); std::fs::create_dir_all(&dir).unwrap();
    let (mut pages, mut jpeg_bytes) = (Vec::new(), 0u64);
    for n in 0..12 {                                  // 12 raw RGB pages would be 69 MB
        let p = dir.join(format!("{n:04}.jpg"));
        save_page(&test_image(1200, 1600), &p).unwrap();
        jpeg_bytes += std::fs::metadata(&p).unwrap().len();
        pages.push(p);
    }
    let out = temp_path("pages.pdf");
    pages_to_pdf(&pages, &out).unwrap();
    let pdf = std::fs::read(&out).unwrap();

    let first = std::fs::read(&pages[0]).unwrap();
    let tail = &first[first.len() - 64..];
    assert!(pdf.windows(64).any(|w| w == tail), "the page JPEG was re-encoded");
    // A re-encode or an embedded pixel buffer would be megabytes out, not kilobytes.
    assert!(pdf.len() as u64 > jpeg_bytes && (pdf.len() as u64) < jpeg_bytes + 16 * 1024);
    assert!(pdf.ends_with(b"%%EOF"));
    assert_eq!(parse_pdf(&pdf).pages.len(), 12);      // printpdf reads its own file back
}
```

---

## 5. The C surface

**This section is a pointer, not a copy.** It is built, so its rules moved next to the code
and the code snippets that used to stand here are gone — they described two functions with
no page size rung and a Swift wrapper of two calls, and by the time they were four functions
each with a struct beside it, the copy here was simply a second, older truth about a
boundary that has exactly one. A plan section is not a home
([`AGENTS.md`](./AGENTS.md)).

Where the C surface actually lives, and nowhere else:

| What | Where |
| --- | --- |
| The surface itself, hand-written, no cbindgen, no generator | [`ffi/include/freepdf.h`](./ffi/include/freepdf.h) — four functions and three structs, and the app imports it as its bridging header |
| Why it is shaped that way: what may cross, why every entry point is wrapped against panics, the order of tools inside `freepdf_scan_page`, the 3000 px cap and the page size rung underneath it, and the check | [`ffi/AGENTS.md`](./ffi/AGENTS.md) |
| The Swift side of all four calls | [`ios/FreePDF/EngineCalls.swift`](./ios/FreePDF/EngineCalls.swift), with the types it passes in [`ios/FreePDF/Engine.swift`](./ios/FreePDF/Engine.swift) |
| The four build settings that link the library, and what to know about a project file written by hand | [`ios/AGENTS.md`](./ios/AGENTS.md), "How the Rust library gets in" |

Two decisions from this section are worth keeping, because they are reasons and not code,
and both now live in [`ffi/AGENTS.md`](./ffi/AGENTS.md) as well:

- **The error buffer belongs to the caller**, which replaces a `freepdf_last_error()`
  thread-local. That is not only one function fewer — the drain `await`s a detached task
  between the call and the error read, and a thread-local would return an empty string
  there, giving "Page 12 failed: " in the one place the message is the only clue.
- **Two spellings in the Swift wrapper are load-bearing** and were found by the compiler:
  `strdup(…)!`, and `UnsafePointer<CChar>` written out. Without either, Swift cannot work
  out the element type of the array C wants and refuses the whole function. They are still
  in `EngineCalls.swift`; do not tidy them away.

### Build and link

`bash /Users/julianhahn/free-pdf/ffi/build-ios.sh` writes both libraries, one per
platform, and why there are two rather than one `lipo`'d file is in
[`ffi/AGENTS.md`](./ffi/AGENTS.md).

---

## 6. Files

| Path | What |
| --- | --- |
| `/Users/julianhahn/free-pdf/core_engine/src/pdf.rs` | + `save_page`, `pages_to_pdf`, `jpeg_shape`, `jpeg_page`, `place` |
| `/Users/julianhahn/free-pdf/core_engine/src/lib.rs` | one re-export line |
| `/Users/julianhahn/free-pdf/core_engine/tests/engine.rs` | + one test |
| `/Users/julianhahn/free-pdf/Cargo.toml` | `members = [..., "ffi"]` |
| `/Users/julianhahn/free-pdf/ffi/Cargo.toml` | `core_engine_ffi`, `[lib] name = "freepdf"`, `crate-type = ["staticlib"]` |
| `/Users/julianhahn/free-pdf/ffi/src/lib.rs` | two `extern "C"` functions, `guard`, `put`, the scan chain |
| `/Users/julianhahn/free-pdf/ffi/include/freepdf.h` | 8 lines, also the bridging header |
| `/Users/julianhahn/free-pdf/ffi/bridge_check.sh` | the FFI check (host arch) |
| `/Users/julianhahn/free-pdf/ffi/build-ios.sh` | the two cargo builds |
| `/Users/julianhahn/free-pdf/ffi/AGENTS.md` | the rules of the boundary, moved out of section 5 |
| `/Users/julianhahn/free-pdf/ios/FreePDF.xcodeproj` | one app target, four build settings. Hand-written, never opened in Xcode |
| `/Users/julianhahn/free-pdf/ios/FreePDF/Scan.swift` | the storage model and the whole state machine. Foundation only |
| `/Users/julianhahn/free-pdf/ios/FreePDF/Engine.swift` | the types the engine's answers take in Swift - `Adjustments`, `Suggestion`, `PageQuality` - and `composed()`. Foundation only, so `check/run.sh` compiles it |
| `/Users/julianhahn/free-pdf/ios/FreePDF/EngineCalls.swift` | the four FFI calls, and the only file that includes the bridging header |
| `/Users/julianhahn/free-pdf/ios/FreePDF/ScanList.swift` | the landing screen: `Scan.all()`, derived subtitles, New scan, swipe-to-delete |
| `/Users/julianhahn/free-pdf/ios/FreePDF/ScanFlow.swift` | the switch on `state`, the drain, the pages, Make PDF, Open PDF |
| `/Users/julianhahn/free-pdf/ios/FreePDF/FakeShoot.swift` | the camera stand-in: the drawn page and the `-autofake` launch argument. Not a screen any more, and it stays as long as nothing can tap a simulator |
| `/Users/julianhahn/free-pdf/ios/FreePDF/CameraView.swift` | session, preview, shutter, counter, `PageWriter` |
| `/Users/julianhahn/free-pdf/ios/FreePDF/FreePDFApp.swift` | `@main`, one `NavigationStack`, the launch sweep |
| `/Users/julianhahn/free-pdf/ios/AGENTS.md` | the rules of the storage model and the screens, moved out of sections 2 and 3 |
| `/Users/julianhahn/free-pdf/ios/check/main.swift` | the resume check, ten preconditions |
| `/Users/julianhahn/free-pdf/ios/check/run.sh` | `swiftc` over `Scan.swift` + the check, then run it |
| `/Users/julianhahn/free-pdf/ios/check/scan_check.sh` | the end-to-end check: build, shoot, kill, resume, PDF |

Export lives on `Scan` (`exportPDF()`), not in its own file: it is file work, and keeping it
in the Foundation-only file means the resume check still compiles the whole model.

There is no `Info.plist` file. Xcode 26 generates it from `INFOPLIST_KEY_…` build
settings, so a key is one line in the project rather than a file to keep in step with it.
`NSCameraUsageDescription` is one of them now; `NSUbiquitousContainers` joins it in
milestone 6, as one more setting.

---

## 7. Build order

Riskiest thing first. Each milestone ends in something that runs.

**1 — Engine.** `save_page` + `pages_to_pdf` + the one test. No phone involved. The
load-bearing unknown is whether printpdf reads back a hand-built `/DCTDecode` XObject.
Check: `cargo test --workspace` → all green (~5 s; the count is in the README, so it lives
in one place). Also confirm the runner still works:
`cargo run -p backend-core-runner -- photo.jpg -o out.pdf --scan`.

**2 — FFI.** The crate, the header, the scan chain with the resolution cap. **Done**, and
what it asserts is written down in [`ffi/AGENTS.md`](./ffi/AGENTS.md).
Check: `bash /Users/julianhahn/free-pdf/ffi/bridge_check.sh` → "bridge ok" (~1 s).
One thing turned out different: no input reaches the panic branch, because the engine has
no panic path, so that branch is checked by a Rust unit test that panics on purpose rather
than through Swift.

**3 — Resume rules.** `Scan.swift` + `check/main.swift`. **Done**, and what the model
promises is written down in [`ios/AGENTS.md`](./ios/AGENTS.md).
Check: `bash /Users/julianhahn/free-pdf/ios/check/run.sh` → "resume ok" (~2 s, no Xcode, no
simulator). Twelve moments: killed after New scan; mid-shooting (`nextPage == 9`);
mid-scanning (`unscanned == [7…12]`, pages 1-6 byte-identical after the sweep); after the
last page; with `scan.pdf` present but pages missing (`.done` wins, and the sweep leaves it
alone); with debris (`0007.part`, `.dat.nosync4f1a`, `IMG_0042.jpg`, `0003.jpeg`,
`00071.jpg`, `-123.jpg`, `0009.tmp`, `scan.part`) invisible before the sweep and gone after;
an orphan page file (must not wedge); a deleted middle page; an orphan page as the highest
number (`nextPage == 5` — never reuse a number the disk has seen); list order and the shape
of the name. Then two the user reaches without any kill: the photos deleted and the pages
kept (`.ready`, not `.empty`), and a scan whose `page/` was never made (the sweep puts it
back).
Seventeen mutations of `Scan.swift` were run against it and all seventeen aborted, including
the one named here: swap `unscanned.isEmpty` for `pages.count == photos.count`.

**4 — The app, killed mid-scan.** Xcode project, `ScanList`, `ScanFlow`, `Engine`, the
drain, and the camera stand-in. **Done**, and what the screens promise is written down in
[`ios/AGENTS.md`](./ios/AGENTS.md).
Check: `bash /Users/julianhahn/free-pdf/ios/check/scan_check.sh` → "scan ok" (~3 min).

Two things turned out different. The stand-in is not twelve lines and not just a button:
nothing can tap a simulator from a script, so it also carries the `-autofake 12` launch
argument that makes the thirteen taps, and it draws a real 12 MP photo rather than a small
one, so what the drain is measured against is what the camera will hand it. And byte-
identical pages turned out to prove nothing on their own - the engine is deterministic, so
a page scanned twice comes out the same - which is why the check compares the moment each
page was written as well.

**5 — The real camera.** `CameraView`. **Done**, and what the camera promises is written
down in [`ios/AGENTS.md`](./ios/AGENTS.md). There is no runnable check for a camera, so the
manual one still has to be walked on a phone: shoot 5 pages, force-quit while aiming at 6,
relaunch — the row says "5 pages - keep shooting" and the counter says "Page 6". Then 3
more, Scan 8 pages. Check that nothing changed under it:
`bash /Users/julianhahn/free-pdf/ios/check/scan_check.sh` → "scan ok".

Three things turned out different. **This section's rotation claim was wrong**, and
believing it would have put every page in the PDF on its side (the warning now sits in
section 3). **`FakeShoot.swift` was not deleted**: the button and the screen went, the
drawn page and `-autofake` stayed, exactly as the decision above required — and it turns
out a simulator has no camera at all, so that drawing is also the only way to work the app
without a phone. **The camera answers on its own queue**, so the shot is awaited rather
than reported through a closure: one continuation per press, resumed by whichever
AVFoundation callback comes first, which is what makes a photo that never arrives release
the shutter instead of freezing it.

**6 — sharing and the photos.** A `ShareLink` on the done screen and `Scan.deletePhotos()`.
Check: by hand on a phone - share the PDF into Files, open it there; then delete the photos
and see the scan still open, still readable, still able to change its pages.

---

## 8. What a kill costs, per phase

"Crash" covers app crash, force-quit, jetsam low-memory kill, and a phone call that leads to
a background kill. They are the same event to this design.

| Killed while… | On disk | He sees | Cost |
| --- | --- | --- | --- |
| tapping New scan | the folder, half of it, or nothing | a row "No pages yet", tap → viewfinder | nothing — `Scan.sweep()` finishes a half-made folder at the next launch |
| shooting, between shots | photos 1-11 | camera, "Page 12" (read from disk) | nothing |
| shooting, mid-write | 1-11 plus an aux file the sweep deletes | camera, "Page 12" again | **one photo** — the sheet is still in front of him |
| scanning page 13 of 40 | pages 1-12, plus `0013.part` | "12 of 40 pages scanned", continues at 13 | ~2 s of CPU |
| backgrounded with 28 of 40 done | pages 1-28 | "28 of 40 pages scanned", resumes at 29 | nothing |
| reviewing | unchanged | the same carousel | the scroll position |
| mid-retake of page 7 | `page/0007.jpg` gone, old photo still there | page 7 rescanned from the old photo | the retake, never a wrong page |
| mid-Delete page | page file gone, photo still there | that page unscanned, drain rebuilds it | the deletion |
| building the PDF | `scan.part`, swept | "ready to check", press Make PDF again | ~2 s. **No page is touched** |
| exporting | an invisible temp at the container root | the done screen, export again | nothing (worst case one duplicate PDF) |
| deleting the photos | some photos left | "photos kept", the button is still there | nothing, self-healing on one tap |

**Floor: no interruption at any instant costs more than one page, and none of them can cost
the scan.** There is no moment where losing the run means starting over, because there is no
run — only files.

The one photo is irreducible: a photo that has not reached disk does not exist. A manifest
would not help, because the manifest write is not atomic with the photo write either.

**Not covered:** power loss and kernel panic. `rename` is atomic in the namespace, but
without `F_FULLFSYNC` the bytes may not have reached storage. Every process-level kill — the
whole stated threat model — is covered, because the page cache outlives the process.

---

## 9. Memory

12 MP is 4032 x 3024. One decoded RGB page is 36.6 MB. Everything below is per page and
flat in the page count, except the PDF step.

| Moment | Peak | Grows with pages? |
| --- | --- | --- |
| shooting | ~105 MB (preview pipeline + one JPEG in flight) | no |
| scanning one page | ~280 MB | no |
| review carousel | ~85 MB (three pages at 1600 px) | no |
| building the PDF, 40 pages | ~140 MB | yes, ~2 MB per page |

**Measured, at last.** Twelve 12 MP pages through the real app on the "iPhone 17 Pro"
simulator, sampling the process every 200 ms:

| Phase | High-water mark |
| --- | --- |
| drawing twelve fake photos (the stand-in's own doing, and it goes with it) | 264 MB |
| scanning them, one at a time | 311 MB |
| building the PDF from twelve page files | 334 MB |

Read them as one rising line, not three peaks: resident memory is a high-water mark and
does not fall back, so scanning added about 47 MB over what the drawing had already
claimed, and the whole PDF step added about 23 MB — roughly the 2 MB a page this section
predicted. Nothing here grows with the page count except that last row. Two caveats: this
is the Mac process's resident size, which carries shared frameworks iOS would not count,
and iOS kills on `phys_footprint` rather than on this. It is the right order of magnitude
and nothing like the 3.1 GB the image path would have cost.

The scanning number, honestly: `deskew` is input + `to_rgb8` clone + output = ~110 MB at
full 12 MP. `sharpen` is the peak, and it is 33 bytes per pixel — `unsharpen` calls
`blur_advanced`, which allocates **two** f32 planes of `w*h*3*4` bytes (image 0.25.10
sample.rs:1437 and :1464), plus the `to_rgb8` clone, the blur output and the caller's
image. At 12 MP that is 403 MB; at the 3000 px cap (6.75 MP) it is 223 MB. Add ~60 MB of
app baseline. All three candidate designs quoted ~150 MB for this and were wrong by 2.7x.

The camera session is torn down before the drain runs (the drain lives on the scan screen,
and the session stops on disappear), so 200 MB of capture pipeline is never added to it.

The PDF step never decodes a page: it reads each JPEG's header for size and colour and
hands the bytes over verbatim. printpdf holds the 40 streams (~40 MB) and lopdf clones each
once at save (~40 MB).

For comparison, today's engine on the same input: the caller's `Vec<DynamicImage>` 1.46 GB,
plus a `to_rgb8` copy per page inside the document 1.46 GB, plus ~3 transient copies at
serialisation, plus 2x the PDF bytes ≈ **3.1 GB**. The foreground jetsam limit is roughly
50-60% of device RAM — ~1.4 GB on a 3 GB iPhone, ~2.0 GB on a 4 GB one (a jetsam report on
a 4 GB iPhone 12 reads `per-process-limit ActiveHard 2098 MB (fatal)`). So today's engine is
fatal on every iPhone at 40 pages, and at risk from 8-10 pages up if the app is
backgrounded mid-run. 280 MB against 1.4 GB is 5x headroom, and it does not grow.

No `com.apple.developer.kernel.increased-memory-limit` entitlement — it also makes a
backgrounded app easier to kill.

Disk while a 40-page scan is in progress: ~100 MB of photos, ~40 MB of pages, ~40 MB of PDF.
The delete prompt shows the measured size, not this estimate.

---

## 10. Corners cut, with the ceiling and the way up

| Cut | Ceiling | Upgrade |
| --- | --- | --- |
| pages capped at 3000 px (~257 dpi on A4) | print below ~6 pt gets soft | raise the constant; +33 bytes of peak per pixel |
| pages written at JPEG quality 45 by default (2026-08-22) | a page that is not dense text - a hard shadow, a photograph on the sheet - can look softer than the same page at Original | one switch, **Smaller pages**, off: the page is written again from its photo at quality 85, so nothing is lost while the photos are there. Once they are deleted the pages are all there is |
| the PDF step is not resumable per page | a kill costs the whole 1-3 s build, and peak grows ~2 MB per page | write the page objects and xref by hand (~120 lines) |
| `images_to_pdf` untouched | the CLI still peaks ~3.1 GB at 40 pages and can truncate on a kill | point its body at `pages_to_pdf` when the CLI needs long documents |
| no `F_FULLFSYNC` | power loss can leave a real name with garbage | `fcntl(fd, F_FULLFSYNC)` before each rename |
| no gap detector | a killed write with a second shot in flight leaves an unannounced hole | block the shutter until the write lands, or add `missing` + a banner |
| Xcode does not know about cargo | a forgotten `build-ios.sh` links yesterday's Rust | a Run Script phase before Compile Sources |
| relative library search paths | the project must stay one level under the repo root | absolute paths (not portable) |
| 512-byte error buffer | a very long path is clipped, possibly mid-UTF-8 | bigger buffer, or ask for the required size |
| export without `NSFileCoordinator`, no "exported" flag | a rare duplicate `…-2.pdf` he swipes away | none — a flag is the one thing the file system cannot express |
| portrait only | landscape shooting is not supported (a landscape sheet still works) | `AVCaptureDevice.RotationCoordinator`, one property |
| four-digit page numbers | 9999 pages per scan | five digits |
| `Scan.all()` is O(scans) | slow launch at a few hundred scans | cache in memory |
| the end-to-end check drives the app by a launch argument | it reads files, so it cannot see which screen the app is on | none while nothing can tap a simulator; a guard in `autoShoot` covers the one screen rule that matters |
| the pages are decoded while the carousel is drawn | about 40 ms of main thread per swipe | decode in a `.task` into a `@State` image |
| the folder name carries local wall-clock time | flying west, or the repeated hour when summer time ends, lists a newer scan below an older one for a few hours | build the name in `.gmt` and convert to local at display time — the name stops being the title as it stands |
| deleting the photos is final | iOS has no trash for sandbox files | none — the button says the megabytes and asks every time |
| `NSUbiquitousContainers` read once | wrong on the first install hides the Files folder forever | bump `CFBundleVersion` |

---

## 11. Deliberately not built

Manifest / SwiftData / Core Data. VisionKit (its delegate has no per-page hook, so a cancel
at page 39 loses all 39 — that is the bug, not a shortcut). HEIC anywhere. Thumbnail files.
Reorder and insert-in-the-middle. Renaming a scan. Per-page redo settings. Upload progress
UI. A page size **picker**, and with it the engine's third rung, a 1700 px longest edge —
two rungs reach the user behind one switch, and 1700 px across A4 is about 150 dpi where
reading the text back out later wants about 300 (`user-flows.md` section 7a). Background execution. A settings screen or a remembered delete choice. The document
picker as the normal destination. CloudKit. Uploading a finished scan by itself. Landscape, iPad,
widgets, Shortcuts, photo-library import, OCR. UniFFI / swift-bridge / cbindgen /
XCFramework / cdylib. `isExcludedFromBackup`. An XCTest target.

Each of those has a "add when" in the plan's decision record; none of them is needed to make
a 40-page document a PDF without losing work.


## 12. Every line of text the app shows

English is the source of truth in code. German is checked by hand, as always.

| Where | English | German |
| --- | --- | --- |
| List screen - navigation title | Scans | Scans |
| List screen - first launch, empty state | No scans yet. Tap New scan and photograph the pages, one after another. You can stop whenever you like. | Noch keine Scans. Tippe auf Neuer Scan und fotografiere die Seiten, eine nach der anderen. Du kannst jederzeit aufhören. |
| List screen - primary button (was "+ Document") | New scan | Neuer Scan |
| List row - title (folder date, formatted) | 11 Aug 2026, 20:14 | 11. Aug. 2026, 20:14 |
| List row - subtitle, State.empty (nothing yet) | No pages yet | Noch keine Seiten |
| List row - subtitle, State.shooting (left mid-capture: photos, nothing scanned) | 8 pages - keep shooting | 8 Seiten - weiter fotografieren |
| List row - subtitle, State.scanning (scanning was interrupted) | 12 of 40 pages scanned | 12 von 40 Seiten gescannt |
| List row - subtitle, State.ready (all scanned, no PDF) | 40 pages - ready to check | 40 Seiten - bereit zum Prüfen |
| List row - subtitle, State.done | 40 pages - PDF ready | 40 Seiten - PDF fertig |
| List row - subtitle, State.done after the photos were deleted | 40 pages - PDF ready, photos deleted | 40 Seiten - PDF fertig, Fotos gelöscht |
| List row - swipe action | Delete | Löschen |
| Camera screen - every line of it, including the ones that only appear when something goes wrong | moved to [`ios/AGENTS.md`](./ios/AGENTS.md), because the screen is built. The one line with no code behind it, the corner thumbnail's "Retake page 7", is parked in the [README](./README.md) with its German | (same) |
| Check screen - while pages are still being scanned (the automatic step, in progress) | Scanning page 12 of 40 | Seite 12 von 40 wird gescannt |
| Check screen - line under the progress bar | You can close the app. It carries on from here. | Du kannst die App schließen. Es geht danach weiter. |
| Check screen - navigation title in the carousel (the review step) | Page 5 of 40 | Seite 5 von 40 |
| Check screen - toolbar action per page | Retake this page | Diese Seite neu fotografieren |
| Check screen - a page the engine could not scan | This page could not be scanned. | Diese Seite konnte nicht gescannt werden. |
| Check screen - primary button (was "Create PDF") | Make PDF | PDF erstellen |
| Check screen - while the PDF is being written | Making the PDF… | PDF wird erstellt … |
| Done screen - title | PDF ready | PDF fertig |
| Done screen - button | Open PDF | PDF öffnen |
| Done screen - button (this is "keep the photos too": doing nothing keeps them) | Done | Fertig |
| Done screen - destructive action, quiet, below the two buttons (this is "keep only the PDF") | Delete the 40 photos (78 MB) | Die 40 Fotos löschen (78 MB) |
| Done screen - line under that action | The PDF stays. Deleted photos cannot be brought back. | Das PDF bleibt. Gelöschte Fotos kann man nicht zurückholen. |
| Done screen - the export, and the only one there is (ShareLink) | Share PDF | PDF teilen |
| The page size setting - the switch **Smaller pages**, its line, its two spoken hints and the done screen's size line | new on 2026-08-22 and **not approved yet**: they sit in [`user-flows.md`](./user-flows.md) sections 4c, 7 and 9, which is where the app's copy tables live | (same) |
| Check after the first photo - all five of its lines | in [`user-flows.md`](./user-flows.md) section 4c, because the screen is built | (same) |
| Info.plist NSCameraUsageDescription - the ONLY place the word "document" is allowed, because there it means the paper in his hand | FreePDF uses the camera to photograph the pages of your document. | FreePDF nutzt die Kamera, um die Seiten deines Dokuments zu fotografieren. |
| OPTIONAL, only if you want the final choice as an explicit two-way dialog instead of one quiet button - dialog title | Keep the photos? | Fotos behalten? |
| OPTIONAL two-way dialog - keep option | Keep them (78 MB) | Behalten (78 MB) |
| OPTIONAL two-way dialog - delete option (destructive) | Delete them | Löschen |
