import React from "react";
import { Icon } from "../core/Icon.jsx";

/* A scanned page. The app is full of these, so the frame is the system's one
   recurring shape: a paper ground, a hairline, and nothing else.
   No src yet -> the ruled placeholder stands in (see readme.md > Imagery).
   state="refused" -> the failure card that replaces an image. */
export function PageImage({
  src,
  alt = "",
  state = "page",
  grey = false,
  label,
  refusedText = "This page could not be scanned.",
  selected = false,
  onClick,
  style,
  ...rest
}) {
  const frameStyle = {
    position: "relative",
    aspectRatio: "var(--page-ratio)",
    background: "var(--paper)",
    border: `1px solid ${selected ? "var(--accent)" : "var(--divider)"}`,
    borderRadius: "var(--radius-md)",
    overflow: "hidden",
    boxShadow: selected ? "0 0 0 1px var(--accent)" : "var(--shadow-sm)",
    cursor: onClick ? "pointer" : "default",
    ...style,
  };
  const ruled = {
    position: "absolute",
    inset: "12% 14%",
    background:
      "repeating-linear-gradient(to bottom, color-mix(in srgb, var(--neutral-900) 26%, transparent) 0 1px, transparent 1px 9px)",
    opacity: 0.5,
    maskImage: "linear-gradient(to bottom, #000 0 62%, transparent 62% 100%)",
    WebkitMaskImage: "linear-gradient(to bottom, #000 0 62%, transparent 62% 100%)",
  };
  return (
    <div
      role={onClick ? "button" : undefined}
      aria-label={onClick ? label : undefined}
      onClick={onClick}
      style={frameStyle}
      {...rest}
    >
      {state === "refused" ? (
        <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", gap: "var(--space-2)", alignContent: "center", padding: "var(--space-3)", background: "var(--surface)", textAlign: "center" }}>
          <Icon name="file-x" size={22} color="var(--destructive)" />
          <span style={{ font: `var(--weight-body) var(--text-sub)/var(--leading-body) var(--font-body)`, color: "var(--destructive)" }}>{refusedText}</span>
        </div>
      ) : src ? (
        <img src={src} alt={alt} style={{ width: "100%", height: "100%", objectFit: "cover", filter: grey ? "grayscale(1)" : "none" }} />
      ) : (
        <>
          <div style={{ position: "absolute", inset: "7% 9%", border: "1px solid color-mix(in srgb, var(--neutral-900) 12%, transparent)" }} />
          <div style={ruled} />
          <div style={{ position: "absolute", inset: "12% 14% auto", height: 3, background: "color-mix(in srgb, var(--neutral-900) 42%, transparent)", width: "42%" }} />
        </>
      )}
      {label ? (
        <span style={{ position: "absolute", left: 0, bottom: 0, padding: "1px var(--space-1)", background: "var(--bg)", borderTop: "1px solid var(--divider)", borderRight: "1px solid var(--divider)", font: `var(--weight-body) var(--text-meta)/1.4 var(--font-body)`, fontVariantNumeric: "tabular-nums", color: "var(--text-muted)" }}>{label}</span>
      ) : null}
    </div>
  );
}
