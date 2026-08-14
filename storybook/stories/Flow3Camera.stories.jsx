import React from "react";
import { AppBar, Screen, StatusLine } from "@ds/ui_kits/iphone/Chrome.jsx";
import { Button, EmptyState, ErrorLine, PageCounter, Shutter, Viewfinder } from "../ds.js";

/* Flow 3, shooting the pages: S7 to S12 of "FreePDF Flow 3 Camera.dc.html".
   Same phone frame as Flow1Scans.stories.jsx. Every sentence is copied from the
   camera table in ios/AGENTS.md, which the task names as the authority. */
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

/* The picture inside the frame stands in for the live preview. */
const Preview = () => (
  <div style={{ position: "absolute", inset: "14% 16%", background: "#38352f", boxShadow: "0 0 40px rgba(0,0,0,.5) inset" }} />
);

/* The footer label: the singular comes from user-flows §4, the rest from the copy table. */
const footerLabel = (pages) =>
  pages === 0 ? "Photograph at least one page" : pages === 1 ? "Scan 1 page" : `Scan ${pages} pages`;

/* S7's frame, and every other camera screen is this frame with one thing changed. */
const CameraFrame = ({ page, pages, writing = false, error = null, note = null }) => (
  <Phone>
    <AppBar title={`Page ${page}`} back />
    <Screen
      footer={
        <Button variant="primary" fullWidth disabled={pages === 0}>
          {footerLabel(pages)}
        </Button>
      }
    >
      {error ? <ErrorLine>{error}</ErrorLine> : null}
      <Viewfinder note={note}>
        <Preview />
        {/* The counter over the picture, inset space-3 from the top-left corner (S7 spec). */}
        <div style={{ position: "absolute", top: "var(--space-3)", left: "var(--space-3)" }}>
          <PageCounter onDark>{`Page ${page}`}</PageCounter>
        </div>
      </Viewfinder>
      <div style={{ display: "grid", placeItems: "center", paddingTop: "var(--space-2)" }}>
        <Shutter
          disabled={writing}
          label={writing ? `Photographing page ${page}, wait` : `Photograph page ${page}`}
        />
      </div>
    </Screen>
  </Phone>
);

/* The whole screen becomes one sentence, and a button only where there is
   something to do (S10 has one, S11 has none). */
const BlockedScreen = ({ page, sentence, action }) => (
  <Phone>
    <AppBar title={`Page ${page}`} back />
    <Screen>
      <div style={{ display: "grid", alignContent: "center", minHeight: "100%" }}>
        <EmptyState icon="camera-off" title={sentence} action={action} />
      </div>
    </Screen>
  </Phone>
);

export default { title: "Flows/3 Camera" };

export const S7ShutterDisabled = {
  name: "S7 — shutter dead while the photo is written",
  render: () => <CameraFrame page={7} pages={6} writing />,
};

export const S8BeforeTheFirstShot = {
  name: "S8 — before the first shot",
  render: () => <CameraFrame page={1} pages={0} />,
};

export const S8Counter = {
  name: "S8 — the counter at 1, 7 and 40",
  /* Tabular figures at every value, on paper and over the viewfinder. */
  render: () => (
    <div style={{ display: "grid", gap: "var(--space-4)", justifyItems: "start" }}>
      <div style={{ display: "flex", gap: "var(--space-3)" }}>
        {[1, 7, 40].map((n) => (
          <PageCounter key={n}>{`Page ${n}`}</PageCounter>
        ))}
      </div>
      <div style={{ display: "flex", gap: "var(--space-3)", background: "var(--viewfinder)", padding: "var(--space-4)", borderRadius: "var(--radius-md)" }}>
        {[1, 7, 40].map((n) => (
          <PageCounter key={n} onDark>{`Page ${n}`}</PageCounter>
        ))}
      </div>
    </div>
  ),
};

export const S9PhotoMissedTheDisk = {
  name: "S9 — a photo missed the disk",
  /* One shape, the reason swapped in. Shown with the storage reason; the shutter
     stays live and the title still says Page 7, the number was not used up. */
  render: () => (
    <CameraFrame
      page={7}
      pages={6}
      error="Page 7 was not saved: the iPhone is out of storage. Nothing already photographed is lost."
    />
  ),
};

export const S10PermissionDenied = {
  name: "S10 — permission denied",
  render: () => (
    <BlockedScreen
      page={7}
      sentence="FreePDF needs the camera to photograph the pages."
      action={<Button variant="primary">Open Settings</Button>}
    />
  ),
};

export const S11NoCameraHardware = {
  name: "S11 — the screen cannot work, no camera",
  render: () => <BlockedScreen page={7} sentence="This iPhone has no camera to photograph with." />,
};

export const S11SessionFailed = {
  name: "S11 — the screen cannot work, the camera did not start",
  render: () => <BlockedScreen page={7} sentence="The camera could not be started." />,
};

export const S11StandInFailed = {
  name: "S11 — the screen cannot work, the stand-in did not draw",
  render: () => <BlockedScreen page={7} sentence="Page 7 could not be drawn." />,
};

export const S12SimulatorNote = {
  name: "S12 — the simulator stand-in",
  render: () => (
    <CameraFrame
      page={7}
      pages={6}
      note="No camera on this iPhone. The shutter draws a page instead."
    />
  ),
};
