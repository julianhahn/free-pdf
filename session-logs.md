# Session logs

One entry per session, newest first, written before the work is called finished. What
changed and what the next person needs to know - not a diff, git has that. Three to six
lines is the size.

This file is the past. The future is [`README.md`](./README.md) under **Next steps**, and
both get updated in the same commit as the work
([`AGENTS.md`](./AGENTS.md#every-session-ends-in-these-two-files)).

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
