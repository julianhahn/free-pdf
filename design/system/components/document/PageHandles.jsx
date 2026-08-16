import React from "react";
import { PageImage } from "./PageImage.jsx";

/* Drag handles over a page: four for Edges, eight for Crop. PageImage stays
   untouched underneath, this only draws the edge and the grips on top.
   Each grip is 11px of paint centred in a 44pt (--touch-min) target, on a
   2px paper ring so it survives a dark page.
   refused -> edge and grips go destructive and the edge gains the inset ring,
   the destructive double rule, plus a sentence under the picture. Colour is
   never the only signal.
   held -> the grip grows, and beside it sits the magnifier: the same picture
   drawn again and blown up around the grip, with a crosshair on the grip
   itself, because a handle is under the fingertip that drags it and the user
   cannot see what he is aiming at. It is aimed with the crosshair, not with
   the finger. Never drawn when the handles are refused, and a screen reader
   never announces it - the grip's own name is how it is moved without sight.
   Julian's decision, 2026-08-16. */
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
  /* Where the held grip sits as a fraction of the whole picture, not of the
     frame: the magnifier is drawn over the picture, which is the thing being
     read. Nothing held, or the handles refused, means no magnifier at all. */
  const grip = !refused && held != null ? SPOTS[held] : null;
  const span = 100 - 2 * inset;
  const at = grip && { x: inset + grip.x * span, y: inset + grip.y * span };
  /* Above the finger, unless the grip is at the top of the picture and there is
     no room - then below it, which is the only other side a finger never covers. */
  const below = grip ? grip.y === 0 : false;
  const lift = below ? "var(--magnifier-lift)" : "calc(0px - var(--magnifier-lift))";
  const centre = at && `calc(${at.y}% ${below ? "+" : "-"} var(--magnifier-lift))`;
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
        {at ? (
          <>
            {/* The picture again, at its own size, scaled about the grip and
                shifted by the lift, then cut to a round hole beside the finger.
                Same drawing, so it can never disagree with what is underneath. */}
            <div
              aria-hidden="true"
              style={{
                position: "absolute",
                inset: 0,
                pointerEvents: "none",
                clipPath: `circle(calc(var(--magnifier) / 2) at ${at.x}% ${centre})`,
              }}
            >
              <div
                style={{
                  position: "absolute",
                  inset: 0,
                  transform: `translateY(${lift}) scale(var(--magnifier-zoom))`,
                  transformOrigin: `${at.x}% ${at.y}%`,
                }}
              >
                <PageImage
                  src={src}
                  grey={grey}
                  style={{ width: "100%", height: "100%", border: "none", boxShadow: "none", borderRadius: 0 }}
                />
              </div>
            </div>
            {/* The rim, and the crosshair the corner is aimed with. */}
            <div
              aria-hidden="true"
              style={{
                position: "absolute",
                left: `${at.x}%`,
                top: centre,
                width: "var(--magnifier)",
                height: "var(--magnifier)",
                transform: "translate(-50%, -50%)",
                borderRadius: "var(--radius-round)",
                border: "1px solid var(--divider)",
                display: "grid",
                placeItems: "center",
                pointerEvents: "none",
              }}
            >
              <span
                style={{
                  position: "absolute",
                  width: "var(--magnifier-cross)",
                  height: "var(--rule-strong)",
                  background: line,
                }}
              />
              <span
                style={{
                  position: "absolute",
                  width: "var(--rule-strong)",
                  height: "var(--magnifier-cross)",
                  background: line,
                }}
              />
            </div>
          </>
        ) : null}
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
