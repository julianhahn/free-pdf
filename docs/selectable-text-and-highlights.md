# Selectable text and highlights - what the PDF standard actually says

A PDF page is not text with layout, it is a list of drawing instructions, and text is one of
them: `BT /F1 12 Tf 1 0 0 1 72 700 Tm (Hallo) Tj ET` means put these glyphs at this point. The
file holds no words, no lines and no reading order. Everything below follows from that.

## How a viewer lets you select text

It replays the page and records, for every glyph, where it landed: the text matrix says where
the pen is, the font's width array says how far each glyph moves it. The result is a list of
*(character, box on the page)*, held in memory only. Selecting is a hit test against those
boxes, and words and lines are guessed from the gaps - which is why copied text loses spaces,
mixes up columns, and keeps end-of-line hyphens. The codes are not Unicode either: only the
font's `/ToUnicode` map says which character a code means, so a PDF with real text but no
`/ToUnicode` looks fine and copies as garbage.

## How OCR makes a scan selectable

Nothing ever links text to pixels. OCR reads the image and returns each word with a box in
pixels; the writer places that same word as **invisible** text at the same spot on the page -
render mode `3 Tr`, which neither fills nor strokes:

    x_pt = x_px * scale + offset_x                          # the scale and centring the image got
    y_pt = page_height - (y_px + h_px) * scale - offset_y    # PDF counts y from the bottom

Invisible glyphs are not as wide as the scanned ink, so each word is stretched to its box: font
size from the box height, `Tz` (horizontal scaling) for the width. Tesseract instead embeds a
*glyphless* font of equally wide, outline-less glyphs plus a `/ToUnicode` map. So the text layer
is a geometric guess laid over the picture: that is why selection can sit beside the ink, why it
feels word by word, and why a crooked page selects badly - `deskew`, `straighten` and
`apply_levels` prepare good OCR, not only good looks.

## How a highlight travels between programs

A highlight is not a drawing instruction. It is a separate object in the page's `/Annots`:
`/Subtype /Highlight`, `/QuadPoints` (the corners, in page coordinates), `/C` the colour, `/CA`
the opacity, `/Contents` the note. It never names the text it covers - it says "paint yellow
over this shape". So highlighting works on a plain image scan too; a text layer only lets the
viewer snap the shape to whole words. Every program draws it the same because the annotation
carries `/AP`, a finished appearance a viewer must paint if it is there. Saving appends the new
objects to the end of the file and leaves the old bytes untouched.

## What this means here

Today `images_to_pdf` writes image-only pages: no text, no annotations, and that is honest. OCR
would keep the offline promise - Apple's Vision runs on the device - and the engine side is
small: take a list of *(word, box)* and write the invisible words in `build_page`, with the same
scale and centring the image uses, or the layer drifts off the ink; `pdftotext -bbox` reads it
back in a test. Highlighting needs no OCR. The standard is ISO 32000-2, free from pdfa.org.
