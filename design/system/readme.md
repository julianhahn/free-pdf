# FreePDF Design System

FreePDF turns sheets of paper into one PDF, with the camera. You photograph the pages, the app
cleans each photo up, then it makes the PDF. Everything stays on the phone: no account, no
sign-in, no server, no settings screen. Nothing leaves until the user taps Share.

It is a tool, not an opinion. It hands the controls over instead of deciding: where the paper
edges are, how straight, how bright, how sharp. Every control opens on the value the engine
suggested, and the user may just accept it.

There will be several clients — iPhone first, more later. **The style is defined once, here, and
each client rebuilds it in its own toolkit.** Only gestures and control mechanics follow the
platform. A platform-native look is by definition not recognizable across platforms; two clients
that each look like their own operating system are not one product.

## Sources this system was built from

The mounted, read-only folder `client-guide-design-system/` — the client guide itself, four
files, no code:

- `AGENTS.md` — what the guide decides, what a client agent may and may not invent.
- `vision.md` — Julian's decision, 2026-08-13: paper and archive. The direction, and what
  makes a design wrong. Decided.
- `tokens.md` — every colour, size, spacing step, radius and shadow, light and dark. Marked
  **provisional**: the values were read off a stylesheet that the delivered gallery never used.
- `components.md` — every component the app needs, its states, and its EN/DE copy.
- `platform-rules.md` — what "rebuild natively" means, plus the accessibility floor.

Referenced by those files but **not** mounted, so not read: `../user-flows.md` (owner of
behaviour), `../design/` (the earlier gallery and its stylesheet), `../storybook/` (three
interim components), `../ios/` (the iPhone client). No Figma file, no repository, no screenshots,
no font binaries and no logo were supplied.

**What this system did with the provisional tokens.** The guide names this round as the one that
redraws every component and states its own token set. The token values here are the ones from
`tokens.md`, adopted unchanged, because the direction they express is the decided one — plus
these additions, made to solve the two tensions the guide flagged rather than to reopen the
style:

- `--paper` (#fdfcfa light / #e9e5e0 dark) — a page image's ground, and the shutter's disc.
- `--viewfinder` (#1b1a19 / #131211) — the dark ground behind a live preview.
- `--divider-strong` (text 32% / 38%) — a slider track and an off switch, which a 16% hairline
  loses at arm's length.
- **The shutter** keeps its 72 px and its stroke, but the accent ring goes to 2 px and the
  inside is a solid `--paper` disc: the sheet you are about to photograph. It is found by its
  light mass, not by its outline, which is what a thumb needs on a dark, moving picture. This
  is the "solid shape where a stroke is too thin" that `vision.md` allows.
- **Destructive without red** is carried three ways at once, never by colour alone: the words
  ("Delete the 40 photos (78 MB)", "This cannot be undone"), accent-700 / accent-300, and a
  **double rule** — an inset 1 px ring inside the border, so a destructive button is a different
  *shape* from a secondary one.
- **The viewfinder frame** is four accent corner marks, not a continuous hairline rectangle: on
  a dark moving picture a thin continuous line reads as part of the scene.

Everything else — the six roles, both ramps, the two faces, the size steps, the spacing steps,
the radii, the shadows, "stroke, not fill", one accent, tabular figures, all copy in both
languages — is the guide's, unchanged.

---

## Content fundamentals

**Who speaks.** The app does not. There is no "we", no brand voice and no personality. Copy
states what is true or what to do, then stops.

**Person.** Second person, only where an instruction needs it: "You can close the app." German
is **du**, never Sie: "Du kannst die App schließen." Never "I" — the app has no self.

**Casing.** Sentence case everywhere, including buttons: "New scan", "Make PDF", "Delete
photos", "Back to the suggestion". Not "New Scan". Uppercase appears only in the h6 section
label and the 10 px kicker, never in a sentence.

**Punctuation.** Full stops on sentences, none on button labels or row subtitles. The em dash
with spaces separates a count from its state: `40 pages — PDF ready`. An ellipsis marks a
running action: `Applying…`, `Making the PDF…`. No exclamation marks anywhere.

**Numbers.** Always digits, always concrete, always tabular: `12 of 40 pages scanned`,
`Delete the 40 photos (78 MB)`, `Page 3 of 12`. Titles are dates, `11 Aug 2026, 20:14`, and a
scan cannot be renamed — the date is the title.

**Errors.** The engine's own finished sentence, printed unchanged; the client never rewrites it.
Per-page camera failures use one shape, and it always ends by saying what survived:
`Page 7 was not saved: <why> Nothing already photographed is lost.`

**Destructive copy names what goes.** "40 pages, the PDF and 40 photos go. This cannot be
undone." Not "Are you sure?".

**Reassurance is factual, not warm.** "You can close the app. It carries on from here." /
"Keep the app open." Those two notes say opposite things on purpose: the drain resumes after a
kill, apply-to-all does not.

**No emoji. Ever.** No mascots, no exclamations, no marketing adjectives ("beautifully clean
scans"), no first-person plural, no "oops".

Say / not say:

| Say | Not |
| --- | --- |
| Tap New scan and photograph the pages, one after another. | Let's get scanning! 🎉 |
| The page runs off the frame. Move back and photograph it again. | Oops — something went wrong. |
| 40 pages — PDF ready, photos deleted | All done! Your PDF is ready 🎉 |
| Photograph at least one page | Please take a photo to continue |

Every string exists in English and German, verbatim as in `components.md`; the full tables are
reproduced in `guidelines/copy.md`.

## Visual foundations

**The direction: paper and archive.** A light ground, serif titles, fine hairlines, a lot of
quiet. A well-kept folder of documents — not a phone app, and not a piece of measuring
equipment. The app's whole subject is paper, and a style borrowed from the paper it scans is the
one style that explains itself without a word.

**Colour.** Six roles, one accent, both themes. Light: bg #f3f2f2, surface #eae9e9, text
#201f1d, accent #b68235, divider text at 16%, muted text at 58%. Dark: neutral-900, neutral-800,
neutral-100, accent-400, 22%, 58%. Two nine-step ramps (neutral, accent) identical in both
themes: 100–300 tinted fills and hovers, 500 base, 700–900 text on a tint and pressed states.
**There is no red and no green anywhere**, and no second accent. The greys are warm — every
neutral leans to paper, never to blue.

**Type.** Two faces only. **Cormorant Garamond 600** for titles, buttons, row titles and dialog
titles, line height 1.12, letter spacing −0.015em. **Lora 400** for everything else, 15 px at
1.55. Sizes: h4 20 (dialog title), row title 17, body 15, control 14, sub 13, h6 13 uppercase
0.08em, meta 11, kicker 10 uppercase 0.1em. h1 42 / h2 32 / h3 25 exist and are not used in the
app. Every number on screen is tabular so a counter does not shuffle while it counts.

**Spacing.** One step is 4.6 px: 4.6, 9.2, 13.8, 18.4, 27.6, 36.8. Screen padding is space-4.
A button's padding is space-2 vertical, 16.56 px horizontal. Free numbers are not allowed; the
only exceptions are the decided control sizes below.

**Layout.** Single column, one thing at a time, no tabs and no navigation bar with more than a
back arrow and one trailing action. The screen's action is a full-width button pinned in a
footer above a hairline; the content scrolls behind nothing. Portrait, fixed. Page images are
always 3:4.

**Backgrounds.** Flat colour, nothing else. No gradients, no photographs behind text, no
patterns, no paper texture, no noise. The one "image" in the system is a page image, and it is
content. Full-bleed is reserved for the viewfinder.

**Cards, or the absence of them.** There are none. Rows, buttons, switches, sliders and the
shutter are **flat and outlined** — in this theme colour is a stroke, not a fill. A filled
platform-default button is the one thing that breaks the look immediately. The page frame is the
only container: paper ground, 1 px divider border, radius-md, shadow-sm. The dialog is the only
raised thing in the app: surface, radius-lg, shadow-lg.

**Borders and hairlines.** 1 px, divider (16% / 22%) between rows and around outlined controls;
divider-strong (32% / 38%) for a slider track and a switch that is off; accent for an active
edge; a double rule (border plus inset ring) for a destructive edge. Never 2 px as decoration —
2 px is reserved for the focus ring, the shutter ring and the viewfinder corners, where it
carries a function.

**Radii.** 2 chips and tags · 4 buttons, inputs, page frames, swipe action · 7 dialogs · round
for the shutter, the switch knob and the slider thumb. Nothing else is rounded.

**Shadows.** shadow-sm 0 1px 2px ink 14%, shadow-md 0 3px 10px ink 16%, shadow-lg 0 12px 32px
ink 22%; light-theme shadows are tinted from neutral-900, dark-theme ones are plain black and
heavier because a tinted shadow is invisible on a dark ground. Only the page frame (sm) and the
dialog (lg) use them. No inner shadows anywhere except the 1 px inset that seats the shutter
disc.

**Hover and press.** Accent control: hover accent at 12%, pressed accent at 22% (dark:
accent-400 at 26%). Neutral control: hover text at 7%, pressed text at 14%. A pressed row is
accent at 14% across the full bleed. Nothing darkens by filter, nothing changes colour on
press, and only the shutter scales — 0.94, because a thumb covers it and mass is the only
feedback left.

**Focus.** 2 px accent, 2 px outside the control, for anything a keyboard or switch control can
reach. Disabled takes the `--disabled-*` colour roles, never opacity.

**Transparency and blur.** Almost never. Two places: the dialog's scrim (neutral-900 at 38%),
and the page counter over a viewfinder (viewfinder at 66% with a 6 px blur), because text over
a moving picture needs a ground. No frosted panels, no translucent bars.

**Animation.** Timing and easing are the platform's — no numbers are prescribed. What is
prescribed is restraint: a state change is a colour or an opacity, 120–180 ms, linear or
ease-out. The switch knob travels 3 → 21 px, the swipe action slides, the progress bar's width
grows. No bounces, no spring overshoot, no page transitions that fly, nothing that pulses or
breathes, and no skeleton shimmer — a progress line says what is happening in words instead.

**Imagery.** Page images are the app's imagery, and there is no other kind: no stock
photography, no illustration, no mascot. They are warm and neutral, never colour-graded; grey
mode is a real greyscale of the page, set by the user. The frame is drawn by the system, the
picture inside it is the user's own. **This kit ships no photographs** — `PageImage` without a
`src` draws a ruled placeholder so density and rhythm can be judged. Replace it with real pages
in product; ask for real sample scans before a review.

**Iconography.** See below.

## Iconography

The sources contain no icon set, no icon font, no SVG sprite and no PNGs — `components.md`
names glyphs only in words ("accent chevron", an icon on the empty state). So:

- **Substitution, flagged:** icons are **Lucide** (`lucide-static` 0.544.0, loaded from unpkg),
  chosen for a single uniform stroke and no fills, which is the nearest thing to a hairline in a
  maintained set. Every glyph goes through `<Icon>`, which paints it with a CSS mask so it
  carries accent or text colour rather than its own. **If FreePDF has a real icon set, send it
  and `Icon.jsx` changes in one place.**
- Sizes: 18 in a row chevron, 17 in menus and tool chips, 20 in an icon button, 22–30 in an
  empty state or a failure card. Stroke is Lucide's own; never re-weighted per icon.
- Colour: accent for anything that leads somewhere (chevron, menu glyph), text-muted for a
  passive tool, destructive for a delete item or a refused page. Never two colours in one glyph.
- Icons never appear inside a text button. A button is its words.
- **No emoji, ever** — not in UI, not in copy, not in documentation. No unicode glyph is used as
  an icon either; the em dash and the ellipsis are punctuation, not decoration.
- **No logo was supplied**, so none is drawn. Where a mark would go, the name is set in
  Cormorant Garamond 600 — see `guidelines/brand-wordmark.html`. Do not invent one.

## Fonts

Cormorant Garamond and Lora, both from Google Fonts, loaded in `tokens/fonts.css` via the
Google Fonts CSS API because **no font binaries were supplied**. These are the two faces the
guide names, so this is not a visual substitution — but a client that must work offline needs
the actual files. **Please send the licensed `.woff2`/`.ttf` files** (or confirm the Google
Fonts copies are the shipping ones) and the `@font-face` rules will point at local assets
instead. Platform system fonts are never a fallback: the stack falls back to Garamond / Georgia,
both serifs, and never to SF Pro or Roboto.

---

## Components

Exactly the families `components.md` defines, plus the additions listed under it.

| Component | Group | What it is |
| --- | --- | --- |
| `Button` | core | Outlined primary / secondary / destructive / ghost, disabled, busy |
| `IconButton` | core | 36 px drawn, 44 pt tappable glyph button |
| `Shutter` | core | 72 px accent ring around a solid paper disc; disabled while writing |
| `SectionLabel` | core | h6 uppercase group label |
| `Icon` | core | Lucide glyph, recoloured by CSS mask |
| `ToolStrip` | core | The adjust tools in a row, one chosen, an accent underline under it |
| `Switch` | forms | 42 × 24 outlined switch row (Grey, Apply to all pages) |
| `Slider` | forms | Hairline track, 17 px thumb, value in tabular figures, suggestion tick |
| `TextField` | forms | The name for the shared copy — the app's one input |
| `PageImage` | document | A scanned page in its paper frame; placeholder, grey and refused states |
| `PageCounter` | document | "Page 3 of 12" on a solid ground, light or over a viewfinder |
| `Viewfinder` | document | 3:4 dark preview stage with accent corner marks |
| `PageStrip` | document | The rail of page thumbnails, plus a jump to a page number |
| `PageHandles` | document | Drag handles over a page: four corners on Edges, eight grips on Crop |
| `ScanRow` | lists | One scan: date, derived subtitle, chevron, hairline, swipe-to-delete |
| `MenuList` | lists | The Page menu |
| `ConfirmDialog` | feedback | The one raised surface; all three deletions ask, always |
| `ErrorLine` | feedback | The engine's own sentence, above the content |
| `ProgressLine` | feedback | A line, a 3 px bar, a note (the drain and apply-to-all) |
| `EmptyState` | feedback | No scans yet |
| `Sheet` | feedback | The raised surface the PDF reader opens on: a title, one close, the pages |

Each directory holds `<Name>.jsx`, `<Name>.d.ts` and `<Name>.prompt.md`.

### Intentional additions

Not in `components.md`; each earns its place and none introduces a new visual rule.

- `Icon` — the guide names glyphs but ships no set. One wrapper means one place to swap it.
- `Viewfinder`, `PageCounter` — `components.md` describes the camera screen's frame and counter
  in prose; they are drawn once here so every client frames the preview identically.
- `PageImage` — the guide describes page images and the refused-page card but names no
  component. The app is mostly pictures; this is the shape they live in.
- `SectionLabel` — the h6 label exists in `tokens.md` with nothing to put it in.
- `TextField` — the done screen has a name field with no component entry.
- `PageStrip`, `ToolStrip`, `PageHandles`, `Sheet` — the four the flows asked for and this kit
  did not have: the page rail, the tool row, the drag handles and the PDF reader's surface.
- `Chrome.jsx` in the UI kit (app bar, screen scaffold, status line) — kit-local, not a
  primitive, because the guide leaves presentation to the platform.

Nothing else was added: no toast, no avatar, no tabs, no card. The app has no such screens.

## Index

| Path | What it is |
| --- | --- |
| `styles.css` | The one file a consumer links; `@import`s everything below |
| `tokens/colors.css` | Six roles, two ramps, interaction tints, light and dark |
| `tokens/typography.css` | Faces, size steps, tracking, tabular figures, helper classes |
| `tokens/spacing.css` | The 4.6 px steps, screen and button padding, 44 pt floor |
| `tokens/radius.css`, `tokens/elevation.css` | Radii; the three shadows and the hairline |
| `tokens/controls.css` | Decided drawn sizes: shutter, switch, slider, icon button, swipe |
| `tokens/fonts.css`, `tokens/base.css` | Font stacks; body and link resets |
| `guidelines/*.html` | 19 specimen cards: colours, type, spacing, brand |
| `guidelines/copy.md` | Every string, English and German, from `components.md` |
| `components/{core,forms,document,lists,feedback}/` | The 21 components above |
| `ui_kits/iphone/Chrome.jsx` | App bar, screen scaffold and status line the flow stories build on |
| `thumbnail.html` | The system's tile |
| `SKILL.md` | Agent-skill wrapper for use outside this project |

## Open questions for the client guide

1. Real page photographs — three or four sample scans would let the page frame, the thumbnail
   rails and the grey switch be judged on real material instead of placeholders.
2. The licensed font files (see Fonts).
3. The real icon set, if one exists (see Iconography).
4. A wordmark, or confirmation that plain type is the mark.
5. `../user-flows.md` was not mounted, so screen order in the UI kit follows `components.md`
   only. It should be read before this kit is used to settle behaviour.
