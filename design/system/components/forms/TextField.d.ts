import * as React from "react";
export interface TextFieldProps {
  label?: string;
  value: string;
  placeholder?: string;
  onChange?: (next: string) => void;
  /** Trailing static text. The done screen sets none: the name field is the label and the placeholder only. */
  suffix?: React.ReactNode;
  /**
   * Takes focus when the field is created, and only then — a redraw never re-focuses, so
   * coming back from a sheet or another screen does not raise the keyboard again.
   */
  autoFocus?: boolean;
  disabled?: boolean;
  style?: React.CSSProperties;
}
/** The name field on the done screen. Outlined, min height 36. */
export declare function TextField(props: TextFieldProps): JSX.Element;
