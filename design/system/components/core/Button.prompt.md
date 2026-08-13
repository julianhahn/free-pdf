# Button

The screen's action, always outlined — use it for Make PDF, Open PDF, Share PDF, Cancel, Delete scan.

```jsx
<Button variant="primary" fullWidth onClick={makePdf}>Make PDF</Button>
<Button variant="secondary">Cancel</Button>
<Button variant="destructive">Delete the 40 photos (78 MB)</Button>
<Button variant="ghost">Back to the suggestion</Button>
```

primary = accent text and border; secondary = text colour, divider border; destructive = accent-700/300 with a double rule and words that say what goes; ghost = accent text, no border. `disabled` drops to 45% opacity and changes nothing else. `busy` for running labels ("Making the PDF…").
