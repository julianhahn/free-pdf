import { Viewfinder } from "../ds.js";

export default { title: "Document/Viewfinder", component: Viewfinder, args: { style: { width: 320 } } };

export const Empty = {};
export const WithNote = {
  args: { note: "No camera on this iPhone. The shutter draws a page instead." },
};
export const WithoutCorners = { args: { corners: false } };
