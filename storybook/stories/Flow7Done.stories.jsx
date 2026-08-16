import React from "react";
import { AppBar, StatusLine } from "@ds/ui_kits/iphone/Chrome.jsx";
import { Button, ConfirmDialog, PageImage, SectionLabel, Sheet, TextField } from "../ds.js";

/* Flow 7, the done screen: S34 to S38 of "FreePDF Flow 7 Done.dc.html", corrected
   against what the app actually ships (ios/FreePDF/ScanFlow.swift, `done`, commit
   b8d9b03). Words come from user-flows.md §9, §10, §11. Same phone frame as Flow1Scans.

   Two things the delivered document draws are not here, because user-flows.md and the
   app both leave them out:
   - the PDF's first page at the top of the screen (TASKS.md open question 2 - nothing
     renders a PDF page back to an image), so the screen starts on the name field;
   - the line under Share PDF, which is the designer's placeholder and has no entry in
     any copy table. */
const Phone = ({ children }) => (
  <div
    style={{
      position: "relative",
      width: 390,
      height: 844,
      background: "var(--bg)",
      display: "grid",
      gridTemplateRows: "auto 1fr",
      overflow: "hidden",
    }}
  >
    <StatusLine />
    <div style={{ position: "relative", minHeight: 0, display: "grid", gridTemplateRows: "auto 1fr" }}>
      {children}
    </div>
  </div>
);

const bar = <AppBar title="PDF ready" back />;

/* The scroll area of the screen: screen padding, space-4 between the blocks. It scrolls
   rather than shrinks, which is what keeps everything reachable when the keyboard is up. */
const Body = ({ children, ...rest }) => (
  <div
    style={{ overflow: "auto", padding: "var(--screen-padding)", display: "grid", gap: "var(--space-4)", alignContent: "start" }}
    {...rest}
  >
    {children}
  </div>
);

/* The name field. Nothing is stored, so every story starts from its own value and the
   state dies with the story (user-flows §10). No ".pdf" suffix: §10 gives the label and
   the placeholder "scan" only.

   `autoFocus` is the whole of Julian's decision of 2026-08-16: "when we say Make PDF we
   can always assume someone wants to type a name, so when the page is open, focus the
   name field automatically so you can start typing right away." It is a mount-time
   focus and nothing else - React applies `autoFocus` when the input is created and never
   again, so a redraw does not re-focus, and coming back from the share sheet, the reader
   sheet or Change pages leaves the keyboard where the user left it. */
const NameField = ({ value: initial = "", autoFocus }) => {
  const [value, setValue] = React.useState(initial);
  return (
    <TextField label="Name for the shared copy" value={value} placeholder="scan" onChange={setValue} autoFocus={autoFocus} />
  );
};

/* All three actions are always on the screen; only the photos block ever goes away. */
const Actions = () => (
  <div style={{ display: "grid", gap: "var(--space-2)" }}>
    <Button variant="primary" fullWidth>Open PDF</Button>
    <Button variant="primary" fullWidth>Share PDF</Button>
    <Button variant="ghost" fullWidth>Change pages</Button>
  </div>
);

/* The photos block: hairline, the group label, the destructive button, the footnote.
   It is removed whole when the photos are gone (§9.3), never greyed. */
const PhotosBlock = ({ onDelete }) => (
  <div style={{ display: "grid", gap: "var(--space-2)", paddingTop: "var(--space-4)", borderTop: "1px solid var(--divider)" }}>
    <SectionLabel>Photos</SectionLabel>
    <Button variant="destructive" fullWidth onClick={onDelete}>Delete the 40 photos (78 MB)</Button>
    <p style={{ margin: 0, font: "var(--weight-body) var(--text-meta)/1.45 var(--font-body)", color: "var(--text-muted)", textWrap: "pretty" }}>
      The PDF stays. Deleted photos cannot be brought back.
    </p>
  </div>
);

/* The iPhone keyboard, drawn as a block. It takes the lower part of the screen; the
   scroll area keeps the rest, so nothing on the screen is resized or dropped.

   336 is the system keyboard's own height in portrait with its suggestion bar - a fact
   about iOS, measured, not a design value, which is why it is a number here and not a
   token. It has to be the real one: draw it shorter and the screen appears to fit when
   on a phone it does not. */
const Keyboard = () => (
  <div
    style={{
      height: 336,
      borderTop: "1px solid var(--divider)",
      background: "var(--surface)",
      display: "grid",
      placeItems: "center",
      color: "var(--text-muted)",
      font: "var(--weight-body) var(--text-meta)/1.4 var(--font-body)",
    }}
  >
    The iPhone keyboard, drawn as a block
  </div>
);

export default { title: "Flows/7 Done" };

export const S34AtOpen = {
  name: "S34 — the screen as it opens, the name field focused",
  /* What the user sees the moment the PDF is ready: the field already has the caret and
     the keyboard is already up, so a name can be typed without tapping anything. The
     field is empty, showing the placeholder, because nothing is stored. Both primaries
     stay above the keyboard - the field is only useful because of the button under it. */
  render: () => (
    <Phone>
      {bar}
      <div style={{ display: "grid", gridTemplateRows: "1fr auto", minHeight: 0 }}>
        <Body>
          <NameField autoFocus />
          <Actions />
          <PhotosBlock />
        </Body>
        <Keyboard />
      </div>
    </Phone>
  ),
};

export const S34PhotosWithKeyboardUp = {
  name: "S34 — keyboard up, the photos block still reachable",
  /* The same screen with a name typed and the keyboard still up. This is the state the
     new focus rule has to survive: nothing above the keyboard is dropped, greyed or
     shrunk to make room, so the photos block and its footnote are still there to be
     pressed. On a 390 x 844 phone the screen fits under a full-height keyboard without
     even scrolling; where it does not - a smaller phone, a bigger type size - the body
     scrolls and the block is one drag away. The delivered document says the destructive
     block only exists "when the keyboard is down"; that is not how it is built. */
  render: () => (
    <Phone>
      {bar}
      <div style={{ display: "grid", gridTemplateRows: "1fr auto", minHeight: 0 }}>
        <Body>
          <NameField value="Rental contract" autoFocus />
          <Actions />
          <PhotosBlock />
        </Body>
        <Keyboard />
      </div>
    </Phone>
  ),
};

export const S35PhotosDeleted = {
  name: "S35 — photos already deleted",
  /* The block is removed, not disabled, and nothing announces the absence (§9.3). The
     screen ends on Change pages, which still works. No keyboard: this is the screen come
     back to after Change pages, and coming back never raises it again. */
  render: () => (
    <Phone>
      {bar}
      <Body>
        <NameField />
        <Actions />
      </Body>
    </Phone>
  ),
};

export const S36Reader = {
  name: "S36 — Open PDF, the reader sheet",
  /* Title "PDF" and the spoken close label from the §9 table. Nothing else on the sheet:
     no share, no print, no page count. The keyboard is down while the sheet is up, and
     closing the sheet leaves it down - the focus happened once, when the screen opened. */
  render: () => (
    <Phone>
      {bar}
      <div style={{ position: "relative", minHeight: 0 }}>
        <Body>
          <NameField value="Rental contract" />
          <Actions />
        </Body>
        <Sheet title="PDF" closeLabel="Close the PDF">
          <div style={{ display: "grid", gap: "var(--space-4)", justifyItems: "center" }}>
            <PageImage label="1" alt="Page 1 of the PDF" style={{ width: 220 }} />
            <PageImage label="2" alt="Page 2 of the PDF" style={{ width: 220 }} />
          </div>
        </Sheet>
      </div>
    </Phone>
  ),
};

export const S38DeletePhotos = {
  name: "S38 — the photos block and its confirmation",
  /* Asked every time, never remembered (§11.4). Cancel keeps the photos; there is no
     "keep the photos" button. */
  render: () => {
    const [confirm, setConfirm] = React.useState(true);
    return (
      <Phone>
        {bar}
        <div style={{ position: "relative", minHeight: 0 }}>
          <Body>
            <NameField />
            <Actions />
            <PhotosBlock onDelete={() => setConfirm(true)} />
          </Body>
          {confirm ? (
            <ConfirmDialog
              title="Delete the 40 photos?"
              body="The PDF stays. Without the photos the pages can no longer be adjusted."
              confirmLabel="Delete photos"
              cancelLabel="Cancel"
              onConfirm={() => setConfirm(false)}
              onCancel={() => setConfirm(false)}
            />
          ) : null}
        </div>
      </Phone>
    );
  },
};
