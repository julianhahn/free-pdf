import React from "react";

/* "Page 3 of 12" over a moving picture. Tabular figures so it does not shuffle
   while it counts, and a solid ground behind it because a hairline caption
   disappears on a viewfinder. */
export function PageCounter({ children, onDark = false, style, ...rest }) {
  const counterStyle = {
    display: "inline-block",
    font: `var(--weight-heading) var(--text-control)/1.2 var(--font-heading)`,
    letterSpacing: "var(--tracking-heading)",
    fontVariantNumeric: "tabular-nums",
    padding: "var(--space-1) var(--space-2)",
    borderRadius: "var(--radius-sm)",
    color: onDark ? "var(--neutral-100)" : "var(--text)",
    background: onDark ? "rgba(19,18,17,.66)" : "var(--surface)",
    border: `1px solid ${onDark ? "rgba(248,244,244,.22)" : "var(--divider)"}`,
    backdropFilter: onDark ? "blur(6px)" : "none",
    ...style,
  };
  return <span style={counterStyle} {...rest}>{children}</span>;
}
