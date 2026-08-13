import { ToolStrip } from "../ds.js";

const tools = [
  { label: "Edges", icon: "scan" },
  { label: "Straighten", icon: "ruler" },
  { label: "Brightness", icon: "sun" },
  { label: "Sharpen", icon: "focus" },
  { label: "Crop", icon: "crop" },
  { label: "Turn", icon: "rotate-cw" },
];

export default {
  title: "Core/ToolStrip",
  component: ToolStrip,
  args: { items: tools },
};

export const Active = { args: { active: "Edges" } };
export const BrightnessActive = { args: { active: "Brightness" } };
export const Passive = { args: {} };
export const Pressed = { args: { active: "Edges", state: "pressed" } };
export const Focused = { args: { active: "Edges", state: "focus" } };
export const Scrolled = { args: { active: "Edges", style: { width: 240 } } };
