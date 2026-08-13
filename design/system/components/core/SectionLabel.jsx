import React from "react";

/* h6: 13 px uppercase, 0.08em. The only all-caps in the system besides the kicker. */
export function SectionLabel({ children, style, ...rest }) {
  const sectionLabelStyle = {
    font: `var(--weight-heading) var(--text-h6)/var(--leading-heading) var(--font-heading)`,
    letterSpacing: "var(--tracking-h6)",
    textTransform: "uppercase",
    color: "var(--text-muted)",
    margin: 0,
    ...style,
  };
  return <div style={sectionLabelStyle} {...rest}>{children}</div>;
}
