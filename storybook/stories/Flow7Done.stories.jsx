import React from "react";
import { AppBar, StatusLine } from "@ds/ui_kits/iphone/Chrome.jsx";
import { Button, ConfirmDialog, PageImage, SectionLabel, Sheet, TextField } from "../ds.js";

/* Flow 7, the done screen: S34 to S38 of "FreePDF Flow 7 Done.dc.html".
   Words come from user-flows.md §9, §10, §11. Same phone frame as Flow1Scans. */
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

/* The scroll area of the screen: screen padding, space-4 between the blocks. */
const Body = ({ children, ...rest }) => (
  <div
    style={{ overflow: "auto", padding: "var(--screen-padding)", display: "grid", gap: "var(--space-4)", alignContent: "start" }}
    {...rest}
  >
    {children}
  </div>
);

/* The name field. Nothing is stored, so every story starts from its own value
   and the state dies with the story (user-flows §10). No ".pdf" suffix: §10
   gives the label and the placeholder "scan" only. */
const NameField = ({ value: initial = "", autoFocus }) => {
  const [value, setValue] = React.useState(initial);
  return (
    <TextField label="Name for the shared copy" value={value} placeholder="scan" onChange={setValue} autoFocus={autoFocus} />
  );
};

const Actions = ({ changePages = true, note }) => (
  <div style={{ display: "grid", gap: "var(--space-2)" }}>
    <Button variant="primary" fullWidth>Open PDF</Button>
    <Button variant="primary" fullWidth>Share PDF</Button>
    {note}
    {changePages ? <Button variant="ghost" fullWidth>Change pages</Button> : null}
  </div>
);

/* The photos block: hairline, the group label, the destructive button, the
   footnote. It is removed whole when the photos are gone (§9.3), never greyed. */
const PhotosBlock = ({ onDelete }) => (
  <div style={{ display: "grid", gap: "var(--space-2)", paddingTop: "var(--space-4)", borderTop: "1px solid var(--divider)" }}>
    <SectionLabel>Photos</SectionLabel>
    <Button variant="destructive" fullWidth onClick={onDelete}>Delete the 40 photos (78 MB)</Button>
    <p style={{ margin: 0, font: "var(--weight-body) var(--text-meta)/1.45 var(--font-body)", color: "var(--text-muted)", textWrap: "pretty" }}>
      The PDF stays. Deleted photos cannot be brought back.
    </p>
  </div>
);

export default { title: "Flows/7 Done" };

export const S34NameField = {
  name: "S34 — the name field in use, keyboard up",
  /* The field is focused and typed in, the keyboard block takes the lower part of
     the screen, and both buttons stay above it — the field is only useful because
     of the button under it. The photos block is scrolled out, not resized. */
  render: () => (
    <Phone>
      {bar}
      <div style={{ display: "grid", gridTemplateRows: "1fr auto", minHeight: 0 }}>
        <Body>
          <PageImage label="1" alt="First page of the PDF" style={{ width: 150, justifySelf: "center" }} />
          <NameField value="Rental contract" autoFocus />
          <Actions changePages={false} />
          <PhotosBlock />
        </Body>
        <div
          style={{
            height: 210,
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
      </div>
    </Phone>
  ),
};

export const S35PhotosDeleted = {
  name: "S35 — photos already deleted",
  /* Block removed, and the room it leaves goes to the picture: 230 px instead of
     150. Nothing announces the absence (§9.3). */
  render: () => (
    <Phone>
      {bar}
      <Body>
        <PageImage label="1" alt="First page of the PDF" style={{ width: 230, justifySelf: "center" }} />
        <NameField />
        <Actions />
      </Body>
    </Phone>
  ),
};

export const S36Reader = {
  name: "S36 — Open PDF, the reader sheet",
  /* Title and close wording from the §9 table. Nothing else on the sheet: no
     share, no print, no page count. */
  render: () => (
    <Phone>
      {bar}
      <div style={{ position: "relative", minHeight: 0 }}>
        <Body>
          <PageImage label="1" alt="First page of the PDF" style={{ width: 230, justifySelf: "center" }} />
          <NameField />
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

export const S37ShareLine = {
  name: "S37 — the line under Share",
  /* The sentence is the delivered document's own placeholder: task 4 left it
     without a copy table entry, so it is repeated here, not invented. */
  render: () => (
    <Phone>
      {bar}
      <Body>
        <PageImage label="1" alt="First page of the PDF" style={{ width: 200, justifySelf: "center" }} />
        <NameField value="Rental contract" />
        <Actions
          note={
            <p style={{ margin: 0, font: "var(--weight-body) var(--text-meta)/1.45 var(--font-body)", color: "var(--text-muted)", textWrap: "pretty" }}>
              Nothing leaves the phone until you choose where the copy goes.
            </p>
          }
        />
      </Body>
    </Phone>
  ),
};

export const S38DeletePhotos = {
  name: "S38 — the photos block and its confirmation",
  /* Asked every time, never remembered (§11.4). Cancel keeps the photos; there is
     no "keep the photos" button. */
  render: () => {
    const [confirm, setConfirm] = React.useState(true);
    return (
      <Phone>
        {bar}
        <div style={{ position: "relative", minHeight: 0 }}>
          <Body>
            <PageImage label="1" alt="First page of the PDF" style={{ width: 200, justifySelf: "center" }} />
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
