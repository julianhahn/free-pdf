# Design prompt 2 — FreePDF, the whole flows (paste into the same Claude Design conversation)

## Read this first

You already designed FreePDF's design system in this conversation: the editorial style —
Cormorant Garamond headings over Lora body, one gold accent, outlined controls, colour as a
stroke and never a fill, no red anywhere. That system is now **decided and closed** (Julian,
2026-08-13). Do not re-invent it, do not offer a second direction, do not change a colour, a
face, a size step, a spacing step or a radius. Every screen below is **composed out of that
system**.

Three components are already approved and built. Everything new must be assembled from them,
not around them:

```
| Component | Approved states |
| --- | --- |
| Scan row | seven status lines, pressed, swiped-left with a Delete action |
| Buttons | primary, secondary, destructive, ghost, disabled, and the round shutter |
| Adjust controls | switch, labelled slider with its printed value and reset, apply button with a running label |
```

This round is not components. **This round is screens and flows.** Julian wants to judge whole
screens, because a single component on a blank page always looks bare and tells him nothing
about whether the app works.

---

## What is wrong right now, and what to fix

The components read as very minimal. Two likely reasons. Fix both, on purpose:

**1. The app is full of images and shows none.** This is a camera app that makes pictures of
paper, and nothing in the design shows a picture of a page. Put the images in:

- the scan row needs a small page thumbnail (the first page of that scan), so the list looks
  like a shelf of documents and not a settings menu
- the pages screen needs a real page image in its frame, and a filmstrip of neighbouring pages
  under it, not only dots
- the done screen needs a preview of the finished PDF's first page, not just a title
- the camera needs the live preview treated as the main object on the screen
- the adjust screen needs the page big, with the handles on it
- an empty state needs a picture-shaped placeholder, so the empty and the full screen have the
  same skeleton

**2. Too little hierarchy between a heading and a row.** A title at 17 px over a subtitle at
13 px, both in the same weight and colour, reads flat. Give a screen real levels: a screen
title, a section label, a row title, a row subtitle, a caption — visibly different in size,
weight and colour, in that order.

What is wanted is **density and rhythm**, not decoration. More content per screen, clear
repeating vertical spacing, alignment you can see. No new ornament, no textures, no
illustrations, no second accent colour.

---

## The vocabulary, exactly these words

A scan is made of **pages**. A page starts as a **photo**. The finished result is **the PDF**.
The word "document" appears in one place only: the camera permission sentence.

All copy below is the **English**. A full German translation already exists and is signed off —
you do not need to design or invent it. But German strings run about 30% longer, so no layout
may depend on the English length.

---

# The flows

Nine flows. Every screen in each flow, with when it is seen, what is on it, its states and its
exact English copy.

---

## Flow 1 — First launch and the empty state

### S1 · Scans, empty
Seen the very first time the app opens, and any time every scan has been deleted.

On it: screen title "Scans", one action "New scan" top right, and a centred empty block —
picture-shaped placeholder, headline, one paragraph. Nothing else. There is no tab bar, no
settings, no account.

```
| Where | English |
| --- | --- |
| Title | Scans |
| Action | New scan |
| Empty title | No scans yet |
| Empty body | Tap New scan and photograph the pages, one after another. You can stop whenever you like. |
```

### S2 · Scans, empty, with an error line
Seen when "New scan" could not make the folder — the phone is out of storage. One line in
destructive colour above the content, cleared on the next reload. The text is the system's own
finished sentence; the app never rewrites it. Show it with a plausible sentence.

Tapping "New scan" when it works goes straight to the camera on Page 1. There is no naming
step, no template picker, no onboarding.

---

## Flow 2 — The list of scans

### S3 · Scans, with rows
The landing screen whenever at least one scan exists. Rows newest first. The row title is the
folder date, e.g. "11 Aug 2026, 20:14" — there is no renaming, the date **is** the name.

Show a list long enough to judge rhythm: at least seven rows, one per status line, and add the
page thumbnail asked for above.

```
| Row state | English subtitle |
| --- | --- |
| empty | No pages yet |
| shooting | 8 pages — keep shooting |
| shooting, one page | 1 page — keep shooting |
| scanning | 12 of 40 pages scanned |
| ready | 40 pages — ready to check |
| done | 40 pages — PDF ready |
| done, photos deleted | 40 pages — PDF ready, photos deleted |
```

Also show: a pressed row, and the list with the error line from S2 at the top.

### S4 · A row swiped left
Swiping a row reveals one 96 px wide **Delete** action in destructive colour. Nothing is
deleted yet.

### S5 · Delete-a-scan confirmation
Seen after tapping Delete on the swiped row. Never skipped.

```
| Where | English |
| --- | --- |
| Title | Delete this scan? |
| Body | 40 pages, the PDF and 40 photos go. This cannot be undone. |
| Confirm | Delete scan |
| Cancel | Cancel |
```

Cancel does nothing. Confirm removes the whole scan and the list reloads.

---

## Flow 3 — Shooting the pages

### S6 · Camera, ready
Seen right after "New scan", and every time an unfinished scan is reopened. The title is the
number the **next** shot lands on. Live preview at 3:4, portrait fixed, flash off. One shutter
under the preview, reachable one-handed with a thumb. One full-width button under that. No
corner thumbnail of the last shot, no photo-library import — deliberately.

```
| Where | English |
| --- | --- |
| Title | Page 7 |
| Shutter, VoiceOver | Photograph page 7 |
| Button | Scan 8 pages |
| Button, disabled | Photograph at least one page |
```

### S7 · Camera, shutter disabled while the photo is written
Seen for the fraction of a second after each press. The shutter is dead until the photo is on
disk — that is what makes one press exactly one page. It must **look** dead and it must say so
to a screen reader. Design this state explicitly.

### S8 · Camera, page counter states
The counter is the title and it counts up as pages are shot. Show it at "Page 1", "Page 7" and
"Page 40" — numbers use tabular figures so the title does not shuffle while it counts. Also
show the state before the first shot, where the "Scan …" button is disabled and reads
"Photograph at least one page".

### S9 · Camera, a photo missed the disk
One line over the preview, destructive colour. One sentence shape, with the reason swapped in:

`Page 7 was not saved: <why> Nothing already photographed is lost.`

```
| Reason | English |
| --- | --- |
| write failed | the iPhone is out of storage. |
| session not running | the camera is not ready. |
| empty capture | the camera handed over no photo. |
| capture ended early | the camera stopped before the photo arrived. |
```

Design the line once and show it with the storage sentence.

### S10 · Camera, permission denied
The whole screen becomes the sentence plus one button. There is no preview behind it.

```
| Where | English |
| --- | --- |
| Sentence | FreePDF needs the camera to photograph the pages. |
| Button | Open Settings |
```

### S11 · Camera, the screen cannot work
Same full-screen takeover shape as S10, no button. Three sentences use it:

```
| Case | English |
| --- | --- |
| no camera hardware | This iPhone has no camera to photograph with. |
| session failed to start | The camera could not be started. |
| stand-in failed | Page 7 could not be drawn. |
```

### S12 · Camera, simulator stand-in
A quiet note under the preview area on a phone with no camera, where the shutter draws a page
instead of taking one: "No camera on this iPhone. The shutter draws a page instead."

Leaving the camera at any moment is safe. Coming back lands on the viewfinder at the next free
number.

---

## Flow 4 — The scan runs (the drain)

### S13 · Scanning progress
Seen after tapping "Scan 8 pages". One page is cleaned at a time. The line counts photos done,
not page numbers.

```
| Where | English |
| --- | --- |
| Line | Scanning page 4 of 12 |
| Note | You can close the app. It carries on from here. |
```

A line of text, a bar, a reassurance note. Show it early (page 1 of 12) and late (page 11 of
12), so the bar is judged at both ends.

### S14 · Scanning, a page was refused
The cleanup refused one page. Its own finished sentence appears in destructive colour and the
run **carries on** — the bar never gets stuck. When there is nothing left to do the screen
moves to the pages, which is where a refused page can be retried, retaken or deleted.

---

## Flow 5 — Checking and retaking the pages

### S15 · Pages, a page shown
Seen once every photo has become a page, and whenever a finished scan is opened for changes.
Title "Page 3 of 12". A carousel, one page per swipe, pinch to zoom (this screen exists to read
small print). Under the page: navigation that is not 40 swipes — a filmstrip or dots with
arrows **plus** a jump straight to a page number. A "Page" menu top right. One switch for the
whole scan, "Grey", living on this screen and not inside Adjust. A full-width primary button at
the bottom.

```
| Where | English |
| --- | --- |
| Title | Page 3 of 12 |
| Switch | Grey |
| Button | Make PDF |
| Button, running | Making the PDF… |
```

Show it for a 12-page scan and for a 40-page scan — the second is the one that tests the
navigation.

### S16 · Pages, Grey switched on
Same screen, the switch on, the page image grey. Grey is per scan, not per page.

### S17 · Pages, a refused page
Instead of an image, a card in the page frame.

```
| Where | English |
| --- | --- |
| Card | This page could not be scanned. |
| Action | Scan this page again |
```

### S18 · The Page menu, while checking
Three items. Delete is marked as the destructive one.

```
| Item | English |
| --- | --- |
| Menu title | Page |
| 1 | Retake this page |
| 2 | Adjust page |
| 3 | Delete page |
```

"Retake this page" opens the camera on that one slot, one shot, and comes straight back.

### S19 · The Page menu, on a finished scan
The same menu with a fourth item, **Shoot another page** — see Flow 8.

### S20 · Delete-a-page confirmation

```
| Where | English |
| --- | --- |
| Title | Delete this page? |
| Body | The photo goes too. This cannot be undone. |
| Confirm | Delete page |
| Cancel | Cancel |
```

Page numbers keep their gaps after a delete and are never renumbered. There is no reorder and
no insert-in-the-middle, on purpose.

### S21 · Pages, making the PDF
"Make PDF" appears **only** once every photo has a page. While it runs the button reads
"Making the PDF…" and the pages stay visible and readable behind it.

### S22 · Pages, making the PDF failed
The engine's own sentence in destructive colour above the content. The pages stay. The button
can be tapped again.

---

## Flow 6 — Adjusting a page

Adjust always comes **after** the automatic clean-up, on a page the user can already see.
Reached from the Page menu. The principle is suggest-then-apply: every control opens sitting on
the value the app suggested, and the user moves it or leaves it.

There is **no live preview anywhere in this app.** The picture on this screen is the page as it
stands now. Values are set, Apply is tapped, about a second passes, then the result is looked
at. Do not design a preview that updates as a slider moves.

A page whose photo has been deleted cannot be adjusted at all.

### S23 · Adjust, common frame
Top bar: Cancel · title · Apply. A large picture of the page. Under it a strip of six tool
names, one active at a time. Under that, the controls for the active tool. At the bottom, one
switch.

```
| Where | English |
| --- | --- |
| Title | Adjust page 3 |
| Confirm | Apply |
| Cancel | Cancel |
| Reset | Back to the suggestion |
| Switch | Apply to all pages |
| Tools | Edges · Straighten · Brightness · Sharpen · Crop · Turn |
```

### S24 · Adjust → Edges
Four drag handles on the page picture, pre-set to the corners the app found, plus one on/off
switch "Pull the sheet flat". A note line sits under the control and has three states: nothing
to say, nothing to cut, or a warning.

```
| Note state | English |
| --- | --- |
| nothing to cut | The sheet fills the whole photo, so there is nothing to cut away. |
| warning | The page runs off the frame. Move back and photograph it again. |
```

### S25 · Adjust → Straighten
One slider, −10 to +10 degrees, one decimal, the value printed beside the label in accent, both
ends labelled. Plus "Back to the suggestion".

### S26 · Adjust → Brightness
Two sliders and one on/off. Black point is how dark the darkest part becomes; white point is
how bright the paper becomes. Both open where the app suggested.

### S27 · Adjust → Sharpen
One slider, 0 to 20, opening at 0.6. Zero means no sharpening at all — show that end state.

### S28 · Adjust → Crop
Drag handles on the page picture. A box that does not fit is refused, not silently shrunk —
show what that refusal looks like.

### S29 · Adjust → Turn
One button, a quarter turn clockwise per tap. Show the page after one tap.

### S30 · Applying to one page
"Apply to all pages" is off. Only this page is rewritten. About a second. Brief in-place busy
state on the Apply button: "Applying…"

### S31 · Applying to all pages
The switch is on. Every page is rewritten from its own photo, one at a time, while the screen
stays up. Full-screen progress.

```
| Where | English |
| --- | --- |
| Line | Applying to 40 pages… |
| Counter | Page 12 of 40 |
| Note | Keep the app open. |
```

This note is the **opposite** of the drain's note in S13, deliberately: the drain survives a
kill, apply-to-all does not. The two progress screens must be visually distinct enough that the
difference is noticed.

### S32 · Applying to all pages, some pages skipped
Pages whose photos were deleted cannot be rewritten. They are skipped and named afterwards, in
one plain sentence on the screen the user lands back on.

Adjusting also deletes an existing PDF, because the PDF is derived from the pages. That happens
silently; there is no dialog for it.

---

## Flow 7 — Making the PDF, the done screen, sharing, deleting the photos

### S33 · Done, photos still there
Seen the moment the PDF is written, and whenever a finished scan is opened.

On it: the title, a preview of the PDF's first page, a text field, two primary buttons, one
ghost action, then a quiet destructive block at the bottom with its footnote.

```
| Where | English |
| --- | --- |
| Title | PDF ready |
| Field label | Name for the shared copy |
| Field placeholder | scan |
| Button | Open PDF |
| Button | Share PDF |
| Ghost action | Change pages |
| Destructive | Delete the 40 photos (78 MB) |
| Footnote | The PDF stays. Deleted photos cannot be brought back. |
```

The name is used only for the copy that leaves through Share. Nothing is stored — reopen the
scan and the field is empty again, and the scan itself keeps its date name.

### S34 · Done, the name field in use
Empty with the placeholder, focused, and typed in. The keyboard must not cover the two buttons.

### S35 · Done, photos already deleted
The destructive block and its footnote are simply **gone**. Nothing greyed out, nothing left
behind. "Change pages" still works on the pages alone. Show the whole screen in this state —
the shorter layout has to look finished, not truncated.

### S36 · Open PDF — the reader sheet
A sheet inside the app showing the finished PDF, with a close control. Nothing else on it.
Nothing is copied, nothing leaves the phone.

### S37 · Share PDF
Opens the phone's own share sheet on the PDF, carrying the typed name. Do not design the sheet
itself — design the moment before it, and make clear nothing is uploaded unasked.

### S38 · Delete-the-photos confirmation
Asked every time, never remembered. There is no settings screen to turn it off.

```
| Where | English |
| --- | --- |
| Title | Delete the 40 photos? |
| Body | The PDF stays. Without the photos the pages can no longer be adjusted. |
| Confirm | Delete photos |
| Cancel | Cancel |
```

"Keep the photos" needs no button — doing nothing is the other half of the choice.

---

## Flow 8 — Adding a page to a finished scan

### S39 · Shoot another page
From the Page menu on a finished scan (S19). Tapping it deletes the PDF, exactly as "Change
pages" does, and opens the camera at the next free page number. The new page is cleaned like
any other and the PDF is made again afterwards.

Design the hand-off: the user was on a done scan and is now on a camera screen. Nothing on the
camera screen tells them the PDF was thrown away — decide whether one calm line belongs there,
and show your call.

---

## Flow 9 — Coming back after a force-quit

No new screens. Nothing is stored, so nothing is lost: the step the app shows is read off the
files every time. Use this to check that each screen above stands on its own as a **landing**
screen, with no state carried in from the screen before it.

```
| Killed when | Where the user lands |
| --- | --- |
| before the first shot | the list, row reads "No pages yet"; tap → camera |
| mid-shooting | the camera, at "Page 12" again |
| mid-scan | the progress line, carrying on at the first unscanned page |
| all pages scanned | the pages |
| after Make PDF | the done screen |
| after deleting the photos | the done screen, destructive block gone |
| mid apply-to-all | the pages, some adjusted and some not, with no way to tell which |
```

---

# What to hand back

For **every screen above**, two things:

1. **A picture** — the screen, in light and in dark, iPhone portrait.
2. **A short written spec**, so it can be rebuilt in code without guessing:
   - which existing components it uses, using the names already established in this
     conversation (Scan row, Primary button, Secondary button, Destructive button, Ghost
     button, Shutter, Switch, Slider, Apply button)
   - in what order, top to bottom
   - the spacing between them, in the spacing steps already decided — no free numbers
   - anything genuinely new: name it, and say why an existing component could not do it
   - the VoiceOver label for every control on it, written out

If a screen needs something that does not exist yet, say so plainly rather than inventing a
colour, a size or a word. If a word is missing, ask — do not write new copy.

---

# The hard constraints, again

- iPhone, **portrait only**. No iPad, no landscape, no web, no desktop.
- One-handed. The shutter sits where a thumb reaches.
- **Light and dark, both first class.** Never hand back only one.
- Large text sizes must not break a layout. Nothing pinned to a fixed height that assumes small
  text. German runs ~30% longer.
- A written-out VoiceOver label on every control, saying what it does, not what it looks like.
- 44 pt minimum touch target, even where the drawn control is smaller.
- Never colour alone: with no red in this theme, a destructive action is carried by its words.
- No network of any kind — no cloud, no sync, no upload, no "backing up".
- No account, no sign-in, no onboarding.
- **No settings screen.** Every choice is asked in the moment and never remembered.
- No renaming a scan, no reordering pages, no inserting a page in the middle.
- No live preview of an adjustment. The camera viewfinder is the only moving picture in the app.
- No delete that happens straight away. Scan, page and photos each ask first.

# The thing to watch

This is a **reading aesthetic** — serif faces, hairline gold, colour as a stroke — in an app
that is camera, thumb and sliders in bad light. Two places is where that shows, and they are
the two to get right:

- **the shutter** — a 1 px gold ring on a dark viewfinder is hard to find with a thumb
- **the destructive button** — "Delete the 40 photos" carries no red in this theme

Fix both **inside** this style. They are not a reason to reopen the style, and a hairline must
not be quietly thickened everywhere to solve them. Show what you did and say why it works with
a thumb, in the dark, holding paper.
