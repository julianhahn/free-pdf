# ios

The iPhone app. `FreePDF/` is what ships - the screens and the storage model under them -
and `check/` holds the two checks: one that needs no Xcode at all, one that drives the
whole app on a simulator. The engine is reached through the two C functions in
[`../ffi`](../ffi/AGENTS.md) and nothing else - no image work and no PDF work belongs in
here.

## One scan is one directory

```
Documents/Scans/
  2026-08-11_201403_8F3A/          <- the scan. Folder name = sort key + id + title.
    photo/0001.jpg 0002.jpg 0004.jpg   <- 0003 was deleted. Gaps stay. Never renumbered.
    page/ 0001.jpg 0002.jpg            <- 0004 unscanned = the resume point
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
New scan inside one second. The formatted date is also the title, so there is no title
field - and that is what the local time buys: flying west, or the hour that repeats when
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
   `photo/` and `page/`, plus `scan.pdf`. `Scan.sweep()` deletes the rest - `.part` files,
   Foundation's `.dat.nosync…`, anything hand-copied in - and puts back a directory that is
   missing. Call it at launch, on every scan, before the list is shown: it is the only
   repair pass there is, and a scan whose `page/` is gone can never be scanned, because the
   engine does not make the folder it writes into.

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
| title | the folder date |
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
   ├─ scanning ◀───────────────────────────────────-┘   the drain, below
   ├─ ready      the pages, one per swipe           "Make PDF" ─▶ scan.pdf
   └─ done       Open PDF │ Change pages
```

`ScanFlow` owns one piece of view state that decides a screen, `shooting`. Everything
else it shows is read from the files; `photos` and `pages` are a copy for SwiftUI to
redraw on, refreshed at every moment the files change, never a second truth.

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
- **The sweep runs in `FreePDFApp.init`, not on the list screen.** The list comes back
  every time the user leaves a scan, and a sweep at that moment could delete the `.part`
  file the engine is writing right then.

### The drain

One page at a time, from the first photo that has no page file, until there is none
left it can do. That is the memory guarantee, and it is the shape of the loop rather
than a comment: sharpening one page peaks near 220 MB on its own
([`../ffi/AGENTS.md`](../ffi/AGENTS.md)).

- **`failed` lives in memory only**, so it dies with the process and a relaunch retries
  each refused page once. Without it the loop would pick the same number for ever, and
  one unreadable photo would make the scan unfinishable.
- **A page already in flight when the screen goes away runs to the end.**
  `Task.detached` does not inherit cancellation, and that is what is wanted: a page
  either lands on disk whole or was never there.

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

The camera and the export are [plan section 3](../iphone-client-plan.md#3-screens); the
memory budget is [section 9](../iphone-client-plan.md#9-memory); every line of text the
app shows, in English and German, is
[section 12](../iphone-client-plan.md#12-every-line-of-text-the-app-shows). Each of those
moves into this file when the code it governs is written.
