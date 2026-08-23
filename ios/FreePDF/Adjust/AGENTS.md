# Adjusting a page

One more branch of `ScanFlow`'s switch, like the camera - not a second destination. The
view is dumb the way the pages are: values in, `onCancel`/`onApply` out, and `ScanFlow`
owns every file move. Applying deletes `scan.pdf` first, exactly as **Change pages** does.

Two things flow 7 draws that this screen does not, both deliberate and both **Julian's to
overrule**:

- **The bar is the system's.** Cancel, the title and Apply are toolbar items, not a drawn
  52 px bar - the same trade the list makes.
- **The handles may be dragged off the picture** - a corner outside it is read as the
  edge, because the crop crosses as fractions 0…1 and nothing outside the picture can be
  said.

The engine seeds a page once, and after that the controls open on what was last applied:
`freepdf_suggest_adjustments` asks what the automatic run would have done and hands back
the corners, the angle, the two levels points and the three note flags
([`../../../ffi/AGENTS.md`](../../../ffi/AGENTS.md)), and the page's `state/NNNN.txt` wins over it
wherever there is one. The suggestion is still asked for on every open, because its two
notes are about the photo rather than about the values, and **Back to the suggestion**
puts that tool's part of the engine's answer back, so the label is true. The exception is
what the engine measures for itself - the straightening angle and the two tone points -
which only mean something against one set of corners, because the engine reads the tilt
and the tone points off the picture **after** it was pulled flat. So moving the sheet
corners asks the engine for them again, against those corners, and its numbers replace
what is on screen, whether the engine put it there or the user did (Julian, 2026-08-16:
the common flow never leaves the Edges tab, so Apply has to run the automatic steps
again). Crop, turn, grey and the flat switch are the user's and are kept. Four rules fall
out of it:

- **Nothing can be moved before the answer arrives, and no page opens without one.** The
  call runs in the screen's own `.task`, after the two files have been measured, because
  the corners come back in photo pixels and are only a fraction of the picture once the
  photo has been measured. If the engine refuses the photo, its sentence is the screen and
  Apply stays dead - a page whose photo is gone cannot be adjusted at all, and the pages
  screen's own **Adjust page** control is dead for exactly those pages.
- **Apply is refused while the numbers belong to a sheet that is no longer on screen.**
  From the moment a corner moves until the re-measure lands, Apply is dead, because
  `write` stores exactly what it sent - a tap in that gap would run and record numbers
  the drag itself had just made wrong.
- **Every tool shows what it would do.** A debounced run of the engine's own recipe into a
  scratch file under the system's temporary directory - never `photo/`, `page/`, `state/`
  or `scan.pdf`, so `sweep()` never sees it - draws the page the current values would
  produce, one run at a time and the newest superseding the last; only **Apply** writes a
  page. (Julian, 2026-08-16, reversing the earlier "no live preview".)
- **Edges shows the photo, every other tool the page.** The sheet corners are photo pixels,
  so drawing them over the page would put them in a space nothing maps back to. Crop stays
  on the page, and the fraction dragged there is a fraction of the last cut, which the
  paragraph below composes onto the stored one. Both files are measured, and the block the handles live in is
  given the shape of the file it draws: fitted inside a block of another shape the picture
  gets bars, and a handle on a bar is a fraction the engine never sees.
- **An all-pages run does not send this page's pixels to the others.** The corners are
  asked of the engine again per page, and only when "Pull the sheet flat" is on. Everything
  else - crop, angle, levels, sharpen, turn, grey - is the same number everywhere and
  travels unchanged; the crop can, because it is a fraction and not pixels.
- **The turn is remembered, not baked in.** It lives in the page's `state/NNNN.txt` and
  the engine turns the image at every Apply, so the photo stays the camera's untouched
  bytes and the append-only rule holds.
- **A new crop is composed onto the stored one, not swapped for it.** The fraction the
  engine cuts is a fraction of an image that exists only mid-recipe - after the corners,
  the straightening, the cap and the turn - so it is neither the photo nor the page
  ([`../../../core_engine/AGENTS.md`](../../../core_engine/AGENTS.md), "Every step has its own
  space"). The box therefore opens on the whole picture, which is honest because the page
  on screen is already the last cut, and Apply lays the new drag inside the old box - and
  turns the old box with the turn first, one quarter clockwise mapping `(x, y, w, h)` to
  `(1 - y - h, x, h, w)`. It follows that a crop can only ever be tightened; widening is
  **Scan this page again**.

One page an all-pages run could not write shows the engine's own sentence with its page
number in front; more than one missing photo shows the copy table's "Pages 4, 9 and 18 were
not changed…", which is only ever about missing photos. There is no singular of that
sentence in the tables, so none is invented.
