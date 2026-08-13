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
    width: 26,
    height: 26,
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
          <span style={corner({ top: "6%", left: "6%", borderTopWidth: 2, borderLeftWidth: 2 })} />
          <span style={corner({ top: "6%", right: "6%", borderTopWidth: 2, borderRightWidth: 2 })} />
          <span style={corner({ bottom: "6%", left: "6%", borderBottomWidth: 2, borderLeftWidth: 2 })} />
          <span style={corner({ bottom: "6%", right: "6%", borderBottomWidth: 2, borderRightWidth: 2 })} />
        </>
      ) : null}
      {note ? (
        <span style={{ position: "absolute", left: "var(--space-3)", right: "var(--space-3)", bottom: "var(--space-3)", font: `var(--weight-body) var(--text-meta)/1.45 var(--font-body)`, color: "rgba(248,244,244,.72)" }}>{note}</span>
      ) : null}
    </div>
  );
}
