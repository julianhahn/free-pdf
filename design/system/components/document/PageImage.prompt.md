# PageImage

Any scanned page or photo, in the system's paper frame. Use it for carousel pages, thumbnails and scan-row leads.

```jsx
<PageImage src={page.url} label="7" style={{ width: 96 }} />
<PageImage state="refused" refusedText="This page could not be scanned." />
```

With no `src` it draws the ruled placeholder — fine for mocks, replace with real photos in product. `grey` mirrors the Grey switch.
