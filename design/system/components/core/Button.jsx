import React from "react";

const variantStyle = {
  primary: { color: "var(--accent)", borderColor: "var(--accent)" },
  secondary: { color: "var(--text)", borderColor: "var(--divider)" },
  destructive: { color: "var(--destructive)", borderColor: "var(--destructive)" },
  ghost: { color: "var(--accent)", borderColor: "transparent" },
};

/* Outlined, never filled. Full width when it is the screen's action. */
export function Button({
  variant = "primary",
  children,
  fullWidth = false,
  disabled = false,
  busy = false,
  onClick,
  style,
  ...rest
}) {
  const [state, setState] = React.useState("rest");
  const v = variantStyle[variant] || variantStyle.primary;
  const tint =
    state === "press"
      ? variant === "secondary"
        ? "var(--press-neutral)"
        : "var(--press-accent)"
      : state === "hover"
      ? variant === "secondary"
        ? "var(--hover-neutral)"
        : "var(--hover-accent)"
      : "transparent";
  const buttonStyle = {
    font: `var(--weight-heading) var(--text-control)/1.2 var(--font-heading)`,
    letterSpacing: "var(--tracking-heading)",
    fontVariantNumeric: "tabular-nums",
    padding: "var(--button-padding-y) var(--button-padding-x)",
    minHeight: "var(--touch-min)",
    width: fullWidth ? "100%" : undefined,
    background: tint,
    border: "1px solid",
    borderRadius: "var(--radius-md)",
    boxShadow: variant === "destructive" ? "inset 0 0 0 3px var(--bg), inset 0 0 0 4px currentColor" : "none",
    opacity: disabled ? "var(--disabled-opacity)" : 1,
    cursor: disabled ? "default" : "pointer",
    outline: state === "focus" ? "2px solid var(--focus-ring)" : "none",
    outlineOffset: 2,
    transition: "background 120ms linear",
    ...v,
    ...style,
  };
  return (
    <button
      type="button"
      disabled={disabled || busy}
      aria-busy={busy || undefined}
      onClick={disabled || busy ? undefined : onClick}
      onPointerEnter={() => !disabled && setState("hover")}
      onPointerLeave={() => setState("rest")}
      onPointerDown={() => !disabled && setState("press")}
      onPointerUp={() => !disabled && setState("hover")}
      onFocus={() => !disabled && setState("focus")}
      onBlur={() => setState("rest")}
      style={buttonStyle}
      {...rest}
    >
      {children}
    </button>
  );
}
