import { StatusLine } from "@ds/ui_kits/iphone/Chrome.jsx";
import { ScansScreen } from "@ds/ui_kits/iphone/ScansScreen.jsx";
import { CameraScreen } from "@ds/ui_kits/iphone/CameraScreen.jsx";
import { PagesScreen } from "@ds/ui_kits/iphone/PagesScreen.jsx";
import { AdjustScreen } from "@ds/ui_kits/iphone/AdjustScreen.jsx";
import { DoneScreen } from "@ds/ui_kits/iphone/DoneScreen.jsx";

/* The delivered iPhone kit, unchanged. Only the phone-sized frame around it
   (390 x 844, the kit's own App.jsx shell) is repeated here. */
const phone = (Screen, props = {}) => () => (
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
      <Screen {...props} />
    </div>
  </div>
);

export default { title: "Screens" };

export const Scans = { render: phone(ScansScreen) };
export const ScansEmpty = { render: phone(ScansScreen, { scans: [] }) };
export const ScansRowPressed = { render: phone(ScansScreen, { pressedId: "a" }) };
/* No ScansError story: the storage failure sentence over the scans list is the
   system's own (user-flows 1, lines 62-63) and no copy table has one, EN or DE.
   `error` stays unset until task 4 supplies it. */

export const Camera = { render: phone(CameraScreen) };
export const CameraFirstShot = { render: phone(CameraScreen, { pages: 0 }) };
export const CameraPage40 = { render: phone(CameraScreen, { pages: 39 }) };
export const CameraWriting = { render: phone(CameraScreen, { writing: true }) };
export const CameraErrorStorage = { render: phone(CameraScreen, { error: "storage" }) };
export const CameraErrorNotReady = { render: phone(CameraScreen, { error: "notReady" }) };
export const CameraErrorNoPhoto = { render: phone(CameraScreen, { error: "noPhoto" }) };
export const CameraErrorStopped = { render: phone(CameraScreen, { error: "stopped" }) };
export const CameraBlockedPermission = {
  render: phone(CameraScreen, { blocked: "permission" }),
};
export const CameraBlockedNoCamera = { render: phone(CameraScreen, { blocked: "noCamera" }) };
export const CameraBlockedStartFailed = {
  render: phone(CameraScreen, { blocked: "startFailed" }),
};
export const CameraSimulator = { render: phone(CameraScreen, { simulator: true }) };

const GOOD_PAGES = Array.from({ length: 12 }, (_, i) => ({ n: i + 1, state: "page" }));

export const Pages = { render: phone(PagesScreen) };
export const PagesJumpOpen = { render: phone(PagesScreen, { total: 40, jump: "open" }) };
export const PagesRefused = { render: phone(PagesScreen, { start: 5 }) };
export const PagesRefusedEngineSentence = {
  render: phone(PagesScreen, {
    start: 5,
    pages: GOOD_PAGES.map((p) =>
      p.n === 5
        ? { n: 5, state: "refused", refusedText: "This page could not be scanned." }
        : p,
    ),
  }),
};
export const PagesPhotoGone = {
  render: phone(PagesScreen, {
    start: 5,
    menuOpen: true,
    pages: GOOD_PAGES.map((p) => (p.n === 5 ? { n: 5, state: "photo-gone" } : p)),
  }),
};
export const PagesAllGood = { render: phone(PagesScreen, { pages: GOOD_PAGES }) };
export const PagesMenuChecking = { render: phone(PagesScreen, { menuOpen: true }) };
export const PagesMenuDone = { render: phone(PagesScreen, { menuOpen: true, done: true }) };
export const PagesSkippedNote = {
  render: phone(PagesScreen, {
    skippedNote: "Pages 4, 9 and 18 were not changed, because their photos are missing.",
  }),
};
/* No PagesMakePdfHidden story either: Make PDF is derived now — the default page
   list already hides it (page 5 is refused), which the Pages story shows.
   No PagesMakePdfFailed story: the failure sentence is the engine's own
   (user-flows 8.5) and no copy table has one. Flagged for task 4. */

export const Adjust = { render: phone(AdjustScreen) };
export const AdjustEdges = {
  render: phone(AdjustScreen, { tool: "Edges", edges: "none" }),
};
export const AdjustEdgesNothingToCut = {
  render: phone(AdjustScreen, { tool: "Edges", edges: "nothing-to-cut" }),
};
export const AdjustEdgesWarning = {
  render: phone(AdjustScreen, { tool: "Edges", edges: "warning" }),
};
export const AdjustCrop = { render: phone(AdjustScreen, { tool: "Crop" }) };
export const AdjustCropRefused = {
  render: phone(AdjustScreen, {
    tool: "Crop",
    cropRefused: true,
    cropRefusedText: "The crop falls outside the page. Move a corner back in.",
  }),
};
export const AdjustStraighten = { render: phone(AdjustScreen, { tool: "Straighten" }) };
export const AdjustBrightness = {
  render: phone(AdjustScreen, {
    tool: "Brightness",
    blackPointLabel: "Black point",
    whitePointLabel: "White point",
    levelsLabel: "Adjust the tones",
  }),
};
export const AdjustSharpen = { render: phone(AdjustScreen, { tool: "Sharpen" }) };
/* Sharpen can sit at 0: the client then skips the call (user-flows 7a). What 0 READS AS
   is missing wording — no copy table has it, so nothing is invented, the slider just
   stands at 0. Flagged for task 4. */
export const AdjustSharpenZero = { render: phone(AdjustScreen, { tool: "Sharpen", sharpen: 0 }) };
export const AdjustTurn = { render: phone(AdjustScreen, { tool: "Turn" }) };
export const AdjustApplyingAll = { render: phone(AdjustScreen, { applyingAll: true }) };
/* No AdjustApplyingOne story: applying to one page is just the busy Apply button,
   driven by a press, not by a prop.
   No AdjustSkipped story: that sentence lives on the pages screen now. */

export const Done = { render: phone(DoneScreen) };
export const DoneNameTyped = { render: phone(DoneScreen, { name: "Insurance letter" }) };
/* No story restores a reader-sheet title: §9.1 gives the sheet none. The close
   wording is the copy table's "Close the PDF" (user-flows 9.1), which the design
   system's Sheet already defaults to. */
export const DoneNameFocused = { render: phone(DoneScreen, { focusName: true }) };
/* No story passes `photosGroupLabel`: no copy table names the label over the
   photo-deletion group. Flagged for task 4. */
export const DonePhotosDeleted = { render: phone(DoneScreen, { photos: false }) };
export const DoneReaderSheet = { render: phone(DoneScreen, { reader: true }) };
