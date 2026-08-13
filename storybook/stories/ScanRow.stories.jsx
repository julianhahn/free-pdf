import { ScanRow } from "../ds.js";

const TITLE = "11 Aug 2026, 20:14";

export default { title: "Lists/ScanRow", component: ScanRow, args: { title: TITLE } };

// The seven derived subtitles from copy.md — all of them required.
export const Empty = { args: { subtitle: "No pages yet" } };
export const Shooting = { args: { subtitle: "8 pages — keep shooting" } };
export const ShootingOne = { args: { subtitle: "1 page — keep shooting" } };
export const Scanning = { args: { subtitle: "12 of 40 pages scanned" } };
export const Ready = { args: { subtitle: "40 pages — ready to check" } };
export const Done = { args: { subtitle: "40 pages — PDF ready" } };
export const DonePhotosDeleted = { args: { subtitle: "40 pages — PDF ready, photos deleted" } };

export const WithThumb = { args: { subtitle: "40 pages — PDF ready", thumb: true } };
export const Swiped = { args: { subtitle: "40 pages — PDF ready", swiped: true, deleteLabel: "Delete" } };
export const Pressed = { args: { subtitle: "40 pages — PDF ready", pressed: true } };
