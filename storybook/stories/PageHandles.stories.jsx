import { PageHandles } from "../ds.js";

export default {
  title: "Document/PageHandles",
  component: PageHandles,
  args: { style: { width: 240 } },
};

export const Resting = { args: { count: 4, inset: 8 } };

/* Held: the grip grows, and the magnifier sits beside the finger with the
   crosshair on the grip - the thing the corner is aimed with. */
export const HandleHeld = {
  name: "Handle held — the magnifier above the finger",
  args: { count: 4, inset: 8, held: 2 },
};

export const HandleHeldAtTheTop = {
  name: "Handle held at the top — the magnifier below the finger",
  /* Nothing above a top corner to put it in, so it goes to the only other side
     a finger never covers. */
  args: { count: 4, inset: 8, held: 0 },
};

export const CropGripHeld = {
  name: "Crop grip held — the magnifier on the eight-grip set",
  /* Both handle sets get it: Edges on the photo, Crop on the page. */
  args: { count: 8, inset: 18, held: 5 },
};

export const Refused = {
  args: {
    count: 8,
    inset: 18,
    refused: true,
    refusedText: "The crop falls outside the page. Move a corner back in.",
  },
};

export const RefusedWhileHeld = {
  name: "Refused while held — no magnifier",
  /* Refused is the one state that never magnifies: there is nothing to aim at. */
  args: {
    count: 8,
    inset: 18,
    refused: true,
    held: 2,
    refusedText: "The crop falls outside the page. Move a corner back in.",
  },
};
