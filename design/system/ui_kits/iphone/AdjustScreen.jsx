const { PageImage, PageHandles, PageCounter, ToolStrip, Slider, Switch, Button, IconButton, SectionLabel, ErrorLine, ProgressLine } = window.FreePDFDesignSystem_43ff31;

const TOOLS = [
  { label: "Edges", icon: "scan" },
  { label: "Straighten", icon: "ruler" },
  { label: "Brightness", icon: "sun" },
  { label: "Sharpen", icon: "focus" },
  { label: "Crop", icon: "crop" },
  { label: "Turn", icon: "rotate-cw" },
];

/* One source for what the drain suggests. The controls open here and
   "Back to the suggestion" comes back here — never two lists of numbers. */
const SUGGESTED = { edgeInset: 8, flat: true, straighten: -2, black: 12, white: 88, sharpen: 0.6 };

/* Wording still missing (task 4), never invented here — it comes in as props with no
   default, so a screen without the word simply shows nothing:
   - cropRefusedText: the crop refusal sentence (S28).
   - blackPointLabel / whitePointLabel / levelsLabel (S26): 7a only describes them in
     prose, "two sliders, black point and white point, plus an on/off". No copy table
     carries the words, and the on/off is NOT the tool name "Brightness".
   - The Edges on/off label: user-flows.md 7a names it "Pull the sheet flat", the copy
     table in section 7 does not carry it yet.
   - The Turn button label: the copy table gives the tool name "Turn" and no more.
   - What Sharpen at 0 reads (S27): 7a only says 0 means no sharpening. */

function AdjustScreen({
  page = 3,
  tool: startTool = "Brightness",
  edges = "none",          // "none" | "nothing-to-cut" | "warning"
  cropRefused = false,
  sharpen: startSharpen = SUGGESTED.sharpen,
  cropRefusedText,
  blackPointLabel,
  whitePointLabel,
  levelsLabel,
  applyingAll = false,
  onDone,
  onBack,
}) {
  const [tool, setTool] = React.useState(startTool);
  const [flat, setFlat] = React.useState(SUGGESTED.flat);
  const [straighten, setStraighten] = React.useState(SUGGESTED.straighten);
  const [black, setBlack] = React.useState(SUGGESTED.black);
  const [white, setWhite] = React.useState(SUGGESTED.white);
  const [levels, setLevels] = React.useState(true);
  const [sharpen, setSharpen] = React.useState(startSharpen);
  const [all, setAll] = React.useState(applyingAll);
  const [running, setRunning] = React.useState(false);

  /* Only the active tool goes back to its suggestion. Crop and Turn have none. */
  const resets = {
    Edges: () => setFlat(SUGGESTED.flat),
    Straighten: () => setStraighten(SUGGESTED.straighten),
    Brightness: () => { setBlack(SUGGESTED.black); setWhite(SUGGESTED.white); },
    Sharpen: () => setSharpen(SUGGESTED.sharpen),
  };
  const reset = resets[tool];

  if (applyingAll || (running && all)) {
    return (
      <>
        <AppBar title={`Adjust page ${page}`} />
        <Screen>
          <div style={{ display: "grid", gap: "var(--space-4)", justifyItems: "start", alignContent: "center", minHeight: "60vh" }}>
            <PageCounter>Page 12 of 40</PageCounter>
            <ProgressLine line="Applying to 40 pages…" note="Keep the app open." value={12} max={40} style={{ width: "100%" }} />
          </div>
        </Screen>
      </>
    );
  }

  return (
    <>
      <AppBar title={`Adjust page ${page}`} />
      <Screen
        footer={
          <>
            <Button variant="primary" fullWidth busy={running} onClick={() => { setRunning(true); setTimeout(() => { setRunning(false); onDone && onDone(); }, 900); }}>
              {running ? "Applying…" : "Apply"}
            </Button>
            <div style={{ display: "flex", gap: "var(--space-2)" }}>
              <Button
                variant="secondary"
                disabled={running}
                style={running ? { flex: 1, opacity: 1, color: "var(--disabled-text)", borderColor: "var(--disabled-border)", background: "var(--disabled-surface)" } : { flex: 1 }}
                onClick={running ? undefined : onBack}
              >
                Cancel
              </Button>
              {reset ? (
                <Button variant="ghost" style={{ flex: 1 }} onClick={reset}>Back to the suggestion</Button>
              ) : null}
            </div>
          </>
        }
      >
        {/* No live preview: the picture is the page as it stands now. */}
        {tool === "Edges" || tool === "Crop" ? (
          <PageHandles
            count={tool === "Crop" ? 8 : 4}
            inset={SUGGESTED.edgeInset}
            refused={tool === "Crop" && cropRefused}
            refusedText={cropRefusedText}
            style={{ width: "62%", justifySelf: "center" }}
          />
        ) : (
          <PageImage style={{ width: "62%", justifySelf: "center" }} />
        )}

        {/* The Edges note has three states: silent, a calm statement, a warning. */}
        {tool === "Edges" && edges === "nothing-to-cut" ? (
          <p style={{ margin: 0, color: "var(--text-muted)", font: "var(--weight-body) var(--text-sub)/var(--leading-body) var(--font-body)" }}>
            The sheet fills the whole photo, so there is nothing to cut away.
          </p>
        ) : null}
        {tool === "Edges" && edges === "warning" ? (
          <ErrorLine>The page runs off the frame. Move back and photograph it again.</ErrorLine>
        ) : null}

        <ToolStrip items={TOOLS} active={tool} onSelect={setTool} />

        <div style={{ display: "grid", gap: "var(--space-2)" }}>
          <SectionLabel>{tool}</SectionLabel>
          {tool === "Edges" ? (
            /* Label from user-flows.md 7a, not yet in the copy table (task 4). */
            <Switch label="Pull the sheet flat" checked={flat} onChange={setFlat} />
          ) : null}
          {tool === "Straighten" ? (
            <Slider label="Straighten" value={straighten} min={-10} max={10} step={0.1} unit="°" suggested={SUGGESTED.straighten} minLabel="−10°" maxLabel="10°" onChange={setStraighten} />
          ) : null}
          {tool === "Brightness" ? (
            /* apply_levels: black point, white point, and an on/off. All three words are
               task 4's — 7a describes them, no copy table names them. */
            <>
              <Slider label={blackPointLabel} value={black} min={0} max={100} suggested={SUGGESTED.black} onChange={setBlack} />
              <Slider label={whitePointLabel} value={white} min={0} max={100} suggested={SUGGESTED.white} onChange={setWhite} />
              <Switch label={levelsLabel} checked={levels} onChange={setLevels} />
            </>
          ) : null}
          {tool === "Sharpen" ? (
            <Slider label="Sharpen" value={sharpen} min={0} max={20} step={0.1} suggested={SUGGESTED.sharpen} minLabel="0" maxLabel="20" onChange={setSharpen} />
          ) : null}
          {tool === "Turn" ? (
            <IconButton icon="rotate-cw" label="Turn" />
          ) : null}
          <Switch label="Apply to all pages" checked={all} onChange={setAll} />
        </div>
      </Screen>
    </>
  );
}

Object.assign(window, { AdjustScreen });
