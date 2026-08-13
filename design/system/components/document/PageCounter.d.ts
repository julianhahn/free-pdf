import * as React from "react";
export interface PageCounterProps {
  children?: React.ReactNode;
  /** True over a viewfinder or a dark preview. */
  onDark?: boolean;
  style?: React.CSSProperties;
}
/** "Page 3 of 12" in tabular figures on a solid ground. */
export declare function PageCounter(props: PageCounterProps): JSX.Element;
