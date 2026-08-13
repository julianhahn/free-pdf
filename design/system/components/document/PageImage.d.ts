import * as React from "react";
/**
 * A scanned page in its paper frame — the system's recurring shape.
 * @startingPoint section="Pages" subtitle="Page frame, placeholder and refused" viewport="700x260"
 */
export interface PageImageProps {
  /** Photo or scanned page. Omitted -> ruled placeholder. */
  src?: string;
  alt?: string;
  state?: "page" | "refused";
  /** Grey mode, as the pages screen switch sets it. */
  grey?: boolean;
  /** Corner caption, e.g. "7". Also the button label when onClick is set. */
  label?: string;
  refusedText?: string;
  selected?: boolean;
  onClick?: () => void;
  style?: React.CSSProperties;
}
/**
 * A scanned page in its paper frame — the system's recurring shape.
 */
export declare function PageImage(props: PageImageProps): JSX.Element;
