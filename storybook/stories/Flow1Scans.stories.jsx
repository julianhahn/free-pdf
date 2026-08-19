import React from "react";
import { AppBar } from "@ds/ui_kits/iphone/Chrome.jsx";
import { Button, ConfirmDialog, EmptyState, ErrorLine, ScanRow } from "../ds.js";
import { Phone } from "./Phone.jsx";

/* Flows 1 and 2, the scans list: S1, S2, S4, S5 of
   "FreePDF Flows 1-2 Scans.dc.html". */

/* The bar action is in the same place across the app; the empty state repeats the
   words the sentence just gave. Both go to the camera (S1 spec). */
const bar = <AppBar title="Scans" trailing={<Button variant="ghost">New scan</Button>} />;

/* Empty: the block is centred in the scroll area, screen padding around it. */
const EmptyBody = ({ error }) => (
  <div style={{ overflow: "auto", padding: "var(--screen-padding)", display: "grid", gap: "var(--space-4)", alignContent: error ? "start" : "center" }}>
    {error ? <ErrorLine>{error}</ErrorLine> : null}
    <EmptyState
      title="No scans yet"
      body="Tap New scan and photograph the pages, one after another. You can stop whenever you like."
      action={<Button variant="primary">New scan</Button>}
    />
  </div>
);

/* Rows are full bleed — no screen padding — so hairline and swipe action reach
   both edges (S4 spec). Copy: the subtitle table of user-flows §2. */
const SCANS = [
  { id: "a", title: "11 Aug 2026, 20:14", subtitle: "40 pages — PDF ready" },
  { id: "b", title: "11 Aug 2026, 09:02", subtitle: "12 of 40 pages scanned" },
  { id: "c", title: "10 Aug 2026, 18:47", subtitle: "8 pages — keep shooting" },
  { id: "e", title: "08 Aug 2026, 11:20", subtitle: "No pages yet" },
];

const ListBody = ({ swipedId }) => (
  <div style={{ overflow: "auto" }}>
    {SCANS.map((s) => (
      <ScanRow key={s.id} title={s.title} subtitle={s.subtitle} swiped={swipedId === s.id} />
    ))}
  </div>
);

export default { title: "Flows/1-2 Scans" };

export const S1Empty = {
  name: "S1 — empty list",
  render: () => (
    <Phone grid>
      {bar}
      <EmptyBody />
    </Phone>
  ),
};

export const S2EmptyWithError = {
  name: "S2 — empty list, error line",
  /* The storage failure is the system's own sentence, printed unchanged, and no
     copy table holds it (user-flows §1). The sentence shown is the one the
     delivered document draws in S2 — a stand-in for the OS text, not app copy. */
  render: () => (
    <Phone grid>
      {bar}
      <EmptyBody error="The scan could not be created: the iPhone is out of storage." />
    </Phone>
  ),
};

export const S4RowSwiped = {
  name: "S4 — a row swiped left",
  render: () => (
    <Phone grid>
      {bar}
      <ListBody swipedId="a" />
    </Phone>
  ),
};

export const S5DeleteConfirm = {
  name: "S5 — delete confirmation",
  /* Counts come from the swiped row: 40 pages, so the plural body of §3. */
  render: () => (
    <Phone grid>
      {bar}
      <div style={{ position: "relative", minHeight: 0 }}>
        <ListBody swipedId="a" />
        <ConfirmDialog
          title="Delete this scan?"
          body="40 pages, the PDF and 40 photos go. This cannot be undone."
          confirmLabel="Delete scan"
          cancelLabel="Cancel"
        />
      </div>
    </Phone>
  ),
};
