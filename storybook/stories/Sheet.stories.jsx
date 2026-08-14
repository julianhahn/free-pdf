import { Sheet, PageImage } from "../ds.js";

export default {
  title: "Feedback/Sheet",
  component: Sheet,
  args: {
    title: "11 Aug 2026, 20:14",
    closeLabel: "Close the PDF",
    style: { width: 700, height: 420, position: "relative" },
  },
};

export const Default = {
  args: {
    children: <PageImage label="1" style={{ width: 180 }} />,
  },
};

export const ContentScrolled = {
  args: {
    children: [1, 2, 3, 4, 5, 6].map((n) => (
      <PageImage key={n} label={String(n)} style={{ width: 180, marginBottom: "var(--space-4)" }} />
    )),
  },
};

export const LongTitle = {
  args: {
    title: "11. August 2026, 20:14 Uhr",
    style: { width: 320, height: 420, position: "relative" },
    children: <PageImage label="1" style={{ width: 180 }} />,
  },
};
