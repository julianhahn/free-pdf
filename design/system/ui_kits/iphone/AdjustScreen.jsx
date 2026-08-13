const { PageImage, Slider, Switch, Button, SectionLabel, IconButton, ErrorLine, ProgressLine } = window.FreePDFDesignSystem_43ff31;

const TOOLS = [
  { label: "Edges", icon: "scan" },
  { label: "Straighten", icon: "rotate-cw" },
  { label: "Brightness", icon: "sun" },
  { label: "Sharpen", icon: "wand-sparkles" },
  { label: "Crop", icon: "crop" },
  { label: "Turn", icon: "refresh-cw" },
];

function AdjustScreen({ page = 3, onDone, onBack }) {
  const [tool, setTool] = React.useState("Brightness");
  const [brightness, setBrightness] = React.useState(12);
  const [straighten, setStraighten] = React.useState(-2);
  const [grey, setGrey] = React.useState(false);
  const [all, setAll] = React.useState(false);
  const [running, setRunning] = React.useState(false);
  return (
    <>
      <AppBar title={`Adjust page ${page}`} back onBack={onBack} />
      <Screen
        footer={
          <>
            {running ? (
              <ProgressLine
                line={all ? "Applying to 40 pages…" : "Applying…"}
                note={all ? "Keep the app open." : null}
                value={all ? 14 : 60}
                max={all ? 40 : 100}
              />
            ) : null}
            <Button variant="primary" fullWidth busy={running} onClick={() => { setRunning(true); setTimeout(() => { setRunning(false); onDone(); }, 900); }}>
              {running ? (all ? "Applying to 40 pages…" : "Applying…") : "Apply"}
            </Button>
            <div style={{ display: "flex", gap: "var(--space-2)" }}>
              <Button variant="secondary" style={{ flex: 1 }} onClick={onBack}>Cancel</Button>
              <Button variant="ghost" style={{ flex: 1 }} onClick={() => { setBrightness(12); setStraighten(-2); }}>Back to the suggestion</Button>
            </div>
          </>
        }
      >
        <PageImage grey={grey} style={{ width: "62%", justifySelf: "center", filter: `brightness(${1 + brightness / 120})`, transform: `rotate(${straighten * 0.2}deg)` }} />
        {tool === "Edges" ? (
          <ErrorLine>The sheet fills the whole photo, so there is nothing to cut away.</ErrorLine>
        ) : null}
        <div style={{ display: "flex", gap: "var(--space-1)", overflow: "auto" }}>
          {TOOLS.map((t) => (
            <button
              key={t.label}
              type="button"
              onClick={() => setTool(t.label)}
              style={{
                display: "grid", justifyItems: "center", gap: 2, flex: "0 0 auto",
                minWidth: 56, minHeight: "var(--touch-min)", padding: "var(--space-1)",
                background: tool === t.label ? "var(--hover-accent)" : "transparent",
                border: `1px solid ${tool === t.label ? "var(--accent)" : "var(--divider)"}`,
                borderRadius: "var(--radius-md)", cursor: "pointer",
                color: tool === t.label ? "var(--accent-700)" : "var(--text)",
                font: "var(--weight-body) var(--text-meta)/1.3 var(--font-body)",
              }}
            >
              <window.FreePDFDesignSystem_43ff31.Icon name={t.icon} size={17} color={tool === t.label ? "var(--accent)" : "var(--text-muted)"} />
              {t.label}
            </button>
          ))}
        </div>
        <div style={{ display: "grid", gap: "var(--space-2)" }}>
          <SectionLabel>{tool}</SectionLabel>
          {tool === "Straighten" ? (
            <Slider label="Straighten" value={straighten} min={-15} max={15} unit="°" suggested={-2} minLabel="−15°" maxLabel="15°" onChange={setStraighten} />
          ) : (
            <Slider label={tool === "Brightness" ? "Brightness" : tool} value={brightness} min={-50} max={50} suggested={12} minLabel="darker" maxLabel="brighter" onChange={setBrightness} />
          )}
          <Switch label="Grey" checked={grey} onChange={setGrey} />
          <Switch label="Apply to all pages" sub="Keep the app open." checked={all} onChange={setAll} />
        </div>
      </Screen>
    </>
  );
}

Object.assign(window, { AdjustScreen });
