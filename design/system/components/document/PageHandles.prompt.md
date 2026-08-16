# PageHandles

Drag handles drawn over a page. Use it on the Edges step (four corners) and the Crop step (eight grips), when the user moves the frame by hand.

```jsx
<PageHandles src={page.url} count={4} inset={8} style={{ width: 240 }} />
<PageHandles src={page.url} count={8} inset={18} refused />
```

Each grip is 11px of paint inside a 44pt touch target, so the drawing stays small and the target stays big; `held` grows it to 13px without changing colour. `refused` turns the edge and grips destructive, adds the inset ring, and announces the sentence once as an alert — the handles keep their own labels.

`held` also puts up the magnifier: a round loupe about a fingertip across, showing the same picture blown up around the grip with a crosshair on the grip itself. A handle sits under the fingertip that drags it, so the corner is aimed with the crosshair, not with the finger. It takes no touch, a screen reader never announces it, and it is never drawn while the handles are `refused`.

**Where it goes.** Not beside the finger — on the far side of the picture from it, so the hand is nowhere near it. Hold a grip on the left half and the loupe docks right; hold one on the right half and it docks left; a grip exactly on the middle docks left, so it never flickers. The dock is a place, not a distance: one small step in from the picture's edge, at the finger's own height. If the finger is so near the top or bottom that the circle would leave the picture, the circle slides inward just enough — the height the magnified spot is drawn at does not move with it.

**How the user knows it is his finger.** One rule runs level from under the fingertip across the picture and into the circle: the crosshair's own horizontal arm, made long. Same colour, same thickness, one stroke. It reads as a leader line — the mark every printed diagram uses to say "this circle is that spot" — so nothing has to be explained. It is drawn under the magnified picture, so it visibly runs into the circle and stops at the rim; it never crosses the loupe, because that would cover the paper edge the loupe exists to show. It carries a hairline of paper around it, the same trick the grips use, so it survives a dark photo. When the finger crosses the middle of the picture the loupe swaps sides and the same one rule simply points the other way — no animation, the kit has no motion tokens.

**What leaves.** While a grip is held, the other grips stop being painted — three marks fewer on Edges, seven fewer on Crop. Their touch targets, their labels and their hit testing are untouched; only the paint goes. Nothing at all is drawn over the working corner any more.

```jsx
<PageHandles src={photo.url} count={4} inset={7} held={2} style={{ width: 240 }} />
```
