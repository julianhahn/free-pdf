import { PageImage } from "../ds.js";

export default {
  title: "Document/PageImage",
  component: PageImage,
  args: { style: { width: 180 } },
};

export const Placeholder = { args: { alt: "Page 3" } };
export const Grey = { args: { alt: "Page 3", grey: true } };
export const WithLabel = { args: { alt: "Page 7", label: "7" } };
export const Selected = { args: { alt: "Page 7", label: "7", selected: true } };
export const Refused = {
  args: { state: "refused", refusedText: "This page could not be scanned." },
};
