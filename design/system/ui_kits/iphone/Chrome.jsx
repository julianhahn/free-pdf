const { SectionLabel, IconButton, Icon } = window.FreePDFDesignSystem_43ff31;

const appBarStyle = {
  display: "flex",
  alignItems: "center",
  gap: "var(--space-2)",
  minHeight: 52,
  padding: "0 var(--screen-padding)",
  borderBottom: "1px solid var(--divider)",
};

function AppBar({ title, back, onBack, trailing }) {
  return (
    <div style={appBarStyle}>
      {back ? <IconButton icon="chevron-left" label="Back" onClick={onBack} style={{ marginLeft: -10 }} /> : null}
      <h1 style={{ margin: 0, flex: 1, font: "var(--weight-heading) var(--text-h4)/var(--leading-heading) var(--font-heading)", letterSpacing: "var(--tracking-heading)", fontVariantNumeric: "tabular-nums" }}>{title}</h1>
      {trailing}
    </div>
  );
}

function Screen({ children, footer }) {
  return (
    <div style={{ display: "grid", gridTemplateRows: "1fr auto", minHeight: 0, height: "100%" }}>
      <div style={{ overflow: "auto", padding: "var(--screen-padding)", display: "grid", gap: "var(--space-4)", alignContent: "start" }}>{children}</div>
      {footer ? (
        <div style={{ padding: "var(--screen-padding)", borderTop: "1px solid var(--divider)", display: "grid", gap: "var(--space-2)" }}>{footer}</div>
      ) : null}
    </div>
  );
}

/* The status line: iPhone-shaped, but drawn in the app's own type — the app never
   inherits the platform's font, not even here. */
function StatusLine({ onDark = false }) {
  const c = onDark ? "rgba(248,244,244,.8)" : "var(--text-muted)";
  return (
    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "8px var(--screen-padding) 2px", font: "var(--weight-body) var(--text-meta)/1 var(--font-body)", fontVariantNumeric: "tabular-nums", color: c }}>
      <span>20:14</span>
      <span style={{ display: "flex", gap: 5, alignItems: "center" }}><Icon name="wifi" size={11} color={c} /><Icon name="battery-full" size={13} color={c} /></span>
    </div>
  );
}

Object.assign(window, { AppBar, Screen, StatusLine });
