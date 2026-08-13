# TASKS.md - building the delivered design

The design round is finished. This is the list of what has to be built, in the order it has
to be built.

**How to use this file.** Take the top task that is not blocked. Hand the whole task over to
one agent - a task is written so that an agent who has read nothing else can do it. When the
task's check passes, tick it off here in the same commit as the work. Do not start a task
whose "Blocked by" line is not ticked off.

Every path below is absolute. The delivered design lives in
`/Users/julianhahn/free-pdf/design/flows/`. Open the `.dc.html` documents in a browser - they
are self-contained pages and they render. The pictures in
`/Users/julianhahn/free-pdf/design/flows/shots/` are the same screens as PNGs, for an agent
that cannot open a browser.

## The rules that hold for every task

- Read `/Users/julianhahn/free-pdf/AGENTS.md` first, and the `AGENTS.md` next to any file you
  touch. `/Users/julianhahn/free-pdf/user-flows.md` is the truth about behaviour. The delivered
  documents are the truth about looks.
- Where a delivered document and `user-flows.md` disagree, `user-flows.md` wins, and you write
  the disagreement into your report. Four are already known, see "Open questions" at the end.
- Invent no words. Every English and German sentence comes from the copy tables in
  `user-flows.md` or `/Users/julianhahn/free-pdf/ios/AGENTS.md`. Missing words are collected in
  task 4 and answered by Julian, not by you.
- Invent no colours, no sizes, no spacing steps, no radii, no shadows. Everything comes from
  `/Users/julianhahn/free-pdf/design/system/tokens/`.
- Nothing in `/Users/julianhahn/free-pdf/storybook/` ships. It is the picture Julian approves
  before any Swift is written.
- Never run `npm run storybook`; it never returns. Build it instead: `cd
  /Users/julianhahn/free-pdf/storybook && npx storybook build`.

## The list

```
| # | Task | Blocked by | Check |
| --- | --- | --- | --- |
| 1 | Disabled becomes a colour role — DONE | - | npx storybook build |
| 2 | Fold the four proposed components into the system — DONE | - | npx storybook build |
| 3 | Fix the five delivered screens — DONE | 1, 2 | npx storybook build |
| 4 | Collect the missing words, get them from Julian | - | Julian answers |
| 5 | Storybook: flows 1-2, the scans list | 1, 2, 3 | npx storybook build |
| 6 | Storybook: flow 3, the camera | 5 | npx storybook build |
| 7 | Storybook: flow 4, the scan runs | 5 | npx storybook build |
| 8 | Storybook: flow 5, the pages | 5 | npx storybook build |
| 9 | Storybook: flow 6, adjust | 8 | npx storybook build |
| 10 | Storybook: flow 7, done | 5 | npx storybook build |
| 11 | Storybook: flows 8-9, one more page | 6, 8 | npx storybook build |
| 12 | Julian approves the screens | 5-11 | Julian says yes |
| 13 | Widen the C boundary for the adjusted case | - | cargo test --workspace, bash ffi/bridge_check.sh |
| 14 | iOS: the scans list | 12 | bash ios/check/run.sh, by hand |
| 15 | iOS: the camera | 14 | bash ios/check/scan_check.sh |
| 16 | iOS: the scan runs | 14 | bash ios/check/scan_check.sh |
| 17 | iOS: the pages | 16 | bash ios/check/scan_check.sh, by hand |
| 18 | iOS: adjust | 13, 17 | bash ios/check/scan_check.sh, by hand |
| 19 | iOS: done, share, delete the photos | 17 | bash ios/check/scan_check.sh, by hand |
```

Task 13 stands alone: it is Rust and C, it touches no screen, and it can be done at any time.
Task 18 cannot start without it. Nothing in tasks 14 to 19 may start before task 12 - Julian
looks at the screens first.

---

## 1. Disabled becomes a colour role, not an opacity

**Why.** A flat 45% opacity drops a real instruction - "Photograph at least one page" - below
readable contrast, and it fades the shape along with the label. Julian asked for this fix.

**Read.** `/Users/julianhahn/free-pdf/design/flows/FreePDF Foundation.dc.html`, section F1.
The finished CSS is `/Users/julianhahn/free-pdf/design/flows/kit/disabled-role.css`. Pictures:
`shots/01-found.png`, `shots/02-found.png`.

**Build.**
1. Add `--disabled-text`, `--disabled-border`, `--disabled-surface` to
   `/Users/julianhahn/free-pdf/design/system/tokens/colors.css`, light and dark, with the exact
   values from `disabled-role.css`. Add the `.fp-on-dark` override for the viewfinder ground.
   Set `--disabled-opacity` to `1` and leave it defined.
2. In every component under `/Users/julianhahn/free-pdf/design/system/components/`, replace
   `opacity: disabled ? var(--disabled-opacity) : 1` with `color: var(--disabled-text)` and
   `borderColor: var(--disabled-border)`. Where a variant carries the accent - `Button`
   primary, ghost and destructive, `Switch` on, `Slider` thumb, `Shutter` ring - the accent
   drops to `--disabled-border` too. Destructive loses its inset ring when disabled.
3. The `Shutter`'s spoken label while writing is "Photographing page 7, wait".

**Do not.** Do not change any other colour, face, size, spacing, radius or shadow. Do not
delete `--disabled-opacity` yet. Do not copy `disabled-role.css` into the system as a file -
its `.fp-disabled-demo` wrapper is a demo trick, not the fix.

**Done when.** `cd /Users/julianhahn/free-pdf/storybook && npx storybook build` passes, and in
the built Storybook the disabled `Button`, `Switch`, `Slider` and `Shutter` stories show a full
strength shape with a grey label, in light and dark.

---

## 2. Fold the four proposed components into the design system

**Why.** The flows need four things the kit does not have. They are written already; they need
a proper home, types, docs and stories.

**Read.** `/Users/julianhahn/free-pdf/design/flows/FreePDF Foundation.dc.html`, sections F2 to
F5 - each one is the full spec: what it is built from, props, states, order and spacing, and
VoiceOver. The code is `/Users/julianhahn/free-pdf/design/flows/kit/proposed.jsx`.

**Build.** One component per sub-task; each is a small run.

- **2.1 `PageStrip`** - the thumbnail rail plus a jump to a page number. 40 pages are not 40
  swipes. Goes to
  `/Users/julianhahn/free-pdf/design/system/components/document/PageStrip.jsx`.
- **2.2 `ToolStrip`** - six adjust tools, one active, an accent underline on the active one.
  Goes to `/Users/julianhahn/free-pdf/design/system/components/core/ToolStrip.jsx`.
- **2.3 `PageHandles`** - drag handles over a page, four for Edges and eight for Crop, with a
  refused state. Goes to
  `/Users/julianhahn/free-pdf/design/system/components/document/PageHandles.jsx`.
- **2.4 `Sheet`** - a raised surface that is a close control and content, for the PDF reader.
  Goes to `/Users/julianhahn/free-pdf/design/system/components/feedback/Sheet.jsx`.

Each one gets, exactly as the existing components have them: a `.jsx`, a `.d.ts`, a
`.prompt.md`, an export line in `/Users/julianhahn/free-pdf/storybook/ds.js`, and a
`<Name>.stories.jsx` in `/Users/julianhahn/free-pdf/storybook/stories/` with one story per state
named in the spec.

**Do not.** Do not invent a new colour, size or spacing step - every one of these is built from
components and tokens that already exist. Do not rewrite `PageImage`; `PageStrip` and
`PageHandles` sit on top of it.

**Done when.** `npx storybook build` passes and each new component has its own stories, all
states, light and dark.

---

## 3. Fix the five delivered screens

**Why.** The five iPhone screens in `/Users/julianhahn/free-pdf/design/system/ui_kits/iphone/`
were delivered before the flows and are behind them.

**Read.** `/Users/julianhahn/free-pdf/design/flows/FreePDF Foundation.dc.html`, section F6. It
is a change list, screen by screen - work through it literally.

**Build.** One screen per sub-task.

- **3.1 `ScansScreen.jsx`** - seven subtitles, not three; a pressed row state; an `ErrorLine`
  slot above the list; rows newest first.
- **3.2 `CameraScreen.jsx`** - the shutter can be `disabled`; the counter at 1, 7 and 40 and the
  before-the-first-shot state; an `ErrorLine` over the viewfinder; the simulator note on
  `Viewfinder`; the shutter names the page.
- **3.3 `PagesScreen.jsx`** - the inline rail becomes `PageStrip`; "Adjust page" lives in the
  menu only, the ghost button goes; the refused page gets "Scan this page again"; the menu is
  three items while checking and four on a finished scan; "Make PDF" is hidden, not disabled;
  the counter reads "Page 3 of 12" in both places.
- **3.4 `AdjustScreen.jsx`** - the inline tool row becomes `ToolStrip`; corner dragging becomes
  `PageHandles`; "Back to the suggestion" on every tool that has one; the Edges note line has
  three states; Sharpen can sit at 0.
- **3.5 `DoneScreen.jsx`** - `TextField` focused and typed in; the two buttons stay clear of the
  keyboard; the photos-already-deleted state removes the block, not greys it; "Open PDF" opens
  the `Sheet`; the footnote belongs to the block, not the button.

**Blocked by.** 1 and 2 - these screens use the new disabled role and three of the four new
components.

**Done when.** `npx storybook build` passes and the five stories in
`/Users/julianhahn/free-pdf/storybook/stories/Screens.stories.jsx` show every point of the F6
list.

---

## 4. Collect the missing words and get them from Julian

**Why.** The designer used placeholders where no wording exists. A placeholder must never reach
the app.

**Read.** `/Users/julianhahn/free-pdf/design/flows/FreePDF Foundation.dc.html`, section F7, plus
every sentence in the flow documents printed in italic asking to "confirm or replace".

**Build.** No code. One short list, English and German, of every missing sentence: the Crop
refusal (S28), the skipped pages after an apply-to-all (S32), the line before Share (S37), the
"the PDF was removed" note (S39), the Brightness switch label (S26), the refusal wording during
the scan run (S14), the PageStrip words "Go to page" and "Go", and the singular German of the
delete-a-scan body. Hand it to Julian. When he answers, put the answers into the copy tables in
`/Users/julianhahn/free-pdf/user-flows.md` - that is where the app reads its words from.

**The list, as tasks 2 and 3 found it.** Every one of these is a slot in the code with no
default: the screen or component renders nothing until a word arrives. Nothing here was invented.

```
| Where | Missing wording | What it is for |
| --- | --- | --- |
| CameraScreen | the singular of "Scan 8 pages" | the finish button after one shot; "Scan 1 pages" reads wrong |
| PagesScreen | the skipped-pages sentence | names the pages an apply-to-all could not rewrite (S32) |
| PagesScreen | the Make PDF failure sentence | when stitching fails; section 8.5 says only "the engine's sentence" |
| PagesScreen | the page menu's spoken name | section 6 gives the menu title "Page" and nothing more |
| AdjustScreen | the Crop refusal sentence | a crop box that falls outside the page (S28) |
| AdjustScreen | the black point slider label | apply_levels, first slider; 7a is prose, not a table |
| AdjustScreen | the white point slider label | apply_levels, second slider |
| AdjustScreen | the Brightness on/off label | must not reuse the tool name "Brightness" |
| AdjustScreen | "Pull the sheet flat" | the Edges on/off; 7a names it, the section 7 table does not |
| AdjustScreen | the Turn button label | the table gives only the tool name "Turn" |
| AdjustScreen | what Sharpen reads at 0 | 7a says 0 means no sharpening; no word for it |
| DoneScreen | the reader sheet title | section 9.1 gives the sheet no title |
| DoneScreen | the reader sheet close wording | section 9.1 gives no close label |
| DoneScreen | the name field suffix | section 10 gives label and placeholder "scan" only |
| DoneScreen | the photo-deletion group label | the SectionLabel over the delete-photos block |
| ScansScreen | the storage error above the list | section 1 says only "the system's own sentence" |
| PageStrip | "Go to page", "Go" | the jump control |
| ConfirmDialog | the singular German of the delete-a-scan body | one scan, not several |
```

Two more that are a decision, not a translation: `Chrome.jsx` labels the back control "Back",
but `ios/AGENTS.md` says it reads "Scans"; and the camera pairs "Page 7" with "Scan 7 pages"
while both tables pair it with "Scan 8 pages" - section 4.1 and 4.4 make the table's pairing
impossible, so the kit follows the rules and not the table.

**Done when.** Julian has answered every line and `user-flows.md` carries the answers.

---

## 5. Storybook: flows 1 and 2, the scans list

**Read.** `/Users/julianhahn/free-pdf/design/flows/FreePDF Flows 1-2 Scans.dc.html`, screens S1,
S2, S4, S5. Pictures: the `01-*`, `02-*` and `03-*` files in
`/Users/julianhahn/free-pdf/design/flows/shots/`. Behaviour: `user-flows.md` sections 1, 2, 3.

**Build.** Four stories in a new
`/Users/julianhahn/free-pdf/storybook/stories/Flow1Scans.stories.jsx`, each rendered in the
phone frame the existing `Screens.stories.jsx` uses: the empty list, the empty list with an
`ErrorLine`, a row swiped left showing Delete, and the delete confirmation over the list.

**Components.** `EmptyState`, `Button`, `ErrorLine`, `ScanRow` (its own `swiped` state),
`ConfirmDialog`.

**Do not.** Do not build a new list component, a tab bar, a settings screen or a rename. The
title is the folder date; there is no rename by design.

**Done when.** `npx storybook build` passes and the four stories match the document in light and
dark.

**Blocked by.** 1, 2, 3.

---

## 6. Storybook: flow 3, the camera

**Read.** `/Users/julianhahn/free-pdf/design/flows/FreePDF Flow 3 Camera.dc.html`, screens S7 to
S12. Behaviour: `user-flows.md` section 4. Copy: the table in
`/Users/julianhahn/free-pdf/ios/AGENTS.md` under "The camera" - it is the authority, not the
flow document.

**Build.** Stories in `/Users/julianhahn/free-pdf/storybook/stories/Flow3Camera.stories.jsx`:
the shutter disabled while the photo is written (S7); before the first shot, with the counter at
1, 7 and 40 (S8); a photo that missed the disk, with the one sentence shape (S9); permission
denied, the whole screen (S10); the screen cannot work, three sentences, no button (S11); the
simulator stand-in note (S12).

**Components.** `Viewfinder`, `PageCounter` with `onDark`, `Shutter`, `Button`, `ErrorLine`,
`EmptyState`.

**Do not.** Do not add a corner thumbnail, a flash control, a landscape frame or a photo-library
import. All four are decided against in `user-flows.md` DECISIONS.

**Done when.** `npx storybook build` passes and all six states are there in light and dark.

**Blocked by.** 5.

---

## 7. Storybook: flow 4, the scan runs

**Read.** `/Users/julianhahn/free-pdf/design/flows/FreePDF Flow 4 Scanning.dc.html`, S13 and
S14. Behaviour: `user-flows.md` section 5.

**Build.** Stories in `/Users/julianhahn/free-pdf/storybook/stories/Flow4Scanning.stories.jsx`:
the progress line early (1 of 12) and late (11 of 12), and the run with a refused page, where an
`ErrorLine` sits above and the bar keeps moving.

**Components.** `ProgressLine`, `ErrorLine`.

**Do not.** No thumbnails appearing one by one, no preview of the page being worked on, no
cancel button. The run finishes or the app is closed.

**Done when.** `npx storybook build` passes and the three states are there.

**Blocked by.** 5.

---

## 8. Storybook: flow 5, the pages

**Read.** `/Users/julianhahn/free-pdf/design/flows/FreePDF Flow 5 Pages.dc.html`, S16 to S22 and
S16b. Behaviour: `user-flows.md` section 6.

**Build.** Split in two, they are separate runs.

- **8.1 The page and the rail** - `Flow5Pages.stories.jsx`: pages with Grey on (S16), and the
  rail at 40 pages with a refused tile and the jump open (S16b), and a refused page with "Scan
  this page again" (S17).
- **8.2 The menu, the deletion, and Make PDF** - the Page menu while checking, three items
  (S18); the same menu on a finished scan, four items (S19); the delete-a-page confirmation
  (S20); Make PDF busy, "Making the PDF…" (S21); Make PDF failed, with the engine's sentence
  (S22).

**Components.** `PageImage`, `PageStrip`, `Switch`, `Button`, `IconButton`, `MenuList`,
`ConfirmDialog`, `ErrorLine`.

**Do not.** No reorder, no insert in the middle - the page number is the filename and is never
renumbered. Grey is one switch for the whole scan and never appears inside Adjust.

**Done when.** `npx storybook build` passes and all eight states are there.

**Blocked by.** 5.

---

## 9. Storybook: flow 6, adjust

**Read.** `/Users/julianhahn/free-pdf/design/flows/FreePDF Flow 6 Adjust.dc.html`, S24 to S32.
Behaviour: `user-flows.md` section 7, and the tool table in 7a - it says which engine tool each
control reaches and which ones are deliberately unreachable.

**Build.** Split in three.

- **9.1 The tools that drag** - `Flow6Adjust.stories.jsx`: Edges with four handles and the note
  line in all three states (S24), and Crop with eight handles including the refused box (S28).
- **9.2 The tools that slide** - Straighten with its suggestion tick and "Back to the
  suggestion" (S25); Brightness with two sliders and a switch (S26); Sharpen, and Sharpen at
  zero reading "None" (S27); Turn, one button, shown after one tap (S29).
- **9.3 Applying** - one page, Apply busy and Cancel disabled (S30); all pages, the full screen
  takeover with a `PageCounter` above the `ProgressLine` and "Keep the app open." (S31); the
  skipped pages sentence on the pages screen afterwards (S32).

**Components.** `PageHandles`, `ToolStrip`, `Slider`, `Switch`, `SectionLabel`, `Button`,
`IconButton`, `PageCounter`, `ProgressLine`, `ErrorLine`.

**Do not.** No live preview anywhere - the picture is the page as it stands, and the result is
seen after Apply. No paper size picker, no resolution picker, no reordering of the recipe steps.
No anticlockwise turn button.

**Done when.** `npx storybook build` passes and all nine states are there.

**Blocked by.** 8 - the adjust screen is reached from the pages screen and reuses its page tile.

---

## 10. Storybook: flow 7, done, sharing, deleting the photos

**Read.** `/Users/julianhahn/free-pdf/design/flows/FreePDF Flow 7 Done.dc.html`, S34 to S38.
Behaviour: `user-flows.md` sections 9, 10, 11.

**Build.** Stories in `/Users/julianhahn/free-pdf/storybook/stories/Flow7Done.stories.jsx`: the
name field empty, focused and typed in with the keyboard up and both buttons still visible
(S34); the photos-already-deleted screen, block removed and the page picture larger (S35); the
reader sheet (S36); the line under Share (S37); the destructive block and its confirmation
dialog (S38).

**Components.** `PageImage`, `TextField`, `Button`, `SectionLabel`, `Sheet`, `ConfirmDialog`.

**Do not.** Do not put a share button, a print button or a page count inside the reader sheet.
Do not store the typed name anywhere - reopening shows an empty field.

**Done when.** `npx storybook build` passes and all five states are there.

**Blocked by.** 5.

---

## 11. Storybook: flows 8 and 9, one more page and coming back

**Read.** `/Users/julianhahn/free-pdf/design/flows/FreePDF Flow 8-9.dc.html`, S39 and the F9
table. Behaviour: `user-flows.md` sections 6 and 12.

**Build.** One story: the camera at "Page 41" after "Shoot another page", with the calm note
inside the `Viewfinder` saying the PDF was removed, and the footer reading "Scan 1 page". Then
walk the F9 table against the stories built in tasks 5 to 10 and report any landing state that
has no story yet. Flow 9 adds no new screens.

**Do not.** Do not use an `ErrorLine` for the removed-PDF note. Nothing failed.

**Done when.** `npx storybook build` passes, the story is there, and the F9 walk is reported.

**Blocked by.** 6 and 8.

---

## 12. Julian looks at the screens and approves them

No code. Build the Storybook, tell Julian it is ready, and wait. Nothing in iOS starts before
this is ticked off.

**Blocked by.** 5 to 11.

---

## 13. Widen the C boundary for the adjusted case

**Why.** Swift can call two functions today, `freepdf_scan_page` and `freepdf_pages_to_pdf`
(`/Users/julianhahn/free-pdf/ffi/include/freepdf.h`). `crop` and `rotate` are not exported at
all and `Levels` never crosses. Without this, Adjust cannot be built.

**Read.** `/Users/julianhahn/free-pdf/ffi/AGENTS.md`,
`/Users/julianhahn/free-pdf/core_engine/AGENTS.md`, and `user-flows.md` section 7a - the tool
table says exactly which values a user can move.

**Build.** **One** new C function. It takes the photo path, the page path, and one struct
holding all the values - the four paper corners, deskew on or off, the straightening angle, the
black and white points and whether levels apply, the sharpen radius, the crop box, the number of
quarter turns, and grey on or off. It replaces `freepdf_scan_page` when the user has adjusted
something. Same error contract as the two existing functions: `0` is ok, anything else fills
`error` with a finished English sentence.

**Do not.** Do not export seven functions, one per tool. Julian decided this on 2026-08-12,
`user-flows.md` DECISIONS point 12. Do not export `images_to_pdf` - it peaks near 3.1 GB and iOS
kills the app. Do not make the page size or the 3000 px cap settable.

**Done when.** `cargo test --workspace` passes, `bash /Users/julianhahn/free-pdf/ffi/bridge_check.sh`
says "bridge ok", and the new function has a test that adjusts a page from
`/Users/julianhahn/free-pdf/test_images/` with non-default values and gets a different page out
than `scan_page` does.

**Blocked by.** Nothing. Can be done at any time, in parallel with the Storybook tasks.

---

## 14 to 19. Rebuild the iPhone app, one screen at a time

All six share this. **Read first:** `/Users/julianhahn/free-pdf/ios/AGENTS.md` in full - the
storage model, the derived step, the sweep, the camera rules and the two checks. Then
`user-flows.md`. Then the flow document for the screen you are building, and the approved
Storybook story for it. Today's app is seven files in
`/Users/julianhahn/free-pdf/ios/FreePDF/`: `FreePDFApp.swift`, `Scan.swift`, `ScanList.swift`,
`ScanFlow.swift`, `CameraView.swift`, `Engine.swift`, `FakeShoot.swift`.

**What never changes, whatever the screen.** The files are the only state and the step is read
off them every time. No manifest. Every file earns its name by rename after a complete write.
No network call of any kind. Every failure sentence comes from the engine and is printed
unchanged. All text is English in the code with German checked by hand against the copy tables.

**The fast loop while writing a screen** - about a third of a second, no Xcode, no simulator:

```sh
cd /Users/julianhahn/free-pdf && swiftc -typecheck -parse-as-library -swift-version 6 \
  -warnings-as-errors -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
  -target arm64-apple-ios18.0-simulator \
  -import-objc-header ffi/include/freepdf.h ios/FreePDF/*.swift
```

**Blocked by.** 12, all of them.

### 14. The scans list

`ScanList.swift`. The seven subtitles, the pressed row, the error line above the list, newest
first, swipe to delete with a confirmation dialog before anything goes. Design: flows 1-2
document. **Check:** `bash /Users/julianhahn/free-pdf/ios/check/run.sh` says "resume ok", and by
hand: make three scans, swipe one, cancel, swipe again, delete, and see the folder gone.

### 15. The camera

`CameraView.swift`. The disabled shutter while the photo is written, the counter naming the next
page, the one error sentence with its four reasons, the permission takeover, the three
cannot-work sentences, the stand-in note. Design: flow 3 document. **Check:** `bash
/Users/julianhahn/free-pdf/ios/check/scan_check.sh` says "scan ok", and by hand on a phone:
shoot five pages, force-quit while aiming at six, relaunch, the counter says "Page 6".

### 16. The scan runs

The drain in `ScanFlow.swift`. The progress line counting photos done, the note "You can close
the app.", a refused page showing the engine's sentence while the bar carries on, and the move
to the pages when there is nothing left it can do. Design: flow 4 document. **Check:**
`scan_check.sh` says "scan ok" - that check is exactly this: twelve pages, killed after three,
carries on at four.

### 17. The pages

`ScanFlow.swift` plus a new pages view. The carousel with pinch to zoom, the rail with the jump,
the Grey switch for the whole scan, the Page menu at three items and at four, the delete
confirmation, Retry on a refused page, Make PDF hidden until every photo has a page, and the
failure line. Design: flow 5 document. **Check:** `scan_check.sh` says "scan ok", and by hand:
a 12 page scan, jump to page 11, delete page 3, see the numbers keep their gap, then Make PDF.

### 18. Adjust

A new adjust view, reached from the Page menu only. The six tools, suggest-then-apply on every
control, no live preview, Apply one page, Apply to all pages with the takeover and "Keep the app
open.", the skipped pages sentence afterwards, and the existing `scan.pdf` deleted whenever a
page is rewritten. Design: flow 6 document; behaviour `user-flows.md` sections 7, 7a and 7b.
**Blocked by.** 13 as well as 17 - this is the screen the new C function exists for. **Check:**
`scan_check.sh` still says "scan ok", and by hand: straighten one page and see it change; turn
"Apply to all pages" on over a three page scan and see all three change; adjust a page whose
photo was deleted and see it refused with a sentence.

### 19. Done, sharing, deleting the photos

The done screen. The name field used only for the copy that leaves, Open PDF in a reader sheet
inside the app, Share PDF through the system share sheet, Change pages deleting `scan.pdf`, the
destructive photos block with its confirmation, and the whole block gone once the photos are.
Design: flow 7 document. **Check:** `scan_check.sh` says "scan ok" and ends in a PDF that ends
in `%%EOF`, and by hand: type a name, share into Files, see the file carry that name; delete the
photos, see the block gone and Change pages still working.

---

## Open questions - the delivered documents against `user-flows.md`

Four places where the design says something `user-flows.md` does not. Julian decides; until he
does, `user-flows.md` wins.

1. **Make PDF next to a refused page.** Flow 5, S17 says a refused page "does not block the
   PDF" and draws Make PDF in the footer. `user-flows.md` section 6 and `ios/AGENTS.md` both say
   Make PDF is hidden until every photo has a page - and a refused page has no page file. As
   written, S17's footer cannot exist.
2. **A page picture on the done screen.** Flow 7, S34 and S35 draw the PDF's first page at the
   top. `user-flows.md` section 9 has no picture there, and nothing in the engine renders a PDF
   page back to an image today.
3. **The title on the scan-runs screen.** Flow 4, S13 puts the scan's date in the app bar.
   `user-flows.md` section 5 shows only a back arrow reading "Scans".
4. **Words that do not exist yet.** Seven sentences are placeholders written by the designer -
   they are gathered in task 4 and must not be shipped as they stand.

## The delivered design system copy

`/Users/julianhahn/free-pdf/design/flows/_ds/freepdf-design-system-43ff3180-.../` is
**byte-identical** to `/Users/julianhahn/free-pdf/design/system/` - tokens, `readme.md`,
`styles.css` and the manifest all match. There is nothing to merge. Task 1 and task 2 change the
repo's copy; the delivered copy can then be deleted.
