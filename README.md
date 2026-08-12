# FreePDF - scan paper to PDF, entirely offline

Photograph the pages of a paper document, get one clean PDF. Everything happens on the
device: no network calls anywhere, no account, no server.

Two parts:

- **`core_engine`** (Rust) - all image and PDF work. One function per step.
- **clients** - the user interface. The client decides the order of the steps and shows
  each one. Clients will call the engine through a plain C interface, which is milestone 2
  below. The first graphical client is the iPhone app; `backend-core-runner` is the
  command-line one, and it is how the engine gets exercised without a phone.

The engine offers single tools; the client owns the order. Nothing runs by itself, so the
user can step in at any point: find the sheet, straighten it, brighten it, sharpen it -
each is its own call, each can be skipped, redone, or corrected by hand.

Every command in this file runs from the repository root, `/Users/julianhahn/free-pdf`.

## Start here

```sh
cargo test --workspace
```

42 green on a Mac, 39 elsewhere - three tests need `sips` for HEIC. Then read
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
| `sharpen(img, r, t)` | Makes edges crisper. |
| `rotate(img, degrees)` | Quarter turns. |
| `crop(img, x, y, w, h)` | Cuts to the box the user drew. Refuses a box that does not fit. |
| `to_grayscale(img)` | Drops the colour. |
| `images_to_pdf(imgs, out)` | One page per image, A4, orientation follows the image, JPEG-compressed inside. |
| `save_page(img, path)` | Writes one finished page as the JPEG the PDF will embed later. The file wears its real name only once it is whole. |
| `pages_to_pdf(pages, out)` | The same PDF, built from page files instead of images: each JPEG goes in untouched and is never decoded, so a forty page scan fits in a phone's memory. |

To watch it work on a real photo:

```sh
cargo run -p backend-core-runner -- <your-photo>.jpg -o out.pdf --scan
```

`--scan` is shorthand for the four tools a photo of a document usually wants: deskew,
straighten, levels, sharpen at radius 0.6. Every tool can also be asked for on its own.

## Next steps

Riskiest thing first. Each milestone ends in something that runs, and every check is one
command. Full text: [plan section 7](./iphone-client-plan.md#7-build-order); the
file-by-file list is [plan section 6](./iphone-client-plan.md#6-files).

**Now: milestone 2.** Create `ffi/`, the crate that builds the one library file the app
links into itself. Two C functions and nothing else: `freepdf_scan_page` is the runner's
`--scan` order lifted into the wrapper, capped at 3000 px on the long edge and skipping
deskew when no sheet was found or the sheet runs off the frame; `freepdf_pages_to_pdf` hands
a list of paths straight to the engine. Signatures, the header, and how a Rust `String` error
crosses to C: [plan section 5](./iphone-client-plan.md#5-the-c-surface). Give the new
directory its own AGENTS.md and move its rules out of the plan as you go.

| # | State | What gets built | Check |
| --- | --- | --- | --- |
| 1 | **done** | `save_page`, `pages_to_pdf`, `place(...)` in the engine. | `cargo test --workspace` -> 42 green, and `--scan` on any photo still produces a PDF |
| 2 | **now** | `ffi/`: one `staticlib` the app links into itself, the hand-written `ffi/include/freepdf.h`, and two C functions, `freepdf_scan_page` and `freepdf_pages_to_pdf`. ([detail](./iphone-client-plan.md#5-the-c-surface)) | `bash ffi/bridge_check.sh` -> "bridge ok". Host architecture, no simulator, no Xcode |
| 3 | to do | `ios/FreePDF/Scan.swift` plus `ios/check/`: the folder layout, the derived step, the sweep. Foundation only. | `bash ios/check/run.sh` -> ten `precondition`s, one per moment the process could die (~2 s, no Xcode) |
| 4 | to do | The Xcode project and the app: list, flow, the scan loop, the two FFI calls. One temporary "Fake shoot" button in place of the camera. | Build for the "iPhone 17 Pro" simulator, fake-shoot 12 pages, kill the app mid-scan: it must come back at page 7 by itself, leave the finished pages byte-identical, and finish. Needs `rustup target add aarch64-apple-ios-sim` first |
| 5 | to do | The real camera: JPEG at the moment of capture, locked to portrait. Deletes the "Fake shoot" button. | By hand: shoot 5 pages, force-quit while aiming at 6, relaunch - the row reads "5 pages - keep shooting" and the counter says "Page 6" |
| 6 | to do | Export to iCloud Drive, and the quiet "delete the photos" action. | With iCloud signed in, find the PDF under `~/Library/Mobile Documents` on the Mac - it only appears there if it really went up |

### Parked

Things noticed but not scheduled.

- **The memory numbers are the plan's, not measured.** "Around 140 MB for forty pages" comes
  from reading printpdf's sources, and nothing has weighed the real thing. Milestone 4 runs
  twelve pages on a simulator, which is the first honest chance to check it.

## Where to find what

Rules sit next to the thing they govern, so working on a file means reading the AGENTS.md
beside it - not this page.

| Where | What is written there |
| --- | --- |
| [`AGENTS.md`](./AGENTS.md) | How to work in this repository, and the three things that must stay true whatever gets built. |
| [`core_engine/AGENTS.md`](./core_engine/AGENTS.md) | The shape of an engine function: suggest-then-apply, refuse instead of guess, what the public API costs, and the engine's own limits. |
| [`core_engine/tests/AGENTS.md`](./core_engine/tests/AGENTS.md) | How to add a test: the fixtures that already exist, temp file names, and which assertions must never be relaxed. |
| [`backend-core-runner/AGENTS.md`](./backend-core-runner/AGENTS.md) | The tool order, which is a contract; flags, messages and exit codes; HEIC. |
| [`iphone-client-plan.md`](./iphone-client-plan.md) | The authority on the phone side, in twelve numbered sections: storage, screens, the C surface, the Swift wrapper, memory, every line of UI text in English and German. |
| [`session-logs.md`](./session-logs.md) | What each session actually did, newest first. |

`ffi/` and `ios/` do not exist yet, so their rules live in the plan until those directories
are real.

## Limits worth knowing

Finding the sheet goes by brightness, so a document on a white desk breaks it, and a sheet
that runs off the edge of the photo cannot be straightened by its corners.
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
