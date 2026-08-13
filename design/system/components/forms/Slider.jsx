import React from "react";

/* 1 px track, 17 px round thumb with an accent border. It opens on the value the
   engine suggested; the value prints beside the label in destructive-weight accent,
   tabular figures, and the two ends are labelled at meta size. */
export function Slider({
  label,
  value,
  min = 0,
  max = 100,
  step = 1,
  unit = "",
  minLabel,
  maxLabel,
  suggested,
  disabled = false,
  onChange,
  style,
  ...rest
}) {
  const pct = ((value - min) / (max - min)) * 100;
  const trackWrapStyle = {
    position: "relative",
    height: "var(--touch-min)",
    display: "flex",
    alignItems: "center",
  };
  return (
    <div style={{ opacity: disabled ? "var(--disabled-opacity)" : 1, ...style }} {...rest}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", gap: "var(--space-2)" }}>
        <span style={{ font: `var(--weight-heading) var(--text-control)/1.2 var(--font-heading)`, letterSpacing: "var(--tracking-heading)" }}>{label}</span>
        <span style={{ font: `var(--weight-body) var(--text-control)/1.2 var(--font-body)`, color: "var(--destructive)", fontVariantNumeric: "tabular-nums" }}>
          {value}{unit}
        </span>
      </div>
      <div style={trackWrapStyle}>
        <div style={{ position: "absolute", left: 0, right: 0, height: "var(--slider-track)", background: "var(--divider-strong)" }} />
        {typeof suggested === "number" ? (
          <div
            title="the engine's suggestion"
            style={{
              position: "absolute",
              left: `${((suggested - min) / (max - min)) * 100}%`,
              width: 1,
              height: 9,
              background: "var(--divider-strong)",
              transform: "translateX(-50%)",
            }}
          />
        ) : null}
        <div
          style={{
            position: "absolute",
            left: `${pct}%`,
            transform: "translateX(-50%)",
            width: "var(--slider-thumb)",
            height: "var(--slider-thumb)",
            borderRadius: "var(--radius-round)",
            background: "var(--bg)",
            border: "1px solid var(--accent)",
            boxShadow: "var(--shadow-sm)",
            pointerEvents: "none",
          }}
        />
        <input
          type="range"
          aria-label={label}
          min={min}
          max={max}
          step={step}
          value={value}
          disabled={disabled}
          onChange={(e) => onChange && onChange(Number(e.target.value))}
          style={{ position: "absolute", inset: 0, width: "100%", height: "100%", margin: 0, opacity: 0, cursor: disabled ? "default" : "pointer" }}
        />
      </div>
      <div style={{ display: "flex", justifyContent: "space-between", font: `var(--weight-body) var(--text-meta)/1.4 var(--font-body)`, color: "var(--text-muted)" }}>
        <span>{minLabel}</span>
        <span>{maxLabel}</span>
      </div>
    </div>
  );
}
