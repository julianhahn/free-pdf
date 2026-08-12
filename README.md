# FreePDF - scan paper to PDF, entirely offline

Photograph the pages of a paper document, get one clean PDF. Everything happens on the
device: no network calls anywhere, no account, no server.

Two parts:

- **`core_engine`** (Rust) - all image and PDF work. One function per step.
- **`ffi`** (Rust) - the one library file a phone app links into itself, and the two C
  functions it calls.
- **clients** - the user interface. The client decides the order of the steps and shows
  each one. The first graphical client is the iPhone app; `backend-core-runner` is the
  command-line one, and it is how the engine gets exercised without a phone.

The engine offers single tools; the client owns the order. Nothing runs by itself, so the
user can step in at any point: find the sheet, straighten it, brighten it, sharpen it -
each is its own call, each can be skipped, redone, or corrected by hand.

Every command in this file runs from the repository root, `/Users/julianhahn/free-pdf`.

## Start here

```sh
cargo test --workspace
```

44 green on a Mac, 41 elsewhere - three tests need `sips` for HEIC. Then read
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

**Now: nothing is scheduled.** All six milestones are built, and the manual check in
[plan section 7](./iphone-client-plan.md#7-build-order) was walked on an iPhone 13 on
2026-08-12: shoot, share into Files, delete the photos, and the force-quit in the middle of
shooting. What is left is the parked items below, of which the 10 degree engine bug is the
one a real sheet of paper will hit.

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
| 2 | **done** | `ffi/`: one `staticlib` the app links into itself, the hand-written `ffi/include/freepdf.h`, and two C functions, `freepdf_scan_page` and `freepdf_pages_to_pdf`. ([rules](./ffi/AGENTS.md)) | `bash ffi/bridge_check.sh` -> "bridge ok" (~1 s, host architecture) |
| 3 | **done** | `ios/FreePDF/Scan.swift` plus `ios/check/`: the folder layout, the derived step, the sweep. Foundation only. ([rules](./ios/AGENTS.md)) | `bash ios/check/run.sh` -> "resume ok" (~2 s, no Xcode) |
| 4 | **done** | The Xcode project and the app: list, flow, the scan loop, the two FFI calls, and the camera stand-in with its `-autofake` launch argument. ([rules](./ios/AGENTS.md)) | `bash ios/check/scan_check.sh` -> "scan ok" (~3 min, "iPhone 17 Pro" simulator) |
| 5 | **done** | `ios/FreePDF/CameraView.swift`: the session, the preview, the shutter and `PageWriter`. The stand-in lost its button and kept its drawing. ([rules](./ios/AGENTS.md)) | `bash ios/check/scan_check.sh` still says "scan ok"; the camera itself is by hand: shoot 5 pages, force-quit while aiming at 6, relaunch - the row reads "5 pages - keep shooting" and the counter says "Page 6" |
| 6 | **done** | A `ShareLink` on the done screen, and `Scan.deletePhotos()` behind "Delete the 12 photos (78 MB)". The automatic iCloud upload was [dropped on purpose](./iphone-client-plan.md#3-screens). | By hand: share the PDF into Files and open it there; then delete the photos and see the scan still readable and still able to change its pages |

### Parked

Things noticed but not scheduled.

- **Writing crooked by 10 degrees or more makes a page unscannable.** `suggest_straightening`
  proposes an angle `straighten` then refuses, so `freepdf_scan_page` fails - and it fails the
  same way every time, so resume would retry that photo for ever. The coarse pass keeps a peak
  at `MOST_TILT` (10.0) and the fine search then runs to 11.0, so the proposal leaves the range
  the act half accepts. Measured through the real C boundary: 3, 8, 9.5 degrees pass; 10, 10.5,
  11, 11.5 and 12 all come back "was given -10.000004" and worse. The engine's own rule is that
  a suggestion is something the act half accepts, so the fix belongs in
  `core_engine/src/deskew.rs:255` - one line, `-tilt.clamp(-MOST_TILT, MOST_TILT)` - plus a test
  at 10.5 degrees. It is engine work, not client work, so it is written down here rather than
  patched over in `ffi/`.
- **The camera screen has no corner thumbnail.** [Plan section
  12](./iphone-client-plan.md#12-every-line-of-text-the-app-shows) gives the last shot a
  thumbnail in the corner whose action reads "Retake page 7" / "Seite 7 neu fotografieren",
  and it is the one line of that table with no code behind it. Retaking works from the
  check screen already, so this only shortens four taps to two - worth about fifteen lines:
  the decoder in `ScanFlow` at a smaller edge, plus one more piece of view state for the
  page the next shot goes back to.
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
