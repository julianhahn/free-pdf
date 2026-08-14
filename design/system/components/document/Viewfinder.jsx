import React from "react";

/* The live preview, 3:4 portrait. The frame is four corner marks in accent, not a
   full hairline rectangle: on a dark moving picture a thin continuous line reads as
   part of the scene, corners read as an instrument. */
export function Viewfinder({ children, note, corners = true, style, ...rest }) {
  const stageStyle = {
    position: "relative",
    aspectRatio: "var(--page-ratio)",
    width: "100%",
    background: "var(--viewfinder)",
    borderRadius: "var(--radius-md)",
    overflow: "hidden",
    ...style,
  };
  const corner = (pos) => ({
    position: "absolute",
    width: "var(--viewfinder-corner)",
    height: "var(--viewfinder-corner)",
    borderColor: "var(--accent)",
    borderStyle: "solid",
    borderWidth: 0,
    ...pos,
  });
  return (
    <div style={stageStyle} {...rest}>
      {children}
      {corners ? (
        <>
          <span style={corner({ top: "calc(var(--viewfinder-corner-inset) * 100%)", left: "calc(var(--viewfinder-corner-inset) * 100%)", borderTopWidth: "var(--rule-strong)", borderLeftWidth: "var(--rule-strong)" })} />
          <span style={corner({ top: "calc(var(--viewfinder-corner-inset) * 100%)", right: "calc(var(--viewfinder-corner-inset) * 100%)", borderTopWidth: "var(--rule-strong)", borderRightWidth: "var(--rule-strong)" })} />
          <span style={corner({ bottom: "calc(var(--viewfinder-corner-inset) * 100%)", left: "calc(var(--viewfinder-corner-inset) * 100%)", borderBottomWidth: "var(--rule-strong)", borderLeftWidth: "var(--rule-strong)" })} />
          <span style={corner({ bottom: "calc(var(--viewfinder-corner-inset) * 100%)", right: "calc(var(--viewfinder-corner-inset) * 100%)", borderBottomWidth: "var(--rule-strong)", borderRightWidth: "var(--rule-strong)" })} />
        </>
      ) : null}
      {note ? (
        <span style={{ position: "absolute", left: "var(--space-3)", right: "var(--space-3)", bottom: "var(--space-3)", font: `var(--weight-body) var(--text-meta)/1.45 var(--font-body)`, color: "var(--on-dark-muted)" }}>{note}</span>
      ) : null}
    </div>
  );
}
