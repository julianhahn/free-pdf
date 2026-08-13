import { Button, EmptyState } from "../ds.js";

export default { title: "Feedback/EmptyState", component: EmptyState };

export const NoScansYet = {
  args: {
    title: "No scans yet",
    body: "Tap New scan and photograph the pages, one after another. You can stop whenever you like.",
    action: <Button variant="primary">New scan</Button>,
  },
};

export const WithoutAction = { args: { ...NoScansYet.args, action: undefined } };
export const OtherIcon = { args: { ...NoScansYet.args, icon: "file-x" } };
