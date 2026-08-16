# ffi

The one library file the iPhone app links into itself, and the four C functions it
calls. Nothing else belongs in here: no screens, no storage, no second way of doing
something the engine already does.

## The boundary is the design

What crosses: C strings, a size, an int32, and two structs of plain numbers holding
no pointer - `FreepdfAdjustments` in, `FreepdfSuggestion` out, both copied at the
boundary. `FreepdfAdjustments` is what makes the adjusted case **one** function
instead of seven, Julian's decision of 2026-08-12
(`user-flows.md` DECISIONS point 12). What never crosses: a pixel buffer, an image
handle, an allocation the caller has to free, a callback. Adding any of those means
the app has to manage the engine's memory, and a leak or a double free then lives on
the phone rather than in a test.

- **Every entry point goes through `guard`.** Unwinding out of an `extern "C"`
  function is undefined behaviour, so `catch_unwind` is not error handling, it is the
  net under the engine's own "no `panic!`" rule
  ([`../core_engine/AGENTS.md`](../core_engine/AGENTS.md)). A new function that
  forgets `guard` is the one bug this crate can make that a test cannot see.
- **0 means it worked. Anything else means nothing was written**, and the sentence is
  in the caller's buffer. Failure never leaves half a file behind, because both
  writing functions rename into place.
- **The error buffer belongs to the caller**, and is copied into rather than
  allocated. That replaces a `freepdf_last_error()` thread-local, which would break
  the app's drain: it `await`s a detached task between the call and reading the error,
  so the read would land on another thread and return nothing - "Page 12 failed: " in
  the one place the sentence is the only clue.
- **A path the app failed to pass is answered with a sentence, not a crash.** It is a
  bug in the app, but the app has somewhere to show a sentence and nowhere to show a
  crash.

## The order of tools lives here, not in the engine

`adjust_page` is the same chain with the user's own values, plus the three tools the
automatic run never uses: crop, turn, grey. Two rules of its own: a step switched off
is skipped, and a step that fails is reported rather than quietly left alone,
because the user chose that value. The crop box is fractions 0…1 of the image this
function holds at that moment, so it is cut after the 3000 px cap and after the turn.

`scan_page` is the whole chain a photo of a document wants: deskew, straighten,
levels, cap, sharpen, write. It sits in this crate because the engine offers single
tools and the client owns the order ([`../AGENTS.md`](../AGENTS.md)) - and this crate
is a client. Two rules hold it together:

- **Two steps may do nothing rather than fail.** A sheet that cannot be found or runs
  off the frame is left alone; writing that is already level is not turned. One
  awkward photo that returned an error would make the scan unfinishable, and resume
  would retry that same photo for ever.
- **The 3000 px cap is a memory cap.** `sharpen` is the peak of the whole scan and
  costs 33 bytes per pixel, so the cap is what keeps a 12 MP photo from peaking near
  400 MB on a phone iOS kills at about 1.4 GB. It is applied before sharpening, not
  after, and the number carries its measurement in `src/lib.rs`.

`suggest_adjustments` walks that same chain for the Adjust screen but writes nothing:
the engine suggests, the user only fine-tunes (`user-flows.md` section 7). It has to
redo the deskew and the straightening rather than only measure them, because the tone
points are read off the sheet **after** it was pulled flat - a suggestion measured on
another image is another suggestion. Two things it carries that the app cannot work
out for itself: whether the sheet fills the whole photo and whether it runs off the
frame, which are the two lines section 7a puts under the Edges control. For that same
reason the caller may hand in **its own sheet** instead of null: the picture is then
pulled flat with those corners before the tilt and the tone points are read off it, and
what comes back - the found corners and the three notes - is still the engine's own
answer, so **Back to the suggestion** reads the same numbers either way.

**The corners are in the photo's own upright full size pixels** - the photo after its
EXIF orientation was applied. That is the space the app draws the photo in, and the
only one it can draw the corners in. It is *not* the page's space: the page is pulled
flat (a new size), maybe straightened (another one) and then capped at 3000 px, so
there is no scaling that takes one to the other. `crop_*` is not pixels at all: it is fractions 0…1 of the
image `adjust_page` holds right before cropping - the one the corners, the straightening,
the cap and the turn made, which no client ever sees. That is Julian's decision of 2026-08-15: a
box outside the page cannot be expressed, and the same fraction means the same piece on
every page, so an all-pages run can carry it.

The command line runner has the same chain behind `--scan` and its own copy of the
sharpening radius. That duplication is deliberate - each client owns its order - but
the two are worth changing together.

## The check

```sh
bash ffi/bridge_check.sh      # -> "bridge ok", about 1 second
```

It builds the host library and compiles a Swift file against
[`include/freepdf.h`](./include/freepdf.h) with `-import-objc-header`, which is the
same mechanism as Xcode's bridging header setting - so the boundary is really
crossed, without a simulator or Xcode. Then: a missing photo names the file, a null
path still returns a sentence, a caller that passes no error buffer does not crash,
a generated 3200x2400 photo comes out as a 3000 px page, the same photo through
`freepdf_adjust_page` comes out cropped and turned, the same crop fractions cut the same
relative piece out of two differently sized photos, `freepdf_suggest_adjustments`
calls that photo a sheet filling the frame with all four corners inside it and its
own values are then accepted unchanged by `freepdf_adjust_page`, and two pages come out as a PDF
ending in `%%EOF`.

Two things about it are load bearing:

- **`precondition`, never `assert`**, and no `-O`. `assert` is compiled out under
  `-O`, which would leave a check that passes without checking; `precondition` traps
  either way but only prints its sentence unoptimised, and a check that aborts without
  saying what it saw is half a check.
- **The panic branch of `guard` is checked in Rust, not through Swift.** No input
  reaches it: the engine has no panic path, and a 1x1 photo, a 2x1 one, a missing file
  and a directory as the output all come back as sentences. So the unit test in
  `src/lib.rs` panics on purpose, which is the only honest way to see that branch work.

When an assertion is added, break it once on purpose and watch it abort. The plan's
own milestone-1 test passed against a deliberately wrong implementation, which is how
that habit was earned ([`../session-logs.md`](../session-logs.md)).

## Building for the phone

```sh
bash ffi/build-ios.sh
```

Two libraries, one per platform: device arm64 and simulator arm64 cannot be joined
with `lipo` - same architecture, different platform - so Xcode picks between them by
SDK. That SDK condition is what replaces the XCFramework people reach for. Nothing in
the dependency tree is C, so cross compiling needs only

```sh
rustup target add aarch64-apple-ios aarch64-apple-ios-sim
```

Xcode does not know about cargo, so a forgotten `build-ios.sh` links yesterday's
Rust. The four build settings on the app target, and the Swift wrapper that calls
these functions, are in
[plan section 5](../iphone-client-plan.md#5-the-c-surface) until `ios/` exists.
