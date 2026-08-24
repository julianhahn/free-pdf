# AGENTS.md - gemma-offline-translate

A text file in, the same file in another language out, with a Gemma model in a local file.
`translate_engine` (Rust) does the work, one function per step; a client drives it -
`translate-runner` on the command line today.

## General rules

- Answer one screen at most. More is overload.
- Keep the words simple, for a non native English speaker.
- Keep code short and readable. Hard focus on clean code and the SOLID principle.

## What has to stay true

- **The engine offers single tools, the client owns the order.** Nothing runs by itself, so a
  person can skip a step, redo it, or correct a passage by hand.
- **Offline only.** Local files in, local files out. This is the product, not a preference:
  one network call and the whole promise is gone. No crate that speaks HTTP, ever, and the
  model is always a path a person gave.
- **Errors are sentences a person can read.** Every step that can fail returns
  `Result<_, String>`, and the String is a finished English sentence, because the client puts
  it on screen unchanged. It names the path or the value it refused.
- **Cutting a text loses nothing.** `split_passages` and `rebuild_text` are one pair, and the
  round trip over a text nobody translated must give that text back, byte for byte. There is
  a test for it; keep it.

## How a new function looks like the old ones

- Every module opens with a `//!` header saying why it exists. Every public function gets a
  `///` block; a fallible one adds the `- Parameters:` / `- Returns:` pair, and `- Returns:`
  describes the error in words.
- Comments say WHY. Every tuning number is a named `const` with a doc comment.
- No `unwrap()`, `expect()`, `panic!`, `unsafe`, no threads, no global state in `src/`.
- The model is reached only through the `Translator` trait. A step that calls a program
  directly cannot be tested and ties the engine to one runner.
- `translate_engine/src/lib.rs` is the whole contract: the `pub use` block is the list a
  client calls by name.

## Where to start

```sh
cargo test --workspace
cargo clippy --workspace --all-targets
cargo fmt --all
```

Then [`README.md`](./README.md) under **Next steps**. That section is the only place that
says what is being built now, so read it before you plan anything.

## Every session ends in the README

In the same commit as the work: tick off what is now done in **Next steps**, reshape a step
that turned out different, add a step your work uncovered. A wrong list costs more than no
list.

## Repo hygiene

- Model files and documents are gitignored. A `.gguf` is hundreds of megabytes and carries
  Google's Gemma terms; a document is someone's private text. Neither belongs in git history.
- Stage the exact paths you edited. `git add -A` sweeps up someone else's unfinished files.
- A new crate has to join `members` in [`Cargo.toml`](./Cargo.toml), or it is neither built
  nor tested.
