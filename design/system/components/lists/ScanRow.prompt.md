# ScanRow

One scan in the Scans list. The title is the folder date; the subtitle is derived from the scan's state (seven of them).

```jsx
<ScanRow title="11 Aug 2026, 20:14" subtitle="40 pages — PDF ready" onPress={open} onDelete={confirmDelete} />
```

`swiped` reveals the 96 px Delete action; the swipe itself is the platform's swipe.
