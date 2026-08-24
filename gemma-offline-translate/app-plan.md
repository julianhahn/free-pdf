# app-plan.md - the offline voice translator, before it exists

This file is the authority on everything that is not built yet: the screens, the turn
machine, the C surface, and which models. [`TASKS.md`](./TASKS.md) is the queue that builds
it, [`README.md`](./README.md) holds the build order. When a section here gets built, its
rules move into the AGENTS.md beside the code and a pointer stays behind.

## 1. What a person does

The phone lies flat on the table, portrait, between two people. The screen is cut across the
middle into two halves. The **bottom half** stands upright for the person the phone belongs
to. The **top half** is turned 180 degrees, so it reads right way up for the person opposite.

1. **Pick the two languages, once.** A full screen before anything else: my language, their
   language. Both are named, so nothing has to be guessed from the sound. Change it later
   from a small control in the corner, never automatically.
2. **One button per half.** Press it and that half starts listening.
3. **Listening has to be visible.** The half that listens shows a moving level, drawn from the
   sound coming in right now, plus the word "Listening". A still picture is not proof.
4. **Press again to finish.** Then that half says "Translating" and the other half's button is
   dead - visibly dead, with the reason, not silently.
5. **The answer lands on the other half**, as text in that person's language, and the phone
   reads it out loud.
6. **A replay button on each half.** It plays that half's last sentence again, as many times
   as wanted, because the sound comes when the other person is not ready for it.

Both halves show the same pair of things: the last thing this person said, and the last thing
they were told. Nothing scrolls away by itself.

### Why press twice instead of holding

A held button on a table means a finger stays on the phone and the person talks to the phone.
Two presses leave the hands free and let a person think in the middle of a sentence. The
price is a press that never comes: after `LONGEST_TURN` of sound the core finishes the turn
itself and says so.

## 2. The turn machine

The core owns it, so both clients are dead in exactly the same places.

```
Idle --begin(side)--> Listening(side) --finish--> Working(side) --> Speaking(other side) --> Idle
```

- Only one side may hold a turn. `begin` on the other side while a turn runs is refused with
  a sentence, not queued.
- `Speaking` ends when the client says the voice is done, because only the client knows.
- Anything that fails puts the machine back to `Idle` and gives back the sentence. A failed
  turn keeps no half-line: the person says it again, they do not repair it.
- Replay never touches the machine. It reads a line that is already there, so it works while
  the other side is listening.

## 3. What the core keeps

One conversation, in memory only. Nothing is written to disk: a recording of two people
talking is the most private thing this app touches, and the phone is not the place to keep
it. A line is `{ side that spoke, what was heard, the translation, the language to speak it
in }`. The client asks for the last line of a side to replay it, and for the whole list only
if a transcript screen is ever built (not planned).

## 4. The C surface

One static library, a handful of functions, the same shape FreePDF's `ffi/` has. Sound comes
in as **mono 32 bit float at 16 kHz**, because that is what the speech model wants; a client
that records something else resamples before it calls - that is the client's one piece of
audio work.

```c
typedef enum { GT_SIDE_BOTTOM = 0, GT_SIDE_TOP = 1 } GtSide;

typedef struct {
    char *heard;           // what the speaker said, in their own language
    char *translation;     // what the other person reads
    char *speak_language;  // the code the client's voice must use, e.g. "en"
    GtSide shown_on;
} GtLine;

// Opens the models. Both paths are files on the device. Returns NULL and fills *error.
GtHandle *gt_open(const char *gemma_gguf, const char *speech_model,
                  const char *bottom_language, const char *top_language, char **error);
void gt_close(GtHandle *handle);

bool gt_begin_turn(GtHandle *handle, GtSide side, char **error);
bool gt_add_audio(GtHandle *handle, const float *samples, size_t count, char **error);
GtLine *gt_finish_turn(GtHandle *handle, char **error);   // the whole turn happens here
GtLine *gt_last_line(GtHandle *handle, GtSide shown_on);  // for the replay button
void gt_line_free(GtLine *line);
void gt_string_free(char *text);
```

`gt_finish_turn` is one call that blocks for seconds. The client runs it off the main thread
and shows "Translating" - it does not get progress, because a half-finished translation is
not something to look at.

The level meter is **not** in here on purpose. The client already holds the samples it is
recording, and a meter that travels through a C call cannot keep up with an ear.

## 5. The two models

- **Gemma**, 4-bit GGUF, for the translation. Linked in as a library, not run as a program: a
  phone app may not start another binary.
- **Speech to text.** Whisper as a GGUF, linked the same way.

**One model may do both.** The on-device Gemma line could take sound directly, which would
drop Whisper, the second load of memory, and one of the two waits. Which Gemma is current and
whether it hears is the first thing to check, before anything is downloaded - it decides
whether the speech crate is one crate or none.

**Latency is the product.** Two people stop talking to each other if a turn takes too long.
Target: a short sentence answered within **3 seconds** on the phone, measured before any
screen is built. If it does not hold, the model gets smaller, not the plan bigger.

## 6. The crates

| Crate | What it owns |
| --- | --- |
| `translate_engine` | Text: the languages, the prompt, the `Translator` trait, cutting a text into passages. Exists. |
| `speech_engine` | Sound in, text out. One trait, one Whisper-backed answer. Falls away if Gemma hears. |
| `conversation` | The turn machine, the lines, replay. Knows no file and no device. |
| `ffi` | The C surface above, and nothing else. |
| `translate-runner` | The command line client. It is how the whole chain runs without a phone. |

## 7. The clients

Both are thin: microphone, loudspeaker, the voice that reads out, drawing, and the two
presses. iPhone first, with `AVAudioEngine` for sound in and `AVSpeechSynthesizer` for the
voice - the voice has to be downloaded once per language and is then offline, which is the
one place the app has to tell a person to fetch something. Android is the same list with
different names and comes after the iPhone one walks.

## 8. The two devices, and why the cheap one decides everything

The phone this is developed on is an **iPhone 15 Pro**. The phone it is *for* is the one
**Samsung Galaxy A20 or A25** that an elderly couple shares. Those two are not the same
machine by a wide margin, and the cheap one is the target, not the fallback.

What that means, without having measured it yet:

- An A20-class phone from 2019 has about **3 GB of memory in total**, of which an app may
  expect well under half. A 4-bit model of a few billion parameters does not fit, and Android
  9 or 10 will kill the app rather than swap. An A25-class phone from 2024 has **6 to 8 GB**
  and can hold a model of about a gigabyte, slowly.
- Inference there is **CPU only**. A general purpose model that answers in two seconds on the
  iPhone can take ten or more on that phone, and a turn nobody waits for is not a product.

So two things are possible and both have to be measured before any screen is built:

1. **Tiers.** The app carries more than one model and picks by what the phone has - memory
   first, not the model name. The client asks the core, the core decides, and the person sees
   only that it is slower.
2. **A smaller kind of model.** A model trained for translation only is a fraction of the size
   of a general one at the same quality of translation, and speech to text has small models
   too. On the A-series that is likely the only thing that runs at all. It costs the one thing
   a general model gives for free - it translates and does nothing else - which this app does
   not need.

**The gate.** Before the iPhone client is made pretty, one turn is measured **on Julian's own
A-series phone**, with whatever model fits it. If nothing gets under about ten seconds there,
the product changes shape - fewer languages, text instead of speech, a smaller model - and it
is far cheaper to learn that from a benchmark than from a finished app.

**Which phone exactly.** A20 and A25 are two different worlds, so the model number, the
Android version and the free memory are the first facts to collect, and they are Julian's to
read off the phone.
