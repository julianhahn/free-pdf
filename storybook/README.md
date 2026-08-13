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

## One style, and it is decided

What stands here is the style, not a candidate: Cormorant Garamond over Lora, one gold accent,
outlined controls. Julian chose it on 2026-08-13, so the iPhone-system-look variant that used
to sit beside it is deleted - git has it if anyone wants to look. The numbers behind these
stories are written down in
[`../client-guide-design-system/tokens.md`](../client-guide-design-system/tokens.md).

## Nothing in here ships

This is a design sandbox. No code from this folder ends up in the app. Once a component is
approved here, it is rebuilt natively in SwiftUI under `ios/`.
