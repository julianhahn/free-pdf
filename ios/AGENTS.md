# ios

The iPhone app. `FreePDF/` is what ships, `check/` is how the part that has no screen is
proven without Xcode. The engine is reached through the two C functions in
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

## The check

```sh
bash ios/check/run.sh      # -> "resume ok", about 2 seconds
```

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

## What is not written here

The screens, the drain, the camera and the export are
[plan section 3](../iphone-client-plan.md#3-screens); the memory budget is
[section 9](../iphone-client-plan.md#9-memory); every line of text the app shows, in
English and German, is [section 12](../iphone-client-plan.md#12-every-line-of-text-the-app-shows).
The four build settings that link the Rust library are
[section 5](../iphone-client-plan.md#5-the-c-surface). Each of those moves into this file
when the code it governs is written.
