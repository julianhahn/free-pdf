# TextField

The name for the shared copy on the done screen. There is no other text input in the app.

```jsx
<TextField label="Name for the shared copy" value={name} placeholder="scan" autoFocus onChange={setName} />
```

The done screen is reached by asking for the PDF, so someone who arrives there wants to type a
name: the field takes focus as the screen opens and the keyboard comes up with it. That is a
mount-time focus and nothing more — a redraw does not re-focus, so coming back from the share
sheet, the reader sheet or Change pages leaves the keyboard down. Everything under the field
stays reachable while the keyboard is up: the screen scrolls, it never shrinks or drops a block.

No suffix on the done screen: the field carries the label and the placeholder `scan`, and the
`.pdf` is not part of what is typed.
