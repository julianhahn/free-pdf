/* FreePDF presentation chrome for this handback.
   AppBar / Screen / StatusLine are the delivered iPhone kit's Chrome.jsx, unchanged.
   Phone / PhonePair are presentation only — they are not app UI and add no visual rule. */
const DS = () => window.FreePDFDesignSystem_43ff31;

const appBarStyle = {
  display: "flex",
  alignItems: "center",
  gap: "var(--space-2)",
  minHeight: 52,
  padding: "0 var(--screen-padding)",
  borderBottom: "1px solid var(--divider)",
};

function AppBar({ title, back, onBack, trailing, children }) {
  const { IconButton } = DS();
  trailing = trailing || children;
  return (
    <div style={appBarStyle}>
      {back ? <IconButton icon="chevron-left" label="Back to the scan" onClick={onBack} style={{ marginLeft: -10 }} /> : null}
      <h1 style={{ margin: 0, flex: 1, font: "var(--weight-heading) var(--text-h4)/var(--leading-heading) var(--font-heading)", letterSpacing: "var(--tracking-heading)", fontVariantNumeric: "tabular-nums" }}>{title}</h1>
      {trailing}
    </div>
  );
}

/* Children marked data-slot="footer" are pinned in the footer above a hairline;
   everything else scrolls. Lets a whole screen be written as markup. */
function Screen({ children, footer, pad = true, style }) {
  const all = React.Children.toArray(children);
  const slot = (name) => all.filter((c) => c && c.props && c.props["data-slot"] === name);
  const foot = footer || (slot("footer").length ? slot("footer") : null);
  children = all.filter((c) => !(c && c.props && c.props["data-slot"] === "footer"));
  footer = foot;
  return (
    <div style={{ display: "grid", gridTemplateRows: "1fr auto", minHeight: 0, height: "100%", ...style }}>
      <div style={{ overflow: "auto", padding: pad ? "var(--screen-padding)" : 0, display: "grid", gap: "var(--space-4)", alignContent: "start" }}>{children}</div>
      {footer ? (
        <div style={{ padding: "var(--screen-padding)", borderTop: "1px solid var(--divider)", display: "grid", gap: "var(--space-2)" }}>{footer}</div>
      ) : null}
    </div>
  );
}

function StatusLine({ onDark = false }) {
  const { Icon } = DS();
  const c = onDark ? "rgba(248,244,244,.8)" : "var(--text-muted)";
  return (
    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "8px var(--screen-padding) 2px", font: "var(--weight-body) var(--text-meta)/1 var(--font-body)", fontVariantNumeric: "tabular-nums", color: c }}>
      <span>20:14</span>
      <span style={{ display: "flex", gap: 5, alignItems: "center" }}><Icon name="wifi" size={11} color={c} /><Icon name="battery-full" size={13} color={c} /></span>
    </div>
  );
}

function Phone({ theme = "light", children, caption, onDarkStatus = false, w = 393, h = 852 }) {
  return (
    <div style={{ display: "grid", gap: "var(--space-2)", justifyItems: "start" }}>
      <div
        data-theme={theme}
        style={{
          width: w, height: h, borderRadius: 46, overflow: "hidden",
          background: "var(--bg)", color: "var(--text)",
          border: "1px solid var(--divider)", boxShadow: "var(--shadow-md)",
          display: "grid", gridTemplateRows: "auto 1fr", fontFamily: "var(--font-body)",
        }}
      >
        <StatusLine onDark={onDarkStatus} />
        <div style={{ minHeight: 0, position: "relative", display: "grid", gridTemplateRows: "auto 1fr" }}>{children}</div>
      </div>
      <div style={{ font: "var(--weight-body) var(--text-meta)/1.4 var(--font-body)", letterSpacing: "var(--tracking-kicker)", textTransform: "uppercase", color: "rgba(32,31,29,.5)" }}>
        {caption || (theme === "dark" ? "Dark" : "Light")}
      </div>
    </div>
  );
}

/* Renders the same screen markup twice, once per theme, so no layout is authored for one theme only. */
function PhonePair({ children, onDarkStatus = false, w, h }) {
  return (
    <div style={{ display: "flex", gap: "var(--space-6)", alignItems: "flex-start" }}>
      <Phone theme="light" onDarkStatus={onDarkStatus} w={w} h={h}>{children}</Phone>
      <Phone theme="dark" onDarkStatus={onDarkStatus} w={w} h={h}>{children}</Phone>
    </div>
  );
}

/* Scrim + centred overlay, for a dialog or a sheet drawn over a screen. */
function Overlay({ children, align = "center", justify = "stretch" }) {
  const a = align === "end" ? "end" : align === "start" ? "start" : "center";
  return (
    <div style={{ position: "absolute", inset: 0, background: "color-mix(in srgb, var(--neutral-900) 38%, transparent)", display: "grid", alignItems: a, alignContent: a, justifyItems: justify, padding: "var(--space-4)" }}>
      {children}
    </div>
  );
}

/* Same specimen markup rendered twice, light and dark, on the app's own grounds. */
function ThemePair({ children, w = 520 }) {
  const panel = (theme) => (
    <div data-theme={theme} style={{ width: w, background: "var(--bg)", color: "var(--text)", border: "1px solid var(--divider)", borderRadius: "var(--radius-md)", padding: "var(--space-4)", fontFamily: "var(--font-body)", display: "grid", gridTemplateColumns: "minmax(0,1fr)", gap: "var(--space-4)", alignContent: "start" }}>
      {children}
    </div>
  );
  return <div style={{ display: "flex", gap: "var(--space-6)", alignItems: "flex-start", flexWrap: "wrap" }}>{panel("light")}{panel("dark")}</div>;
}

/* Thin slot wrappers: these delivered components take a ReactNode as a prop, so a
   wrapper lets a screen be written entirely as markup. No visual change. */
function EmptyStateA({ icon, title, body, children }) {
  const { EmptyState } = DS();
  return <EmptyState icon={icon} title={title} body={body} action={children || null} />;
}

window.FPKit = { AppBar, Screen, StatusLine, Phone, PhonePair, Overlay, ThemePair, EmptyStateA };
