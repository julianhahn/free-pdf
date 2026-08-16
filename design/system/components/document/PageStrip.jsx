import React from "react";
import { PageImage } from "./PageImage.jsx";
import { Button } from "../core/Button.jsx";
import { TextField } from "../forms/TextField.jsx";

/* The thumbnail rail with a jump to a page number: 40 pages are not 40 swipes.
   It sits on top of PageImage - every tile is a PageImage, nothing about the
   page frame is redrawn here. The jump control lives in the same row, behind a
   hairline, so the rail keeps the whole width when it is closed. */

/* From ten pages up the rail carries the jump. Julian's number, decided on
   2026-08-16 because "Go to page" on a one page scan has nowhere to go - it is
   not measured off anything. */
const JUMP_FROM = 10;

export function PageStrip({
  pages = [],
  selected,
  onSelect,
  total,
  grey = false,
  jump = "closed",
  jumpValue = "",
  onJumpToggle,
  onJumpChange,
  onJumpSubmit,
  style,
  ...rest
}) {
  const railRef = React.useRef(null);
  React.useEffect(() => {
    const rail = railRef.current;
    const tile = rail?.querySelector(`[data-page="${selected}"]`);
    /* Scroll the rail itself, not the screen: scrollIntoView would drag the
       page above it out of view as well. */
    if (rail && tile) rail.scrollLeft = tile.offsetLeft - (rail.clientWidth - tile.offsetWidth) / 2;
  }, [selected]);

  /* Below ten pages the rail is the rail and nothing else: no button, and no
     field either, so a parent still holding jump="open" cannot bring it back. */
  const jumpable = total >= JUMP_FROM;
  const open = jumpable && jump === "open";

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "var(--space-2)", minWidth: 0, ...style }} {...rest}>
      <div style={{ display: "flex", alignItems: "center" }}>
        <div
          ref={railRef}
          role="group"
          aria-label={`Pages, ${selected} of ${total} shown`}
          style={{
            display: "flex",
            gap: "var(--space-2)",
            padding: "var(--space-2)",
            overflowX: "auto",
            flex: 1,
            /* Without this the 40 tiles set the row's intrinsic width, the rail
               never scrolls, and the whole screen widens to fit it. */
            minWidth: 0,
          }}
        >
          {pages.map((p) => (
            <PageImage
              key={p.n}
              data-page={p.n}
              src={p.src}
              state={p.state}
              grey={grey}
              label={String(p.n)}
              selected={p.n === selected}
              onClick={onSelect ? () => onSelect(p.n) : undefined}
              aria-label={
                p.state === "refused"
                  ? `Page ${p.n}, could not be scanned`
                  : `Page ${p.n}, shown`
              }
              style={{ width: 40, flex: "none" }}
            />
          ))}
        </div>
        {jumpable ? (
          <div style={{ borderLeft: "1px solid var(--divider)", padding: "var(--space-2)" }}>
            <Button
              variant="secondary"
              aria-label={`Go to page. Go to a page number. Page ${selected} of ${total} shown`}
              onClick={onJumpToggle}
            >
              Go to page
            </Button>
          </div>
        ) : null}
      </div>
      {open ? (
        <div style={{ display: "flex", alignItems: "center", gap: "var(--space-2)", padding: "0 var(--space-2)" }}>
          <TextField
            value={jumpValue}
            onChange={onJumpChange}
            inputMode="numeric"
            aria-label={`Page number, 1 to ${total}`}
            style={{ flex: 1 }}
          />
          <Button
            variant="secondary"
            aria-label={`Go to page ${jumpValue}`}
            onClick={() => onJumpSubmit?.(jumpValue)}
          >
            Go
          </Button>
        </div>
      ) : null}
    </div>
  );
}
