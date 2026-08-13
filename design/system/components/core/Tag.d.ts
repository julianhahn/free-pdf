import * as React from "react";
export interface TagProps {
  children?: React.ReactNode;
  tone?: "neutral" | "accent" | "quiet";
  style?: React.CSSProperties;
}
/** Small chip at radius-sm — a page's state on a thumbnail. */
export declare function Tag(props: TagProps): JSX.Element;
