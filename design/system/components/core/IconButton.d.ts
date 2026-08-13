import * as React from "react";
export interface IconButtonProps {
  /** Lucide icon name, e.g. "rotate-cw". */
  icon: string;
  /** Screen-reader label saying what it does, not what it looks like. */
  label: string;
  outlined?: boolean;
  disabled?: boolean;
  size?: number;
  onClick?: () => void;
  style?: React.CSSProperties;
}
/** 36 x 36 drawn, 44 pt tappable icon button. */
export declare function IconButton(props: IconButtonProps): JSX.Element;
