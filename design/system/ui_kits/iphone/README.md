# UI kit — FreePDF for iPhone

A click-through recreation of the whole scan flow at 390 × 844, built only from this system's
components. Open `index.html`; the row of buttons under the phone jumps between screens and
flips light/dark.

| File | Screen | Source |
| --- | --- | --- |
| `ScansScreen.jsx` | Scans list, swipe-to-delete, delete dialog, empty state, drain progress | `components.md` > Scan row, Empty state, Confirmation dialog, Progress |
| `CameraScreen.jsx` | Viewfinder, page counter, shutter, shot-page rail, "Scan 8 pages" | `components.md` > Camera screen, Shutter |
| `PagesScreen.jsx` | Page carousel, thumbnail rail, Page menu, Grey switch, Make PDF | `components.md` > Page carousel |
| `AdjustScreen.jsx` | Tool row, sliders on the engine's suggestion, apply-to-all, Reset | `components.md` > Adjust controls |
| `DoneScreen.jsx` | PDF ready, name field, Open/Share, destructive block + footnote | `components.md` > Done screen |
| `Chrome.jsx` | App bar, screen scaffold, status line | not in the source; see readme.md > Intentional additions |

Cut corners, on purpose: no real camera, one page image placeholder standing in for every
page, three or four rows standing in for forty. Copy is verbatim English from `components.md`;
the German column lives in readme.md and is not rendered here.
