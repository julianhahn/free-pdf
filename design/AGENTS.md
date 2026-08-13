# design

What the app should look like, and the brief that produced it. No code that ships is in
here - the iPhone client is rebuilt natively from this, it never loads any of it.

| Path | What it is |
| --- | --- |
| `claude-design-prompt.md` | The brief. Every screen, every component, every constraint, written for a designer who has never seen this repository. |
| `gallery/FreePDF Components.dc.html` | The component gallery that came back. Open it in a browser - it is one self-contained page. |
| `gallery/_ds/<theme>/styles.css` | The design system itself: every colour, font, spacing step, radius and shadow as a CSS variable. This is the source of truth for any number a component uses. |
| `gallery/_ds/<theme>/readme.md` | How that system is meant to be used, class by class. |

The flows those screens serve are [`../user-flows.md`](../user-flows.md), and that document
is the one that decides behaviour. Where the gallery and the flows disagree, the flows win -
a picture cannot know that the step is derived from the files, or that a kill has to be
survivable.

The theme that came back is editorial: Cormorant Garamond over Lora, a single gold accent,
outlined buttons, colour as stroke rather than fill. Julian chose it on 2026-08-13, and the
rules it now carries live in
[`../client-guide-design-system/`](../client-guide-design-system/AGENTS.md) - read them
there, not here. What it costs a native client is a font file and hand-styled controls,
because no platform's defaults look like this. That is the price of one recognizable app on
every platform, and it was paid on purpose.
