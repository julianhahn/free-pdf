# Shutter

The camera shutter — the one control that must be found by thumb without looking.

```jsx
<Shutter label="Photograph page 7" onPress={shoot} />
<Shutter label="Photographing page 7, wait" onPress={shoot} disabled />
```

The label is the caller's: while the photo is being written it reads "Photographing page 7, wait".

Disabled while the photo is being written; that state is the rule that makes one press one page. Never fill it with accent and never shrink it below 72 px.
