# PageStrip

The rail of page thumbnails under a page view, plus a jump to a page number. Use it wherever a scan has more pages than a person wants to swipe through.

```jsx
<PageStrip pages={pages} selected={3} total={12} onSelect={setPage} />
<PageStrip pages={pages} selected={12} total={40} jump={jump} onJumpToggle={toggleJump} jumpValue="37" onJumpSubmit={goTo} />
```

Every tile is a `PageImage`, so a refused page shows the same refusal here as anywhere else. `jump` is owned by the parent: the "Go to page" button calls `onJumpToggle` and the parent flips it; when `selected` changes from outside, the rail scrolls that tile into view.
