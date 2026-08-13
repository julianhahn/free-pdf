# PageHandles

Drag handles drawn over a page. Use it on the Edges step (four corners) and the Crop step (eight grips), when the user moves the frame by hand.

```jsx
<PageHandles src={page.url} count={4} inset={8} style={{ width: 240 }} />
<PageHandles src={page.url} count={8} inset={18} refused />
```

Each grip is 11px of paint inside a 44pt touch target, so the drawing stays small and the target stays big; `held` grows it to 13px without changing colour. `refused` turns the edge and grips destructive, adds the inset ring, and announces the sentence once as an alert — the handles keep their own labels.
