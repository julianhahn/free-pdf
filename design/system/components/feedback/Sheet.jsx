import React from "react";
import { IconButton } from "../core/IconButton.jsx";

/* The PDF reader's raised surface: the scan's date as the title, one close
   control, and content that scrolls under a hairline. It reuses the dialog's
   own values (surface, radius-lg, shadow-lg, the same scrim) so the system
   keeps one raised look. Nothing is pinned to a fixed header height, so a
   long German title can wrap to two lines. */
export function Sheet({ title, onClose, closeLabel, children, style, ...rest }) {
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        display: "grid",
        placeItems: "center",
        padding: "var(--space-4)",
        background: "color-mix(in srgb, var(--neutral-900) 38%, transparent)",
        ...style,
      }}
      {...rest}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-label={title}
        style={{
          display: "flex",
          flexDirection: "column",
          width: "100%",
          maxWidth: 320,
          maxHeight: "100%",
          background: "var(--surface)",
          border: "1px solid var(--divider)",
          borderRadius: "var(--radius-lg)",
          boxShadow: "var(--shadow-lg)",
          overflow: "hidden",
        }}
      >
        <div
          style={{
            display: "flex",
            alignItems: "flex-start",
            gap: "var(--space-2)",
            padding: "var(--space-2) var(--space-2) var(--space-2) var(--space-4)",
            borderBottom: "1px solid var(--divider)",
          }}
        >
          <h2
            style={{
              flex: 1,
              margin: 0,
              paddingTop: "var(--space-2)",
              font: `var(--weight-heading) var(--text-h4)/var(--leading-heading) var(--font-heading)`,
              letterSpacing: "var(--tracking-heading)",
              textWrap: "pretty",
            }}
          >
            {title}
          </h2>
          <IconButton icon="x" label={closeLabel} onClick={onClose} />
        </div>
        <div style={{ flex: 1, minHeight: 0, overflowY: "auto", padding: "var(--space-4)" }}>{children}</div>
      </div>
    </div>
  );
}
