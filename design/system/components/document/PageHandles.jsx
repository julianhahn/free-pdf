import React from "react";
import { PageImage } from "./PageImage.jsx";

/* Drag handles over a page: four for Edges, eight for Crop. PageImage stays
   untouched underneath, this only draws the edge and the grips on top.
   Each grip is 11px of paint centred in a 44pt (--touch-min) target, on a
   2px paper ring so it survives a dark page.
   refused -> edge and grips go destructive and the edge gains the inset ring,
   the destructive double rule, plus a sentence under the picture. Colour is
   never the only signal. */
const SPOTS = [
  { x: 0, y: 0, name: "Top left corner" },
  { x: 1, y: 0, name: "Top right corner" },
  { x: 1, y: 1, name: "Bottom right corner" },
  { x: 0, y: 1, name: "Bottom left corner" },
  { x: 0.5, y: 0, name: "Top edge" },
  { x: 1, y: 0.5, name: "Right edge" },
  { x: 0.5, y: 1, name: "Bottom edge" },
  { x: 0, y: 0.5, name: "Left edge" },
];

export function PageHandles({
  src,
  grey = false,
  count = 4,
  inset = 8,
  refused = false,
  refusedText,
  held,
  style,
  ...rest
}) {
  const line = refused ? "var(--destructive)" : "var(--accent)";
  return (
    <div style={{ display: "grid", gap: "var(--space-2)", ...style }} {...rest}>
      <div style={{ position: "relative" }}>
        <PageImage src={src} grey={grey} />
        <div
          style={{
            position: "absolute",
            inset: `${inset}%`,
            border: `1px solid ${line}`,
            color: line,
            borderRadius: "var(--radius-sm)",
            boxShadow: refused ? "inset 0 0 0 3px var(--bg), inset 0 0 0 4px currentColor" : "none",
          }}
        >
          {SPOTS.slice(0, count).map((spot, i) => {
            const size = held === i ? 13 : 11;
            return (
              <button
                key={spot.name}
                type="button"
                aria-label={`${spot.name} of the sheet. Swipe up or down to move it.`}
                style={{
                  position: "absolute",
                  left: `${spot.x * 100}%`,
                  top: `${spot.y * 100}%`,
                  width: "var(--touch-min)",
                  height: "var(--touch-min)",
                  transform: "translate(-50%, -50%)",
                  display: "grid",
                  placeItems: "center",
                  padding: 0,
                  border: "none",
                  background: "transparent",
                  cursor: "grab",
                }}
              >
                <span
                  style={{
                    width: size,
                    height: size,
                    borderRadius: "var(--radius-round)",
                    background: line,
                    boxShadow: "0 0 0 2px var(--paper)",
                  }}
                />
              </button>
            );
          })}
        </div>
      </div>
      {refused ? (
        <span
          role="alert"
          style={{
            font: `var(--weight-body) var(--text-sub)/var(--leading-body) var(--font-body)`,
            color: "var(--destructive)",
          }}
        >
          {refusedText}
        </span>
      ) : null}
    </div>
  );
}
