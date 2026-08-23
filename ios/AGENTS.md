# ios

The iPhone app. `FreePDF/` is what ships - the screens and the storage model under them -
and `check/` holds the two checks: one that needs no Xcode at all, one that drives the
whole app on a simulator. The engine is reached through the four C functions in
[`../ffi`](../ffi/AGENTS.md) and nothing else - no image work and no PDF work belongs in
here. Four is still the count: the page size rung was added as one more parameter to the
two functions that write a page, `freepdf_scan_page` and `freepdf_adjust_page`, rather than
as a fifth function.

## One scan is one directory

```
Documents/Scans/
  2026-08-11_201403_8F3A/          <- the scan. Folder name = sort key + id.
    photo/0001.jpg 0002.jpg 0004.jpg   <- 0003 was deleted. Gaps stay. Never renumbered.
    page/ 0001.jpg 0002.jpg            <- 0004 unscanned = the resume point
    state/0001.txt 0002.txt            <- what the user last asked for on that page
    name.txt                           <- the name he typed, if he typed one. The title.
    quality.txt                        <- one word: how small the pages of this scan are written.
    scan.pdf                           <- exists => finished. Arrives only by rename.
  2026-08-09_093207_1C7D/ ...
```

The files are the only state, so nothing can disagree with the disk after a kill - there
is nothing else to disagree with it. Local, never an iCloud container: a synced folder may
evict a file to a placeholder that needs the network to read back, and this app reads its
own input offline. iCloud is where the finished PDF is exported to.

The folder name is `<yyyy-MM-dd>_<HHmmss>_<4 hex>`, written in the Gregorian calendar
whatever the phone is set to, and in local time. A reverse lexicographic sort over those
names is newest first with no attribute reads, and the hex tail survives a double tap on
New scan inside one second. The formatted date is the title of every scan the user has not
named himself, and `name.txt` wins wherever it exists - the folder is never renamed either
way. That is what the local time buys: flying west, or the hour that repeats when
summer time ends, can list a newer scan below an older one for a few hours. It costs the
order of two rows and no data.

### Three rules carry the whole thing

1. **Append-only.** No file is ever modified in place, so no torn update exists and
   `FileManager.replaceItem` is never needed anywhere.
2. **A file earns its real name only by rename after a complete write.** Swift:
   `try data.write(to: url, options: .atomic)`. Rust: `.part`, flush, `sync_all`, rename
   ([`../core_engine/AGENTS.md`](../core_engine/AGENTS.md)). A real name is proof of a
   complete file - that is what replaces checksums and a validation pass.
3. **Debris is invisible and swept.** Readers accept `0007.jpg` and nothing else inside
   `photo/` and `page/`, `0007.txt` and nothing else inside `state/`, plus `scan.pdf`,
   `name.txt` and `quality.txt`.
   `Scan.sweep()` deletes the rest - `.part` files,
   Foundation's `.dat.nosync…`, anything hand-copied in - and puts back a directory that is
   missing. Call it at launch, on every scan, before the list is shown: it is the only
   repair pass there is, and a scan whose `page/` is gone can never be scanned, because the
   engine does not make the folder it writes into.

### `state/NNNN.txt` - what the user asked for

One ASCII line per page: a version `1` and the 24 numbers of `Engine.Adjustments` -
the four sheet corners, the flat switch, the angle, the two levels points, the tones
switch, the sharpen radius, the crop box, the quarter turns and grey. It is written by
`Scan.writeState` under `.part` and renamed, read by `Scan.readState`, and an absent,
truncated or unreadable line is not a failure and gets no sentence: that page simply
opens on the engine's suggestion, which is what the first open does anyway. It goes
three ways - the drain deletes it the moment `Engine.scanPage` rebuilds that page from
its photo (a retake's old sidecar describes a photo that is gone), `deletePage` deletes
it with the page, and `sweep()` deletes anything in `state/` that is not `NNNN.txt` for
a number the disk still has.

**It is not the manifest the table below buries.** A manifest holds where the work got
to, which can lag the files and send a screen to the wrong step; this holds what the user
asked for, and nothing in `Scan.state`, `photos`, `pages`, `unscanned` or `nextPage`
reads it. The page is renamed first and the sidecar second, so the worst a kill in
between costs is one nudge made again - never a wrong page, and never a screen lying
about done or not-done.

### `quality.txt` - how small the pages are written

One word for the whole scan: `small` or `original`. `small` is `Engine.PageQuality`'s
quality 45 with every pixel kept; `original` is quality 85 with every pixel kept, which is
the engine's own `PageQuality::UNCHANGED` and byte for byte the page this app wrote before
there was anything to choose. `Scan.quality` reads it, `Scan.writeQuality` writes it
`.atomic`, and the two words are machine keys - they are not copy and are not translated.

- **It is one fact about the scan, so it is one file - not `state/NNNN.txt`.** `state/` is
  per page, and one fact stored forty times is a fact that can disagree with itself: forty
  sidecars saying `small` and one saying `original` has no honest answer for a switch that
  shows one position. It sits beside `name.txt` for exactly the reason the name does.
  `readState` also counts exactly 25 tokens, so a 26th would change the on-disk format of
  every page for a value that is not a page's.
- **The word, never the numbers.** A stored `45` would freeze today's number into every old
  scan and disagree with the switch the day the rung is retuned. The numbers behind a rung
  live in `Engine.PageQuality` and nowhere else.
- **`quality.txt` has to be in `sweep()`'s keep list, or the setting dies at every launch.**
  The sweep deletes everything in a scan folder that is not on that list, and it runs in
  `FreePDFApp.init` - so a name left off it means the user's choice survives until he next
  opens the app, which is the worst kind of bug: it works while he is watching. The list is
  one named constant in `Scan.swift` for that reason. Anything added to a scan folder from
  now on is added to that constant in the same edit.
- **A kill in the middle of a rewrite leaves the word new and some pages old.** `quality.txt`
  is written first on purpose: the reverse order - pages at the new rung under a file naming
  the old one - sends the switch back and costs the whole run again instead of one page.
  What it costs is that a scan can hold pages of both sizes, and unlike the same kill during
  a Grey flip **this one is invisible**: the pages all look right, they are only not all the
  size the file promises. Flipping the switch twice repairs it. That is accepted rather than
  fixed, because the honest fix is a marker file the sweep also has to know about and a
  resume that finishes the run at the next launch - worth building the day a rung changes
  something a person can see. **Measured on 2026-08-23 and still not worth it:** at 1:1 on
  real paper a quality 45 page is not distinguishable from Original, fine print and long
  digit strings included ([`../README.md`](../README.md) **Next steps** row 14), so a scan
  holding both sizes reads right on every page - the only wrong thing is a number the user
  never sees. Build the marker the day a visible rung is added; the parked CCITT-G4 rung
  ([`../TASKS.md`](../TASKS.md) 40) would be exactly that day.
- **Absent, empty, unreadable, or a word this version does not know reads as `small`.** No
  sentence, exactly like `name`. That is not a shrug: `small` is what the app promises a
  scan will cost, so a scan whose one small file was lost still comes out the size it
  promised, and Original stays the thing the user chose on purpose.

**Quality 45 is the default, and the check after the first photo is where it is seen and
switched** (Julian, 2026-08-22 - [`../user-flows.md`](../user-flows.md) DECISIONS 7, the
half of it he reversed). Two rungs reach the user and no more, so the control is a `Toggle`
in `.switch` style: the design system has neither a picker nor a segmented control, and a
switch is the honest control for a two-way choice.

The same switch is on the pages screen too - the same value in, the same callback out, one
setting with two places to reach it - because the first page check happens once per scan, on
the first photo, so a scan he comes back to would otherwise have no way back. **That second
switch is not Julian's decision, it is the agent's extension of his,** and it waits for him
the way its label does.

- **The preview and the written page are always made at the same rung.** The check screen's
  picture is a real `freepdf_scan_page` run, so it is keyed on the rung - `.task(id: quality)`
  - and a flip makes a new picture. Previewing one thing and writing another is the whole
  failure this screen exists to prevent, so any future screen that shows a page must pass
  the scan's rung too. That is why `Engine.scanPage` and `Engine.adjustPage` have **no
  default argument** for the rung: every call site has to name one, and the Adjust screen's
  live preview and `write` both had to be given the scan's, or Apply would silently
  un-shrink a page.
- **`ScanFlow` owns the file work, as with every other file move.** `setQuality` deletes
  `scan.pdf`, writes `quality.txt`, then rewrites the pages that exist, one at a time. That
  order is the kill-safety argument: the PDF is derived and costs two seconds; a kill after
  the one atomic rename leaves the setting new and some pages old, which reads perfectly,
  is repaired by flipping the switch twice, and means every page written from then on - the
  drain's included - is at the new rung. The reverse order costs the whole run instead of
  one page, because pages at the new rung under a file naming the old one send the switch
  back.
- **A rewrite is the run that made the page, not `write`.** A page with a `state/NNNN.txt`
  goes back through `adjust_page` with exactly those stored values, so crop, turn and levels
  survive and no crop is composed onto itself; a page without one goes back through
  `scan_page`. Nothing new is written into `state/`, because what the user asked for did not
  change - only how small it is written.
- **On the check screen the flip rewrites nothing**, because no page file exists yet. It
  writes the word and the drain then writes every page at it. That also keeps the engine at
  one run at a time, instead of a rewrite racing that screen's own preview run.
- **Once the photos are deleted the switch is dead, not gone.** A page cannot be rewritten
  without its photo, which is the same reason **Adjust page** is dead for a page whose photo
  is missing. The setting on disk stays what it was and still describes the pages, and a new
  page shot into that scan is still written at it.
- **A page whose photo is missing is answered by the engine's own sentence**, prefixed with
  its page number; more than one becomes the copy table's "Pages 4, 9 and 18 were not
  changed…" - the same takeover, the same "Keep the app open.", no new sentence invented.

### The step is derived, never stored

`Scan.state` reads the files every time. A stored step is a second truth, and the kill that
matters is the one between writing the file and writing the step.

`.shooting` and `.scanning` are separate for one reason: they decide where reopening lands
him. No pages yet means he was still shooting, so he gets the viewfinder; some pages plus
leftovers means the scanning was cut off, so he gets the progress line.

Three lines are worth more than they look, and each has a mutation in the check watching
it:

- **`unscanned`, not `pages.count == photos.count`.** One orphan page file - a page whose
  photo was deleted - would wedge the count form in `.scanning` for ever with nothing left
  to scan.
- **`nextPage` counts both directories.** A number the disk has ever seen is never handed
  out twice, so a new shot cannot land on a page number that is already in the PDF.
- **`.empty` needs both directories empty.** The done screen offers deleting the photos and
  then changing the pages, so no photos and forty pages is a state the user reaches on his
  own, in two taps. Reading it as an empty scan puts him in the viewfinder and makes forty
  finished pages invisible to every screen.

### The manifest that isn't

| Field it would hold | What killed it |
| --- | --- |
| title | the folder date, or `name.txt` when he typed one |
| pageOrder | zero-padded filenames, lexicographic |
| step | `Scan.state`, five lines |
| pageCount | a count of files, which cannot disagree with the disk |
| keepPhotos | not state - an action taken once |
| reviewedUpTo | not needed - review is a viewer |
| exported | not derivable offline (placeholders), and re-export is idempotent |

A manifest is pure addition: it needs its own atomic write, and (photo, manifest) is not
atomic as a pair, so it can lag the files by one page - forcing exactly the file-derived
reconciliation it was meant to replace, plus a schema.

## The screens

```
ScanList ──"New scan"──▶ Scan.create() ──▶ ScanFlow
   │  tap a scan ──────────────────────────▶ ScanFlow
   ▼
ScanFlow - one screen, and it switches on what the files say
   ├─ shooting ─▶ the camera        "Scan 7 pages" ─┐
   ├─ first page after the first photo of the scan: retake, or photograph the rest
   ├─ takeover   one answer being applied to every page
   ├─ adjusting  one page, in AdjustView
   ├─ scanning ◀───────────────────────────────────-┘   the drain, below
   ├─ ready      the pages, one per swipe           "Make PDF" ─▶ scan.pdf
   └─ done       Open PDF │ Change pages
```

### A tappable control is built from the inside out

**Never chain padding, a frame, a background or a stroke onto a `Button` value.** A
`Button` hit-tests its *label*. Modifiers written after `Button(...)` decorate the wrapper
around that label, so they paint a box whose tappable part is still only the words - and a
trailing `.contentShape` does not rescue it, because it lands on that same wrapper. The
result is a control that looks 44 points tall and answers on 17.

This bug has been shipped twice and felt on the phone twice, the second time with six
`.contentShape` lines written to fix it. So there are exactly two shapes allowed:

- a **`ButtonStyle`**, which decorates `configuration.label` - the thing the tap is tested
  against. `PrimaryStyle` and `GhostStyle` in
  [`FreePDF/ButtonStyles.swift`](./FreePDF/ButtonStyles.swift) are the two more than one
  screen uses; `SecondaryStyle`, `RowStyle`, `ChipStyle`, `ShutterStyle` and the done
  screen's `OutlineStyle` stay private beside the screen each belongs to.
- **`Button { } label: { <decorated label> }`**, with every modifier inside the closure.

Two things carry a hit area and nothing else does: a `.background(colour, in: shape)` and a
`.contentShape`. A `.frame` alone is layout, and a `.overlay(Shape().stroke(…))` is a
painted line - a shape is hit-tested on its own path, so an outlined box answers on the
outline and not inside it. Where a style paints nothing at rest, the press state is what
tells the user the tap landed: `pressAccent` behind unpainted words, `pressNeutral` as a
veil over a filled one.

`ScanFlow` owns three pieces of view state that decide a screen - `shooting`,
`applyingAll` and `adjusting`. Everything else it shows is read from the files; `photos`
and `pages` are a copy for SwiftUI to redraw on, refreshed at every moment the files
change, never a second truth.

- **The screen is not `scan.state` alone.** A photo the engine refuses stays unscanned
  for ever, so the scan would sit in front of a progress bar that can never move again.
  The drain running out of work counts as arriving at the pages, which is where the user
  can retake that one or delete it.
- **Make PDF is hidden until every photo has a page**, so a scan cannot quietly lose a
  page to a PDF the user thought was whole.
- **"Change pages" deletes `scan.pdf`**, which drops the scan back to the pages. That is
  safe precisely because the PDF is derived: every page file is still there and
  rebuilding costs two seconds. Without it, a bad page spotted after Make PDF costs the
  whole scan.
- **Retake and delete remove the page file first, the photo second.** A kill in between
  leaves the page merely unscanned, so the drain rebuilds it - never a fresh photo
  wearing a page made from the sheet before it, and never a page in the PDF he asked to
  be rid of.
- **Getting the PDF out is a `ShareLink` and nothing else.** Save to Files, and with it
  iCloud Drive in the folder he picks, plus AirDrop and Mail - all of it the system's,
  none of it this app's. Nothing is uploaded unasked: **Julian's call, 2026-08-12 - this
  is a tool, not an opinion about where his PDFs live** ([plan section
  3](../iphone-client-plan.md#3-screens) says what that deleted).
- **Deleting the photos keeps `photo/` itself.** Every writer assumes the directory is
  there and `sweep()` only puts it back at the next launch, so a shot taken before that
  would fail. The scan that is left - pages, no photos - reads as `.done`, and
  `Change pages` still works on it, because the pages are the work.
- **The sweep runs in `FreePDFApp.init`, not on the list screen.** The list comes back
  every time the user leaves a scan, and a sweep at that moment could delete the `.part`
  file the engine is writing right then.

### The list

Newest first straight from the folder names, every row read off the files each draw. Two
rules of its own:

- **Nothing is deleted until the question is answered.** There is no trash for a sandbox
  folder, so the swipe only asks; `Cancel` puts the row back and takes nothing. The
  question names this scan's own counts, and pages and photos each carry their own plural.
- **The seven sentences live on `Scan`, not on the screen.** Five states, seven sentences -
  one page reads differently from eight, and a finished scan whose photos are gone says so.
  They sit in `Scan.swift` because that is the half of the app `run.sh` can compile, and
  three mutations were run against them: the plural dropped, the photos-deleted tail
  dropped, and the photo plural dropped. All three aborted on the line meant to catch them.

The error line is the one failure this screen has - `New scan` could not make the folder,
which in practice is a full iPhone. The system's own sentence, printed unchanged above the
list, gone at the next reload.

The twelve sentences this screen prints — the seven subtitles, the four words of the
delete question and the swipe's own `Delete`, English and German — are the copy tables in
[`../user-flows.md`](../user-flows.md) sections 2 and 3. They are not copied here: a second
copy drifts, and this one already had the wrong dash before it was a day old.

Three things the flows 1-2 document draws that this screen does not, all deliberate and
all **Julian's to overrule**:

- **No page thumbnail on the row.** It means decoding a JPEG per row on the screen that
  opens first, and an empty scan has none to decode.
- **The app bar is the system's**, not a drawn bar of 52 px with its own hairline. A
  navigation bar is the one place iOS owns the back gesture, the large-title collapse and
  the Dynamic Type behaviour, and redrawing it buys a font and loses all three.
- **The delete question is the system's alert**, not `ConfirmDialog` on its own scrim. The
  words are the copy table's either way, and the platform dialog is the one surface the
  user already trusts. Nothing else in the app is raised, so the shadow and scrim tokens
  stay out of `Tokens.swift` until something needs them.

The confirm button's spoken hint drops the photo count the flows document reads out
("its PDF and its 40 photos" becomes "its photos"): the alert body right above it already
says the number, and a hint that counts would say it twice in one breath.

The swipe action is 96 px wide in the design (`--swipe-action-w`) and system-wide here:
SwiftUI's `swipeActions` sizes its own buttons, so the token is generated and unused.

### The drain

One page at a time, from the first photo that has no page file, until there is none
left it can do. That is the memory guarantee, and it is the shape of the loop rather
than a comment: sharpening one page peaks near 220 MB on its own
([`../ffi/AGENTS.md`](../ffi/AGENTS.md)).

- **`failed` lives in memory only**, so it dies with the process and a relaunch retries
  each refused page once. Without it the loop would pick the same number for ever, and
  one unreadable photo would make the scan unfinishable.
- **An incomplete page is cut and says so.** A sheet that ran off the edge of the photo is
  straightened on the points where it left the frame, so the page is a piece of the sheet; the
  pages screen asks `Engine.suggest` for the page on screen and puts a calm note under it, with
  the retake that already exists (Julian, 2026-08-17).
- **A page already in flight when the screen goes away runs to the end.**
  `Task.detached` does not inherit cancellation, and that is what is wanted: a page
  either lands on disk whole or was never there.

### The check after the first photo

[`FreePDF/FirstPageCheck.swift`](./FreePDF/FirstPageCheck.swift): the photo, small, beside
the page the engine makes of it, large, with three ways out - **Scan this page again**,
**Scan 1 page** and **Photograph the rest**. Julian, 2026-08-17; the third one added on
2026-08-18, after a one page document turned out to be unfinishable with only the other two.

- **Once per scan, and the camera decides when.** `landed()` calls `onFirstPhoto` when the
  scan's photo count is one and the shot was not a retake, so a resumed scan and one more
  page on a finished scan never see it. The flag lives in `ScanFlow`'s memory only: a
  relaunch shows the viewfinder, not the check.
- **The picture is a real engine run**, `freepdf_scan_page` into a scratch file under the
  system's temporary directory - never `photo/`, `page/`, `state/` or `scan.pdf`, so
  `sweep()` never sees it - for the reason the Adjust screen runs one. The real page is
  still written by the drain and by nothing else, and nothing here writes into `page/`.
- **A refusal is the engine's sentence unchanged, and all three controls still work.** A
  page the engine refused is a reason to retake, so the screen says so instead of trapping
  him, and the promise over an empty picture is not drawn.
- **Scan 1 page finishes the scan from here**, in the camera footer's own words for one
  page, and it is the same end that footer reaches - `shooting = false` and the drain. It
  exists because this screen does not carry the footer, so the other two ways out both lead
  back to the camera, and a receipt or a single letter could not be finished at all.
  `-autofake-one` is the check for it ([`check/scan_check.sh`](./check/scan_check.sh)).
- **The left control is `ScanFlow.retake`**, the one that already exists, and there is no
  second retake path. Adjust is deliberately not on this screen: it answers "carry on or
  start over", and a page fixed by hand would still leave the next twenty shot on the same
  bad desk.
- **The page size switch lives here**, because this is the one screen where the choice can
  be judged: the picture above it is made at the rung the switch shows. On is the default.
  Value in, `onQuality` out - the screen writes nothing, and the rules are
  [`quality.txt`](#qualitytxt---how-small-the-pages-are-written) above.
- **The photo beside the page is taught here so the camera's thumbnail needs no caption.**
  Two pictures of one sheet look nothing alike, and this is the one screen with room to say
  why.

### The pages

[`FreePDF/PagesView.swift`](./FreePDF/PagesView.swift): one page per swipe, pinch to zoom
because reading small print is the only reason this screen exists, a rail of tiles that
follows the swipe, and a jump for the scan that is forty pages long. `ScanFlow` keeps the
actions and hands the screen numbers.

- **Nothing on it lists a directory.** The page numbers, the refused ones, whether the
  scan is whole and whether the PDF exists all come out of the `@State` cache of the
  files. That is not tidiness: while the drain writes, a listing inside a body answers
  differently twice in one frame and SwiftUI never settles - the screen sat in front of a
  finished scan for ever. The drain was fixed for that first; this screen was built that
  way. `makePDF()` and `everyPage()` are the deliberate exceptions and read the numbers
  straight off the disk, because a cache one refresh behind would leave a page out of the
  PDF, or out of the run that has to cover every page.
- **The position is counted, the number is printed.** "Page 3 of 12" counts the carousel;
  the tile says the file's own number. A page deleted in the middle keeps its gap for
  ever, so the two disagree from the first delete on, and the jump takes the counted one -
  that is the number he read off the rail.
- **The images decode in a `.task`, never in a body**, at 1600 px for the page and 200 for
  a tile. A full page is about 34 MB decoded and a carousel keeps three alive.
- **Grey is a fact about the pages, not about the screen.** One switch for the whole scan,
  and flipping it rewrites every page through `freepdf_adjust_page` - the same takeover
  Apply to all pages uses, the same "Keep the app open.", the same skipped-pages sentence,
  and each page keeps its own stored values with only `grey` moved. A page with no state
  file gets the engine's suggestion plus the flipped switch. The switch itself reads the
  lowest-numbered page that has a state file, so leaving the scan and coming back shows
  what is on disk rather than what a screen remembered.
- **How small the pages are written is a fact about the pages too**, so it is the second
  switch in the same footer, under Grey, with the same value-in/callback-out shape. Flipping
  it rewrites every page that exists through the same takeover, and it is dead once the
  photos are gone - a page cannot be rewritten without its photo. Its rules are
  [`quality.txt`](#qualitytxt---how-small-the-pages-are-written) above and are not repeated
  here.
- **"Shoot another page" deletes `scan.pdf` first.** The PDF is what this screen reads as
  finished, so a scan that still had one would answer the tap with the done screen and the
  new photo would never be drained.
- **Adjust page** opens [`FreePDF/AdjustView.swift`](./FreePDF/AdjustView.swift) and hands
  it the scan's Grey switch, because applying without it would quietly un-grey the page.

### Adjusting a page

Built, and its rules now live next to the four files in
[`FreePDF/Adjust/AGENTS.md`](./FreePDF/Adjust/AGENTS.md): what "Back to the suggestion"
puts back, why moving a corner re-asks the engine and holds Apply until that answer lands,
the scratch preview every tool runs, and why a crop can only ever be tightened.

### The done screen

[`FreePDF/DoneView.swift`](./FreePDF/DoneView.swift): the name field, Open PDF, Share PDF,
Change pages, and the photos block that names its own count and size. The words are the copy
tables in [`../user-flows.md`](../user-flows.md) sections 9, 10 and 11.

It is one more branch of `ScanFlow`'s switch and is dumb the way the pages and Adjust screens
are: the PDF's URL, the photo count and what the photos cost go in, `onChangePages` and
`onDeletePhotos` come out, and `ScanFlow` makes every file move. The keyboard flag is the one
thing it cannot hold itself - see below.

- **The name he types is the scan's name.** On disk the file is always `scan.pdf`. What he
  types becomes a hard link in the temporary directory called `<name>.pdf`, which is what
  `ShareLink` hands the system - a link rather than a copy, because it costs no bytes and
  the temporary directory is on the same volume - and it is written into the scan's folder
  as `name.txt` at the same moment, which is what the list row then reads instead of the
  date. One sanitised string for both, `Scan.sanitised` and nowhere else: a name that would
  not be one path component (`/`, `:`) has those two characters replaced and the ends
  trimmed. There is no Save button and nothing to lose by leaving, the field opens on the
  stored name, and clearing it deletes the file and puts the date back. The write is
  `ScanFlow`'s, like every other file move (Julian, 2026-08-17: a name he has already typed
  is the scan's name).
- **The field is focused when the screen opens, once.** Make PDF always means a copy is
  about to leave, so the keyboard comes up with the screen and its first load is paid
  there instead of on the first tap - which is the wait Julian felt on the phone
  (2026-08-16, his call). Once is the whole subtlety: the sheets present over this screen
  and cost nothing, but `Change pages` destroys the branch and Make PDF builds it again,
  and raising the keyboard a second time would cover a screen he came back to read. So the
  flag is the one piece of this screen's state that sits in `ScanFlow` and comes back as a
  binding: this screen is what Change pages destroys, and `ScanFlow` is what survives it. The
  price is that VoiceOver reads the field instead of the "PDF ready" title on opening.
  The block below stays reachable because the screen is a `ScrollView`: the keyboard is a
  bottom safe-area inset, which a scroll view turns into content it can scroll to.
- **The PDF's real size is one read-only line, and no promise.** It is the finished file's
  own bytes off disk, through the same `ByteCountFormatter` the photos block uses, and it is
  the only place in the app that says what the page size setting actually bought. Left out
  entirely when the size cannot be read, the way the photos block says nothing rather than
  "Zero KB". Nothing here predicts a size: that would need every page encoded again, and a
  formula would be the guess the engine's own rules forbid.
- **The reader is the system's PDF view under the system's sheet**, and there is nothing
  else on it - no share, no print, no page count. The close control is a glyph, so the copy
  table's "Close the PDF" is the spoken label rather than a word on screen.
- **The photos block is removed whole once the photos are gone**, never greyed: there is
  nothing left to press, and nothing announces the absence. Its confirmation is the system's
  dialog, for the reason the list section gives, and it is asked every time - doing nothing
  is the other half of the choice, so "keep the photos" needs no button.
- **The plural is the one `Scan.deleteBody` already carries.** The tables give the plural
  only; a one-page scan would otherwise read "Delete the 1 photos", so `photo`/`photos`
  follows the count and no new sentence is invented.

Two things flow 7 draws that this screen does not, both deliberate and both **Julian's to
overrule**: the PDF's first page at the top - `user-flows.md` section 9 has no picture
there and nothing renders a PDF page back to an image today (TASKS.md open question 2) -
and the line under Share, which is the designer's own placeholder and has no copy table
entry.

### The camera

`AVCaptureSession`, `.photo` preset, back wide angle, **video input only** - so the app
never needs a microphone usage key - and every line that touches the session runs on the
camera's own queue, because `startRunning` blocks the thread it is called on
(`AVCaptureSession.h:607`). It stops on disappear, and that is a memory rule rather than
hygiene: the pipeline holds about 200 MB and the drain runs next
([plan section 9](../iphone-client-plan.md#9-memory)).

- **The picture is turned by one number, and doing nothing is wrong.**
  `videoRotationAngle` defaults to 0 - the sensor's own landscape - so a page
  photographed in portrait would end up on its side. Portrait is 90, and it is set on
  the photo output's connection **and** the preview's, or the preview lies about what
  gets written. It is fixed rather than read from the phone: a phone held flat over a
  table has no reliable "up" for `AVCaptureDevice.RotationCoordinator` to find. The
  photo output writes it as an EXIF tag and never turns the pixels
  (`AVCaptureSession.h:1106`): the file stays 4032x3024 and says "rotate 90 CW", which is
  what `load_image` applies with `apply_orientation` before anything else happens to it.
  Measured on an iPhone 13 on 2026-08-12: a portrait sheet comes out of the PDF upright,
  so 90 is the right number and not merely the triangulated one.
- **A fresh `AVCapturePhotoSettings` per press.** A second capture with the same
  `uniqueID` throws (`AVCapturePhotoOutput.h:71`), so the settings are made inside the
  press. JPEG is asked for there rather than assumed, because HEIC must never reach the
  engine; 12 MP comes from writing no code at all, since the settings default to the
  smallest of the active format's `supportedMaxPhotoDimensions`
  (`AVCapturePhotoOutput.h:1454`); and the flash stays off, which is its default and what
  a sheet of paper wants.
- **The codec is checked before the shutter, because that rule throws.** `capturePhoto`
  validates the settings and raises an exception rather than failing, and the one rule
  this app can violate is a codec missing from `availablePhotoCodecTypes` - an array that
  is empty until the output sits in a session with a video source
  (`AVCapturePhotoOutput.h:96`). Checking it turns the one crash into a sentence.
- **The page number is settled at the press and travels with the writer.** One
  `PageWriter` per shot, all of it immutable, so two shots finishing out of order cannot
  swap pages. The writer is held in `inFlight` until AVFoundation's last callback,
  because nothing promises to keep a delegate alive.
- **The shutter is dead until the photo is on disk.** Two quick presses would otherwise
  both read the same `nextPage` off the disk and one page would overwrite the other.
- **AVFoundation answers on its own queue, and the first answer wins.** The callbacks
  come on a common queue, not the main one (`AVCapturePhotoOutput.h:981`), and only
  `didFinishCaptureFor` is promised to come last - so it is what answers a capture that
  never delivered a photo at all. Both answers go through one `land` on the camera queue,
  which is what makes "resumed exactly once" true without a lock.
- **Permission is only asked for where there is a camera to permit.** A simulator has
  none, and its permission alert cannot be answered by the check that drives the app
  there - an unanswered one survives `terminate`, `privacy reset` and even `uninstall`,
  and only a SpringBoard restart clears it.
- **No camera at all means the shutter draws.** iOS 26.2 on "iPhone 17 Pro" reports zero
  video devices, only a microphone, so on a simulator the shutter writes a drawn 12 MP
  page through the same atomic write ([`FreePDF/FakeShoot.swift`](./FreePDF/FakeShoot.swift)).
  That is what keeps the app hand-drivable without a phone, and what `-autofake` presses.

Every line of text it shows while nothing goes wrong, English in the code and German
checked by hand:

| Where | English | German |
| --- | --- | --- |
| Page counter, top centre (a principal toolbar item on all three of its screens; Back reads "Scans" from the list behind it) | Page 7 | Seite 7 |
| The shutter, for VoiceOver | Photograph page 7 | Seite 7 fotografieren |
| The shutter while the photo is written, for VoiceOver (it is dead, and says why) | Photographing page 7, wait | Seite 7 wird fotografiert, warten |
| Primary button | Scan 8 pages | 8 Seiten scannen |
| Primary button, nothing photographed yet (disabled) | Photograph at least one page | Mindestens eine Seite fotografieren |
| Camera access denied | FreePDF needs the camera to photograph the pages. | FreePDF braucht die Kamera, um die Seiten zu fotografieren. |
| Camera access denied, button | Open Settings | Einstellungen öffnen |
| There is no camera (a simulator) | No camera on this iPhone. The shutter draws a page instead. | Keine Kamera auf diesem iPhone. Der Auslöser zeichnet stattdessen eine Seite. |
| `NSCameraUsageDescription`, the only place the word "document" is allowed | FreePDF uses the camera to photograph the pages of your document. | FreePDF nutzt die Kamera, um die Seiten deines Dokuments zu fotografieren. |

And when something does go wrong. A photo that did not reach the disk always reads
`Page 7 was not saved: <why> Nothing already photographed is lost.` - one shape, one
place, four reasons:

| Reason | English | German |
| --- | --- | --- |
| the write failed, in the words the system used | the iPhone is out of storage. | Auf dem iPhone ist kein Speicherplatz mehr frei. |
| the session is not running, and pressing again did not fix it | the camera is not ready. | Die Kamera ist nicht bereit. |
| the capture came back with nothing in it | the camera handed over no photo. | Die Kamera hat kein Foto geliefert. |
| the capture ended before a photo arrived | the camera stopped before the photo arrived. | Die Kamera hat gestoppt, bevor das Foto kam. |

Three more, which are the screen rather than a page: "This iPhone has no camera to
photograph with." / "Dieses iPhone hat keine Kamera, um zu fotografieren.", "The camera
could not be started." / "Die Kamera konnte nicht gestartet werden." - with the system's
own reason appended where there is one - and, from the stand-in, "Page 7 could not be
drawn." / "Seite 7 konnte nicht gezeichnet werden."

Two sentences and a screen, told apart by where they are drawn: a page that missed the
disk is the error line over the viewfinder, and the three above are the whole screen -
same shape as the permission takeover, with no button, because there is nothing to press.
The stand-in's two are split the same way, by `FakeShoot.Failure`: `.notSaved` is the error
line, `.notDrawn` is the whole screen.

Three things flow 3 draws that this screen does not, all deliberate and all
**Julian's to overrule**:

- **The counter is a principal toolbar item, not `navigationTitle`.** A title cannot carry
  a font, and this one has to be the heading face with tabular figures so nothing shuffles
  between "Page 1" and "Page 40". The bar itself is still the system's, for the reasons the
  list section gives.
- **No re-check when the user comes back from Settings.** Changing a privacy permission
  there terminates the app, so the way back through the denied screen is a relaunch, and a
  `scenePhase` watcher would be code for a moment that cannot happen.
- **The permission takeover shows one sentence, not a body under it.** The flow's
  `EmptyState` has room for both; there is nothing true to put there that the sentence and
  the button do not already say.

The failure sentence says "Nothing already photographed is lost." where
[plan section 12](../iphone-client-plan.md#12-every-line-of-text-the-app-shows) wrote
"Pages 1-6 are safe.": a scan with a deleted page in the middle has no such range, and
page 1 has none at all.

## How the Rust library gets in

Four settings on the app target and nothing else - no wrapper target, no Swift package,
no framework, no XCFramework, no Run Script phase:

```
OTHER_LDFLAGS                              = -lfreepdf
LIBRARY_SEARCH_PATHS[sdk=iphoneos*]        = $(SRCROOT)/../target/aarch64-apple-ios/release
LIBRARY_SEARCH_PATHS[sdk=iphonesimulator*] = $(SRCROOT)/../target/aarch64-apple-ios-sim/release
SWIFT_OBJC_BRIDGING_HEADER                 = $(SRCROOT)/../ffi/include/freepdf.h
```

The SDK condition is what replaces the XCFramework people reach for
([`../ffi/AGENTS.md`](../ffi/AGENTS.md)). Three more things about `FreePDF.xcodeproj`,
which was written by hand and never opened in Xcode:

- **The sources are a synchronised group** (`PBXFileSystemSynchronizedRootGroup`), so a
  new `.swift` file in `FreePDF/` joins the target without the project file being
  touched at all.
- **`SWIFT_TREAT_WARNINGS_AS_ERRORS` is load bearing.** SwiftUI's `View` is
  `@preconcurrency @MainActor`, so a real data race inside a view comes out as a warning
  and the build goes green without it.
- **Xcode does not know about cargo**, so `scan_check.sh` builds the library itself. A
  green check can never be about yesterday's Rust.

## The checks

```sh
bash ios/check/run.sh          # -> "resume ok", about 2 seconds, no Xcode at all
bash ios/check/scan_check.sh   # -> "scan ok", about 3 minutes on the simulator
```

While a screen is being written there is a loop faster than either, and it needs no
project and no simulator - about a third of a second for the whole app:

```sh
swiftc -typecheck -parse-as-library -swift-version 6 -warnings-as-errors \
  -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
  -target arm64-apple-ios18.0-simulator \
  -import-objc-header ffi/include/freepdf.h $(find ios/FreePDF -name '*.swift')
```

`-parse-as-library` is not decoration: without it a single file is read as a script, and
the concurrency diagnostics quietly disappear.

### Onto a real phone, which is the only place the camera exists

```sh
xcrun devicectl list devices                      # the UDID, and that it is connected
xcodebuild -project ios/FreePDF.xcodeproj -scheme FreePDF \
  -destination 'id=<udid>' -allowProvisioningUpdates build
xcrun devicectl device install app --device <udid> \
  ~/Library/Developer/Xcode/DerivedData/FreePDF-*/Build/Products/Debug-iphoneos/FreePDF.app
xcrun devicectl device process launch --device <udid> com.julianhahn.freepdf
```

Two things stop that the first time, and neither is a bug. `DEVELOPMENT_TEAM` has to be in
the project - only Xcode's Signing & Capabilities editor can put it there, because a free
personal team's ID exists nowhere on disk until it does. And the launch is refused with
"profile has not been explicitly trusted" until the phone's Settings -> General -> VPN &
Device Management trusts the developer certificate. A personal team's signature expires
after seven days; installing again is the whole fix.

### run.sh - the resume rules

Twelve moments - ten where the process is killed, and two the user reaches on his own -
built as real files in a temporary directory and read back through the model the app itself
uses. `Scan.swift` is Foundation only, so `swiftc` alone compiles the whole state machine -
no Xcode, no simulator, no project file. It compiles in Swift 6 language mode, which is
what a new Xcode project defaults to.

- **`precondition`, never `assert`**, and no `-O`, for the same two reasons as
  [`../ffi/AGENTS.md`](../ffi/AGENTS.md): `assert` is compiled out under `-O`, and
  `precondition` prints its sentence only unoptimised.
- **Every rule the model states has a mutation that breaks it.** Twenty were run against
  this check and all twenty aborted with a readable sentence. Add an assertion, then
  break it on purpose once and watch it fail - the plan's own milestone-1 test passed
  against a deliberately wrong implementation, which is how that habit was earned
  ([`../session-logs.md`](../session-logs.md)). Four of the seventeen were written after
  the mutation showed the rule was not watched at all: a sweep that eats `scan.pdf`, and
  each of the three guards in `pageNumber`, which the debris list had only ever tested
  together.
- **The three `quality.txt` rules are watched, since 2026-08-23.** Section 18: an absent
  file reads as `small`, one write/read round trip comes back both ways, empty and blank and
  a word this version does not know all read as `small`, the sweep keeps `quality.txt` and
  takes a half-written `quality.part`, and the rung is counted as neither a page nor a step.
  Three mutations earned it - `quality.txt` off the keep list, an absent file reading as
  `original`, and a `writeQuality` that returns true and writes nothing - and all three
  aborted with a sentence naming what the check saw.
- **One rule cannot be watched here: the Gregorian calendar.** A machine whose own calendar
  is Gregorian cannot tell `Calendar(identifier: .gregorian)` from `Calendar.current`. The
  check compares the name against a POSIX formatter, which is Gregorian by definition, so
  the mutation aborts on a phone set to the Buddhist calendar and passes on this Mac.

### scan_check.sh - the app, killed in the middle of a scan

Twelve pages shot, killed after three, opened again, then three more pages added to the
finished scan. It has to carry on at page four by
itself, leave the three finished pages byte-identical **and written at the same moment**,
sweep away the debris planted while it was dead, and end in a PDF that ends in `%%EOF`.
That one kill exercises the whole design at once: the step derived from the files, temp
file plus rename, the sweep, the C boundary and the streamed PDF.

- **Identical bytes are not enough, so the moment is checked too.** The engine is
  deterministic: a page scanned twice comes out byte for byte the same, so a checksum
  alone cannot tell resumed work from repeated work. The modification time can.
- **There is no way to tap a simulator from a script.** `simctl` has no touch command,
  and AppleScript is refused without a human granting assistive access. So the app is
  driven by `-autofake 12`, which stands in for the thirteen taps and lives in
  [`FreePDF/FakeShoot.swift`](./FreePDF/FakeShoot.swift) with the rest of the camera
  stand-in. `-autofake-more 3` is the same trick for adding pages to a finished scan: it
  presses Shoot another page once and then the shutter three times, one press at a time
  with a redraw in between, so a camera screen that ended itself after the first shot
  would leave the count two short.
- **It cannot see which screen the app is on**, only the files. The one screen rule that
  matters after a kill - a scan that has pages belongs on the progress line, not in the
  viewfinder - is watched by a guard inside `autoShoot`, which refuses to press on and
  lets the check run out of pages instead.
- **A fourth mutation covers the extra pages**: `landed()` ending the screen after every
  shot, not only after a retake, aborts on "only 13 of 15 pages: Shoot another page did not
  keep the camera up" - which is the bug task 33 went looking for and did not find.
- **Three mutations were run against it**, each aborting on the line meant to catch it: a
  sweep that eats the finished pages ("a finished page was written again"), reopening
  that lands on the viewfinder ("only 3 of 5 pages after the relaunch"), and nothing
  swept at launch ("debris left behind"). A fourth attempt never got as far as running,
  because it left a variable unused and `SWIFT_TREAT_WARNINGS_AS_ERRORS` stopped the
  build - which is that setting earning its place.

## The app icon is generated, not drawn here

`FreePDF/Assets.xcassets/AppIcon.appiconset` holds two rasterised 1024 px PNGs of the
decided icon (variant 6c), and the drawing they come from is
[`../design/flows/brand/app-icon.svg`](../design/flows/brand/app-icon.svg) plus its tinted twin - the
same relation `build-tokens.mjs` has to `Tokens.swift`. Never redraw them by hand; run:

```sh
rsvg-convert -w 1024 -h 1024 -o ios/FreePDF/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png design/flows/brand/app-icon.svg
rsvg-convert -w 1024 -h 1024 -o ios/FreePDF/Assets.xcassets/AppIcon.appiconset/AppIcon-1024-tinted.png design/flows/brand/app-icon-tinted.svg
```

The SVG paints its own opaque ground across the whole square, so the PNG carries no
alpha channel - iOS rejects a transparent app icon. Xcode scales every smaller size off
the 1024 itself.

## What is not written here

The export is [plan section 3](../iphone-client-plan.md#3-screens); the memory budget is
[section 9](../iphone-client-plan.md#9-memory); every line of text the app shows, in English
and German, is [section 12](../iphone-client-plan.md#12-every-line-of-text-the-app-shows) -
except the camera's lines, which are in the camera section above. Each of those moves into
this file when the code it governs is written.
