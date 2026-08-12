# client-guide-design-system

How every FreePDF client looks and behaves. There will be more than one client - the iPhone
app today, others later - so the style is written down **once, here**, and each client
rebuilds it in its own native toolkit. Nothing in this folder ships or is loaded at runtime.

Julian's decision, 2026-08-12: a little drift between platforms is fine, guessing a value is
not. If a client agent has to invent a colour or a word, this folder failed and needs the
missing line added.

**The tokens are a candidate.** The editorial theme (Cormorant Garamond over Lora, one gold
accent, outlined buttons, colour as stroke) is what Claude Design returned as a proposal.
Julian has not finally chosen it. One concern is already on the table: it is a reading
aesthetic - serif faces, hairline gold - and this app is mostly camera, thumb and sliders in
bad light. The shutter and the destructive button are where that shows: a 1 px gold ring on a
dark viewfinder is hard to find with a thumb, and "delete the photos" carries no red.

## What is in here

| File | What it decides |
| --- | --- |
| `tokens.md` | Every colour, font, size, spacing step, radius and shadow, named, light and dark. Read this instead of a CSS file. |
| `components.md` | Every component the app needs: its states and its EN/DE copy. |
| `platform-rules.md` | What "rebuild natively" means, and the accessibility floor. |

## What is not in here

- **Behaviour** - which screen follows which, what a kill costs, when a button appears. That
  is [`../user-flows.md`](../user-flows.md), and it wins any disagreement, because a picture
  cannot know that the step is read off the files.
- **The raw design output** - the gallery page and its stylesheet live in
  [`../design/`](../design/AGENTS.md). That is where the numbers came from; this folder is
  where they are agreed. Retuning happens there first, then here.
- **Approval** - a component is looked at and approved in [`../storybook/`](../storybook/).
  Nothing in Storybook ships either; once approved it is rebuilt natively.
- **Client code** - the iPhone app is [`../ios/`](../ios/AGENTS.md). It is still in the
  system look, not this one.

## What a client agent may invent, and what it may not

May invent, because the platform knows better than this document:

- gestures - what a swipe, a long press or a pinch is on that platform
- control mechanics - how a switch flips, how a slider tracks a finger, how a sheet presents
- animation timing and easing
- the layout under an unusual text size or screen shape

May **not** invent - if it is missing here, ask, do not guess:

- colour, including hover and pressed tints
- type scale, weights, and which face is heading and which is body
- spacing steps, radii, shadows
- copy, in either language
- the set of states a component has

Every rule here carries its reason. If you change a rule, move the reason with it.
