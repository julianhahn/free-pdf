# Components

One entry per thing a client has to build. States come from
[`../user-flows.md`](../user-flows.md), which stays the owner of behaviour; copy is that
document's table, repeated here so a client agent reads one file.

**In Storybook** means Julian has looked at it in `../storybook/` and it is approved to build.
**Described only** means it is written down but nobody has seen it yet - build it after it has
been through Storybook, not before.

```
| Component | Status |
| --- | --- |
| Scan row | in Storybook |
| Buttons (primary, secondary, destructive, disabled, shutter) | in Storybook |
| Adjust controls (switch, slider, apply button) | in Storybook |
| everything below | described only |
```

---

## Scan row - in Storybook

One scan in the list. A whole-row button: date title, derived subtitle, accent chevron,
hairline underneath. No fill, no card.

States: the seven subtitles below, plus pressed (accent at 14%) and swiped-left, which reveals
a 96 px **Delete** action in destructive colour.

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
| Swipe action | Delete | Löschen |
```

The title is the folder date, e.g. `11 Aug 2026, 20:14`. There is no rename: the date is the
title.

## Buttons - in Storybook

Outlined, never filled. Full width when they are the screen's action.

```
| Variant | Look | Used for |
| --- | --- | --- |
| primary | accent text, accent border | Make PDF, Open PDF, Scan 8 pages |
| secondary | text colour, divider border | Change pages, Cancel |
| destructive | accent-700 (light) / accent-300 (dark) text and border | Delete scan, Delete page, Delete photos |
| ghost | accent text, no border | Change pages on the done screen, Reset |
| disabled | any variant at 45% opacity | shutter and Scan button before the first page |
```

States for all: rest, hover, pressed, disabled, focused.

## Shutter - in Storybook

72 px circle, stroke only: a divider ring, then a gap in the background colour, then a 1 px
accent ring. States: rest, pressed, **disabled while the photo is being written** - that
disabled state is the rule that makes one press one page.

This is the control the theme is hardest on. On a dark viewfinder a hairline gold circle is
thin under a thumb. Flagged, not solved.

## Adjust controls - in Storybook

**Switch** - 42 x 24 outlined track, round knob. Off: knob at text 45%. On: accent border,
accent knob. Two switches exist: `Grey` on the pages screen, `Apply to all pages` in Adjust.

**Slider** - 1 px track, round thumb with an accent border. It opens on the value the engine
suggested; the value is printed beside the label in accent-700 / accent-300, tabular figures,
and the two ends are labelled in meta size.

**Apply button** - primary, with a running label.

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
| Switch | Grey | Graustufen |
| Switch | Apply to all pages | Auf alle Seiten anwenden |
| Running, one page | Applying… | Wird angewendet… |
| Running, all pages | Applying to 40 pages… | Wird auf 40 Seiten angewendet… |
| Edges warning | The page runs off the frame. Move back and photograph it again. | Die Seite ragt aus dem Bild. Geh weiter weg und fotografiere sie noch einmal. |
| Edges, nothing to cut | The sheet fills the whole photo, so there is nothing to cut away. | Das Blatt füllt das ganze Foto, es gibt nichts abzuschneiden. |
```

---

## Described only

### Empty state

Icon, title, body. Shown when there are no scan folders.

```
| Where | English | German |
| --- | --- | --- |
| Empty title | No scans yet | Noch keine Scans |
| Empty body | Tap New scan and photograph the pages, one after another. You can stop whenever you like. | Tippe auf Neuer Scan und fotografiere die Seiten, eine nach der anderen. Du kannst jederzeit aufhören. |
| Title | Scans | Scans |
| Button | New scan | Neuer Scan |
```

### Confirmation dialog

Surface background, radius-lg, shadow-lg. Title (h4), body, then the actions right-aligned:
destructive first, secondary Cancel. Three of them exist - scan, page, photos - and all three
ask, always.

```
| Case | English | German |
| --- | --- | --- |
| Scan title | Delete this scan? | Diesen Scan löschen? |
| Scan body | 40 pages, the PDF and 40 photos go. This cannot be undone. | 40 Seiten, das PDF und 40 Fotos werden gelöscht. Das lässt sich nicht rückgängig machen. |
| Scan confirm | Delete scan | Scan löschen |
| Page title | Delete this page? | Diese Seite löschen? |
| Page body | The photo goes too. This cannot be undone. | Das Foto wird ebenfalls gelöscht. Das lässt sich nicht rückgängig machen. |
| Photos title | Delete the 40 photos? | Die 40 Fotos löschen? |
| Photos body | The PDF stays. Without the photos the pages can no longer be adjusted. | Das PDF bleibt. Ohne die Fotos lassen sich die Seiten nicht mehr anpassen. |
| Photos confirm | Delete photos | Fotos löschen |
| Cancel | Cancel | Abbrechen |
```

### Camera screen

Live preview at 3:4, portrait fixed, flash off, the shutter under it, the Scan button under
that. States: ready, shutter disabled while writing, no camera hardware, permission denied,
simulator stand-in.

```
| Where | English | German |
| --- | --- | --- |
| Title | Page 7 | Seite 7 |
| Shutter label (VoiceOver) | Photograph page 7 | Seite 7 fotografieren |
| Button | Scan 8 pages | 8 Seiten scannen |
| Button, disabled | Photograph at least one page | Mindestens eine Seite fotografieren |
| permission denied | FreePDF needs the camera to photograph the pages. | FreePDF braucht die Kamera, um die Seiten zu fotografieren. |
| permission button | Open Settings | Einstellungen öffnen |
| no camera hardware | This iPhone has no camera to photograph with. | Dieses iPhone hat keine Kamera, um zu fotografieren. |
| session failed | The camera could not be started. | Die Kamera konnte nicht gestartet werden. |
| simulator note | No camera on this iPhone. The shutter draws a page instead. | Keine Kamera auf diesem iPhone. Der Auslöser zeichnet stattdessen eine Seite. |
```

### Error line

One line, destructive colour, above the content, cleared on the next reload. The text is the
engine's own finished sentence - the client never rewrites it. Per-page camera failures use one
shape: `Page 7 was not saved: <why> Nothing already photographed is lost.` /
`Seite 7 wurde nicht gespeichert: <warum> Nichts bereits Fotografiertes geht verloren.`

### Progress

A line, a bar, a note. Two of them: the drain, and apply-to-all.

```
| Where | English | German |
| --- | --- | --- |
| Line | Scanning page 4 of 12 | Seite 4 von 12 wird gescannt |
| Note | You can close the app. It carries on from here. | Du kannst die App schließen. Sie macht hier weiter. |
| All-pages note | Keep the app open. | Lass die App offen. |
```

The drain's note and the apply-to-all note say opposite things on purpose: the drain resumes
after a kill, apply-to-all does not.

### Page carousel

One page per swipe, pinch to zoom, a page indicator, a page-jump, and the Page menu. States:
page shown, refused page (failure card instead of an image), Make PDF hidden until every photo
has a page, Make PDF running.

```
| Where | English | German |
| --- | --- | --- |
| Title | Page 3 of 12 | Seite 3 von 12 |
| Menu | Page | Seite |
| Menu item | Retake this page | Diese Seite neu fotografieren |
| Menu item | Adjust page | Seite anpassen |
| Menu item | Delete page | Seite löschen |
| Refused page | This page could not be scanned. | Diese Seite konnte nicht gescannt werden. |
| Retry | Scan this page again | Diese Seite noch einmal scannen |
| Button | Make PDF | PDF erstellen |
| Button, running | Making the PDF… | PDF wird erstellt… |
```

On a finished scan the menu also carries **Shoot another page**.

### Done screen

Title, the name field, two primary buttons, a ghost button, then the destructive block. States:
photos present, photos already deleted (the destructive block and its footnote are simply gone).

```
| Where | English | German |
| --- | --- | --- |
| Title | PDF ready | PDF fertig |
| Field label | Name for the shared copy | Name für die geteilte Kopie |
| Placeholder | scan | scan |
| Button | Open PDF | PDF öffnen |
| Button | Share PDF | PDF teilen |
| Button | Change pages | Seiten ändern |
| Destructive | Delete the 40 photos (78 MB) | Die 40 Fotos löschen (78 MB) |
| Footnote | The PDF stays. Deleted photos cannot be brought back. | Das PDF bleibt. Gelöschte Fotos lassen sich nicht wiederherstellen. |
```
