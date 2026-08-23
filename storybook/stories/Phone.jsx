import React from "react";
import { StatusLine } from "@ds/ui_kits/iphone/Chrome.jsx";

/* The phone every flow story is drawn inside: one 390x844 iPhone in portrait — the
   only size the app has — with the kit's status line above the screen. It was copied
   into all seven Flow*.stories.jsx files; it is written once here instead.

   `grid` is the one thing those copies disagreed about, and both answers are real
   layout, not drift. With it, the body is two rows, a bar and the rest, and the story
   hands the phone its app bar and its <Screen> as two children (Flows 1-2, 3, 4, 7
   and 8). Without it the body is a plain positioned box and the story lays the whole
   screen out itself — Flow 5 builds the two rows so it can hang a dialog or a menu
   beside them, Flow 6 does the same and also gives the phone a bare <Screen> with no
   bar at all for the takeover. */
const body = { position: "relative", minHeight: 0 };

export const Phone = ({ children, grid = false }) => (
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
    <div style={grid ? { ...body, display: "grid", gridTemplateRows: "auto 1fr" } : body}>
      {children}
    </div>
  </div>
);
