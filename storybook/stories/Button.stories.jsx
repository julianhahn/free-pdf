import { Button } from "../ds.js";

export default { title: "Core/Button", component: Button };

export const Primary = { args: { variant: "primary", children: "Make PDF" } };
export const Secondary = { args: { variant: "secondary", children: "Cancel" } };
export const Destructive = { args: { variant: "destructive", children: "Delete the 40 photos (78 MB)" } };
export const Ghost = { args: { variant: "ghost", children: "Back to the suggestion" } };
export const FullWidth = { args: { variant: "primary", fullWidth: true, children: "Make PDF" } };
export const Disabled = { args: { variant: "primary", disabled: true, children: "Make PDF" } };
export const Busy = { args: { variant: "primary", busy: true, children: "Making the PDF…" } };
