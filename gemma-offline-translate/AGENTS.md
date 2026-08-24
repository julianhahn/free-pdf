# AGENTS.md - gemma-offline-translate

Two people sit at a table with one phone between them. Each speaks their own language, the
other hears theirs. Everything happens on the device: no account, no server, no network call.

The shape is the same as FreePDF's: **one Rust core holds the logic, thin native clients sit
on top of it and reach it through a C header.** A client captures sound, draws, and speaks;
it decides nothing.

## General rules

- Answer one screen at most. More is overload.
- Keep the words simple, for a non native English speaker.
- Keep code short and readable. Hard focus on clean code and the SOLID principle.

## What has to stay true

- **As much as possible in Rust.** A rule that lives in a client lives once per platform and
  drifts. Only what the operating system owns stays in the client: the microphone, the
  loudspeaker, the voice that reads text out, and the drawing.
- **The core offers single tools, the client owns the order.** Nothing runs by itself, so a
  person can stop a turn, say it again, or hear it again.
- **Offline only.** Local files in, local sound out. This is the product, not a preference:
  one network call and the whole promise is gone. No crate that speaks HTTP, ever, and every
  model is a path a person gave.
- **Errors are sentences a person can read.** Every step that can fail returns
  `Result<_, String>`, and the String is a finished English sentence, because the client puts
  it on screen unchanged. It names the path or the value it refused.
- **Cutting a text loses nothing.** `split_passages` and `rebuild_text` are one pair, and the
  round trip over a text nobody translated gives that text back, byte for byte. Keep the test.
- **One turn at a time.** Two people talking into one microphone is noise. The core owns that
  state, so both clients are dead in the same places.

## How a new function looks like the old ones

- Every module opens with a `//!` header saying why it exists. Every public function gets a
  `///` block; a fallible one adds the `- Parameters:` / `- Returns:` pair, and `- Returns:`
  describes the error in words.
- Comments say WHY. Every tuning number is a named `const` with a doc comment.
- No `unwrap()`, `expect()`, `panic!`, `unsafe`, no threads, no global state in `src/`. A
  panic across the C boundary is undefined behaviour.
- A model is reached only through a trait (`Translator` today). A step that calls a program
  or a library directly cannot be tested and ties the core to one runner.
- Each crate's `src/lib.rs` is its whole contract: the `pub use` block is the list a client
  calls by name.

## Every session ends in these two files

Do this before you report the work as finished, **in the same commit as the work itself**.

- **[`TASKS.md`](./TASKS.md).** Set the state of what you touched, write the result into the
  row - the number you measured, the thing that turned out different - and add the task your
  work uncovered. Julian's whole instruction to an agent is "look at TASKS.md and take the
  next one", so a stale row costs a whole session.
- **[`session-logs.md`](./session-logs.md).** One short entry at the top: the date, what
  changed, and what the next person needs to know. Three to six lines, no diff, git has that.

[`README.md`](./README.md) is the front door and holds the build order. When a milestone
changes shape, fix it there too. The README and TASKS.md are the future, the session log is
the past. Do not swap them.

## Where to start

```sh
cargo test --workspace
cargo clippy --workspace --all-targets
cargo fmt --all
```

Then [`TASKS.md`](./TASKS.md), and for anything not built yet
[`app-plan.md`](./app-plan.md) is the authority - screens, the turn machine, the C surface,
which models. Do not repeat a plan section here: when you build what a section describes,
move its rules into the AGENTS.md beside the code and leave a pointer behind.

## Repo hygiene

- Model files, recordings and documents are gitignored. A `.gguf` is hundreds of megabytes
  and carries Google's Gemma terms; a recording is someone's voice. Neither belongs in git.
- Stage the exact paths you edited. `git add -A` sweeps up someone else's unfinished files.
- A new crate has to join `members` in [`Cargo.toml`](./Cargo.toml), or it is neither built
  nor tested.
