# Session logs

One entry per session, newest first, written before the work is called finished. What
changed and what the next person needs to know - not a diff, git has that. Three to six
lines is the size.

This file is the past. The future is [`README.md`](./README.md) under **Next steps**, and
both get updated in the same commit as the work
([`AGENTS.md`](./AGENTS.md#every-session-ends-in-these-two-files)).

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
