import React from "react";
import { AppBar, Screen, StatusLine } from "@ds/ui_kits/iphone/Chrome.jsx";
import {
  Button,
  ErrorLine,
  IconButton,
  PageCounter,
  PageHandles,
  PageImage,
  PageStrip,
  ProgressLine,
  SectionLabel,
  Slider,
  Switch,
  ToolStrip,
} from "../ds.js";

/* Flow 6, adjusting a page: S24 to S32 of "FreePDF Flow 6 Adjust.dc.html".
   Same phone frame as Flow5Pages.stories.jsx. */
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

const TOOLS = [
  { label: "Edges", icon: "scan" },
  { label: "Straighten", icon: "ruler" },
  { label: "Brightness", icon: "sun" },
  { label: "Sharpen", icon: "focus" },
  { label: "Crop", icon: "crop" },
  { label: "Turn", icon: "rotate-cw" },
];

/* The adjust bar is not the AppBar: it carries Cancel and Apply, no back arrow.
   While applying, Apply is busy and Cancel is disabled - stopping halfway would
   leave a half-written page. */
const AdjustBar = ({ busy = false }) => (
  <div
    style={{
      display: "flex",
      alignItems: "center",
      gap: "var(--space-3)",
      minHeight: 52,
      padding: "0 var(--screen-padding)",
      borderBottom: "1px solid var(--divider)",
    }}
  >
    <Button variant="ghost" disabled={busy}>
      Cancel
    </Button>
    <span
      style={{
        flex: 1,
        textAlign: "center",
        font: "var(--weight-heading) var(--text-h4)/var(--leading-heading) var(--font-heading)",
        letterSpacing: "var(--tracking-heading)",
        fontVariantNumeric: "tabular-nums",
      }}
    >
      Adjust page 3
    </span>
    <Button variant="primary" busy={busy}>
      {busy ? "Applying…" : "Apply"}
    </Button>
  </div>
);

/* One adjust screen: bar, page, tool strip, the active tool's controls,
   and the all-pages switch in the footer. */
const Adjust = ({ tool, page, controls, busy = false }) => (
  <Phone>
    <div style={{ display: "grid", gridTemplateRows: "auto 1fr", height: "100%", minHeight: 0 }}>
      <AdjustBar busy={busy} />
      <Screen footer={<Switch label="Apply to all pages" />}>
        {page}
        <ToolStrip items={TOOLS} active={tool} />
        <div style={{ display: "grid", gap: "var(--space-2)" }}>
          <SectionLabel>{tool}</SectionLabel>
          {controls}
        </div>
      </Screen>
    </div>
  </Phone>
);

const Page = (props) => (
  <PageImage style={{ width: 230, justifySelf: "center" }} alt="Page 3" {...props} />
);

/* The way back to the tick, on every tool that has a suggestion. */
const Reset = () => (
  <Button variant="ghost" style={{ justifySelf: "start" }}>
    Back to the suggestion
  </Button>
);

/* The note line under the Edges switch: 13 px body, muted, or destructive for
   the warning. Nothing to say means the line is not drawn at all. */
const NoteLine = ({ warning = false, children }) => (
  <p
    style={{
      margin: 0,
      font: "var(--weight-body) var(--text-sub)/var(--leading-body) var(--font-body)",
      color: warning ? "var(--destructive)" : "var(--text-muted)",
      textWrap: "pretty",
    }}
  >
    {children}
  </p>
);

const Edges = ({ note }) => (
  <Adjust
    tool="Edges"
    page={<PageHandles count={4} inset={7} style={{ width: 230, justifySelf: "center" }} />}
    controls={
      <>
        <Switch label="Pull the sheet flat" checked />
        {note}
      </>
    }
  />
);

export default { title: "Flows/6 Adjust" };

/* 9.1 - the tools that drag. */

export const S24EdgesNothingToSay = {
  name: "S24 — Edges, the note line not drawn",
  render: () => <Edges />,
};

export const S24EdgesNothingToCut = {
  name: "S24 — Edges, nothing to cut away",
  render: () => (
    <Edges note={<NoteLine>The sheet fills the whole photo, so there is nothing to cut away.</NoteLine>} />
  ),
};

export const S24EdgesWarning = {
  name: "S24 — Edges, the page runs off the frame",
  render: () => (
    <Edges
      note={<NoteLine warning>The page runs off the frame. Move back and photograph it again.</NoteLine>}
    />
  ),
};

export const S28Crop = {
  name: "S28 — Crop, eight handles",
  render: () => (
    <Adjust
      tool="Crop"
      page={<PageHandles count={8} inset={16} style={{ width: 230, justifySelf: "center" }} />}
      controls={<Reset />}
    />
  ),
};

export const S28CropRefused = {
  name: "S28 — Crop, the box is refused",
  /* The sentence is the copy table's, not the delivered document's. */
  render: () => (
    <Adjust
      tool="Crop"
      page={
        <PageHandles
          count={8}
          inset={16}
          refused
          refusedText="The crop falls outside the page. Move a corner back in."
          style={{ width: 230, justifySelf: "center" }}
        />
      }
      controls={<Reset />}
    />
  ),
};

/* 9.2 - the tools that slide. */

const Angle = ({ value }) => (
  <Slider
    label="Angle"
    value={value}
    min={-10}
    max={10}
    step={0.1}
    unit="°"
    minLabel="−10°"
    maxLabel="+10°"
    suggested={-1.4}
  />
);

export const S25Straighten = {
  name: "S25 — Straighten, sitting on the suggestion",
  render: () => (
    <Adjust
      tool="Straighten"
      page={<Page />}
      controls={
        <>
          <Angle value={-1.4} />
          <Reset />
        </>
      }
    />
  ),
};

export const S26Brightness = {
  name: "S26 — Brightness, two sliders and a switch",
  /* The ends are sentences: there is no preview, so each end says what happens there. */
  render: () => (
    <Adjust
      tool="Brightness"
      page={<PageImage style={{ width: 200, justifySelf: "center" }} alt="Page 3" />}
      controls={
        <>
          <Slider
            label="Black point"
            value={12}
            min={0}
            max={100}
            unit="%"
            minLabel="Darkest part stays dark"
            maxLabel="Darkest part goes black"
            suggested={12}
          />
          <Slider
            label="White point"
            value={92}
            min={0}
            max={100}
            unit="%"
            minLabel="Paper stays grey"
            maxLabel="Paper goes white"
            suggested={92}
          />
          <Switch label="Adjust the tones" />
          <Reset />
        </>
      }
    />
  ),
};

const Sharpen = ({ value }) => (
  <Slider
    label="Sharpen"
    value={value}
    min={0}
    max={20}
    step={0.1}
    minLabel="None"
    maxLabel="Most"
    suggested={0.6}
  />
);

export const S27Sharpen = {
  name: "S27 — Sharpen, at the suggested 0.6",
  render: () => (
    <Adjust
      tool="Sharpen"
      page={<Page />}
      controls={
        <>
          <Sharpen value={0.6} />
          <Reset />
        </>
      }
    />
  ),
};

export const S27SharpenAtZero = {
  name: "S27 — Sharpen at zero, reading None",
  /* The tick stays to the right of the thumb: the user went below the suggestion. */
  render: () => (
    <Adjust
      tool="Sharpen"
      page={<Page />}
      controls={
        <>
          <Sharpen value={0} />
          <Reset />
        </>
      }
    />
  ),
};

export const S29Turn = {
  name: "S29 — Turn, after one tap",
  /* Landscape in the same block the portrait page used, so nothing else moves.
     One button only: four taps come back to the start. */
  render: () => (
    <Adjust
      tool="Turn"
      page={
        <div style={{ height: 250, display: "grid", placeItems: "center" }}>
          <PageImage
            style={{ width: 185, transform: "rotate(90deg)" }}
            alt="Page 3, turned a quarter turn clockwise"
          />
        </div>
      }
      controls={
        <IconButton icon="rotate-cw" label="A quarter turn clockwise" outlined />
      }
    />
  ),
};

/* 9.3 - applying. */

export const S30ApplyOnePage = {
  name: "S30 — applying to one page",
  /* The controls stay at the values being applied, so it is clear what is written. */
  render: () => (
    <Adjust
      tool="Straighten"
      busy
      page={<Page />}
      controls={<Angle value={-1.4} />}
    />
  ),
};

export const S31ApplyAllPages = {
  name: "S31 — applying to all pages",
  /* The takeover: no app bar, no back arrow, and a PageCounter above the line. */
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
          <PageCounter>Page 12 of 40</PageCounter>
          <ProgressLine line="Applying to 40 pages…" note="Keep the app open." value={12} max={40} />
        </div>
      </Screen>
    </Phone>
  ),
};

export const S32SkippedPages = {
  name: "S32 — back on the pages, some pages skipped",
  /* Page 5 carries the refused tile, as the pages screen draws it. */
  render: () => (
    <Phone>
      <div style={{ display: "grid", gridTemplateRows: "auto 1fr", height: "100%", minHeight: 0 }}>
        <AppBar
          title="Page 3 of 40"
          back
          trailing={<IconButton icon="ellipsis" label="Page menu" />}
        />
        <Screen
          footer={
            <>
              <Switch label="Grey" />
              <Button variant="primary" fullWidth>
                Make PDF
              </Button>
            </>
          }
        >
          <ErrorLine>
            Pages 4, 9 and 18 were not changed, because their photos are missing.
          </ErrorLine>
          <PageImage alt="Page 3 of 40" />
          <PageStrip
            pages={Array.from({ length: 40 }, (_, i) => ({
              n: i + 1,
              state: i + 1 === 5 ? "refused" : "page",
            }))}
            selected={3}
            total={40}
          />
        </Screen>
      </div>
    </Phone>
  ),
};
