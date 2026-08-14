import React from "react";
import { AppBar, Screen, StatusLine } from "@ds/ui_kits/iphone/Chrome.jsx";
import { Button, PageCounter, Shutter, Viewfinder } from "../ds.js";

/* Flow 8, one more page on a finished scan: S39 of "FreePDF Flow 8-9.dc.html".
   Same phone frame and same camera screen as Flow3Camera.stories.jsx; only the
   calm note inside the Viewfinder is new. Flow 9 adds no screens. */
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

export default { title: "Flows/8 One more page" };

export const S39ShootAnotherPage = {
  name: "S39 — the camera at page 41 after Shoot another page",
  /* Page 41 because numbers keep their gaps and are never reused. One photo is
     waiting, so the footer counts 1, singular. */
  render: () => (
    <Phone>
      <AppBar title="Page 41" back />
      <Screen
        footer={
          <Button variant="primary" fullWidth>
            Scan 1 page
          </Button>
        }
      >
        <Viewfinder note="The PDF was removed. It is made again after this page.">
          <Preview />
          <div style={{ position: "absolute", top: "var(--space-3)", left: "var(--space-3)" }}>
            <PageCounter onDark>Page 41</PageCounter>
          </div>
        </Viewfinder>
        <div style={{ display: "grid", placeItems: "center", paddingTop: "var(--space-2)" }}>
          <Shutter label="Photograph page 41" />
        </div>
      </Screen>
    </Phone>
  ),
};
