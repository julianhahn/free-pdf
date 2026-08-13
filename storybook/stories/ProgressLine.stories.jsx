import { ProgressLine } from "../ds.js";

export default { title: "Feedback/ProgressLine", component: ProgressLine };

export const Drain = {
  args: {
    line: "Scanning page 4 of 12",
    note: "You can close the app. It carries on from here.",
    value: 4,
    max: 12,
  },
};

export const ApplyToAll = {
  args: { line: "Applying…", note: "Keep the app open.", value: 9, max: 40 },
};

export const WithoutABar = { args: { line: "Making the PDF…" } };
