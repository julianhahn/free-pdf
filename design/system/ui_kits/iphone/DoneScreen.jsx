const { TextField, Button, ConfirmDialog, PageImage, SectionLabel } = window.FreePDFDesignSystem_43ff31;

function DoneScreen({ onChangePages, onBack }) {
  const [name, setName] = React.useState("");
  const [photos, setPhotos] = React.useState(true);
  const [confirm, setConfirm] = React.useState(false);
  return (
    <>
      <AppBar title="PDF ready" back onBack={onBack} />
      <Screen
        footer={
          <>
            <Button variant="primary" fullWidth>Open PDF</Button>
            <Button variant="primary" fullWidth>Share PDF</Button>
            <Button variant="ghost" fullWidth onClick={onChangePages}>Change pages</Button>
          </>
        }
      >
        <div style={{ display: "flex", gap: "var(--space-2)" }}>
          {[1, 2, 3, 4].map((i) => <PageImage key={i} label={String(i)} style={{ width: 62 }} />)}
        </div>
        <TextField label="Name for the shared copy" value={name} placeholder="scan" suffix=".pdf" onChange={setName} />
        {photos ? (
          <div style={{ display: "grid", gap: "var(--space-2)", paddingTop: "var(--space-2)", borderTop: "1px solid var(--divider)" }}>
            <Button variant="destructive" fullWidth onClick={() => setConfirm(true)}>Delete the 40 photos (78 MB)</Button>
            <p style={{ margin: 0, font: "var(--weight-body) var(--text-meta)/1.45 var(--font-body)", color: "var(--text-muted)", textWrap: "pretty" }}>
              The PDF stays. Deleted photos cannot be brought back.
            </p>
          </div>
        ) : null}
      </Screen>
      {confirm ? (
        <ConfirmDialog
          title="Delete the 40 photos?"
          body="The PDF stays. Without the photos the pages can no longer be adjusted."
          confirmLabel="Delete photos"
          onConfirm={() => { setPhotos(false); setConfirm(false); }}
          onCancel={() => setConfirm(false)}
        />
      ) : null}
    </>
  );
}

Object.assign(window, { DoneScreen });
