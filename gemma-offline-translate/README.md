# gemma-offline-translate - translate a text file without a network

A text file in, the same file in another language out. The model is a file on your disk, so
nothing you translate leaves the machine: no account, no server, no API key.

Two parts:

- **`translate_engine`** (Rust) - all the work. One function per step: read the file, cut it
  into passages, translate one passage, put the passages back.
- **`translate-runner`** - the command line client. It decides the order of the steps and
  prints what happened. A graphical client would replace this part and nothing else.

The engine offers single tools, the client owns the order. So a person can look at one
passage, redo it, or correct it by hand, instead of watching a whole file go past.

## Start here

```sh
cargo test --workspace
```

16 green, and they need neither a model file nor llama.cpp: the tests bring their own
answers. Then read [Next steps](#next-steps).

## What you need for a real translation

1. **llama.cpp**, built, so you have a `llama-cli` program. That is what runs the model.
2. **A Gemma model file** in GGUF form, downloaded once. A 4-bit Gemma 3 4B file is about
   3 GB and is enough for letters and documents.

The engine never downloads either one. Where they are is your answer to give:

```sh
cargo run -p translate-runner -- letter.txt --from de --to en \
  --llama ~/llama.cpp/build/bin/llama-cli \
  --model ~/models/gemma-3-4b-it-Q4_K_M.gguf \
  -o letter.en.txt
```

Or put the two paths in `LLAMA_CLI` and `GEMMA_MODEL` and leave the flags out.
`--help` lists everything.

## What the engine does today

| `translate_engine` function | What it does |
| --- | --- |
| `load_text(path)` | Reads a text file. |
| `split_passages(text)` | Cuts the text into the blocks a translation is asked for one at a time. Every blank line and indent is kept aside, so nothing is lost. |
| `translate_passage(model, text, from, to)` | Translates one block. Refuses an empty one, and refuses a language translated into itself. |
| `rebuild_text(document, translations)` | Puts the translations back into the shape the file had. |
| `save_text(text, path)` | Writes the finished file. |
| `Language::from_code(code)` | Turns `de` into German, and refuses a code it does not know by name. |
| `LlamaCli::new(program, model)` | Points the engine at your llama.cpp and your model file, and says which path is empty when one is. |

A file is translated passage by passage because a whole file in one prompt runs past what the
model can hold, and one bad answer would spoil the entire text.

## Next steps

- [ ] **Try it against a real Gemma file and write down what came out.** Everything above the
      model is covered by tests, and the CLI has been driven end to end with a stand-in
      program. The `llama-cli` flags themselves have not been run against a real llama.cpp
      build yet, and llama.cpp renames its flags now and then - `translate_engine/src/model.rs`
      is the one file that would need the fix.
- [ ] **Say what a passage cost.** A long file takes minutes, and right now the only sign of
      life is `Passage 3 of 40`.
- [ ] **Keep the words a person chose.** A name or a term that must not be translated should
      be a list the client hands in, not something the prompt hopes for.
- [ ] **More file kinds.** Today it is plain text. Markdown would need the marks left alone.
- [ ] **Link the model in instead of running a program.** A crate such as `llama-cpp-2` would
      drop the `llama-cli` dependency and make this usable from a phone app. It is a bigger
      build, which is why it is not first.

## Licence

The code is under the [PolyForm Noncommercial License 1.0.0](./LICENSE.md): use it, change it,
share it, for anything that is not commercial. It is a source-available licence, not an
OSI open-source one - commercial use needs a word with me first.

The **model** is not covered by that. Gemma has its own terms from Google, which you accept
when you download the weights, and they apply whatever this repository says.
