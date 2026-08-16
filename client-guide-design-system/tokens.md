# Tokens

> **Provisional. Do not treat any number here as approved.** These values were read off a
> stylesheet that the delivered component gallery never used - the gallery was drawn in the
> platform system font and in none of that stylesheet's classes. So the pictures and this table
> have never agreed, and nobody has looked at a component built from these numbers and said
> yes. A fresh design round is redrawing every component and will state its own token set; see
> [`vision.md`](./vision.md) and
> [`../design/claude-design-components-prompt.md`](../design/claude-design-components-prompt.md).
> Until that lands, use this table to keep the interim consistent, not to settle an argument.

Every number a client is allowed to use, the same values as `../design/system/tokens/*.css`.
Do not re-derive them from those files - copy from this table, so all clients read one list.

The **direction** is decided - paper and archive, serif titles, hairlines, one accent, see
[`vision.md`](./vision.md). The numbers below are not.

## Colours

Roles first. A client sets these six and everything else follows.

```
| Name | Light | Dark | What it is |
| --- | --- | --- | --- |
| bg | #f3f2f2 | #2d2b2b (neutral-900) | The screen behind everything. |
| surface | #eae9e9 | #444141 (neutral-800) | Raised things: dialogs, the frame around a page image. |
| text | #201f1d | #f8f4f4 (neutral-100) | All text. |
| accent | #b68235 | #e1ad66 (accent-400) | The one gold. Buttons, chevrons, the checked switch, focus. |
| divider | text at 16% | #f8f4f4 at 22% | Hairlines between rows and around outlined controls. |
| text-muted | text at 55-60% | same rule | Subtitles, captions, slider end labels. |
```

`accent-2` exists in the stylesheet but is a machine-derived stand-in. This is a **one-accent**
scheme. Ignore it.

Ramps, same in both themes. Use 100-300 for tinted fills and hovers, 500 as the base, 700-900
for text on a tinted fill and for pressed states.

```
| Step | Neutral | Accent |
| --- | --- | --- |
| 100 | #f8f4f4 | #fff3e4 |
| 200 | #eae7e7 | #ffe3bf |
| 300 | #d7d3d3 | #facb8d |
| 400 | #bab6b6 | #e1ad66 |
| 500 | #9b9797 | #c28d41 |
| 600 | #7d7979 | #a06f24 |
| 700 | #605d5d | #7d5411 |
| 800 | #444141 | #5a3b0a |
| 900 | #2d2b2b | #3a270d |
```

Interaction tints, because a native control must not fall back to its platform default here:

```
| State | Value |
| --- | --- |
| hover, accent control | accent at 12% over the ground |
| pressed, accent control | accent at 22% over the ground (dark theme: accent-400 at 26%) |
| hover, neutral control | text at 7% |
| pressed, neutral control | text at 14% |
| row pressed | accent at 14% |
| focus ring | 2 px accent, 2 px outside the control |
| disabled | disabled text colour and a hairline border, never opacity |
| destructive text and border | accent-700 light, accent-300 dark |
```

There is no red anywhere. That is the style's choice, and one of the two places to watch while
building, named in AGENTS.md.

## Type

```
| Name | Face | Weight | Used for |
| --- | --- | --- | --- |
| heading | Cormorant Garamond | 600 | Titles, buttons, row titles, dialog titles. |
| body | Lora | 400 | Everything else. |
```

Body text is 15 px, line height 1.55. Headings have line height 1.12 and letter spacing
-0.015em.

```
| Size | px | Where |
| --- | --- | --- |
| h1 | 42 | not used in the app |
| h2 | 32 | not used in the app |
| h3 | 25 | not used in the app |
| h4 | 20 | dialog title |
| h5 | 16 | - |
| h6 | 13 | uppercase, letter spacing 0.08em, section label |
| row title | 17 | scan row title, card title |
| body | 15 | screen text |
| control | 14 | button label, input, switch row, slider head |
| sub | 13 | scan row subtitle, card body |
| meta | 11 | slider end labels, captions |
| kicker | 10 | uppercase, letter spacing 0.1em |
```

Anything that is a number on screen - page counts, degrees, dates - uses tabular figures, so
it does not jump while it counts.

## Spacing

One step is 4.6 px. Use the steps, not free numbers.

```
| Name | px |
| --- | --- |
| space-1 | 4.6 |
| space-2 | 9.2 |
| space-3 | 13.8 |
| space-4 | 18.4 |
| space-6 | 27.6 |
| space-8 | 36.8 |
```

Screen padding is space-4. A button's padding is space-2 vertical, space-3 x 1.2 horizontal.

## Radius

```
| Name | px | Where |
| --- | --- | --- |
| radius-sm | 2 | tags and small chips |
| radius-md | 4 | buttons, inputs, cards, the swipe action |
| radius-lg | 7 | dialogs |
| round | 50% | shutter, switch knob, slider thumb |
```

## Shadow

Light theme: ink-tinted, from neutral-900. Dark theme: plain black, heavier, because a tinted
shadow is invisible on a dark ground.

```
| Name | Light | Dark |
| --- | --- | --- |
| shadow-sm | 0 1px 2px neutral-900 at 14% | 0 1px 2px black at 50% |
| shadow-md | 0 3px 10px neutral-900 at 16% | 0 3px 10px black at 55% |
| shadow-lg | 0 12px 32px neutral-900 at 22% | 0 12px 32px black at 60% |
```

Only the dialog is raised (shadow-lg). Rows, buttons and cards are flat and outlined - in this
theme colour is a stroke, not a fill.

## Fixed sizes that are not tokens but are decided

```
| Thing | Size |
| --- | --- |
| shutter | 72 px circle, 1 px divider border, inner 4 px bg ring, then 1 px accent ring |
| switch | 42 x 24, knob 16, travel 3 to 21 |
| slider | 1 px track, 17 px round thumb, bg fill, 1 px accent border |
| icon button | 36 x 36 |
| input | min height 36 |
| swipe action | 96 wide |
```

Those are the drawn sizes. The **touch** target is 44 pt minimum regardless - see
[platform-rules.md](./platform-rules.md).
