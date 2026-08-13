# Components brief - FreePDF (paste into Claude Design)

## Read this first: a round is being discarded

A previous round delivered a component gallery and a stylesheet beside it, and the two
disagreed. The pictures were drawn in the platform system font (`-apple-system`, SF Pro) and
used not one class of the design system that shipped with them, while that system was a
completely different editorial look. So the pictures showed a stock iPhone app, which is the
one thing this product must not be. That round is thrown away. This one redraws everything.

Three rules follow from it, and they are not negotiable:

1. **Draw the components in the system you define.** Every picture is rendered with the tokens
   below the token set - same fonts, same colours, same spacing. A gallery that does not use
   its own system is not a deliverable.
2. **State the system as tokens**, named, with values, light and dark, before the first
   component.
3. **No picture may use a platform default font or a platform default control.** No
   `-apple-system`, no SF Pro, no Roboto, no system switch, no system slider, no system list
   row, no system alert. Everything is drawn.

---

## The vision (self-contained - do not look for a repository)

**What the app is.** FreePDF turns sheets of paper into one PDF, with the phone camera.
Photograph the pages one after another, the app cleans each photo up so it looks like a scan,
then it makes one PDF. Everything stays on the phone: no account, no sign-in, no server, no
settings screen. Nothing leaves until the user taps Share. It is a tool, not an opinion: it
hands the controls over - edges, straightness, brightness, sharpness - each opening on the
value the app suggested, which the user may simply accept.

**Who holds it.** Someone standing over a table with a stack of paper in one hand and the
phone in the other. One-handed, often. Sometimes in bad light. They want the scan done and the
app gone.

**The direction: paper and archive.** A light ground, serif titles, fine hairlines, a lot of
quiet. It should feel like a well-kept folder of documents - not like a phone app, and not like
a piece of measuring equipment. The reason: the app's subject is paper, so a style borrowed
from paper explains itself without a word.

**Identical everywhere except mechanics.** Colours, type, spacing and shapes are the same on
every client. Only gestures and control mechanics follow the platform: a swipe is the
platform's swipe, a switch behaves like the platform's switch, but it must not **look** like
the platform's switch. One style is defined once and rebuilt natively per client, because a
platform-native look is by definition not recognizable across platforms.

**The tension to solve, not to ignore.** A paper aesthetic has to survive a camera viewfinder,
a shutter and sliders. Paper is light, still and quiet; a viewfinder is dark and moving, a
shutter is pressed with a thumb without looking, a slider is dragged. A hairline on a dark
preview is not a control, it is a decoration. Do not answer this by leaving the style - answer
it inside the style, with weight, size, contrast, and a solid shape where a stroke is too thin.
Three places decide it: **the camera**, **the adjust controls**, **the destructive actions**
(there is no red in this palette, and delete still has to read as delete).

**What makes a round wrong.** It looks like a stock platform app; the shutter needs a second
glance to find; no page images are shown anywhere; it is text-heavy where the content is
pictures; a control whose state cannot be seen at arm's length.

---

## What Julian disliked last time - fix these

- **Everything felt very minimal.** Air with nothing in it is not calm, it is empty.
- **The app is full of images and the design showed none.** Pages, thumbnails, the viewfinder,
  the page being adjusted - the picture is the content and it has to be on screen.
- **Too little hierarchy between a heading and a row.** A title and a list item looked the same
  size and weight, so nothing led the eye.

Ask of this round: **density and rhythm, not decoration.** More on screen, clearly ranked -
bigger jumps between heading, row title and subtitle, real page images at real sizes, tighter
vertical rhythm. Do not answer it with ornament, borders for their own sake, or illustrations.

---

## Vocabulary, use exactly these words

A scan is made of **pages**. A page starts as a **photo**. The finished result is **the PDF**.
The word "document" appears in one place only, the camera permission sentence.

---

## Hand back, in this order

### 1. A token set

Named values, nothing free-floating. A component spec may only reference these names.

- **Colour**, light and dark, both first-class: ground, raised surface, text, muted text, one
  accent, hairline/divider, plus whatever the destructive treatment needs. Give each one a
  role sentence. Give the interaction tints too - hover, pressed, disabled, focus ring, pressed
  row.
- **Type scale**: which face is heading, which is body, the weights, and every size with what
  it is used for. Numbers on screen (page counts, degrees, sizes) use tabular figures so they
  do not jump while counting.
- **Spacing scale**: a step and its multiples, plus the screen padding.
- **Radius scale**.
- **Shadow scale**, light and dark separately - a tinted shadow is invisible on a dark ground.

### 2. Every component, every state

Drawn in the system, light and dark.

### 3. A written spec per component

So it can be rebuilt in code **without measuring a picture**: the component's name (the code
will use that exact name), its sizes in px, its spacing, which tokens it uses for what, its
states, and its VoiceOver label written out.

---

## The components

Each with the states named.

**List and shell**

1. **Top bar** - back control, title, one trailing action or menu. States: with back, without,
   with menu open.
2. **Scan row** - date title (`11 Aug 2026, 20:14`; there is no rename, the date is the name),
   one status line under it, a chevron. Status lines: `No pages yet` / `8 pages — keep
   shooting` / `1 page — keep shooting` / `12 of 40 pages scanned` / `40 pages — ready to
   check` / `40 pages — PDF ready` / `40 pages — PDF ready, photos deleted`. States: rest,
   pressed, swiped-left revealing **Delete**.
3. **Empty state** - shown when there are no scans. `No scans yet` / `Tap New scan and
   photograph the pages, one after another. You can stop whenever you like.`
4. **Error banner** - one line, the sentence comes from the engine and is never rewritten.
   Two placements: at the top of a list, and over the camera preview. States: list, over-photo.

**Pictures - none of these has a design yet, and they are the most important part**

5. **Page thumbnail** - a page image in a frame, at small and medium size, including a
   page number. States: normal, selected, refused page, missing photo.
6. **Page carousel** - the full-size page image frame, one page per swipe, pinch to zoom, page
   dots with left/right arrows, and a jump-to-page control by number (40 pages must not mean 40
   swipes; no thumbnail strip in the jump control). States: page shown, zoomed, first page,
   last page, refused page.
7. **Refused-page card** - sits where the page image would be. `This page could not be
   scanned.` plus the action `Scan this page again`.
8. **Camera viewfinder frame** - the live 3:4 preview, portrait fixed, with its page counter
   (`Page 7`) and the frame that marks the picture area. This is the hardest screen for a paper
   style: a dark moving picture. States: ready, writing a photo, error banner over it,
   permission takeover (`FreePDF needs the camera to photograph the pages.` + `Open Settings`),
   no camera hardware (`This iPhone has no camera to photograph with.`), camera failed to start
   (`The camera could not be started.`), simulator stand-in (`No camera on this iPhone. The
   shutter draws a page instead.`).

**Controls**

9. **Shutter** - the big round one, thumb-reachable one-handed. States: rest, pressed,
   **disabled while the photo is being written** (that disabled state is what makes one press
   one page), disabled before the first page.
10. **Primary button**, full width - states: rest, pressed, disabled, running-with-label
    (`Making the PDF…`, `Applying…`, `Applying to 40 pages…`).
11. **Secondary button** and **plain text button** - same states.
12. **Destructive button** - the quiet kind, with a footnote line under it. Used for `Delete
    scan`, `Delete page`, `Delete the 40 photos (78 MB)`. There is no red in this palette, so
    show how it still reads as destructive. States: rest, pressed, disabled.
13. **Switch** - drawn, never the platform switch. Used for `Grey` (whole scan, on the pages
    screen), `Pull the sheet flat`, `Apply to all pages`. States: off, on, pressed, disabled,
    focused. Its state must be readable at arm's length.
14. **Labelled slider** - label, current value beside it, both end labels, and a reset `Back to
    the suggestion`. Used for Straighten (−10…+10 degrees, one decimal), Brightness (two
    sliders, black point and white point), Sharpen (0…20, opening at 0.6). States: rest,
    dragging, at either end, disabled.
15. **Tool strip** - a row of tool names, one selected: Edges · Straighten · Brightness ·
    Sharpen · Crop · Turn. States: one selected, scrolled.
16. **Crop / edge handles** on a page picture - four handles pre-set to the found corners.
    States: rest, dragging, warning (`The page runs off the frame. Move back and photograph it
    again.`), nothing to cut (`The sheet fills the whole photo, so there is nothing to cut
    away.`).
17. **Text field** - used once, on the done screen: label `Name for the shared copy`,
    placeholder `scan`. States: empty, typing, filled, focused.
18. **Menu** (the `Page` menu) - three items while checking (`Retake this page`, `Adjust page`,
    `Delete page`), four on a finished scan (plus `Shoot another page`), delete marked
    destructive.

**Feedback**

19. **Progress block** - a line, a bar, a note. Two of them, and the notes say opposite things
    on purpose: the drain (`Scanning page 4 of 12`, `You can close the app. It carries on from
    here.`) and apply-to-all (`Applying to 40 pages…`, `Page 12 of 40`, `Keep the app open.`).
    States: starting, mid-run, indeterminate.
20. **Confirmation dialog** - title, body, destructive confirm, cancel. All three deletions ask,
    every time: scan (`Delete this scan?` / `40 pages, the PDF and 40 photos go. This cannot be
    undone.` / `Delete scan`), page (`Delete this page?` / `The photo goes too. This cannot be
    undone.`), photos (`Delete the 40 photos?` / `The PDF stays. Without the photos the pages
    can no longer be adjusted.` / `Delete photos`). Cancel is `Cancel`.

---

## Constraints

- **iPhone portrait first, but the design is for several clients.** Draw it on a 390 x 844
  portrait frame, and keep every value expressible as a token so another client can rebuild it.
- **One-handed.** The thing that gets pressed most sits where a thumb reaches.
- **Light and dark**, both first-class, both drawn.
- **Large text sizes** must not break a layout. Show at least the scan row, a dialog and the
  adjust controls at a large text size.
- **VoiceOver label written out** for every control, not implied.
- Touch targets at least 44 x 44 pt, whatever the drawn size is.
- No icon-only controls: anything tappable carries a word, or a word beside the icon.
- **English words come from the tables above** - do not invent copy. German exists already and
  runs roughly 30% longer, so leave room; do not translate anything yourself.

## Do not design

- Anything implying a network: no sync icon, no cloud, no upload, no "backing up".
- No account, sign-in, profile, onboarding.
- **No settings screen.** Every choice is asked in the moment and never remembered.
- No branding beyond a plain app name. No illustrations that need explaining.
- No renaming a scan, no reorder, no insert-page.
- No live preview of an adjustment. Values are set, Apply is tapped, then the result is looked
  at. The viewfinder is the only moving picture in the app.
- No corner thumbnail on the camera, no import from the photo library.
- No delete that happens straight away.
