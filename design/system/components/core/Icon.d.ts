import * as React from "react";
export interface IconProps {
  /** Lucide icon name (kebab-case), e.g. "chevron-right". */
  name: string;
  size?: number;
  /** Any CSS colour or var(); defaults to currentColor. */
  color?: string;
  style?: React.CSSProperties;
}
/** Lucide glyph recoloured via CSS mask. Intentional addition — see readme.md. */
export declare function Icon(props: IconProps): JSX.Element;
