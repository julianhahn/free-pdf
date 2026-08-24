# Session logs

One entry per session, newest first, written before the work is called finished. What changed
and what the next person needs to know - not a diff, git has that. Three to six lines is the
size.

This file is the past. The future is [`TASKS.md`](./TASKS.md) and [`README.md`](./README.md)
under **Build order**, and both get updated in the same commit as the work
([`AGENTS.md`](./AGENTS.md#every-session-ends-in-these-two-files)).

## 2026-08-24 - The repo, and the plan for a voice translator

Julian asked for his own repo under a non-commercial licence, then said what it is really for:
two people at a table, one phone lying flat between them, each half facing one person, press
to speak, the other half reads it out. Rust core, thin native clients over a C header, like
FreePDF.

**Built:** the text half. `translate_engine` (read, cut into passages, translate one, put back)
and the `translate-runner` command line client, 16 tests green with no model file and no
llama.cpp. The CLI was driven end to end against a stand-in program, so the real `llama-cli`
flags are the one untested piece.

**Written:** [`app-plan.md`](./app-plan.md) - screens, the turn machine, the C surface, the two
models - and [`TASKS.md`](./TASKS.md), fifteen tasks in the order they have to happen. The
first one changes no code: find out which Gemma is current and whether it takes sound directly,
because if it does, the whole speech crate never gets written.

**The thing that reshaped the plan:** Julian develops on an iPhone 15 Pro, but the people this
is for are an elderly couple who share one Samsung Galaxy A20 or A25. The cheap phone is the
target, not the fallback - three gigabytes of memory and CPU-only inference against a phone that
answers in two seconds - so [`app-plan.md`](./app-plan.md) section 8 and tasks 8b and 8c hold the
gate: one turn timed on that phone, and model tiers picked by memory, before any screen is made
pretty.

**Next person:** take TASKS.md 1. And note the repo could not be created from that session -
the GitHub app was refused with a 403 - so this tree was carried inside the free-pdf repo on
the branch `claude/gemma-offline-translate-repo-xagaq0`. If it still sits there, moving it out
is the first thing to do.

`HANDOVER.md` in this folder is the paste-in for the local agent that creates the repo. It is
disposable - delete it once the repo exists.
