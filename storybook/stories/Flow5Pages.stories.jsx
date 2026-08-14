import React from "react";
import { AppBar, Screen, StatusLine } from "@ds/ui_kits/iphone/Chrome.jsx";
import {
  Button,
  ConfirmDialog,
  ErrorLine,
  IconButton,
  MenuList,
  PageImage,
  PageStrip,
  Switch,
} from "../ds.js";

/* Flow 5, the pages: S16, S16b, S17 to S22 of "FreePDF Flow 5 Pages.dc.html".
   Same phone frame as Flow1Scans.stories.jsx. */
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
    <div style={{ position: "relative", minHeight: 0 }}>{children}</div>
  </div>
);

/* Pages, as the delivered document builds them: page 5 is the refused one. */
const pages = (n, refused = []) =>
  Array.from({ length: n }, (_, i) => ({
    n: i + 1,
    state: refused.includes(i + 1) ? "refused" : "page",
  }));

const bar = (title) => (
  <AppBar title={title} back trailing={<IconButton icon="ellipsis" label="Page menu" />} />
);

/* The footer is the same on every state of this screen: Grey, then Make PDF.
   Grey is one switch for the whole scan, and never appears inside Adjust. */
const Footer = ({ grey = false, busy = false }) => (
  <>
    <Switch label="Grey" checked={grey} />
    <Button variant="primary" fullWidth busy={busy}>
      {busy ? "Making the PDF…" : "Make PDF"}
    </Button>
  </>
);

/* One page screen: bar, body, footer. Children go between page and rail. */
const Pages = ({ title, grey = false, busy = false, error, page, rail, overlay }) => (
  <Phone>
    <div style={{ display: "grid", gridTemplateRows: "auto 1fr", height: "100%", minHeight: 0 }}>
      {bar(title)}
      <Screen footer={<Footer grey={grey} busy={busy} />}>
        {error ? <ErrorLine>{error}</ErrorLine> : null}
        {page}
        {rail}
      </Screen>
    </div>
    {overlay}
  </Phone>
);

export default { title: "Flows/5 Pages" };

export const S16GreyOn = {
  name: "S16 — pages, Grey switched on",
  render: () => (
    <Pages
      title="Page 3 of 12"
      grey
      page={<PageImage grey alt="Page 3 of 12" />}
      rail={<PageStrip pages={pages(12)} selected={3} total={12} grey />}
    />
  ),
};

export const S16bRailAt40 = {
  name: "S16b — the rail at 40 pages, jump open",
  /* The case the rail exists for: page 5 is refused and carries the tile rule,
     and the jump is open with a page number typed in. */
  render: () => (
    <Pages
      title="Page 12 of 40"
      page={<PageImage alt="Page 12 of 40" />}
      rail={
        <PageStrip
          pages={pages(40, [5])}
          selected={12}
          total={40}
          jump="open"
          jumpValue="37"
        />
      }
    />
  ),
};

export const S17RefusedPage = {
  name: "S17 — a refused page",
  /* Secondary, not primary: the screen's action is still Make PDF in the footer. */
  render: () => (
    <Pages
      title="Page 5 of 12"
      page={
        <>
          <PageImage
            state="refused"
            refusedText="This page could not be scanned."
            alt="Page 5 of 12, could not be scanned"
          />
          <Button variant="secondary" fullWidth style={{ marginTop: "var(--space-4)" }}>
            Scan this page again
          </Button>
        </>
      }
      rail={<PageStrip pages={pages(12, [5])} selected={5} total={12} />}
    />
  ),
};

/* The menu is anchored under the bar button it came from, on the dialog scrim. */
const MenuOverlay = ({ items }) => (
  <div
    style={{
      position: "absolute",
      inset: 0,
      background: "color-mix(in srgb, var(--neutral-900) 38%, transparent)",
      display: "grid",
      justifyItems: "end",
      alignContent: "start",
      padding: "var(--screen-padding)",
    }}
  >
    <MenuList title="Page" items={items} style={{ marginTop: 52 }} />
  </div>
);

const MENU_3 = [
  { label: "Retake this page", icon: "camera" },
  { label: "Adjust page", icon: "sliders-horizontal" },
  { label: "Delete page", icon: "trash-2", destructive: true },
];

const MENU_4 = [
  { label: "Retake this page", icon: "camera" },
  { label: "Adjust page", icon: "sliders-horizontal" },
  { label: "Shoot another page", icon: "plus" },
  { label: "Delete page", icon: "trash-2", destructive: true },
];

export const S18MenuWhileChecking = {
  name: "S18 — the Page menu, while checking",
  render: () => (
    <Pages
      title="Page 3 of 12"
      page={<PageImage alt="Page 3 of 12" />}
      rail={<PageStrip pages={pages(12)} selected={3} total={12} />}
      overlay={<MenuOverlay items={MENU_3} />}
    />
  ),
};

export const S19MenuFinishedScan = {
  name: "S19 — the Page menu, on a finished scan",
  render: () => (
    <Pages
      title="Page 3 of 40"
      page={<PageImage alt="Page 3 of 40" />}
      rail={<PageStrip pages={pages(40)} selected={3} total={40} />}
      overlay={<MenuOverlay items={MENU_4} />}
    />
  ),
};

export const S20DeleteConfirm = {
  name: "S20 — delete-a-page confirmation",
  render: () => (
    <Pages
      title="Page 3 of 12"
      page={<PageImage alt="Page 3 of 12" />}
      rail={<PageStrip pages={pages(12)} selected={3} total={12} />}
      overlay={
        <ConfirmDialog
          title="Delete this page?"
          body="The photo goes too. This cannot be undone."
          confirmLabel="Delete page"
          cancelLabel="Cancel"
        />
      }
    />
  ),
};

export const S21MakePdfBusy = {
  name: "S21 — Make PDF busy",
  render: () => (
    <Pages
      title="Page 3 of 12"
      busy
      page={<PageImage alt="Page 3 of 12" />}
      rail={<PageStrip pages={pages(12)} selected={3} total={12} />}
    />
  ),
};

export const S22MakePdfFailed = {
  name: "S22 — Make PDF failed",
  /* The engine's own finished sentence, printed unchanged; no copy table holds it. */
  render: () => (
    <Pages
      title="Page 3 of 12"
      error="The PDF could not be written: the iPhone is out of storage."
      page={<PageImage alt="Page 3 of 12" />}
      rail={<PageStrip pages={pages(12)} selected={3} total={12} />}
    />
  ),
};
