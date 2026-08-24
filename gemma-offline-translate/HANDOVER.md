# Handover - gemma-offline-translate

Paste this whole file to a local agent that can create a GitHub repository. It is written for
that agent, and it is disposable: **delete it once the repo exists.**

---

## What happened before you

Julian wants an offline voice translator. A remote session built the text half of it and wrote
the plan, but that session's GitHub app was refused (403) when it tried to create the repo, so
the finished tree was carried inside another repository. Your first job is to lift it out. You
are not starting from a blank page - everything below already exists as files.

## 1. Make the repo (do this first, change nothing while you do it)

```sh
# 1. Get the carried tree. The branch exists on GitHub and holds nothing else of yours.
git clone --branch claude/gemma-offline-translate-repo-xagaq0 --single-branch \
  https://github.com/julianhahn/free-pdf.git /tmp/carrier

# 2. Move it out, dotfiles and the CLAUDE.md symlink included.
mkdir -p ~/code/gemma-offline-translate
cp -R /tmp/carrier/gemma-offline-translate/. ~/code/gemma-offline-translate/
cd ~/code/gemma-offline-translate
rm HANDOVER.md            # this file. It has done its job.

# 3. Check it before you commit it. All three must pass.
cargo test --workspace     # 16 green, no model file needed
cargo clippy --workspace --all-targets
cargo fmt --all -- --check

# 4. Its own history, its own repo. Private first; Julian makes it public when he likes it.
git init -b main && git add . && git commit -m "feat: the text half, and the plan for the voice app"
gh repo create julianhahn/gemma-offline-translate --private --source=. --push
```

Then take the folder out of the carrier repo, so there is one copy of the truth:

```sh
cd /path/to/free-pdf && git checkout claude/gemma-offline-translate-repo-xagaq0
git rm -r --cached gemma-offline-translate && rm -rf gemma-offline-translate
# say in session-logs.md that it moved, and where to
git commit -am "chore: gemma-offline-translate moved to its own repo" && git push
```

**Read `AGENTS.md`, `TASKS.md` and `app-plan.md` in the new repo before you write a line of
code.** They are the truth. What follows here is only so you understand why they say what they
say.

## 2. What the app is

Two people sit at a table. One phone lies flat between them, portrait. The screen is cut
across the middle: the **bottom half** reads right way up for its owner, the **top half** is
turned 180 degrees for the person opposite.

- The two languages are **chosen once, by hand**, on a screen before anything else. Nothing is
  guessed from the sound.
- Each half has **one button**. Press it, that half listens. Press again, it stops.
- **Listening must be visible** - a level that moves with the voice, drawn by the client from
  its own microphone buffer, and the word "Listening". A still picture is not proof.
- When a turn finishes, the **other** half shows the sentence in that person's language and the
  phone **reads it out loud**.
- Each half has a **replay button**, because the sound arrives when the other person was not
  ready for it. It works while the other side is listening.
- Only **one side at a time**. The other button is visibly dead with its reason, never silently.

Everything is offline. No account, no server, no API key, no network call anywhere.

## 3. The shape of the code

Same shape as Julian's other project, FreePDF, and this is not negotiable:

> **One Rust core holds all the logic. Thin native clients sit on top and reach it through a C
> header.** The client owns the microphone, the loudspeaker, the voice that reads text out, and
> the drawing. It decides nothing else.

- `translate_engine` - text: languages, prompt, the `Translator` trait, cutting a text into
  passages so nothing is lost. **Exists, tested.**
- `translate-runner` - the command line client. **Exists.** It is how the core runs without a
  phone, and it stays that way.
- `speech_engine`, `conversation`, `ffi` - sound in, the turn machine, the C surface. Planned in
  `app-plan.md`, sections 2 to 6.
- Clients: iPhone first because it iterates fastest. Android matters more (see below).

Four rules the repo will not bend on, all in `AGENTS.md`: as much as possible in Rust; offline
only; every error is a finished English sentence a client can put on screen unchanged; no
`unwrap`, `panic!` or `unsafe` in `src/`.

## 4. The thing that actually decides this project

**Julian develops on an iPhone 15 Pro. The people it is for are an elderly couple who share one
Samsung Galaxy A20 or A25.** The cheap phone is the target; the iPhone is the workbench.

That gap is wide. An A20-class phone from 2019 has roughly 3 GB of memory in total and no
useful accelerator; an A25-class one from 2024 has 6 to 8 GB. Inference is on the CPU. A model
that answers in two seconds on the iPhone can take ten or more there, and one that fits the
iPhone may not fit at all.

So, before any screen is made pretty:

1. Find out **which phone exactly** - model number, Android version, free memory. Julian reads
   it off the phone.
2. Run the smallest model that fits **on that phone** and time one short sentence
   (`TASKS.md` 8b, the gate).
3. Expect to need **tiers**: more than one model in the app, picked by what the phone has -
   memory first, never the phone's name - decided once in Rust, not once per client
   (`TASKS.md` 8c).
4. Expect the answer to be a **translation-only model** rather than a general one on the cheap
   phone. A model trained for translation alone is a fraction of the size at the same quality of
   translation, and it gives up only the things this app never asks for.

If nothing on that phone gets under about ten seconds, **the product changes shape** - fewer
languages, text instead of speech, a smaller model - and a benchmark is a far cheaper place to
learn that than a finished app.

## 5. The two standing rules for every agent

Both are written into `AGENTS.md`, and they are the reason Julian can hand a session over in one
sentence. Honour them in the same commit as the work:

- **`TASKS.md`** is the queue. Take the top task whose "Blocked by" is done. Set its state, write
  what you measured into the row, and add the task your work uncovered. Julian's whole instruction
  to an agent is "look at TASKS.md and take the next one", so a stale row costs a session.
- **`session-logs.md`** gets one short entry at the top: the date, what changed, what the next
  person needs to know. Three to six lines. No diff, git has that.

## 6. Where to start

`TASKS.md` task 1, and it changes no code: **find out which Gemma is current**, which sizes exist
as 4-bit GGUF, and whether it takes sound directly. Julian said "Gemma 4"; the session that wrote
this could not confirm what is out, so check rather than assume. If the current Gemma hears sound
itself, the whole `speech_engine` crate never gets written, one model load disappears, and one of
the two waits per turn disappears with it. That is why it is first.

Then task 2: llama.cpp is currently started as a **child process** (`llama-cli`), which a phone
app may not do. It has to be linked in as a library. `translate_engine/src/model.rs` is the only
file that changes, because everything above it goes through the `Translator` trait.

## 7. Open questions only Julian can answer

- Which Samsung is it, exactly, and what Android version does it run?
- Which language pair matters first? The engine knows ten codes today and the list is one line
  of code, but the models and the offline voices have to exist for them.
- The phone's own voice (`AVSpeechSynthesizer`, Android `TextToSpeech`) needs a language pack
  downloaded once. That is the one place the app must tell a person to fetch something. Is that
  acceptable, or should a voice ship inside the app?
