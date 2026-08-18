# Copy — every string, English and German

Verbatim from `client-guide-design-system/components.md`. A client shows these words; it does
not rewrite them, and it does not translate them again.

## Scans

| Where | English | German |
| --- | --- | --- |
| Title | Scans | Scans |
| Button | New scan | Neuer Scan |
| Empty title | No scans yet | Noch keine Scans |
| Empty body | Tap New scan and photograph the pages, one after another. You can stop whenever you like. | Tippe auf Neuer Scan und fotografiere die Seiten, eine nach der anderen. Du kannst jederzeit aufhören. |
| Swipe action | Delete | Löschen |

Row subtitles — seven, all of them required:

| State | English | German |
| --- | --- | --- |
| empty | No pages yet | Noch keine Seiten |
| shooting | 8 pages — keep shooting | 8 Seiten — weiter fotografieren |
| shooting, one | 1 page — keep shooting | 1 Seite — weiter fotografieren |
| scanning | 12 of 40 pages scanned | 12 von 40 Seiten gescannt |
| ready | 40 pages — ready to check | 40 Seiten — bereit zum Prüfen |
| done | 40 pages — PDF ready | 40 Seiten — PDF fertig |
| done, photos gone | 40 pages — PDF ready, photos deleted | 40 Seiten — PDF fertig, Fotos gelöscht |

The title is the name typed on the done screen, or the folder date, e.g. `11 Aug 2026, 20:14`,
when none was typed. The row itself is never editable.

## Camera

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

## Pages

| Where | English | German |
| --- | --- | --- |
| Title | Page 3 of 12 | Seite 3 von 12 |
| Menu | Page | Seite |
| Menu item | Retake this page | Diese Seite neu fotografieren |
| Button | Adjust page | Seite anpassen |
| Menu item | Delete page | Seite löschen |
| Button (finished scan) | Shoot another page | Weitere Seite fotografieren |
| Refused page | This page could not be scanned. | Diese Seite konnte nicht gescannt werden. |
| Retry | Scan this page again | Diese Seite noch einmal scannen |
| Button | Make PDF | PDF erstellen |
| Button, running | Making the PDF… | PDF wird erstellt… |
| Switch | Grey | Graustufen |

## Adjust

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
| Switch | Apply to all pages | Auf alle Seiten anwenden |
| Running, one page | Applying… | Wird angewendet… |
| Running, all pages | Applying to 40 pages… | Wird auf 40 Seiten angewendet… |
| Edges warning | The page runs off the frame. Move back and photograph it again. | Die Seite ragt aus dem Bild. Geh weiter weg und fotografiere sie noch einmal. |
| Edges, nothing to cut | The sheet fills the whole photo, so there is nothing to cut away. | Das Blatt füllt das ganze Foto, es gibt nichts abzuschneiden. |

## Done

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

## Deletions — all three ask, always

| Case | English | German |
| --- | --- | --- |
| Scan title | Delete this scan? | Diesen Scan löschen? |
| Scan body | 40 pages, the PDF and 40 photos go. This cannot be undone. | 40 Seiten, das PDF und 40 Fotos werden gelöscht. Das lässt sich nicht rückgängig machen. |
| Scan confirm | Delete scan | Scan löschen |
| Page title | Delete this page? | Diese Seite löschen? |
| Page body | The photo goes too. This cannot be undone. | Das Foto wird ebenfalls gelöscht. Das lässt sich nicht rückgängig machen. |
| Page confirm | Delete page | Seite löschen |
| Photos title | Delete the 40 photos? | Die 40 Fotos löschen? |
| Photos body | The PDF stays. Without the photos the pages can no longer be adjusted. | Das PDF bleibt. Ohne die Fotos lassen sich die Seiten nicht mehr anpassen. |
| Photos confirm | Delete photos | Fotos löschen |
| Cancel | Cancel | Abbrechen |

## Progress and errors

| Where | English | German |
| --- | --- | --- |
| Line | Scanning page 4 of 12 | Seite 4 von 12 wird gescannt |
| Note (the drain) | You can close the app. It carries on from here. | Du kannst die App schließen. Sie macht hier weiter. |
| Note (apply to all) | Keep the app open. | Lass die App offen. |

Error lines carry the engine's own finished sentence, unchanged. Per-page camera failures use
one shape: `Page 7 was not saved: <why> Nothing already photographed is lost.` /
`Seite 7 wurde nicht gespeichert: <warum> Nichts bereits Fotografiertes geht verloren.`
