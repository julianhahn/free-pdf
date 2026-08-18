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
| 28 | iOS: the typed name is the scan's name — DONE | 19 | bash ios/check/run.sh, bash ios/check/scan_check.sh, by hand |
| 29 | The sheet is found by its edges, not by its brightness — DONE | - | cargo test --workspace, bash ffi/bridge_check.sh, by eye on real photos |
| 30 | iOS: Pull the sheet flat starts on — DONE | 29 | bash ios/check/scan_check.sh, by hand |
| 31 | A sheet that leaves the frame is cut anyway, and the page says so — DONE | - | cargo test --workspace, bash ios/check/scan_check.sh, by eye on real photos |
| 32 | iOS: Adjust and Shoot another page are controls, not menu items — DONE | - | bash ios/check/scan_check.sh, by hand |
| 33 | iOS: shooting another page does not stop after one — DONE | - | bash ios/check/scan_check.sh, by hand |
| 34 | iOS: after the first page, the app shows what it is about to do — DONE | - | bash ios/check/run.sh, bash ios/check/scan_check.sh, by hand |
| 35 | iOS: the viewfinder shows the last page photographed — DONE | 34 | bash ios/check/scan_check.sh, by hand |
| 36 | The bottom edge still overshoots, and cropping in is allowed — DONE | - | cargo run --example edge_error, cargo test --workspace, by eye on a phone |
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

**Do not.** Do not add a flash control, a landscape frame or a photo-library import. All three
are decided against in `user-flows.md` DECISIONS.

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
it never moves. It keeps its existing words ("Adjust page") and its existing hint. No new colour, size or spacing: the disabled
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

## 28. The typed name is the scan's name - Julian, 2026-08-17

**Why.** At the end of a scan the app already asks for a name, and then throws it away. In
`/Users/julianhahn/free-pdf/ios/FreePDF/DoneView.swift` the field is a `@State` that only builds
the hard link the share sheet carries ("Nothing is stored", `nameTheCopy()`), so the name lives
until the screen closes - so coming back to Done, from the overview or from the pages, opens on
an empty field and the name he typed a minute ago is gone. Meanwhile the scans list shows the
folder's timestamp -
`/Users/julianhahn/free-pdf/ios/FreePDF/Scan.swift`, `title`. Julian's decision: a name he has
already typed is the scan's name, and the front list shows it.

**Read.** `DoneView.swift` - `name`, `nameField`, `nameTheCopy()`. `Scan.swift` - `title`, and
how the state files are read and written, because the name is stored the same way and never by
listing a directory. `ScanList.swift` - `row`.

**Build.** The typed name is written into the scan folder as its own small file, next to the
existing per-page state, and `Scan.title` reads it: a stored name is the row's title, and a scan
with none keeps the date exactly as it reads today. Writing happens as the name is typed - the
same moment the copy is renamed - so there is no Save button and nothing to lose by leaving. The
field itself opens on the stored name, so coming back to Done shows what was typed last time and
the next visit is an edit rather than a retype. Clearing the field puts the date back. The name that leaves in the share sheet and the name in
the list are the same string sanitised the same way, in one place, not two.

**Do not.** Do not rename the scan folder - its name is the date and every file in the app is
found through it. Do not add a name field anywhere but Done, do not make the list rows editable,
and do not invent a second title for the pages screen. A missing name is not an error line: it
is the date.

**Docs.** `/Users/julianhahn/free-pdf/user-flows.md` section 9 and
`/Users/julianhahn/free-pdf/ios/AGENTS.md` both say the name belongs to the shared copy only -
both sentences are now false and are corrected, not extended.

**Check.** `bash /Users/julianhahn/free-pdf/ios/check/run.sh` says "resume ok" and
`bash /Users/julianhahn/free-pdf/ios/check/scan_check.sh` says "scan ok", plus by hand: name a
scan "Rechnung", go back, the list row reads Rechnung; open it again and the field reads
Rechnung, not empty; clear the field and the row reads the date again; a kill between the typing and the back is still named.

---

## 29. The sheet is found by its edges, not by its brightness - Julian, 2026-08-17

**Why.** The automatic cut does not work on a desk with any shine on it, and it never has.
Julian scanned seven pages on a real phone and every page came out `2250x3000` - exactly 3:4,
the ratio of the uncut photo. Not one was cut to the sheet.

The cause is not the cut and not the guard. It is what
`/Users/julianhahn/free-pdf/core_engine/src/paper.rs` calls the paper. `find_paper` splits the
picture into dark and bright by Otsu, walks the dark pixels in from the border to find the
background, and takes the largest blob of what is left. On a lit desk the sheen beside the
sheet is as bright as the paper, so it joins the blob. Then two things break at once:

- `Paper::corners` (`paper.rs:78-106`) is a **global extremum along each diagonal over the
  mask**. One leaked patch near a frame corner steals that corner. Measured on the real photo:
  the corners come back `(336,253) (2695,291) (3020,4028) (253,3672)` on a `3024x4032` photo,
  and the third one is the corner of the **frame**, not of the paper.
- `Paper::runs_off_the_picture` is therefore true, so `scan_page` skips `deskew` entirely and
  the page is the whole photo. That refusal is **correct and must be left alone**: pulling a
  wrong quadrilateral flat bends the picture and loses writing, and an uncut page is complete.

**Two things were already tried and both are reverted. Do not try them again.**

1. **Loosening the border guard** into a share-per-side tolerance, so a small bleed no longer
   counted as running off. The corners were still wrong, so `deskew` ran on the frame's corner
   and **cut content out of the page** - a chopped letterhead and a cut-through text block.
   Reverted the same day.
2. **Opening the mask** (erode then dilate) before `largest_blob`, to snap thin bridges.
   Committed as `bb66350` and reverted as `1e9b254`; read both messages, they carry the
   measurements. It fixed one photo of seven and moved none of the rest, because sheet and
   sheen do not meet over a thin bridge - they are one run across 32 consecutive rows. Cutting
   that needs a radius of a twentieth of the picture width, and a real corner is gone at a
   quarter of that. It also introduced two ways to fail that the old code did not have, both
   spelt out in `1e9b254`.

The lesson that cost two rounds: **look at the mask, do not count pixels of it.** Paint it over
the photo and open the picture. Both wrong fixes came from reading numbers and inferring the
wrong shape from them.

**Read.** `/Users/julianhahn/free-pdf/core_engine/AGENTS.md` and
`/Users/julianhahn/free-pdf/core_engine/tests/AGENTS.md` first, then `paper.rs` in full - its
`ponytail:` note at the end of `find_paper` has named this task since the first commit
(`d8052d8`): "brightness only. A document on a white desk breaks it... Following the edges of
the sheet instead would fix that, and would also give the four corners a deskew needs." Then
`/Users/julianhahn/free-pdf/ffi/src/lib.rs`, `scan_page` and `suggest_adjustments`, which are
the only two callers, and `/Users/julianhahn/free-pdf/ffi/AGENTS.md`.

**Build.** Find the sheet by its edges. The shape of the answer does not change: `find_paper`
keeps its signature, returns `Option<Paper>`, and `Paper` keeps `bounds`, `contains`, `corners`,
`runs_off_the_picture` and `is_the_whole_image`, because `scan_page`, `suggest_adjustments` and
`suggest_levels` all read them and the C surface is frozen. What changes is how the four corners
are arrived at: from the sheet's four sides rather than from the extremes of a brightness blob.

Whatever the method, these have to come out true:

- **The corners are the paper's corners**, so `contains` still answers for the pixels inside
  them - `suggest_levels` measures the paper through it, and a mask that means the desk makes
  the tones of every page wrong. That failure has no guard anywhere, which is why it decided
  against the opening.
- **`runs_off_the_picture` becomes rare and honest.** Once the corners are the paper's, it says
  what its own doc claims: the sheet really does leave the frame. It stays as the guard.
- **A picture that is all paper still finds a sheet.** This is the regression that
  `ffi/bridge_check.sh` catches and **no Rust test does** - an earlier draft made the page fall
  into seventeen pieces and `find_paper` return `None`, which kills the whole automatic run.
  Add that Rust test as part of this task: a full-frame page, `find_paper` finds it,
  `is_the_whole_image` is true.
- **A photo of something that is not paper still returns `None`.** `SMALLEST_SHARE` and
  `THINNEST_SIDE` exist for that and the existing tests cover it.

**Do not.** Do not add a dependency - `image` is already there and this is a few hundred lines
of arithmetic at `WORK_WIDTH`. Do not touch `ffi/include/freepdf.h`, `ffi/bridge_check.sh` or
any existing assertion in `core_engine/tests/engine.rs`; they staying green unchanged is the
proof no boundary moved. Do not make
this a client-side change - the phone must not learn a second way to find paper.

**The photos, and the rule about them.** Seven real photos are the only honest evidence, and
they are private correspondence with a home address and a contract number on them.
`/Users/julianhahn/free-pdf/test_images/` is gitignored for exactly this reason
(`/Users/julianhahn/free-pdf/AGENTS.md`, Repo hygiene): **never commit one, never name its
contents in a comment, a test or a report.** Every test that ships is synthetic. To fetch a
fresh scan off the phone over the cable, with the phone unlocked and plugged in:

```sh
xcrun devicectl list devices
xcrun devicectl device info files -d <device-id> \
  --domain-type appDataContainer --domain-identifier com.julianhahn.freepdf \
  --subdirectory Documents/Scans --no-recurse
xcrun devicectl device copy from -d <device-id> \
  --domain-type appDataContainer --domain-identifier com.julianhahn.freepdf \
  --source Documents/Scans/<folder> --destination <somewhere outside the repo>
```

**Check.** `cargo test --workspace` passes with the new synthetic tests,
`bash /Users/julianhahn/free-pdf/ffi/bridge_check.sh` says "bridge ok", and - the part that
actually decides it - **by eye on every real photo**: paint the mask over the photo, save a
PNG, open it, and confirm the red is the sheet and nothing else. Then run
`cargo build -p backend-core-runner --release` and
`./target/release/backend-core-runner <photo> --scan -o <page>` on each, open each page, and
confirm two things: the page is cut to the sheet, and it is cut **nowhere into** it. No
chopped letterhead, no cut-through text, no desk left in a corner. A number is not a
substitute for that look.

**Blocked by.** Nothing.

---

## 30. iOS: Pull the sheet flat starts on - Julian, 2026-08-17

**Why.** Julian's decision on 2026-08-17: the switch is on when the screen opens. Today
`/Users/julianhahn/free-pdf/ios/FreePDF/AdjustView.swift`, `seed(_:)`, reads

```swift
pullFlat = all.pullTheSheetFlat && measured
```

and the left half is the engine's veto. While task 29 is unbuilt that veto is true on almost
every photo, so the one control that would cut the page opens switched off and the user has to
know to turn it on. He should not have to.

**Build.** The switch opens on whether corners were measured at all, not on whether the engine
approves of them. The switch stays - turning it off is how a photo the engine is right about is
handled - and nothing else about the screen changes.

**Do not.** Do not touch `runs_off_the_picture`, `scan_page` or anything in `core_engine` and
`ffi`; this is the Adjust screen and nothing else. The automatic run keeps the engine's own
judgement, so a page written by the drain is unaffected. Do not remove the switch, and do not
apply anything without Apply.

**Why it is safe even with wrong corners.** Adjust draws the four handles before Apply is
pressed, so a corner the engine got wrong is on screen and can be dragged. The user sees what
will be cut. That is the whole difference from the automatic run, and it is why this is not a
second version of the reverted tolerance in task 29.

**Blocked by.** 29 - once the corners are the paper's, this stops being a workaround and
becomes the honest default. Building it earlier is allowed and only makes today's manual step
unnecessary; say in the report which of the two situations it was built in.

**Built before 29 and now standing behind it.** The switch was flipped first, so for one run it was
the workaround; task 29 landed the same day and made it the honest default - `runs_off_the_picture`
is false on all twelve real photos, so the engine's own judgement no longer vetoes anything here.
One deviation from the text above: the engine's veto was dropped only from the *suggestion* path,
`pullFlat = stored != nil ? all.pullTheSheetFlat : measured`. A plain `pullFlat = measured` would
overwrite a stored "off" and break task 21's rule that the tools open on what was last applied.

**Check.** `bash /Users/julianhahn/free-pdf/ios/check/scan_check.sh` says "scan ok", and by
hand on a phone: open Adjust on a page, the switch reads on, Apply cuts the page without
touching the switch first.

---

## 31. A sheet that leaves the frame is cut anyway, and the page says so - Julian, 2026-08-17

**Why.** Julian photographed a letter that runs off the frame at the lower left and right,
scanned it on a phone carrying task 29, and the page came out `2250x3000` - the whole photo,
desk and a furniture edge along the top included. Then he opened Adjust, changed nothing, and
Apply gave him a clean `2183x3000` page with the desk gone.

Both are today's code working as written. `scan_page`
(`/Users/julianhahn/free-pdf/ffi/src/lib.rs`) skips `deskew` when
`Paper::runs_off_the_picture` is true, so the automatic run refuses; Adjust sends the four
corners itself and so is not asking. The corners it sent were
`(374,359) (2604,359) (3020,3884) (3,4005)` on a `3024x4032` photo - the two real sheet
corners at the top, and at the bottom the two places where the sheet crosses the left and
right edge of the frame.

**Julian's decision on 2026-08-17: the automatic run does what Adjust already does.** Those
two crossing points become the lower corners, `deskew` runs, and the page is cut. Where this
contradicts a rule written earlier in this file or in
`/Users/julianhahn/free-pdf/core_engine/AGENTS.md`, his decision wins and the old rule is
deleted, not argued with. Two sentences go: task 29's "Do not put a tolerance back into
`runs_off_the_picture`", and whatever `runs_off_the_picture`'s own doc comment says about not
straightening. It stays a true report about the photo; it stops being a veto.

**What it costs, and what pays for it.** The two lower points are not corners of the sheet, so
the quadrilateral is only an honest perspective picture of a piece of the page when the sheet
leaves the frame roughly along one line - which is Julian's photo. A sheet crossing a frame
corner at an angle gives a quadrilateral that slices diagonally through the paper, and `deskew`
then shears the writing. That does not look wrong, it looks slightly stretched, which is worse.

It is paid for by the other half of his decision: **the page says it is not the whole sheet,
and offers a retake.** An incomplete page the user is told about is not a silent failure, and a
retake is the one repair that always works.

**Read.** `/Users/julianhahn/free-pdf/ffi/src/lib.rs` - `scan_page` and its one
`runs_off_the_picture` branch, and `suggest_adjustments`, which already reports the same fact
across the boundary as `FreepdfSuggestion.runs_off_the_picture`
(`/Users/julianhahn/free-pdf/ffi/include/freepdf.h`). Swift already reads it as
`Engine.Suggestion.runsOffThePicture`
(`/Users/julianhahn/free-pdf/ios/FreePDF/Engine.swift`).
`/Users/julianhahn/free-pdf/ios/FreePDF/PagesView.swift` - the carousel, the page menu and
Retake. `/Users/julianhahn/free-pdf/user-flows.md` section 6.

**Build.**

- **The engine.** Delete the `if !sheet.runs_off_the_picture()` guard in `scan_page`, so the
  automatic run always straightens on the corners it found. One line. Nothing else in
  `core_engine` moves: `find_paper`, `corners`, `contains` and `runs_off_the_picture` are all
  unchanged, and this is the only caller that was refusing.
- **The warning.** The pages screen says, for the page on screen and only when the sheet ran
  off, that this page is not the whole sheet. It is a calm note and **not** an `ErrorLine` -
  nothing failed, the same rule as the removed-PDF note in task 11.
- **Where the fact comes from: the photo, at the moment the page is shown.** `runsOffThePicture`
  comes back from `Engine.suggest` on that page's photo, which is one engine run for the page on
  screen - the same call Adjust already makes when it opens, not forty runs when a scan is
  opened. Nothing is stored and no boundary is widened. This also settles the awkward case for
  free: the note and the retake both need the photo, so when the photos are deleted both are
  gone together, and there is nothing to explain.
- **The retake is the one that exists.** "Scan this page again", the same words and the same
  path the refused page already uses. Do not add a second way to retake a page.
- **The words.** No sentence for this exists in either copy table, so they are drafted here and
  are Julian's to change, exactly as the sixteen in task 4 were:

```
| Where | English | German |
| --- | --- | --- |
| The note under the page | Not the whole sheet - it ran off the edge of the photo. | Nicht das ganze Blatt - es lief aus dem Foto heraus. |
```

  Put the answer into the copy tables in `/Users/julianhahn/free-pdf/user-flows.md` section 6,
  which is where the app reads its words from.

**Do not.** Do not widen the C boundary - the fact already crosses. Do not store the flag in
`state/NNNN.txt`: that file holds what the user asked for, and this is a fact about the photo,
which is why it is read off the photo instead. Do not run the engine for pages that are not on
screen. Do not put a threshold on how far a sheet may run off - a threshold would be a second
judgement to get wrong, and the note plus the retake covers the bad case. Do not change Adjust,
which already behaves this way.

**Cut on purpose:** a sheet crossing a frame corner at an angle comes out sheared. Ceiling: the
note says the page is incomplete and the retake fixes it; if someone reports the shear itself,
the way up is to cut to the found edges without straightening when the two crossing points sit
on different edges of the frame.

**Docs.** `/Users/julianhahn/free-pdf/core_engine/AGENTS.md` and
`/Users/julianhahn/free-pdf/README.md` under "Limits worth knowing" both say a sheet that runs
off the photo cannot be straightened by its corners - now false for the automatic run, and
corrected in one line, not extended. `/Users/julianhahn/free-pdf/ios/AGENTS.md`: one sentence
next to the drain saying an incomplete page is cut and says so.

**Check.** `cargo test --workspace` passes, `bash /Users/julianhahn/free-pdf/ffi/bridge_check.sh`
says "bridge ok", `bash /Users/julianhahn/free-pdf/ios/check/scan_check.sh` says "scan ok". A new
synthetic Rust test: a sheet running off one edge is now cut, and the page is smaller than the
photo. Then by eye, which is what decides it: run the twelve photos in
`/Users/julianhahn/free-pdf/test_images/phone/` through
`backend-core-runner --scan` and open every page - the eleven that do not run off must come out
exactly as they do today, and `runs_off_1.jpg` must lose the furniture edge along its top. By
hand on a phone: shoot a page that hangs off the frame, see it cut, see the note, tap the retake.

**Blocked by.** Nothing. 29 is done, which is what makes the corners worth trusting.

---

## 32 and 33. What the phone showed on the pages screen - Julian, 2026-08-17

Two more things Julian found using the finished app. Both are about the pages screen and the
camera it opens, they touch the same two files, and they can run at the same time.

## 32. Adjust and Shoot another page are controls, not menu items — DONE

**Why.** Task 24 moved Adjust onto the pages screen because Julian could not find it, and left
it in the "…" menu as well - "only if that costs nothing". It costs something: the same action
in two places is a choice the user has to make before he can act, and the menu is still where
the eye goes looking. "Shoot another page" never came out at all and is still only in the menu,
behind a glyph, on exactly the screen where a user notices a page is missing.

Today in `/Users/julianhahn/free-pdf/ios/FreePDF/PagesView.swift`: Adjust is a control under
the carousel (`Button("Adjust page")`) **and** a menu item; "Shoot another page" is a menu item
only, shown on a finished scan.

**Build.** Both are controls on the pages screen, visible without opening a menu. Adjust loses
its menu entry - one way in, not two. "Shoot another page" gets a control of its own and keeps
the rule task 24 set for Adjust: the same place for every page, and disabled rather than hidden
where it does not apply, so nothing moves under the thumb.

The menu keeps what is left - retake and delete - and stays where it is.

**Do not.** Do not invent a word or a glyph meaning: "Adjust page" and "Shoot another page" are
the words, unchanged. Do not add a third entry point to either from Done or from the camera.
Do not make the controls appear and disappear - task 24's whole point was that a control which
moves cannot be found twice. No new colour, size or spacing: the dead look is the
`--disabled-*` colour role from task 1, never an opacity.

**Docs.** Task 24's sentence allowing Adjust to stay in the menu is now false and goes. The
flow 5 document and `/Users/julianhahn/free-pdf/user-flows.md` section 6 describe a menu of
three and four items - correct the count in one line, do not extend it.

**Check.** `bash /Users/julianhahn/free-pdf/ios/check/scan_check.sh` says "scan ok", and by
hand: a three page scan, both controls reachable in one tap from the page on screen, neither of
them in the "…" menu, and on a page whose photo was deleted Adjust is there and refuses.

## 33. Shooting another page does not stop after one — DONE

**Why.** Julian's words: "add a page" stops immediately after one photo. Adding three pages to a
finished scan should be three presses of the shutter and then one "Scan 3 pages", the same as
the first run of a scan - not going back to the pages screen and reaching for the menu again
between every shot.

**What the code says today, which is the awkward part of this task.** Reading it, this should
already work, and the cause is not visible from the source:

- `/Users/julianhahn/free-pdf/ios/FreePDF/CameraView.swift:284`, `if slot != nil { finished() }`
  is the one-shot path, and it belongs to a **retake** - one shot that takes itself back, by
  design.
- `ScanFlow.shootAnother()` sets `slot = nil`, which is not that path.
- The footer, the way out of the camera, is drawn only when `slot == nil` - so on this path it
  is there.

So do not start by rewriting the camera. Start by reproducing it on a real phone and finding out
what actually ends the screen: whether `slot` is not `nil` when it should be, whether the
enclosing `ScanFlow` tears the camera down for its own reason, or whether the footer's own
`finished()` is being reached without a tap. **Write what it turned out to be into the report** -
if the reading above is wrong somewhere, that is worth more than the fix.

**Build.** Shooting another page keeps the camera up until the user says he is done, exactly as
the first run of a scan does, with the same footer and the same words. Every shot lands on the
next free number, and the counter names it.

**Do not.** Do not change the retake: one shot that returns is what a retake is. Do not add a
"done" control of a second kind - the footer is the way out and it already exists. Do not
change what the footer says; if its wording is wrong for a scan that already has pages, that is
task 4's open pairing question and is Julian's to answer, not this task's to invent.

**Check.** `bash /Users/julianhahn/free-pdf/ios/check/scan_check.sh` says "scan ok", and by
hand on a phone: a scan of two pages, Shoot another page, three shots without leaving the
viewfinder, the counter reading 3, 4 and 5 as they land, then the footer once - and five pages
on the carousel.

**Blocked by.** Nothing. Runs alongside 32.

---

## 34. After the first page, the app shows what it is about to do — DONE

**Why.** A scan is photographed blind. Every page is shot, and only when the user says he is
done does the engine turn any of them into pages - so a whole scan can be photographed on a desk
the engine cannot read, and the news arrives twenty pages too late. Nobody knows in advance how
long a scan will be, so there is no good moment to check except the earliest one.

Julian's decision on 2026-08-17: after the first photo of a scan, and only after that one, the
app shows what the page made from it would look like, and asks whether to carry on.

**Corrected on 2026-08-18, by Julian on a phone: there are three ways out, not two.** A
document of one page could not be finished from this screen at all - both ways out below lead
back to the camera, and the footer that scans is not on this screen. It gained a third
control, **Scan 1 page**, in the camera footer's own words for one page. The rest of this
section stands.

**The two ways out, which is the whole point of the screen.** Left: the surroundings are the
problem and the shot is taken again - more light, a plainer surface, less shine. Right: this is
right, carry on and photograph the rest in one go. The second is the normal answer and the
screen must not slow it down.

**Build.**

- **Once per scan, after the first photo lands, before the second shot.** Never again in that
  scan, whatever happens later - a check the user has to dismiss on every page is a different
  app, and a slow one. A scan that already has photos - resumed after a kill, or "Shoot another
  page" on a finished scan - does not show it at all: he has seen his pages by then.
- **The picture is a real engine run, not an approximation.** What is shown is the page that
  would be written, for the same reason task 26 gives on the Adjust screen: a picture drawn to
  look about right is a promise the app cannot keep. It costs one engine run, once per scan,
  and that is what the screen is buying.
- **The scratch file rule is task 26's, unchanged.** The preview goes to a file that is not
  `photo/`, `page/`, `state/` or `scan.pdf`, `sweep()` stays true afterwards, and if that means
  it lives outside the scan folder, it lives outside the scan folder. The real page is still
  written by the drain and by nothing else.
- **It names the shot it came from**, so there is no doubt which photo is being judged - the
  page number, in the words the counter already uses.
- **A kill costs nothing.** The photo is on disk before this screen exists, so a kill here
  leaves a scan with one photo and no page, which is exactly the state the app already resumes
  from today.
- **A preview that fails shows the engine's sentence unchanged**, as everywhere else, and the
  two controls still work - a page the engine refused is a reason to retake, and the screen must
  say so rather than trap him.

**The words**, drafted here and Julian's to change, as the sixteen in task 4 were. One new
sentence only; the left control reuses the words the pages screen already uses for a retake:

```
| Where | English | German |
| --- | --- | --- |
| Above the two pictures | This is how your pages will come out. | So werden deine Seiten aussehen. |
| Between or under them | Your photo becomes this page. | Aus deinem Foto wird diese Seite. |
| The line under it | Not right? More light or a plainer surface fixes most of it. | Nicht richtig? Mehr Licht oder eine ruhigere Unterlage hilft meistens. |
| Left control | Scan this page again | Diese Seite neu scannen |
| Right control | Photograph the rest | Restliche Seiten fotografieren |
```

**It shows the photo as well as the page, and that is what makes task 35 readable.** Julian
spotted this: this screen shows a cut, straightened, brightened page, and seconds later the
viewfinder shows a small raw photo with the desk still in it. Two pictures of the same sheet,
looking nothing alike, half a minute apart - and nothing anywhere says why.

So the pair is taught here, once, where there is room for it: the shot he took beside the page
it becomes, in that order, with the sentence above naming the relationship. After that the
thumbnail in the corner needs no caption, because he has already seen which of the two it is.
The photo is the small one and the page is the large one - the page is what he is judging.

This is the cheap half of the fix. The alternative was a caption on the thumbnail, which means
words over a live viewfinder on every single shot to explain something that has to be said once.

**Do not.** Do not show it after every page, and do not make it a setting - it is once per scan
or it is nothing. Do not put Adjust on it: this screen answers "carry on or start over", and a
page fixed by hand here would still leave the next twenty shot on the same bad desk. Do not
build a second retake path - the left control is `ScanFlow.retake`, which already exists and
already puts the camera back on that page number. Do not write the previewed page into `page/`,
and do not let it stand in for the drain's own run: the drain writes every page from every
photo, exactly as it does today.

**The thumbnail he also asked for is task 35**, not this screen. On this screen the picture
already is the last photo taken.

**Read.** `/Users/julianhahn/free-pdf/ios/FreePDF/CameraView.swift` - where a shot lands and
what `photos` and `slot` mean. `/Users/julianhahn/free-pdf/ios/FreePDF/ScanFlow.swift` - the
step, `retake`, and the drain that owns page writing.
`/Users/julianhahn/free-pdf/ios/FreePDF/AdjustView.swift` and task 26 - the preview into a
scratch file, which is the pattern to copy rather than reinvent. `/Users/julianhahn/free-pdf/ios/AGENTS.md`
in full, especially the storage model and the sweep.

**Check.** `bash /Users/julianhahn/free-pdf/ios/check/run.sh` says "resume ok" and
`bash /Users/julianhahn/free-pdf/ios/check/scan_check.sh` says "scan ok" - `sweep()` unchanged
by the scratch file. By hand on a phone: start a scan, shoot one page, see the page as it would
come out; tap the right control and photograph four more without being asked again; start
another scan, shoot one page, tap the left control and land back on the viewfinder for page 1;
kill the app on the check screen and find one photo, no page, and the viewfinder on relaunch.

**Blocked by.** Nothing. It shares the scratch-file rule with task 26, which is built.

---

## 35. The viewfinder shows the last page photographed — DONE

**Why.** This was decided against and is now decided for; the reason it was skipped was wrong.
`/Users/julianhahn/free-pdf/user-flows.md` DECISIONS point 10 says a corner thumbnail is not
needed because "retaking from the pages already works" - but retaking is not what it is for.
Julian, working through seven double-sided sheets: the counter says "Page 8" and that is a
number, not an answer to the question he actually has, which is *which sheet did I just
photograph*. Turning a stack of paper over is exactly where a person loses their place, and a
picture answers in a glance what a number cannot answer at all.

Nothing else in the camera gives any feedback that a shot landed except the counter going up.

**Build.** A small picture of the newest photo of this scan, in a corner of the viewfinder,
appearing when the first shot of the session lands and replaced by each shot after it.

- **Reuse `PageImage`** (`/Users/julianhahn/free-pdf/ios/FreePDF/PagesView.swift`, not private
  precisely so other screens can use it). It already decodes at a maximum pixel size off the
  main thread and shows the paper colour until it is ready. A thumbnail is that view with a
  small `maxPixels` and a frame - do not write a second decoder.
- **It shows a photo, not a page.** During shooting no page exists yet, and making one per shot
  would put an engine run between him and the shutter. What it confirms is what he pointed the
  camera at, which is the question being asked: *which sheet was that*, not *how good is it*.
  Those are two different questions and they want two different pictures.

**Why that is not confusing, which it would be on its own.** Task 34 shows a cut, straightened,
brightened page after the first shot, and this shows a small raw photo with the desk still in it.
Same sheet, nothing alike, half a minute apart. Task 34 therefore shows the photo beside the
page it becomes, with one sentence naming the relationship, so the pair is taught once on a
screen with room for it. That is why this thumbnail carries no caption of its own: words over a
live viewfinder, on every shot, to explain something that needs saying once, is the expensive
way round.
- **It appears when a shot lands, not when one is pressed.** A file earns its name by rename
  (`/Users/julianhahn/free-pdf/ios/AGENTS.md`), so the thumbnail follows the newest photo that
  really is on disk. Nothing is held in memory that has not been written - the same rule the
  rest of the app keeps.
- **Nothing before the first shot of the session.** A fresh scan starts with no thumbnail;
  "Shoot another page" on an existing scan also starts with none, because the point is to
  confirm what *he* just took, not to show him a photo from an hour ago. It never appears at all
  during a retake, which is one shot that leaves immediately.
- **It sits clear of everything that takes a touch** - the shutter, the counter, the footer and
  the error line, which may all be on screen at once. Its size, corner inset and radius come
  from `Token`; a missing token is a token to add to
  `/Users/julianhahn/free-pdf/design/system/tokens/*.css` and regenerate with
  `node design/system/tokens/build-tokens.mjs`, never a number typed into the screen.
- **VoiceOver:** it is confirmation of something the counter already announces, so it is
  decoration a screen reader skips. The counter keeps naming the page.

**Do not.** Do not make it tappable, do not open a gallery, do not let it grow into a filmstrip
of every page - the rail on the pages screen is where pages are browsed, and a second browser in
the camera is a second place to keep true. Do not decode the full 12 MP photo to draw a small
picture. Do not delay the shutter for it: a thumbnail that is still decoding must never be a
reason a shot cannot be taken. Do not put the page count or any words on it; it is a picture.

**Docs.** `/Users/julianhahn/free-pdf/user-flows.md` DECISIONS point 10 is now false and is
replaced, not extended - one line saying the thumbnail is built and what it is for. Task 6's
"Do not add a corner thumbnail" in this file is false for the same reason and goes; the other
three things it rules out - a flash control, a landscape frame, a photo-library import - all
stand. `/Users/julianhahn/free-pdf/user-flows.md` section 4 gains one line describing it.

**Check.** `bash /Users/julianhahn/free-pdf/ios/check/scan_check.sh` says "scan ok", and by
hand on a phone: start a scan, no thumbnail before the first shot; shoot three pages and the
thumbnail is each one in turn as it lands; force-quit and relaunch into the viewfinder, no
thumbnail until the next shot; a retake shows none.

**Blocked by.** 34, and only for the reason above: the thumbnail is readable because the check
screen has already shown what a photo and a page each look like. Building it first is allowed;
shipping it to a phone before 34 is what leaves the question unanswered. It touches only the
camera and can run beside 32 and 33.

---

## 36. The bottom edge still overshoots, and cropping in is allowed - Julian, 2026-08-18

**Read this whole section before you touch anything.** Three attempts at this have already
been made today, two of them wrong, and the wrong ones are written down here so you do not
repeat them. The person who made them is the agent handing over; the numbers are all
measured and reproducible.

**What Julian sees, on a phone, on the current build.** The top corners are exactly right.
The bottom corners still overshoot - less than before, but the page still carries a strip of
his table along the bottom. His words: "we could easily crop in more and would be rid of the
table." That sentence is a decision, and it is the one thing this task turns on. His build was
verified current: the app was built at 15:02:43 and the engine library it links at 15:02,
after the last engine change.

**The instrument. Use it, do not reason without it.**

```sh
cargo run --release --example edge_error -- test_images/phone/*.jpg
```

`core_engine/examples/edge_error.rs` walks across each found side in the FULL sized photo and
finds the true paper-to-table step. It prints two numbers per side, `middle/worst`, over nine
places along that side. **Sign: positive means the side sits INSIDE the paper. Negative means
it sits outside it - a strip of desk in the page, which is the bug.** The middle says whether
the side sits on the edge at all; the worst says whether any part of it is outside. They
disagree because a sheet on a desk bows, and that gap is this task's whole subject.

The state as this is written, `INWARD_HAIR = 1.5`, twelve photos, `runs_off_1.jpg` excluded
because its lower corners come from where the paper leaves the frame (task 31) and not from a
fitted side:

```
| photo | left mid/worst | right | top | bottom |
| --- | --- | --- | --- | --- |
| extra_1 | +1 / -3 | +2 / -3 | +1 / -16 | +1 / -8 |
| extra_2 | +2 / -12 | +2 / -5 | +1 / -13 | +2 / -57 |
| extra_3 | +2 / -3 | +0 / -6 | +0 / -11 | +1 / -37 |
| extra_4 | +2 / -4 | +2 / -3 | +1 / -36 | +2 / -37 |
| extra_5 | +1 / -4 | +2 / -2 | +1 / -8 | +1 / -20 |
| sheen_1 | +1 / -2 | +1 / -9 | +0 / -13 | +3 / -18 |
| sheen_2 | +1 / -4 | +2 / -10 | +0 / -13 | +1 / -16 |
| sheen_3 | +1 / -6 | +1 / -8 | +1 / -45 | +1 / -15 |
| sheen_4 | +1 / -1 | +1 / -10 | +1 / -11 | +0 / -18 |
| sheen_5 | +2 / -3 | +0 / -9 | +0 / -41 | +1 / -24 |
| sheen_6 | +1 / -4 | +1 / -16 | +1 / -14 | +2 / -7 |
| sheen_7 | +1 / -2 | +1 / -10 | +2 / -47 | +0 / -5 |
```

Every middle is 0 to +3, which is why the last change was called done. Every worst is
negative, which is why Julian still sees his table. **The middle was the wrong number to
finish on.**

**What the code does today.** `find_paper` in
`/Users/julianhahn/free-pdf/core_engine/src/paper.rs`: brightness gives a rough area, rays
along rows and columns find where the paper stops on a 400 pixel wide copy (`WORK_WIDTH`),
four straight sides are fitted through those places, and then
`sides_read_again_in_the_photo` moves each side onto the **middle** of nine readings taken in
the full sized photo, minus `INWARD_HAIR = 1.5` pixels. The corners are where the sides
cross. One working pixel is 7.6 photo pixels, which is why the second reading exists at all.

**The three attempts already made, so you do not make them again.**

1. **Flipping `OUTWARD_BIAS` to `INWARD_BIAS`** (committed, `4819c32`). Moved all four sides
   inward by the same amount. It cannot work: the miss was asymmetric, so it traded desk on
   three sides for cutting 7 pixels into the sheet on those three while the top kept its desk.
2. **Turning that constant up.** 0.5, 1.0, 1.5, 2.0 were all measured. Same problem, further
   along. A single scalar cannot fix a per-side error, and this is why Julian saw "better but
   still wrong" twice in a row.
3. **Aiming at the worst reading instead of the middle** (second smallest of nine, to leave no
   place outside the paper). Tried and reverted: it lets a single misread place - a fold, a
   shadow, a second sheet inside the 60 pixel search window - drag a whole side deep into the
   page. Some readings jumped between -25 and -59 without tracking the constant at all, which
   is the signature of a misread edge rather than a real miss: **a real miss moves by exactly
   as much as the constant is moved, an artefact jumps about.** Use that test.
4. **`INWARD_HAIR = 6.0`**, which does put every place of every left and right side inside the
   paper. Reverted because it cuts 6 pixels off a **flat** sheet and two synthetic tests in
   `core_engine/tests/engine.rs` fail:
   `a_patch_of_sheen_beside_the_sheet_is_not_part_of_it` and
   `the_corners_are_found_in_the_photo_and_not_only_in_the_shrunk_copy`.

**Point 4 is where the previous agent got stuck, and it is the thing you are being handed.**
Two truths disagreed and it kept the wrong one. The synthetic tests draw a perfectly flat
sheet and demand the corners land within a few pixels of it. Julian's paper is not flat and
his phone is the truth. **His decision on 2026-08-18: crop in more.** A few pixels of white
margin are invisible; a strip of his desk is not. So the synthetic tests' expectation is what
gives way here - they are a fixture the previous agent wrote this morning, not a rule Julian
set - and they are corrected to expect a page cut slightly inside the drawn sheet, with the
reason written next to them.

**Build.**

- **Ask why the bottom is the worst side before you change anything.** It is the only side
  Julian named, and the numbers agree with him: bottom worst runs -5 to -57 while left is -1
  to -12. Find out why, and write it into your report. Two things worth measuring first: a
  sheet photographed from above lifts at the edge nearest the camera, and the shadow under
  that lifted edge is wider - so ask whether the reading is landing on the shadow's outer
  boundary rather than on the paper. If the bottom has a cause of its own, fixing that cause
  beats any margin.
- **Then make the page cut inside the paper everywhere, not on average.** The straightforward
  way is a margin that covers the bow. Measure what it costs on all twelve photos and on the
  synthetic fixtures, and say the cost in your report in pixels and in millimetres of an A4
  page. Do not exceed what the acceptance below allows.
- **Whatever you build must be measured with the instrument, not argued.** Paste the table.

**Do not.**

- Do not tune per photo, and do not add a constant read from the image's own name or size.
- Do not raise the margin until the worst column is positive everywhere: `sheen_3`'s top and
  `extra_2`'s bottom are misread places, not 45 pixels of desk, and chasing them would cut
  half a centimetre off every page. Prove which is which with the tracking test above.
- Do not widen the C boundary, do not touch the iOS client, do not change `WORK_WIDTH`, and do
  not read the whole full sized photo into memory - only along the four sides (see the memory
  budget in `/Users/julianhahn/free-pdf/ios/AGENTS.md`).
- Do not let a side invent an edge. A place with no clear step is dropped, and a side with
  fewer than five answers keeps the rough fit's position. That rule stays.
- Do not delete `core_engine/examples/edge_error.rs`. It is not shipped and it is the only
  reason any of this is known.

**Acceptance.** Not a feeling, and not the middle column:

- On the twelve photos, every side's **worst** reading is at least -3, except where you have
  shown with the tracking test that a reading is a misread edge rather than desk - and each
  such exception is named in your report with its evidence.
- No side's middle reading exceeds +12, so no page loses more than about a millimetre of its
  margin.
- `cargo test --workspace` passes. `bash /Users/julianhahn/free-pdf/ffi/bridge_check.sh` says
  "bridge ok". All thirteen photos still produce a page through
  `target/release/backend-core-runner <photo> --scan -o <out.jpg>`.
- `bash /Users/julianhahn/free-pdf/ffi/build-ios.sh` at the end, or Julian's phone runs
  yesterday's engine. His Xcode now runs cargo itself through a "Build the engine" phase
  (uncommitted at handover time, in `ios/FreePDF.xcodeproj/project.pbxproj`), so a Cmd+R is
  enough for him - but a library built here has to be fresh for the checks.
- Then Julian looks at a page on his phone. That is what decides it.

**Blocked by.** Nothing.

---

### Done on 2026-08-18 - the report

**The bottom is not the worst side. It has no cause of its own.** Bottom and top are the same
defect, a straight side laid on a curved long edge, and the numbers cannot tell them apart: the
bottom's nine readings spread by 44 pixels on average and the top's by 40, the bottom is worse on
seven photos and the top on five.

Both things this task asked to measure first are real, and neither is the cause.

- **The sheet does lift at the edge nearest the camera.** The shadow under the bottom edge is 30
  pixels wide on average over the twelve photos, 29.8; under the top edge it is 3.4. But a lifted
  near edge
  would make the bottom worse than the top, and it is not worse. A shadow also makes the step from
  paper to table bigger, so the edge is easier to find there, not harder.
- **A reading does sometimes land on the outer boundary of something else, but it is sheen, not
  shadow, and it errs the safe way.** On `sheen_4`'s bottom, three of the nine places sit on the
  outer edge of a bright band lying on the table beyond the sheet. Walking outward at one of them:
  the paper reads 217 to 222, drops to 148 at its own edge, climbs again to 179, 203, 213, 231 out
  to +12, then falls to 60, 59, 8. The paper's own step is 74 and the band's outer step is 223, so
  the steeper one wins, and the place reports +16 when the paper's edge is at -2. That is 18 pixels
  of extra white margin, not table. On the top side the steepest step is the first step at every
  one of the nine places on all twelve photos, so this cannot reach the top at all.

**Why Julian saw the bottom, then: how visible it is, not how big it is.** The table beyond the
bottom edge reads 39 grey on average, the table beyond the top edge 77, on the same scale where the
paper reads 150 to 220. A 15 pixel strip of near-black along the bottom of a page looks like his
table. The same strip along the top is light grey, looks like more white margin, and `scan` pushes
it further towards white. Same defect on both sides; only one of them shows.

**What was built.** One line of arithmetic, in a new four-line helper called
`where_the_side_goes`, in
`/Users/julianhahn/free-pdf/core_engine/src/paper.rs`. A side used to be laid on the MIDDLE of its
nine readings, which leaves half of its places outside the paper by definition - that was the
number the last change finished on. It is now laid on the INNERMOST reading, and never more than
`MOST_INWARD = 10` photo pixels past the middle. The cap is the whole defence against a misread
place: at 10 pixels, `extra_2`'s wild reading is pulled in by the same 11.5 pixels as any ordinary
bowed side, so no second test for a lone reading is needed and none was added. The margin scales
itself - a flat edge gives nine equal readings, so its innermost IS its middle and it pays nothing
at all. That is why the two synthetic tests that hold corners to a drawn sheet pass untouched, and
why only one fixture expectation had to be corrected.

**The table, after the fix.** `cargo run --release --example edge_error -- test_images/phone/*.jpg`,
run twice with the same result. `middle/worst`, in pixels of the photograph; positive is inside the
paper.

```
| photo | left mid/worst | right | top | bottom |
| --- | --- | --- | --- | --- |
| extra_1 | +6 / 2 | +7 / 2 | +12 / -5 | +10 / 1 |
| extra_2 | +12 / -3 | +7 / 1 | +11 / -3 | +11 / -47 |
| extra_3 | +7 / 3 | +7 / 1 | +10 / -1 | +11 / -25 |
| extra_4 | +6 / 2 | +3 / 1 | +11 / -27 | +12 / -27 |
| extra_5 | +6 / 1 | +6 / 2 | +10 / 1 | +12 / -10 |
| sheen_1 | +7 / 3 | +11 / 1 | +10 / -1 | +12 / -9 |
| sheen_2 | +5 / 0 | +12 / 1 | +11 / -2 | +10 / -6 |
| sheen_3 | +7 / 1 | +11 / 2 | +9 / -60 | +11 / -6 |
| sheen_4 | +4 / 1 | +11 / 0 | +12 / -1 | +11 / -8 |
| sheen_5 | +6 / 1 | +10 / 1 | +11 / -55 | +12 / -7 |
| sheen_6 | +6 / 1 | +12 / -6 | +11 / -4 | +11 / 2 |
| sheen_7 | +5 / 2 | +11 / 0 | +12 / -36 | +7 / 1 |
```

`runs_off_1.jpg` reads +9/7, +40/-28, +37/-39, +59/34, exactly as it did before - unchanged is the
proof that its corners come from where the paper leaves the frame (task 31) and not from a fitted
side.

**What it costs.** A millimetre of these photos is 11.5 pixels: the twelve finished pages come out
2317 to 2594 pixels across, mean 2458, for the 210 mm of an A4 sheet, and 3250 to 3567 tall for its
297 mm. So 11.4 to 11.7 pixels per millimetre either way.

- **Per side, the hard ceiling is `MOST_INWARD` plus `INWARD_HAIR`, 11.5 pixels, which is 1.00 mm.**
  It cannot be more, whatever the photo.
- **Per page, measured on the JPEGs before and after:** 8 to 26 pixels of width, mean 18, which is
  1.6 mm across both left and right margins together; and 1 to 18 pixels of height, mean 10, which
  is 0.9 mm across top and bottom together. The middle column of the ruler says the same from the
  other end: it moved from +0..+3 to +3..+12. A printed letter has 20 to 25 mm of white margin, so
  this is about a twentieth of it.
- **A flat sheet pays nothing.** Three of the four synthetic fixtures are unchanged to the last
  decimal, at their original 6.0 and 8.0 tolerances. The fourth, `document_on_a_dark_table`, comes
  in 9 to 12 pixels, and it pays for real geometry rather than for the constant: its corners are cut
  off by 60 pixels, a sixth of its width, so the outermost of the nine places really does sit where
  the drawn paper has ended. Its expectation was corrected, as this task allows, and the reason is
  written beside the assertion.
- **A bigger allowance does not buy what it looks like it would.** At `MOST_INWARD = 20` the middles
  run up to +22, over the cap Julian set, and `extra_4`'s bottom gets WORSE, -27 to -60: moving a
  side slides the nine places it is read at along the edge, so the reading is not monotone in the
  constant and cannot be bisected.

**Acceptance, plainly: the second, third, fourth and fifth criteria are met. The first is not, and
cannot be.**

- **Worst reading at least -3: NOT met.** Sixteen of the forty-eight sides read worse than -3. Three
  are the ruler misreading and are named below. The other thirteen are real table left in the page:
  `extra_1` top -5, `extra_3` bottom -25, `extra_4` top -27 and bottom -27, `extra_5` bottom -10,
  `sheen_1` bottom -9, `sheen_2` bottom -6, `sheen_3` bottom -6, `sheen_4` bottom -8, `sheen_5`
  bottom -7, `sheen_6` right -6 and top -4, `sheen_7` top -36. Each was checked two independent
  ways - a continuous walk along the whole side, and the brightness of the strip the side cuts off -
  and both say paper on one side and table on the other. This is arithmetic, not tuning: a place of
  a side ends up at `innermost - middle + 11.5`, so "worst at least -3" asks every side to bow
  within 14.5 pixels, and these thirteen bow further, up to 49 pixels on `sheen_7`'s top. No placing
  of a straight line reaches them. `extra_2`'s left and top read exactly -3 and pass.
- **No middle above +12: met, with nothing to spare.** Ten of the forty-eight read exactly +12.
- **`cargo test --workspace` passes:** 52 green on this Mac, 0 failed, no test added or removed and
  one expectation corrected.
- **`bash ffi/bridge_check.sh`:** prints "bridge ok".
- **All thirteen photos still produce a page:** 13 of 13 through
  `target/release/backend-core-runner <photo> --scan -o <out.jpg>`, all non-empty.
- **`bash ffi/build-ios.sh`:** both libraries built at 16:50, after the last change to `paper.rs`.

**The three excluded readings, each with its evidence.** The tracking test this task gave -
a real miss moves by exactly as much as the constant is moved, an artefact jumps about - settles two
of the three on its own. The first one needs a walk along the side as well, and that is worth
knowing: the tracking test alone is not enough.

1. **`extra_2` bottom, -47, at the ninth of nine places.** It PASSES the tracking test: as the cap
   moves, the reading follows it exactly, -57, -54, -51, -47. The walk along the side kills it. At
   1 percent steps the readings around it are 87%: -2, 88%: -2, 89%: -3, 90%: -57, 91%: -3, 92%: -4,
   93%: -5. One sample in a hundred and one. Something dark genuinely is there - walking outward
   from the photo point (3323, 2833) reads 173, 183, 136 and then 32 to 88 continuously, and the
   strip scores dark - but it is 2 percent of the side wide, with the paper's edge at -3 on both
   sides of it. No sheet dives 54 pixels in and back out within 2 percent of its length; a mark, a
   staple or a shadow touching the edge does exactly that, and the ninth place of the grid lands on
   it. Following it would cut 54 pixels off every page for one place on one photo. Excluded.
   `extra_2`'s bottom is really -5 at worst.
2. **`sheen_3` top, -60.** In the last tenth of that side the ruler returns pure noise: as the
   constant moves, the ninth place reads +54, +37, +31, +36 - it does not track, and it changes
   sign. A walk along the same zone swings from -56 to +57 within a few percent of the side. The
   true edge there lies further out than the 60 pixels of `LOOK_FOR_THE_EDGE`, so nothing stable
   ever wins. This is the reading this task already warned about. Excluded.
3. **`sheen_5` top, -55.** The same corner, the same failure: -31, -60, -59, -56, a jump of 29
   pixels on the first three-pixel step. Excluded.

Both excluded tops read at or within a few pixels of the ruler's own limit of 60, which is the
tell. They are what a corner does to the instrument, not evidence about a side.

**One wording in this task's "Do not" list is worth making exact.** It calls `sheen_3`'s top and
`extra_2`'s bottom "misread places, not 45 pixels of desk". On `extra_2`'s bottom something dark
really is there, measured above: the mistake is not that the ruler saw nothing, it is that the
ruler saw a spot and reported it as a side. The conclusion the list draws is right either way, and
the reason is worth stating exactly, because the next person will measure that brightness and find
table.

**What is left, and where it is written.** Thirteen sides bow further than the millimetre a page may
lose, so a thin wedge of table stays near one end of those sides - a wedge at a corner, not a band
along an edge. The way up is a corner of its own for each end, or four sides that may bend; both
are more than a constant. That is the `ponytail:` note on `sides_read_again_in_the_photo`, and the
row in **Parked** in `/Users/julianhahn/free-pdf/README.md`. Do not raise `MOST_INWARD` to chase it:
the millimetre is Julian's, and the measurement above shows that raising it makes one side worse
rather than better.

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
