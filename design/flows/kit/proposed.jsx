/* Four components proposed for the FreePDF system (round 2). Same tokens, no new visual rule.
   Namespace kept separate (FPNew) until they are merged into FreePDFDesignSystem. */
const DS = () => window.FreePDFDesignSystem_43ff31;

/* ── PageStrip ─────────────────────────────────────────────────────────────
   Why not an existing component: PageImage is one tile; nothing in the kit
   scrolls a rail of them or jumps to a number. 40 pages are not 40 swipes.
   props: pages [{n,state,src}], selected, onSelect, grey, jump ("closed"|"open"),
          jumpValue, onJumpChange, onJumpSubmit, total */
function PageStrip({ pages = [], selected, onSelect, grey, jump = "closed", jumpValue = "", onJumpChange, onJumpSubmit, total }) {
  const { PageImage, IconButton, Button } = DS();
  return (
    <div style={{ display: "grid", gridTemplateColumns: "minmax(0,1fr)", gap: "var(--space-2)" }}>
      <div style={{ display: "flex", gap: "var(--space-2)", alignItems: "center", minWidth: 0 }}>
        <div style={{ display: "flex", gap: "var(--space-2)", overflow: "auto", flex: 1, minWidth: 0, paddingBottom: 2, scrollbarWidth: "none" }} role="listbox" aria-label={`Pages, ${selected} of ${total} shown`}>
          {pages.map((p) => {
            const refused = p.state === "refused";
            /* A refused tile is too small for the refusal sentence: it is marked by the
               destructive double rule — a different shape — and said in its label. */
            return (
              <div
                key={p.n}
                aria-label={refused ? `Page ${p.n}, could not be scanned` : undefined}
                style={{ flex: "0 0 auto", borderRadius: "var(--radius-md)", boxShadow: refused ? "0 0 0 1px var(--destructive), inset 0 0 0 3px var(--paper), inset 0 0 0 4px var(--destructive)" : "none" }}
              >
                <PageImage
                  label={String(p.n)}
                  grey={grey}
                  src={p.src}
                  selected={p.n === selected}
                  onClick={() => onSelect && onSelect(p.n)}
                  style={{ width: 40 }}
                />
              </div>
            );
          })}
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: "var(--space-2)", paddingLeft: "var(--space-2)", borderLeft: "1px solid var(--divider)", alignSelf: "stretch" }}>
          {/* A button is its words: no glyph here — the system keeps icons out of text buttons. */}
          <Button variant="secondary" aria-label={`Go to a page number. Page ${selected} of ${total} shown`} style={{ whiteSpace: "nowrap" }}>Go to page</Button>
        </div>
      </div>
      {jump === "open" ? (
        <div style={{ display: "flex", gap: "var(--space-2)", alignItems: "flex-end" }}>
          <div style={{ flex: 1, minWidth: 0 }}>
            <label style={{ display: "grid", gap: "var(--space-1)" }}>
              <span style={{ font: "var(--weight-body) var(--text-sub)/1.3 var(--font-body)", color: "var(--text-muted)" }}>Go to page</span>
              <input
                value={jumpValue}
                onChange={(e) => onJumpChange && onJumpChange(e.target.value)}
                inputMode="numeric"
                aria-label={`Page number, 1 to ${total}`}
                style={{ width: "100%", minHeight: "var(--input-min-h)", padding: "0 var(--space-2)", background: "transparent", color: "var(--text)", border: "1px solid var(--divider-strong)", borderRadius: "var(--radius-md)", font: "var(--weight-body) var(--text-control)/1 var(--font-body)", fontVariantNumeric: "tabular-nums" }}
              />
            </label>
          </div>
          <Button variant="secondary" onClick={() => onJumpSubmit && onJumpSubmit(jumpValue)}>Go</Button>
        </div>
      ) : null}
    </div>
  );
}

/* ── ToolStrip ─────────────────────────────────────────────────────────────
   Why not an existing component: Tag is a state chip and cannot be selected;
   MenuList is a menu that opens and closes. Adjust needs six persistent,
   selectable tools in one row, 44 pt each.
   props: items [{label,icon}], active (label), onSelect */
function ToolStrip({ items = [], active, onSelect }) {
  const { Icon } = DS();
  return (
    <div role="tablist" aria-label="Adjustment tools" style={{ display: "flex", gap: "var(--space-2)", overflow: "auto", scrollbarWidth: "none", borderTop: "1px solid var(--divider)", borderBottom: "1px solid var(--divider)" }}>
      {items.map((it) => {
        const on = it.label === active;
        return (
          <button
            key={it.label}
            role="tab"
            aria-selected={on}
            aria-label={`${it.label}${on ? ", shown" : ""}`}
            onClick={() => onSelect && onSelect(it.label)}
            style={{
              flex: "0 0 auto", minHeight: "var(--touch-min)", padding: "0 var(--space-2)",
              display: "flex", alignItems: "center", gap: "var(--space-1)",
              background: "transparent", border: 0, cursor: "pointer",
              borderBottom: on ? "2px solid var(--accent)" : "2px solid transparent",
              color: on ? "var(--accent)" : "var(--text-muted)",
              font: "var(--weight-body) var(--text-control)/1 var(--font-body)",
            }}
          >
            <Icon name={it.icon} size={17} color={on ? "var(--accent)" : "var(--text-muted)"} />
            {it.label}
          </button>
        );
      })}
    </div>
  );
}

/* ── PageHandles ───────────────────────────────────────────────────────────
   Why not an existing component: Edges and Crop both drag corners over a page.
   Drawn once here, with the refusal state Crop needs, instead of twice on two screens.
   props: count (4|8), inset (%), refused, refusedText, grey, src, label */
function PageHandles({ count = 4, inset = 8, refused = false, refusedText, grey, src, style }) {
  const { PageImage } = DS();
  const edge = refused ? "var(--destructive)" : "var(--accent)";
  const pts = [];
  const a = inset, b = 100 - inset;
  pts.push([a, a], [b, a], [b, b], [a, b]);
  if (count === 8) pts.push([(a + b) / 2, a], [b, (a + b) / 2], [(a + b) / 2, b], [a, (a + b) / 2]);
  return (
    <div style={{ display: "grid", gap: "var(--space-2)", ...style }}>
      <div style={{ position: "relative" }}>
        <PageImage src={src} grey={grey} style={{ width: "100%" }} />
        <div style={{ position: "absolute", inset: 0 }} aria-hidden="true">
          <div style={{ position: "absolute", left: `${a}%`, top: `${a}%`, right: `${a}%`, bottom: `${a}%`, border: `1px solid ${edge}`, boxShadow: refused ? `inset 0 0 0 3px color-mix(in srgb, ${edge} 40%, transparent)` : "none" }} />
          {pts.map(([x, y], i) => (
            <div key={i} style={{ position: "absolute", left: `${x}%`, top: `${y}%`, width: 44, height: 44, marginLeft: -22, marginTop: -22, display: "grid", placeItems: "center" }}>
              <div style={{ width: 11, height: 11, background: edge, borderRadius: "var(--radius-sm)", boxShadow: "0 0 0 2px var(--paper)" }} />
            </div>
          ))}
        </div>
      </div>
      {refused && refusedText ? (
        <p style={{ margin: 0, font: "var(--weight-body) var(--text-sub)/var(--leading-body) var(--font-body)", color: "var(--destructive)" }}>{refusedText}</p>
      ) : null}
    </div>
  );
}

/* ── Sheet ─────────────────────────────────────────────────────────────────
   Why not an existing component: ConfirmDialog is the only raised surface and it
   is a dialog — a title, a body and two actions. The PDF reader needs a raised
   surface that is only a close control and content.
   props: title, onClose, children, closeLabel */
function Sheet({ title, onClose, children, closeLabel = "Close the PDF" }) {
  const { IconButton } = DS();
  return (
    <div role="dialog" aria-label={title} style={{ background: "var(--surface)", borderRadius: "var(--radius-lg)", boxShadow: "var(--shadow-lg)", display: "grid", gridTemplateRows: "auto 1fr", minHeight: 0, overflow: "hidden" }}>
      <div style={{ display: "flex", alignItems: "center", gap: "var(--space-2)", padding: "var(--space-2) var(--space-4)", borderBottom: "1px solid var(--divider)" }}>
        <span style={{ flex: 1, font: "var(--weight-heading) var(--text-h4)/var(--leading-heading) var(--font-heading)", letterSpacing: "var(--tracking-heading)" }}>{title}</span>
        <IconButton icon="x" label={closeLabel} onClick={onClose} />
      </div>
      <div style={{ padding: "var(--space-4)", overflow: "auto", minHeight: 0 }}>{children}</div>
    </div>
  );
}

window.FPNew = { PageStrip, ToolStrip, PageHandles, Sheet };
