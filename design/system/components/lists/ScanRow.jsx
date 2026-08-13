import React from "react";
import { Icon } from "../core/Icon.jsx";
import { PageImage } from "../document/PageImage.jsx";

/* One scan in the list. A whole-row button: date title, derived subtitle, accent
   chevron, hairline underneath. No fill, no card. Swiped left it reveals a 96 px
   Delete action in destructive colour.
   `thumb` is an intentional addition (readme.md): the first page, 30 px wide, so the
   list is not a wall of dates. Pass thumb={false} for the plain row. */
export function ScanRow({
  title,
  subtitle,
  thumb = true,
  thumbSrc,
  swiped = false,
  deleteLabel = "Delete",
  onPress,
  onDelete,
  style,
  ...rest
}) {
  const [pressed, setPressed] = React.useState(false);
  return (
    <div style={{ position: "relative", overflow: "hidden", borderBottom: "1px solid var(--divider)", ...style }} {...rest}>
      <button
        type="button"
        onClick={onDelete}
        style={{
          position: "absolute",
          top: 0,
          right: 0,
          bottom: 0,
          width: "var(--swipe-action-w)",
          background: "transparent",
          border: "none",
          borderLeft: "1px solid var(--destructive)",
          color: "var(--destructive)",
          font: `var(--weight-heading) var(--text-control)/1.2 var(--font-heading)`,
          letterSpacing: "var(--tracking-heading)",
          cursor: "pointer",
        }}
      >
        {deleteLabel}
      </button>
      <button
        type="button"
        onClick={onPress}
        onPointerDown={() => setPressed(true)}
        onPointerUp={() => setPressed(false)}
        onPointerLeave={() => setPressed(false)}
        style={{
          position: "relative",
          display: "flex",
          alignItems: "center",
          gap: "var(--space-3)",
          width: "100%",
          minHeight: "var(--touch-min)",
          padding: "var(--space-3) 0",
          background: pressed ? "var(--press-row)" : "var(--bg)",
          border: "none",
          textAlign: "left",
          cursor: "pointer",
          transform: swiped ? "translateX(calc(-1 * var(--swipe-action-w)))" : "none",
          transition: "transform 180ms ease-out, background 120ms linear",
        }}
      >
        {thumb ? <PageImage src={thumbSrc} style={{ width: 30, flex: "0 0 auto" }} /> : null}
        <span style={{ flex: 1, minWidth: 0 }}>
          <span style={{ display: "block", font: `var(--weight-heading) var(--text-row-title)/var(--leading-heading) var(--font-heading)`, letterSpacing: "var(--tracking-heading)", fontVariantNumeric: "tabular-nums" }}>{title}</span>
          <span style={{ display: "block", font: `var(--weight-body) var(--text-sub)/var(--leading-body) var(--font-body)`, color: "var(--text-muted)", fontVariantNumeric: "tabular-nums" }}>{subtitle}</span>
        </span>
        <Icon name="chevron-right" size={18} color="var(--accent)" />
      </button>
    </div>
  );
}
