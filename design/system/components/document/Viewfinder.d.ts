import * as React from "react";
/**
 * 3:4 dark preview stage with accent corner marks.
 * @startingPoint section="Camera" subtitle="3:4 viewfinder with corner marks" viewport="700x400"
 */
export interface ViewfinderProps {
  /** The live preview, or a stand-in image. */
  children?: React.ReactNode;
  /** Quiet line inside the frame, e.g. the simulator note. */
  note?: string;
  corners?: boolean;
  style?: React.CSSProperties;
}
/**
 * 3:4 dark preview stage with accent corner marks.
 */
export declare function Viewfinder(props: ViewfinderProps): JSX.Element;
