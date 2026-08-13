import React from "react";

/* Small chip, radius-sm. Carries a page's state on a thumbnail, never a decoration. */
export function Tag({ children, tone = "neutral", style, ...rest }) {
  const toneStyle =
    tone === "accent"
      ? { color: "var(--accent-700)", borderColor: "var(--accent)", background: "var(--accent-100)" }
      : tone === "quiet"
      ? { color: "var(--text-muted)", borderColor: "var(--divider)", background: "transparent" }
      : { color: "var(--text)", borderColor: "var(--divider)", background: "var(--surface)" };
  const tagStyle = {
    display: "inline-block",
    font: `var(--weight-body) var(--text-meta)/1.4 var(--font-body)`,
    fontVariantNumeric: "tabular-nums",
    padding: "1px var(--space-1)",
    border: "1px solid",
    borderRadius: "var(--radius-sm)",
    ...toneStyle,
    ...style,
  };
  return <span style={tagStyle} {...rest}>{children}</span>;
}
