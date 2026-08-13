import { Icon } from "../ds.js";

const NAMES = ["chevron-right", "files", "file-x", "rotate-cw", "crop", "sun", "scan", "wand-sparkles", "trash-2", "camera", "share-2", "plus"];

export default { title: "Core/Icon", component: Icon };

export const Default = { args: { name: "chevron-right", size: 18, color: "var(--accent)" } };

export const Sizes = {
  render: () => (
    <div style={{ display: "flex", gap: "var(--space-3)", alignItems: "center" }}>
      {[17, 18, 20, 22, 30].map((s) => (
        <Icon key={s} name="scan" size={s} color="var(--text)" />
      ))}
    </div>
  ),
};

export const UsedNames = {
  render: () => (
    <div style={{ display: "flex", flexWrap: "wrap", gap: "var(--space-3)" }}>
      {NAMES.map((n) => (
        <Icon key={n} name={n} size={20} color="var(--text-muted)" />
      ))}
    </div>
  ),
};
