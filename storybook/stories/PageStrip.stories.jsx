import { PageStrip } from "../ds.js";

const pages = Array.from({ length: 12 }, (_, i) => ({ n: i + 1 }));
const manyPages = Array.from({ length: 40 }, (_, i) => ({ n: i + 1 }));
const withRefused = pages.map((p) => (p.n === 5 ? { ...p, state: "refused" } : p));

export default {
  title: "Document/PageStrip",
  component: PageStrip,
  args: { pages, selected: 3, total: 12, style: { width: 560 } },
};

export const SelectedTile = {};
export const RefusedTile = { args: { pages: withRefused, selected: 5 } };
export const GreyOn = { args: { grey: true } };
export const JumpClosed = { args: { jump: "closed" } };
export const JumpOpen = { args: { jump: "open", jumpValue: "37" } };
export const RailScrolled = { args: { pages: manyPages, selected: 12, total: 40 } };
