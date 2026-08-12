# backend-core-runner

The engine's exerciser without a phone, and the reference for the scan order. It reads
arguments, loads photos, calls engine functions and prints what happened. No image logic lives
here: if it did, the iPhone client would inherit nothing and the two would drift apart. It is
not a product, so it gets no feature for its own sake.

## The tool order is a contract

`apply_tools` always runs this order, whatever order the flags were typed in:

    rotate -> crop -> auto-crop -> deskew -> straighten -> levels -> sharpen -> gray

`--scan` means deskew + straighten + levels + `sharpen(&img, 0.6, 0)`. `SCAN_SHARPEN = 0.6`
was measured against a hand edit of the same photo; more starts to draw halos around the
letters. `--scan` only fills in what was not asked for, so `--scan --sharpen 1.2` keeps 1.2 in
either order.

Do not tidy that order away. Milestone 2's `freepdf_scan_page` repeats the deskew, straighten,
levels, sharpen part of it in the `ffi/` crate, deskew skipped when no sheet is found
([plan section 5](../iphone-client-plan.md#5-the-c-surface)). And `USAGE` promises the order in
words, so it and `apply_tools` change in one commit or the printed contract lies.

There is no resolution cap here on purpose. The 3000 px cap belongs to the phone, which has a
low-memory limit a desktop does not.

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

## What the phone will not copy

Not `write_output`, which hands a `.pdf` to `images_to_pdf` - leave both alone, see
[../core_engine/AGENTS.md](../core_engine/AGENTS.md). The app calls `save_page` per page and
`pages_to_pdf` over a list of paths, because forty pages through `images_to_pdf` peak around
3.1 GB ([plan section 4](../iphone-client-plan.md#4-engine-changes)). Not the printed lines
either; their text is
[plan section 12](../iphone-client-plan.md#12-every-line-of-text-the-app-shows). Only the tool
order travels.
