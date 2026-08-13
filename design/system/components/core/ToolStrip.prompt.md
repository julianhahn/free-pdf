# ToolStrip

The row of adjust tools under a page. Use it wherever the user picks which adjustment to work on.

```jsx
<ToolStrip
  items={[
    { label: "Edges", icon: "scan" },
    { label: "Straighten", icon: "ruler" },
    { label: "Brightness", icon: "sun" },
    { label: "Sharpen", icon: "focus" },
    { label: "Crop", icon: "crop" },
    { label: "Turn", icon: "rotate-cw" },
  ]}
  active="Edges"
  onSelect={setTool}
/>
<ToolStrip items={tools} />
```

With no `active` every tool is passive; the active one is matched by label, so labels have to be unique. The row scrolls sideways instead of wrapping, and `state="pressed" | "focus"` draws the active tool held or focused at rest.
