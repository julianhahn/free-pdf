# FreePDF Storybook

A browser preview of the **delivered design system** in `../design/system/`. Nothing in here is
hand-drawn any more.

## Start

```
cd storybook
npm install   # first time only
npm run storybook
```

Opens on http://localhost:6006. Every story renders at iPhone size (390x844 portrait) by default —
the app is iPhone-portrait-only.

## What is in here

- All 21 delivered components, grouped as the system groups them: Core, Forms, Document, Lists,
  Feedback. Every state named in a component's `.prompt.md` / `.d.ts` is its own story.
- **Brand/AppIcon** — the decided app icon (6c), rendered from `../design/flows/brand/app-icon.svg` at the sizes the delivered document shows.
- **Flows** — the seven flow stories, each a whole screen of the app built from those components
  and the kit's chrome (`design/system/ui_kits/iphone/Chrome.jsx`).

## The components are imported, not copied

`ds.js` re-exports the components straight from `../design/system/components/`, and the stylesheet
`../design/system/styles.css` (which imports all tokens) is loaded in `.storybook/preview.js`.
Nothing is re-implemented here, so this Storybook cannot drift from what the designer delivered —
edit the design system and the stories change with it.

Vite is configured in `.storybook/main.js` for that: a `@ds` alias, `server.fs.allow` for the folder
outside this one, `react` / `react-dom` aliased into this folder's `node_modules` (the design system
has none), and one small transform that lets the iPhone kit's `<script type="text/babel">` files
(they read a global, export nothing) be imported as modules without touching them on disk.

## Nothing in here ships

This is a preview. No code from this folder ends up in the app; components are rebuilt natively in
SwiftUI under `ios/`.
