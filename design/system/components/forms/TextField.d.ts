import * as React from "react";
export interface TextFieldProps {
  label?: string;
  value: string;
  placeholder?: string;
  onChange?: (next: string) => void;
  /** Trailing static text, e.g. ".pdf". */
  suffix?: React.ReactNode;
  disabled?: boolean;
  style?: React.CSSProperties;
}
/** The name field on the done screen. Outlined, min height 36. */
export declare function TextField(props: TextFieldProps): JSX.Element;
