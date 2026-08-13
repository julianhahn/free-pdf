const { ScanRow, EmptyState, Button, ConfirmDialog, ProgressLine, ErrorLine } = window.FreePDFDesignSystem_43ff31;

/* Newest first, by folder date — the row order of the real list (user-flows §2.1).
   All seven subtitles of the §2 table, one row each. */
const SCANS = [
  { id: "a", title: "11 Aug 2026, 20:14", subtitle: "40 pages — PDF ready" },
  { id: "b", title: "11 Aug 2026, 09:02", subtitle: "12 of 40 pages scanned", progress: [12, 40] },
  { id: "c", title: "10 Aug 2026, 18:47", subtitle: "8 pages — keep shooting" },
  { id: "f", title: "10 Aug 2026, 07:15", subtitle: "40 pages — ready to check" },
  { id: "g", title: "09 Aug 2026, 19:58", subtitle: "1 page — keep shooting" },
  { id: "d", title: "09 Aug 2026, 14:31", subtitle: "40 pages — PDF ready, photos deleted" },
  { id: "e", title: "08 Aug 2026, 11:20", subtitle: "No pages yet" },
];

/* `error` stays a slot and stays undefined. The one error on this screen — New scan
   could not create the folder (out of storage) — is "the system's own sentence"
   (user-flows §1, S2); no copy table gives it, so nothing is invented here.
   TASK 4: supply the EN and DE storage-error sentence. */
function ScansScreen({ onOpen, onNew, scans: initial = SCANS, error, pressedId }) {
  const [scans, setScans] = React.useState(initial);
  const [swiped, setSwiped] = React.useState(null);
  const [confirm, setConfirm] = React.useState(null);
  const empty = scans.length === 0;
  return (
    <>
      <AppBar title="Scans" />
      <Screen footer={<Button variant="primary" fullWidth onClick={onNew}>New scan</Button>}>
        {error ? <ErrorLine style={{ marginBottom: "var(--space-3)" }}>{error}</ErrorLine> : null}
        {empty ? (
          <EmptyState title="No scans yet" body="Tap New scan and photograph the pages, one after another. You can stop whenever you like." />
        ) : (
          <div>
            {scans.map((s) => (
              <ScanRow
                key={s.id}
                title={s.title}
                subtitle={s.subtitle}
                swiped={swiped === s.id}
                pressed={pressedId === s.id}
                onPress={() => (swiped === s.id ? setSwiped(null) : swiped ? setSwiped(null) : onOpen(s))}
                onDelete={() => setConfirm(s)}
                onContextMenu={(e) => { e.preventDefault(); setSwiped(swiped === s.id ? null : s.id); }}
              />
            ))}
          </div>
        )}
        {scans.some((s) => s.progress) ? (
          <ProgressLine line="Scanning page 12 of 40" note="You can close the app. It carries on from here." value={12} max={40} />
        ) : null}
      </Screen>
      {confirm ? (
        <ConfirmDialog
          title="Delete this scan?"
          body="40 pages, the PDF and 40 photos go. This cannot be undone."
          confirmLabel="Delete scan"
          onConfirm={() => { setScans(scans.filter((s) => s.id !== confirm.id)); setSwiped(null); setConfirm(null); }}
          onCancel={() => setConfirm(null)}
        />
      ) : null}
    </>
  );
}

Object.assign(window, { ScansScreen });
