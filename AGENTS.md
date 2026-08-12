# AGENTS.md - FreePDF

Photograph the pages of a paper document, get one clean PDF. `core_engine` (Rust) does all
image and PDF work, one function per step; a client drives it - `backend-core-runner` on the
command line today, an iPhone app next.

## General rules

- Answer one screen at most, nothing longer than a 30 second read. More is overload.
- Keep the words simple, for a non native English speaker.
- Keep code short and readable. Hard focus on clean code and the SOLID principle.

## What has to stay true

- **The engine offers single tools, the client owns the order.** Nothing runs by itself, so
  the user can skip a step, redo it, or correct it by hand at any point.
- **Offline only.** Local files in, local files out. This is the product, not a preference:
  one network call and the whole promise is gone.
- **Errors are sentences a person can read.** Every step that can fail returns
  `Result<_, String>`, and the String is a finished English sentence, because the client puts
  it on screen unchanged.

## Where to start

```sh
cargo test --workspace
```

Then [`README.md`](./README.md) under **Next steps**. That section is the only place that
says what is being built now, so read it before you plan anything, and do not look for the
answer here.

## Where the rest is written down

Every rule sits next to the thing it governs, and this file only carries what has no smaller
home. The engine keeps its own AGENTS.md in [`core_engine/`](./core_engine/AGENTS.md), the
tests theirs in [`core_engine/tests/`](./core_engine/tests/AGENTS.md), and the command line
tool theirs in [`backend-core-runner/`](./backend-core-runner/AGENTS.md). Before you touch a
file, read the AGENTS.md beside it.

[`README.md`](./README.md) is the front door: what the project is, where to find what, and
what happens next. [`iphone-client-plan.md`](./iphone-client-plan.md) is the authority on the
phone side in twelve numbered sections. Point at both instead of repeating them - a fact
written down twice is a fact that will disagree with itself.

`ffi/` and `ios/` do not exist yet, and neither does any Swift code, so their rules stay in
[plan section 5](./iphone-client-plan.md#5-the-c-surface) and
[plan section 6](./iphone-client-plan.md#6-files) until those directories are real. When you
create one of those directories, give it an AGENTS.md and move its rules out of the plan.

## Every session ends in these two files

Do this before you report the work as finished, in the same commit as the work itself.

- **[`README.md`](./README.md), the Next steps section.** A fresh agent gets pointed at it
  and believes it, so leave nothing in it that your work made false: tick off what is now
  done, reshape a step that turned out different, add a step your work uncovered, park what
  you found but did not schedule. Ask this even when the work was small - a wrong list costs
  more than no list.
- **[`session-logs.md`](./session-logs.md).** One short entry at the top: the date, what
  changed, and what the next person needs to know. Three to six lines, no diff, git has that.

The README is the future, the session log is the past. Do not swap them.

## Repo hygiene

- `test_images/` is gitignored because one photo in it is a scan of a private letter, and
  personal data in git history cannot be taken back. Never commit it, never read it from code.
- Stage the exact paths you edited. `git add -A` sweeps up someone else's unfinished files
  under your commit message.
- A new crate has to join `members` in [`Cargo.toml`](./Cargo.toml), or it is neither built
  nor tested.
