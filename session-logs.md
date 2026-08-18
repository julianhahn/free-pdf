# Session logs

One entry per session, newest first, written before the work is called finished. What
changed and what the next person needs to know - not a diff, git has that. Three to six
lines is the size.

This file is the past. The future is [`README.md`](./README.md) under **Next steps**, and
both get updated in the same commit as the work
([`AGENTS.md`](./AGENTS.md#every-session-ends-in-these-two-files)).

## 2026-08-18 - The viewfinder shows the last page photographed

TASKS.md 35. [`ios/FreePDF/CameraView.swift`](./ios/FreePDF/CameraView.swift) keeps one
`latest` URL, set in `landed()` after a shot that is not a retake, and draws it with the
existing `PageImage` at `maxPixels: 200` in the top trailing corner of the preview: no second
decoder, no page made, nothing tappable, hidden from VoiceOver because the counter already
says the number. Nothing shows before the first shot of the session - a resumed scan starts
blank, and a retake never shows it. New token `--camera-thumb-w:56px` in
design/system/tokens/controls.css, Tokens.swift regenerated. `user-flows.md` DECISIONS 10 is
now "built", not "skipped", and section 4 step 3 says it; task 6's "no corner thumbnail" is
gone. No Xcode here, so the Swift change is unbuilt: scan_check, run.sh, bridge_check and
cargo test are green and the phone pass is left for Julian.

## 2026-08-18 - After the first photo, the app shows what it is about to do

TASKS.md 34. New screen [`ios/FreePDF/FirstPageCheck.swift`](./ios/FreePDF/FirstPageCheck.swift):
the photo small beside the page the engine really makes of it, large, and two ways out -
**Scan this page again** (the existing `ScanFlow.retake`) or **Photograph the rest**. The
camera calls the new `onFirstPhoto` when the scan's photo count is one and the shot was not a
retake, so it happens once per scan and never on a resumed one; the flag is in memory only, so
a kill on this screen leaves one photo and no page and the relaunch shows the viewfinder. The
preview is a real `freepdf_scan_page` run into a file in the temporary directory, so `sweep()`
is untouched and the drain still writes every page. `-autofake` writes its photos without
going through `landed()`, so `scan_check.sh` never sees the screen and needed no change.

## 2026-08-18 - Shooting another page never stopped after one, and the check now says so

TASKS.md 33. The reported bug could not be reproduced, and the reading in the task turned out
right on every point: `shootAnother()` sets `slot = nil`, the one-shot `finished()` in
`landed()` belongs to a retake only, and nothing in `ScanFlow` tears the camera down by
itself. So `scan_check.sh` grew the missing coverage instead of the camera growing a fix:
`-autofake-more 3` presses Shoot another page on the finished scan and then the shutter three
times, one press at a time, and the run ends with fifteen pages and a rebuilt PDF. The new line was proved by mutation: ending the screen after every shot aborts it at thirteen pages. Julian's
report is from the era when that control still sat in the "…" menu (before task 32); the only
candidate left that a simulator cannot see is the app being killed for memory on the second
shot, which would also land him back on the pages screen.

## 2026-08-18 - Adjust and Shoot another page are controls, not menu items

TASKS.md 32. `PagesView` now draws both under the carousel, in the same place for every page:
Adjust page, disabled where the photo is gone, and Shoot another page, disabled until every
photo has a page. The "…" menu lost both entries and keeps retake and delete, so no action has
two ways in. Nothing appears or disappears - the dead look is the `--disabled-*` role. Corrected
alongside: task 24's sentence that let Adjust stay in the menu, `user-flows.md` section 6, the
flow 5 document and the copy tables' "Menu item" labels for the two words.

## 2026-08-18 - a sheet that leaves the frame is cut anyway, and the page says so

TASKS.md 31. `scan_page` in `ffi/` lost its `if !sheet.runs_off_the_picture()` guard, so the
automatic run now straightens on the corners it found whatever they are - the same thing Adjust
already did with the corners it sends. `runs_off_the_picture` stays a true report about the photo
and is no longer a veto; the runner deskews too, and only prints what it means. `PagesView` asks
`Engine.suggest` for the page on screen - one run, re-keyed by the swipe, nothing stored - and
puts a calm note under a page whose sheet ran off, with the existing "Scan this page again"
below it. Cost: a sheet crossing a frame corner at an angle comes out slightly sheared; the note
plus the retake is what pays for it. The twelve phone photos were re-run: eleven byte for byte
as before, `runs_off_1.jpg` now cut from 3024x4032 to 2558x3515.

## 2026-08-17 - the sheet is found by its edges now, so the cut works on a lit desk

TASKS.md 29. `find_paper` keeps the whole brightness pipeline, but only as a rough guess: from
inside it a ray marches outward along every row and column until it crosses a real paper-to-table
step, a line is fitted through those places per side, and the corners are where the sides cross.
Sheen cannot steal a corner any more because a corner is no longer a pixel of the mask, and the
mask is the quadrilateral **and** the rough area, so neither can claim what the other calls
table. The two are checked against each other both ways round: a quadrilateral reaching out onto
the table is wrong, and so is one that abandons the sheet, which is what a hand or a pen lying
across the page and out onto the table caused - it is dark, it reaches the frame through the
table, so the rays stopped on it, they were the majority of that side, and the page came out cut
short. Two numbers catch that, and each is needed for a case the other misses: how much of one
side's length has paper carrying on past it, and how much of the bright area the shape keeps.
Every new way to fail falls back to the old blob answer; `None` still comes from exactly the two
places it did before, because one `None` stops a whole automatic run. Four new synthetic tests,
`a_patch_of_sheen_beside_the_sheet_is_not_part_of_it` (it fails on the old code with the
corner at the frame's edge, which is the bug),
`a_page_that_fills_the_frame_is_still_one_whole_sheet` (the fallback, which only
`bridge_check.sh` covered), `a_dark_thing_lying_on_the_page_does_not_shorten_it` and
`a_dark_bar_right_across_the_page_does_not_halve_it` - each of the last two fails if its own
guard is taken out. Judged by painting the mask over twelve real photos and looking:
all twelve come out cut to the sheet. Each side leans a little off the fitted line on purpose
(`INWARD_BIAS`, turned inward on 2026-08-18 - see that day's entry).

## 2026-08-18 - a scan of one page could not be finished

Task 34's check screen has two ways out on purpose: shoot this page again, or photograph the
rest. Julian, on his phone: a document of one page cannot be finished at all. Both ways out
lead back to the camera, and the footer that scans - the only control that ends a scan - is
not on this screen. A receipt was a dead end.

His decision: three ways out. **Scan 1 page**, in the camera footer's own words for one page,
reaching the same end that footer reaches. No new path, no second retake, and Photograph the
rest stays the normal answer.

The check harness could not see this, because `FakeShoot.autoShoot` writes its photos
straight to disk and never goes through `CameraView.landed()`, so the check screen never
appeared in it at all. `-autofake-one` now shoots once through the screen's own shutter and
then presses that screen's Scan 1 page, and `scan_check.sh` says "one page scanned from the
check screen". Proved by mutation: pressing Photograph the rest there instead ends the run
with "a one page scan could not be finished from the check screen".

Also today, and the reason Julian saw the old edge behaviour after the bias was turned
inward: the iOS client links the prebuilt Rust static library out of `target/`, and it was
three hours older than the change. `ffi/build-ios.sh` after an engine change, or the phone
runs yesterday's engine.

## 2026-08-18 - the cut leaned the wrong way, and Julian saw it

Task 29 pushed every fitted side half a pixel of the shrunk copy **outward**, reasoning that
swallowed desk only bends a straightening while lost paper loses writing. On a real phone that
came out as a hair of desk along all four sides of every page - Julian's words: "each corner
overshot by a few pixels, so I always have a slight border of the table". A 400 pixel wide
working copy against a 3024 pixel photo makes one working pixel 7.6 real ones, so the bias plus
the rounding is 4 to 11 pixels of desk per side.

Julian's decision: turn it inward, and rename it, because the name carried the old reasoning
(`OUTWARD_BIAS` -> `INWARD_BIAS`, `core_engine/src/paper.rs`). The sign is the whole change. What
pays for it is the white margin a sheet of writing carries at its edge - inward costs those
pixels and nothing that is in them.

Measured on the thirteen photos in `test_images/phone/`: every page lost 14 to 22 pixels of
width, and the outer band of each page got brighter with fewer dark pixels in it - desk leaving,
not content. Worst case before, `sheen_1`, went from a quarter of its outer band dark to under a
tenth. Two photos (`extra_4`, `sheen_7`) still carry about a tenth, so a stronger bias is the way
up if Julian still sees desk on a phone. `runs_off_1` is unchanged, as its lower corners come
from where the paper leaves the frame rather than from a fitted side.

## 2026-08-17 - the automatic cut has never worked on a lit desk, and why

Julian's pages come out uncut. `find_paper`'s mask leaks onto reflections on the desk, and
`Paper::corners` is a global extremum over that mask, so a sheen patch in a frame corner
steals that corner - `(3020,4028)` of a `3024x4032` photo. `runs_off_the_picture` is
therefore true and rightly refuses: unbeschnitten but complete beats bent. Two small fixes
were tried and both reverted, `bb66350`/`1e9b254` and one before it that got as far as
cutting content out of a page - measure the mask by *looking* at it, not by counting border
pixels, or you will fix the wrong thing twice. The way up is TASKS.md 29, following the
sheet's edges, which the `ponytail:` note in `find_paper` has named since the first commit.
Seven real photos are the evidence and stay out of the repository; `test_images/` is
gitignored for that reason.

## 2026-08-17 - the typed name is the scan's name

TASKS.md 28. The done screen's name field no longer throws the name away: `Scan.writeName`
puts it in the scan's folder as `name.txt` (`.part`, then rename), `Scan.name` reads it and
`Scan.title` prefers it over the folder date. `ScanFlow` does the write, as it does every
file move, and the field opens on what is stored - clearing it deletes the file and the date
comes back. One sanitiser, `Scan.sanitised`, for both the share sheet's copy and the row.
`sweep()` keeps `name.txt` and takes `name.part`. Six new blocks in section 15 of
`ios/check/main.swift`, two of them mutation-tested. `user-flows.md` 9, 10 and DECISIONS 8
and `ios/AGENTS.md` said the name was for the shared copy only; those sentences are replaced,
not extended.

## 2026-08-16 - the loop closes, and the map is true again

Last iteration of the architecture loop. `ARCHITECTURE.md` items 9, 11, 12, 13, 14, 15 and 16
are ticked; the picture says 21 components, not 22, and now names `Engine.swift`, which item 3
turned into the app's only checkable arithmetic. Three dangling pointers the loop created are
gone: `ios/AGENTS.md:452` named the deleted `FakeShoot.isDrawFailure`, `storybook/README.md`
pointed at the deleted `.storybook/preview.jsx` and promised a Light/Dark toolbar that item 13
proved never ran. In `ffi/src/lib.rs` the last `values` binding inside `suggest_adjustments`
became `chosen`, finishing item 15 in the one place it mattered.

Two items were refused today with reasons, and both refusals are written into their entries so
nobody re-proposes them: item 8's `Scan.numbers` property adds a fourth spelling rather than
removing three, and item 16's "Crop refused" copy row is drawn live by `PageHandles.jsx`. Two
new items were raised from what the verifiers found - 19, the eight flow specimens loading a
bundle that has never been in git, and 20, a registered worktree holding a pre-item-5 copy of
the app that repo-wide grep cannot tell from the real one.

A new closing section, **Where this loop stopped**, holds the handover: item 6 is the only
thing blocked, and the question is whether Julian wants three filled buttons to go outlined.
It also records the biggest hole in the checks - nothing asserts which sink an error sentence
reaches, so `scan_check.sh` prints "scan ok" even when a failure is routed to the wrong screen.

## 2026-08-16 - four things the engine and its boundary stopped carrying

`ARCHITECTURE.md` items 11, 14, 15 and 16. `sharpen` lost its `threshold` parameter: all seven
callers passed zero, so it is `SHARPEN_THRESHOLD` in `tools.rs` now and reversible in one line.
`pdf.rs` works the document's name out in `title_of()` instead of twice. At the C surface,
`freepdf_suggest_adjustments`'s second argument is `sheet` and not `values` - only the corners
and their switch are read, and the header says so on both sides; C arguments are positional, so
no caller changed. And `crop_box`'s comment stopped promising that `crop` still refuses an
impossible box: it clamps both ends, so nothing it returns can be refused.

**Refused:** striking the "Crop refused" row from `user-flows.md:383`, which item 16 asks for.
It has no producer in the engine, but it is not dead copy: `PageHandles.jsx` draws a `refused`
state, `PageHandles.stories.jsx:55` and `:68` and `Flow6Adjust.stories.jsx:253` render it, and
two `design/flows/*.dc.html` name it as the placeholder they used. That row is where its German
lives. Whether the component keeps a state the app cannot reach is a design-system question, not
a line to delete on the way past.

`cargo test --workspace` 38 + 3 + 5 passed, `bridge ok`, and the Swift typecheck clean.

## 2026-08-16 - the stand-in says which failure it had, instead of a sentence to sniff

`ARCHITECTURE.md` item 9. `FakeShoot.write` knew which of its two failures it had and threw
that away, returning a sentence; `CameraView.say` got the kind back out with
`FakeShoot.isDrawFailure`, which was `hasSuffix("could not be drawn.")`. So a copy edit in
`ios/AGENTS.md`'s error table would have sent a failure to the wrong sink in silence. `write`
and `autoShoot` now return `FakeShoot.Failure` - `.notSaved` for a page that missed the disk,
`.notDrawn` for the one failure that is about the screen - and `say` switches on the kind. The
sentences are unchanged, still written in one place, still printed as they are; `isDrawFailure`
is gone. Left for whoever owns the docs: `ios/AGENTS.md:452` still names `isDrawFailure`.
`resume ok`, `scan ok`, and the typecheck clean.

## 2026-08-16 - the chip nothing draws and the preview file nothing loads

`ARCHITECTURE.md` items 12 and 13. `Tag` is gone - `Tag.jsx`, `.d.ts`, `.prompt.md`, its story
and its `ds.js` export. `<Tag` appears nowhere in the repo but its own `.prompt.md` example: no
flow, no kit screen, no card, and no chip in the app. The readme's census is 21 rows and says 21,
and the "intentional additions" bullet that paired it with `SectionLabel` now names only
`SectionLabel`. `--radius-sm` stays - `PageCounter.jsx:13`, `PageHandles.jsx:87` and
`PagesView.swift:235` use it.

`storybook/.storybook/preview.jsx` is gone, proved by building before and after rather than by
reading the config: `Light or dark ground`, its theme toolbar's own string, is in neither bundle,
while `preview.js`'s `iPhone (390x844)` is in both. The two builds' story lists differ by exactly
one line, `Core/Tag`. Left standing on purpose: `storybook/README.md:28` still says the stylesheet
is loaded in `preview.jsx`, and `:15` still promises a Light / Dark switch - both were already
false before this commit, and that file was not mine to edit. `ARCHITECTURE.md:52` and
`design/claude-design-flows-prompt.md` still count the old components; the prompt is a dated brief
for a round that is finished, the picture is a later agent's line.

## 2026-08-16 - items 4, 5 and 7 are ticked, and the last false lines go with them

`ARCHITECTURE.md` items 4, 5 and 7 are `[x]`. Item 7's document half had landed (a855f8b); its
other half - the code's own comments - is in this commit: `ios/AGENTS.md` said two C functions
(four), drew four screen branches (six: the takeover and Adjust were missing), claimed one piece
of view state decides a screen (three do: `shooting`, `applyingAll`, `adjusting`) and named
`makePDF()` as the one listing exception (`everyPage()` is the second - `refresh`'s grey line
reads state files, it lists nothing, so item 7's "three" was itself wrong). Both check headers
said "milestone 3" and counted ten and twelve moments where there are seventeen sections;
`ffi/src/lib.rs:9` said one struct crosses where two do; `bridge_check.sh` numbered two sections
`5c`. Three more were found on the way and struck with them: `TASKS.md:214`'s phone frame at the
deleted `Screens.stories.jsx`, and in the client guide the `accent-2` sentence (that token lives
only in the retired classical stylesheet) and the shutter row (2 px accent ring and a 4 px gap,
not "1 px divider border … 1 px accent ring", per `controls.css` and `Shutter.jsx`).

The picture caught up with the tree: `ios/` is thirteen files, the done branch is `DoneView` and
no longer "the only screen with no file", `Scan` owns the deletes including `scan.pdf`, and
`DoneView`'s share hard-link is named as the one file a screen makes itself. Items 6, 8 and 10
had anchors pointing into the moved code and now point at `DoneView.swift`. Items 4 and 5 carry
what was refused with them: `retake` and `deletePage` still name `FileManager` in the router, and
`focusTaken` stayed behind as a `Binding`. Item 17 lost its blocker - nothing outside the folder
names the classical theme any more - and one new item 18 went on the list: `README.md`'s Next
steps row 3 still says tasks 19 to 23 are unbuilt. Only comments were edited inside the checks;
no assertion was touched. `resume ok`, `bridge ok`, `cargo test --workspace` 46 green.

## 2026-08-16 - the done screen is a file, like every other screen

`ARCHITECTURE.md` item 5. The finished screen - name field, Open PDF, Share PDF, Change
pages, the photos block, the reader sheet and `OutlineStyle` - lived inside `ScanFlow`, which
is a router. It is `FreePDF/DoneView.swift` now, the same shape `PagesView` and `AdjustView`
have: `pdf`, the photo count and what the photos cost go in, `onChangePages` and
`onDeletePhotos` come out, and `ScanFlow` still makes every file move. Nothing was rewritten
and no comment was shortened; `ScanFlow` is 238 lines shorter and no longer imports PDFKit.

One of the six state properties could not move: `focusTaken`. `Change pages` destroys the
done screen and Make PDF builds it again, so `@State` over there would raise the keyboard a
second time over a screen the user came back to read - a behaviour change. It stays in
`ScanFlow` and goes back as a `Binding`, the way `PagesView` takes `showing`. Five moved.

Two claims from item 5 are still not true and were left alone rather than written down:
`ios/AGENTS.md:121` ("one piece of view state that decides a screen") - `shooting`,
`applyingAll` and `adjusting` still decide screens, and moving a screen out did not change
that, so it stays item 7's line. And `ios/` is thirteen Swift files now, not the twelve
`ARCHITECTURE.md:19` draws; item 6 also points `OutlineStyle` at `ScanFlow.swift:701`, which
is `DoneView.swift` now.

## 2026-08-16 - the docs stop describing an app that is gone

`ARCHITECTURE.md` item 7, the four documents that are not code: `TASKS.md`, `user-flows.md`,
`client-guide-design-system/tokens.md`, `design/system/readme.md`. Every line was read against
the code first and then cut, never explained. The one that mattered: the copy table said
"Choose a page" where the app, `PageStrip.jsx` and the story all say "Go to page" - the copy
tables are where the words come from, so that was wrong in the one place meant to be right.
Its German pair, "Seite wählen", is left for Julian: no German for "Go to page" exists anywhere
in the repo and inventing one is his call, not mine.

`design/system/readme.md` listed 18 components and 22 exist. `ToolStrip`, `PageStrip`,
`PageHandles` and `Sheet` are in the table now, because a census that is short makes the next
client agent ship a kit with no rail and no handles. `tokens.md` pointed at the retired
classical stylesheet and at `storybook/styles.css`, which no longer exists; every table in it
was compared against `design/system/tokens/*.css` first - colours, ramps, type steps, spacing,
radii, shadows all agree - so it now names that one source. That was the last line in the repo
naming `classical-fee6c86c`, which unblocks item 17.

Two the list did not name and the code did: all five task 3 titles name a deleted
`*Screen.jsx`, not two, and task 3.3 still ordered "Adjust page" into the menu only, which
task 24 reversed and says is deleted, not argued with.

Left standing on purpose: `tokens.md`'s "Provisional, do not treat as approved" preface. Its
numbers are true, but whether they are *approved* is Julian's word, not a fact I can read off
the code. Docs only, no behaviour: `npx storybook build` passes unedited.

## 2026-08-16 - the PDF is a file the scan owns

`ARCHITECTURE.md` item 4. `try? FileManager.default.removeItem(at: scan.pdf)` stood four
times in `ScanFlow.swift` - Apply, the Grey switch, Shoot another page, Change pages - three
of them with their own comment saying the same thing. It is `Scan.deletePDF()` now, beside
`delete()`, `deletePhotos()` and `deleteState()`, and the shared reason is written once in
its doc; each call site keeps only what is about that site. "Finished" was spelled twice, a
`fileExists` in `Scan.state` and another in the router's `refresh()`; both read `Scan.finished`
now. Section 11 of `check/main.swift` stops building the after-state by hand and presses the
two buttons: the PDF is written, the photos deleted, then `deletePDF()`, and the scan has to
drop from `.done` back to `.ready` with its three pages intact. Mutated `deletePDF` to a
no-op and it aborts on "the PDF survived Change pages". Behaviour unchanged: `run.sh`,
`scan_check.sh` and the whole-app typecheck pass unedited.

Not true after this, so not written anywhere: item 4's claim that `ScanFlow` would then name
`FileManager` only for the share hard-link. `retake` and `deletePage` still remove a page and
a photo file directly, and moving those would add two members to `Scan` to delete three lines,
with a `Scan.deletePage` that deletes one file sitting beside a `ScanFlow.deletePage` that
deletes three. Left alone.

## 2026-08-16 - items 2 and 3 ticked, and the counts they moved

`ARCHITECTURE.md` items 2 and 3 are done and ticked; item 1's three leftover pointers are
recorded under it as struck. Two things item 2 left behind are fixed here: `README.md` still
listed the tilt bug under **Parked** and handed the next agent the fix as an instruction, so
that bullet is gone; and the workspace is 46 green on a Mac and 43 elsewhere now, not 45/42 -
moved in `README.md` and `core_engine/tests/AGENTS.md`, which is the file that states the rule.
Two new item 7 lines (`TASKS.md:156, :160, :171`, `client-guide-design-system/tokens.md:13`) and
one new item 17: `design/gallery/_ds/classical-…/` is the last root of the retired theme and
only `tokens.md` still names it. It needs Julian's call on the client guide, so it is an item,
not a strike.

## 2026-08-16 - the crop arithmetic sits on the values, not on a screen

`ARCHITECTURE.md` item 3. `composed` was a `nonisolated static` on `ScanFlow`, a View, and
`AdjustView` reached across for it - so the app's only real arithmetic lived on a screen and
no check could see it. It is now `Engine.Adjustments.composed(onto:)`, a method on the values
it was always about; both call sites read `values.composed(onto: stored)` and the note
explaining why a screen exposed a static is gone. `Engine.swift` stays Foundation only, so
`ios/check/run.sh` compiles it: `main.swift` section 17 now asserts a crop laid inside a
stored crop, a stored crop turned a quarter clockwise, and the first crop on a page with no
state. Behaviour is unchanged - `run.sh` and `scan_check.sh` pass unedited.

## 2026-08-16 - a page tilted ten degrees can be finished again

`ARCHITECTURE.md` item 2. `suggest_straightening` measured a coarse peak, then refined a
degree either side of it, so a page lying at the edge of the range came back past the range
and `straighten` refused it - `-10.500006` for a 10.5 degree page. In `ffi/src/lib.rs` that
`?` failed the whole page, and it failed the same way on every retry: the scan could never
finish. The answer is now clamped where it is returned, so measure and act agree by
construction. The filter above the peak went with it - it kept tilts inside a range the loop
never left. New test `a_page_tilted_past_the_limit_is_told_an_angle_straighten_takes`; it
fails on the old code with the engine's own refusal sentence.

## 2026-08-16 - the three pointers the deletion left dangling

Cleaning up after the frozen-copy deletion. `design/AGENTS.md` still sent every agent to
`gallery/_ds/<theme>/readme.md`, which teaches `var(--color-*)`; the live tokens are
`--accent-500`, `--bg` and so on, so that row was a second, incompatible source of truth in
the one table that names the first. Row cut. `Flow1Scans.stories.jsx` pointed its phone
frame at `Screens.stories.jsx`, which no longer exists - it is the frame the six other flow
stories copy, and now says so. `.storybook/main.js` lost the `chrome` ternary: it injected
an import into every kit `.jsx` that is not `Chrome.jsx`, and `Chrome.jsx` is the only one
left, so that branch could never fire. The window-global rewrite and the generated export
stay - the flow stories need both, and `npx storybook build` still resolves
`AppBar`/`Screen`/`StatusLine` from the Chrome chunk.

## 2026-08-16 - the design system exists once, not twice

`design/system/` held itself twice: the live `tokens/*.css` and 22 `.jsx` components, and a
frozen bundle from two weeks earlier that the specimen cards and the iPhone kit actually
loaded. The frozen half still wrote `var(--disabled-opacity)` (retired), had no `PageStrip`,
`ToolStrip`, `PageHandles` or `Sheet`, and its `AdjustScreen`/`PagesScreen` still showed the
two things tasks 24 and 26 reversed. Deleted: `_ds_bundle.js`, `_ds_manifest.json`,
`_adherence.oxlintrc.json`, the five `*.card.html`, the five `ui_kits/iphone/*Screen.jsx`,
`App.jsx`, `index.html` and `storybook/stories/Screens.stories.jsx` - 3,108 lines.
`ui_kits/iphone/Chrome.jsx` stays: the seven flow stories import `AppBar`/`Screen`/
`StatusLine` from it. `design/AGENTS.md` pointed at `gallery/_ds/<theme>/styles.css` as the
source of truth for every number; it now points at `system/tokens/*.css` and names
`build-tokens.mjs`. `ARCHITECTURE.md` item 1 is ticked; item 2 is next.

## 2026-08-15 - Adjust, and the engine learns to suggest

TASKS.md task 18. `ios/FreePDF/AdjustView.swift` is new and carries flow 7: the six tools one
at a time, no live preview, Apply one page or all with the takeover, and the skipped-pages
sentence. `freepdf_suggest_adjustments` is the fourth C function - it answers what the
automatic run would have chosen for one photo, so every control opens on the engine's own
value instead of a neutral default and "Back to the suggestion" means something.

Two traps closed on the way. The crop crosses the boundary as fractions 0…1 of the image the
engine holds right before cutting, not as pixels of the page file - a pixel box measured on
the old page cuts the wrong piece out of a newly derived one. And the levels keep their three
channels across the bridge; collapsing them to one put the colour cast back.

Julian's decision on the turn: it goes into the photo's EXIF orientation tag, because nothing
else on disk could hold it. That is a stopgap - `ios/AGENTS.md` says so - and task 22 takes it
back out once `state/NNNN.txt` exists.

Next: tasks 20 to 23, the page state file. A crop, a turn and a moved slider still die at the
next Apply.

## 2026-08-15 - the pages screen, drawn from the tokens and read from the cache

Task 17. `ios/FreePDF/PagesView.swift` is new and carries flow 5: the carousel with pinch
to zoom, the rail with its jump, the Grey switch, the Page menu, the delete question,
Retry on a refused page and Make PDF hidden until every photo has a page. `ScanFlow` keeps
the actions and the disk.

The trap Julian spotted is closed: nothing on this screen lists a directory while it
draws. `unscanned` and `finished` come out of the `@State` cache, the images decode in a
`.task`. `makePDF()` still reads the disk on purpose - the comment there says why.

Grey greys the screen only. The engine takes the flag through `freepdf_adjust_page`, which
the app does not call before task 18; Julian chose the display-only switch today.

## 2026-08-15 - the camera, and the screen-level sentence gets its own screen

TASKS.md task 15. `CameraView.swift` is flow 3 on the tokens: the dead shutter while the
photo is written (with its own spoken label), the counter naming the next page as a
principal toolbar item, the error line over the viewfinder for a page that missed the disk,
and the three cannot-work sentences as a takeover with no button - the split the old file
did not have, everything went into one small red line under the preview.

Two shared kit files caught up with the tokens they should have used (`Shutter`'s disc edge,
`Viewfinder`'s corner marks and note), and the generator learned two more shapes: an `em`
and a CSS ratio, so `--page-ratio` is `Token.Number.pageRatio` instead of a typed `3.0/4.0`.

Julian's call on the one missing sentence: the German for the dead shutter is
"Seite 7 wird fotografiert, warten". Three departures from flow 3 are written into
`ios/AGENTS.md` as his to overrule - the counter is a toolbar item not a title, no re-check
after Settings (changing the permission kills the app anyway), and the takeover has no body.

Green: typecheck, `scan_check.sh` "scan ok", `run.sh` "resume ok", `--check`/`--self-check`
"tokens ok", `npx storybook build`. The phone half of task 15 - five pages, force-quit while
aiming at six, relaunch, "Page 6" - and anything needing a real camera is still Julian's.

## 2026-08-15 - the scans list is the first screen built on the tokens

TASKS.md task 14. `ios/FreePDF/ScanList.swift` is the approved flows 1-2 screen: the pressed
row, the error line with its 2 px rule, the hand-built empty state with its own New scan
button, full-bleed rows with the divider hairline and the accent chevron, and the VoiceOver
strings copied out of the flow document. Every value is a `Token`; not one number is typed.

Two token bugs found on the way, both in `design/system/tokens/build-tokens.mjs`: a comment
that mentions a variable (`/* neutral-700 on --bg */`) was read as a declaration and ate
`--bg` and `--disabled-border`, and `controls.css` was never read at all. Fixed, regenerated,
`--check` and `--self-check` pass.

Four deliberate departures from the flow document are written into `ios/AGENTS.md` and are
Julian's to overrule: no row thumbnail, the system app bar, the system alert for the delete
question, and the confirm hint without the photo count. `run.sh` says "resume ok"; the
by-hand half of the check - three scans, swipe, cancel, swipe, delete - is still Julian's.

## 2026-08-14 - every flow has a screen, and Julian approved them

TASKS.md tasks 5 to 11 and 13 are built and committed: the scans list, the camera, the scan
run, the pages, adjust, done, and the one-more-page screen, as stories in
`storybook/stories/`. Julian looked at the built Storybook and ticked off task 12, so the
iOS tasks 14 to 19 are unblocked.

One bug only the browser could show: the `PageStrip` rail wrapped its tiles at 40 pages.
Found by measuring the tiles' bounding boxes in a headless browser, not by reading the
build log - a green build says nothing about the layout. Fixed with a `minWidth` on the tile.

Two decisions from Julian, written into TASKS.md "Open questions" as decided: the page
number on the camera screen is the app bar title only, the counter over the viewfinder is
gone from flows 3 and 8; and "New scan" sits in the app bar as the flows draw it, so the old
`ScansScreen.jsx` footer stays wrong on purpose - too small to chase.

## 2026-08-14 - the adjusted case can cross to Swift

TASKS.md task 13. `freepdf_adjust_page` is the third C function: photo path, page path,
and one read-only `FreepdfAdjustments` struct - the corners and the flatten switch, the
angle, the black and white points and their switch, the sharpen radius, the crop box, the
quarter turns, grey. Same recipe as `scan_page`, plus crop, turn and grey, which the
automatic run never uses. A switched-off step is skipped; a step the user set wrong (a
crop box off the page) is reported, not silently left alone.
The crop box is in the page's pixels after the 3000 px cap, because that is the picture
the user is looking at. `bridge_check.sh` now crosses the struct from Swift as well.
Next: task 18 (iOS Adjust) is unblocked once Julian approves the screens in task 12.

## 2026-08-12 - the client can reach almost none of the engine, and now there is a plan for it

The iOS client calls one fixed chain and nothing else: sixteen engine capabilities - grey,
levels, sharpen, straighten, crop, rotate, paper finding, page size, resolution - have no
control anywhere in the app. `user-flows.md` is now every flow the app should have, with the
control each tool gets, and twelve open questions Julian decided in one pass (adjust after
the automatic run on a page he can see, no live preview, all three deletions ask, the PDF can
be named before sharing, a finished scan can take another page; A4, the resolution cap, the
corner thumbnail and photo-library import stay unbuilt).

`design/` holds the brief and what Claude Design returned. `storybook/` is where a component
is approved before anyone writes Swift: plain HTML and CSS, Storybook on html-vite, and the
same three components twice - the iPhone system look against the editorial theme.

Then the decision that reshaped it: **there will be more than one client, so the style is
defined once and rebuilt natively per client, for recognizability**. That rules out the
system look as the source - a system look is by definition not recognizable. So
`client-guide-design-system/` is now the single source of truth for how a client looks:
tokens, components with their states and their English and German words, and what a client
agent may decide for itself. Behaviour still belongs to `user-flows.md`.

Not decided yet: the theme itself. Editorial is a proposal, and it is a reading aesthetic -
serif faces and hairline gold - in an app that is mostly camera, thumb and sliders in bad
light. The shutter and the destructive button are where that shows, which is why they are in
Storybook rather than in an argument.

## 2026-08-12 - milestone 6: the export shrank to one line

`ShareLink(item: scan.pdf)` on the done screen, `Scan.deletePhotos()` and `Scan.photoBytes`
behind "Delete the 12 photos (78 MB)". Both checks still green.

The plan had the app copy every finished scan into its own iCloud container by itself.
**Julian's call: this is a tool, not an opinion about where his PDFs live** - he wants to
move the PDF out, not to have it moved for him. The system share sheet already does that,
Save to Files and iCloud Drive included, in his folder. Gone with it: the container, the
iCloud entitlement (which a free personal team may not even be allowed), the
copy-to-temp-then-rename dance, the `-2` suffix loop, the signed-out branch, and a check
that needed a Mac with iCloud on it. One line of code replaced a section.

`photo/` survives `deletePhotos()` on purpose: every writer assumes the directory exists and
`sweep()` only puts it back at the next launch, so a shot taken before that would fail.

That was the last milestone, and the manual check was walked on the iPhone 13 straight after
it: shoot, share into Files, delete the photos, and the force-quit while aiming at the next
page. Nothing is scheduled; the README lists what is parked.

## 2026-08-12 - milestone 5: the real camera, and the angle the plan got wrong

`ios/FreePDF/CameraView.swift` is the camera: an `AVCaptureSession` on one queue of its
own, a fresh `AVCapturePhotoSettings` per press, and a `PageWriter` per shot that carries
its page number and writes the JPEG the camera hands over, untouched. `scan_check.sh` still
says "scan ok". A simulator has no camera at all, only a microphone (measured), which is why
`FakeShoot` kept its drawing and lost only its button and screen - and why the app was put
on an iPhone 13 over the cable at the end of the session. It shot a portrait sheet and the
PDF came out upright, so `videoRotationAngle = 90` is now measured. The four commands that
put it there are in [`ios/AGENTS.md`](./ios/AGENTS.md), along with the two things that stop
the first run: a `DEVELOPMENT_TEAM` only Xcode's editor can write, and a certificate the
phone has to be told to trust.

**The plan's rotation claim was wrong and would have shipped**: portrait lock does not make
the EXIF come out right by itself. `videoRotationAngle` defaults to 0, the sensor's own
landscape, so every page in every PDF would have been on its side. It is now set to 90 on
the photo output's connection and the preview's - and 90 is triangulated from Apple's
`RotationCoordinator` wording plus four independent implementations - and then confirmed on
the phone, above.

The shot is `await`ed rather than reported through a closure: one continuation per press,
resumed by whichever AVFoundation callback comes first on the camera's queue, which is what
makes a photo that never arrives release the shutter instead of freezing it. Permission is
only ever asked for where a camera exists - a simulator's alert cannot be tapped by the
check, and an unanswered one survives `terminate`, `privacy reset` and even `uninstall`.

Two holes a review found afterwards, both now shut. "Scan 7 pages" was tappable while a
photo was still in flight: leaving tears the screen down, the session stops, the capture is
aborted, and the sentence saying so is written into a screen that is already gone - a 7 page
PDF of an 8 page document, in silence. It carries `busy` now, like the shutter. And nothing
restarted a session that AVFoundation stopped by itself, so the preview froze on its last
frame for good; a press now starts it again before it gives up. What is still unwatched: the
stand-in shutter's own three lines, because `-autofake` writes its pages directly rather
than through a press.

## 2026-08-12 - milestone 4: the app, and thirteen taps nobody can make

`ios/FreePDF.xcodeproj` exists and was never opened in Xcode - `project.pbxproj` is hand
written, about 200 lines, with a file-system-synchronised group, so a new `.swift` file
joins the target without the project file being touched. Around it: `ScanList`,
`ScanFlow` with the drain, `Engine`, and `FakeShoot` as the camera's stand-in.
`bash ios/check/scan_check.sh` -> "scan ok" in about three minutes.

The check was the half worth the time. Nothing can tap a simulator: `simctl` has no touch
command, AppleScript is refused without a human granting assistive access, and neither
`idb` nor `cliclick` is here. So the stand-in also carries a `-autofake 12` launch
argument, which makes the thirteen taps and lets the whole thing be one command. Three
things it then taught:

- **Byte-identical pages prove nothing.** The engine is deterministic, so a page scanned
  twice comes out the same. A checksum passes against an app that redoes all the work.
  The check compares the moment each page was written as well, and that is the assertion
  the first mutation - a sweep that eats the finished pages - aborts on.
- **A files-only check cannot see which screen the app is on.** Reopening after a kill has
  to land on the progress line, not the viewfinder, and `-autofake` would have papered
  straight over that by pressing on regardless. One guard in `autoShoot` refuses to
  shoot when the scan already has pages, so the wrong landing runs the check out of pages
  instead. Mutation two aborts with "only 2 of 5 pages after the relaunch".
- **`Scan.sweep()` had nothing watching it here** until the check started planting debris
  while the app is dead. Mutation three, the launch sweep removed, aborts on it.

A fourth mutation never got as far as running: it left a variable unused, and
`SWIFT_TREAT_WARNINGS_AS_ERRORS` stopped the build. That setting is in for a sharper
reason - SwiftUI's `View` is `@preconcurrency @MainActor`, so a genuine data race inside a
view comes out as a warning and the build otherwise goes green.

And the parked memory question got an answer. Twelve 12 MP pages through the real app peak
at 334 MB for the whole run, of which the PDF step is about 23 MB - the plan's "2 MB a
page" holds. What is still unweighed is forty pages on a real phone, because this is the
Mac process's resident size and iOS kills on `phys_footprint`.

## 2026-08-12 - milestone 3: the resume rules, and seventeen ways to break them

`ios/` exists: `FreePDF/Scan.swift` is the whole storage model in about 190 lines of
Foundation, and `bash ios/check/run.sh` -> "resume ok" in about two seconds, with no Xcode
and no simulator. Plan section 2 moved into [`ios/AGENTS.md`](./ios/AGENTS.md) and left a
pointer, the way section 5 did for `ffi/`.

The twelve moments were the easy half. The half worth the time: seventeen mutations of
`Scan.swift`, each run against the check, all seventeen aborting with a sentence naming what
they saw. Writing them is what found the holes - four rules turned out to have nothing
watching them at all. A sweep that deletes `scan.pdf` passed, because the one moment with a
PDF never swept and the one that swept had no PDF. And all three guards in `pageNumber`
passed when deleted one at a time, because every debris name in the check was rejected by
the length guard alone; `00071.jpg`, `-123.jpg` and `0009.tmp` now reach the other two.

Then a review of the finished thing found two real bugs, both in `state` and both reachable
without any kill:

- **The photos deleted, then Change pages, read as an empty scan.** Both buttons are on the
  done screen, in that order, and the plan says in as many words that changing the pages is
  safe "because every page file is still there". `photos.isEmpty` was tested before the
  pages were looked at, so forty finished pages became invisible to every screen and the
  PDF could not be rebuilt. One line: `photos.isEmpty && pages.isEmpty`.
- **A kill between the two folders `create` makes leaves a scan that can never be scanned.**
  `photo/` there, `page/` not; the scan reads as healthy, shooting works, and every page
  write then fails for ever with "No such file or directory", because the engine's
  `save_page` does not make the folder it writes into. Measured through the real library.
  `sweep()` is now the launch repair pass and puts the directory back.

Also from the review, one word with real reach: the folder name is built with
`Calendar(identifier: .gregorian)`, not `Calendar.current`. A phone set to the Buddhist
calendar - the default in Thailand - writes 2569 for 2026, and the Japanese era year reset
to 1 in 2019, either of which turns the sort key upside down for good. That one rule is the
only one no mutation here can catch: this Mac's own calendar is Gregorian. Local wall-clock
time in the name is kept on purpose and is now in the plan's cut table - it is what lets the
name also be the title, and it costs the order of two rows for a few hours after a flight.

Two things worth knowing next time. `precondition` needs an unoptimised build to print, as
in `ffi/`, so `run.sh` passes no `-O`; it does pass `-swift-version 6`, because that is what
a new Xcode project defaults to and the model has to survive strict concurrency there rather
than on the day it is dropped into the app. And `Scan.sweep()` exists but nothing calls it -
milestone 4 owns the launch path, along with `title`, `delete()` and `exportPDF()`, each
left for the screen that needs it.

## 2026-08-12 - milestone 2: the C surface, and Swift really calls it

`ffi/` is there: `freepdf_scan_page`, `freepdf_pages_to_pdf`, the hand-written header, and
`bridge_check.sh` -> "bridge ok" in about a second. 44 tests green. Both iOS libraries build
(`bash ffi/build-ios.sh`, ~40 s), and `nm` shows exactly the two symbols in each.

Three things the plan claimed did not survive contact:

- **Its Swift wrapper does not compile.** `owned.map { UnsafePointer($0) }` leaves Swift
  unable to work out the element type of the array C wants. It needs `strdup(…)!` and
  `UnsafePointer<CChar>` spelled out; the fixed version in plan section 5 was compiled,
  linked and run against the real library, so milestone 3 can copy it as it stands.
- **No input reaches the panic branch.** A 1x1 photo, a 2x1 one, a missing file, a directory
  as the output - all come back as sentences, because the engine has no panic path. So that
  branch is checked by a Rust unit test that panics on purpose, not through Swift.
- **`save_page` writes `0007.part`, not `0007.jpg.part`.** `with_extension` replaces the
  extension. Corrected in plan sections 7 and 8, which milestone 3's sweep fixtures use.

A review of the new crate then found an engine bug the FFI made reachable: writing crooked by
10 degrees or more fails the whole page, because `suggest_straightening` proposes an angle
`straighten` refuses. Parked in the README with the measurement and the one-line fix - it is
engine work, and patching it in `ffi/` would leave the runner broken. Two doc claims were wrong
and are now corrected: `core_engine/tests/AGENTS.md` still counted 42, and
`core_engine/AGENTS.md` claimed only `load_image` and `images_to_pdf` touch files, which
`save_page` and `pages_to_pdf` ended six lines below it.

Also: `precondition` prints its sentence only in an unoptimised build, so `bridge_check.sh`
compiles the Swift check without `-O`. With `-O` it still aborts, but silently - a check that
cannot say what it saw is half a check. Both new assertions were broken on purpose once and
watched to fail.

## 2026-08-12 - milestone 1: the engine can write pages and stitch them

`save_page` and `pages_to_pdf` are in `core_engine/src/pdf.rs`, `place(...)` is pulled out of
`build_page`, and 42 tests are green. Everything the plan claimed about printpdf held when
checked against its sources.

The plan's own test did not. It asserts a page's last 64 bytes appear in the PDF, which is
meant to catch a page that was decoded and re-encoded - but a JPEG of a smooth picture
survives that round trip **byte for byte** (measured: 0 of 174,229 bytes change), so the test
passed on an implementation that decodes every page. It now uses a page of noise, where
3,018,895 of 3,034,201 bytes change, and it was proven to fail against a deliberately
decoding version. Also worth knowing: printpdf 0.12.5 never acts on a stream's `compress`
flag - its `doc.compress()` call is commented out - so that flag proves nothing when flipped.

## 2026-08-12 - the README became the map

Rules now live next to the code they govern, and the README stops repeating them. Deleted
from it: the homography explanation (already the `//!` header of `core_engine/src/deskew.rs`
word for word), the iPhone storage and screen sections (plan sections 2 and 3), the
milestone-1 engine table (`core_engine/AGENTS.md` plus plan section 4), and the HEIC
paragraph (`backend-core-runner/AGENTS.md`). What is left is what the project is, where to
find what, and **Next steps** - the section a fresh agent gets pointed at. Two new rules in
the root `AGENTS.md` keep both current: update Next steps and append here before finishing.

Earlier the same day, still uncommitted: `iphone-client-plan.md` and the four AGENTS.md
files. `technical_architecture.md` was deleted, its content having moved into the plan.

## 2026-08-11 - photo of a document in, scan-like PDF out (`d8052d8`)

The whole engine and the command line runner, 41 tests green. `load_image`, `find_paper`,
`deskew`, `suggest_straightening` / `straighten`, `suggest_levels` / `apply_levels`,
`sharpen`, `rotate`, `crop`, `to_grayscale`, `images_to_pdf`.

Three problems ate the session, each solved by measuring rather than guessing: the
brightness stretch measured the table instead of the paper, a box around a tilted sheet
still holds 3-14% table in its corners, and printpdf picks lossless LZW for grey unless
JPEG is forced - a greyed scan grew from 107 KB to 347 KB before that was found.

## 2026-08-01 - repository set up (`b3d0f50`)

Workspace, the two crates, and the first architecture notes.
