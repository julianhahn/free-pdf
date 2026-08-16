import { PageStrip } from "../ds.js";

const pages = Array.from({ length: 12 }, (_, i) => ({ n: i + 1 }));
const threePages = pages.slice(0, 3);
const manyPages = Array.from({ length: 40 }, (_, i) => ({ n: i + 1 }));
const withRefused = pages.map((p) => (p.n === 5 ? { ...p, state: "refused" } : p));

export default {
  title: "Document/PageStrip",
  component: PageStrip,
  args: { pages, selected: 3, total: 12, style: { width: 560 } },
};

/* The default args are a twelve page scan, so every story below carries the jump.
   Ten pages is where it starts; ThreePagesNoJump is the other side of that line. */
export const SelectedTile = {};
export const RefusedTile = { args: { pages: withRefused, selected: 5 } };
export const GreyOn = { args: { grey: true } };
export const JumpClosed = { args: { jump: "closed" } };
export const JumpOpen = { args: { jump: "open", jumpValue: "37" } };
/* Under ten pages the rail is the rail: no "Go to page", and jump="open" is
   ignored rather than obeyed. */
export const ThreePagesNoJump = {
  args: { pages: threePages, selected: 2, total: 3, jump: "open" },
};
export const RailScrolled = { args: { pages: manyPages, selected: 12, total: 40 } };
