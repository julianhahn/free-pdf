import React from "react";
import { PageImage } from "./PageImage.jsx";

/* Drag handles over a page: four for Edges, eight for Crop. PageImage stays
   untouched underneath, this only draws the edge and the grips on top.
   Each grip is 11px of paint centred in a 44pt (--touch-min) target, on a
   2px paper ring so it survives a dark page.
   refused -> edge and grips go destructive and the edge gains the inset ring,
   the destructive double rule, plus a sentence under the picture. Colour is
   never the only signal.
   held -> the grip grows, every other grip stops being painted, and the
   magnifier docks on the far side of the picture from the finger: the same
   picture drawn again and blown up around the grip. A single accent rule - the
   crosshair's own horizontal arm, made long - runs level from under the
   fingertip into the disc, so the circle reads as "this spot", the way a
   leader line works in a printed diagram. A handle is under the fingertip that
   drags it and the user cannot see what he is aiming at; it is aimed with the
   crosshair, not with the finger. Never drawn when the handles are refused,
   and a screen reader never announces it - the grip's own name is how it is
   moved without sight.
   Julian's decision, 2026-08-16, after using it on the phone: the loupe was
   too close to the thumb and the screen felt crowded. */
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

/* The disc is inset one --space-2 from the picture edge, so it clears the
   picture's rounded corner, and its centre is therefore that plus its radius. */
const PAD_R = "calc(var(--space-2) + var(--magnifier) / 2)";
const PAD_CROSS = "calc(var(--space-2) + var(--magnifier-cross))";

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
  /* The dock is a place, not a distance: the far edge of the picture from the
     hand, at the finger's own height. Dock right when the finger is left of the
     middle, left otherwise - so Crop's "Top edge" and "Bottom edge", which sit
     at exactly 50%, dock left every time rather than flickering. The swap at the
     middle is hard: the kit has no motion tokens and a duration would be an
     invented value. Because the leader always runs finger-to-disc-centre, the
     swap flips one line instead of exchanging two marks, and at the crossing
     point the run is the same length on either side. */
  const farRight = at ? at.x < 50 : false;
  const cx = farRight ? `calc(100% - ${PAD_R})` : PAD_R;
  /* cy is the disc, clamped so the circle never leaves the picture. ay is where
     the magnified point - and so the crosshair and the leader - sit; its band is
     far looser, so ay is the fingertip's own height for every inset the app
     uses. The loose clamp exists only so a degenerate inset of 0 cannot push the
     cross out of the disc. Dragging a corner into the very corner therefore
     slides the disc inward while the leader stays dead level and still lands on
     the cross - only the cross moves off the disc's geometric centre, which
     shows more of the sheet on the side the paper is actually on. */
  const cy = at && `clamp(${PAD_R}, ${at.y}%, calc(100% - ${PAD_R}))`;
  const ay = at && `clamp(${PAD_CROSS}, ${at.y}%, calc(100% - ${PAD_CROSS}))`;
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
          {SPOTS.slice(0, count).map((spot, i) => (
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
              {/* While a grip is held, only that grip is painted - three marks
                  fewer on Edges, seven fewer on Crop. The targets, the labels
                  and the hit testing are untouched: only the paint goes. */}
              {held != null && held !== i ? null : (
                <span
                  style={{
                    width: held === i ? 13 : 11,
                    height: held === i ? 13 : 11,
                    borderRadius: "var(--radius-round)",
                    background: line,
                    boxShadow: "0 0 0 2px var(--paper)",
                  }}
                />
              )}
            </button>
          ))}
        </div>
        {at ? (
          <>
            {/* The leader: one rule from under the fingertip to the disc's
                centre, the crosshair's horizontal arm made long. Both ends are
                named coordinates, so there is no length arithmetic and the
                swap at the middle is the same expression read the other way.
                The paper ring is the trick the grips already use, so an accent
                rule survives a dark photo - which is what Edges is for. Never
                destructive: a refused frame draws no loupe and so no leader.
                Ceiling: it stops under the rim rather than reaching the cross
                across the magnified picture. Drawing it across would cover the
                paper edge the loupe exists to show. */}
            <div
              aria-hidden="true"
              style={{
                position: "absolute",
                top: ay,
                left: farRight ? `${at.x}%` : cx,
                right: farRight ? `calc(100% - ${cx})` : `calc(100% - ${at.x}%)`,
                height: "var(--rule-strong)",
                transform: "translateY(-50%)",
                background: "var(--accent)",
                boxShadow: "0 0 0 var(--hairline-w) var(--paper)",
                pointerEvents: "none",
              }}
            />
            {/* The picture again, at its own size, scaled about the grip and
                then carried to the dock, cut to a round hole on the far side of
                the picture. Same drawing, so it can never disagree with what is
                underneath. The percentage translate resolves against this
                element's own box, which is inset: 0 - the same box the corner
                percentages use, so the two agree by construction. Drawn after
                the leader, so the magnified copy paints over its far end and the
                line visibly runs into the circle. */}
            <div
              aria-hidden="true"
              style={{
                position: "absolute",
                inset: 0,
                pointerEvents: "none",
                clipPath: `circle(calc(var(--magnifier) / 2) at ${cx} ${cy})`,
              }}
            >
              <div
                style={{
                  position: "absolute",
                  inset: 0,
                  transform: `translate(calc(${cx} - ${at.x}%), calc(${ay} - ${at.y}%)) scale(var(--magnifier-zoom))`,
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
            {/* The rim, on the disc's centre. */}
            <div
              aria-hidden="true"
              style={{
                position: "absolute",
                left: cx,
                top: cy,
                width: "var(--magnifier)",
                height: "var(--magnifier)",
                transform: "translate(-50%, -50%)",
                borderRadius: "var(--radius-round)",
                border: "var(--hairline-w) solid var(--divider)",
                pointerEvents: "none",
              }}
            />
            {/* The crosshair the corner is aimed with, on the magnified point -
                not on the disc's centre, which is why it rides ay and not cy. */}
            <div
              aria-hidden="true"
              style={{
                position: "absolute",
                left: cx,
                top: ay,
                transform: "translate(-50%, -50%)",
                display: "grid",
                placeItems: "center",
                pointerEvents: "none",
              }}
            >
              <span
                style={{
                  gridArea: "1 / 1",
                  width: "var(--magnifier-cross)",
                  height: "var(--rule-strong)",
                  background: line,
                }}
              />
              <span
                style={{
                  gridArea: "1 / 1",
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
