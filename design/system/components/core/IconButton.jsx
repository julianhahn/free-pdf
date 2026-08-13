import React from "react";
import { Icon } from "./Icon.jsx";

/* 36 x 36 drawn, 44 pt tappable. Outlined or bare. */
export function IconButton({ icon, label, outlined = false, disabled = false, onClick, size = 20, style, ...rest }) {
  const [state, setState] = React.useState("rest");
  const iconButtonStyle = {
    width: "var(--touch-min)",
    height: "var(--touch-min)",
    display: "grid",
    placeItems: "center",
    padding: 0,
    background: "transparent",
    border: "none",
    cursor: disabled ? "default" : "pointer",
    color: disabled ? "var(--disabled-text)" : undefined,
    outline: state === "focus" ? "2px solid var(--focus-ring)" : "none",
    outlineOffset: 2,
    ...style,
  };
  const boxStyle = {
    width: "var(--icon-button)",
    height: "var(--icon-button)",
    display: "grid",
    placeItems: "center",
    borderRadius: "var(--radius-md)",
    border: outlined ? `1px solid ${disabled ? "var(--disabled-border)" : "var(--divider)"}` : "1px solid transparent",
    background: state === "press" ? "var(--press-neutral)" : state === "hover" ? "var(--hover-neutral)" : "transparent",
    transition: "background 120ms linear",
  };
  return (
    <button
      type="button"
      aria-label={label}
      disabled={disabled}
      onClick={disabled ? undefined : onClick}
      onPointerEnter={() => !disabled && setState("hover")}
      onPointerLeave={() => setState("rest")}
      onPointerDown={() => !disabled && setState("press")}
      onPointerUp={() => !disabled && setState("hover")}
      onFocus={() => !disabled && setState("focus")}
      onBlur={() => setState("rest")}
      style={iconButtonStyle}
      {...rest}
    >
      <span style={boxStyle}>
        <Icon name={icon} size={size} />
      </span>
    </button>
  );
}
