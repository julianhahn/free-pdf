# Finding the sheet

Six files, one search, and it runs in this order. Reading them out of order will not make
sense, because every step is handed what the one before it found.

1. [`rough_area.rs`](./rough_area.rs) - brightness alone: shrink, split, flood in from the
   border, keep the largest thing that is not background. It also reads the paper and table
   levels off this picture, which the next two steps compare a step against.
2. [`sides.rs`](./sides.rs) - one ray per row and one per column outward from inside the
   rough area, and a straight line fitted through where they stopped: four sides.
3. [`read_again.rs`](./read_again.rs) - each of those four sides read again in the full
   sized photo, at nine places along it.
4. [`where_a_side_goes.rs`](./where_a_side_goes.rs) - the two numbers one side gets out of
   its nine readings: how far it leans, and where it is laid. No image is touched here.
5. [`quadrilateral.rs`](./quadrilateral.rs) - the four sides crossed into four corners, a
   mask and a box, with the checks that drop a shape reaching onto the table or abandoning
   part of the sheet.
6. [`mod.rs`](./mod.rs) - what a caller gets, and `find_paper`, which drives the other five.

## Two rasters, and a number of one means nothing on the other

`rough_area.rs`, `sides.rs` and `quadrilateral.rs` count pixels of a 400 px wide shrunk copy.
`read_again.rs` and `where_a_side_goes.rs` count pixels of the photograph, where one pixel of
the copy is about eight. That is why `EDGE_SAMPLES` and `PHOTO_EDGE_SAMPLES` are both three
and are two separate consts with two separate doc comments: they are not the same three. Never
carry a measurement from one side of that line to the other
([`../../AGENTS.md`](../../AGENTS.md), "Every step has its own space").

## What may never change

- `mod.rs` owns the four names `src/lib.rs` re-exports: `find_paper`, `Paper`, `Point`,
  `Rect`. `Paper`'s fields are private and `find_paper` fills them in, so the two stay
  together.
- **Nothing about the sides may turn a found sheet into `None`.** A client reads `None` as
  "leave this photo alone". A side that cannot be fitted, a quadrilateral that is not
  believed, a place that reads no edge - each falls back to the rough area and the page still
  comes out. Only `rough_area.rs` finding nothing sheet-like says `None`.
- Everything crossing a file is `pub(super)`; nothing here becomes `pub`. The one exception is
  `pub(crate) use rough_area::shrink_to_gray`, which `src/deskew.rs` calls so that it shrinks
  a photo exactly the way this search did.
- Every tuning number stays a `const` beside the code that uses it, with its measurement in
  its own doc comment. Moving a const next to a sibling number instead of next to its user is
  how the measurement gets separated from the thing it was measured on.

## What a newcomer gets wrong

Raising a cap to chase one bowed edge. `INWARD_HAIR`, `MOST_INWARD` and `MOST_LEAN` each carry
what was already tried at a higher value and what it cost - six pixels off a flat sheet, a
side collapsing from -25 to -60. Read the const's own doc before touching it, and note that
their three caps add up to a millimetre of A4 on purpose (Julian, 2026-08-18).

The checks: `cargo test --workspace` for the whole engine, `cargo doc -p core_engine
--no-deps` for the links across these files, `examples/edge_error.rs` for how far each side
sits from the real edge, and `backend-core-runner --deskew` for the four corners, which is the
only thing that sees what a lean costs.
