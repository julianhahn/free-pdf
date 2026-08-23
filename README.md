# FreePDF - scan paper to PDF, entirely offline

Photograph the pages of a paper document, get one clean PDF. Everything happens on the
device: no network calls anywhere, no account, no server.

Four parts:

- **`core_engine`** (Rust) - all image and PDF work. One function per step.
- **`ffi`** (Rust) - the one library file a phone app links into itself, and the four C
  functions it calls.
- **clients** - the user interface. The client decides the order of the steps and shows
  each one. The first graphical client is the iPhone app; `backend-core-runner` is the
  command-line one, and it is how the engine gets exercised without a phone.
- **`client-guide-design-system`** - how every client looks and behaves: the tokens, the
  components with their states and their English and German words, and what a client may
  decide for itself. Written once, rebuilt natively per client.

The engine offers single tools; the client owns the order. Nothing runs by itself, so the
user can step in at any point: find the sheet, straighten it, brighten it, sharpen it -
each is its own call, each can be skipped, redone, or corrected by hand.

Every command in this file runs from the repository root, `/Users/julianhahn/free-pdf`.

## Start here

```sh
cargo test --workspace
```

68 green on a Mac, 65 elsewhere - three tests need `sips` for HEIC. Counted on
2026-08-22: 52 in `core_engine/tests/engine.rs`, 8 in `ffi/src/lib.rs` and 5 in
`backend-core-runner` here, plus that crate's 3 HEIC tests on a Mac. Then read
[Next steps](#next-steps): it is the one place that says what is being built right now, and
every session leaves it correct.

## What the engine does today

| `core_engine` function | What it does |
| --- | --- |
| `load_image(path)` | Reads a photo or scan and turns it upright, using the camera rotation the phone stored in the file. |
| `find_paper(img)` | Finds the sheet in a photo: the box to cut to, its four corners, and which pixels are paper. |
| `deskew(img, corners)` | Pulls those four corners into a rectangle, so a sheet photographed at an angle comes out as if seen from straight above. |
| `suggest_straightening(img)` | Reads the lines of writing and says how crooked they are. Needs neither the corners nor the sheet. |
| `straighten(img, degrees)` | Turns the picture by that much, cutting in slightly so no empty corners are left. |
| `suggest_levels(img)` | Measures where the paper and the writing sit, and proposes a brightness stretch. Measures the sheet only, not the table around it. |
| `apply_levels(img, l)` | Carries out that stretch: paper becomes white, writing black, colour cast gone. |
| `sharpen(img, r)` | Makes edges crisper. |
| `rotate(img, degrees)` | Quarter turns. |
| `crop(img, x, y, w, h)` | Cuts to the box the user drew. Refuses a box that does not fit. |
| `to_grayscale(img)` | Drops the colour. |
| `fit_within(img, edge)` | Shrinks the page until neither edge is longer than that, keeping its shape. Never enlarges, and refuses a bound too small to read. |
| `images_to_pdf(imgs, out)` | One page per image, A4, orientation follows the image, JPEG-compressed inside. |
| `save_page(img, path, quality)` | Writes one finished page as the JPEG the PDF will embed later, with its Huffman tables rebuilt from the page's own symbol counts - the same pixels in fewer bytes. The file wears its real name only once it is whole. `PageQuality::UNCHANGED` writes the page the engine has always written, byte for byte; a lower `jpeg_quality` writes a smaller one. A non-zero `longest_edge` is refused here, because shrinking belongs where the size cap already is. |
| `pages_to_pdf(pages, out)` | The same PDF, built from page files instead of images: each JPEG goes in untouched and is never decoded, so a forty page scan fits in a phone's memory. |

To watch it work on a real photo:

```sh
cargo run -p backend-core-runner -- <your-photo>.jpg -o out.pdf --scan
```

`--scan` is shorthand for the four tools a photo of a document usually wants: deskew,
straighten, levels, sharpen at radius 0.6. Every tool can also be asked for on its own.

`--quality <1..100>` and `--long-edge <px>` say how small the pages should be, and are the two
numbers a client's page size setting is built out of. Measured on 2026-08-23 over the thirteen
real photographed sheets in `test_images/`: with no flag the PDF is 1,078,248 bytes for a
typical one, 526,077 at `--quality 45` and 180,962 at `--quality 45 --long-edge 1700`. Across
all thirteen that is **about 51% off** at quality 45 and **about 82%** with the 1700 px edge.

**Name the baseline whenever you quote a share.** With no flag the runner builds the PDF
through `images_to_pdf`, which gets no Huffman recode, so its Original is 8 to 13% fatter than
the page the app writes and its shares read that much kinder. Against the app's own Original -
`save_page` at quality 85, recode included - the same two rungs are **about 45% off** at
quality 45 (40 to 68% across the thirteen) and **about 81%** at 1700 px (76 to 92%). Quality 45
is invisible at 100% zoom on real paper, fine print and long digit strings included; the 1700
px edge is visibly softer.

## Next steps

Riskiest thing first. Each milestone ends in something that runs, and every check is one
command. Full text: [plan section 7](./iphone-client-plan.md#7-build-order); the
file-by-file list is [plan section 6](./iphone-client-plan.md#6-files).

**Now: the style is decided, and the client gets rebuilt in it.** Julian chose it on
2026-08-13: one style, defined once and rebuilt natively in every client, because a
platform-native system look is by definition not recognizable across platforms
([the style](./client-guide-design-system/AGENTS.md)). The six milestones above are all built
and walked on a phone, so what is being worked on has moved from the engine to the client.
Two documents carry it: [`user-flows.md`](./user-flows.md), which is every flow
the app should have and what control each engine tool gets, and
[`client-guide-design-system/`](./client-guide-design-system/AGENTS.md), which is how a
client looks. The reason there is any of this: **the app can reach almost none of the
engine.** Grey, brightness, sharpening, straightening, cropping, rotating, paper finding,
page size, resolution - none of it had a control anywhere. The client called one fixed chain
and that was all a user got. All of it has a control now except two deliberate non-choices:
resolution (row 7 below) and paper size (DECISIONS 6).

The order from here, and nothing after step 1 can start before it:

| # | What | Who |
| --- | --- | --- |
| 1 | **done** on 2026-08-14 for the seven flow screens ([`TASKS.md`](./TASKS.md) task 12). What is still unapproved: the remaining components, one by one. Three stand there today - scan row, buttons, adjust; the rest of [`components.md`](./client-guide-design-system/components.md) still has to be drawn and looked at. | Julian, by looking |
| 2 | **done** - the C boundary is wide enough for Adjust: `freepdf_adjust_page` takes the photo path, the page path and one `FreepdfAdjustments` struct of all the values. One function, not seven. | engine + ffi |
| 3 | Rebuild the iPhone client against the approved components and the flows - which is also when the sixteen capabilities get their controls. Built, screen by screen: [`TASKS.md`](./TASKS.md) 14 to 28 are all done, so every screen exists, every value the user sets survives a kill in `state/NNNN.txt`, and the name he types is the scan's name. Adjust brought a fourth C function with it, `freepdf_suggest_adjustments`, so every control opens on what the engine would have chosen. | client agent |
| 4 | **done** on 2026-08-17 ([`TASKS.md`](./TASKS.md) 29) - the engine could not find the sheet on a lit desk, so every page came out uncut. `find_paper` now takes the brightness area only as a rough guess and then follows the edges of the paper: it marches outward along every row and column until it crosses a step from paper to table, fits the four sides through those places, and takes the corners from where the sides cross. Checked by eye on twelve real photos, all twelve cut to the sheet. [`TASKS.md`](./TASKS.md) 30 is the small client half of it, and is still open. | engine agent |
| 6 | **done** on 2026-08-18 ([`TASKS.md`](./TASKS.md) 32) - the pages screen carries both actions as controls under the carousel: Adjust page, and Shoot another page dead until the scan is finished. The "…" menu is retake and delete only. [`TASKS.md`](./TASKS.md) 33 is done with it - `scan_check.sh` now adds three pages to a
finished scan and the camera stays up for all three, so nothing had to change in the
camera; [`TASKS.md`](./TASKS.md) 34 is done too - after the first photo of a scan the app
shows the page that photo becomes, once, with retake or "Photograph the rest". [`TASKS.md`](./TASKS.md) 35
closes the camera work - the last photo taken sits small in a corner of the viewfinder, so he
sees which sheet that was and not only a number. | client agent |
| 7 | **done** on 2026-08-22 ([`TASKS.md`](./TASKS.md) 36 to 38; 39 and 40 are the two things the same session measured and refused, and they are answers rather than open work) - how small a page is written is a choice, and the app makes it. `save_page` rebuilds each page's Huffman tables from its own symbol counts, so the same pixels cost fewer bytes; then it took a `PageQuality` and `freepdf_scan_page` / `freepdf_adjust_page` took a `FreepdfPageQuality *` beside it, NULL still meaning Original; then the app made quality 45 its default in `quality.txt` and put one switch, **Smaller pages**, on the check after the first photo and on the pages screen. Two rungs reach the user and no more. The engine's 1700 px rung is deliberately not offered - about 150 dpi on A4, and reading the text back out later wants about 300 - which is the one of the sixteen capabilities, resolution, that stays without a control on purpose. All of it was built on Linux and checked on a Mac on 2026-08-23: `cargo test --workspace`, `bridge_check.sh`, `run.sh` and `scan_check.sh` all pass, so **the Swift compiles and the app runs**, and the byte figures were remeasured on real paper (row 10). **One thing is open**: the five new lines of text wait for Julian's approval. | engine + ffi + client |
| 5 | **done** on 2026-08-18 ([`TASKS.md`](./TASKS.md) 31) - the automatic run no longer refuses a sheet that leaves the frame. It cuts on the points where the paper crosses the edge, exactly as Adjust already did, and the pages screen puts a calm note under such a page saying it is not the whole sheet, with the retake that already exists. Checked against the twelve real photos: eleven byte for byte as before, `runs_off_1.jpg` cut. | engine + client |
| 8 | **open** - the five lines of text the page size setting adds are new words and none is approved: the switch **Smaller pages** / **Kleinere Seiten**, its line "About half the file size. Switch it off if this page looks too soft.", the two spoken hints, and the done screen's "This PDF is 1.3 MB." They are in the code so no screen is mute, written in the voice of the tables around them, and they are marked as waiting in [`user-flows.md`](./user-flows.md) sections 4c, 7 and 9. Nothing already approved was reworded, and nothing was added to the design system's own tables: a client agent may not invent copy ([`client-guide-design-system/AGENTS.md`](./client-guide-design-system/AGENTS.md)), so the words wait in the app's own copy tables until he says yes. | Julian, by reading |
| 9 | **open, smaller than it was** - the page size work now builds and runs: on 2026-08-23 `scan_check.sh` compiled the app and drove it in the "iPhone 17 Pro" simulator, so the Swift is no longer right by inspection only. Two questions are left and only a phone in a hand answers them: whether two switches stacked in the pages footer and one above the two buttons on the check screen read as one setting or as clutter, and how long the re-run feels when the switch is flipped on the check screen, where the old picture stays up until the new one lands. The third question this row used to ask - whether "About half the file size" is honest - is answered: **yes**, 45% off the page the app writes, median over thirteen real photographed sheets, and the fine print survives it. | Julian, on a phone |
| 10 | **done** on 2026-08-23 - the measurement only a Mac can make. Every byte figure in the repository came from synthetic photographs of synthetic glyphs; the runner was run by hand over the thirteen real sheets in the gitignored `test_images/phone/` at all three rungs and the pages were looked at in Preview. Two figures had drifted: the 1700 px rung is **about 81%** off the app's page, not 71%, and the Huffman recode is **8 to 13%** on a text page, not 5 to 9%. Quality 45 held at **about 45%**. Corrected in README, TASKS 36 and 37, `core_engine/AGENTS.md`, `pdf.rs`, `rehuff.rs`, `tests/engine.rs` and `Engine.swift`, each with its baseline named. `LEAST_PAGE_SAVING` did not move - all thirteen real pages sit under it, which is the reason its test keeps the synthetic gradient fixture. | engine, on a Mac |

```sh
cd storybook && npm install && npm run storybook    # step 1 happens here
```

**The camera has seen a phone, once.** On an iPhone 13 on 2026-08-12 it shot a portrait
sheet and the PDF came out upright, which settles `videoRotationAngle = 90` - the one number
in the camera that was triangulated rather than measured. The commands that put a build on a
phone are in [`ios/AGENTS.md`](./ios/AGENTS.md).

Milestone 6 is deliberately smaller than it was written: the automatic upload into the app's
own iCloud container is gone, and a `ShareLink` is the whole export
([plan section 3](./iphone-client-plan.md#3-screens) says why and what that deleted).

| # | State | What gets built | Check |
| --- | --- | --- | --- |
| 1 | **done** | `save_page`, `pages_to_pdf`, `place(...)` in the engine. | `cargo test --workspace`, and `--scan` on any photo still produces a PDF |
| 2 | **done** | `ffi/`: one `staticlib` the app links into itself, the hand-written `ffi/include/freepdf.h`, and four C functions: `freepdf_scan_page`, `freepdf_suggest_adjustments`, `freepdf_adjust_page` and `freepdf_pages_to_pdf` - the page size rung came as a parameter on the two that write a page, not as a fifth function. ([rules](./ffi/AGENTS.md)) | `bash ffi/bridge_check.sh` -> "bridge ok" (~1 s, host architecture, **needs a Mac**: the Swift half will not compile anywhere else. Run on a Mac 2026-08-23, all eight assertions green, the page size rung's five among them) |
| 3 | **done** | `ios/FreePDF/Scan.swift` plus `ios/check/`: the folder layout, the derived step, the sweep. Foundation only. ([rules](./ios/AGENTS.md)) | `bash ios/check/run.sh` -> "resume ok" (~2 s, no Xcode) |
| 4 | **done** | The Xcode project and the app: list, flow, the scan loop, the FFI calls (two then, four now), and the camera stand-in with its `-autofake` launch argument. ([rules](./ios/AGENTS.md)) | `bash ios/check/scan_check.sh` -> "scan ok" (~3 min, "iPhone 17 Pro" simulator) |
| 5 | **done** | `ios/FreePDF/CameraView.swift`: the session, the preview, the shutter and `PageWriter`. The stand-in lost its button and kept its drawing. ([rules](./ios/AGENTS.md)) | `bash ios/check/scan_check.sh` still says "scan ok"; the camera itself is by hand: shoot 5 pages, force-quit while aiming at 6, relaunch - the row reads "5 pages - keep shooting" and the counter says "Page 6" |
| 6 | **done** | A `ShareLink` on the done screen, and `Scan.deletePhotos()` behind "Delete the 12 photos (78 MB)". The automatic iCloud upload was [dropped on purpose](./iphone-client-plan.md#3-screens). | By hand: share the PDF into Files and open it there; then delete the photos and see the scan still readable and still able to change its pages |

### Parked

Things noticed but not scheduled.

- **The corner thumbnail is not tappable.** The thumbnail itself was built on 2026-08-18
  ([`TASKS.md`](./TASKS.md) 35), but [plan section
  12](./iphone-client-plan.md#12-every-line-of-text-the-app-shows) gives it an action reading
  "Retake page 7" / "Seite 7 neu fotografieren", and that is the one line of that table with
  no code behind it. Retaking works from the check screen already, so this only shortens four
  taps to two - worth about fifteen lines: one more piece of view state for the page the next
  shot goes back to.
- **Tesseract cannot go into the Rust bundle.** Asked and answered on 2026-08-22, written up
  as [`TASKS.md`](./TASKS.md) 40. It builds and it works well - 917 ms and 48 MB a page,
  99.92% of German characters right, and no network call - but **no crate builds it for
  `aarch64-apple-ios`**: all seven read the build machine's settings, and one downloads its
  own sources at compile time. Doing it anyway means our own C++ cross-build for two Apple
  platforms, +10.8 MB in the app, and C++ exceptions under a repository whose rule is that
  nothing in the dependency tree is C - and `catch_unwind` does not catch a C++ exception.
  The way in, when OCR is picked up: the engine draws the invisible text layer (about 42
  lines, no dependency, no bundle bytes) and the words come from Apple's own on-device Vision
  framework in the client. `ocrs`, the pure-Rust option, is out for German - its alphabet is
  96 ASCII characters, so the umlauts come back as `?`.
- **A bilevel CCITT-G4 rung reaches 93.5% off**, which no JPEG rung comes near: 40 pages to
  2.7 MB. Written up in full as [`TASKS.md`](./TASKS.md) 39. A pure-Rust G4 encoder was
  prototyped and verified at 201 lines - no dependency, and the format is the one PDF has
  embedded since 1.0. It was **rejected, not deferred**,
  and for one reason: it is one bit per pixel, so something has to decide the threshold, and
  Otsu silently deletes 39-42% of faint pencil, turns a red stamp into flat print, and takes
  a photograph on the page to PSNR 14.8 dB. Silently is the word that kills it - a page that
  lost the pencil still looks like a clean page. It is the best codec there is for text, so
  the way in is not a fourth rung on the switch: it is a **suggest-half that refuses an
  unsafe page**, in the engine's own suggest-then-apply shape - measure the page, and say
  "not this one" for pencil, colour or a photograph. That is a design task, not an encoder
  task, and the encoder is the part already known to work.
- **Four compression levers were measured and are dead ends.** Chroma subsampling is
  impossible with `image` 0.25 at all - it hardcodes h:1, v:1 - and would need a different
  encoder. `to_grayscale` as a compression lever is 7.1%, which is not worth spending the
  colour on. 4-bit grey measured **larger** than grey at quality 65. Flate over the PDF's
  non-image streams saves 0 bytes, because the pages are already the whole file, and
  PDF-1.5 object streams save 0.07%. None of these is worth trying again; that is why they
  are written down.
- **~~Every compression number comes from synthetic glyphs.~~ Closed on 2026-08-23** by
  hand, on Julian's Mac, over the thirteen real photographed sheets in the gitignored
  `test_images/phone/`: `--scan`, then `--scan --quality 45`, then the same with
  `--long-edge 1700`, and the pages looked at in Preview. Two of the three shares had
  drifted and are corrected everywhere; the recode read a little low. The measurement is
  reproducible but not repeatable in CI - `test_images/` may never be committed or read
  from code ([`AGENTS.md`](./AGENTS.md)), so a future agent has to redo it by hand.
- **Two small inconsistencies the page size work found and left alone.** `ios/check/run.sh`
  has no assertion for the three `quality.txt` rules (an absent file reads as `small`, the
  sweep keeps it, one write/read round trip) - the rule is written in
  [`ios/AGENTS.md`](./ios/AGENTS.md) and the assertion is not. And on the pages screen the
  Grey switch stays live once the photos are deleted while the new size switch is frozen;
  neither can rewrite a page without its photo, so one of the two is wrong and it is
  probably Grey.
- **Forty pages on a real phone is still unweighed.** Twelve were measured on the simulator
  and the whole run peaked at 334 MB, which is comfortable
  ([plan section 9](./iphone-client-plan.md#9-memory)) - but that number is the Mac
  process's resident size, and what iOS kills on is `phys_footprint`. A device run with
  Instruments is what would settle it.

## Where to find what

Rules sit next to the thing they govern, so working on a file means reading the AGENTS.md
beside it - not this page.

| Where | What is written there |
| --- | --- |
| [`AGENTS.md`](./AGENTS.md) | How to work in this repository, and the three things that must stay true whatever gets built. |
| [`core_engine/AGENTS.md`](./core_engine/AGENTS.md) | The shape of an engine function: suggest-then-apply, refuse instead of guess, what the public API costs, and the engine's own limits. |
| [`core_engine/tests/AGENTS.md`](./core_engine/tests/AGENTS.md) | How to add a test: the fixtures that already exist, temp file names, and which assertions must never be relaxed. |
| [`ffi/AGENTS.md`](./ffi/AGENTS.md) | The C boundary: what may cross it, why every entry point is wrapped against panics, the order of tools a photo goes through, and the check. |
| [`ios/AGENTS.md`](./ios/AGENTS.md) | The phone side: one scan is one directory, the three rules that carry it, the step derived from the files, the screens and the drain, how the Rust library gets linked, and the two checks. |
| [`backend-core-runner/AGENTS.md`](./backend-core-runner/AGENTS.md) | The tool order, which is a contract; flags, messages and exit codes; HEIC. |
| [`iphone-client-plan.md`](./iphone-client-plan.md) | The authority on what is not built yet, in twelve numbered sections: the screens, the camera, the export, memory, and every line of UI text in English and German. A section moves out of it into an AGENTS.md when its code is written. |
| [`session-logs.md`](./session-logs.md) | What each session actually did, newest first. |

## Limits worth knowing

Finding the sheet needs the paper to be brighter than what it lies on, so a document on a white
desk breaks it, and a sheet that runs off the edge of the photo is straightened on the points
where it leaves the frame, so that page is a piece of the sheet and the pages screen says so.
`find_paper` reports both cases instead of guessing, which is why `deskew` takes the corners
as an argument: a user can place them by hand
([`core_engine/AGENTS.md`](./core_engine/AGENTS.md)).

An iPhone stores photos as HEIC, and decoding that means shipping a video decoder with
patent licensing this project has no reason to take on. So HEIC stays out of the engine: the
runner hands the file to macOS, the phone asks the camera for JPEG at capture
([`backend-core-runner/AGENTS.md`](./backend-core-runner/AGENTS.md)).

The storage design gives up on power loss and kernel panic, and the PDF step is not
resumable page by page. Every process-level kill is covered
([plan section 8](./iphone-client-plan.md#8-what-a-kill-costs-per-phase)). The floor: **no
interruption at any moment costs more than one page, and none of them can cost the scan.**
