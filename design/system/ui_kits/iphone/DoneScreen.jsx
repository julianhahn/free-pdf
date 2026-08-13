const { TextField, Button, ConfirmDialog, PageImage, Sheet, SectionLabel } = window.FreePDFDesignSystem_43ff31;

function DoneScreen({ onChangePages, onBack, name: initialName = "", focusName = false, photosGroupLabel, photos: initialPhotos = true, reader = false }) {
  const [name, setName] = React.useState(initialName);
  const [photos, setPhotos] = React.useState(initialPhotos);
  const [confirm, setConfirm] = React.useState(false);
  const [open, setOpen] = React.useState(reader);
  return (
    <>
      <AppBar title="PDF ready" back onBack={onBack} />
      {/* No keyboard is drawn: Screen's own footer — Open PDF, Share PDF, Change pages —
          keeps its place at the bottom, and the device's keyboard is the platform's. The
          "field in use" story sets focusName instead of painting keys. */}
      <Screen
        footer={
          <>
            <Button variant="primary" fullWidth onClick={() => setOpen(true)}>Open PDF</Button>
            <Button variant="primary" fullWidth>Share PDF</Button>
            <Button variant="ghost" fullWidth onClick={onChangePages}>Change pages</Button>
          </>
        }
      >
        {/* OPEN QUESTION 2 for task 4: user-flows §9 shows no picture on this screen, and
            nothing renders a written PDF page back to an image today. These four thumbnails
            come from the delivered design (S33, "PageImage, the PDF's first page") only —
            unsettled, not evidence that the screen has them. */}
        <div style={{ display: "flex", gap: "var(--space-2)" }}>
          {[1, 2, 3, 4].map((i) => <PageImage key={i} label={String(i)} style={{ width: 62 }} />)}
        </div>
        <TextField label="Name for the shared copy" value={name} placeholder="scan" onChange={setName} autoFocus={focusName} />
        {/* The photos block is the button and its footnote together, under the group's
            SectionLabel (S33): when the photos are gone the whole block goes with them
            (user-flows §9.3), it is never greyed.
            FOR TASK 4: no copy table names this group label. user-flows §9 and §11 have no
            wording for it, so it is not invented here — pass photosGroupLabel once the copy
            table has the word, and the label stays absent until then. */}
        {photos ? (
          <div style={{ display: "grid", gap: "var(--space-2)", paddingTop: "var(--space-2)", borderTop: "1px solid var(--divider)" }}>
            {photosGroupLabel ? <SectionLabel>{photosGroupLabel}</SectionLabel> : null}
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
      {open ? (
        /* FOR TASK 4: §9.1 gives the reader sheet no title and no close wording, and no
           copy table has either — so the sheet carries neither until task 4 answers.
           The ".pdf" suffix on the name field went the same way: §10 gives label and
           placeholder "scan" only. */
        <Sheet onClose={() => setOpen(false)}>
          <PageImage label="1" />
        </Sheet>
      ) : null}
    </>
  );
}

Object.assign(window, { DoneScreen });
