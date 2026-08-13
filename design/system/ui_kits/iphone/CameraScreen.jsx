const { Viewfinder, PageCounter, Shutter, Button, PageImage, ErrorLine } = window.FreePDFDesignSystem_43ff31;

function CameraScreen({ onFinish, onBack }) {
  const [pages, setPages] = React.useState(6);
  const [writing, setWriting] = React.useState(false);
  const shoot = () => {
    setWriting(true);
    setTimeout(() => { setPages((p) => p + 1); setWriting(false); }, 550);
  };
  return (
    <>
      <AppBar title={`Page ${pages + 1}`} back onBack={onBack} />
      <Screen
        footer={
          <Button variant="primary" fullWidth disabled={pages === 0} onClick={() => onFinish(pages)}>
            {pages === 0 ? "Photograph at least one page" : `Scan ${pages} pages`}
          </Button>
        }
      >
        <Viewfinder note={writing ? "Writing the photo…" : null}>
          <div style={{ position: "absolute", inset: "14% 16%", background: "#38352f", boxShadow: "0 0 40px rgba(0,0,0,.5) inset" }} />
          <div style={{ position: "absolute", top: "var(--space-2)", left: "var(--space-2)" }}>
            <PageCounter onDark>{`Page ${pages + 1}`}</PageCounter>
          </div>
        </Viewfinder>
        <div style={{ display: "grid", placeItems: "center" }}>
          <Shutter label={`Photograph page ${pages + 1}`} disabled={writing} onPress={shoot} />
        </div>
        <div style={{ display: "flex", gap: "var(--space-2)", overflow: "auto", paddingBottom: 2 }}>
          {Array.from({ length: pages }, (_, i) => (
            <PageImage key={i} label={String(i + 1)} style={{ width: 44, flex: "0 0 auto" }} />
          ))}
        </div>
      </Screen>
    </>
  );
}

Object.assign(window, { CameraScreen });
