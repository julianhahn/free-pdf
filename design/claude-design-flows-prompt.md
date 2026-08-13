# Design prompt 2 — FreePDF, the remaining screens of every flow

## Read this first

The FreePDF design system **already exists**. It was delivered as code, not as pictures: token
files, 18 components, guideline cards, and a click-through iPhone kit. It is **decided and
closed** (Julian, 2026-08-13).

Do not re-invent any of it. Do not offer a second direction. Do not change a colour, a face, a
size step, a spacing step, a radius or a shadow. **Every screen below is composed out of the
delivered components, called by their real names.** If a screen seems to need a new colour, a
new size or a new word — stop and ask, do not invent it.

Five iPhone screens were delivered with the system: **ScansScreen, CameraScreen, PagesScreen,
AdjustScreen, DoneScreen**. This round is about the **remaining** screens and states of every
flow, plus a review of those five (see "The five that already exist").

### The delivered components — these exact names

```
| Group | Components |
| --- | --- |
| core | Button, IconButton, Shutter, SectionLabel, Tag, Icon |
| forms | Switch, Slider, TextField |
| document | PageImage, PageCounter, Viewfinder |
| lists | ScanRow, MenuList |
| feedback | ConfirmDialog, EmptyState, ErrorLine, ProgressLine |
```

What each one already does, so nothing is rebuilt by accident:

```
| Component | Already covers |
| --- | --- |
| Button | primary / secondary / destructive / ghost, fullWidth, disabled, busy (running label) |
| IconButton | 36 px drawn, 44 pt tappable, outlined or plain, with a spoken label |
| Shutter | 72 px accent ring on a solid paper disc, disabled while the photo is written, spoken label |
| SectionLabel | 13 px uppercase group label |
| Tag | small chip for a page's state |
| Icon | Lucide glyph recoloured by mask |
| Switch | 42 x 24 outlined switch row, label plus optional sub-line, disabled |
| Slider | hairline track, printed value in tabular figures, min/max labels, the engine's suggestion as a tick |
| TextField | label, placeholder, value, optional trailing text |
| PageImage | a page in its paper frame; no picture = ruled placeholder; grey mode; refused state with its own text; corner label; selectable; tappable |
| PageCounter | "Page 3 of 12" in tabular figures, on paper or over a viewfinder |
| Viewfinder | 3:4 dark preview stage, accent corner marks, one quiet note line inside |
| ScanRow | date title, derived subtitle, thumbnail, accent chevron, hairline, swiped state with the Delete action |
| MenuList | a titled menu, items with an icon, a destructive item, a disabled item |
| ConfirmDialog | the one raised surface: title, body, destructive confirm, cancel |
| EmptyState | icon, title, body, optional action — also the shape for a full-screen takeover |
| ErrorLine | the engine's own sentence, above the content |
| ProgressLine | a line, a 3 px bar, a note |
```

Spacing is the delivered 4.6 px step scale (space-1 … space-6 = 4.6, 9.2, 13.8, 18.4, 27.6,
36.8). Screen padding is space-4. **No free numbers.**

---

## The five that already exist

These five came with the system. **Do not redraw them from scratch.** Review each against the
flows below and hand back a short list of what is missing or wrong — the flows contain states
the delivered version does not have.

```
| Delivered screen | Covers | Review against |
| --- | --- | --- |
| ScansScreen | S3 | all seven row subtitles, pressed row, error line on top |
| CameraScreen | S6 | disabled shutter (S7), counter at 1 / 7 / 40 (S8), failure line (S9), stand-in note (S12) |
| PagesScreen | S15 | 40-page navigation, grey on (S16), refused page (S17), busy button (S21), failure (S22) |
| AdjustScreen | S23 | the six tools one by one (S24–S29) and both apply paths (S30–S32) |
| DoneScreen | S33 | field in use (S34), photos already deleted (S35) |
```

---

## The vocabulary, exactly these words

A scan is made of **pages**. A page starts as a **photo**. The finished result is **the PDF**.
The word "document" appears in one place only: the camera permission sentence.

All copy below is the **English**. A full German translation already exists and is signed off —
you do not need to design or invent it. But German strings run about 30% longer, so no layout
may depend on the English length.

---

# The flows

Nine flows. Every screen, with when it is seen, what is on it, its states, its exact English
copy, and **what it is built from**.

---

## Flow 1 — First launch and the empty state

### S1 · Scans, empty
Seen the very first time the app opens, and any time every scan has been deleted.

Built from: `EmptyState` (icon, title, body) with a `Button` action; the screen title and the
top-right "New scan" are the app bar. No tab bar, no settings, no account.

```
| Where | English |
| --- | --- |
| Title | Scans |
| Action | New scan |
| Empty title | No scans yet |
| Empty body | Tap New scan and photograph the pages, one after another. You can stop whenever you like. |
```

### S2 · Scans, empty, with an error line
Seen when "New scan" could not make the folder — the phone is out of storage.

Built from: `ErrorLine` above `EmptyState`. The sentence is the system's own and is never
rewritten; show it with a plausible one. Cleared on the next reload.

Tapping "New scan" when it works goes straight to the camera on Page 1. No naming step, no
template picker, no onboarding.

---

## Flow 2 — The list of scans

### S3 · Scans, with rows — **delivered as ScansScreen, review only**
The landing screen whenever at least one scan exists. Rows newest first. The row title is the
folder date, e.g. "11 Aug 2026, 20:14" — there is no renaming, the date **is** the name.

Built from: a list of `ScanRow` with `thumb`, and `ErrorLine` above it when S2's error applies.

Show at least seven rows, one per subtitle, so rhythm can be judged.

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

Also show: a pressed row, and the list with the error line at the top.

### S4 · A row swiped left
Built from: `ScanRow` with `swiped` — the 96 px Delete action is already part of the component.
Nothing is deleted yet.

### S5 · Delete-a-scan confirmation
Built from: `ConfirmDialog` over the list. Never skipped.

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

### S6 · Camera, ready — **delivered as CameraScreen, review only**
Seen right after "New scan", and every time an unfinished scan is reopened. The title is the
number the **next** shot lands on. Live preview at 3:4, portrait fixed, flash off. No corner
thumbnail of the last shot, no photo-library import — deliberately.

Built from: `Viewfinder` (with the live preview inside), `PageCounter` with `onDark` over it,
`Shutter` placed where a thumb reaches, `Button` fullWidth under it.

```
| Where | English |
| --- | --- |
| Title | Page 7 |
| Shutter, VoiceOver | Photograph page 7 |
| Button | Scan 8 pages |
| Button, disabled | Photograph at least one page |
```

### S7 · Camera, shutter disabled while the photo is written
Built from: `Shutter` with `disabled`. Seen for the fraction of a second after each press — the
shutter is dead until the photo is on disk, which is what makes one press exactly one page. It
must **look** dead and say so to a screen reader. Show this state explicitly.

### S8 · Camera, page counter states
Built from: `PageCounter`. Show it at "Page 1", "Page 7" and "Page 40" — tabular figures, so
the title does not shuffle while it counts. Also show the state before the first shot, where
`Button` is `disabled` and reads "Photograph at least one page".

### S9 · Camera, a photo missed the disk
Built from: `ErrorLine` over the `Viewfinder`. One sentence shape, reason swapped in:

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
The whole screen becomes the sentence plus one button. No preview behind it.

Built from: `EmptyState` (this is the full-screen takeover shape) with a `Button` action.

```
| Where | English |
| --- | --- |
| Sentence | FreePDF needs the camera to photograph the pages. |
| Button | Open Settings |
```

### S11 · Camera, the screen cannot work
Built from: `EmptyState` with no action. Same shape as S10. Three sentences use it:

```
| Case | English |
| --- | --- |
| no camera hardware | This iPhone has no camera to photograph with. |
| session failed to start | The camera could not be started. |
| stand-in failed | Page 7 could not be drawn. |
```

### S12 · Camera, simulator stand-in
Built from: `Viewfinder` with its `note`: "No camera on this iPhone. The shutter draws a page
instead." Nothing new is needed.

Leaving the camera at any moment is safe. Coming back lands on the viewfinder at the next free
number.

---

## Flow 4 — The scan runs (the drain)

### S13 · Scanning progress
Seen after tapping "Scan 8 pages". One page is cleaned at a time. The line counts photos done,
not page numbers.

Built from: `ProgressLine` (line, bar, note).

```
| Where | English |
| --- | --- |
| Line | Scanning page 4 of 12 |
| Note | You can close the app. It carries on from here. |
```

Show it early (page 1 of 12) and late (page 11 of 12), so the bar is judged at both ends.

### S14 · Scanning, a page was refused
Built from: `ProgressLine` plus `ErrorLine` with the cleanup's own sentence. The run **carries
on** — the bar never gets stuck. When there is nothing left to do the screen moves to the
pages, which is where a refused page can be retried, retaken or deleted.

---

## Flow 5 — Checking and retaking the pages

### S15 · Pages, a page shown — **delivered as PagesScreen, review only**
Seen once every photo has become a page, and whenever a finished scan is opened for changes.
Title "Page 3 of 12". A carousel, one page per swipe, pinch to zoom (this screen exists to read
small print). A "Page" menu top right. One `Switch` for the whole scan, "Grey", on this screen
and not inside Adjust. A `Button` fullWidth at the bottom.

Built from: `PageCounter`, `PageImage` (large), `Switch`, `Button`, `IconButton` for the menu.

**Missing component — please add it to the system, do not draw it once.** The navigation under
the page is not 40 swipes: it needs a rail of small pages plus a jump straight to a page
number. `PageImage` is the tile, but there is no component for the rail or the jump. Add a
`PageStrip` (a scrolling rail of `PageImage` thumbnails with one selected, plus the jump
control) to the system, with its own props and states, so every client gets the same one.

```
| Where | English |
| --- | --- |
| Title | Page 3 of 12 |
| Switch | Grey |
| Button | Make PDF |
| Button, running | Making the PDF… |
```

Show it for a 12-page scan and for a 40-page scan — the second is the one that tests the rail.

### S16 · Pages, Grey switched on
Built from: the same screen, `Switch` checked, `PageImage` with `grey`. Grey is per scan, not
per page.

### S17 · Pages, a refused page
Built from: `PageImage` with `state="refused"` and its `refusedText`, plus a `Button`
(secondary) for the action. No new component.

```
| Where | English |
| --- | --- |
| Card | This page could not be scanned. |
| Action | Scan this page again |
```

### S18 · The Page menu, while checking
Built from: `MenuList`, title "Page", three items, the third marked destructive.

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
Built from: the same `MenuList` with a fourth item, **Shoot another page** — see Flow 8.

### S20 · Delete-a-page confirmation
Built from: `ConfirmDialog`.

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
Built from: `Button` with `busy` — the running label is already a state of the component. "Make
PDF" appears **only** once every photo has a page. The pages stay visible and readable behind it.

### S22 · Pages, making the PDF failed
Built from: `ErrorLine` above the content, with the engine's own sentence. The pages stay. The
button can be tapped again.

---

## Flow 6 — Adjusting a page

Adjust always comes **after** the automatic clean-up, on a page the user can already see.
Reached from the Page menu. The principle is suggest-then-apply: every control opens sitting on
the value the app suggested — that is what `Slider`'s `suggested` tick is for — and the user
moves it or leaves it.

There is **no live preview anywhere in this app.** The picture on this screen is the page as it
stands now. Values are set, Apply is tapped, about a second passes, then the result is looked
at. Do not design a preview that updates as a slider moves.

A page whose photo has been deleted cannot be adjusted at all.

### S23 · Adjust, common frame — **delivered as AdjustScreen, review only**
Top bar: Cancel · title · Apply. A large picture of the page. Under it a strip of six tool
names, one active at a time. Under that, the controls for the active tool. At the bottom, one
switch.

Built from: `Button` (Cancel ghost, Apply primary), `PageImage` large, `SectionLabel` over the
control group, `Switch` at the bottom.

**Missing component — please add it to the system.** The six-tool strip has no component.
`Tag` is a state chip, not a selectable tool, and `MenuList` is a menu, not a horizontal strip.
Add a `ToolStrip` (horizontal, one active at a time, 44 pt targets, spoken labels) rather than
drawing it once on this screen.

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
Built from: `PageImage` with four drag handles on it, `Switch` "Pull the sheet flat", and a
quiet note line under the control with three states: nothing to say, nothing to cut, a warning.

**Missing component — please add it to the system.** The draggable corner handles on a page are
used by both Edges and Crop and belong in the system, not on two screens. Add a `PageHandles`
overlay (four or eight handles over a `PageImage`, with the refusal state S28 needs).

```
| Note state | English |
| --- | --- |
| nothing to cut | The sheet fills the whole photo, so there is nothing to cut away. |
| warning | The page runs off the frame. Move back and photograph it again. |
```

### S25 · Adjust → Straighten
Built from: one `Slider`, −10 to +10 degrees, one decimal, `unit` "°", both ends labelled, the
suggestion as its tick, plus a `Button` ghost "Back to the suggestion".

### S26 · Adjust → Brightness
Built from: two `Slider` and one `Switch`. Black point is how dark the darkest part becomes;
white point is how bright the paper becomes. Both open where the app suggested.

### S27 · Adjust → Sharpen
Built from: one `Slider`, 0 to 20, opening at 0.6. Zero means no sharpening at all — show that
end state.

### S28 · Adjust → Crop
Built from: `PageImage` plus the `PageHandles` asked for in S24. A box that does not fit is
refused, not silently shrunk — show what that refusal looks like, and make it a state of
`PageHandles`.

### S29 · Adjust → Turn
Built from: one `IconButton` (outlined), a quarter turn clockwise per tap. Show the page after
one tap.

### S30 · Applying to one page
Built from: `Switch` off, `Button` with `busy` reading "Applying…". Only this page is rewritten.
About a second.

### S31 · Applying to all pages
Built from: `ProgressLine` as a full-screen takeover, with `PageCounter` for the counter line.
Every page is rewritten from its own photo, one at a time, while the screen stays up.

```
| Where | English |
| --- | --- |
| Line | Applying to 40 pages… |
| Counter | Page 12 of 40 |
| Note | Keep the app open. |
```

This note is the **opposite** of the drain's note in S13, deliberately: the drain survives a
kill, apply-to-all does not. Both use `ProgressLine`, so they must still be visually distinct
enough that the difference is noticed — say how you did that without adding a colour.

### S32 · Applying to all pages, some pages skipped
Built from: `ErrorLine` on the screen the user lands back on. Pages whose photos were deleted
cannot be rewritten; they are skipped and named afterwards in one plain sentence.

Adjusting also deletes an existing PDF, because the PDF is derived from the pages. That happens
silently; there is no dialog for it.

---

## Flow 7 — Making the PDF, the done screen, sharing, deleting the photos

### S33 · Done, photos still there — **delivered as DoneScreen, review only**
Seen the moment the PDF is written, and whenever a finished scan is opened.

Built from: `PageImage` (the PDF's first page), `TextField`, two `Button` primary, one `Button`
ghost, then a `SectionLabel` over a quiet block with a `Button` destructive and its footnote.

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
Built from: `TextField` in three states — empty with the placeholder, focused, typed in. The
keyboard must not cover the two buttons.

### S35 · Done, photos already deleted
The destructive block and its footnote are simply **gone**. Nothing greyed out, nothing left
behind. "Change pages" still works on the pages alone. Show the whole screen in this state —
the shorter layout has to look finished, not truncated.

### S36 · Open PDF — the reader sheet
A sheet inside the app showing the finished PDF, with a close control. Nothing else on it.
Nothing is copied, nothing leaves the phone.

**Missing component — please add it to the system.** `ConfirmDialog` is the only raised surface
the system has, and it is a dialog, not a sheet. Add a `Sheet` (raised surface, a close
`IconButton`, content area) so the reader and any later sheet share one shape.

### S37 · Share PDF
Built from: `Button` primary; the sheet itself is the phone's own — do not design it. Design the
moment before it, and make clear nothing is uploaded unasked.

### S38 · Delete-the-photos confirmation
Built from: `ConfirmDialog`. Asked every time, never remembered. There is no settings screen to
turn it off.

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

Built from: `MenuList` item, then the S6 camera screen. If you decide one calm line belongs on
the camera screen to say the PDF was thrown away, it is a `Viewfinder` `note` or an
`ErrorLine` — not a new component. Show your call.

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

# Fixes asked for

**1. The disabled state is hard to read.** It is `--disabled-opacity: .45` in
`tokens/colors.css`, applied as a flat opacity to the whole control. On a light paper ground
that drops the label below a comfortable reading contrast — and the disabled camera button
("Photograph at least one page") is a real instruction someone has to read, not decoration.

Asked for: a disabled treatment that stays legible. Use a **colour role** — a defined disabled
text colour and a disabled border colour — rather than a blanket opacity over the whole
control. **The target is that the label stays readable at arm's length**, in both themes, on
paper and on the viewfinder. It must still be obvious that the control is dead: shape, border
and the absence of the accent carry that, not faintness. Hand back the new values and show
every control in its disabled state side by side with its live one.

---

# What to hand back

For **every screen above** except the five marked delivered, two things:

1. **A picture** — the screen, in light and in dark, iPhone portrait.
2. **A short written spec**, so it can be rebuilt in code without guessing:
   - which delivered components it uses, **by their real names** (Button, IconButton, Icon,
     Shutter, Tag, SectionLabel, Slider, Switch, TextField, PageCounter, PageImage, Viewfinder,
     MenuList, ScanRow, ConfirmDialog, EmptyState, ErrorLine, ProgressLine) and which props and
     states of each
   - in what order, top to bottom
   - the spacing between them, in the delivered 4.6 px steps — no free numbers
   - anything genuinely new: name it, say why no existing component could do it, and propose it
     as a **new component for the system**, not as a one-off drawing on that screen
   - the VoiceOver label for every control on it, written out

For the five delivered screens: a list of what the flows show that the kit's version does not,
and what to change. Do not redraw them.

If a word is missing, ask — do not write new copy.

---

# The hard constraints, again

- iPhone, **portrait only**. No iPad, no landscape, no web, no desktop.
- One-handed. The shutter sits where a thumb reaches.
- **Light and dark, both first class.** Never hand back only one.
- Large text sizes must not break a layout. Nothing pinned to a fixed height that assumes small
  text. German runs ~30% longer.
- A written-out VoiceOver label on every control, saying what it does, not what it looks like.
- 44 pt minimum touch target, even where the drawn control is smaller.
- Never colour alone: there is no red in this theme, so a destructive action is carried by its
  words, by accent-700 / accent-300, and by the double rule that already makes a destructive
  button a different shape.
- No network of any kind — no cloud, no sync, no upload, no "backing up".
- No account, no sign-in, no onboarding.
- **No settings screen.** Every choice is asked in the moment and never remembered.
- No renaming a scan, no reordering pages, no inserting a page in the middle.
- No live preview of an adjustment. The camera viewfinder is the only moving picture in the app.
- No delete that happens straight away. Scan, page and photos each ask first.
- No emoji, no illustration, no mascot, no stock photography, no gradients, no textures, no
  second accent colour. The only image in the app is a page.

# The thing to watch

This is a **reading aesthetic** — serif faces, hairline gold, colour as a stroke — in an app
that is camera, thumb and sliders in bad light. The system already answered that in two places,
and both answers are decided: the shutter is found by the mass of its solid paper disc, not by
its ring; the destructive button carries a double rule so it is a different *shape*, not just
different words.

Hold to those two answers on every screen you draw. Do not thicken a hairline elsewhere to
solve a legibility problem — the disabled fix above is the one place the treatment is reopened,
and it is reopened as a colour role, not as weight.
