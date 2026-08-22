# backend-core-runner

The engine's exerciser without a phone, and the reference for the scan order. It reads
arguments, loads photos, calls engine functions and prints what happened. No image logic lives
here: if it did, the iPhone client would inherit nothing and the two would drift apart. It is
not a product, so it gets no feature for its own sake.

## The tool order is a contract

`apply_tools` always runs this order, whatever order the flags were typed in:

    rotate -> crop -> auto-crop -> deskew -> straighten -> levels -> long-edge -> sharpen -> gray

`--scan` means deskew + straighten + levels + `sharpen(&img, 0.6, 0)`. `SCAN_SHARPEN = 0.6`
was measured against a hand edit of the same photo; more starts to draw halos around the
letters. `--scan` only fills in what was not asked for, so `--scan --sharpen 1.2` keeps 1.2 in
either order.

Do not tidy that order away. Milestone 2's `freepdf_scan_page` repeats the deskew, straighten,
levels, sharpen part of it in the `ffi/` crate, deskew skipped only when no sheet is found
([plan section 5](../iphone-client-plan.md#5-the-c-surface)). And `USAGE` promises the order in
words, so it and `apply_tools` change in one commit or the printed contract lies.

`--long-edge` sits where it does because a page shrunk after sharpening throws the sharpening
away - the phone shrinks in the same place, before `sharpen`, and the two orders are worth
keeping the same. There is still no resolution cap here on purpose: the 3000 px cap belongs to
the phone, which has a low-memory limit a desktop does not, so `--long-edge` is a page size the
user asked for and never a ceiling of its own.

## HEIC

`load_photo` looks at the extension (`.heic`, `.heif`). On macOS it hands the file to `sips`
with the sRGB profile, because an iPhone shoots Display P3, then loads the JPEG and deletes
the temp file. `sips` exits 0 even on a file it skipped, so the size of the written file is
checked as well. The camera rotation tag is left alone: `load_image` in the engine is the one
place for it. On any other target it returns the sentence asking the user to convert to JPEG
first.

This must never move into the engine: HEIC is video compression in a still container, so
decoding it means shipping a video decoder and taking on its patent licensing, while every
target platform already has a licensed one. Keep `mod heic_tests` behind
`#[cfg(all(test, target_os = "macos"))]` and keep it building its own HEIC with `sips`, so no
real photo lands in the repository.

## Flags, messages, exit codes

`USAGE` in `main.rs` is the flag list. `--grayscale` works too and is deliberately not in it.
`--quality <1..100>` and `--long-edge <px>` are the two numbers behind a page size setting, and
they are raw numbers here on purpose: the rung names a user reads ("Small", "Smallest") are the
client's product decision and live in one place only, which is not this file. `--quality` is
range-checked while the arguments are read, so a typo is answered before the first photo is
opened; `--long-edge` is answered by the engine's own floor as soon as the first page reaches
it. `--quality` next to an image output is refused rather than ignored, because only a PDF has
pages.

Parsing is a hand-rolled `while let` match in `parse_args`; keep it that way, no clap.
`value_for` refuses a value starting with `-`, so a missing value is reported instead of
swallowing the next argument. Do not loosen it for paths with a leading dash.

`run` returns `Result<PathBuf, String>`; success prints `Wrote {path}` and
`ExitCode::SUCCESS`, failure prints `Error: {message}` to stderr and `ExitCode::FAILURE`. No
codes, no enum, no `--json`. Errors about the shape of the arguments append `\n\n{USAGE}`; a
wrong number does not, because that user does not need the help text again. A tool that cannot
do its job prints one indented line, for example `  paper: no sheet found, left as it is`, and
leaves the image untouched. Only an error from the engine aborts the run.

## Dependencies

`core_engine` by path is the only runtime dependency, and there is deliberately no `image`
crate here: the runner uses the types the engine re-exports, so the two can never disagree on
a version. `image` 0.25 with the `jpeg` feature is a dev-dependency, used only to build the
HEIC test photo. If one more is truly unavoidable, set `default-features = false`, take only
the features in use, and write in [Cargo.toml](./Cargo.toml) why it is there.

## Two roads into a PDF

Without `--quality`, `write_output` hands the images to `images_to_pdf`, exactly as it always
did - that function and the two tests that count its bytes are frozen, see
[../core_engine/AGENTS.md](../core_engine/AGENTS.md), and nothing about that road may move.
With `--quality` the same pages take the road the phone takes instead, because
`images_to_pdf` has no quality to set: `save_page` per page into a folder named after this
process, then `pages_to_pdf` over those paths. The folder is removed again whether the PDF came
out or not, and a folder that cannot be made is a sentence naming it.

## What the phone will not copy

Not `write_output` itself: the app writes no image file and never takes the `images_to_pdf`
road, whatever the user picked. It calls `save_page` per page and `pages_to_pdf` over a list of
paths, because forty pages through `images_to_pdf` peak around 3.1 GB
([plan section 4](../iphone-client-plan.md#4-engine-changes)). Not the printed lines
either; their text is
[plan section 12](../iphone-client-plan.md#12-every-line-of-text-the-app-shows). Only the tool
order travels.
