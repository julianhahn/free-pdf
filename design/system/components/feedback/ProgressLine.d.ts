import * as React from "react";
export interface ProgressLineProps {
  /** e.g. "Scanning page 4 of 12". */
  line: React.ReactNode;
  /** The drain says the app may close; apply-to-all says keep it open. */
  note?: React.ReactNode;
  value?: number;
  max?: number;
  style?: React.CSSProperties;
}
/** A line, a 3 px bar, a note. */
export declare function ProgressLine(props: ProgressLineProps): JSX.Element;
