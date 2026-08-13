import React from "react";

/* 42 x 24 outlined track, 16 knob, travel 3 to 21. Off: knob at text 45%.
   On: accent border, accent knob. Drawn 24 high, tappable 44. */
export function Switch({ checked = false, onChange, label, sub, disabled = false, style, ...rest }) {
  const [focused, setFocused] = React.useState(false);
  const rowStyle = {
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
    gap: "var(--space-3)",
    minHeight: "var(--touch-min)",
    width: "100%",
    background: "transparent",
    border: "none",
    padding: 0,
    textAlign: "left",
    cursor: disabled ? "default" : "pointer",
    color: disabled ? "var(--disabled-text)" : undefined,
    ...style,
  };
  const trackStyle = {
    position: "relative",
    width: "var(--switch-w)",
    height: "var(--switch-h)",
    flex: "0 0 auto",
    borderRadius: 999,
    border: `1px solid ${checked ? (disabled ? "var(--disabled-border)" : "var(--accent)") : disabled ? "var(--disabled-border)" : "var(--divider-strong)"}`,
    background: disabled ? "var(--disabled-surface)" : checked ? "var(--hover-accent)" : "transparent",
    outline: focused ? "2px solid var(--focus-ring)" : "none",
    outlineOffset: 2,
    transition: "border-color 140ms linear, background 140ms linear",
  };
  const knobStyle = {
    position: "absolute",
    top: "50%",
    left: checked ? "var(--switch-travel-end)" : "var(--switch-travel-start)",
    transform: "translate(-0%, -50%)",
    width: "var(--switch-knob)",
    height: "var(--switch-knob)",
    borderRadius: "var(--radius-round)",
    background: checked ? (disabled ? "var(--disabled-border)" : "var(--accent)") : "color-mix(in srgb, var(--text) 45%, transparent)",
    transition: "left 140ms ease-out, background 140ms linear",
  };
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      disabled={disabled}
      onClick={disabled ? undefined : () => onChange && onChange(!checked)}
      onFocus={() => setFocused(true)}
      onBlur={() => setFocused(false)}
      style={rowStyle}
      {...rest}
    >
      <span>
        <span style={{ font: `var(--weight-heading) var(--text-control)/1.2 var(--font-heading)`, letterSpacing: "var(--tracking-heading)", display: "block" }}>{label}</span>
        {sub ? <span style={{ font: `var(--weight-body) var(--text-meta)/1.4 var(--font-body)`, color: disabled ? "var(--disabled-text)" : "var(--text-muted)" }}>{sub}</span> : null}
      </span>
      <span style={trackStyle}><span style={knobStyle} /></span>
    </button>
  );
}
