# core_engine

All image and PDF work lives here. This crate takes images and paths and gives back images and
sentences: no UI, no decision about the order of the steps.

## How a new function looks like the old ones

- Every module opens with a `//!` header saying why it exists at all. Every public function
  gets a `///` block; a fallible one adds the `- Parameters:` / `- Returns:` pair, and the
  `- Returns:` line describes the error in words (`rotate` in `src/tools.rs`).
- Comments say WHY. When a number was chosen by measuring, the measurement goes in the
  comment: `CLEAR_LINES` in `src/deskew.rs` carries "a photographed invoice scores 91 ... a
  blank sheet lit unevenly 0.007".
- Every tuning number is a named `const` with a doc comment. A bare number in an expression
  cannot be found again when someone has to retune it against real photos.
- The error String names the path or the offending value: `"A 50x10 crop at (180, 0) does not
  fit inside the 200x300 image."` Wrapping a cause keeps one shape and no full stop, because
  the cause ends the sentence: `Failed to write the PDF to {}: {}`.
- No `unwrap()`, `expect()`, `panic!`, `unsafe`, no threads, no global state. `src/` has none
  today, and a panic across the planned C boundary is undefined behaviour.

## Suggest, then apply

Anything automatic is two functions: the measure half returns plain data and cannot fail, the
act half takes that same data as a parameter. `suggest_levels` / `apply_levels`,
`find_paper` -> `Paper::corners` -> `deskew(img, corners)`. A new tool follows that shape. One
function that finds its own parameters and applies them leaves the user no point to look at
the proposal and move it.

## Every step has its own space

The photo file is never written to: every tool takes an image and gives a new one back. The
four corners `find_paper` finds in the photo are what says where the page is, and the app can
move them. But there is no one boundary to move: straightening turns the picture inside a
second rectangle nobody drags, the 3000 px cap resamples a third time, and a crop cuts into a
picture that only exists after all of them. So each step's numbers are numbers of the image
that step is handed, and a number measured on one image means nothing on the next.

That is why the app composes a second crop onto the first instead of moving the handles to a
different canvas: the crop's own image is neither the photo nor the page, so there is no
picture on screen a stored crop box could be drawn on ([`../ios/AGENTS.md`](../ios/AGENTS.md)).

## Refuse instead of guess

- A measure function that is unsure returns the do-nothing answer, never a guess: `find_paper`
  returns `None`, `suggest_straightening` returns `0.0`. Doing nothing is visible and
  reversible, a damaged picture is not.
- An act function refuses input that does not fit instead of clamping it: `crop` refuses a box
  outside the image, `rotate` a free angle, `straighten` more than `MOST_TILT`. A silently
  shrunk result looks like the tool ignored the user.
- `Paper::runs_off_the_picture()` reports, it does not refuse. Those corners are only where the
  paper leaves the frame, so the page is a piece of the sheet - deskew anyway and let the client
  say the page is incomplete (Julian, 2026-08-17).

## What the public API costs

`src/lib.rs` is the whole contract: the `pub use` block is the list clients and the C wrapper
in [`../ffi`](../ffi/AGENTS.md) call by name. Take and return the re-exported `DynamicImage`,
so clients need no dependency on the `image` crate and can never link a different version than
the engine. `load_image` and `pdf.rs` are the only places that touch the file system; every
tool is image in, image out, which is what lets the client rerun one step. Do not add a
dependency.

## pdf.rs: two ways into a PDF

`images_to_pdf` takes the images themselves, which is what the command line runner holds.
`save_page` writes one finished page as a JPEG and `pages_to_pdf` takes a list of those
paths, which is the only shape under which a phone can name forty pages without holding
them. Both write `<name>.part`, flush, `sync_all` and then rename, because a half-written
file must never wear a real name. Both paths end in `place(id, px_w, px_h)`, so the fit and
centre maths exists once.

`images_to_pdf`, `to_raw_image`, `save_options` and `JPEG_QUALITY` stay untouched; two tests
assert the size of what they write. `JPEG_QUALITY = 0.85` and the forced
`ImageCompression::Jpeg` belong together: left alone, printpdf picks lossless LZW for grey,
and a greyed scan grew from 107 KB to 347 KB. `PAGE_JPEG_QUALITY = 85` is the same quality in
the scale the page encoder counts in, and the two agree **at that one setting only**:
`save_page` now takes a `PageQuality`, and a client asking for a smaller page passes a lower
number on purpose. So do not re-align the two, and do not read a lower page quality as a bug.

`PageQuality { jpeg_quality, longest_edge }` is a struct and not a bare number, because a bare
`45` at a call site cannot be found again; and not an enum of rung names, because the names the
user reads and the numbers behind them are the client's decision. `PageQuality::UNCHANGED` is
quality 85 with every pixel kept, and a page written with it is byte for byte the page this
engine has always written - `the_default_quality_writes_the_very_same_page_as_before` pins that
with a length and a fingerprint taken off commit 966a52f.

`longest_edge` is **refused** unless it is zero, rather than ignored, because an ignored field is
a lie about what the call did. The resampling belongs where the client's size cap already is,
before sharpening: `sharpen` is the memory peak (234 MB at 3000 px against 116 MB at 1754 px),
shrinking after sharpening throws the sharpening away, and a crop is fractions of the image
*after* the cap, so moving the cap changes what every stored crop box means. `fit_within` is the
tool, Lanczos3 and shrink only - the box filter a client reaches for instead measured moire 26.6
against 5.5 at a 1240 px edge and 62% more ink damage for *more* bytes at 2000 px, and
`FilterType` cannot even be named outside this crate. One thing not to promise: 80% off a
photographed page and "not even visible" are not both reachable - 80% needs a 1200 to 1400 px
edge, which three probes called plainly blurred.

Why the page path exists at all, so nobody simplifies it away later:

- `save_page` writes the page, rather than the client, for two reasons. Its bytes have to be
  exactly the stream the PDF later embeds, or every page is compressed twice; and a PDF
  ignores the camera rotation tag, so a page written by the phone's own image code lands
  sideways.
- `pages_to_pdf` takes a list of *paths* and hands each JPEG to the PDF untouched, never
  decoding a page. Forty pages through `images_to_pdf` peak around 3.1 GB, and iOS kills an
  app around 1.4 GB on a 3 GB phone; the path form keeps the peak near 140 MB, growing about
  2 MB a page instead of about 70.
- `page_files_go_into_the_pdf_without_being_decoded` is the only thing watching that. A
  silently re-encoded page still opens and still looks right, so no other assertion can see
  it - and it only works because the page it checks is noise
  ([tests/AGENTS.md](./tests/AGENTS.md)).

## rehuff.rs: the same pixels in fewer bytes

`image`'s JPEG encoder writes the fixed example Huffman tables out of the standard's Annex K,
which are nobody's page. `rehuff` rebuilds them from the page's own symbol counts and carries
every quantised coefficient over untouched, so the file decodes to the very same pixels and
simply weighs less. It is private, has no dependency, no `unsafe` and no panic path, and
`save_page` calls it through `unwrap_or`: a JPEG it refuses keeps its original bytes, so a scan
can never be left unfinishable by it. It is not a setting and there is nothing to switch,
because it costs the user nothing.

**What it is worth, and do not quote the best case.** 8 to 13% on real photographed text
pages - thirteen of them, median 10% - 15 to 16% on grainy and photographic ones, 2.5 to 5% on
grey text. A document scanner's typical page is text, so 8 to 13% is the number to plan with.
The earlier "5 to 9%" was four probes on synthetic glyphs and read a little low; the thirteen
that replaced it on 2026-08-23 are photographs of real paper. The first write-up said 20 to 30%, which was
one 40-page synthetic run quoted as the rule. The "up to 28% over a mixed scan" that
`rehuff.rs`, `pdf.rs` and `tests/engine.rs` still carry is that same run, and it is kept beside
the per-page spread on purpose: it is what a whole synthetic scan of mixed page kinds came to,
not what any one real page will do. Quote the page kind, never the scan.

**Four other compression levers were measured and are dead ends.** They are written down here
so nobody spends the day again: chroma subsampling is impossible with `image` 0.25 at all - it
hardcodes h:1, v:1 - and would need a different encoder. `to_grayscale` as a compression lever
is 7.1%, which is not worth spending the colour on. 4-bit grey measured **larger** than grey at
quality 65. Flate over the PDF's non-image streams saves 0 bytes, because the pages are already
the whole file, and PDF-1.5 object streams save 0.07%. The one lever that is not a dead end is
bilevel CCITT-G4 at 93.5% off, and it is parked rather than built because the threshold it
needs deletes faint pencil silently ([`../TASKS.md`](../TASKS.md) 40).

**Every one of those numbers came from synthetic photographs of synthetic glyphs.**
`test_images/` is gitignored and reading it from code is forbidden
([`../AGENTS.md`](../AGENTS.md)), so the shares are sound - the same pipeline against itself -
but the absolute bytes are unproven on real paper.

## Sweeping a constant to find its value

Two of these caps - `MOST_INWARD` and `PLACES_READ_AGAIN` in `paper/` - are found by sweeping
them over the photos in `test_images/phone/` rather than reasoned out. Two rules, both learnt
by getting them wrong on 2026-08-24.

**Verify the write, or the sweep measures nothing.** A loop that rewrites a constant with
`sed` and then builds must check the file afterwards:

```sh
sed -i '' "s/^pub(super) const MOST_INWARD: f32 = .*/pub(super) const MOST_INWARD: f32 = ${n}.0;/" $M
grep -q "f32 = ${n}.0;" $M || { echo "SED FEHLGESCHLAGEN"; return; }
```

Without that line a shell quirk wrote an empty value, the file held `= .0;`, five runs in a
row failed to compile - and the loop still printed a tidy table of numbers, because the
measuring commands fell back on a stale binary and the summarising `awk` happily averaged
nothing. Plausible output from code that never built is worse than an error.

**Caps that gate each other must be swept TOGETHER.** `PLACES_READ_AGAIN` decides where a side
is READ and `MOST_INWARD` how far it may be MOVED, and either one alone pins the result:
more readings find a corner the old cap then refuses to reach, and a bigger cap cannot reach a
corner no reading found. Swept one at a time, each looked useless and the second was written
off as "a straight side cannot be aimed better than it already is". Swept together, 29 and 60
took Julian's corner from -42 to -6. A one-at-a-time sweep over two caps proves nothing about
either.

## Limits, not bugs

The six steps that search for the sheet, the order they run in and which raster each of them
counts its pixels in are [`src/paper/AGENTS.md`](./src/paper/AGENTS.md).

Finding the sheet starts from brightness and then follows the edges of the paper, so a document
on a white desk still breaks it: there is no step from paper to desk for a ray to stop on. That
is recorded as a `ponytail:` note on `find_paper` in `src/paper/mod.rs` with the way up; do not
paper over it with a threshold.

Every fitted side is then read again in the full sized photo and laid on the edge it finds there
(`sides_read_again_in_the_photo`), on the INNERMOST of nine readings rather than the middle of
them, and no further in than `MOST_INWARD`: a sheet on a desk bows, so the middle of the readings
left half of every side outside the paper and the page kept a strip of desk. A side may also LEAN,
one end of it moving up to `MOST_LEAN` pixels further than the other (`how_the_side_leans`),
because a slope measured on a 400 pixel wide copy is off by about that much and one number cannot
sit on an edge whose readings run steadily from one end to the other. A lean re-aims a side rather
than pushing it in, so it costs the middle of a page nothing: on average a page now keeps more of
its white margin than it did without it. Along a side a page still loses at most a millimetre -
Julian's decision on 2026-08-18, on real scans.

Three things there are limits, not bugs.

- **One bad reading can pick a lean.** The lean chosen is the one leaving the least bow, measured
  to the INNERMOST reading, so a place that misreads far outside the paper pulls the line onto
  itself. `MOST_LEAN` and the cap in `where_the_side_goes` are the only guards, and
  `how_the_side_leans` carries the measurement of one real case.
- **What a lean spends lands at a CORNER, and no reading covers a corner** - the ruler reads
  between a tenth and nine tenths of a side. So a change to `MOST_LEAN` is checked on the four
  corners `backend-core-runner --deskew` prints, never on the ruler alone. Nothing in `tests/`
  reaches it either: a drawn sheet is straight, so its lean is nought and the fixtures cannot see
  a wrong one.
- **Some sides bow further than that millimetre even after the best lean**, and a straight side
  cannot follow them, so a wedge of desk stays near one end of those. Every side that still does
  it is a LEFT or a RIGHT side - a page's top and bottom read no worse than -1 now. A page whose
  writing runs to the very edge of the paper needs Adjust.

How many sides that is today is the header of `examples/edge_error.rs` - the only thing that
measures any of it, and it loads the photo the way the app does, so its side names are the sides a
page has on screen. Which readings are the tool misreading rather than desk, and the walk along
the side that decides that, is `TASKS.md` 36.
HEIC decoding stays out of this crate, the client's own system does it. And widening
`MOST_TILT` is not how a page held sideways gets fixed; that is `rotate`.
