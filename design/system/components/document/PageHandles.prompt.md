# PageHandles

Drag handles drawn over a page. Use it on the Edges step (four corners) and the Crop step (eight grips), when the user moves the frame by hand.

```jsx
<PageHandles src={page.url} count={4} inset={8} style={{ width: 240 }} />
<PageHandles src={page.url} count={8} inset={18} refused />
```

Each grip is 11px of paint inside a 44pt touch target, so the drawing stays small and the target stays big; `held` grows it to 13px without changing colour. `refused` turns the edge and grips destructive, adds the inset ring, and announces the sentence once as an alert — the handles keep their own labels.

`held` also puts the magnifier beside the grip: a round loupe about a fingertip across, showing the same picture blown up around the grip with a crosshair on the grip itself. A handle sits under the fingertip that drags it, so the corner is aimed with the crosshair, not with the finger. It sits above the grip, and below it when the grip is on the top edge and there is no room. It takes no touch, a screen reader never announces it, and it is never drawn while the handles are `refused`.

```jsx
<PageHandles src={photo.url} count={4} inset={7} held={2} style={{ width: 240 }} />
```
