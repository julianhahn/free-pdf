# TASKS.md - building the delivered design

The design round is finished. This is the list of what has to be built, in the order it has
to be built.

**How to use this file.** Take the top task that is not blocked. Hand the whole task over to
one agent - a task is written so that an agent who has read nothing else can do it. When the
task's check passes, tick it off here in the same commit as the work. Do not start a task
whose "Blocked by" line is not ticked off.

Every path below is absolute. The delivered design lives in
`/Users/julianhahn/free-pdf/design/flows/`. The pictures in
`/Users/julianhahn/free-pdf/design/flows/shots/` are the same screens as PNGs; the components
themselves are drawn by Storybook.

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
| 4 | Collect the missing words, get them from Julian — DONE | - | Julian answers |
| 5 | Storybook: flows 1-2, the scans list — DONE | 1, 2, 3 | npx storybook build |
| 6 | Storybook: flow 3, the camera — DONE | 5 | npx storybook build |
| 7 | Storybook: flow 4, the scan runs — DONE | 5 | npx storybook build |
| 8 | Storybook: flow 5, the pages — DONE | 5 | npx storybook build |
| 9 | Storybook: flow 6, adjust — DONE | 8 | npx storybook build |
| 10 | Storybook: flow 7, done — DONE | 5 | npx storybook build |
| 11 | Storybook: flows 8-9, one more page — DONE | 6, 8 | npx storybook build |
| 12 | Julian approves the screens — DONE | 5-11 | Julian says yes |
| 13 | Widen the C boundary for the adjusted case — DONE | - | cargo test --workspace, bash ffi/bridge_check.sh |
| 14 | iOS: the scans list — DONE | 12 | bash ios/check/run.sh, by hand |
| 15 | iOS: the camera — DONE | 14 | bash ios/check/scan_check.sh |
| 16 | iOS: the scan runs — DONE | 14 | bash ios/check/scan_check.sh |
| 17 | iOS: the pages — DONE | 16 | bash ios/check/scan_check.sh, by hand |
| 18 | iOS: adjust — DONE | 13, 17 | bash ios/check/scan_check.sh, by hand |
| 19 | iOS: done, share, delete the photos — DONE | 17 | bash ios/check/scan_check.sh, by hand |
| 20 | iOS: the page state file — DONE | 18 | bash ios/check/run.sh |
| 21 | iOS: Adjust opens on the state and writes it — DONE | 20 | bash ios/check/scan_check.sh |
| 22 | iOS: the turn and the crop come out of the state — DONE | 21 | bash ios/check/scan_check.sh |
| 23 | iOS: Grey becomes a fact about the pages — DONE | 21 | bash ios/check/scan_check.sh |
| 24 | iOS: Adjust is visible in the overview — DONE | 19 | bash ios/check/scan_check.sh, by hand |
| 25 | iOS: a magnifier for the corner drags — DONE | 22 | bash ios/check/scan_check.sh, by hand |
| 26 | iOS: every tool shows what it would do — DONE | 22 | bash ios/check/scan_check.sh, by hand |
| 27 | iOS: the jump appears from ten pages — DONE | 17 | bash ios/check/scan_check.sh, by hand |
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

- **3.1 The scans list** - seven subtitles, not three; a pressed row state; an `ErrorLine`
  slot above the list; rows newest first.
- **3.2 The camera** - the shutter can be `disabled`; the counter at 1, 7 and 40 and the
  before-the-first-shot state; an `ErrorLine` over the viewfinder; the simulator note on
  `Viewfinder`; the shutter names the page.
- **3.3 The pages** - the inline rail becomes `PageStrip`; the refused page gets "Scan this
  page again"; the menu is three items while checking and four on a finished scan; "Make PDF"
  is hidden, not disabled; the counter reads "Page 3 of 12" in both places.
- **3.4 Adjust** - the inline tool row becomes `ToolStrip`; corner dragging becomes
  `PageHandles`; "Back to the suggestion" on every tool that has one; the Edges note line has
  three states; Sharpen can sit at 0.
- **3.5 Done** - `TextField` focused and typed in; the two buttons stay clear of the
  keyboard; the photos-already-deleted state removes the block, not greys it; "Open PDF" opens
  the `Sheet`; the footnote belongs to the block, not the button.

**Blocked by.** 1 and 2 - these screens use the new disabled role and three of the four new
components.

**Done when.** `npx storybook build` passes and the flow stories in
`/Users/julianhahn/free-pdf/storybook/stories/` show every point of the F6 list.

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

**Answered on 2026-08-14.** Julian read the sixteen sentences, said they were good, and asked
for the wording to be drafted rather than written by him - so they are drafted here and in the
copy tables of `user-flows.md`, where the app reads its words from. They are his to change; the
draft is not a decision. Three of the collected lines needed no word at all:

- the Make PDF failure and the storage error above the scans list are the engine's and the
  system's own sentences, printed unchanged. The slot stays empty on purpose.
- the name field's `.pdf` suffix is a design addition, not a missing word. It is gone.

Two are a decision, not a translation, and are still open: `Chrome.jsx` labels the back control
"Back" where `ios/AGENTS.md` says it reads "Scans"; and the camera pairs "Page 7" with
"Scan 7 pages" while both tables pair it with "Scan 8 pages" - sections 4.1 and 4.4 make the
table's pairing impossible, so the kit follows the rules.

**Done when.** Julian has answered every line and `user-flows.md` carries the answers.

---

## 5. Storybook: flows 1 and 2, the scans list

**Read.** `/Users/julianhahn/free-pdf/design/flows/FreePDF Flows 1-2 Scans.dc.html`, screens S1,
S2, S4, S5. Pictures: the `01-*`, `02-*` and `03-*` files in
`/Users/julianhahn/free-pdf/design/flows/shots/`. Behaviour: `user-flows.md` sections 1, 2, 3.

**Build.** Four stories in a new
`/Users/julianhahn/free-pdf/storybook/stories/Flow1Scans.stories.jsx`, each rendered in the
phone frame the flow stories use: the empty list, the empty list with an
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

**The tokens.** No colour, size, spacing step or radius is written into a screen, and no
SwiftUI default stands in for one - not `.red`, not `.footnote`, not `.secondary`, not a bare
`spacing:` number. They come from `Token` in `/Users/julianhahn/free-pdf/ios/FreePDF/Tokens.swift`,
which is **generated** out of `/Users/julianhahn/free-pdf/design/system/tokens/*.css` by
`node design/system/tokens/build-tokens.mjs`. Never edit `Tokens.swift`; change the CSS and run
the generator. A missing token is a token to add to the CSS, not a number to type.

`ScanList.swift` was moved over in task 14. The four older screens - `ScanFlow.swift`,
`CameraView.swift`, `FakeShoot.swift`, `FreePDFApp.swift` - still carry system defaults.
**Julian's decision: each of tasks 15 to 19 moves the screen it touches over as it goes**, so
there is no separate cleanup task and no screen is rewritten twice.

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

## 20 to 23. The page keeps what the user asked for

Julian decided on 2026-08-15: every page carries a state. It is set from the engine's
suggestion the first time and kept after that, so a value can be nudged instead of set again
from the photo. It lives in one small text file per page, `state/NNNN.txt`, written by Swift
and read by Swift.

**Why a file and not the pixels.** The same 24 numbers spliced into the page JPEG would cost a
new C function, a changed `save_page`, a header change and a marker splicer, and the engine
would have to know a format it does not need. Re-deriving them instead does not work:
`freepdf_suggest_adjustments` always answers with the drain's sharpen radius, so every reopen
would sharpen the page again.

**Why this is not the manifest that was rejected.** `state/NNNN.txt` is never an input to
`Scan.state`, `photos`, `pages`, `unscanned` or `nextPage` - the step is still read off the two
directories every time. It holds what the user asked for, never where the work got to. The page
is renamed first and the state second, so a kill in between costs one nudge and never a wrong
page.

**Blocked by.** 18, all of them.

## 20. The page state file

**Why.** Every value the user sets on Adjust dies with the view - `AdjustView` holds all of it in `@State` and re-seeds from `Engine.suggest` on each open, so a crop, a turn and a shifted level evaporate at the next Apply. One file per page holds what he last asked for. It is never an input to `Scan.state`, `photos`, `pages`, `unscanned` or `nextPage` - the step is still read off the files every time, which is what the manifest failed at (`/Users/julianhahn/free-pdf/ios/AGENTS.md`, "The manifest that isn't").

**Read.** `/Users/julianhahn/free-pdf/ios/AGENTS.md` in full. `/Users/julianhahn/free-pdf/ios/FreePDF/Scan.swift` - `numbers(in:)`, `pageNumber`, `sweep()`, `state`. `/Users/julianhahn/free-pdf/ios/FreePDF/Engine.swift` - `Engine.Adjustments`. `/Users/julianhahn/free-pdf/ios/check/main.swift`.

**Build.** In `/Users/julianhahn/free-pdf/ios/FreePDF/Scan.swift`:

- `stateDirectory` = `<scan>/state`, `stateURL(_ number: Int)` = `state/NNNN.txt`.
- `writeState(_ number: Int, _ values: Engine.Adjustments)`: one ASCII line, newline-terminated, `1` then 24 space-separated numbers in this order - `c0x c0y c1x c1y c2x c2y c3x c3y flat angle bR bG bB wR wG wB tones sharpen cx cy cw ch turns grey`. Corners are the photo's own pixels, four decimals for them and for the crop, one for the angle and the sharpen, integers for the rest. Written to `state/NNNN.part` and renamed - the same earn-your-name rule the engine uses in `core_engine/src/pdf.rs`.
- `readState(_ number: Int) -> Engine.Adjustments?`: `nil` unless the first token is `1` and exactly 24 further tokens all parse. No error sentence - absent state is a normal case, not a failure.
- `deleteState(_ number: Int)`.
- `sweep()`: add `"state"` to the root allow-list (today `["photo","page","scan.pdf"]`), create `state/` if missing, and delete every entry inside it that is not `NNNN.txt`, plus any `NNNN.txt` with neither a photo nor a page.
- In `/Users/julianhahn/free-pdf/ios/FreePDF/ScanFlow.swift`, `drain()`: call `scan.deleteState(number)` right after `Engine.scanPage` returns, before the list refresh. This is the retake rule - a page the engine just built from a photo carries the engine's own recipe, and any older sidecar described a photo that is gone.
- In `deletePage`, delete the sidecar with the page.

Nothing new is added to `Engine.Adjustments`; corners stay the photo's own pixels, as `AdjustView` hands them over today.

**Docs.** `/Users/julianhahn/free-pdf/ios/AGENTS.md`: a new paragraph under the storage model saying `state/NNNN.txt` holds what the user last asked for, never where the work got to, and that it is deleted by the drain, by `deletePage` and by `sweep()`. The sentence in "The manifest that isn't" stays true and must be left standing - say in one line why this file is not that file. `/Users/julianhahn/free-pdf/core_engine/AGENTS.md`: unchanged, no engine code moves.

**Check.** `bash /Users/julianhahn/free-pdf/ios/check/run.sh` says "resume ok", with new cases: a full value set round-trips; a truncated line, a garbage line and an empty file each read back `nil`; `sweep()` keeps `state/0007.txt`, deletes `state/0007.part` and `state/foo`, keeps the `state` directory itself, and removes a sidecar with neither photo nor page; `state` and `subtitle` are unchanged by all of it.

## 21. Adjust opens on the state and writes it

**Why.** Task 20 makes the file; nothing reads it yet. This is the task that makes "the state is simply always there" true: the engine's suggestion seeds a page the first time, and after that the screen opens on what the user last asked for.

**Read.** `/Users/julianhahn/free-pdf/ios/FreePDF/AdjustView.swift` in full - `.task`, `seed(_:)`, the Apply path. `/Users/julianhahn/free-pdf/ios/FreePDF/ScanFlow.swift` - `write(_:_:on:)` and `apply(_:_:allPages:)`. `/Users/julianhahn/free-pdf/ios/FreePDF/Scan.swift` after task 20.

**Build.**

- `.task` still calls `Engine.suggest` on the photo - its two notes ("runs off the frame", "fills the whole photo") are about the photo and are wanted on every open.
- `seed(_:)` becomes one branch: if `scan.readState(number)` returns values, every control opens on them; otherwise on the suggestion. Delete the unconditional `box = wholePicture` line and the unconditional `quarterTurns = 0`.
- `ScanFlow.write(_:_:on:)`: after `Engine.adjustPage` returns and the page has been renamed into place, call `scan.writeState(number, values)`. The order is fixed and is the whole safety argument: page first, sidecar second. On an all-pages run each page writes its own sidecar after its own rename, with that page's own re-asked corners when `own == false`.

**The kill story, to be written into the report.** Killed before the page's rename: old page, old-or-no sidecar, nothing happened. Killed after the page's rename and before the sidecar's: the new page with the previous instruction - the user redoes one nudge, nothing is corrupt, no screen lies about done or not-done, and `Scan.state` never read this file. Killed during the sidecar write: a `.part` that `sweep()` takes. The reverse skew - a sidecar ahead of its page - is impossible by the write order.

**Docs.** `/Users/julianhahn/free-pdf/user-flows.md` section 7: the sentence that every tool re-seeds from the engine on each open becomes false - replace it with "the engine seeds a page once, and after that the tools open on what was last applied". `/Users/julianhahn/free-pdf/ios/AGENTS.md`: same correction next to the Adjust notes.

**Check.** `bash /Users/julianhahn/free-pdf/ios/check/scan_check.sh` says "scan ok", and by hand: straighten page 1 to -3.2°, Apply, reopen Adjust, the angle reads -3.2°; force-quit and relaunch, it still reads -3.2°.

## 22. The turn and the crop come out of the state

**Why.** The EXIF turn patch (`ScanFlow.turn`, `turned.write(to: photo)`) rewrites a photo in place, which breaks the append-only rule the rest of the app keeps, and it exists only because nothing remembered the turn. The sidecar remembers it. The crop is the worst-lost value: the box resets to the whole picture on every open, so a crop silently disappears at the next Apply.

**The uncommitted work, decided.** The EXIF turn patch is **reverted** - `import ImageIO`, `Self.turn(photo:by:)`, the whole EXIF branch and the `own = false` re-ask it forced go away, and the photo goes back to being the camera's untouched bytes. The **crop-as-fractions change is kept unchanged** - fractions are what makes the crop storable at all, and nothing here makes it wrong.

**Read.** `/Users/julianhahn/free-pdf/ffi/src/lib.rs:318-360` - the recipe order: corners, straighten, the 3000 px cap, the turn, then the crop. `/Users/julianhahn/free-pdf/ios/AGENTS.md` lines about "Edges shows the photo, every other tool the page" and "The turn goes on the photo, not on the page".

**Build.**

- Delete the turn patch as above. `quarterTurns` travels in `Engine.Adjustments` and in the sidecar; the engine turns the image, as it did before the patch.
- The crop keeps its canvas: **the page, not the photo.** The crop the engine cuts is a fraction of an image that exists only mid-recipe - after corners, straighten, the cap and the turn - which is neither the photo nor the page, so moving the handles onto the photo trades one mismatch for a worse one on every turned page. Instead the box opens at the whole picture, which is honest (the page on screen is already the last cut, so there is no *further* cut yet), and Apply **composes** the new drag onto the stored crop: `x = oldX + newX * oldW`, `w = oldW * newW`, same for y and h. Four lines.
- If the turn changes while a crop is stored, rotate the stored box with it before composing - one quarter turn clockwise maps `(x,y,w,h)` to `(1-y-h, x, h, w)`. Four more lines, applied once per quarter turn of difference.

**Cut on purpose:** composition means the user can only ever cut tighter, never widen. Ceiling: widening needs "Scan this page again", which is already the undo for everything else on this screen.

**Docs.** `/Users/julianhahn/free-pdf/ios/AGENTS.md`: the whole paragraph beginning "**The turn goes on the photo, not on the page.**" becomes false and is deleted - replace with one sentence saying the turn is stored in the page's state file and applied by the engine at every Apply. The "**An all-pages run does not send this page's pixels to the others.**" paragraph stays, minus the re-ask-because-the-photo-changed clause. `/Users/julianhahn/free-pdf/core_engine/AGENTS.md`: "Every step has its own space" stays exactly as written - it is the reason the crop composes rather than moves canvas; add one sentence saying so.

**Check.** `bash /Users/julianhahn/free-pdf/ios/check/scan_check.sh` says "scan ok", and by hand: crop page 1 to its middle, Apply, reopen Adjust, tap Turn once, Apply - the page is still the middle third and now turned; force-quit, relaunch, Adjust again, Apply with nothing changed - the page does not move.

## 23. Grey becomes a fact about the pages

**Why.** `@State private var grey` on `PagesView` greys what is on screen, not what is written - its own comment says so. Leave the scan and come back and the colour is back, while pages adjusted in between are genuinely grey on disk. One truth, in the files.

**Read.** `/Users/julianhahn/free-pdf/ios/FreePDF/PagesView.swift` - the switch, `.grayscale(grey ? 1 : 0)`, the comment block. `/Users/julianhahn/free-pdf/ios/FreePDF/ScanFlow.swift` - `apply(_:_:allPages:)` and its takeover. `/Users/julianhahn/free-pdf/user-flows.md` section 7a.

**Build.**

- Delete `@State private var grey`, `.grayscale(grey ? 1 : 0)`, the comment block, and `ScanFlow.adjustGrey`.
- The switch reads the lowest-numbered sidecar that has a `grey` token and shows that. Flipping it runs the existing all-pages Apply with each page's own stored values and `grey` flipped - the same takeover, the same "Keep the app open.", the same skipped-pages sentence. No new words.
- A page with no sidecar gets the engine's suggestion plus the flipped `grey`, exactly as Adjust would.

**Cut on purpose:** the switch shows page one's answer, so a scan whose pages disagree about grey shows one of them. Ceiling: add a reconciliation when someone reports it.

**Docs.** `/Users/julianhahn/free-pdf/ios/AGENTS.md`: "**Grey greys the screen, not the file.**" becomes false - rewrite as one switch that rewrites every page. `/Users/julianhahn/free-pdf/user-flows.md` 7a: the words "Off today, unreachable in the app at all" become false and go.

**Check.** `bash /Users/julianhahn/free-pdf/ios/check/scan_check.sh` says "scan ok", and by hand: a three page scan, flip Grey, watch the takeover, leave the scan, come back - all three are still grey.

## 24 to 27. What the phone showed - Julian, 2026-08-16

Four things Julian found the first time the finished app ran on a real phone. All four are his
decisions, not a designer's; where one of them contradicts a rule written earlier in this file
or in `/Users/julianhahn/free-pdf/ios/AGENTS.md`, his decision wins and the old rule is deleted,
not argued with. Tasks 24 and 27 are the pages overview, tasks 25 and 26 the adjust screen -
the two pairs touch different files and can run at the same time.

## 24. Adjust is visible in the overview

**Why.** Julian could not find Adjust on the phone. It is one item inside the "…" page menu in
`/Users/julianhahn/free-pdf/ios/FreePDF/PagesView.swift` (`menu`), behind a glyph, next to
Retake, Shoot another and Delete. The screen the whole of tasks 13, 18, 21, 22 and 25-26 exists
for is the hardest one to reach in the app.

**Read.** `/Users/julianhahn/free-pdf/ios/FreePDF/PagesView.swift` - `menu`, `pageActions` and
whatever the flow 5 document draws under the carousel. The flow 5 document in
`/Users/julianhahn/free-pdf/design/flows/`, and the approved Storybook story for it.

**Build.** Adjust gets a control of its own on the pages overview, visible without opening a
menu, in the same place for every page, and disabled - not hidden - where the photo is gone, so
it never moves. It keeps its existing words ("Adjust page") and its existing hint, and it stays
in the menu as well only if that costs nothing. No new colour, size or spacing: the disabled
look is the `--disabled-*` colour role from task 1, not an opacity.

**Do not.** Do not invent a word, a glyph meaning or a second entry point into Adjust from
anywhere but the pages overview - Adjust is still reached from the pages, never from Done or
from the camera.

**Check.** `bash /Users/julianhahn/free-pdf/ios/check/scan_check.sh` says "scan ok", and by
hand: a three page scan, Adjust reachable in one tap from the page on screen, and on a page
whose photo was deleted the control is there and refuses.

## 25. A magnifier for the corner drags

**Why.** A corner handle is under the fingertip that drags it, so the user cannot see the thing
he is aiming at. Julian's decision: the drag does not just move the corner, it shows a
magnifier beside the finger - about a fingertip across - with a crosshair in it, and the
crosshair is what is aimed with. The corner goes where the crosshair is, not where the finger
is.

**Read.** `/Users/julianhahn/free-pdf/ios/FreePDF/AdjustView.swift` - `handles(_:colour:)`, the
four corner names, `sheet`, `box`, and the header comment. `/Users/julianhahn/free-pdf/ffi/src/lib.rs:318-360`
- the recipe order: corners, straighten, the 3000 px cap, the turn, then the crop.
`/Users/julianhahn/free-pdf/design/system/components/document/PageHandles.jsx` - the delivered
component, including its refused state. `/Users/julianhahn/free-pdf/user-flows.md` section 7.

**Build.**

- While a handle is dragged, a round magnifier follows the finger, offset so the finger never
  covers it, showing the picture under the crosshair at a magnification that makes a corner
  aimable. Its size, radius and colours come from `Token`; a missing token is a token to add to
  `/Users/julianhahn/free-pdf/design/system/tokens/*.css` and regenerate with
  `node design/system/tokens/build-tokens.mjs`, never a number typed into the screen.
- It appears for both handle sets - Edges on the photo and Crop on the page - and never when
  the handles are refused.
- Setting the corners re-runs everything to the right of that step in the recipe. Edges is the
  first step, so a new corner means straighten, the cap, the turn and the crop are all applied
  again on top of it, and the preview from task 26 shows that, not the old picture with new
  dots. The stored crop composes as task 22 says; nothing about composition changes here.
  The angle and the two tone points are also re-*measured* against the new corners,
  replacing whatever is showing.
- VoiceOver is unchanged: the four corner names stay, and the magnifier is decoration a screen
  reader never announces.

**Check.** `bash /Users/julianhahn/free-pdf/ios/check/scan_check.sh` says "scan ok", and by
hand: drag a sheet corner on Edges - the magnifier shows beside the finger and the corner lands
under the crosshair; a page whose photo is gone still refuses with its sentence and shows no
magnifier.

## 26. Every tool shows what it would do

**Why.** Today the adjust screen has no live preview at all - the header comment in
`AdjustView.swift` says so and `/Users/julianhahn/free-pdf/ios/AGENTS.md` states it as a rule.
Julian's decision on 2026-08-16 reverses it: a value that is changed and only visible after
Apply is a value the user sets blind. Change-then-Apply stays - Apply is still what leaves the
tool and writes the page - but every debounced value change shows what the new state would look
like.

**Read.** `/Users/julianhahn/free-pdf/ios/FreePDF/AdjustView.swift` in full - `values`,
`suggestion`, `seed(_:)`, the controls, Apply. `/Users/julianhahn/free-pdf/ios/FreePDF/ScanFlow.swift`
- `apply(_:_:allPages:)` and `write(_:_:on:)`, which is how a page is really written.
`/Users/julianhahn/free-pdf/ios/AGENTS.md` - the paragraphs about the drain, about the app never
holding what it has not written, and the "no live preview" rule, which is now false.

**Build.**

- On every value change, debounced, the picture on screen becomes the page the current values
  would produce. The engine does the work - the preview is a real run of the recipe, not an
  approximation drawn in SwiftUI, so what is shown is what Apply writes.
- The preview never writes the real page and never touches `state/NNNN.txt`. It goes to a
  scratch file that is not `photo/`, `page/`, `state/` or `scan.pdf`, and `sweep()` must still
  be true afterwards - if that means the scratch lives outside the scan folder, it lives
  outside the scan folder.
- One run at a time, and a change while a run is going supersedes it. A preview that fails
  shows the engine's sentence unchanged, exactly as Apply does, and leaves the last good
  picture up.
- Edges keeps showing the photo and every other tool the page, as today.

**Do not.** Do not remove Apply, do not apply on change, and do not preview across all pages -
"Apply to all pages" stays a takeover that happens on Apply only.

**Docs.** `/Users/julianhahn/free-pdf/ios/AGENTS.md`: the "no live preview" rule becomes false
and is deleted, replaced by one sentence saying the preview is a real engine run into a scratch
file and that only Apply writes a page. The header comment in `AdjustView.swift` goes the same
way. `/Users/julianhahn/free-pdf/user-flows.md` section 7: the sentence that promises no preview
goes.

**Check.** `bash /Users/julianhahn/free-pdf/ios/check/scan_check.sh` says "scan ok" and
`bash /Users/julianhahn/free-pdf/ios/check/run.sh` says "resume ok" - `sweep()` unchanged by the
scratch file. By hand: drag the straighten control and see the page turn a moment later without
Apply; Cancel and see the page on the pages overview unchanged; kill the app mid-preview and
find nothing new in the scan folder.

## 27. The jump appears from ten pages

**Why.** "Go to page" shows on a one page scan, where there is nowhere to go. Julian's
decision: the rail's jump appears from ten pages up.

**Read.** `/Users/julianhahn/free-pdf/ios/FreePDF/PagesView.swift` - `rail`, `jump`, `jumping`,
`jumpTo` and the go. `/Users/julianhahn/free-pdf/design/system/components/document/PageStrip.jsx`,
which is the delivered component the rail is built from, and its story.

**Build.** The "Go to page" button and its field are shown only when the scan has ten pages or
more. Below that the rail is the rail and nothing else. Closing behaviour, the field, the go and
what happens to a typed number that does not exist are all unchanged. The threshold is one
named constant with a one-line comment saying it is Julian's number, not a measured one.

**Do not.** Do not hide the rail itself, do not change the tile size, and do not invent a
different way to reach page 40.

**Docs.** If `/Users/julianhahn/free-pdf/user-flows.md` or the flow 5 document says the jump is
always there, that sentence is now false - correct it in one line.

**Check.** `bash /Users/julianhahn/free-pdf/ios/check/scan_check.sh` says "scan ok", and by
hand: a three page scan shows no jump, a twelve page scan does and page 11 is still reachable
by it.

---

## What is deleted by this plan

- `/Users/julianhahn/free-pdf/ios/FreePDF/ScanFlow.swift`: `import ImageIO`, `Self.turn(photo:by:)` and the whole EXIF branch, the `own = false` re-ask it forced, `adjustGrey`. About 75 lines.
- `/Users/julianhahn/free-pdf/ios/FreePDF/PagesView.swift`: `@State private var grey`, `.grayscale(grey ? 1 : 0)`, the four-line comment, the `onAdjust(showing, grey)` argument. About 20 lines.
- `/Users/julianhahn/free-pdf/ios/FreePDF/AdjustView.swift`: the unconditional `box = wholePicture` and `quarterTurns = 0` in `seed(_:)` and the comment that explained them. About 10 lines.
- `/Users/julianhahn/free-pdf/ios/AGENTS.md`: the "turn goes on the photo" paragraph, the "Grey greys the screen" paragraph.
- `/Users/julianhahn/free-pdf/user-flows.md`: 7a's "Off today, unreachable in the app at all", and 7's re-seed-every-open sentence.

`ffi/`, `core_engine/`, `freepdf.h`, `ffi/bridge_check.sh` and `ios/check/scan_check.sh`'s existing cases are untouched, and they must stay green unchanged - that is the proof no boundary moved.

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

**Decided on 2026-08-14, not open any more.**

5. **The page number on the camera screen.** It is the app bar title and nothing else. The
   counter over the viewfinder is gone from flow 3 and flow 8. Built that way already.
6. **"New scan" on the scans list.** The delivered `ScansScreen.jsx` puts it in a footer, the
   flows put it in the app bar. The stories follow the app bar. Julian judged this too small
   to chase, so the old kit screen stays as it is - decided not to chase, not open.

## The delivered design system copy

`/Users/julianhahn/free-pdf/design/flows/_ds/freepdf-design-system-43ff3180-.../` is
**byte-identical** to `/Users/julianhahn/free-pdf/design/system/` - tokens, `readme.md`,
`styles.css` and the manifest all match. There is nothing to merge. Task 1 and task 2 change the
repo's copy; the delivered copy can then be deleted.
