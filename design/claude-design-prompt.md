# Design prompt — FreePDF (paste into Claude Design)

## How the output will be used

The designs are built twice. First as plain web components in a Storybook in this
repository, so Julian can look at each component on its own and approve it one by one.
Only after that are they rebuilt natively in SwiftUI for the iPhone. So every component
must stand on its own and be describable without a screen around it: its name, its
states, its sizes, its colours, its spacing, and what it does. A picture of a whole
screen is not enough. Target is the iPhone in portrait only — no Android, no web app,
no desktop.

## What the app is

FreePDF turns sheets of paper into a PDF, using the iPhone camera. You photograph the
pages one after another, the app cleans each photo up so it looks like a scan, and then
it makes one PDF out of them. Everything happens on the phone: no account, no sign-in,
no server, nothing is uploaded unless the user themselves taps Share.

## Who uses it, and how it should feel

Someone standing at a desk with a stack of paper in one hand and the phone in the other.
Often one-handed. They want the scan done and the app gone.

The app is a tool, not an opinion. It hands over the controls instead of deciding for the
user: where the paper edges are, how straight, how bright, how sharp — all adjustable
afterwards, on a page the user can already see, and all pre-set to a sensible suggestion
the user can just accept. It never nags, never
suggests a cloud, never asks to be configured.

The feeling: calm, quiet, fast, out of the way. Plain type, plenty of air, no decoration
that has to be looked past. Buttons big enough to hit while holding paper. Nothing
animated for its own sake.

Vocabulary to use throughout, exactly these words: a scan is made of **pages**, a page
starts as a **photo**, the finished result is **the PDF**.

---

## Screens to design

### 1. Scans (the list, and the landing screen)
- Title "Scans", one action "New scan" in the top right.
- Row: a date as the title (e.g. "11 Aug 2026, 20:14"), one line of status under it, a
  chevron. There is no renaming — the date is the name.
- Status line variants: "No pages yet" / "8 pages — keep shooting" / "12 of 40 pages
  scanned" / "40 pages — ready to check" / "40 pages — PDF ready" / "40 pages — PDF
  ready, photos deleted".
- States: empty (icon + "No scans yet" + "Tap New scan and photograph the pages, one
  after another. You can stop whenever you like."), a list of rows, an error line at the
  top of the list (red, one sentence, e.g. the phone is out of storage).
- Swipe a row left → Delete → confirmation dialog.

### 2. Delete-a-scan confirmation
- "Delete this scan?" / "40 pages, the PDF and 40 photos go. This cannot be undone." /
  Delete scan · Cancel.

### 3. Camera (shooting pages)
- Back to Scans, title is the page the next shot lands on: "Page 7".
- Live preview, 3:4, portrait only.
- One big shutter button, thumb-reachable. Nothing else on the screen: no thumbnail of
  the last shot in the corner, no way to pick a photo from the phone's photo library.
- Below it: "Scan 8 pages" — the button that ends shooting and starts the cleanup.
- States: normal; shutter disabled while the photo is being written (one press = one
  page); "Scan 8 pages" disabled when nothing has been shot yet.
- Error states on this screen: a one-line red banner over the preview for a photo that
  did not save ("Page 7 was not saved: the iPhone is out of storage. Nothing already
  photographed is lost."), and full-screen takeovers for: camera permission denied
  (sentence + "Open Settings"), no camera hardware, camera could not start.

### 4. Scanning (progress)
- One line "Scanning page 4 of 12", a progress bar, and the note "You can close the app.
  It carries on from here."
- A page the cleanup refuses shows a red line and the run continues.

### 5. Pages (checking and retaking)
- Title "Page 3 of 12". A carousel, one page per swipe, pinch to zoom.
- Page dots below with left/right arrows, plus a way to jump straight to a page number
  (40 pages must not mean 40 swipes).
- A "Page" menu (top right): Retake this page · Adjust page · Delete page. On a finished
  scan a fourth item, "Shoot another page", which reopens the camera and the PDF is made
  again afterwards.
- One switch for the whole scan, on this screen: Colour / Grey. It is not inside Adjust.
- Primary button at the bottom: "Make PDF"; while running "Making the PDF…". It only
  appears once every photo has become a page.
- States: a good page; a refused page (a card saying "This page could not be scanned."
  with a "Scan this page again" action instead of an image); while the PDF is being made
  the button shows "Making the PDF…" and the pages stay visible; an error line if making
  the PDF fails.
- Delete-a-page confirmation: "Delete this page?" / "The photo goes too. This cannot be
  undone."

### 6. Adjust a page
- Reached only after the app has already cleaned the pages, from a page the user can see.
- There is no live preview anywhere in this app. The picture on this screen is the page
  as it stands now; nothing on it changes while values are moved. The user sets the
  values, taps Apply, waits about a second, and then looks at the result.
- Top bar: Cancel · "Adjust page 3" · Apply.
- Large picture of the page; when the Edges or Crop tool is active, four drag handles sit
  on it, pre-set to the corners the app found.
- A strip of tools, one active at a time: Edges · Straighten · Brightness · Sharpen ·
  Crop · Turn.
- Under it, the controls for the active tool:
  - Edges: four drag handles + an on/off switch "Pull the sheet flat"; a note line
    underneath ("The sheet fills the whole photo, so there is nothing to cut away." or
    the warning "The page runs off the frame. Move back and photograph it again.")
  - Straighten: one slider −10…+10 degrees, current value shown with one decimal
  - Brightness: two sliders + an on/off. Black point = how dark the darkest part becomes,
    white point = how bright the paper becomes
  - Sharpen: one slider 0…20, opening at 0.6; 0 means no sharpening
  - Crop: drag handles on the page picture
  - Turn: one button, a quarter turn per tap
- Every control starts on the value the app suggested. A "Back to the suggestion" reset.
- A switch at the bottom: "Apply to all pages".
- States: applying to one page (brief); applying to all pages — full-screen progress
  "Applying to 40 pages…", a bar, "Page 12 of 40", and the note "Keep the app open."

### 7. PDF ready (the done screen)
- Title "PDF ready".
- A text field labelled "Name for the shared copy", empty, showing "scan" as placeholder.
  The name is used only for the copy that leaves through Share. Nothing is stored — reopen
  the scan and the field is empty again; the scan itself keeps its date name.
- Two primary buttons: "Open PDF", "Share PDF". Below them a plain text action "Change
  pages".
- A quiet destructive area at the bottom: "Delete the 40 photos (78 MB)" with the
  footnote "The PDF stays. Deleted photos cannot be brought back."
- State: photos already deleted → the destructive area is simply gone.
- Confirmation: "Delete the 40 photos?" / "The PDF stays. Without the photos the pages
  can no longer be adjusted."

### 8. PDF reader sheet
- The finished PDF shown inside the app, a sheet with a close control. Nothing else.

---

## Components to design, one by one

Name each one; the code will use the same name.

1. Primary button (full width) — normal, pressed, disabled, busy-with-label.
2. Secondary / plain text button.
3. Destructive button — the quiet kind, with a footnote line under it.
4. Top bar — back, title, one trailing action or menu.
5. Scan row — date title, status line, chevron; plus its swipe-to-delete state.
6. Empty state — icon, headline, one paragraph, nothing else.
7. Error banner — one red line, inline at the top of a list or over the camera preview.
8. Confirmation dialog — title, body, destructive confirm, cancel.
9. Shutter button — the big round one, plus its disabled moment.
10. Camera page counter / title treatment.
11. Camera permission takeover — sentence plus "Open Settings".
12. Progress block — line of text, bar, reassurance note.
13. Page carousel — the page image frame, the swipe, the page dots with arrows, and the
    jump-to-page control (numbers, no thumbnails).
14. Refused-page card — message plus a retry action, sitting where the page image would.
15. Page menu — three items while checking, four on a finished scan, delete marked destructive.
16. Tool strip — a row of tool names, one selected.
17. Labelled slider — name, current value, min/max ends, and the reset.
18. Labelled switch — used for "Pull the sheet flat", Colour / Grey, "Apply to all pages".
19. Crop / edge handles on a preview.
20. Text field — used once, on the done screen, labelled "Name for the shared copy",
    placeholder "scan".

---

## Hard constraints

- iPhone, portrait only. iOS 18 and up. No iPad, no landscape.
- System fonts and system type sizes; Dynamic Type must not break any layout.
- Design light **and** dark. Both are first-class.
- Every control needs a VoiceOver label written out, not implied.
- The shutter must sit where a thumb reaches it one-handed.
- No icon-only controls. Anything tappable carries a word, or a word next to the icon.
- Touch targets at least 44×44 pt.
- Text in English; German exists too, so leave room — German strings run roughly 30%
  longer.

## Do not design

- Anything that implies a network: no sync icon, no cloud, no upload, no "backing up",
  no progress that suggests something leaving the phone.
- No account, sign-in, profile, or onboarding carousel.
- No settings screen. There are no preferences; every choice is asked in the moment and
  never remembered.
- No branding beyond a plain app name. No illustrations that need explaining.
- No renaming a scan, no reorder, no insert-page.
- No live preview of an adjustment. Values are set, Apply is tapped, then the result is
  looked at. The camera viewfinder is the only moving picture in the app.
- No corner thumbnail on the camera, and no importing photos from the photo library.
- No delete that happens straight away — scan, page and photos each ask first.

## What to hand back

1. **Component specs** — one per component in the list above, with its name, its states,
   sizes and spacing, colours in both light and dark, and its VoiceOver label.
2. **Screen mockups** — every screen listed above, in each of its states, light and dark.
3. Name every component clearly and consistently, so the code can use the same names.
