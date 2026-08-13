import * as React from "react";
/**
 * The camera shutter: 72 px accent ring around a solid paper disc.
 * @startingPoint section="Camera" subtitle="72 px shutter, rest and writing states" viewport="700x200"
 */
export interface ShutterProps {
  /** Disabled while the photo is being written — one press, one page. */
  disabled?: boolean;
  onPress?: () => void;
  /** VoiceOver label, e.g. "Photograph page 7" — while writing, "Photographing page 7, wait". */
  label?: string;
  style?: React.CSSProperties;
}
/**
 * The camera shutter: 72 px accent ring around a solid paper disc.
 */
export declare function Shutter(props: ShutterProps): JSX.Element;
