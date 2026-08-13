import * as React from "react";
/**
 * The adjust tools in one scrolling row — the active tool wears the accent glyph, label and underline.
 * @startingPoint section="Core" subtitle="Six adjust tools, one active" viewport="700x260"
 */
export interface ToolStripProps {
  /** The tools, in the order they are shown. */
  items?: { label: string; icon: string }[];
  /** Label of the tool that is shown right now. */
  active?: string;
  /** Called with the label of the tapped tool. */
  onSelect?: (label: string) => void;
  /** Draws the active tool pressed or focused at rest. */
  state?: "pressed" | "focus";
  style?: React.CSSProperties;
}
/**
 * The adjust tools in one scrolling row — the active tool wears the accent glyph, label and underline.
 */
export declare function ToolStrip(props: ToolStripProps): JSX.Element;
