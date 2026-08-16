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

/* Flow 6, adjusting a page: S24 to S32 of "FreePDF Flow 6 Adjust.dc.html",
   plus what the phone showed Julian on 2026-08-16 (TASKS.md 21, 22, 25, 26).
   Same phone frame as Flow5Pages.stories.jsx.

   Three things the delivered document does not have, and the app now does:

   - Every tool shows what it would do. A moment after a value moves, the
     picture is a real engine run of the current values into a scratch file, so
     what is on screen is what Apply writes. Change-then-Apply stays: only
     Apply leaves the tool and writes the page. A preview that fails shows the
     engine's own sentence and leaves the last good picture up. The document's
     "There is no live preview anywhere" is false (TASKS.md 26).
   - A held handle puts the magnifier on the far side of the picture from the
     hand, tied back to the fingertip by one level rule, and the corner is aimed
     with its crosshair rather than with the finger. Every other grip stops
     being painted while the drag lasts (TASKS.md 25).
   - The screen opens on what was last applied, not on a fresh suggestion: the
     turn is remembered and the crop box opens on the whole picture, because
     Apply composes the new drag onto the stored one and a crop can only ever
     be cut tighter. "Back to the suggestion" is the one way back to the
     engine's own answer (TASKS.md 21 and 22). */
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

/* One adjust screen: bar, the engine's sentence when a run failed, the picture,
   the tool strip, the active tool's controls, and the all-pages switch in the
   footer. The picture is the preview - what the current values would make of
   the page - except on Edges, which shows the photo. Brightness and Sharpen
   draw the page itself: the kit's page is a ruled placeholder with no tone and
   no grain, so their run has nothing to show here that the phone shows. */
const Adjust = ({ tool, page, controls, busy = false, error }) => (
  <Phone>
    <div style={{ display: "grid", gridTemplateRows: "auto 1fr", height: "100%", minHeight: 0 }}>
      <AdjustBar busy={busy} />
      <Screen footer={<Switch label="Apply to all pages" />}>
        {error ? <ErrorLine>{error}</ErrorLine> : null}
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

/* The page as the current values would leave it - the picture the engine wrote
   into its scratch file a moment after the value stopped moving. Nothing is
   written to the page until Apply. The kit's page is a placeholder drawing, so
   the run is shown here by drawing the page the way the values leave it. */
const Preview = ({ angle = 0, width = 210, ...props }) => (
  <div style={{ height: 250, display: "grid", placeItems: "center" }}>
    <Page style={{ width, transform: `rotate(${angle}deg)` }} {...props} />
  </div>
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

const Edges = ({ note, held }) => (
  <Adjust
    tool="Edges"
    /* Edges keeps showing the photo: its handles are the sheet's corners, which
       the engine takes in photo pixels. */
    page={<PageHandles count={4} inset={7} held={held} style={{ width: 230, justifySelf: "center" }} />}
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

export const S24EdgesCornerHeld = {
  name: "S24 — Edges, a corner under the finger",
  /* The magnifier on the far side of the picture from the hand, one rule
     running level from under the fingertip into it, the crosshair on the
     corner: the corner goes where the crosshair is, not where the finger is.
     The other three corners keep their targets and their names but lose their
     paint, so nothing sits near the thumb. The four corner names are unchanged,
     and a screen reader never announces the magnifier. */
  render: () => <Edges held={2} />,
};

export const S28Crop = {
  name: "S28 — Crop, opening on the whole picture",
  /* The box opens on the whole picture every time, because Apply composes this
     drag onto the crop already stored - so a crop can only ever be cut tighter,
     never widened back out. */
  render: () => (
    <Adjust
      tool="Crop"
      page={<PageHandles count={8} inset={0} style={{ width: 230, justifySelf: "center" }} />}
      controls={<Reset />}
    />
  ),
};

export const S28CropGripHeld = {
  name: "S28 — Crop, a grip under the finger",
  /* The magnifier is on both handle sets, Edges on the photo and Crop on the
     page. Here the picture under it is the preview, so the loupe shows what the
     values would make of the page, not the page on disk. Crop is the screen
     Julian called crowded: seven of the eight grips lose their paint the moment
     one is held, which is the real subtraction. */
  render: () => (
    <Adjust
      tool="Crop"
      page={<PageHandles count={8} inset={16} held={2} style={{ width: 230, justifySelf: "center" }} />}
      controls={<Reset />}
    />
  ),
};

export const S28CropRefused = {
  name: "S28 — Crop, the box is refused while held",
  /* The sentence is the copy table's, not the delivered document's. A refused
     box never magnifies, even with a grip under the finger: there is nothing
     to aim at. */
  render: () => (
    <Adjust
      tool="Crop"
      page={
        <PageHandles
          count={8}
          inset={16}
          held={2}
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
  /* The picture is already a run of these values: the preview is not something
     the user turns on, it is what the picture is. */
  render: () => (
    <Adjust
      tool="Straighten"
      page={<Preview angle={-1.4} />}
      controls={
        <>
          <Angle value={-1.4} />
          <Reset />
        </>
      }
    />
  ),
};

export const S25StraightenMoved = {
  name: "S25 — Straighten moved, the picture follows before Apply",
  /* The value moved to +6.2 and, a moment after it stopped, the picture became
     the page these values would produce - a real engine run, so what is on
     screen is what Apply writes. Apply has not been pressed and the page on
     disk is untouched. The tick stays where the engine's answer was. */
  render: () => (
    <Adjust
      tool="Straighten"
      page={<Preview angle={6.2} />}
      controls={
        <>
          <Angle value={6.2} />
          <Reset />
        </>
      }
    />
  ),
};

export const S25StraightenOpensOnWhatWasApplied = {
  name: "S25 — Straighten opens on what was last applied",
  /* Opening the screen again does not re-seed the controls: they come up on the
     page's stored values, here −4.0, while the tick still marks the engine's
     −1.4. "Back to the suggestion" is the one way back to it. */
  render: () => (
    <Adjust
      tool="Straighten"
      page={<Preview angle={-4} />}
      controls={
        <>
          <Angle value={-4} />
          <Reset />
        </>
      }
    />
  ),
};

export const S25PreviewFailed = {
  name: "S25 — a preview that failed",
  /* The engine's own sentence, printed unchanged exactly as Apply prints it,
     and the last good picture stays up under it. Nothing was written. */
  render: () => (
    <Adjust
      tool="Crop"
      error="A 2400x3200 crop at (100, 100) does not fit inside the 2000x2600 image."
      page={<PageHandles count={8} inset={16} style={{ width: 230, justifySelf: "center" }} />}
      controls={<Reset />}
    />
  ),
};

export const S26Brightness = {
  name: "S26 — Brightness, two sliders and a switch",
  /* The ends are sentences, as the delivered document draws them: the numbers
     mean little on their own, so each end says what happens there. */
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
  name: "S29 — Turn, opening on the turn already applied",
  /* The turn is remembered: the page file carries the quarter turns of the last
     Apply, so the screen opens on the turned page with no tap, and a tap adds a
     turn onto that one. Landscape in the same block the portrait page used, so
     nothing else moves. One button only: four taps come back to the start. The
     picture turns as soon as the tap lands, before Apply, like every value. */
  render: () => (
    <Adjust
      tool="Turn"
      page={<Preview angle={90} width={185} alt="Page 3, turned a quarter turn clockwise" />}
      controls={
        <IconButton icon="rotate-cw" label="A quarter turn clockwise" outlined />
      }
    />
  ),
};

/* 9.3 - applying. */

export const S30ApplyOnePage = {
  name: "S30 — applying to one page",
  /* The controls stay at the values being applied, so it is clear what is written,
     and the picture is still the preview of those values - Apply writes what was
     already on screen. */
  render: () => (
    <Adjust
      tool="Straighten"
      busy
      page={<Preview angle={-1.4} />}
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
