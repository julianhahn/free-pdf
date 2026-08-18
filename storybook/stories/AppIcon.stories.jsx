import icon from "../../design/brand/app-icon.svg";
import tinted from "../../design/brand/app-icon-tinted.svg";

export default { title: "Brand/AppIcon" };

// iOS rounds the corners itself: 27px on 120 in the delivered document, so 22.5% of the side.
const ROUNDED = "22.5%";

const Tile = ({ src, size, label, rounded }) => (
  <div style={{ display: "grid", gap: "var(--space-2)", justifyItems: "center" }}>
    <img src={src} alt="" width={size} height={size} style={{ display: "block", borderRadius: rounded ? ROUNDED : 0 }} />
    <span className="fp-meta">{label}</span>
  </div>
);

const Row = ({ children }) => (
  <div style={{ display: "flex", gap: "var(--space-6)", alignItems: "flex-end", flexWrap: "wrap" }}>{children}</div>
);

export const Sizes = {
  render: () => (
    <Row>
      <Tile src={icon} size={240} label="1024 · delivered" />
      <Tile src={icon} size={240} label="1024 · rounded" rounded />
      <Tile src={icon} size={120} label="120 · home screen @2x" rounded />
      <Tile src={icon} size={60} label="60" rounded />
      <Tile src={icon} size={40} label="40 · Spotlight" rounded />
      <Tile src={icon} size={29} label="29 · Settings" rounded />
    </Row>
  ),
};

export const Tinted = {
  render: () => (
    <Row>
      <Tile src={tinted} size={120} label="120 · tinted" rounded />
    </Row>
  ),
};
