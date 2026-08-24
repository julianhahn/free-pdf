# gemma-offline-translate - two people, one phone, no network

The phone lies flat on the table between two people. Each presses the button on their half,
says a sentence, and the other half shows it in their language and reads it out loud. The
models are files on the device, so nothing that is said leaves it: no account, no server, no
API key.

The shape is one core and thin clients:

- **`translate_engine`** (Rust) - the text work. One function per step.
- **`translate-runner`** - the command line client. It is how the core runs without a phone.
- **`speech_engine`, `conversation`, `ffi`** - sound in, the turn machine, and the C header a
  phone app links. Planned, not built: [`app-plan.md`](./app-plan.md).
- **clients** - the user interface, one per platform, each as thin as it can be. They own the
  microphone, the loudspeaker, the voice and the drawing, and decide nothing else.

## Start here

```sh
cargo test --workspace
```

16 green, and they need neither a model file nor llama.cpp: the tests bring their own answers.
Then read [`TASKS.md`](./TASKS.md) - it is the queue, and an agent that has read nothing else
can take the top task. [`app-plan.md`](./app-plan.md) is the authority on everything not built
yet: the screens, the turn machine, the C surface, the models.

## What runs today

A text file, translated passage by passage on the command line. That is the text half of the
voice app, already working, and it is what the voice turn will call.

You need llama.cpp built (`llama-cli`) and a Gemma `.gguf` file on the disk. The engine
downloads neither; where they are is your answer to give:

```sh
cargo run -p translate-runner -- letter.txt --from de --to en \
  --llama ~/llama.cpp/build/bin/llama-cli \
  --model ~/models/gemma-3-4b-it-Q4_K_M.gguf \
  -o letter.en.txt
```

Or put the two paths in `LLAMA_CLI` and `GEMMA_MODEL` and leave the flags out. `--help` lists
everything.

| `translate_engine` function | What it does |
| --- | --- |
| `load_text(path)` | Reads a text file. |
| `split_passages(text)` | Cuts the text into the blocks a translation is asked for one at a time. Every blank line and indent is kept aside, so nothing is lost. |
| `translate_passage(model, text, from, to)` | Translates one block. Refuses an empty one, and refuses a language translated into itself. |
| `rebuild_text(document, translations)` | Puts the translations back into the shape the file had. |
| `save_text(text, path)` | Writes the finished file. |
| `Language::from_code(code)` | Turns `de` into German, and refuses a code it does not know by name. |
| `LlamaCli::new(program, model)` | Points the core at your llama.cpp and your model file, and says which path is empty when one is. |

## Build order

Riskiest thing first, and the risk here is **seconds on a cheap phone**: this is built on an
iPhone 15 Pro but it is for one shared Samsung A-series phone, where a model runs on the CPU
and may not fit in memory at all ([`app-plan.md`](./app-plan.md) section 8). So the whole chain
is measured - on a desk, then on that phone - before a single screen is drawn. Every step ends in something that runs, and every check is one command. The numbered
tasks are in [`TASKS.md`](./TASKS.md).

1. **Know the model.** Which Gemma is current, and does it take sound directly? If it does,
   the speech crate never gets written. Task 1.
2. **Link it in.** llama.cpp as a library, not as a program a phone may not start. Tasks 2, 3.
3. **Hear a sentence.** `speech_engine`, then measure. After this the 3 second budget is
   either standing or dead, and it is cheap to find out here. Tasks 4, 5.
4. **The turn machine.** `conversation`: one side at a time, replay, every refusal a sentence.
   Tasks 6, 7.
5. **The C surface.** `ffi` plus a `bridge_check.sh` that calls every function from C. Task 8.
   With it, **the gate**: one turn timed on the cheap Android phone this is actually for, and
   model tiers if it needs them. Tasks 8b, 8c, 9.
6. **The iPhone client.** Pick the languages, then one real turn end to end. Tasks 10, 11.
7. **Make it usable.** Listening you can see, a replay button, a dead button that says why,
   and a screen for every error the core can return. Tasks 12 to 14.
8. **Measure it on the phone.** The real number, at the sizes steps 2 and 3 chose. Task 15.

## Licence

The code is under the [PolyForm Noncommercial License 1.0.0](./LICENSE.md): use it, change it,
share it, for anything that is not commercial. It is a source-available licence, not an
OSI open-source one - commercial use needs a word with me first.

The **models** are not covered by that. Gemma has its own terms from Google, which you accept
when you download the weights, and they apply whatever this repository says.
