const { PageImage, PageCounter, IconButton, MenuList, Switch, Button, ConfirmDialog } = window.FreePDFDesignSystem_43ff31;

function PagesScreen({ total = 12, onAdjust, onMakePdf, onBack }) {
  const [page, setPage] = React.useState(3);
  const [grey, setGrey] = React.useState(false);
  const [menu, setMenu] = React.useState(false);
  const [confirm, setConfirm] = React.useState(false);
  const [making, setMaking] = React.useState(false);
  const refused = page === 5;
  return (
    <>
      <AppBar
        title={`Page ${page} of ${total}`}
        back
        onBack={onBack}
        trailing={<IconButton icon="ellipsis" label="Page menu" onClick={() => setMenu(!menu)} />}
      />
      <Screen
        footer={
          <>
            <Switch label="Grey" checked={grey} onChange={setGrey} />
            <Button variant="primary" fullWidth busy={making} onClick={() => { setMaking(true); setTimeout(() => { setMaking(false); onMakePdf(); }, 700); }}>
              {making ? "Making the PDF…" : "Make PDF"}
            </Button>
          </>
        }
      >
        <div style={{ position: "relative" }}>
          <PageImage state={refused ? "refused" : "page"} grey={grey} style={{ width: "100%" }} />
          <div style={{ position: "absolute", left: "var(--space-2)", bottom: "var(--space-2)" }}>
            <PageCounter>{`${page} / ${total}`}</PageCounter>
          </div>
        </div>
        {refused ? (
          <Button variant="secondary" fullWidth>Scan this page again</Button>
        ) : (
          <Button variant="ghost" fullWidth onClick={() => onAdjust(page)}>Adjust page</Button>
        )}
        <div style={{ display: "flex", gap: "var(--space-2)", overflow: "auto", paddingBottom: 2 }}>
          {Array.from({ length: total }, (_, i) => (
            <PageImage
              key={i}
              label={String(i + 1)}
              grey={grey}
              state={i + 1 === 5 ? "refused" : "page"}
              selected={i + 1 === page}
              onClick={() => setPage(i + 1)}
              style={{ width: 40, flex: "0 0 auto" }}
            />
          ))}
        </div>
      </Screen>
      {menu ? (
        <div onClick={() => setMenu(false)} style={{ position: "absolute", inset: 0, background: "color-mix(in srgb, var(--neutral-900) 22%, transparent)", padding: "var(--space-4)", display: "grid", justifyItems: "end", alignContent: "start" }}>
          <MenuList
            title="Page"
            items={[
              { label: "Retake this page", icon: "camera" },
              { label: "Adjust page", icon: "sun" },
              { label: "Shoot another page", icon: "plus" },
              { label: "Delete page", icon: "trash-2", destructive: true },
            ]}
            onSelect={(item) => { setMenu(false); if (item.label === "Delete page") setConfirm(true); if (item.label === "Adjust page") onAdjust(page); }}
            style={{ marginTop: 52 }}
          />
        </div>
      ) : null}
      {confirm ? (
        <ConfirmDialog
          title="Delete this page?"
          body="The photo goes too. This cannot be undone."
          confirmLabel="Delete page"
          onConfirm={() => setConfirm(false)}
          onCancel={() => setConfirm(false)}
        />
      ) : null}
    </>
  );
}

Object.assign(window, { PagesScreen });
