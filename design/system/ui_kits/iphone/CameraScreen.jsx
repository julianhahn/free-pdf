const { Viewfinder, Shutter, Button, EmptyState, ErrorLine } = window.FreePDFDesignSystem_43ff31;

// The four <why> variants of the failure sentence, verbatim from ios/AGENTS.md.
const SHOT_ERRORS = {
  storage: "the iPhone is out of storage.",
  notReady: "the camera is not ready.",
  noPhoto: "the camera handed over no photo.",
  stopped: "the camera stopped before the photo arrived.",
};

// The two screen-level states, verbatim from user-flows.md 4a/4b.
const BLOCKED = {
  noCamera: "This iPhone has no camera to photograph with.",
  startFailed: "The camera could not be started.",
  permission: "FreePDF needs the camera to photograph the pages.",
};

// pages / writing / error / blocked / simulator are the story states; pages also grows by shooting.
function CameraScreen({ onFinish, onBack, onOpenSettings, pages: startPages = 6, writing = false, error = null, blocked = null, simulator = false }) {
  const [pages, setPages] = React.useState(startPages);
  const page = pages + 1;

  if (blocked) {
    return (
      <>
        <AppBar title={`Page ${page}`} back onBack={onBack} />
        <Screen>
          <EmptyState
            icon="camera-off"
            title={BLOCKED[blocked]}
            action={blocked === "permission" ? <Button variant="primary" onClick={onOpenSettings}>Open Settings</Button> : null}
          />
        </Screen>
      </>
    );
  }

  return (
    <>
      <AppBar title={`Page ${page}`} back onBack={onBack} />
      <Screen
        footer={
          <Button variant="primary" fullWidth disabled={pages === 0} onClick={() => onFinish(pages)}>
            {/* TASK 4: no copy table has the singular — "Scan 1 pages" reads wrong and the
                singular wording must come from ios/AGENTS.md, not from here. */}
            {pages === 0 ? "Photograph at least one page" : `Scan ${pages} pages`}
          </Button>
        }
      >
        {error ? <ErrorLine>{`Page ${page} was not saved: ${SHOT_ERRORS[error]} Nothing already photographed is lost.`}</ErrorLine> : null}
        <Viewfinder note={simulator ? "No camera on this iPhone. The shutter draws a page instead." : null}>
          <div style={{ position: "absolute", inset: "14% 16%", background: "#38352f", boxShadow: "0 0 40px rgba(0,0,0,.5) inset" }} />
        </Viewfinder>
        <div style={{ display: "grid", placeItems: "center" }}>
          <Shutter label={`Photograph page ${page}`} disabled={writing} onPress={() => setPages((p) => p + 1)} />
        </div>
      </Screen>
    </>
  );
}

Object.assign(window, { CameraScreen });
