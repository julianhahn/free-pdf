const { ScanRow, EmptyState, Button, ConfirmDialog, ProgressLine } = window.FreePDFDesignSystem_43ff31;

const SCANS = [
  { id: "a", title: "11 Aug 2026, 20:14", subtitle: "40 pages — PDF ready" },
  { id: "b", title: "11 Aug 2026, 09:02", subtitle: "12 of 40 pages scanned", progress: [12, 40] },
  { id: "c", title: "10 Aug 2026, 18:47", subtitle: "8 pages — keep shooting" },
  { id: "d", title: "09 Aug 2026, 14:31", subtitle: "40 pages — PDF ready, photos deleted" },
  { id: "e", title: "08 Aug 2026, 11:20", subtitle: "No pages yet" },
];

function ScansScreen({ onOpen, onNew }) {
  const [scans, setScans] = React.useState(SCANS);
  const [swiped, setSwiped] = React.useState(null);
  const [confirm, setConfirm] = React.useState(null);
  const empty = scans.length === 0;
  return (
    <>
      <AppBar title="Scans" />
      <Screen footer={<Button variant="primary" fullWidth onClick={onNew}>New scan</Button>}>
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
