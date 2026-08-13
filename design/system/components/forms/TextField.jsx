import React from "react";

/* The one text field in the app: the name for the shared copy. Outlined, min height 36. */
export function TextField({ label, value, placeholder, onChange, suffix, disabled = false, style, ...rest }) {
  const [focused, setFocused] = React.useState(false);
  return (
    <label style={{ display: "block", ...style }}>
      {label ? (
        <span style={{ display: "block", font: `var(--weight-body) var(--text-meta)/1.4 var(--font-body)`, color: "var(--text-muted)", marginBottom: "var(--space-1)" }}>{label}</span>
      ) : null}
      <span
        style={{
          display: "flex",
          alignItems: "center",
          gap: "var(--space-1)",
          minHeight: "var(--input-min-h)",
          padding: "0 var(--space-2)",
          border: `1px solid ${focused ? "var(--accent)" : "var(--divider)"}`,
          borderRadius: "var(--radius-md)",
          outline: focused ? "2px solid var(--focus-ring)" : "none",
          outlineOffset: 2,
          opacity: disabled ? "var(--disabled-opacity)" : 1,
        }}
      >
        <input
          value={value}
          placeholder={placeholder}
          disabled={disabled}
          onChange={(e) => onChange && onChange(e.target.value)}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
          style={{
            flex: 1,
            minWidth: 0,
            border: "none",
            background: "transparent",
            color: "var(--text)",
            font: `var(--weight-body) var(--text-control)/1.4 var(--font-body)`,
            padding: "var(--space-2) 0",
            outline: "none",
          }}
          {...rest}
        />
        {suffix ? <span style={{ font: `var(--weight-body) var(--text-control)/1.4 var(--font-body)`, color: "var(--text-muted)" }}>{suffix}</span> : null}
      </span>
    </label>
  );
}
