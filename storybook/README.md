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

## Nothing in here ships

This is a design sandbox. No code from this folder ends up in the app. Once a component is
approved here, it is rebuilt natively in SwiftUI under `ios/`.
