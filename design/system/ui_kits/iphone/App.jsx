function App() {
  const [screen, setScreen] = React.useState("scans");
  const [theme, setTheme] = React.useState("light");
  React.useEffect(() => { document.documentElement.dataset.theme = theme; }, [theme]);
  const view = {
    scans: <ScansScreen onOpen={() => setScreen("pages")} onNew={() => setScreen("camera")} />,
    camera: <CameraScreen onBack={() => setScreen("scans")} onFinish={() => setScreen("pages")} />,
    pages: <PagesScreen onBack={() => setScreen("scans")} onAdjust={() => setScreen("adjust")} onMakePdf={() => setScreen("done")} />,
    adjust: <AdjustScreen onBack={() => setScreen("pages")} onDone={() => setScreen("pages")} />,
    done: <DoneScreen onBack={() => setScreen("scans")} onChangePages={() => setScreen("pages")} />,
  }[screen];
  return (
    <div style={{ display: "grid", gap: "var(--space-4)", justifyItems: "center" }}>
      <div
        style={{
          position: "relative",
          width: 390,
          height: 844,
          background: "var(--bg)",
          border: "1px solid var(--divider)",
          borderRadius: 40,
          overflow: "hidden",
          display: "grid",
          gridTemplateRows: "auto 1fr",
          boxShadow: "var(--shadow-md)",
        }}
      >
        <StatusLine />
        <div style={{ position: "relative", minHeight: 0 }}>{view}</div>
      </div>
      <div style={{ display: "flex", gap: "var(--space-2)", alignItems: "center", font: "var(--weight-body) var(--text-meta)/1.4 var(--font-body)", color: "var(--text-muted)" }}>
        {["scans", "camera", "pages", "adjust", "done"].map((s) => (
          <button
            key={s}
            type="button"
            onClick={() => setScreen(s)}
            style={{
              background: "transparent",
              border: `1px solid ${screen === s ? "var(--accent)" : "var(--divider)"}`,
              color: screen === s ? "var(--accent-700)" : "var(--text-muted)",
              borderRadius: "var(--radius-sm)",
              padding: "3px 8px",
              font: "var(--weight-body) var(--text-meta)/1.4 var(--font-body)",
              cursor: "pointer",
            }}
          >
            {s}
          </button>
        ))}
        <button
          type="button"
          onClick={() => setTheme(theme === "light" ? "dark" : "light")}
          style={{ background: "transparent", border: "1px solid var(--divider)", color: "var(--text-muted)", borderRadius: "var(--radius-sm)", padding: "3px 8px", font: "var(--weight-body) var(--text-meta)/1.4 var(--font-body)", cursor: "pointer" }}
        >
          {theme === "light" ? "dark" : "light"}
        </button>
      </div>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
