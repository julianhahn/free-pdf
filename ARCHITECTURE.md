# ARCHITECTURE

What FreePDF is shaped like, why it is shaped that way, and what is worth changing next.
The rules live next to the code they govern - this file points at them, it does not restate
them. Read the AGENTS.md beside a file before you touch it.

## 1. The picture

```
                      THE FILES ARE THE ONLY STATE
   Documents/Scans/2026-08-11_201403_8F3A/
      photo/0001.jpg 0002.jpg 0004.jpg     gaps stay, numbers are never reused
      page/ 0001.jpg 0002.jpg              a photo with no page = the resume point
      state/0001.txt                       what the user last asked for on that page
      scan.pdf                             exists => finished. Arrives only by rename.
                              ▲
                              │  every read is a fresh directory listing. No cache
                              │  of the truth, no manifest, nothing to disagree.
   ios/  SwiftUI, 12 files    │
      FreePDFApp ── sweep() at launch, the only repair pass
         └─ ScanList ──tap──▶ ScanFlow ───── Scan.swift  (the disk. Foundation only)
                                 │
                                 │  refresh(): photos, pages, bytes, finished, grey
                                 │  the switch turns that into exactly one screen
                                 ├─ CameraView      shooting
                                 ├─ takeover        applying to every page
                                 ├─ AdjustView      adjusting one page
                                 ├─ done            finished  ← the only screen with no file
                                 ├─ PagesView       nothing left to drain
                                 └─ scanning        the drain
                                 │
                                 └─ the write policy: apply / flipGrey / write / makePDF
                                                     (no SwiftUI in any of it)
                                 │  paths and plain numbers in
                                 ▼
   ios/FreePDF/EngineCalls.swift  ──▶  ffi/include/freepdf.h
                                 │     0 = it worked. Anything else = one sentence,
                                 │     copied into the caller's buffer, shown unchanged.
   ffi/  Rust, 622 lines, four C functions
      scan_page   suggest_adjustments   adjust_page   pages_to_pdf
      ★ THE ORDER OF THE TOOLS LIVES HERE, not in the engine:
        deskew → straighten → levels → 3000 px cap → sharpen → [turn → crop → grey] → write
                                 │
                                 ▼
   core_engine/  Rust, ~1500 lines. No order, no state, opens no file but load_image + pdf.rs
      paper.rs  find_paper ──corners──▶ deskew.rs  deskew / straighten
      tools.rs  levels, sharpen, rotate, crop, grey
      pdf.rs    save_page ──paths──▶ pages_to_pdf        Result<_, String> everywhere
      every tool is a pair:  measure (cannot fail)  /  act (refuses, never clamps)

   design/system/  tokens/*.css ──build-tokens.mjs──▶ ios/FreePDF/Tokens.swift
                   22 components (.jsx) ──▶ storybook/stories/*
                   the declared source of truth for every future client
```

**core_engine** is a box of single tools: images and paths in, images and sentences out. It
knows no order and holds no state, which is what lets a client rerun one step
([`core_engine/AGENTS.md`](./core_engine/AGENTS.md)).

**ffi** is the smallest client there is, and the only one that speaks C. Four functions,
paths and plain numbers in, an `int32` out. It owns the order of the tools
([`ffi/AGENTS.md`](./ffi/AGENTS.md)).

**ios** is a router with screens hanging off it. `Scan.swift` is the disk; `ScanFlow` reads
it into a cache, decides from that cache which screen this scan means, and owns every file
move any screen asks for. The screens are dumb: numbers in, closures out
([`ios/AGENTS.md`](./ios/AGENTS.md)).

**design/system** is where a visual value is decided. The CSS tokens are the single source
and `build-tokens.mjs` generates `Tokens.swift` from them, so a second client is an emitter
and nothing else.

## 2. The rules that hold

- **The files are the only state.** After a kill there is nothing else to disagree with the
  disk - [`ios/AGENTS.md`](./ios/AGENTS.md), "One scan is one directory".
- **The step is read off the directories, every time.** A photo with no page is the resume
  point; `scan.pdf` existing is the definition of finished. No manifest, no progress field.
- **A file earns its real name only by rename after a complete write.** `.part` then rename
  in Rust, `.atomic` in Swift. A real name is proof of a complete file.
- **Debris is invisible and swept.** `Scan.sweep()` at launch is the only repair pass.
- **The engine offers single tools, the client owns the order** - [`AGENTS.md`](./AGENTS.md).
  Nothing runs by itself, so the user can skip, redo or correct any step.
- **Measure and act are two functions.** The measure half cannot fail, answers "do nothing" when
  unsure, and only ever proposes something the act half accepts; the act half refuses input that
  does not fit rather than clamping it - [`core_engine/AGENTS.md`](./core_engine/AGENTS.md).
- **One error sentence, printed unchanged.** Every fallible step returns `Result<_, String>`
  and the String is a finished English sentence the screen shows as it is.
- **Offline only.** Local files in, local files out. One network call and the promise is gone.
- **Nothing on a screen lists a directory** while the drain is running - a listing inside a
  body answers differently twice in one frame and SwiftUI never settles. `makePDF()` and
  `everyPage()` are the deliberate exceptions and each carries its argument.
- **Every visual value is a token.** A missing token is a CSS change, never a number typed
  into a screen. `Tokens.swift` is generated; never hand-edit it.
- **The design system is the source of truth for clients.** A client mirrors it; it never
  invents a variant of its own.

## 3. The ranked list

Ranked by how much a reader's head is unburdened per line of risk. Every item removes
something. Checks: `cargo test --workspace`; `bash ffi/bridge_check.sh` (~1 s);
`bash ios/check/run.sh` (~2 s, no Xcode); `bash ios/check/scan_check.sh` (~3 min, simulator);
`cd storybook && npx storybook build`; `node design/system/tokens/build-tokens.mjs --check`.

### 1. [x] Delete the frozen second copy of the design system

`design/system/` contains itself twice. The live half - `tokens/*.css` and the 22 `.jsx`
components - is current with the app. The frozen half describes the app of two weeks ago and
is what the specimen cards and the iPhone kit actually load: `_ds_bundle.js` still writes
`opacity: disabled ? var(--disabled-opacity)`, the mechanism task 1 replaced, seven times, and
has no `PageStrip`, `ToolStrip`, `PageHandles` or `Sheet` in it at all. `ui_kits/iphone/
AdjustScreen.jsx:99` still says "No live preview" (reversed by task 26) and `PagesScreen.jsx:99`
still hides Adjust in the `⋯` menu (the exact complaint task 24 was written for).

- **Removes:** ~3,110 lines and one whole source of truth. `_ds_bundle.js` (1,925),
  `_ds_manifest.json`, `_adherence.oxlintrc.json`, the five `*.card.html`, the five
  `ui_kits/iphone/*Screen.jsx`, `App.jsx`, `index.html`, `storybook/stories/Screens.stories.jsx`.
- **Keeps:** `ui_kits/iphone/Chrome.jsx` and the `kitAsModules` transform in
  `.storybook/main.js` - the seven flow stories import `AppBar`/`Screen`/`StatusLine` from it.
- **Costs:** the specimen cards stop existing. Storybook already renders every component from
  the `.jsx`, so nothing is lost that is not also drawn better elsewhere.
- **Check:** `npx storybook build` still succeeds; `grep -rn _ds_bundle design/system` returns
  nothing.
- **Left dangling, struck since** (443f878): the `gallery/_ds/<theme>/readme.md` row in
  `design/AGENTS.md`, the now-unreachable `Chrome.jsx` branch in `.storybook/main.js`, and
  Flow1's comment pointing at the deleted `Screens.stories.jsx`. Three more are still open -
  the `TASKS.md` lines in item 7, and the folder in item 17.

### 2. [x] `suggest_straightening` hands `straighten` an angle it refuses

`core_engine/src/deskew.rs:237-240` filters the coarse scores to `|tilt| <= MOST_TILT`, but the
loop above only ever pushed tilts in that range - the filter filters nothing. The refine step
then searches `peak ± 1.0`, so the answer can leave the range, and `straighten` refuses it.
Measured against the tests' own `crooked_page` fixture:

```
tilt   9.90 -> suggested  -9.900003   accepted
tilt  10.00 -> suggested -10.000004   REFUSED
tilt  10.50 -> suggested -10.500006   REFUSED
tilt  11.00 -> suggested -11.000008   REFUSED
```

In `ffi/src/lib.rs:253-256` that `?` fails the whole page, deterministically: Retry gives the
same answer, relaunch gives the same answer. That is the one thing
[`ffi/AGENTS.md`](./ffi/AGENTS.md) forbids - "resuming would retry that same photo for ever".

- **Removes:** net −1 line (the dead filter goes, the answer is clamped at the return), plus a
  whole class of unfinishable scan. Makes measure/act true by construction instead of by hope.
- **Costs:** nothing. The existing tests only cover 3.0°.
- **Check:** `cargo test --workspace`, with one more case at 10.5° beside
  `crooked_writing_is_measured_from_the_writing_itself`.

### 3. [x] `composed` moves off the screen and onto `Engine.Adjustments`

`ScanFlow.swift:400-416` is `nonisolated static func composed` - pure arithmetic over
`Engine.Adjustments` (the quarter-turn map `(x,y,w,h) -> (1-y-h, x, h, w)` and the nesting of a
new cut inside a stored one) sitting on a View, reached from another screen at
`AdjustView.swift:274`.

- **Removes:** the `nonisolated static` on a View, one cross-screen dependency, and the
  four-line apology at `ScanFlow.swift:397` explaining why a screen exposes a static.
- **Gains:** `ios/check/run.sh` compiles `Scan.swift + Engine.swift` alone, so the app's only
  real arithmetic becomes checkable in two seconds. Today no check reaches it.
- **Costs:** ~16 lines move. `Engine.swift` must stay free of the bridging header, which pure
  arithmetic is.
- **Check:** `bash ios/check/run.sh`, plus one round-trip case in `check/main.swift`.

### 4. [ ] The PDF gets a home on `Scan`

`try? FileManager.default.removeItem(at: scan.pdf)` appears at `ScanFlow.swift:251, 307, 455,
524`, three of them with their own comment saying the same thing: the PDF is derived, so
anything that touches a page invalidates it. `Scan` already owns `delete()`, `deletePhotos()`
and `deleteState()`. The PDF is the one file the model does not delete, and "finished" is
spelled twice - `Scan.swift:103` and `ScanFlow.swift:691`.

- **Removes:** four copies plus three comments, one direct `fileExists` out of the router, and
  one of the two spellings of finished. After it, `ScanFlow` names `FileManager` only for the
  share hard-link, which really is the screen's business.
- **Costs:** two small members on `Scan`.
- **Check:** `bash ios/check/run.sh` - and it can then watch "Change pages unfinishes a
  finished scan", which no check sees today.

### 5. [ ] The done screen gets a file

`ScanFlow.swift:503-681` plus `OutlineStyle:701-718` is a whole screen - name field, share
link, PDF reader, photos block - living inside the router, while every other branch of the same
switch is its own file. It drags six of `ScanFlow`'s twenty-one state properties in with it
(`name`, `naming`, `focusTaken`, `shareCopy`, `confirmingPhotos`, `reading`) - a keyboard and a
share sheet, not a scan.

- **Removes:** ~215 lines and six state properties from the router, and makes
  `ios/AGENTS.md:121` true again ("ScanFlow owns one piece of view state that decides a
  screen" - today three do).
- **Costs:** a 215-line move. Nothing new is introduced: `DoneView.swift` with values in and
  `onChangePages` / `onDeletePhotos` out is exactly the shape `PagesView` and `AdjustView`
  already have. Every comment moves with its code and none is shortened.
- **Check:** `bash ios/check/scan_check.sh` - the only check that compiles a screen.

### 6. [ ] One button style

The design system has one `Button` with four variants and one rule: "Outlined, never filled"
(`components/core/Button.jsx:11`). Swift writes that recipe - heading face, tracking,
`buttonPaddingY/X`, `touchMin`, `radiusMd`, hairline stroke - in eight places behind two nearly
identical `ButtonStyle` structs: `ScanFlow.swift:701` `OutlineStyle`, `PagesView.swift:366`
`SecondaryStyle`, and six inline copies (`PagesView:272`, `ScanList:119`, `CameraView:156` and
`:190`, `AdjustView:467` and `:584`). They have already drifted: the two in `AdjustView` use no
`buttonPaddingY` at all, and three of the eight are **filled**, a variant the source of truth
does not have.

- **Removes:** two `ButtonStyle` structs and six inline copies of the same decision. Thirteen
  copies of `Token.Face.heading(Token.Size.textControl)` become one.
- **Costs:** **Julian's call first.** Adopting one style forces the outlined answer on Make PDF,
  the empty state's New scan and the chosen tool chip. That is what the design system says; it
  is still a visible change and it is his to approve. The tool chip has a delivered component of
  its own (`ToolStrip.jsx`) that is transparent with an accent underline, not a filled pill.
- **Check:** `bash ios/check/scan_check.sh` builds the app; nothing checks how it looks.

### 7. [ ] Strike what the docs say that the code no longer does

Each is one line. All verified against the code today.

- ~~`design/AGENTS.md:10`~~ - done by 50242b2 and 443f878: the stylesheet it pointed at is gone
  and the row that taught its naming scheme went with it.

- `ios/AGENTS.md:5` - "the **two** C functions in `../ffi`". There are four.
- `ios/AGENTS.md:110-119` - the screens diagram draws four branches. The switch has six; the
  takeover and Adjust are missing.
- `ios/AGENTS.md:121` - "one piece of view state that decides a screen". Three do:
  `shooting`, `applyingAll`, `adjusting`. (Item 5 makes this one true instead.)
- `ios/AGENTS.md:220` - "`makePDF()` is the one deliberate exception". There are three:
  `makePDF`, `everyPage` and `refresh`'s grey line.
- `TASKS.md:534` and `:541` - "Corners are fractions 0…1 of the photo". They are pixels:
  `Engine.swift:31`, `Scan.swift:155`, `ffi/AGENTS.md`, `freepdf.h:41`.
- `user-flows.md:291` - the copy table says "Choose a page". The app, the component and the
  story all say "Go to page" (`PagesView.swift:179`, `PageStrip.jsx:88`). The German pair goes
  with it. The copy tables are where the app reads its words from, so this one line is wrong in
  the one place that is meant to be right.
- `user-flows.md:255` and `:333` - both still route to Adjust through the `⋯` menu. Task 24
  gave it its own control. Correct by cutting the "⋯ →", not by adding a paragraph.
- `client-guide-design-system/tokens.md:13` - says every number a client may use is "Taken from"
  `design/gallery/_ds/classical-…/styles.css`. That is the retired classical theme, and it is now
  the only thing in the repo naming that folder (item 17). The truth is `design/system/tokens/*.css`.
- `TASKS.md:171` - "the five stories in `storybook/stories/Screens.stories.jsx`". Item 1 deleted
  that file; the flow stories are what shows those screens now.
- `TASKS.md:156` and `:160` - tasks 3.3 and 3.4 are titled `PagesScreen.jsx` and `AdjustScreen.jsx`,
  both deleted by item 1. Both tasks are done, so this is a title pointing at a gone file.
- `design/system/readme.md:225-278` - lists 18 components; there are 22. `PageStrip`,
  `ToolStrip`, `PageHandles` and `Sheet` are missing, so a future client agent builds a kit with
  no rail and no handles. `:168` still teaches "Disabled is 45% opacity", which
  `tokens/colors.css:33` marks retired.
- `TASKS.md:12` - "Open the `.dc.html` documents in a browser - they render." They do not: all
  seven load `_ds/freepdf-design-system-…/_ds_bundle.js` and that folder is gone. Point at
  `design/flows/shots/` and Storybook instead.
- `ios/check/run.sh:2` says "Ten moments"; `check/main.swift:2` says twelve. There are seventeen
  numbered sections. Both headers still say "milestone 3", and the file long ago stopped being
  only about resume. `ffi/bridge_check.sh` numbers two different sections `5c`.
- `ffi/src/lib.rs:9-10` - "**one** read-only struct". Two cross now, and the second is written
  to. `ffi/AGENTS.md` already says it correctly.

### 8. [ ] `Scan.numbers`

"Every number this scan has ever had" is written four times in three spellings:
`Scan.swift:297`, `Scan.swift:100`, `ScanFlow.swift:272` and `:693`
(`Array(Set(photos + pages)).sorted()`). `ios/AGENTS.md:86` already describes the concept in
prose.

- **Removes:** three spellings of one concept; `nextPage` reads `(numbers.max() ?? 0) + 1`.
- **Costs:** none. `ScanFlow.numbers:449` stays as it is - it reads the cache on purpose.
- **Check:** `bash ios/check/run.sh`.

### 9. [ ] `FakeShoot` returns the failure kind instead of a sentence to sniff

`FakeShoot.write` (`FakeShoot.swift:43-59`) knows which kind of failure it had, returns a
sentence, and `CameraView.say:259` works the kind back out by calling `FakeShoot.isDrawFailure`,
which is `hasSuffix("could not be drawn.")`.

- **Removes:** `isDrawFailure`, and the coupling where editing a copy-table sentence silently
  sends a failure to the wrong screen. The sentence still comes from one place and is still
  printed unchanged.
- **Costs:** ~6 lines changed in a file that only the check reaches.
- **Check:** `bash ios/check/scan_check.sh`.

### 10. [ ] `photoCount()` beside `pageCount()`

`"photo\(n == 1 ? "" : "s")"` is written at `Scan.swift:139`, `ScanFlow.swift:617` and `:621`.
`pageCount(_:)` at `Scan.swift:13` is the shape to copy, and `ios/AGENTS.md:344` already claims
this plural is not duplicated.

- **Removes:** three ternaries, and makes that sentence in AGENTS.md true.
- **Check:** `bash ios/check/run.sh`.

### 11. [ ] `sharpen`'s `threshold` parameter becomes a const

`core_engine/src/tools.rs:56`. All seven call sites in the repo pass `0` - `ffi/src/lib.rs:267`
and `:377`, `backend-core-runner/src/main.rs:227`, four in `tests/engine.rs`. `user-flows.md:406`
gives the user a radius slider and nothing else. It is a knob on the public API nobody has ever
turned.

- **Removes:** one parameter from the engine's contract, seven literal zeros, and the doc lines
  that describe it. Reversible in one line the day a second value exists.
- **Check:** `cargo test --workspace`, `bash ffi/bridge_check.sh`.

### 12. [ ] Delete `Tag`

`design/system/components/core/Tag.jsx` + `.d.ts` + `.prompt.md`, its export in `storybook/ds.js`
and `stories/Tag.stories.jsx`. No flow draws it, no kit screen uses it, no story but its own
renders it, and the app has no chip anywhere. `design/system/readme.md:257` gives its reason for
existing: the radius-sm chip "exist[s] in tokens.md with nothing to put [it] in" - a component
invented to give a token a home, which the same readme forbids two lines later.

- **Removes:** five files. `--radius-sm` stays; `PagesView.swift:235` uses it for the rail tiles.
- **Check:** `npx storybook build`.

### 13. [ ] Delete `storybook/.storybook/preview.jsx`

Two preview files exist; Storybook loads `preview.js`. I built it and grepped the output:
`iPhone (390x844)` is in the bundle, "Light or dark ground" is nowhere. The Light/Dark toolbar
and the `data-theme` switch in `preview.jsx` have never run.

- **Removes:** 40 dead lines, and the reason `storybook/README.md:13` and every "Done when …
  light and dark" in TASKS.md are false.
- **Costs:** if the theme toolbar is wanted, that is a feature - fold its 20 lines into
  `preview.js` and say so. Either way one file goes.
- **Check:** `npx storybook build`.

### 14. [ ] `pdf.rs`: the document's name written once

`core_engine/src/pdf.rs:53-57` and `:139-143` are byte-identical: the `file_stem` title and its
`"FreePDF Document"` fallback.

- **Removes:** 8 lines for 4. It continues the file's own habit - `place()` exists so the fit
  maths is written once, `failed()` so the write sentence is.
- **Check:** `cargo test --workspace`.

### 15. [ ] `freepdf_suggest_adjustments`'s `values` parameter is called `sheet`

`ffi/include/freepdf.h:48` takes the whole 24-value `FreepdfAdjustments`, but only `corners` and
`pull_the_sheet_flat` are read (`ffi/src/lib.rs:297-302`, where it is already named `chosen`).
The header uses the same word, "values", that means "everything the user set" everywhere else.

- **Removes:** a reader wondering whether the sharpen radius he passed changed the answer. Safe:
  C arguments are positional and Swift imports these without labels.
- **Check:** `bash ffi/bridge_check.sh`.

### 16. [ ] Strike the crop error that cannot happen

`ffi/src/lib.rs:402` says "`crop` still refuses a box that is genuinely impossible". It cannot:
`crop_box` clamps every edge (`at.min(size)`, then `long.min(size - at)`), so no box reaching
`crop` is ever outside the image. `user-flows.md:383` therefore lists a sentence - "Crop refused
| The crop falls outside the page." - with no producer anywhere, and no Swift file has it.

- **Removes:** one false comment and one dead copy-table row. The clamping stays; it is correct.
- **Check:** `bash ffi/bridge_check.sh`.

### 17. [ ] Delete the last root of the classical theme

Item 1 deleted the frozen copy under `design/system/`. The older one is still there:
`design/gallery/_ds/classical-fee6c86c-b348-4033-b8e7-e8f35de9f737/` - `_ds_bundle.js`,
`styles.css`, `readme.md`, `_ds_manifest.json`, `_adherence.oxlintrc.json`. Nothing loads it:
`design/gallery/FreePDF Components.dc.html` names only `./support.js`, which exists. One line in
the whole repo points into it, `client-guide-design-system/tokens.md:13`, and it points there for
provenance - "Taken from" - not to be read.

- **Removes:** the second frozen stylesheet, and the last place an agent can find a colour that
  no client uses. After it, `design/system/tokens/*.css` is the only stylesheet in the repo that
  decides anything.
- **Needs a decision first:** `tokens.md` is the client guide, and its numbers were copied from
  that file. Either the numbers are re-sourced against `tokens/*.css` (they may have drifted -
  the guide's own preface says the table and the pictures never agreed) or the provenance line is
  cut. That is Julian's call, and it is why this is not part of item 7.
- **Check:** `npx storybook build`; `grep -rn classical-fee6c86c .` returns nothing.

## Considered and rejected

Do not re-propose these. Each was checked and each adds without removing.

- **A view model or `ObservableObject` for `ScanFlow`.** It would become the second truth the
  whole storage model exists to avoid.
- **A `Snapshot` struct for the six cache properties.** Collapses six lines, adds a type,
  removes no decision.
- **A protocol over `Engine`, or a `ScanStore` repository over `Scan`.** One implementation, one
  caller, and the store would put a second truth between the screens and the disk.
- **One shared progress view for the drain and the takeover.** They look alike and promise the
  opposite: the drain resumes after a kill and says so, the takeover cannot and says so.
  Merging them needs a flag that means "can this be killed", which is the difference itself.
- **A generic "run the engine, catch, show" wrapper.** Seven one-line catches, seven different
  sinks. A helper adds indirection and deletes nothing.
- **Merging `retake` / `deletePage` / `shootAnother`.** Three different orders, three different
  kill-safety arguments.
- **Collapsing `scan_page` into `suggest_adjustments` + `adjust_page`.** It is arithmetically
  redundant - I checked, and `freepdf_adjust_page(photo, suggestion.values)` comes back byte for
  byte identical to `freepdf_scan_page(photo)`. But it would decode and resample every photo
  twice, roughly doubling the drain cost per page, on the one screen where the user watches a
  40-page bar. What is missing is not a refactor but one line of guard: nothing asserts those two
  files are identical, so the copies can drift in silence. Add that `assert_eq!` beside the
  existing test in `ffi/src/lib.rs`, or compare the two files `bridge_check.sh` already writes at
  `:106` and `:212`.
- **A `write_atomically` helper over `save_page` and `pages_to_pdf`.** Same promise, different
  mechanics - one has the bytes in hand, the other must catch printpdf swallowing a write error.
- **Splitting `tools.rs` into one file per tool, or `deskew.rs` into perspective and tilt.**
  Five files replacing one deletes nothing, and `straighten` is built on `deskew`.
- **A `trait Suggester` or `enum Tool` over the three measure/act pairs.** An abstraction over
  three implementations that are three lines each.
- **`thiserror`, an error enum, or error codes.** The String is the contract; a typed error
  needs a renderer and the sentence would then live in two places.
- **A fifth C function** for `sizeof`, a version, or `freepdf_last_error`. Four functions is the
  design, and the existing preconditions already catch a shifted field.
- **A `Corners` value type for the 8-float array.** Every constructor is in this repo and
  produces 8; the type costs more reading than the risk it removes.
- **Making `Adjustments` `Codable`** to delete `writeState`/`readState`. It would delete ~50
  lines, but a field rename would then silently change the on-disk format instead of loudly
  changing an order. Worth doing the day a field is added to `Adjustments`, not to be tidy.
- **Deleting `Rect` and `Paper::bounds`.** They look dead from the phone;
  `backend-core-runner/src/main.rs:171` uses them for `--auto-crop`.
- **Turning the `Camera` class into an actor, hoisting its photo settings, or merging its two
  delegate callbacks.** Every line there is a header citation and a bug that already happened.

## What is already right - propose nothing here

`Scan.swift` is the best file in the app: a struct wrapping one URL, every read a fresh
listing, nothing cached. `refresh()` as the single place the screen layer learns anything.
`write()`'s page-then-sidecar order and its detached task - the whole kill-safety argument.
`EngineCalls.call()`, six lines, caller-owned buffer, the sentence thrown unchanged.
`guard`/`catch_unwind` on every C entry point. `crop_box`'s clamping. `bridge_check.sh` and
its `precondition`-never-`assert` rule. `AdjustView`'s two gates. The
`tokens/*.css → build-tokens.mjs → Tokens.swift` pipeline, which has no drift at all. And the
long dated comments everywhere: they are the only record of why the code is shaped this way. A
refactor that moves code carries its comment with it, and no refactor shortens one.
