import React from "react";
import { AppBar } from "@ds/ui_kits/iphone/Chrome.jsx";
import { ErrorLine, ProgressLine } from "../ds.js";
import { Phone } from "./Phone.jsx";

/* Flow 4, the scan runs: S13 and S14 of "FreePDF Flow 4 Scanning.dc.html".
   Behaviour: user-flows.md §5. */

/* The bar carries the scan's date and a back arrow — leaving is safe, the page in
   flight finishes (§5.3). Nothing else: no cancel, no thumbnails, no preview. */
const bar = <AppBar title="11 Aug 2026, 20:14" back />;

/* The block sits centred in the scroll area, so it does not move as the sentence
   grows from "1 of 12" to "11 of 12". An error line, when there is one, sits at the
   top of that area and the block is centred in what is left. */
const Body = ({ error, value }) => (
  <div
    style={{
      overflow: "auto",
      padding: "var(--screen-padding)",
      display: "grid",
      gridTemplateRows: error ? "auto 1fr" : "1fr",
      gap: "var(--space-4)",
    }}
  >
    {error ? <ErrorLine>{error}</ErrorLine> : null}
    <div style={{ display: "grid", alignContent: "center" }}>
      <ProgressLine
        line={`Scanning page ${value} of 12`}
        note="You can close the app. It carries on from here."
        value={value}
        max={12}
      />
    </div>
  </div>
);

export default { title: "Flows/4 Scanning" };

export const S13Early = {
  name: "S13 — early, 1 of 12",
  render: () => (
    <Phone grid>
      {bar}
      <Body value={1} />
    </Phone>
  ),
};

export const S13Late = {
  name: "S13 — late, 11 of 12",
  render: () => (
    <Phone grid>
      {bar}
      <Body value={11} />
    </Phone>
  ),
};

export const S14Refused = {
  name: "S14 — a page was refused",
  /* The refusal is the engine's own finished sentence, printed unchanged; no copy
     table holds it, so this is the stand-in the delivered document draws. The count
     stays on the page being worked on now — the bar never gets stuck (§5). */
  render: () => (
    <Phone grid>
      {bar}
      <Body
        value={6}
        error="Page 5 could not be scanned: the sheet could not be found in the photo."
      />
    </Phone>
  ),
};
