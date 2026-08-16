import * as React from "react";
/**
 * Drag handles over a page — four corners for Edges, eight grips for Crop.
 * @startingPoint section="Document" subtitle="Handles resting, held and refused" viewport="700x260"
 */
export interface PageHandlesProps {
  /** Photo or scanned page, passed straight to PageImage. */
  src?: string;
  /** Grey mode, as the pages screen switch sets it. */
  grey?: boolean;
  /** Four corners (Edges) or eight grips (Crop). */
  count?: 4 | 8;
  /** Distance of the frame from the page border, in percent. */
  inset?: number;
  /** The crop is outside the page: destructive edge, ring and sentence. */
  refused?: boolean;
  /** The sentence under the picture when refused. */
  refusedText?: string;
  /**
   * Index of the grip being dragged — it grows 11 to 13px, no colour change, and
   * the magnifier appears beside it with a crosshair on the grip. Not drawn while
   * `refused`.
   */
  held?: number;
  style?: React.CSSProperties;
}
/**
 * Drag handles over a page — four corners for Edges, eight grips for Crop.
 */
export declare function PageHandles(props: PageHandlesProps): JSX.Element;
