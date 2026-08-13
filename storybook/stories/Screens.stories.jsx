import { StatusLine } from "@ds/ui_kits/iphone/Chrome.jsx";
import { ScansScreen } from "@ds/ui_kits/iphone/ScansScreen.jsx";
import { CameraScreen } from "@ds/ui_kits/iphone/CameraScreen.jsx";
import { PagesScreen } from "@ds/ui_kits/iphone/PagesScreen.jsx";
import { AdjustScreen } from "@ds/ui_kits/iphone/AdjustScreen.jsx";
import { DoneScreen } from "@ds/ui_kits/iphone/DoneScreen.jsx";

/* The delivered iPhone kit, unchanged. Only the phone-sized frame around it
   (390 x 844, the kit's own App.jsx shell) is repeated here. */
const phone = (Screen) => () => (
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
    <div style={{ position: "relative", minHeight: 0 }}>
      <Screen />
    </div>
  </div>
);

export default { title: "Screens" };

export const Scans = { render: phone(ScansScreen) };
export const Camera = { render: phone(CameraScreen) };
export const Pages = { render: phone(PagesScreen) };
export const Adjust = { render: phone(AdjustScreen) };
export const Done = { render: phone(DoneScreen) };
