import * as React from "react";
/**
 * The PDF reader's raised surface — a close control, and content that scrolls under a hairline.
 * @startingPoint section="Feedback" subtitle="Reader sheet over a screen" viewport="700x260"
 */
export interface SheetProps {
  /** Title of the sheet, the scan's date, e.g. "11 Aug 2026, 20:14". */
  title: string;
  /** Called when the close control is pressed. */
  onClose?: () => void;
  /** Label of the close control. */
  closeLabel?: string;
  /** What the sheet shows, e.g. the page picture. */
  children?: React.ReactNode;
  style?: React.CSSProperties;
}
/**
 * The PDF reader's raised surface — a close control, and content that scrolls under a hairline.
 */
export declare function Sheet(props: SheetProps): JSX.Element;
