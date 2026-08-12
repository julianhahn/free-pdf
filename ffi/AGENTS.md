# ffi

The one library file the iPhone app links into itself, and the two C functions it
calls. Nothing else belongs in here: no screens, no storage, no second way of doing
something the engine already does.

## The boundary is the design

What crosses: C strings, a size, an int32. What never crosses: a pixel buffer, an
image handle, an allocation the caller has to free, a struct, a callback. Adding any
of those means the app has to manage the engine's memory, and a leak or a double free
then lives on the phone rather than in a test.

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
and a generated 3200x2400 photo comes out as a 3000 px page and two of those come out
as a PDF ending in `%%EOF`.

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
these two functions, are in
[plan section 5](../iphone-client-plan.md#5-the-c-surface) until `ios/` exists.
