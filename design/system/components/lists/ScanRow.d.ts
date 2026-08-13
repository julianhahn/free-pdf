import * as React from "react";
/**
 * One scan in the list: date, derived subtitle, accent chevron, hairline.
 * @startingPoint section="Scans" subtitle="Scan row with swipe-to-delete" viewport="700x220"
 */
export interface ScanRowProps {
  /** The folder date; there is no rename. e.g. "11 Aug 2026, 20:14". */
  title: string;
  /** One of the seven derived subtitles from components.md. */
  subtitle: string;
  /** Leading page thumbnail (intentional addition). */
  thumb?: boolean;
  thumbSrc?: string;
  /** Swiped left, revealing the 96 px Delete action. */
  swiped?: boolean;
  /** Held in the pressed treatment at rest, so the state can be shown in a story. */
  pressed?: boolean;
  deleteLabel?: string;
  onPress?: () => void;
  onDelete?: () => void;
  style?: React.CSSProperties;
}
/**
 * One scan in the list: date, derived subtitle, accent chevron, hairline.
 */
export declare function ScanRow(props: ScanRowProps): JSX.Element;
