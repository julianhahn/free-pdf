import { PageHandles } from "../ds.js";

export default {
  title: "Document/PageHandles",
  component: PageHandles,
  args: { style: { width: 240 } },
};

export const Resting = { args: { count: 4, inset: 8 } };

/* Held: the grip grows, every other grip stops being painted, and the loupe
   docks on the far side of the picture - tied back to the finger by one level
   accent rule that ends under the fingertip and runs into the circle. */
export const HandleHeldLeft = {
  name: "Handle held on the left — the loupe docks right",
  /* Bottom left corner. The finger is on the left half, so the disc goes to the
     right edge and the leader runs left to right. Nothing is drawn over the
     corner being dragged. */
  args: { count: 4, inset: 18, held: 3 },
};

export const HandleHeldRight = {
  name: "Handle held on the right — the loupe docks left",
  /* The mirror: same one rule, pointing the other way. Crossing the middle
     swaps the sides with no animation, and at the crossing point the run is the
     same length either way, so the swap is symmetric rather than a lurch. */
  args: { count: 4, inset: 18, held: 2 },
};

export const HandleHeldTopCorner = {
  name: "Handle held at the top corner — the disc slides in, the leader stays level",
  /* The case every Edges corner hits: the circle would leave the picture, so it
     slides inward until it is one --space-2 from the edge. The leader does not
     move with it - it stays at the fingertip's height and still lands on the
     crosshair, which is why the cross sits off the disc's geometric centre and
     more of the sheet shows on the side the paper is on. */
  args: { count: 4, inset: 8, held: 0 },
};

export const CropGripHeld = {
  name: "Crop grip held — eight grips, one painted",
  /* Both handle sets get it: Edges on the photo, Crop on the page. This is also
     the middle case - "Top edge" sits at exactly 50%, and the rule is "dock
     right below 50%, left otherwise", so it docks left every time instead of
     flickering. Seven grips lose their paint here; their touch targets, labels
     and hit testing are untouched. */
  args: { count: 8, inset: 18, held: 4 },
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
  /* Refused is the one state that never magnifies: there is nothing to aim at,
     so there is no disc and no leader either. */
  args: {
    count: 8,
    inset: 18,
    refused: true,
    held: 2,
    refusedText: "The crop falls outside the page. Move a corner back in.",
  },
};
