import * as React from "react";
/**
 * The thumbnail rail with a jump to a page number — 40 pages are not 40 swipes.
 * @startingPoint section="Document" subtitle="Page rail, selected tile and the jump control" viewport="700x260"
 */
export interface PageStripProps {
  /** The pages in order; `state: "refused"` draws PageImage's refusal. */
  pages: { n: number; state?: "page" | "refused"; src?: string }[];
  /** The page number shown right now; its tile is kept in view. */
  selected: number;
  /** Called with the page number of a tapped tile. */
  onSelect?: (n: number) => void;
  /** How many pages the scan has. Under ten, the jump is not drawn at all. */
  total: number;
  /** Grey mode, as the pages screen switch sets it. */
  grey?: boolean;
  /** Whether the jump field is open. Default "closed". The parent owns it, and
   *  under ten pages it is ignored. */
  jump?: "closed" | "open";
  /** Called when "Go to page" is pressed; the parent flips `jump`. */
  onJumpToggle?: () => void;
  /** Text in the jump field. */
  jumpValue?: string;
  /** Called on every keystroke in the jump field. */
  onJumpChange?: (v: string) => void;
  /** Called when Go is pressed. */
  onJumpSubmit?: (v: string) => void;
  style?: React.CSSProperties;
}
/**
 * The thumbnail rail with a jump to a page number — 40 pages are not 40 swipes.
 */
export declare function PageStrip(props: PageStripProps): JSX.Element;
