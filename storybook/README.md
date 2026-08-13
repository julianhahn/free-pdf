# FreePDF Storybook

A browser preview of the app's UI components, written in plain HTML + CSS, so designs can be
looked at and approved before anything is built.

## Start

```
cd storybook
npm install   # first time only
npm run storybook
```

Opens on http://localhost:6006. Every story renders at iPhone size (390x844 portrait) by default —
the app is iPhone-portrait-only.

## The three components in here are an interim

Scan row, buttons and the adjust controls were built here, in this repository, from a
stylesheet the delivered gallery never used - they are not the designer's work and they are not
approved. A fresh design round is redrawing every component with its own token set, and these
three will be replaced by it. The brief is
[`../design/claude-design-components-prompt.md`](../design/claude-design-components-prompt.md);
the direction they must all meet is
[`../client-guide-design-system/vision.md`](../client-guide-design-system/vision.md). The
numbers behind the current stories are the provisional ones in
[`../client-guide-design-system/tokens.md`](../client-guide-design-system/tokens.md).

## Nothing in here ships

This is a design sandbox. No code from this folder ends up in the app. Once a component is
approved here, it is rebuilt natively in SwiftUI under `ios/`.
