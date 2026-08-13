import { ErrorLine } from "../ds.js";

export default { title: "Feedback/ErrorLine", component: ErrorLine };

export const PageNotSaved = {
  args: { children: "Page 7 was not saved: the disk is full. Nothing already photographed is lost." },
};
export const CameraFailed = { args: { children: "The camera could not be started." } };
