# ios

The iPhone app. `FreePDF/` is what ships - the screens and the storage model under them -
and `check/` holds the two checks: one that needs no Xcode at all, one that drives the
whole app on a simulator. The engine is reached through the four C functions in
[`../ffi`](../ffi/AGENTS.md) and nothing else - no image work and no PDF work belongs in
here.

## One scan is one directory

```
Documents/Scans/
  2026-08-11_201403_8F3A/          <- the scan. Folder name = sort key + id.
    photo/0001.jpg 0002.jpg 0004.jpg   <- 0003 was deleted. Gaps stay. Never renumbered.
    page/ 0001.jpg 0002.jpg            <- 0004 unscanned = the resume point
    state/0001.txt 0002.txt            <- what the user last asked for on that page
    name.txt                           <- the name he typed, if he typed one. The title.
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
   `photo/` and `page/`, `0007.txt` and nothing else inside `state/`, plus `scan.pdf` and
   `name.txt`.
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
- **"Shoot another page" deletes `scan.pdf` first.** The PDF is what this screen reads as
  finished, so a scan that still had one would answer the tap with the done screen and the
  new photo would never be drained.
- **Adjust page** opens [`FreePDF/AdjustView.swift`](./FreePDF/AdjustView.swift) and hands
  it the scan's Grey switch, because applying without it would quietly un-grey the page.

### Adjusting a page

One more branch of `ScanFlow`'s switch, like the camera - not a second destination. The
view is dumb the way the pages are: values in, `onCancel`/`onApply` out, and `ScanFlow`
owns every file move. Applying deletes `scan.pdf` first, exactly as **Change pages** does.

Two things flow 7 draws that this screen does not, both deliberate and both **Julian's to
overrule**:

- **The bar is the system's.** Cancel, the title and Apply are toolbar items, not a drawn
  52 px bar - the same trade the list makes.
- **The handles may be dragged off the picture** - a corner outside it is read as the
  edge, because the crop crosses as fractions 0…1 and nothing outside the picture can be
  said.

The engine seeds a page once, and after that the controls open on what was last applied:
`freepdf_suggest_adjustments` asks what the automatic run would have done and hands back
the corners, the angle, the two levels points and the three note flags
([`../ffi/AGENTS.md`](../ffi/AGENTS.md)), and the page's `state/NNNN.txt` wins over it
wherever there is one. The suggestion is still asked for on every open, because its two
notes are about the photo rather than about the values, and **Back to the suggestion**
puts that tool's part of the engine's answer back, so the label is true. The exception is
what the engine measures for itself - the straightening angle and the two tone points -
which only mean something against one set of corners, because the engine reads the tilt
and the tone points off the picture **after** it was pulled flat. So moving the sheet
corners asks the engine for them again, against those corners, and its numbers replace
what is on screen, whether the engine put it there or the user did (Julian, 2026-08-16:
the common flow never leaves the Edges tab, so Apply has to run the automatic steps
again). Crop, turn, grey and the flat switch are the user's and are kept. Four rules fall
out of it:

- **Nothing can be moved before the answer arrives, and no page opens without one.** The
  call runs in the screen's own `.task`, after the two files have been measured, because
  the corners come back in photo pixels and are only a fraction of the picture once the
  photo has been measured. If the engine refuses the photo, its sentence is the screen and
  Apply stays dead - a page whose photo is gone cannot be adjusted at all, and the pages
  screen's own **Adjust page** control is dead for exactly those pages.
- **Apply is refused while the numbers belong to a sheet that is no longer on screen.**
  From the moment a corner moves until the re-measure lands, Apply is dead, because
  `write` stores exactly what it sent - a tap in that gap would run and record numbers
  the drag itself had just made wrong.
- **Every tool shows what it would do.** A debounced run of the engine's own recipe into a
  scratch file under the system's temporary directory - never `photo/`, `page/`, `state/`
  or `scan.pdf`, so `sweep()` never sees it - draws the page the current values would
  produce, one run at a time and the newest superseding the last; only **Apply** writes a
  page. (Julian, 2026-08-16, reversing the earlier "no live preview".)
- **Edges shows the photo, every other tool the page.** The sheet corners are photo pixels,
  so drawing them over the page would put them in a space nothing maps back to. Crop stays
  on the page, and the fraction dragged there is a fraction of the last cut, which the
  paragraph below composes onto the stored one. Both files are measured, and the block the handles live in is
  given the shape of the file it draws: fitted inside a block of another shape the picture
  gets bars, and a handle on a bar is a fraction the engine never sees.
- **An all-pages run does not send this page's pixels to the others.** The corners are
  asked of the engine again per page, and only when "Pull the sheet flat" is on. Everything
  else - crop, angle, levels, sharpen, turn, grey - is the same number everywhere and
  travels unchanged; the crop can, because it is a fraction and not pixels.
- **The turn is remembered, not baked in.** It lives in the page's `state/NNNN.txt` and
  the engine turns the image at every Apply, so the photo stays the camera's untouched
  bytes and the append-only rule holds.
- **A new crop is composed onto the stored one, not swapped for it.** The fraction the
  engine cuts is a fraction of an image that exists only mid-recipe - after the corners,
  the straightening, the cap and the turn - so it is neither the photo nor the page
  ([`../core_engine/AGENTS.md`](../core_engine/AGENTS.md), "Every step has its own
  space"). The box therefore opens on the whole picture, which is honest because the page
  on screen is already the last cut, and Apply lays the new drag inside the old box - and
  turns the old box with the turn first, one quarter clockwise mapping `(x, y, w, h)` to
  `(1 - y - h, x, h, w)`. It follows that a crop can only ever be tightened; widening is
  **Scan this page again**.

One page an all-pages run could not write shows the engine's own sentence with its page
number in front; more than one missing photo shows the copy table's "Pages 4, 9 and 18 were
not changed…", which is only ever about missing photos. There is no singular of that
sentence in the tables, so none is invented.

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
  -import-objc-header ffi/include/freepdf.h ios/FreePDF/*.swift
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
- **Every rule the model states has a mutation that breaks it.** Seventeen were run against
  this check and all seventeen aborted with a readable sentence. Add an assertion, then
  break it on purpose once and watch it fail - the plan's own milestone-1 test passed
  against a deliberately wrong implementation, which is how that habit was earned
  ([`../session-logs.md`](../session-logs.md)). Four of the seventeen were written after
  the mutation showed the rule was not watched at all: a sweep that eats `scan.pdf`, and
  each of the three guards in `pageNumber`, which the debris list had only ever tested
  together.
- **One rule cannot be watched here: the Gregorian calendar.** A machine whose own calendar
  is Gregorian cannot tell `Calendar(identifier: .gregorian)` from `Calendar.current`. The
  check compares the name against a POSIX formatter, which is Gregorian by definition, so
  the mutation aborts on a phone set to the Buddhist calendar and passes on this Mac.

### scan_check.sh - the app, killed in the middle of a scan

Twelve pages shot, killed after three, opened again. It has to carry on at page four by
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
  stand-in.
- **It cannot see which screen the app is on**, only the files. The one screen rule that
  matters after a kill - a scan that has pages belongs on the progress line, not in the
  viewfinder - is watched by a guard inside `autoShoot`, which refuses to press on and
  lets the check run out of pages instead.
- **Three mutations were run against it**, each aborting on the line meant to catch it: a
  sweep that eats the finished pages ("a finished page was written again"), reopening
  that lands on the viewfinder ("only 3 of 5 pages after the relaunch"), and nothing
  swept at launch ("debris left behind"). A fourth attempt never got as far as running,
  because it left a variable unused and `SWIFT_TREAT_WARNINGS_AS_ERRORS` stopped the
  build - which is that setting earning its place.

## What is not written here

The export is [plan section 3](../iphone-client-plan.md#3-screens); the memory budget is
[section 9](../iphone-client-plan.md#9-memory); every line of text the app shows, in English
and German, is [section 12](../iphone-client-plan.md#12-every-line-of-text-the-app-shows) -
except the camera's lines, which are in the camera section above. Each of those moves into
this file when the code it governs is written.
