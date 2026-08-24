# TASKS.md - the queue

**How to use this file.** Take the top task whose "Blocked by" is done. One task goes to one
agent, and a task is written so that an agent who has read nothing else can do it. When the
check passes, set the state here and write the result into the task - the number you measured,
the thing that turned out different - in the same commit as the work. Add the task your work
uncovered. Then write your line in [`session-logs.md`](./session-logs.md).

States: **open**, **doing**, **done**, **parked** (with the reason).

## The rules that hold for every task

- Read [`AGENTS.md`](./AGENTS.md) first, and the `AGENTS.md` next to any file you touch.
  [`app-plan.md`](./app-plan.md) is the truth about anything not built yet.
- Every check is one command, and it either passes or it does not. `cargo test --workspace`,
  `cargo clippy --workspace --all-targets` and `cargo fmt --all -- --check` pass before any
  task is called done.
- No network, in code or in a test. A test brings its own answers.
- Do not download a model to make a test pass. Tests run without one.

## The list

| # | Task | Blocked by | Check |
| --- | --- | --- | --- |
| 1 | **open, first** - **Which Gemma, and does it hear?** Find out which Gemma is current, which sizes exist as 4-bit GGUF, and whether it takes sound directly. Write the answer into [`app-plan.md`](./app-plan.md) section 5 with the date, and say plainly whether `speech_engine` is one crate or none. Nothing is downloaded in this task and no code changes. It decides tasks 4 and 5. | - | app-plan.md section 5 names a model, a size in GB, and yes or no on sound |
| 2 | **open** - **Link the model in instead of running a program.** `LlamaCli` starts `llama-cli` as a child process, which a phone app may not do. Replace it with a `Translator` that links llama.cpp in (`llama-cpp-2` or the like), keeping the trait and every test. The old one may stay for the command line only if it costs nothing; if it costs anything, delete it. | 1 | `cargo test --workspace`, then the runner translates a typed line with a real Gemma file |
| 3 | **open** - **Measure one translation on a desk.** With the linked model, time a short sentence from prompt to finished text, at two model sizes. Write both numbers into [`app-plan.md`](./app-plan.md) section 5. This is the first half of the 3 second budget. | 2 | a printed number of seconds for each size, in the plan |
| 4 | **open** - **`speech_engine`: sound in, text out.** New crate. One trait `Listener` with `hear(samples, language) -> Result<String, String>`, one Whisper-backed answer, and a fake in the tests. Takes mono f32 at 16 kHz, refuses anything shorter than `SHORTEST_TURN` with a sentence. Skip this task if task 1 says Gemma hears. | 1 | `cargo test --workspace`, and the runner prints the words of a spoken `.wav` |
| 5 | **open** - **Measure one transcription.** Same as task 3 for the speech half: a 4 second clip, two model sizes, both numbers into the plan. Task 3 plus this is the whole budget, and if it is over 3 seconds, say so and propose which model shrinks. | 3, 4 | two numbers in the plan, and a sentence saying whether the budget holds |
| 6 | **open** - **`conversation`: the turn machine.** New crate, no file access and no device. `Conversation::new(bottom, top)`, `begin_turn(side)`, `add_audio(samples)`, `finish_turn() -> Line`, `last_line(side)`. Refuses a second side while a turn runs, refuses `finish` without a `begin`, ends a turn itself after `LONGEST_TURN`, and every refusal is a sentence. Tests use the fake `Listener` and the fake `Translator`, so the whole chain runs with no model at all. | 4 | `cargo test --workspace`, with a test per refusal |
| 7 | **open** - **Two people at a desk, on the command line.** The runner drives a whole conversation from two `.wav` files, printing what each side would show. This is the proof the core is finished before any Swift exists. | 6 | one command turns two recordings into four printed lines |
| 8 | **open** - **The C surface.** New `ffi` crate, exactly the functions in [`app-plan.md`](./app-plan.md) section 4, one static library, one header. No panic may cross it, every fallible call fills `error` with a sentence, and every returned pointer has its free function. A `bridge_check.sh` calls every function from a small C file, the way FreePDF's does. | 6 | `./ffi/bridge_check.sh` |
| 8b | **open, the gate** - **One turn on the cheap phone.** Julian's target is one shared Samsung Galaxy A20 or A25, not the iPhone ([`app-plan.md`](./app-plan.md) section 8). Collect the model number, the Android version and the free memory, then run the smallest model that fits it on that phone and time one short sentence. Nothing about the app is built in this task. If nothing gets under about ten seconds, this row says what the product gives up instead. | 5 | a number of seconds, measured on that phone, in the plan |
| 8c | **open** - **Tiers, if 8b needs them.** The core picks the model from what the phone has - memory first, never the phone's name - and says which one it picked, so a client can show that it is the slow one. One place, in Rust, not once per client. | 8b | a test picks the small model for a small memory figure and the big one for a big figure |
| 9 | **open** - **The library the phone links.** Build the static library for the iPhone and the simulator, and a script that does it in one command. | 8 | the script prints a path to a `.a` that holds both slices |
| 10 | **open** - **Pick the two languages.** The first screen of the iPhone client: my language, their language, and it remembers them. Nothing else on screen yet. | 9 | the app opens, both languages are chosen, and they survive a kill |
| 11 | **open** - **One turn, for real.** The two halves, one button each, the top half turned 180 degrees. Press, speak, press: the other half shows the text and the phone reads it out. Nothing pretty yet. | 10 | one spoken sentence comes out of the other half as sound |
| 12 | **open** - **Listening has to be visible.** The moving level on the listening half, drawn from the client's own samples, and the word "Listening". The other half's button goes visibly dead with its reason while a turn runs. | 11 | by eye, on the phone: a person can tell it is listening without being told |
| 13 | **open** - **The replay button.** One per half, plays that half's last sentence again, and works while the other side is listening. | 11 | press it three times, hear it three times |
| 14 | **open** - **A turn that goes wrong.** Every sentence the core can return has a place on screen: no words heard, turn too long, model missing, voice for that language not downloaded. Invent no words - collect them here and let Julian read them. | 12, 13 | every error in the core has a screen, listed in this row |
| 15 | **open** - **Measure it on the phone.** The real budget: press to sound, on a real device, at the model sizes tasks 3 and 5 chose. Write it into the plan. If it is over 3 seconds, this row says what shrinks. | 11 | a number of seconds, measured on a device, in the plan |

## Parked

- **The Android client.** Same list as tasks 10 to 15 with different names. The iPhone one is
  built first because it iterates faster, **not** because it matters more - the people this is
  for share one Samsung ([`app-plan.md`](./app-plan.md) section 8). Task 8b keeps that phone in
  the plan while the iPhone client is being written.
- **A transcript screen.** Nothing is written to disk today and that is on purpose
  ([`app-plan.md`](./app-plan.md) section 3). If it is ever wanted, it is a decision about
  privacy first and a screen second.
- **Words a person must not have translated.** A name or a term to keep as it is. It belongs
  to the text side and has no home in a conversation yet.
