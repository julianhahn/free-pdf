import React from "react";
import { AppBar, Screen } from "@ds/ui_kits/iphone/Chrome.jsx";
import {
  Button,
  ConfirmDialog,
  ErrorLine,
  IconButton,
  MenuList,
  PageCounter,
  PageImage,
  PageStrip,
  ProgressLine,
  Switch,
} from "../ds.js";
import { Phone } from "./Phone.jsx";

/* Flow 5, the pages: S16, S16b, S17 to S22 of "FreePDF Flow 5 Pages.dc.html". */

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
   Grey is one switch for the whole scan, and never appears inside Adjust. It is
   a fact about the pages, not about the screen: flipping it rewrites every page
   under the same takeover Apply to all pages uses, and the switch afterwards
   reads what the pages are. */
const Footer = ({ grey = false, busy = false }) => (
  <>
    <Switch label="Grey" checked={grey} />
    <Button variant="primary" fullWidth busy={busy}>
      {busy ? "Making the PDF…" : "Make PDF"}
    </Button>
  </>
);

/* One page screen: bar, body, footer. The body is the page, then Adjust, then
   whatever `extra` that state adds, then the rail.

   Adjust is a control of its own here, not a glyph inside the "…" menu - it was
   the hardest thing in the app to find (Julian, 2026-08-16). It is in the same
   slot on every page, and where the page's photo is gone it is disabled, never
   hidden, so it does not move: the disabled colour role, not an opacity. */
const Pages = ({
  title,
  grey = false,
  busy = false,
  error,
  page,
  photo = true,
  rail,
  extra,
  overlay,
}) => (
  <Phone>
    <div style={{ display: "grid", gridTemplateRows: "auto 1fr", height: "100%", minHeight: 0 }}>
      {bar(title)}
      <Screen footer={<Footer grey={grey} busy={busy} />}>
        {error ? <ErrorLine>{error}</ErrorLine> : null}
        {page}
        <Button variant="secondary" fullWidth disabled={!photo}>
          Adjust page
        </Button>
        {extra}
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
  /* Secondary, not primary: the screen's action is still Make PDF in the footer.
     The photo is still there - the engine refused it - so Adjust is live. */
  render: () => (
    <Pages
      title="Page 5 of 12"
      page={
        <PageImage
          state="refused"
          refusedText="This page could not be scanned."
          alt="Page 5 of 12, could not be scanned"
        />
      }
      extra={
        <Button variant="secondary" fullWidth>
          Scan this page again
        </Button>
      }
      rail={<PageStrip pages={pages(12, [5])} selected={5} total={12} />}
    />
  ),
};

export const AdjustWithoutPhoto = {
  name: "Adjust, on a page whose photo is gone",
  /* Adjust re-runs the recipe from the photo, so a page whose photo went with
     the share cannot be adjusted. The control stays where it is and refuses. */
  render: () => (
    <Pages
      title="Page 3 of 12"
      photo={false}
      page={<PageImage alt="Page 3 of 12" />}
      rail={<PageStrip pages={pages(12)} selected={3} total={12} />}
    />
  ),
};

export const ThreePagesNoJump = {
  name: "A three page scan — the rail carries no jump",
  /* Under ten pages the rail is the rail and nothing else. Ten is Julian's
     number, 2026-08-16: "Go to page" on a one page scan has nowhere to go. */
  render: () => (
    <Pages
      title="Page 2 of 3"
      page={<PageImage alt="Page 2 of 3" />}
      rail={<PageStrip pages={pages(3)} selected={2} total={3} />}
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

export const GreyRewritingEveryPage = {
  name: "Grey — rewriting every page",
  /* Flipping Grey is the all-pages run, so it takes the phone over exactly as
     Apply to all pages does: no app bar, no way back, and the note turned round
     - this one cannot resume. Same furniture as flow 6's S31. */
  render: () => (
    <Phone>
      <Screen>
        <div
          style={{
            display: "grid",
            alignContent: "center",
            justifyItems: "start",
            height: "100%",
            gap: "var(--space-4)",
          }}
        >
          <PageCounter>Page 5 of 12</PageCounter>
          <ProgressLine line="Applying to 12 pages…" note="Keep the app open." value={5} max={12} />
        </div>
      </Screen>
    </Phone>
  ),
};

export const GreySkippedPages = {
  name: "Grey — the pages it could not rewrite",
  /* Back on the pages afterwards. A page whose photo is gone cannot be
     rewritten; those pages are skipped and named, the same sentence the
     all-pages Apply leaves behind. */
  render: () => (
    <Pages
      title="Page 3 of 20"
      grey
      error="Pages 4, 9 and 18 were not changed, because their photos are missing."
      page={<PageImage grey alt="Page 3 of 20" />}
      rail={<PageStrip pages={pages(20)} selected={3} total={20} grey />}
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
