import React from "react";

/* One line, destructive colour, above the content, cleared on the next reload.
   The text is the engine's own finished sentence — the client never rewrites it.
   Marked by a rule to its left, because this theme never leans on colour alone. */
export function ErrorLine({ children, style, ...rest }) {
  return (
    <p
      role="status"
      style={{
        margin: 0,
        paddingLeft: "var(--space-2)",
        borderLeft: "2px solid var(--destructive)",
        color: "var(--destructive)",
        font: `var(--weight-body) var(--text-sub)/var(--leading-body) var(--font-body)`,
        fontVariantNumeric: "tabular-nums",
        textWrap: "pretty",
        ...style,
      }}
      {...rest}
    >
      {children}
    </p>
  );
}
