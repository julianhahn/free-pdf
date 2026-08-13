import * as React from "react";
/**
 * Outlined 42 x 24 switch row. Never the platform's switch, but flips like it.
 * @startingPoint section="Adjust" subtitle="Switch row, off and on" viewport="700x160"
 */
export interface SwitchProps {
  checked?: boolean;
  onChange?: (next: boolean) => void;
  /** Row label and screen-reader label: "Grey", "Apply to all pages". */
  label: string;
  sub?: string;
  disabled?: boolean;
  style?: React.CSSProperties;
}
/**
 * Outlined 42 x 24 switch row. Never the platform's switch, but flips like it.
 */
export declare function Switch(props: SwitchProps): JSX.Element;
