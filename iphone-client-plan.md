# FreePDF Scan — iPhone client

One scan is one directory. The files in it are the only state. Nothing can disagree with
the disk after a crash, because there is nothing else to disagree.

Goal: photograph the pages of a document, get a clean PDF into iCloud, and be able to stop
at any moment without losing a thing. Offline, no network calls anywhere.

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
Page 7 was not saved: the iPhone is out of storage. Pages 1-6 are safe.
                             / Seite 7 wurde nicht gespeichert: Auf dem iPhone ist kein
                               Speicherplatz mehr frei. Seiten 1-6 sind sicher.
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
progress bar, and what makes changing the pages after Make PDF safe. Two screens in this
section are not built yet, and they are what is left of it.

### Camera

Custom `AVCaptureSession`, `.photo` preset, back wide angle, **video input only** (so no
microphone usage key), `startRunning()` off the main thread, `stopRunning()` on disappear.
JPEG asked for at capture:

```swift
let s = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
s.photoQualityPrioritization = .speed          // flat paper gains nothing from fusion
let n = slot ?? scan.nextPage                  // decided NOW, on the main actor
output.capturePhoto(with: s, delegate: PageWriter(url: scan.photoURL(n)))
```

A settings object may not be reused (a second capture with the same uniqueID throws), so a
fresh one per press. `PageWriter` is one object per shot, carries `n` as an immutable field,
writes `.atomic`, and is retained in an `inFlight` set until `didFinishCaptureFor`. Because
the number travels with the writer, out-of-order completion cannot swap pages.

Default 12 MP: `maxPhotoDimensions` defaults to the smallest supported, so writing no code
gives 12 MP rather than the 48 MP capture. Portrait-locked, which is what makes the EXIF
rotation come out right for free.

**The write failure must reach the UI.** `try?` here is the product's one unforgivable bug:
a full disk at page 25 would otherwise keep the shutter clicking and produce a 24-page PDF
of a 40-page contract.

### Export

```
copy scan.pdf ─▶ <container>/<temp name>          (container root: invisible in Files)
move           ─▶ <container>/Documents/Scan 2026-08-11 20.14.pdf     (atomic rename)
```

`url(forUbiquityContainerIdentifier: nil)` off the main thread. A `-2` suffix loop covers
two scans finished in the same minute. `copyItem`, not `setUbiquitous`: the move would
consume the local file, and `scan.pdf` stays the record. Nothing waits for the upload — the
system daemon finishes it with the app dead or the phone offline, so there is no progress
bar and no background mode. Container nil (signed out, iCloud Drive off, out of quota) is
one branch: keep the PDF local, show "iCloud is off, so the PDF is only on this iPhone."
plus a `ShareLink`.

Then, and only then, the quiet destructive button: **Delete the 40 photos (78 MB)**, size
measured with `attributesOfItem`, asked every time, never remembered. Doing nothing is the
other half of the choice, so "keep the photos" needs no button.

---

## 4. Engine changes

All additive. `backend-core-runner` calls every public engine function and is **not
affected by any of them**.

| Change | Why the goal is unreachable without it | Breaks the runner |
| --- | --- | --- |
| ADD `pdf::save_page(img, path)` | The resume rule is "page 7 exists = page 7 is done", which is only true if a page can never appear under its real name half-written. Its bytes must also be the exact stream the PDF embeds, or every page is compressed twice. It must be the engine that writes it: a PDF ignores EXIF rotation, so a page written by Swift's ImageIO lands sideways, and a progressive JPEG is not readable as `/DCTDecode`. | no |
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

Built, and its rules now live next to it in [`ffi/AGENTS.md`](./ffi/AGENTS.md): what may
cross the boundary, why every entry point is wrapped against panics, the order of tools
inside `freepdf_scan_page`, the 3000 px cap, and the check. What the app has to know is
the header it imports as its bridging header,
[`ffi/include/freepdf.h`](./ffi/include/freepdf.h) — hand-written, no cbindgen, no
generator:

```c
/* 0 = ok. Anything else = failed, and `error` holds a sentence (may be NULL). */
int32_t freepdf_scan_page(const char *photo_path, const char *out_page_path,
                          char *error, size_t error_size);
int32_t freepdf_pages_to_pdf(const char *const *page_paths, size_t page_count,
                             const char *out_pdf_path,
                             char *error, size_t error_size);
```

The error buffer replaces a `freepdf_last_error()` thread-local. That is not only one
function fewer — the drain `await`s a detached task between the call and the error read,
and a thread-local would return an empty string there, giving "Page 12 failed: " in the one
place the message is the only clue.

Swift wrapper, the whole thing. This exact text was compiled and linked against the real
library, and the sentence came back out of it, so it can be copied as it stands. Two
spellings in it are load-bearing and were found by the compiler: `strdup(…)!`, and
`UnsafePointer<CChar>` written out — without either, Swift cannot work out the element
type of the array C wants and refuses the whole function.

```swift
enum Engine {
    struct Failed: Error, LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }
    static func scanPage(_ photo: URL, into out: URL) throws {
        try call { e, n in freepdf_scan_page(photo.path, out.path, e, n) }
    }
    static func pagesToPDF(_ pages: [URL], out: URL) throws {
        let owned = pages.map { strdup($0.path)! }
        defer { owned.forEach { free($0) } }
        var c: [UnsafePointer<CChar>?] = owned.map { UnsafePointer<CChar>($0) }
        try call { e, n in freepdf_pages_to_pdf(&c, c.count, out.path, e, n) }
    }
    private static func call(_ body: (UnsafeMutablePointer<CChar>, Int) -> Int32) throws {
        var buf = [CChar](repeating: 0, count: 512)
        if body(&buf, 512) != 0 { throw Failed(message: String(cString: buf)) }
    }
}
```

### Build and link

`bash /Users/julianhahn/free-pdf/ffi/build-ios.sh` writes both libraries, one per
platform, and why there are two rather than one `lipo`'d file is in
[`ffi/AGENTS.md`](./ffi/AGENTS.md). The four build settings that pick between them, and
the three things worth knowing about a project file written by hand, are now in
[`ios/AGENTS.md`](./ios/AGENTS.md).

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
| `/Users/julianhahn/free-pdf/ios/FreePDF/Engine.swift` | the two FFI calls (~20 lines) |
| `/Users/julianhahn/free-pdf/ios/FreePDF/ScanList.swift` | the landing screen: `Scan.all()`, derived subtitles, New scan, swipe-to-delete |
| `/Users/julianhahn/free-pdf/ios/FreePDF/ScanFlow.swift` | the switch on `state`, the drain, the pages, Make PDF, Open PDF |
| `/Users/julianhahn/free-pdf/ios/FreePDF/FakeShoot.swift` | the camera stand-in and the `-autofake` launch argument. Deleted in milestone 5 |
| `/Users/julianhahn/free-pdf/ios/FreePDF/CameraView.swift` | session, preview, shutter, counter, `PageWriter` |
| `/Users/julianhahn/free-pdf/ios/FreePDF/FreePDFApp.swift` | `@main`, one `NavigationStack`, the launch sweep |
| `/Users/julianhahn/free-pdf/ios/FreePDF/FreePDF.entitlements` | iCloud Documents only |
| `/Users/julianhahn/free-pdf/ios/AGENTS.md` | the rules of the storage model and the screens, moved out of sections 2 and 3 |
| `/Users/julianhahn/free-pdf/ios/check/main.swift` | the resume check, ten preconditions |
| `/Users/julianhahn/free-pdf/ios/check/run.sh` | `swiftc` over `Scan.swift` + the check, then run it |
| `/Users/julianhahn/free-pdf/ios/check/scan_check.sh` | the end-to-end check: build, shoot, kill, resume, PDF |

Export lives on `Scan` (`exportPDF()`), not in its own file: it is file work, and keeping it
in the Foundation-only file means the resume check still compiles the whole model.

There is no `Info.plist` file. Xcode 26 generates it from `INFOPLIST_KEY_…` build
settings, so a key is one line in the project rather than a file to keep in step with it.
`NSCameraUsageDescription` joins it in milestone 5 and `NSUbiquitousContainers` in
milestone 6, each as one more setting.

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

**5 — The real camera.** `CameraView`, and `FakeShoot.swift` deleted — it reaches out of
itself in exactly two lines, and the compiler points at both. There is no runnable check
for a camera; the documented manual one is: shoot 5 pages, force-quit while aiming at 6,
relaunch — the row says "5 pages - keep shooting" and the counter says "Page 6". Then 3
more, Scan 8 pages.

One thing to decide before deleting the file rather than after: `-autofake` is what makes
the milestone 4 check run without hands, and it lives in there. Keeping the drawing and
the argument and deleting only the button and its screen keeps the only end-to-end check
there is, and milestone 6 needs it too.

**6 — iCloud and the photos.** `Scan.exportPDF()`, the done screen, entitlement and plist.
Check: with iCloud signed in (`xcrun simctl icloud_sync booted` on the simulator),
`find ~/Library/Mobile\ Documents -path '*iCloud~com~julianhahn~freepdf/Documents/*.pdf' -size +1k | grep . || echo FAIL`
— on the Mac that only finds the file if it really went up.

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
UI. Background execution. A settings screen or a remembered delete choice. The document
picker as the normal destination. CloudKit. In-progress scans in iCloud. Landscape, iPad,
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
| Camera screen - page counter, top centre | Page 7 | Seite 7 |
| Camera screen - primary button (this is the automatic step, named by its verb) | Scan 8 pages | 8 Seiten scannen |
| Camera screen - primary button while nothing is photographed yet (disabled) | Photograph at least one page | Mindestens eine Seite fotografieren |
| Camera screen - back label (there is no Save button, because there is nothing to save) | Scans | Scans |
| Camera screen - action on the corner thumbnail of the last shot | Retake page 7 | Seite 7 neu fotografieren |
| Camera screen - a photo could not be written (never swallow this) | Page 7 was not saved: the iPhone is out of storage. Pages 1-6 are safe. | Seite 7 wurde nicht gespeichert: Auf dem iPhone ist kein Speicherplatz mehr frei. Seiten 1-6 sind sicher. |
| Camera screen - camera access denied | FreePDF needs the camera to photograph the pages. | FreePDF braucht die Kamera, um die Seiten zu fotografieren. |
| Camera screen - camera access denied, button | Open Settings | Einstellungen öffnen |
| Check screen - while pages are still being scanned (the automatic step, in progress) | Scanning page 12 of 40 | Seite 12 von 40 wird gescannt |
| Check screen - line under the progress bar | You can close the app. It carries on from here. | Du kannst die App schließen. Es geht danach weiter. |
| Check screen - navigation title in the carousel (the review step) | Page 5 of 40 | Seite 5 von 40 |
| Check screen - toolbar action per page | Retake this page | Diese Seite neu fotografieren |
| Check screen - a page the engine could not scan | This page could not be scanned. | Diese Seite konnte nicht gescannt werden. |
| Check screen - primary button (was "Create PDF") | Make PDF | PDF erstellen |
| Check screen - while the PDF is being written | Making the PDF… | PDF wird erstellt … |
| Done screen - title | PDF ready | PDF fertig |
| Done screen - where it went | In iCloud Drive › FreePDF › Scan 2026-08-11 20.14.pdf | In iCloud Drive › FreePDF › Scan 2026-08-11 20.14.pdf |
| Done screen - button | Open PDF | PDF öffnen |
| Done screen - button (this is "keep the photos too": doing nothing keeps them) | Done | Fertig |
| Done screen - destructive action, quiet, below the two buttons (this is "keep only the PDF") | Delete the 40 photos (78 MB) | Die 40 Fotos löschen (78 MB) |
| Done screen - line under that action | The PDF stays. Deleted photos cannot be brought back. | Das PDF bleibt. Gelöschte Fotos kann man nicht zurückholen. |
| Done screen - iCloud is signed out, off, or full | iCloud is off, so the PDF is only on this iPhone. | iCloud ist aus, das PDF liegt nur auf diesem iPhone. |
| Done screen - fallback button in that case (ShareLink) | Share PDF | PDF teilen |
| Info.plist NSCameraUsageDescription - the ONLY place the word "document" is allowed, because there it means the paper in his hand | FreePDF uses the camera to photograph the pages of your document. | FreePDF nutzt die Kamera, um die Seiten deines Dokuments zu fotografieren. |
| OPTIONAL, only if you want the final choice as an explicit two-way dialog instead of one quiet button - dialog title | Keep the photos? | Fotos behalten? |
| OPTIONAL two-way dialog - keep option | Keep them (78 MB) | Behalten (78 MB) |
| OPTIONAL two-way dialog - delete option (destructive) | Delete them | Löschen |
