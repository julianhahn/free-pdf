import { PageCounter } from "../ds.js";

export default { title: "Document/PageCounter", component: PageCounter };

export const OnLight = { args: { children: "Page 3 of 12" } };
export const OverAViewfinder = {
  args: { children: "Page 7", onDark: true },
  decorators: [(Story) => <div style={{ background: "var(--viewfinder)", padding: "var(--space-4)" }}><Story /></div>],
};
