const { PageImage, PageStrip, PageCounter, IconButton, MenuList, Switch, Button, ConfirmDialog } = window.FreePDFDesignSystem_43ff31;

function PagesScreen({
  total = 12,
  start = 3,
  // The pages themselves. `state`: "page" | "refused" | "photo-gone".
  // "refused" carries the engine's own sentence in `refusedText` (user-flows 5, 6);
  // "photo-gone" is a page whose photo was deleted (user-flows 7.2, 11.5).
  pages: pageList,
  // A finished scan gets a fourth menu item, "Shoot another page" (user-flows 6).
  done = false,
  // TASK 4 — no copy: the sentence naming the pages an apply-to-all skipped
  // (user-flows 7b.4, design S32). Wording exists in no copy table, so it comes
  // in as data and has no default.
  skippedNote,
  menuOpen = false,
  jump: jumpStart = "closed",
  onAdjust,
  onMakePdf,
  onBack,
}) {
  const [page, setPage] = React.useState(start);
  const [grey, setGrey] = React.useState(false);
  const [menu, setMenu] = React.useState(menuOpen);
  const [confirm, setConfirm] = React.useState(false);
  const [making, setMaking] = React.useState(false);
  const [jump, setJump] = React.useState(jumpStart);
  const [jumpValue, setJumpValue] = React.useState("");
  const pages =
    pageList ||
    Array.from({ length: total }, (_, i) => ({
      n: i + 1,
      state: i + 1 === 5 ? "refused" : "page",
      // The copy table for the pages screen gives this one sentence (user-flows 6).
      refusedText: i + 1 === 5 ? "This page could not be scanned." : undefined,
    }));
  const current = pages[page - 1];
  const refused = current.state === "refused";
  // OPEN QUESTION 1: the design document draws Make PDF next to a refused page.
  // user-flows 6.6 and 8.1 and ios/AGENTS.md win: it appears only when every
  // photo has a page, so it is derived here, never a prop defaulting to true.
  const ready = pages.every((p) => p.state !== "refused");
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
            {skippedNote ? <p className="fp-sub" style={{ margin: 0 }}>{skippedNote}</p> : null}
            <Switch label="Grey" checked={grey} onChange={setGrey} />
            {ready ? (
              <Button variant="primary" fullWidth busy={making} onClick={() => { setMaking(true); setTimeout(() => { setMaking(false); onMakePdf(); }, 700); }}>
                {making ? "Making the PDF…" : "Make PDF"}
              </Button>
            ) : null}
          </>
        }
      >
        <div style={{ position: "relative" }}>
          <PageImage
            state={refused ? "refused" : "page"}
            refusedText={refused ? current.refusedText : undefined}
            grey={grey}
            style={{ width: "100%" }}
          />
          <div style={{ position: "absolute", left: "var(--space-2)", bottom: "var(--space-2)" }}>
            <PageCounter>{`Page ${page} of ${total}`}</PageCounter>
          </div>
        </div>
        {refused ? <Button variant="secondary" fullWidth>Scan this page again</Button> : null}
        <PageStrip
          pages={pages.map((p) => ({ n: p.n, state: p.state === "refused" ? "refused" : "page" }))}
          selected={page}
          onSelect={setPage}
          total={total}
          grey={grey}
          jump={jump}
          jumpValue={jumpValue}
          onJumpToggle={() => setJump(jump === "open" ? "closed" : "open")}
          onJumpChange={setJumpValue}
          onJumpSubmit={(n) => { setPage(Number(n)); setJump("closed"); }}
        />
      </Screen>
      {menu ? (
        <div onClick={() => setMenu(false)} style={{ position: "absolute", inset: 0, background: "color-mix(in srgb, var(--neutral-900) 22%, transparent)", padding: "var(--space-4)", display: "grid", justifyItems: "end", alignContent: "start" }}>
          <MenuList
            title="Page"
            items={[
              { label: "Retake this page", icon: "camera" },
              // Adjust needs the photo (user-flows 7.2, 11.5): a page whose photo
              // is gone cannot be adjusted, so the item is not offered at all.
              // TASK 4 — no copy: no copy table gives a sentence explaining the
              // missing item, so nothing is written in its place.
              ...(current.state === "photo-gone" ? [] : [{ label: "Adjust page", icon: "sun" }]),
              ...(done ? [{ label: "Shoot another page", icon: "plus" }] : []),
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
