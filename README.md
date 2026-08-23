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

69 green on a Mac, 66 elsewhere - three tests need `sips` for HEIC. Counted on the
merged tree on 2026-08-23: 53 in `core_engine/tests/engine.rs`, 8 in `ffi/src/lib.rs`
and 5 in `backend-core-runner` here, plus that crate's 3 HEIC tests on a Mac. Then read
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
resolution (row 11 below) and paper size (DECISIONS 6).

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
| 7 | **done** on 2026-08-18 - a page still came out with a strip of desk along its edges, because the four sides were only ever fitted on the 400 pixel copy, where one pixel is about eight of a phone photo, and the miss was different on each side, so no single bias could take it out. `find_paper` now reads each fitted side again in the full sized photo, at nine places along it, and moves the whole side onto the middle of those readings. Measured with `core_engine/examples/edge_error.rs` on the twelve real photos: the middle of every side lands 0 to 3 pixels inside the paper, where before three sides cut up to 17 pixels into the sheet and the fourth left desk in the page. The middle of it, not all of it - a sheet on a desk bows, so a straight side laid on the middle still left a strip of desk where the bow ran the other way, which row 8 then fixed. Costs about half a millisecond of the nineteen a search takes. | engine agent |
| 8 | **done** on 2026-08-18 ([`TASKS.md`](./TASKS.md) 36) - the page still carried a strip of Julian's table along its bottom, because each side was laid on the MIDDLE of its nine readings, which by definition leaves half of them outside the paper. Every side is now laid on its INNERMOST reading instead, and never more than `MOST_INWARD = 10` photo pixels - one millimetre of A4 - past the middle, so one misread place cannot eat the page. The margin is whatever that one side bows by: a flat sheet pays nothing, which is why the synthetic corner tests pass untouched. Measured with `core_engine/examples/edge_error.rs`: sides whose worst place is no more than the 3 pixels task 36 allows went from 9 of 48 to 32 of 48, and 26 of the 48 have no place outside the paper at all where before none did; no middle reads past +12; a page comes out 8 to 26 pixels narrower and 1 to 18 shorter, and no single side can lose more than `MOST_INWARD` plus the hair, 11.5 pixels, which is 1.0 mm on these photos. **Task 36's acceptance is not met, and it is arithmetic rather than tuning**: 13 of the 48 sides bow further than that millimetre, so they still keep a thin wedge of table near one end - the readings that are the ruler misreading instead are named with their evidence in [`TASKS.md`](./TASKS.md) 36, where the third round settles which. What is left is the ceiling of a straight side, not a number to turn up - see **Parked**. | engine agent |
| 9 | **done** on 2026-08-18 ([`TASKS.md`](./TASKS.md) 36, second round) - the change is in, **task 36 itself is still open**. The wedge of table row 8 left near the corners of the long sides is smaller. Each side had kept the slope the 400 pixel copy gave it, so one number had to satisfy nine readings and a side could not sit on the edge at both of its ends at once. A side may now LEAN as well: `how_the_side_leans` picks how much further one end of it moves than the other, up to `MOST_LEAN = 12` photo pixels, taking the lean that leaves the least bow for the cap to pay for. It is nearly free, because a lean re-aims a side instead of pushing it in - a page came out 13 pixels wider to 11 narrower and 17 taller to 5 shorter. What a lean does spend lands at a corner, where no reading looks: 11 pixels at worst on the twelve, just under a millimetre, measured on the corners `backend-core-runner --deskew` prints. Row 10 says what a page gets, and the counts in this row and row 8 are not comparable to it - both were measured with the ruler reading the photo lying on its side. | engine agent |
| 10 | **done** on 2026-08-18 ([`TASKS.md`](./TASKS.md) 36, third round) - and **task 36 is still open**. The ruler every number in rows 7 to 9 was measured with loaded the photo without the turn the phone recorded, so it measured a 4032 pixel wide landscape raster the app never processes while the app fits the 3024 pixel wide upright one - and its four side names came out turned a quarter, which is why two rounds went at the bottom edge. It now loads the photo the way the app does: one line, no engine code changed, and every side name and count in these documents corrected against it. **The edge Julian reported is clean.** On his own build, read the app's way, every one of the twenty-four tops and bottoms of the twelve photos sat outside the paper, -1 to -13; now twenty-three of the twenty-four have no place outside the paper at all and the twenty-fourth reads -1. The strip of table along the bottom of his page is gone. **What is left sits on the LEFT and RIGHT edges, which he never mentioned:** nine sides keep a wedge of desk, -5 to -57 pixels, and a straight side cannot follow a bow like that - see **Parked**. One reading goes the other way and is new: `extra_3`'s right side stands up to 59 pixels INSIDE the paper near one corner, about 5 mm of that page, which the ruler's two columns cannot show. Julian looking at a page decides the rest. | engine agent |
| 11 | **done** on 2026-08-22 ([`TASKS.md`](./TASKS.md) 37 to 39; 40 and 41 are the two things the same session measured and refused, and they are answers rather than open work) - how small a page is written is a choice, and the app makes it. `save_page` rebuilds each page's Huffman tables from its own symbol counts, so the same pixels cost fewer bytes; then it took a `PageQuality` and `freepdf_scan_page` / `freepdf_adjust_page` took a `FreepdfPageQuality *` beside it, NULL still meaning Original; then the app made quality 45 its default in `quality.txt` and put one switch, **Smaller pages**, on the check after the first photo and on the pages screen. Two rungs reach the user and no more. The engine's 1700 px rung is deliberately not offered - about 150 dpi on A4, and reading the text back out later wants about 300 - which is the one of the sixteen capabilities, resolution, that stays without a control on purpose. All of it was built on Linux and checked on a Mac on 2026-08-23: `cargo test --workspace`, `bridge_check.sh`, `run.sh` and `scan_check.sh` all pass, so **the Swift compiles and the app runs**, and the byte figures were remeasured on real paper (row 14). **One thing is open**: five of the seven new lines of text wait for Julian's approval (row 12). | engine + ffi + client |
| 5 | **done** on 2026-08-18 ([`TASKS.md`](./TASKS.md) 31) - the automatic run no longer refuses a sheet that leaves the frame. It cuts on the points where the paper crosses the edge, exactly as Adjust already did, and the pages screen puts a calm note under such a page saying it is not the whole sheet, with the retake that already exists. Checked against the twelve real photos: eleven byte for byte as before, `runs_off_1.jpg` cut. | engine + client |
| 12 | **open, five of seven** - the page size setting adds seven lines of new words. **Five wait**: the switch **Smaller pages** / **Kleinere Seiten**, its line on the check screen "About half the file size. Switch it off if this page looks too soft.", the two spoken hints, and the done screen's "This PDF is 2,3 MB." **Two do not**: Julian asked on 2026-08-23 for the pages screen's switch to say what it does, so "Every page you already have is written again." and its frozen form "The photos are gone, so the pages cannot be written again." are his idea and only their German is still an agent's. All seven are in the code so no screen is mute, written in the voice of the tables around them, and marked in [`user-flows.md`](./user-flows.md) sections 4c, 7 and 9. Nothing already approved was reworded and nothing was added to the design system's own tables: a client agent may not invent copy ([`client-guide-design-system/AGENTS.md`](./client-guide-design-system/AGENTS.md)). | Julian, by reading |
| 13 | **open, smaller than it was** - the page size work now builds and runs: on 2026-08-23 `scan_check.sh` compiled the app and drove it in the "iPhone 17 Pro" simulator, so the Swift is no longer right by inspection only. Two questions are left and only a phone in a hand answers them: whether two switches stacked in the pages footer and one above the two buttons on the check screen read as one setting or as clutter, and how long the re-run feels when the switch is flipped on the check screen, where the old picture stays up until the new one lands. The third question this row used to ask - whether "About half the file size" is honest - is answered: **yes**, 45% off the page the app writes, median over thirteen real photographed sheets, and the fine print survives it. | Julian, on a phone |
| 14 | **done** on 2026-08-23 - the measurement only a Mac can make. Every byte figure in the repository came from synthetic photographs of synthetic glyphs; the runner was run by hand over the thirteen real sheets in the gitignored `test_images/phone/` at all three rungs and the pages were looked at in Preview. Two figures had drifted: the 1700 px rung is **about 81%** off the app's page, not 71%, and the Huffman recode is **8 to 13%** on a text page, not 5 to 9%. Quality 45 held at **about 45%**. Corrected in README, TASKS 37 and 38, `core_engine/AGENTS.md`, `pdf.rs`, `rehuff.rs`, `tests/engine.rs` and `Engine.swift`, each with its baseline named. `LEAST_PAGE_SAVING` did not move - all thirteen real pages sit under it, which is the reason its test keeps the synthetic gradient fixture. | engine, on a Mac |

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

- **The sides that bow more than the millimetre a page may lose** are the nine in row 10, and
  [`TASKS.md`](./TASKS.md) 36 names them one by one. The desk that is left sits in a wedge near one
  end of such a side, not in a band along it, and a straight side cannot follow that bow at any
  slope.
  Neither cap helps in the small either: at `MOST_INWARD = 20` `extra_4`'s left side got worse, -27
  to -60, and at `MOST_LEAN = 32` the same, -25 to -60, because moving or turning a side slides the
  nine places it is read at along the edge. The way up is four sides that may bend, or a corner of
  its own for each end, and neither is worth building until Julian looks at a page and says the
  wedge shows.
- **One side stands INSIDE the paper, and nobody has measured what that costs.** `extra_3`'s right
  side runs up to 59 pixels inside the sheet near one corner, about 5 mm of that page cut off, and
  the ruler cannot show it: its two columns are the middle and the worst reading, and a side
  standing inside the paper reads high in both. What is missing is the other end of the ruler - the
  highest reading per side, not only the lowest.
- **The camera screen has no corner thumbnail.** [Plan section
  12](./iphone-client-plan.md#12-every-line-of-text-the-app-shows) gives the last shot a
  thumbnail in the corner whose action reads "Retake page 7" / "Seite 7 neu fotografieren",
  and it is the one line of that table with no code behind it. Retaking works from the
  check screen already, so this only shortens four taps to two - worth about fifteen lines:
  the decoder in `ScanFlow` at a smaller edge, plus one more piece of view state for the
  page the next shot goes back to.
- **The corner thumbnail is not tappable.** The thumbnail itself was built on 2026-08-18
  ([`TASKS.md`](./TASKS.md) 35), but [plan section
  12](./iphone-client-plan.md#12-every-line-of-text-the-app-shows) gives it an action reading
  "Retake page 7" / "Seite 7 neu fotografieren", and that is the one line of that table with
  no code behind it. Retaking works from the check screen already, so this only shortens four
  taps to two - worth about fifteen lines: one more piece of view state for the page the next
  shot goes back to.
- **Tesseract cannot go into the Rust bundle.** Asked and answered on 2026-08-22, written up
  as [`TASKS.md`](./TASKS.md) 41. It builds and it works well - 917 ms and 48 MB a page,
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
  2.7 MB. Written up in full as [`TASKS.md`](./TASKS.md) 40. A pure-Rust G4 encoder was
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
- **~~`ios/check/run.sh` does not watch the `quality.txt` rules.~~ Closed on 2026-08-23** -
  section 18, and three mutations of `Scan.swift` prove it aborts
  ([`ios/AGENTS.md`](./ios/AGENTS.md)).
- **"This PDF is 2,3 MB." - an English sentence with a German decimal comma.** Not a defect,
  and do not "fix" it by forcing the number to English. `ByteCountFormatter` follows the
  phone on purpose, which is right; what is missing is the other half, the German sentence.
  The app has no `.lproj` at all yet - every string is an English literal in the code, and
  the German lives only in [`user-flows.md`](./user-flows.md). The day those strings land the
  comma is correct and the sentence catches up. Seen on a German-region simulator on
  2026-08-23.
- **The Grey switch stays live once the photos are deleted, the size switch is frozen.**
  Neither can rewrite a page without its photo, so one of the two is wrong and it is
  probably Grey. Left alone on purpose: which switch a user may still touch is a product
  answer, not a bug fix - it is one line either way once Julian says which.
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

## License

[PolyForm Noncommercial 1.0.0](./LICENSE.md). Read it, run it, change it, pass it on - all of
that is yours for any noncommercial purpose. Selling it, or building a commercial product on
it, is not covered and needs a separate word with Julian Hahn, who holds the copyright. That
choice is deliberate: the point is people taking the thing apart and making it better, not
somebody shipping it for money.

A contribution comes in under these same terms.
