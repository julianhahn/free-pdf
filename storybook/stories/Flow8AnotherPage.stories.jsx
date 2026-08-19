import React from "react";
import { AppBar, Screen } from "@ds/ui_kits/iphone/Chrome.jsx";
import { Button, Shutter, Viewfinder } from "../ds.js";
import { Phone } from "./Phone.jsx";

/* Flow 8, one more page on a finished scan: S39 of "FreePDF Flow 8-9.dc.html".
   The same camera screen as Flow3Camera.stories.jsx; only the calm note inside the
   Viewfinder is new. Flow 9 adds no screens. */

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
    <Phone grid>
      <AppBar title="Page 41" back />
      <Screen
        footer={
          <Button variant="primary" fullWidth>
            Scan 1 page
          </Button>
        }
      >
        <Viewfinder note="The PDF was removed. It is made again after this page.">
          {/* The page number is the app bar title only — see Flow3Camera. */}
          <Preview />
        </Viewfinder>
        <div style={{ display: "grid", placeItems: "center", paddingTop: "var(--space-2)" }}>
          <Shutter label="Photograph page 41" />
        </div>
      </Screen>
    </Phone>
  ),
};
