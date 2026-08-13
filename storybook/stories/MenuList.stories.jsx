import { MenuList } from "../ds.js";

export default { title: "Lists/MenuList", component: MenuList };

export const PageMenu = {
  args: {
    title: "Page",
    items: [
      { label: "Retake this page", icon: "camera" },
      { label: "Adjust page", icon: "sun" },
      { label: "Delete page", icon: "trash-2", destructive: true },
    ],
  },
};

export const FinishedScan = {
  args: {
    title: "Page",
    items: [
      { label: "Shoot another page", icon: "camera" },
      { label: "Adjust page", icon: "sun", disabled: true },
      { label: "Delete page", icon: "trash-2", destructive: true },
    ],
  },
};
