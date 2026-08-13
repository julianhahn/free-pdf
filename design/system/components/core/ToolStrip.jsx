import React from "react";
import { Icon } from "./Icon.jsx";

/* The adjust tools, one row. The active tool carries the accent: glyph, label
   and a 2 px underline, so it never reads by colour alone. Not tabs and not
   chips - VoiceOver says "Edges" and "Edges, shown", so these stay buttons.
   The row scrolls sideways; tools never wrap and never shrink.
   `state` draws the active tool pressed or focused at rest, as Button and
   IconButton do. */
export function ToolStrip({ items = [], active, onSelect, state, style, ...rest }) {
  const [pressed, setPressed] = React.useState(null);
  return (
    <div
      role="group"
      aria-label="Adjustment tools"
      style={{
        display: "flex",
        gap: "var(--space-2)",
        overflowX: "auto",
        borderTop: "1px solid var(--divider)",
        borderBottom: "1px solid var(--divider)",
        ...style,
      }}
      {...rest}
    >
      {items.map((item) => {
        const on = item.label === active;
        const isPressed = pressed === item.label || (on && state === "pressed");
        const colour = on ? "var(--accent)" : "var(--text-muted)";
        return (
          <button
            key={item.label}
            type="button"
            aria-label={on ? `${item.label}, shown` : item.label}
            onClick={() => onSelect && onSelect(item.label)}
            onPointerDown={() => setPressed(item.label)}
            onPointerUp={() => setPressed(null)}
            onPointerLeave={() => setPressed(null)}
            style={{
              flex: "0 0 auto",
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              gap: "var(--space-1)",
              minHeight: "var(--touch-min)",
              padding: "var(--space-2)",
              background: isPressed ? "var(--press-neutral)" : "transparent",
              border: "none",
              borderBottom: `2px solid ${on ? "var(--accent)" : "transparent"}`,
              color: colour,
              font: `var(--weight-body) var(--text-control)/1.2 var(--font-body)`,
              cursor: "pointer",
              outline: on && state === "focus" ? "2px solid var(--focus-ring)" : undefined,
              outlineOffset: 2,
            }}
          >
            <Icon name={item.icon} size={17} color={colour} />
            {item.label}
          </button>
        );
      })}
    </div>
  );
}
