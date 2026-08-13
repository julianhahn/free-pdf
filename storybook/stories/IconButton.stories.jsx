import { IconButton } from "../ds.js";

export default { title: "Core/IconButton", component: IconButton };

export const Bare = { args: { icon: "rotate-cw", label: "Turn the page" } };
export const Outlined = { args: { icon: "crop", label: "Crop the page", outlined: true } };
export const Disabled = { args: { icon: "trash-2", label: "Delete page", outlined: true, disabled: true } };
