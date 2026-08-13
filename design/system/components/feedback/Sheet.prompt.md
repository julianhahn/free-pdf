# Sheet

The raised surface the PDF reader opens on: the scan's date on top, one close control, the pages below. Use it when a screen has to cover the one under it and can be closed again.

```jsx
<Sheet title="11 Aug 2026, 20:14" onClose={close}>
  <PageImage label="1" />
</Sheet>
```

The close label is "Close the PDF" unless you pass another one. The header has no fixed height, so a long title wraps to two lines and the content keeps its full room; only the content area scrolls, and the hairline under the header stays.
