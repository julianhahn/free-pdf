import { ConfirmDialog } from "../ds.js";

export default { title: "Feedback/ConfirmDialog", component: ConfirmDialog, args: { cancelLabel: "Cancel" } };

export const DeleteScan = {
  args: {
    title: "Delete this scan?",
    body: "40 pages, the PDF and 40 photos go. This cannot be undone.",
    confirmLabel: "Delete scan",
  },
};

export const DeletePage = {
  args: {
    title: "Delete this page?",
    body: "The photo goes too. This cannot be undone.",
    confirmLabel: "Delete page",
  },
};

export const DeletePhotos = {
  args: {
    title: "Delete the 40 photos?",
    body: "The PDF stays. Without the photos the pages can no longer be adjusted.",
    confirmLabel: "Delete photos",
  },
};
