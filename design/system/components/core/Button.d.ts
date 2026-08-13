import * as React from "react";
/**
 * FreePDF button: outlined, serif label, 44 pt tappable.
 * @startingPoint section="Core" subtitle="Outlined buttons, four variants" viewport="700x200"
 */
export interface ButtonProps {
  /** Outlined variants. Never filled. */
  variant?: "primary" | "secondary" | "destructive" | "ghost";
  children?: React.ReactNode;
  /** True when it is the screen's action. */
  fullWidth?: boolean;
  disabled?: boolean;
  /** Running label state, e.g. "Making the PDF…". Blocks presses. */
  busy?: boolean;
  onClick?: () => void;
  style?: React.CSSProperties;
}
/**
 * FreePDF button: outlined, serif label, 44 pt tappable.
 */
export declare function Button(props: ButtonProps): JSX.Element;
