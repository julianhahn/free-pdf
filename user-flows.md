# User flows

What the app does, screen by screen, as the redesign will build it. Everything here is
offline. One scan is one directory. The files are the only state, and the step the app
shows is read off the files every time, so a force-quit at any moment costs nothing but
the photo that was in the air.

Vocabulary, unchanged: a scan is made of **pages**, a page starts as a **photo**, the
finished scan is **the PDF**. The word "document" appears in one place only, the camera
permission text.

---

## 0. The shape of it

```
ScanList ──"New scan"──▶ ScanFlow
   │  tap a scan ───────▶ ScanFlow
   ▼
ScanFlow — one screen, switching on what the files say
   ├─ shooting  camera            "Scan 7 pages" ─┐
   ├─ scanning  the drain  ◀──────────────────────┘
   ├─ ready     the pages, one per swipe   "Make PDF" ─▶ scan.pdf
   └─ done      Open PDF │ Share PDF │ Change pages
```

New in this redesign: an **Adjust** step hanging off the pages, per page and for all
pages. It sits **after** the automatic run, on a page you can already see. Nothing else
moves.

---

## 1. First launch, empty state

1. The app opens on **Scans**. The sweep has already run in `FreePDFApp.init`.
2. There are no scan folders, so the empty text is shown.
3. Tap **New scan** → a folder is created → the camera opens on Page 1.

```
┌──────────────────────────────┐
│ Scans              New scan  │
├──────────────────────────────┤
│                              │
│         [doc icon]           │
│        No scans yet          │
│  Tap New scan and photograph │
│  the pages, one after        │
│  another. You can stop       │
│  whenever you like.          │
└──────────────────────────────┘
```

```
| Where | English | German |
| --- | --- | --- |
| Title | Scans | Scans |
| Button | New scan | Neuer Scan |
| Empty title | No scans yet | Noch keine Scans |
| Empty body | Tap New scan and photograph the pages, one after another. You can stop whenever you like. | Tippe auf Neuer Scan und fotografiere die Seiten, eine nach der anderen. Du kannst jederzeit aufhören. |
```

Error, only one on this screen: `New scan` could not create the folder (out of storage).
A red line at the top of the list, the system's own sentence, cleared on the next reload.

---

## 2. The list of scans

1. The list is the landing screen. Rows sorted newest first by folder name, no attribute
   reads.
2. The title is the folder date, e.g. `11 Aug 2026, 20:14`. There is no rename, by design:
   the date **is** the title.
3. The subtitle is derived from the files each draw.
4. Tap a row → ScanFlow, which lands on whatever step the files say.
5. Swipe a row → **Delete** → confirm → the whole folder goes.

```
┌──────────────────────────────┐
│ Scans              New scan  │
├──────────────────────────────┤
│ 11 Aug 2026, 20:14        ›  │
│ 40 pages — PDF ready         │
├──────────────────────────────┤
│ 11 Aug 2026, 09:32        ›  │
│ 12 of 40 pages scanned       │
├──────────────────────────────┤
│ 09 Aug 2026, 18:02        ›  │
│ No pages yet                 │
└──────────────────────────────┘
```

```
| State | English | German |
| --- | --- | --- |
| empty | No pages yet | Noch keine Seiten |
| shooting | 8 pages — keep shooting | 8 Seiten — weiter fotografieren |
| shooting, one | 1 page — keep shooting | 1 Seite — weiter fotografieren |
| scanning | 12 of 40 pages scanned | 12 von 40 Seiten gescannt |
| ready | 40 pages — ready to check | 40 Seiten — bereit zum Prüfen |
| done | 40 pages — PDF ready | 40 Seiten — PDF fertig |
| done, photos gone | 40 pages — PDF ready, photos deleted | 40 Seiten — PDF fertig, Fotos gelöscht |
```

---

## 3. Deleting a scan

Today the swipe deletes at once. The docs say the screen asks first, and it does not.
The redesign makes the docs true.

1. Swipe the row left.
2. Tap **Delete**.
3. A confirmation dialog names what goes.
4. Confirm → folder removed → list reloads. Cancel → nothing happens.

```
┌──────────────────────────────┐
│  Delete this scan?           │
│  40 pages, the PDF and 40    │
│  photos go. This cannot be   │
│  undone.                     │
│  [ Delete scan ]  [ Cancel ] │
└──────────────────────────────┘
```

```
| Where | English | German |
| --- | --- | --- |
| Swipe action | Delete | Löschen |
| Title | Delete this scan? | Diesen Scan löschen? |
| Body | 40 pages, the PDF and 40 photos go. This cannot be undone. | 40 Seiten, das PDF und 40 Fotos werden gelöscht. Das lässt sich nicht rückgängig machen. |
| Body, one | 1 page, the PDF and 1 photo go. This cannot be undone. | 1 Seite, das PDF und 1 Foto werden gelöscht. Das lässt sich nicht rückgängig machen. |
| Confirm | Delete scan | Scan löschen |
| Cancel | Cancel | Abbrechen |
```

---

## 4. Shooting pages

1. The scan opens on the viewfinder. The title is the number the next shot lands on.
2. Tap the shutter. The shutter is dead until the photo is on disk, so one press is one
   page and two fast presses cannot collide.
3. The counter goes up. Keep going.
4. Tap **Scan 8 pages** when done → the drain starts.
5. Leave any time. Coming back lands on the viewfinder again, at the next free number.

```
┌──────────────────────────────┐
│ ‹ Scans        Page 7        │
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │                          │ │
│ │      live preview        │ │
│ │        3 : 4             │ │
│ │                          │ │
│ └──────────────────────────┘ │
│           ( ⃝ )               │
│  ┌────────────────────────┐  │
│  │     Scan 8 pages       │  │
│  └────────────────────────┘  │
└──────────────────────────────┘
```

Rotation is fixed at portrait, set on both the preview and the photo output, so the
preview never lies about what is written. Flash off. Landscape is not built.

Copy is exactly the existing table (ios/AGENTS.md): `Page 7` / `Seite 7`, VoiceOver
`Photograph page 7` / `Seite 7 fotografieren` - and while the photo is being written, when
the shutter is dead, `Photographing page 7, wait` / `Seite 7 wird fotografiert, warten` -
`Scan 8 pages` / `8 Seiten scannen`,
with the singular `Scan 1 page` / `1 Seite scannen`,
disabled `Photograph at least one page` / `Mindestens eine Seite fotografieren`.

### 4a. Errors on the camera

One shape for a photo that missed the disk:
`Page 7 was not saved: <why> Nothing already photographed is lost.` /
`Seite 7 wurde nicht gespeichert: <warum> Nichts bereits Fotografiertes geht verloren.`

```
| Why | English | German |
| --- | --- | --- |
| write failed | the iPhone is out of storage. | Auf dem iPhone ist kein Speicherplatz mehr frei. |
| session not running | the camera is not ready. | Die Kamera ist nicht bereit. |
| empty capture | the camera handed over no photo. | Die Kamera hat kein Foto geliefert. |
| capture ended early | the camera stopped before the photo arrived. | Die Kamera hat gestoppt, bevor das Foto kam. |
```

Screen-level, not a page:

```
| Case | English | German |
| --- | --- | --- |
| no camera hardware | This iPhone has no camera to photograph with. | Dieses iPhone hat keine Kamera, um zu fotografieren. |
| session failed to start | The camera could not be started. | Die Kamera konnte nicht gestartet werden. |
| stand-in failed | Page 7 could not be drawn. | Seite 7 konnte nicht gezeichnet werden. |
| simulator note | No camera on this iPhone. The shutter draws a page instead. | Keine Kamera auf diesem iPhone. Der Auslöser zeichnet stattdessen eine Seite. |
| permission denied | FreePDF needs the camera to photograph the pages. | FreePDF braucht die Kamera, um die Seiten zu fotografieren. |
| permission button | Open Settings | Einstellungen öffnen |
```

### 4b. Permission

1. First shot on a phone with a camera → the system asks.
2. Allowed → viewfinder.
3. Denied → the whole screen becomes the sentence above plus **Open Settings**.
4. On a simulator nothing is asked at all, and the shutter draws a page.

---

## 5. The drain (scanning)

1. **Scan 8 pages** starts one page at a time, from the first photo without a page file.
2. The line counts how many photos are done, not page numbers: page numbers have gaps
   after a delete and are never renumbered.
3. Leaving the screen cancels the loop; the page in flight finishes and lands whole.
4. Coming back after a kill resumes at the same number, because the number is the files.
5. When there is nothing left it can do — finished or refused — the view moves to the
   pages.

```
┌──────────────────────────────┐
│ ‹ Scans                      │
├──────────────────────────────┤
│  Scanning page 4 of 12       │  ← 4th of 12 photos
│  ███████░░░░░░░░░░░░         │
│  You can close the app.      │
│  It carries on from here.    │
└──────────────────────────────┘
```

```
| Where | English | German |
| --- | --- | --- |
| Line | Scanning page 4 of 12 | Seite 4 von 12 wird gescannt |
| Note | You can close the app. It carries on from here. | Du kannst die App schließen. Sie macht hier weiter. |
```

A refused page shows the engine's own sentence in red and the drain moves on. It lands on
the pages, not on a stuck bar — that is where the user can retake or delete it.

New: **Retry** next to a refused page on the pages screen (see 6), because the refused set
only lives in memory today and a relaunch is the only retry there is.

---

## 6. Checking and retaking a page

1. The pages are a carousel, one per swipe. Title `Page 3 of 12`.
2. Swipe to look. A page the engine refused shows the failure card instead of an image.
3. **Page** menu → **Retake this page** → the camera opens on that slot, one shot, back to
   the pages.
4. **Page** menu → **Delete page** → confirm → page file first, photo second.
5. **Adjust page** → section 7.
6. **Make PDF** appears only when every photo has a page.

```
┌──────────────────────────────┐
│ ‹ Scans   Page 3 of 12   ⋯   │
├──────────────────────────────┤
│  ┌────────────────────────┐  │
│  │                        │  │
│  │      page image        │  │
│  │   pinch to zoom        │  │
│  │                        │  │
│  └────────────────────────┘  │
│      ‹  ● ● ○ ○ ○ ○  ›       │
│  ┌────────────────────────┐  │
│  │       Make PDF         │  │
│  └────────────────────────┘  │
└──────────────────────────────┘
```

```
| Where | English | German |
| --- | --- | --- |
| Title | Page 3 of 12 | Seite 3 von 12 |
| Menu | Page | Seite |
| Menu, spoken | Page menu | Seitenmenü |
| Menu item | Retake this page | Diese Seite neu fotografieren |
| Menu item | Adjust page | Seite anpassen |
| Menu item | Delete page | Seite löschen |
| Refused page | This page could not be scanned. | Diese Seite konnte nicht gescannt werden. |
| Retry | Scan this page again | Diese Seite noch einmal scannen |
| Button | Make PDF | PDF erstellen |
| Button, running | Making the PDF… | PDF wird erstellt… |
| Delete confirm title | Delete this page? | Diese Seite löschen? |
| Delete confirm body | The photo goes too. This cannot be undone. | Das Foto wird ebenfalls gelöscht. Das lässt sich nicht rückgängig machen. |
| Skipped after apply-to-all | Pages 4, 9 and 18 were not changed, because their photos are missing. | Seite 4, 9 und 18 wurden nicht geändert, weil ihre Fotos fehlen. |
| Jump | Go to page | Seite wählen |
| Jump, confirm | Go | Los |
```

Changes to today: pinch-to-zoom on the page (this screen exists to check small print, and
1600 px flat is too little), a **Retry** on a refused page, a confirmation on delete, and
a page-jump so a 40-page scan is not 40 swipes, shown only from ten pages up.

Adding a page to a finished scan is built: **Shoot another page** in the Page menu. It
deletes `scan.pdf` first, exactly as **Change pages** does, then opens the camera at
`nextPage` — otherwise the scan keeps reading `.done` and the new photo is never scanned.
The new page is scanned like any other and the PDF is built again afterwards. It appears
only on a finished scan; while checking, the menu has the three items above.

Not built, on purpose: reorder, insert in the middle. The page number is the filename and
is never renumbered.

---

## 7. Adjusting a page — the big gap

Today the engine runs one fixed recipe and the user sees none of it: load, deskew,
straighten, levels, shrink, sharpen, save. The engine itself is single tools and the
client owns the order. This screen is where the tools become reachable.

Adjust always comes **after** the automatic run. You fix a page you can already see
instead of guessing settings for a page you have not seen.

The principle from the engine docs holds: **suggest, then apply**. The engine seeds a
page once, and after that the tools open on what was last applied. The user moves a
value or leaves it, and **Back to the suggestion** is the way back to the engine's own
answer. What the engine measures for itself is measured again rather than seeded once —
the straightening angle and the two tone points — because they only mean something
against one set of corners, so moving the sheet re-measures them and replaces what is on
screen, hand-set or not; from there the user is back to nudging. Crop, turn, grey and the
flat switch are his and are kept.

Every tool **shows what it would do**: a moment after a value moves, the picture becomes
a real engine run of the current values into a scratch file, so what is on screen is what
Apply would write. Only Apply writes the page. (Julian, 2026-08-16, reversing the earlier
"no live preview".)

1. From the pages: **Adjust page**.
2. The photo is re-read from `photo/NNNN.jpg`. Adjust needs the photo: a page whose photo
   has been deleted cannot be adjusted at all.
3. A control strip picks one tool at a time. The picture follows the values; nothing is
   written until Apply.
4. **Apply** re-runs the recipe with the chosen values and replaces the page file whole,
   by rename. The previous page bytes are gone; the photo is what an adjustment can be
   redone from. **Cancel** leaves the page as it was.
5. If the scan already has a PDF, applying deletes `scan.pdf`, exactly as **Change pages**
   does. The PDF is derived, so this is safe.

```
┌──────────────────────────────┐
│ Cancel   Page 3      Apply   │
├──────────────────────────────┤
│  ┌────────────────────────┐  │
│  │                        │  │
│  │   the page as it is    │  │
│  │   (drag handles when   │  │
│  │    Edges/Crop active)  │  │
│  └────────────────────────┘  │
├──────────────────────────────┤
│ Edges  Straighten  Bright…   │
│ Sharpen  Crop  Turn          │
├──────────────────────────────┤
│ Straighten          −1.4°    │
│ −10 ──────●──────────── +10  │
│              [ Reset ]       │
├──────────────────────────────┤
│ [ ] Apply to all pages       │
└──────────────────────────────┘
```

```
| Where | English | German |
| --- | --- | --- |
| Title | Adjust page 3 | Seite 3 anpassen |
| Apply | Apply | Übernehmen |
| Cancel | Cancel | Abbrechen |
| Reset | Back to the suggestion | Zurück zum Vorschlag |
| Tool | Edges | Ränder |
| Tool | Straighten | Geraderücken |
| Tool | Brightness | Helligkeit |
| Tool | Sharpen | Schärfen |
| Tool | Crop | Zuschneiden |
| Tool | Turn | Drehen |
| Pages screen switch | Grey | Graustufen |
| All-pages switch | Apply to all pages | Auf alle Seiten anwenden |
| Running, one page | Applying… | Wird angewendet… |
| Running, all pages | Applying to 40 pages… | Wird auf 40 Seiten angewendet… |
| Crop refused | The crop falls outside the page. Move a corner back in. | Der Ausschnitt liegt außerhalb der Seite. Zieh eine Ecke zurück ins Bild. |
| Edges switch | Pull the sheet flat | Blatt geradeziehen |
| Levels slider | Black point | Schwarzpunkt |
| Levels slider | White point | Weißpunkt |
| Levels switch | Adjust the tones | Tonwerte anpassen |
| Sharpen at zero | None | Keine |
| Turn, spoken | A quarter turn clockwise | Eine Vierteldrehung im Uhrzeigersinn |
| Edges warning | The page runs off the frame. Move back and photograph it again. | Die Seite ragt aus dem Bild. Geh weiter weg und fotografiere sie noch einmal. |
| Edges, nothing to cut | The sheet fills the whole photo, so there is nothing to cut away. | Das Blatt füllt das ganze Foto, es gibt nichts abzuschneiden. |
```

### 7a. Each tool, and how it is reached

```
| Tool | Where the user reaches it | Control |
| --- | --- | --- |
| load_image | nowhere, by design | none — every photo is read this way, rotation tag applied first |
| find_paper | Adjust → Edges | four drag handles, pre-set to the found corners |
| deskew | Adjust → Edges | the same four handles, plus an on/off switch "Pull the sheet flat" |
| suggest_straightening | Adjust → Straighten | none of its own — it sets where the slider starts, and the degrees are printed |
| straighten | Adjust → Straighten | slider −10…+10 degrees, one decimal |
| suggest_levels | Adjust → Brightness | none of its own — it sets where both sliders start |
| apply_levels | Adjust → Brightness | two sliders, black point and white point, plus an on/off |
| sharpen | Adjust → Sharpen | slider 0…20 radius, opening at the drain's 0.6. 0 means no sharpening: the client skips the call, because the engine refuses radius 0 |
| to_grayscale | the pages screen | one switch, Colour / Grey, for the whole scan. Flipping it rewrites every page |
| crop | Adjust → Crop | drag handles on the page. The box crosses as fractions 0…1 of the image the engine cuts, so a corner dragged out is read as the edge |
| rotate | Adjust → Turn | one button, a quarter turn clockwise each tap. The turn is kept in the page's state file, so the engine turns the page again at every Apply |
| Paper::is_the_whole_image | Adjust → Edges | none — it is the line under the Edges control |
| Paper::runs_off_the_picture | Adjust → Edges | none — it is the warning line under the Edges control |
| save_page | nowhere, by design | none. Quality 85 is fixed and stays fixed |
| pages_to_pdf | the pages screen | the Make PDF button, unchanged |
| images_to_pdf | never reachable | deliberately not on the phone: it would peak near 3.1 GB and iOS kills the app |
| A4 page size | never reachable | fixed at A4. Not built |
| LONGEST_EDGE 3000 px cap | never reachable | the cap stays. It is the memory guarantee. Not built |
| the fixed order of the recipe | never reachable | the order is fixed; only each step's values move |
```

The C boundary has to be widened before any of this is buildable: `crop` and `rotate` are
not imported by the FFI at all, and `Levels` never crosses it. Today Swift can only call
`scanPage` and `pagesToPDF`.

It is **one** new C function for the adjusted case: it takes the photo path, the page path
and a struct holding all the values, and replaces `scan_page` when the user has adjusted
something. One function, not seven.

### 7b. One page or all pages

1. Adjust one page. Set the values.
2. Leave **Apply to all pages** off → only this page is rewritten. One page, about a
   second.
3. Turn it on → Apply rewrites every page from its own photo, one at a time, while the
   screen is up: **Keep the app open**. A kill leaves a mix of adjusted and unadjusted
   pages with nothing on disk to tell them apart, so there is no resume.
4. A page whose photo has been deleted cannot be rewritten. Those pages are skipped and
   named afterwards.
5. Values are **not remembered** for the next scan. Nothing is stored but the files.

```
┌──────────────────────────────┐
│  Applying to 40 pages…       │
│  ███████░░░░░░░░░░░░         │
│  Page 12 of 40               │
│  Keep the app open.          │
└──────────────────────────────┘
```

---

## 8. Making the PDF

1. Every photo has a page → **Make PDF** appears.
2. Tap it. The pages are stitched without being decoded again, so forty pages fit in a
   phone.
3. The file arrives by rename, so `scan.pdf` existing means it is whole.
4. The screen becomes the done screen.
5. It fails → the engine's own sentence in red, the pages stay, tap again.

---

## 9. The done screen

```
┌──────────────────────────────┐
│ ‹ Scans        PDF ready     │
├──────────────────────────────┤
│        PDF ready             │
│  Name for the shared copy    │
│  ┌────────────────────────┐  │
│  │ scan                   │  │
│  └────────────────────────┘  │
│  ┌────────────────────────┐  │
│  │       Open PDF         │  │
│  └────────────────────────┘  │
│  ┌────────────────────────┐  │
│  │       Share PDF        │  │
│  └────────────────────────┘  │
│        Change pages          │
│                              │
│  Delete the 40 photos (78 MB)│
│  The PDF stays. Deleted      │
│  photos cannot be brought    │
│  back.                       │
└──────────────────────────────┘
```

```
| Where | English | German |
| --- | --- | --- |
| Title | PDF ready | PDF fertig |
| Button | Open PDF | PDF öffnen |
| Button | Share PDF | PDF teilen |
| Button | Change pages | Seiten ändern |
| Destructive | Delete the 40 photos (78 MB) | Die 40 Fotos löschen (78 MB) |
| Footnote | The PDF stays. Deleted photos cannot be brought back. | Das PDF bleibt. Gelöschte Fotos lassen sich nicht wiederherstellen. |
| Reader sheet title | PDF | PDF |
| Reader sheet close, spoken | Close the PDF | PDF schließen |
| Photos group | Photos | Fotos |
```

1. **Open PDF** → a reader sheet inside the app. Nothing copied, nothing leaves.
2. **Change pages** → deletes `scan.pdf` and drops back to the pages, so one bad page
   spotted late does not cost the scan.
3. Photos already deleted → the destructive button and its footnote are simply gone, and
   Change pages still works on the pages alone.

---

## 10. Sharing

1. **Share PDF** opens the system share sheet on `scan.pdf`.
2. Save to Files (and with it iCloud Drive in the folder he picks), AirDrop, Mail, Print —
   all of it the system's.
3. Nothing is uploaded unasked. Julian's call, 2026-08-12: this is a tool, not an opinion
   about where his PDFs live.
4. The copy leaves; the original stays in the app's own folder until the scan is deleted.

On disk the file is always `scan.pdf`. A name field on the done screen lets the user name
the copy that leaves: type a name, share, and the share sheet carries that name. Nothing
is stored — reopen the scan and the field is empty again.

```
| Where | English | German |
| --- | --- | --- |
| Field label | Name for the shared copy | Name für die geteilte Kopie |
| Placeholder | scan | scan |
```

---

## 11. Deleting the photos

1. On the done screen, the quiet destructive button names the count and the size.
2. Tap it → confirm → `photo/` is emptied but the directory stays, because every writer
   assumes it is there.
3. The scan stays `.done`. Doing nothing is the other half of the choice, so "keep the
   photos" needs no button.
4. It is asked every time and never remembered. There is no settings screen.
5. After this, **Adjust page** cannot work on those pages any more — the photo is the
   input. The confirmation must say so.

```
| Where | English | German |
| --- | --- | --- |
| Confirm title | Delete the 40 photos? | Die 40 Fotos löschen? |
| Confirm body | The PDF stays. Without the photos the pages can no longer be adjusted. | Das PDF bleibt. Ohne die Fotos lassen sich die Seiten nicht mehr anpassen. |
| Confirm | Delete photos | Fotos löschen |
| Cancel | Cancel | Abbrechen |
```

---

## 12. After a force-quit

Nothing is stored, so nothing is lost. Where reopening lands:

```
| Killed when | What he sees |
| --- | --- |
| before the first shot | a row "No pages yet", tap → viewfinder |
| mid-shooting | the camera, "Page 12" again |
| mid-scan | the progress line, carrying on at the first unscanned page |
| all pages scanned | the pages |
| after Make PDF | the done screen, share again |
| after deleting the photos | "photos deleted", the button is gone |
| mid apply-to-all | the pages, some adjusted and some not, with no way to tell which |
```

---

## DECISIONS

All settled, Julian, 2026-08-12. Each one is written into the section named beside it.

1. **Adjust comes after the automatic run**, on a page you can already see. Never before.
   (Sections 0 and 7.)

2. **Every tool shows what it would do.** A debounced engine run into a scratch file
   shows the page the current values would produce; only Apply writes it. (Julian,
   2026-08-16, reversing the 2026-08-12 decision. Section 7.)

3. **Apply-to-all is not promised across a kill.** "Keep the app open" for that one run,
   nothing new goes on disk. (Section 7b.)

4. **Grey is per scan**, one switch on the pages screen, not inside Adjust. (Section 7a.)

5. **All three deletions ask first**: scan, page, photos. (Sections 3, 6 and 11.)

6. **Paper size stays fixed at A4.** No picker. Not built. (Section 7a.)

7. **The 3000 px cap stays.** No quality picker. Not built — it is the memory guarantee.
   (Section 7a.)

8. **Renaming the PDF is built**: a text field on the done screen. The name is used only
   for the shared copy, nothing is stored. (Sections 9 and 10.)

9. **"Shoot another page" on a finished scan is built.** The PDF is built again
   afterwards. (Section 6.)

10. **No corner thumbnail on the camera.** Skipped — retaking from the pages already
    works, and the camera screen stays one shutter and one button. (Section 4.)

11. **No import from the photo library.** Skipped: iOS hands over HEIC and the engine
    cannot read it.

12. **One new C function for the adjusted case**, taking the photo path, the page path and
    a struct of all the values. Not seven functions. (Section 7a.)
