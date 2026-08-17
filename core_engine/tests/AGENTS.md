# Tests

Rules for anything you add to [`engine.rs`](./engine.rs). One command, from the repository
root:

```sh
cargo test --workspace
```

42 tests are in this file. Five more are in `backend-core-runner/src/main.rs`, three of them
only on macOS, and three in `ffi/src/lib.rs`, so the workspace shows 50 green on a Mac and 47
elsewhere. A different number means something else was touched. [`../../README.md`](../../README.md) prints both counts
under "Start here" - move them with the count, in the same commit.

## Tests build their own images

Reuse a generator before writing one: `test_image(width, height)`, `photographed_document()`
(warm, unevenly lit paper with a block of writing), `document_on_a_dark_table()` (cut corners
plus a bright reflection), `photo_of_a_tilted_sheet()` (a trapezoid, and it returns its own
four corners), `crooked_page(tilt_degrees)` (a known tilt), `noise_page(width, height)`
(pseudo-random pixels). Each doc comment says what the fixture is there to trip over. A
fresh, naive fixture usually removes the trap, and then the new test proves nothing.

`noise_page` exists because of one measurement worth keeping: a JPEG of a smooth picture
survives being decoded and encoded again **byte for byte**. Of `test_image`, 0 of 174,229
bytes change on a round trip; of `photographed_document` and `document_on_a_dark_table` none
either; of `crooked_page` 40 of 22,541, and its last 64 bytes still match. So any check of
the form "the page went into the PDF unchanged" passes on a page that was decoded and
re-encoded, unless the page is noise, where 3,018,895 of 3,034,201 bytes change. Do not swap
`noise_page` for a friendlier picture in
`page_files_go_into_the_pdf_without_being_decoded`; the test then proves nothing at all.

Never read a file the test did not just write itself, `test_images/` included. Build the input
in code, the way `a_sideways_photo_is_turned_upright_when_loaded` splices the hand-written
`EXIF_ROTATED_QUARTER_TURN` block into a freshly encoded JPEG.

## Temp files

Write only through `temp_path("<name>")`, and pick a name no other test uses. Nothing cleans
up and the names are fixed, so a reused name means two tests overwrite each other in parallel
and the failure looks random. Twelve names are taken today, one of them a directory
(`temp_path("pages")`). A test that asserts a file is absent
deletes it first, as `refuses_to_write_a_pdf_without_pages` does. No `tempfile` crate: there
is no `[dev-dependencies]` section and none is needed.

## Assertions that must not be relaxed

If a test fails, the code is wrong until proven otherwise. Never widen a bound and never drop
an assertion to get green. These numbers were measured, not guessed:
`levels_turn_the_paper_white_and_the_writing_black` wants the paper exactly
`[255, 255, 255]`, `a_bright_speck_is_not_mistaken_for_a_sheet` wants `None`,
`the_corners_of_the_sheet_are_found` wants `< 6.0`.

Keep the guards that prove a fixture is still hard, and keep them before the real assertion:
`before < 0.5` in `straightening_puts_the_lines_of_writing_back_in_their_rows`,
`warmth_before > 15` in `levels_remove_the_colour_cast_from_the_paper`. Without them the real
assertion passes on a page that was never crooked and paper that was never warm.

Counting bytes (`embedded_scans_are_compressed`, `grayscale_does_not_grow_the_pdf`) belongs
here because a fat PDF is invisible to everything else: it still parses, still opens, still
looks right. Read a written PDF back through `parse_pdf`; the `b"%PDF-"` prefix check is never
the only assertion.

## Shape

Name a test as a plain English sentence in snake_case saying what the user gets: the name is
the failure report. Three-part body: set up, blank line, the one call under test, blank line,
the assertions. An assert on a measured number prints the number. Test the public surface
only, so a new engine function needs its `pub use` in [`../src/lib.rs`](../src/lib.rs) first.

[`../examples/compare.rs`](../examples/compare.rs) is not a test: it has a `main` and unwraps
freely, and it measures how a hand-edited photo differs from the original, so a tool can be
built to do the same thing on purpose instead of by feel. `cargo test --workspace` only
compiles it, and it calls `core_engine::load_image`, so changing that signature turns the test
run red in a file that looks unrelated. Run it by hand:

```sh
cargo run -p core_engine --example compare -- original.jpeg edited.jpeg
```

[`../examples/mask.rs`](../examples/mask.rs) is not a test either, and the same warning
applies: it calls `core_engine::load_image` and `core_engine::find_paper`. It paints what
`find_paper` calls the paper over the photo, which is the only honest way to check the search -
a mask is looked at, not counted. Run it by hand and open the PNG:

```sh
cargo run -p core_engine --example mask -- photo.jpeg overlay.png
```
