import React from "react";

/* A line, a bar, a note. Two of them exist: the drain, and apply-to-all.
   The bar is a 3 px rule that fills with accent — no radius, no gradient. */
export function ProgressLine({ line, note, value = 0, max = 100, style, ...rest }) {
  const pct = Math.max(0, Math.min(100, (value / max) * 100));
  return (
    <div style={style} {...rest}>
      <div style={{ font: `var(--weight-body) var(--text-sub)/var(--leading-body) var(--font-body)`, fontVariantNumeric: "tabular-nums" }}>{line}</div>
      <div
        role="progressbar"
        aria-valuenow={value}
        aria-valuemax={max}
        aria-label={typeof line === "string" ? line : undefined}
        style={{ height: 3, background: "var(--divider)", margin: "var(--space-1) 0" }}
      >
        <div style={{ width: `${pct}%`, height: "100%", background: "var(--accent)", transition: "width 240ms linear" }} />
      </div>
      {note ? <div style={{ font: `var(--weight-body) var(--text-meta)/1.45 var(--font-body)`, color: "var(--text-muted)" }}>{note}</div> : null}
    </div>
  );
}
