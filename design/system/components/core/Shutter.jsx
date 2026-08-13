import React from "react";

/* The shutter. 72 px, stroke first: a 2 px accent ring, a gap in the ground, and a
   solid paper disc inside it — the sheet you are about to photograph. The disc is
   the answer to "a hairline on a dark viewfinder is not a control": it is found by
   its light mass, not by its outline. Disabled while the photo is being written,
   which is the rule that makes one press one page. */
export function Shutter({ disabled = false, onPress, label = "Photograph page", style, ...rest }) {
  const [pressed, setPressed] = React.useState(false);
  const [focused, setFocused] = React.useState(false);
  const shutterStyle = {
    width: "var(--shutter-size)",
    height: "var(--shutter-size)",
    borderRadius: "var(--radius-round)",
    border: `var(--shutter-ring) solid ${disabled ? "var(--disabled-border)" : "var(--accent)"}`,
    background: "transparent",
    padding: "var(--shutter-gap)",
    display: "grid",
    placeItems: "center",
    cursor: disabled ? "default" : "pointer",
    outline: focused ? "2px solid var(--focus-ring)" : "none",
    outlineOffset: 2,
    transition: "transform 90ms ease-out",
    transform: pressed && !disabled ? "scale(.94)" : "none",
    ...style,
  };
  const discStyle = {
    width: "100%",
    height: "100%",
    borderRadius: "var(--radius-round)",
    background: pressed && !disabled ? "var(--accent-200)" : "var(--paper)",
    boxShadow: "inset 0 0 0 1px rgba(45,43,43,.18)",
  };
  return (
    <button
      type="button"
      aria-label={label}
      aria-disabled={disabled || undefined}
      disabled={disabled}
      onClick={disabled ? undefined : onPress}
      onPointerDown={() => setPressed(true)}
      onPointerUp={() => setPressed(false)}
      onPointerLeave={() => setPressed(false)}
      onFocus={() => setFocused(true)}
      onBlur={() => setFocused(false)}
      style={shutterStyle}
      {...rest}
    >
      <span style={discStyle} />
    </button>
  );
}
