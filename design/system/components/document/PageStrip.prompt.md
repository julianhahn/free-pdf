# PageStrip

The rail of page thumbnails under a page view, plus a jump to a page number. Use it wherever a scan has more pages than a person wants to swipe through.

```jsx
<PageStrip pages={pages} selected={3} total={12} onSelect={setPage} />
<PageStrip pages={pages} selected={12} total={40} jump={jump} onJumpToggle={toggleJump} jumpValue="37" onJumpSubmit={goTo} />
```

Every tile is a `PageImage`, so a refused page shows the same refusal here as anywhere else. `jump` is owned by the parent: the "Go to page" button calls `onJumpToggle` and the parent flips it; when `selected` changes from outside, the rail scrolls that tile into view.

The jump appears from ten pages up. Under that, `total` decides and the rail is the rail and nothing else — the button and the field are both left out, whatever `jump` says. Ten is Julian's number, decided on 2026-08-16 because "Go to page" on a one page scan has nowhere to go.
