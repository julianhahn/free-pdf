import * as React from "react";
/**
 * Adjust slider: hairline track, 17 px thumb, value in tabular figures.
 * @startingPoint section="Adjust" subtitle="Hairline slider with suggested tick" viewport="700x200"
 */
export interface SliderProps {
  label: string;
  value: number;
  min?: number;
  max?: number;
  step?: number;
  /** Printed after the value, e.g. "°" or "%". */
  unit?: string;
  minLabel?: string;
  maxLabel?: string;
  /** The engine's suggestion; drawn as a tick on the track. */
  suggested?: number;
  disabled?: boolean;
  onChange?: (next: number) => void;
  style?: React.CSSProperties;
}
/**
 * Adjust slider: hairline track, 17 px thumb, value in tabular figures.
 */
export declare function Slider(props: SliderProps): JSX.Element;
