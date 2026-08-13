import React from "react";
import { Icon } from "../core/Icon.jsx";

/* Icon, title, body. Shown when there are no scan folders. Centred, quiet, and the
   icon is a stack of sheets — the app's own subject rather than a mascot. */
export function EmptyState({ icon = "files", title, body, action, style, ...rest }) {
  return (
    <div style={{ display: "grid", justifyItems: "center", gap: "var(--space-3)", textAlign: "center", padding: "var(--space-8) var(--space-4)", ...style }} {...rest}>
      <Icon name={icon} size={30} color="var(--accent)" />
      <h2 style={{ margin: 0, font: `var(--weight-heading) var(--text-h4)/var(--leading-heading) var(--font-heading)`, letterSpacing: "var(--tracking-heading)" }}>{title}</h2>
      <p style={{ margin: 0, maxWidth: 30 * 8, font: `var(--weight-body) var(--text-body)/var(--leading-body) var(--font-body)`, color: "var(--text-muted)", textWrap: "pretty" }}>{body}</p>
      {action}
    </div>
  );
}
