import React from "react";
import { Button } from "../core/Button.jsx";

/* Surface, radius-lg, shadow-lg — the only raised thing in the system. Title (h4),
   body, then the actions right-aligned: destructive first, secondary Cancel.
   All three deletions ask, always. */
export function ConfirmDialog({
  title,
  body,
  confirmLabel,
  cancelLabel = "Cancel",
  onConfirm,
  onCancel,
  style,
  ...rest
}) {
  return (
    <div role="dialog" aria-modal="true" aria-label={title} style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", padding: "var(--space-4)", background: "color-mix(in srgb, var(--neutral-900) 38%, transparent)", ...style }} {...rest}>
      <div style={{ width: "100%", maxWidth: 320, background: "var(--surface)", border: "1px solid var(--divider)", borderRadius: "var(--radius-lg)", boxShadow: "var(--shadow-lg)", padding: "var(--space-4)" }}>
        <h2 style={{ margin: 0, font: `var(--weight-heading) var(--text-h4)/var(--leading-heading) var(--font-heading)`, letterSpacing: "var(--tracking-heading)" }}>{title}</h2>
        <p style={{ margin: "var(--space-2) 0 var(--space-4)", font: `var(--weight-body) var(--text-body)/var(--leading-body) var(--font-body)`, fontVariantNumeric: "tabular-nums", textWrap: "pretty" }}>{body}</p>
        <div style={{ display: "flex", justifyContent: "flex-end", gap: "var(--space-2)", flexWrap: "wrap" }}>
          <Button variant="destructive" onClick={onConfirm}>{confirmLabel}</Button>
          <Button variant="secondary" onClick={onCancel}>{cancelLabel}</Button>
        </div>
      </div>
    </div>
  );
}
