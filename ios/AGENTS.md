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

The eleven sentences this screen prints — the seven subtitles and the four words of the
delete question, English and German — are the copy table in
[`../user-flows.md`](../user-flows.md) section 2. They are not copied here: a second copy
drifts, and this one already had the wrong dash before it was a day old.

The row draws no page thumbnail, where the delivered flow document draws one. A thumbnail
means decoding a JPEG per row on the screen that opens first, and an empty scan has none to
decode - **not built, and Julian's to overrule**.

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
| Page counter, top centre (the navigation title, which is also why Back reads "Scans") | Page 7 | Seite 7 |
| The shutter, for VoiceOver | Photograph page 7 | Seite 7 fotografieren |
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
