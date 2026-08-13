import React from "react";
import { Icon } from "../core/Icon.jsx";

/* The Page menu, presented the platform's way but drawn here: surface, radius-lg,
   hairline-separated rows. A destructive item carries its words, never a colour alone. */
export function MenuList({ title, items = [], onSelect, style, ...rest }) {
  return (
    <div
      role="menu"
      style={{
        background: "var(--surface)",
        border: "1px solid var(--divider)",
        borderRadius: "var(--radius-lg)",
        boxShadow: "var(--shadow-lg)",
        overflow: "hidden",
        minWidth: 232,
        ...style,
      }}
      {...rest}
    >
      {title ? (
        <div style={{ padding: "var(--space-2) var(--space-3)", borderBottom: "1px solid var(--divider)", font: `var(--weight-heading) var(--text-h6)/1.2 var(--font-heading)`, letterSpacing: "var(--tracking-h6)", textTransform: "uppercase", color: "var(--text-muted)" }}>{title}</div>
      ) : null}
      {items.map((item, i) => (
        <button
          key={item.label}
          type="button"
          role="menuitem"
          disabled={item.disabled}
          onClick={() => onSelect && onSelect(item)}
          style={{
            display: "flex",
            alignItems: "center",
            gap: "var(--space-2)",
            width: "100%",
            minHeight: "var(--touch-min)",
            padding: "var(--space-2) var(--space-3)",
            background: "transparent",
            border: "none",
            borderTop: i === 0 ? "none" : "1px solid var(--divider)",
            color: item.destructive ? "var(--destructive)" : "var(--text)",
            font: `var(--weight-body) var(--text-control)/1.3 var(--font-body)`,
            textAlign: "left",
            opacity: item.disabled ? "var(--disabled-opacity)" : 1,
            cursor: item.disabled ? "default" : "pointer",
          }}
        >
          {item.icon ? <Icon name={item.icon} size={17} color={item.destructive ? "var(--destructive)" : "var(--accent)"} /> : null}
          {item.label}
        </button>
      ))}
    </div>
  );
}
