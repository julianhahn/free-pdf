# Session logs

One entry per session, newest first, written before the work is called finished. What
changed and what the next person needs to know - not a diff, git has that. Three to six
lines is the size.

This file is the past. The future is [`README.md`](./README.md) under **Next steps**, and
both get updated in the same commit as the work
([`AGENTS.md`](./AGENTS.md#every-session-ends-in-these-two-files)).

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
