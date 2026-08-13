import { PageHandles } from "../ds.js";

export default {
  title: "Document/PageHandles",
  component: PageHandles,
  args: { style: { width: 240 } },
};

export const Resting = { args: { count: 4, inset: 8 } };
export const HandleHeld = { args: { count: 4, inset: 8, held: 0 } };
export const Refused = {
  args: {
    count: 8,
    inset: 18,
    refused: true,
    // placeholder sentence, awaiting task 4 (Julian owns this copy)
    refusedText: "This crop falls outside the page. Move a corner back in.",
  },
};
