/* @ds-bundle: {"format":4,"namespace":"FreePDFDesignSystem_43ff31","components":[{"name":"Button","sourcePath":"components/core/Button.jsx"},{"name":"Icon","sourcePath":"components/core/Icon.jsx"},{"name":"IconButton","sourcePath":"components/core/IconButton.jsx"},{"name":"SectionLabel","sourcePath":"components/core/SectionLabel.jsx"},{"name":"Shutter","sourcePath":"components/core/Shutter.jsx"},{"name":"Tag","sourcePath":"components/core/Tag.jsx"},{"name":"PageCounter","sourcePath":"components/document/PageCounter.jsx"},{"name":"PageImage","sourcePath":"components/document/PageImage.jsx"},{"name":"Viewfinder","sourcePath":"components/document/Viewfinder.jsx"},{"name":"ConfirmDialog","sourcePath":"components/feedback/ConfirmDialog.jsx"},{"name":"EmptyState","sourcePath":"components/feedback/EmptyState.jsx"},{"name":"ErrorLine","sourcePath":"components/feedback/ErrorLine.jsx"},{"name":"ProgressLine","sourcePath":"components/feedback/ProgressLine.jsx"},{"name":"Slider","sourcePath":"components/forms/Slider.jsx"},{"name":"Switch","sourcePath":"components/forms/Switch.jsx"},{"name":"TextField","sourcePath":"components/forms/TextField.jsx"},{"name":"MenuList","sourcePath":"components/lists/MenuList.jsx"},{"name":"ScanRow","sourcePath":"components/lists/ScanRow.jsx"}],"sourceHashes":{"components/core/Button.jsx":"fd3c6abb9bd4","components/core/Icon.jsx":"b74342f2e691","components/core/IconButton.jsx":"6d68c7df1548","components/core/SectionLabel.jsx":"ec0c3b433dfb","components/core/Shutter.jsx":"1e2bf61ed86e","components/core/Tag.jsx":"aa8536d24fc9","components/document/PageCounter.jsx":"162cc90271b0","components/document/PageImage.jsx":"93dfdce4e89e","components/document/Viewfinder.jsx":"ae739dfcebbd","components/feedback/ConfirmDialog.jsx":"c35958bb9db1","components/feedback/EmptyState.jsx":"b9fd823dce22","components/feedback/ErrorLine.jsx":"564017b318bd","components/feedback/ProgressLine.jsx":"18fcacb330dd","components/forms/Slider.jsx":"70199bef903c","components/forms/Switch.jsx":"f586d2fa9124","components/forms/TextField.jsx":"c43441be4c1a","components/lists/MenuList.jsx":"ad7bc472ef11","components/lists/ScanRow.jsx":"8f45897a356f","ui_kits/iphone/AdjustScreen.jsx":"e55e52b55d43","ui_kits/iphone/App.jsx":"556b55ecdb49","ui_kits/iphone/CameraScreen.jsx":"e337dc548fd8","ui_kits/iphone/Chrome.jsx":"dff1898ea212","ui_kits/iphone/DoneScreen.jsx":"1afab0f42745","ui_kits/iphone/PagesScreen.jsx":"76a81c490f57","ui_kits/iphone/ScansScreen.jsx":"240d489a8dd5"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.FreePDFDesignSystem_43ff31 = window.FreePDFDesignSystem_43ff31 || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/core/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const variantStyle = {
  primary: {
    color: "var(--accent)",
    borderColor: "var(--accent)"
  },
  secondary: {
    color: "var(--text)",
    borderColor: "var(--divider)"
  },
  destructive: {
    color: "var(--destructive)",
    borderColor: "var(--destructive)"
  },
  ghost: {
    color: "var(--accent)",
    borderColor: "transparent"
  }
};

/* Outlined, never filled. Full width when it is the screen's action. */
function Button({
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
  const tint = state === "press" ? variant === "secondary" ? "var(--press-neutral)" : "var(--press-accent)" : state === "hover" ? variant === "secondary" ? "var(--hover-neutral)" : "var(--hover-accent)" : "transparent";
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
    ...style
  };
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    disabled: disabled || busy,
    "aria-busy": busy || undefined,
    onClick: disabled || busy ? undefined : onClick,
    onPointerEnter: () => !disabled && setState("hover"),
    onPointerLeave: () => setState("rest"),
    onPointerDown: () => !disabled && setState("press"),
    onPointerUp: () => !disabled && setState("hover"),
    onFocus: () => !disabled && setState("focus"),
    onBlur: () => setState("rest"),
    style: buttonStyle
  }, rest), children);
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Button.jsx", error: String((e && e.message) || e) }); }

// components/core/Icon.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const LUCIDE = "https://unpkg.com/lucide-static@0.544.0/icons/";

/* Icons are Lucide, recoloured through a CSS mask so they always carry the
   current text/accent colour. See readme.md > Iconography (substitution flagged). */
function Icon({
  name,
  size = 20,
  color = "currentColor",
  strokeAlign,
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("span", _extends({
    "aria-hidden": "true",
    style: {
      display: "inline-block",
      width: size,
      height: size,
      flex: "0 0 auto",
      background: color,
      WebkitMaskImage: `url(${LUCIDE}${name}.svg)`,
      maskImage: `url(${LUCIDE}${name}.svg)`,
      WebkitMaskRepeat: "no-repeat",
      maskRepeat: "no-repeat",
      WebkitMaskPosition: "center",
      maskPosition: "center",
      WebkitMaskSize: "contain",
      maskSize: "contain",
      ...style
    }
  }, rest));
}
Object.assign(__ds_scope, { Icon });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Icon.jsx", error: String((e && e.message) || e) }); }

// components/core/IconButton.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/* 36 x 36 drawn, 44 pt tappable. Outlined or bare. */
function IconButton({
  icon,
  label,
  outlined = false,
  disabled = false,
  onClick,
  size = 20,
  style,
  ...rest
}) {
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
    opacity: disabled ? "var(--disabled-opacity)" : 1,
    outline: state === "focus" ? "2px solid var(--focus-ring)" : "none",
    outlineOffset: 2,
    ...style
  };
  const boxStyle = {
    width: "var(--icon-button)",
    height: "var(--icon-button)",
    display: "grid",
    placeItems: "center",
    borderRadius: "var(--radius-md)",
    border: outlined ? "1px solid var(--divider)" : "1px solid transparent",
    background: state === "press" ? "var(--press-neutral)" : state === "hover" ? "var(--hover-neutral)" : "transparent",
    transition: "background 120ms linear"
  };
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    "aria-label": label,
    disabled: disabled,
    onClick: disabled ? undefined : onClick,
    onPointerEnter: () => !disabled && setState("hover"),
    onPointerLeave: () => setState("rest"),
    onPointerDown: () => !disabled && setState("press"),
    onPointerUp: () => !disabled && setState("hover"),
    onFocus: () => !disabled && setState("focus"),
    onBlur: () => setState("rest"),
    style: iconButtonStyle
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: boxStyle
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: size
  })));
}
Object.assign(__ds_scope, { IconButton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/IconButton.jsx", error: String((e && e.message) || e) }); }

// components/core/SectionLabel.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/* h6: 13 px uppercase, 0.08em. The only all-caps in the system besides the kicker. */
function SectionLabel({
  children,
  style,
  ...rest
}) {
  const sectionLabelStyle = {
    font: `var(--weight-heading) var(--text-h6)/var(--leading-heading) var(--font-heading)`,
    letterSpacing: "var(--tracking-h6)",
    textTransform: "uppercase",
    color: "var(--text-muted)",
    margin: 0,
    ...style
  };
  return /*#__PURE__*/React.createElement("div", _extends({
    style: sectionLabelStyle
  }, rest), children);
}
Object.assign(__ds_scope, { SectionLabel });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/SectionLabel.jsx", error: String((e && e.message) || e) }); }

// components/core/Shutter.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/* The shutter. 72 px, stroke first: a 2 px accent ring, a gap in the ground, and a
   solid paper disc inside it — the sheet you are about to photograph. The disc is
   the answer to "a hairline on a dark viewfinder is not a control": it is found by
   its light mass, not by its outline. Disabled while the photo is being written,
   which is the rule that makes one press one page. */
function Shutter({
  disabled = false,
  onPress,
  label = "Photograph page",
  style,
  ...rest
}) {
  const [pressed, setPressed] = React.useState(false);
  const [focused, setFocused] = React.useState(false);
  const shutterStyle = {
    width: "var(--shutter-size)",
    height: "var(--shutter-size)",
    borderRadius: "var(--radius-round)",
    border: "var(--shutter-ring) solid var(--accent)",
    background: "transparent",
    padding: "var(--shutter-gap)",
    display: "grid",
    placeItems: "center",
    cursor: disabled ? "default" : "pointer",
    opacity: disabled ? "var(--disabled-opacity)" : 1,
    outline: focused ? "2px solid var(--focus-ring)" : "none",
    outlineOffset: 2,
    transition: "transform 90ms ease-out",
    transform: pressed && !disabled ? "scale(.94)" : "none",
    ...style
  };
  const discStyle = {
    width: "100%",
    height: "100%",
    borderRadius: "var(--radius-round)",
    background: pressed && !disabled ? "var(--accent-200)" : "var(--paper)",
    boxShadow: "inset 0 0 0 1px rgba(45,43,43,.18)"
  };
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    "aria-label": label,
    "aria-disabled": disabled || undefined,
    disabled: disabled,
    onClick: disabled ? undefined : onPress,
    onPointerDown: () => setPressed(true),
    onPointerUp: () => setPressed(false),
    onPointerLeave: () => setPressed(false),
    onFocus: () => setFocused(true),
    onBlur: () => setFocused(false),
    style: shutterStyle
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: discStyle
  }));
}
Object.assign(__ds_scope, { Shutter });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Shutter.jsx", error: String((e && e.message) || e) }); }

// components/core/Tag.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/* Small chip, radius-sm. Carries a page's state on a thumbnail, never a decoration. */
function Tag({
  children,
  tone = "neutral",
  style,
  ...rest
}) {
  const toneStyle = tone === "accent" ? {
    color: "var(--accent-700)",
    borderColor: "var(--accent)",
    background: "var(--accent-100)"
  } : tone === "quiet" ? {
    color: "var(--text-muted)",
    borderColor: "var(--divider)",
    background: "transparent"
  } : {
    color: "var(--text)",
    borderColor: "var(--divider)",
    background: "var(--surface)"
  };
  const tagStyle = {
    display: "inline-block",
    font: `var(--weight-body) var(--text-meta)/1.4 var(--font-body)`,
    fontVariantNumeric: "tabular-nums",
    padding: "1px var(--space-1)",
    border: "1px solid",
    borderRadius: "var(--radius-sm)",
    ...toneStyle,
    ...style
  };
  return /*#__PURE__*/React.createElement("span", _extends({
    style: tagStyle
  }, rest), children);
}
Object.assign(__ds_scope, { Tag });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Tag.jsx", error: String((e && e.message) || e) }); }

// components/document/PageCounter.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/* "Page 3 of 12" over a moving picture. Tabular figures so it does not shuffle
   while it counts, and a solid ground behind it because a hairline caption
   disappears on a viewfinder. */
function PageCounter({
  children,
  onDark = false,
  style,
  ...rest
}) {
  const counterStyle = {
    display: "inline-block",
    font: `var(--weight-heading) var(--text-control)/1.2 var(--font-heading)`,
    letterSpacing: "var(--tracking-heading)",
    fontVariantNumeric: "tabular-nums",
    padding: "var(--space-1) var(--space-2)",
    borderRadius: "var(--radius-sm)",
    color: onDark ? "var(--neutral-100)" : "var(--text)",
    background: onDark ? "rgba(19,18,17,.66)" : "var(--surface)",
    border: `1px solid ${onDark ? "rgba(248,244,244,.22)" : "var(--divider)"}`,
    backdropFilter: onDark ? "blur(6px)" : "none",
    ...style
  };
  return /*#__PURE__*/React.createElement("span", _extends({
    style: counterStyle
  }, rest), children);
}
Object.assign(__ds_scope, { PageCounter });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/document/PageCounter.jsx", error: String((e && e.message) || e) }); }

// components/document/PageImage.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/* A scanned page. The app is full of these, so the frame is the system's one
   recurring shape: a paper ground, a hairline, and nothing else.
   No src yet -> the ruled placeholder stands in (see readme.md > Imagery).
   state="refused" -> the failure card that replaces an image. */
function PageImage({
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
    ...style
  };
  const ruled = {
    position: "absolute",
    inset: "12% 14%",
    background: "repeating-linear-gradient(to bottom, color-mix(in srgb, var(--neutral-900) 26%, transparent) 0 1px, transparent 1px 9px)",
    opacity: 0.5,
    maskImage: "linear-gradient(to bottom, #000 0 62%, transparent 62% 100%)",
    WebkitMaskImage: "linear-gradient(to bottom, #000 0 62%, transparent 62% 100%)"
  };
  return /*#__PURE__*/React.createElement("div", _extends({
    role: onClick ? "button" : undefined,
    "aria-label": onClick ? label : undefined,
    onClick: onClick,
    style: frameStyle
  }, rest), state === "refused" ? /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      inset: 0,
      display: "grid",
      placeItems: "center",
      gap: "var(--space-2)",
      alignContent: "center",
      padding: "var(--space-3)",
      background: "var(--surface)",
      textAlign: "center"
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "file-x",
    size: 22,
    color: "var(--destructive)"
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      font: `var(--weight-body) var(--text-sub)/var(--leading-body) var(--font-body)`,
      color: "var(--destructive)"
    }
  }, refusedText)) : src ? /*#__PURE__*/React.createElement("img", {
    src: src,
    alt: alt,
    style: {
      width: "100%",
      height: "100%",
      objectFit: "cover",
      filter: grey ? "grayscale(1)" : "none"
    }
  }) : /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      inset: "7% 9%",
      border: "1px solid color-mix(in srgb, var(--neutral-900) 12%, transparent)"
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: ruled
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      inset: "12% 14% auto",
      height: 3,
      background: "color-mix(in srgb, var(--neutral-900) 42%, transparent)",
      width: "42%"
    }
  })), label ? /*#__PURE__*/React.createElement("span", {
    style: {
      position: "absolute",
      left: 0,
      bottom: 0,
      padding: "1px var(--space-1)",
      background: "var(--bg)",
      borderTop: "1px solid var(--divider)",
      borderRight: "1px solid var(--divider)",
      font: `var(--weight-body) var(--text-meta)/1.4 var(--font-body)`,
      fontVariantNumeric: "tabular-nums",
      color: "var(--text-muted)"
    }
  }, label) : null);
}
Object.assign(__ds_scope, { PageImage });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/document/PageImage.jsx", error: String((e && e.message) || e) }); }

// components/document/Viewfinder.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/* The live preview, 3:4 portrait. The frame is four corner marks in accent, not a
   full hairline rectangle: on a dark moving picture a thin continuous line reads as
   part of the scene, corners read as an instrument. */
function Viewfinder({
  children,
  note,
  corners = true,
  style,
  ...rest
}) {
  const stageStyle = {
    position: "relative",
    aspectRatio: "var(--page-ratio)",
    width: "100%",
    background: "var(--viewfinder)",
    borderRadius: "var(--radius-md)",
    overflow: "hidden",
    ...style
  };
  const corner = pos => ({
    position: "absolute",
    width: 26,
    height: 26,
    borderColor: "var(--accent)",
    borderStyle: "solid",
    borderWidth: 0,
    ...pos
  });
  return /*#__PURE__*/React.createElement("div", _extends({
    style: stageStyle
  }, rest), children, corners ? /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("span", {
    style: corner({
      top: "6%",
      left: "6%",
      borderTopWidth: 2,
      borderLeftWidth: 2
    })
  }), /*#__PURE__*/React.createElement("span", {
    style: corner({
      top: "6%",
      right: "6%",
      borderTopWidth: 2,
      borderRightWidth: 2
    })
  }), /*#__PURE__*/React.createElement("span", {
    style: corner({
      bottom: "6%",
      left: "6%",
      borderBottomWidth: 2,
      borderLeftWidth: 2
    })
  }), /*#__PURE__*/React.createElement("span", {
    style: corner({
      bottom: "6%",
      right: "6%",
      borderBottomWidth: 2,
      borderRightWidth: 2
    })
  })) : null, note ? /*#__PURE__*/React.createElement("span", {
    style: {
      position: "absolute",
      left: "var(--space-3)",
      right: "var(--space-3)",
      bottom: "var(--space-3)",
      font: `var(--weight-body) var(--text-meta)/1.45 var(--font-body)`,
      color: "rgba(248,244,244,.72)"
    }
  }, note) : null);
}
Object.assign(__ds_scope, { Viewfinder });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/document/Viewfinder.jsx", error: String((e && e.message) || e) }); }

// components/feedback/ConfirmDialog.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/* Surface, radius-lg, shadow-lg — the only raised thing in the system. Title (h4),
   body, then the actions right-aligned: destructive first, secondary Cancel.
   All three deletions ask, always. */
function ConfirmDialog({
  title,
  body,
  confirmLabel,
  cancelLabel = "Cancel",
  onConfirm,
  onCancel,
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    role: "dialog",
    "aria-modal": "true",
    "aria-label": title,
    style: {
      position: "absolute",
      inset: 0,
      display: "grid",
      placeItems: "center",
      padding: "var(--space-4)",
      background: "color-mix(in srgb, var(--neutral-900) 38%, transparent)",
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("div", {
    style: {
      width: "100%",
      maxWidth: 320,
      background: "var(--surface)",
      border: "1px solid var(--divider)",
      borderRadius: "var(--radius-lg)",
      boxShadow: "var(--shadow-lg)",
      padding: "var(--space-4)"
    }
  }, /*#__PURE__*/React.createElement("h2", {
    style: {
      margin: 0,
      font: `var(--weight-heading) var(--text-h4)/var(--leading-heading) var(--font-heading)`,
      letterSpacing: "var(--tracking-heading)"
    }
  }, title), /*#__PURE__*/React.createElement("p", {
    style: {
      margin: "var(--space-2) 0 var(--space-4)",
      font: `var(--weight-body) var(--text-body)/var(--leading-body) var(--font-body)`,
      fontVariantNumeric: "tabular-nums",
      textWrap: "pretty"
    }
  }, body), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      justifyContent: "flex-end",
      gap: "var(--space-2)",
      flexWrap: "wrap"
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Button, {
    variant: "destructive",
    onClick: onConfirm
  }, confirmLabel), /*#__PURE__*/React.createElement(__ds_scope.Button, {
    variant: "secondary",
    onClick: onCancel
  }, cancelLabel))));
}
Object.assign(__ds_scope, { ConfirmDialog });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/ConfirmDialog.jsx", error: String((e && e.message) || e) }); }

// components/feedback/EmptyState.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/* Icon, title, body. Shown when there are no scan folders. Centred, quiet, and the
   icon is a stack of sheets — the app's own subject rather than a mascot. */
function EmptyState({
  icon = "files",
  title,
  body,
  action,
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      display: "grid",
      justifyItems: "center",
      gap: "var(--space-3)",
      textAlign: "center",
      padding: "var(--space-8) var(--space-4)",
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 30,
    color: "var(--accent)"
  }), /*#__PURE__*/React.createElement("h2", {
    style: {
      margin: 0,
      font: `var(--weight-heading) var(--text-h4)/var(--leading-heading) var(--font-heading)`,
      letterSpacing: "var(--tracking-heading)"
    }
  }, title), /*#__PURE__*/React.createElement("p", {
    style: {
      margin: 0,
      maxWidth: 30 * 8,
      font: `var(--weight-body) var(--text-body)/var(--leading-body) var(--font-body)`,
      color: "var(--text-muted)",
      textWrap: "pretty"
    }
  }, body), action);
}
Object.assign(__ds_scope, { EmptyState });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/EmptyState.jsx", error: String((e && e.message) || e) }); }

// components/feedback/ErrorLine.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/* One line, destructive colour, above the content, cleared on the next reload.
   The text is the engine's own finished sentence — the client never rewrites it.
   Marked by a rule to its left, because this theme never leans on colour alone. */
function ErrorLine({
  children,
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("p", _extends({
    role: "status",
    style: {
      margin: 0,
      paddingLeft: "var(--space-2)",
      borderLeft: "2px solid var(--destructive)",
      color: "var(--destructive)",
      font: `var(--weight-body) var(--text-sub)/var(--leading-body) var(--font-body)`,
      fontVariantNumeric: "tabular-nums",
      textWrap: "pretty",
      ...style
    }
  }, rest), children);
}
Object.assign(__ds_scope, { ErrorLine });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/ErrorLine.jsx", error: String((e && e.message) || e) }); }

// components/feedback/ProgressLine.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/* A line, a bar, a note. Two of them exist: the drain, and apply-to-all.
   The bar is a 3 px rule that fills with accent — no radius, no gradient. */
function ProgressLine({
  line,
  note,
  value = 0,
  max = 100,
  style,
  ...rest
}) {
  const pct = Math.max(0, Math.min(100, value / max * 100));
  return /*#__PURE__*/React.createElement("div", _extends({
    style: style
  }, rest), /*#__PURE__*/React.createElement("div", {
    style: {
      font: `var(--weight-body) var(--text-sub)/var(--leading-body) var(--font-body)`,
      fontVariantNumeric: "tabular-nums"
    }
  }, line), /*#__PURE__*/React.createElement("div", {
    role: "progressbar",
    "aria-valuenow": value,
    "aria-valuemax": max,
    "aria-label": typeof line === "string" ? line : undefined,
    style: {
      height: 3,
      background: "var(--divider)",
      margin: "var(--space-1) 0"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: `${pct}%`,
      height: "100%",
      background: "var(--accent)",
      transition: "width 240ms linear"
    }
  })), note ? /*#__PURE__*/React.createElement("div", {
    style: {
      font: `var(--weight-body) var(--text-meta)/1.45 var(--font-body)`,
      color: "var(--text-muted)"
    }
  }, note) : null);
}
Object.assign(__ds_scope, { ProgressLine });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/ProgressLine.jsx", error: String((e && e.message) || e) }); }

// components/forms/Slider.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/* 1 px track, 17 px round thumb with an accent border. It opens on the value the
   engine suggested; the value prints beside the label in destructive-weight accent,
   tabular figures, and the two ends are labelled at meta size. */
function Slider({
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
  const pct = (value - min) / (max - min) * 100;
  const trackWrapStyle = {
    position: "relative",
    height: "var(--touch-min)",
    display: "flex",
    alignItems: "center"
  };
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      opacity: disabled ? "var(--disabled-opacity)" : 1,
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      justifyContent: "space-between",
      alignItems: "baseline",
      gap: "var(--space-2)"
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      font: `var(--weight-heading) var(--text-control)/1.2 var(--font-heading)`,
      letterSpacing: "var(--tracking-heading)"
    }
  }, label), /*#__PURE__*/React.createElement("span", {
    style: {
      font: `var(--weight-body) var(--text-control)/1.2 var(--font-body)`,
      color: "var(--destructive)",
      fontVariantNumeric: "tabular-nums"
    }
  }, value, unit)), /*#__PURE__*/React.createElement("div", {
    style: trackWrapStyle
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      left: 0,
      right: 0,
      height: "var(--slider-track)",
      background: "var(--divider-strong)"
    }
  }), typeof suggested === "number" ? /*#__PURE__*/React.createElement("div", {
    title: "the engine's suggestion",
    style: {
      position: "absolute",
      left: `${(suggested - min) / (max - min) * 100}%`,
      width: 1,
      height: 9,
      background: "var(--divider-strong)",
      transform: "translateX(-50%)"
    }
  }) : null, /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      left: `${pct}%`,
      transform: "translateX(-50%)",
      width: "var(--slider-thumb)",
      height: "var(--slider-thumb)",
      borderRadius: "var(--radius-round)",
      background: "var(--bg)",
      border: "1px solid var(--accent)",
      boxShadow: "var(--shadow-sm)",
      pointerEvents: "none"
    }
  }), /*#__PURE__*/React.createElement("input", {
    type: "range",
    "aria-label": label,
    min: min,
    max: max,
    step: step,
    value: value,
    disabled: disabled,
    onChange: e => onChange && onChange(Number(e.target.value)),
    style: {
      position: "absolute",
      inset: 0,
      width: "100%",
      height: "100%",
      margin: 0,
      opacity: 0,
      cursor: disabled ? "default" : "pointer"
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      justifyContent: "space-between",
      font: `var(--weight-body) var(--text-meta)/1.4 var(--font-body)`,
      color: "var(--text-muted)"
    }
  }, /*#__PURE__*/React.createElement("span", null, minLabel), /*#__PURE__*/React.createElement("span", null, maxLabel)));
}
Object.assign(__ds_scope, { Slider });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Slider.jsx", error: String((e && e.message) || e) }); }

// components/forms/Switch.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/* 42 x 24 outlined track, 16 knob, travel 3 to 21. Off: knob at text 45%.
   On: accent border, accent knob. Drawn 24 high, tappable 44. */
function Switch({
  checked = false,
  onChange,
  label,
  sub,
  disabled = false,
  style,
  ...rest
}) {
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
    opacity: disabled ? "var(--disabled-opacity)" : 1,
    ...style
  };
  const trackStyle = {
    position: "relative",
    width: "var(--switch-w)",
    height: "var(--switch-h)",
    flex: "0 0 auto",
    borderRadius: 999,
    border: `1px solid ${checked ? "var(--accent)" : "var(--divider-strong)"}`,
    background: checked ? "var(--hover-accent)" : "transparent",
    outline: focused ? "2px solid var(--focus-ring)" : "none",
    outlineOffset: 2,
    transition: "border-color 140ms linear, background 140ms linear"
  };
  const knobStyle = {
    position: "absolute",
    top: "50%",
    left: checked ? "var(--switch-travel-end)" : "var(--switch-travel-start)",
    transform: "translate(-0%, -50%)",
    width: "var(--switch-knob)",
    height: "var(--switch-knob)",
    borderRadius: "var(--radius-round)",
    background: checked ? "var(--accent)" : "color-mix(in srgb, var(--text) 45%, transparent)",
    transition: "left 140ms ease-out, background 140ms linear"
  };
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    role: "switch",
    "aria-checked": checked,
    "aria-label": label,
    disabled: disabled,
    onClick: disabled ? undefined : () => onChange && onChange(!checked),
    onFocus: () => setFocused(true),
    onBlur: () => setFocused(false),
    style: rowStyle
  }, rest), /*#__PURE__*/React.createElement("span", null, /*#__PURE__*/React.createElement("span", {
    style: {
      font: `var(--weight-heading) var(--text-control)/1.2 var(--font-heading)`,
      letterSpacing: "var(--tracking-heading)",
      display: "block"
    }
  }, label), sub ? /*#__PURE__*/React.createElement("span", {
    style: {
      font: `var(--weight-body) var(--text-meta)/1.4 var(--font-body)`,
      color: "var(--text-muted)"
    }
  }, sub) : null), /*#__PURE__*/React.createElement("span", {
    style: trackStyle
  }, /*#__PURE__*/React.createElement("span", {
    style: knobStyle
  })));
}
Object.assign(__ds_scope, { Switch });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Switch.jsx", error: String((e && e.message) || e) }); }

// components/forms/TextField.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/* The one text field in the app: the name for the shared copy. Outlined, min height 36. */
function TextField({
  label,
  value,
  placeholder,
  onChange,
  suffix,
  disabled = false,
  style,
  ...rest
}) {
  const [focused, setFocused] = React.useState(false);
  return /*#__PURE__*/React.createElement("label", {
    style: {
      display: "block",
      ...style
    }
  }, label ? /*#__PURE__*/React.createElement("span", {
    style: {
      display: "block",
      font: `var(--weight-body) var(--text-meta)/1.4 var(--font-body)`,
      color: "var(--text-muted)",
      marginBottom: "var(--space-1)"
    }
  }, label) : null, /*#__PURE__*/React.createElement("span", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: "var(--space-1)",
      minHeight: "var(--input-min-h)",
      padding: "0 var(--space-2)",
      border: `1px solid ${focused ? "var(--accent)" : "var(--divider)"}`,
      borderRadius: "var(--radius-md)",
      outline: focused ? "2px solid var(--focus-ring)" : "none",
      outlineOffset: 2,
      opacity: disabled ? "var(--disabled-opacity)" : 1
    }
  }, /*#__PURE__*/React.createElement("input", _extends({
    value: value,
    placeholder: placeholder,
    disabled: disabled,
    onChange: e => onChange && onChange(e.target.value),
    onFocus: () => setFocused(true),
    onBlur: () => setFocused(false),
    style: {
      flex: 1,
      minWidth: 0,
      border: "none",
      background: "transparent",
      color: "var(--text)",
      font: `var(--weight-body) var(--text-control)/1.4 var(--font-body)`,
      padding: "var(--space-2) 0",
      outline: "none"
    }
  }, rest)), suffix ? /*#__PURE__*/React.createElement("span", {
    style: {
      font: `var(--weight-body) var(--text-control)/1.4 var(--font-body)`,
      color: "var(--text-muted)"
    }
  }, suffix) : null));
}
Object.assign(__ds_scope, { TextField });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/TextField.jsx", error: String((e && e.message) || e) }); }

// components/lists/MenuList.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/* The Page menu, presented the platform's way but drawn here: surface, radius-lg,
   hairline-separated rows. A destructive item carries its words, never a colour alone. */
function MenuList({
  title,
  items = [],
  onSelect,
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    role: "menu",
    style: {
      background: "var(--surface)",
      border: "1px solid var(--divider)",
      borderRadius: "var(--radius-lg)",
      boxShadow: "var(--shadow-lg)",
      overflow: "hidden",
      minWidth: 232,
      ...style
    }
  }, rest), title ? /*#__PURE__*/React.createElement("div", {
    style: {
      padding: "var(--space-2) var(--space-3)",
      borderBottom: "1px solid var(--divider)",
      font: `var(--weight-heading) var(--text-h6)/1.2 var(--font-heading)`,
      letterSpacing: "var(--tracking-h6)",
      textTransform: "uppercase",
      color: "var(--text-muted)"
    }
  }, title) : null, items.map((item, i) => /*#__PURE__*/React.createElement("button", {
    key: item.label,
    type: "button",
    role: "menuitem",
    disabled: item.disabled,
    onClick: () => onSelect && onSelect(item),
    style: {
      display: "flex",
      alignItems: "center",
      gap: "var(--space-2)",
      width: "100%",
      minHeight: "var(--touch-min)",
      padding: "var(--space-2) var(--space-3)",
      background: "transparent",
      border: "none",
      borderTop: i === 0 ? "none" : "1px solid var(--divider)",
      color: item.destructive ? "var(--destructive)" : "var(--text)",
      font: `var(--weight-body) var(--text-control)/1.3 var(--font-body)`,
      textAlign: "left",
      opacity: item.disabled ? "var(--disabled-opacity)" : 1,
      cursor: item.disabled ? "default" : "pointer"
    }
  }, item.icon ? /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: item.icon,
    size: 17,
    color: item.destructive ? "var(--destructive)" : "var(--accent)"
  }) : null, item.label)));
}
Object.assign(__ds_scope, { MenuList });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/lists/MenuList.jsx", error: String((e && e.message) || e) }); }

// components/lists/ScanRow.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/* One scan in the list. A whole-row button: date title, derived subtitle, accent
   chevron, hairline underneath. No fill, no card. Swiped left it reveals a 96 px
   Delete action in destructive colour.
   `thumb` is an intentional addition (readme.md): the first page, 30 px wide, so the
   list is not a wall of dates. Pass thumb={false} for the plain row. */
function ScanRow({
  title,
  subtitle,
  thumb = true,
  thumbSrc,
  swiped = false,
  deleteLabel = "Delete",
  onPress,
  onDelete,
  style,
  ...rest
}) {
  const [pressed, setPressed] = React.useState(false);
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      position: "relative",
      overflow: "hidden",
      borderBottom: "1px solid var(--divider)",
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("button", {
    type: "button",
    onClick: onDelete,
    style: {
      position: "absolute",
      top: 0,
      right: 0,
      bottom: 0,
      width: "var(--swipe-action-w)",
      background: "transparent",
      border: "none",
      borderLeft: "1px solid var(--destructive)",
      color: "var(--destructive)",
      font: `var(--weight-heading) var(--text-control)/1.2 var(--font-heading)`,
      letterSpacing: "var(--tracking-heading)",
      cursor: "pointer"
    }
  }, deleteLabel), /*#__PURE__*/React.createElement("button", {
    type: "button",
    onClick: onPress,
    onPointerDown: () => setPressed(true),
    onPointerUp: () => setPressed(false),
    onPointerLeave: () => setPressed(false),
    style: {
      position: "relative",
      display: "flex",
      alignItems: "center",
      gap: "var(--space-3)",
      width: "100%",
      minHeight: "var(--touch-min)",
      padding: "var(--space-3) 0",
      background: pressed ? "var(--press-row)" : "var(--bg)",
      border: "none",
      textAlign: "left",
      cursor: "pointer",
      transform: swiped ? "translateX(calc(-1 * var(--swipe-action-w)))" : "none",
      transition: "transform 180ms ease-out, background 120ms linear"
    }
  }, thumb ? /*#__PURE__*/React.createElement(__ds_scope.PageImage, {
    src: thumbSrc,
    style: {
      width: 30,
      flex: "0 0 auto"
    }
  }) : null, /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      display: "block",
      font: `var(--weight-heading) var(--text-row-title)/var(--leading-heading) var(--font-heading)`,
      letterSpacing: "var(--tracking-heading)",
      fontVariantNumeric: "tabular-nums"
    }
  }, title), /*#__PURE__*/React.createElement("span", {
    style: {
      display: "block",
      font: `var(--weight-body) var(--text-sub)/var(--leading-body) var(--font-body)`,
      color: "var(--text-muted)",
      fontVariantNumeric: "tabular-nums"
    }
  }, subtitle)), /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "chevron-right",
    size: 18,
    color: "var(--accent)"
  })));
}
Object.assign(__ds_scope, { ScanRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/lists/ScanRow.jsx", error: String((e && e.message) || e) }); }

// ui_kits/iphone/AdjustScreen.jsx
try { (() => {
const {
  PageImage,
  Slider,
  Switch,
  Button,
  SectionLabel,
  IconButton,
  ErrorLine,
  ProgressLine
} = window.FreePDFDesignSystem_43ff31;
const TOOLS = [{
  label: "Edges",
  icon: "scan"
}, {
  label: "Straighten",
  icon: "rotate-cw"
}, {
  label: "Brightness",
  icon: "sun"
}, {
  label: "Sharpen",
  icon: "wand-sparkles"
}, {
  label: "Crop",
  icon: "crop"
}, {
  label: "Turn",
  icon: "refresh-cw"
}];
function AdjustScreen({
  page = 3,
  onDone,
  onBack
}) {
  const [tool, setTool] = React.useState("Brightness");
  const [brightness, setBrightness] = React.useState(12);
  const [straighten, setStraighten] = React.useState(-2);
  const [grey, setGrey] = React.useState(false);
  const [all, setAll] = React.useState(false);
  const [running, setRunning] = React.useState(false);
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(AppBar, {
    title: `Adjust page ${page}`,
    back: true,
    onBack: onBack
  }), /*#__PURE__*/React.createElement(Screen, {
    footer: /*#__PURE__*/React.createElement(React.Fragment, null, running ? /*#__PURE__*/React.createElement(ProgressLine, {
      line: all ? "Applying to 40 pages…" : "Applying…",
      note: all ? "Keep the app open." : null,
      value: all ? 14 : 60,
      max: all ? 40 : 100
    }) : null, /*#__PURE__*/React.createElement(Button, {
      variant: "primary",
      fullWidth: true,
      busy: running,
      onClick: () => {
        setRunning(true);
        setTimeout(() => {
          setRunning(false);
          onDone();
        }, 900);
      }
    }, running ? all ? "Applying to 40 pages…" : "Applying…" : "Apply"), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        gap: "var(--space-2)"
      }
    }, /*#__PURE__*/React.createElement(Button, {
      variant: "secondary",
      style: {
        flex: 1
      },
      onClick: onBack
    }, "Cancel"), /*#__PURE__*/React.createElement(Button, {
      variant: "ghost",
      style: {
        flex: 1
      },
      onClick: () => {
        setBrightness(12);
        setStraighten(-2);
      }
    }, "Back to the suggestion")))
  }, /*#__PURE__*/React.createElement(PageImage, {
    grey: grey,
    style: {
      width: "62%",
      justifySelf: "center",
      filter: `brightness(${1 + brightness / 120})`,
      transform: `rotate(${straighten * 0.2}deg)`
    }
  }), tool === "Edges" ? /*#__PURE__*/React.createElement(ErrorLine, null, "The sheet fills the whole photo, so there is nothing to cut away.") : null, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: "var(--space-1)",
      overflow: "auto"
    }
  }, TOOLS.map(t => /*#__PURE__*/React.createElement("button", {
    key: t.label,
    type: "button",
    onClick: () => setTool(t.label),
    style: {
      display: "grid",
      justifyItems: "center",
      gap: 2,
      flex: "0 0 auto",
      minWidth: 56,
      minHeight: "var(--touch-min)",
      padding: "var(--space-1)",
      background: tool === t.label ? "var(--hover-accent)" : "transparent",
      border: `1px solid ${tool === t.label ? "var(--accent)" : "var(--divider)"}`,
      borderRadius: "var(--radius-md)",
      cursor: "pointer",
      color: tool === t.label ? "var(--accent-700)" : "var(--text)",
      font: "var(--weight-body) var(--text-meta)/1.3 var(--font-body)"
    }
  }, /*#__PURE__*/React.createElement(window.FreePDFDesignSystem_43ff31.Icon, {
    name: t.icon,
    size: 17,
    color: tool === t.label ? "var(--accent)" : "var(--text-muted)"
  }), t.label))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gap: "var(--space-2)"
    }
  }, /*#__PURE__*/React.createElement(SectionLabel, null, tool), tool === "Straighten" ? /*#__PURE__*/React.createElement(Slider, {
    label: "Straighten",
    value: straighten,
    min: -15,
    max: 15,
    unit: "\xB0",
    suggested: -2,
    minLabel: "\u221215\xB0",
    maxLabel: "15\xB0",
    onChange: setStraighten
  }) : /*#__PURE__*/React.createElement(Slider, {
    label: tool === "Brightness" ? "Brightness" : tool,
    value: brightness,
    min: -50,
    max: 50,
    suggested: 12,
    minLabel: "darker",
    maxLabel: "brighter",
    onChange: setBrightness
  }), /*#__PURE__*/React.createElement(Switch, {
    label: "Grey",
    checked: grey,
    onChange: setGrey
  }), /*#__PURE__*/React.createElement(Switch, {
    label: "Apply to all pages",
    sub: "Keep the app open.",
    checked: all,
    onChange: setAll
  }))));
}
Object.assign(window, {
  AdjustScreen
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/iphone/AdjustScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/iphone/App.jsx
try { (() => {
function App() {
  const [screen, setScreen] = React.useState("scans");
  const [theme, setTheme] = React.useState("light");
  React.useEffect(() => {
    document.documentElement.dataset.theme = theme;
  }, [theme]);
  const view = {
    scans: /*#__PURE__*/React.createElement(ScansScreen, {
      onOpen: () => setScreen("pages"),
      onNew: () => setScreen("camera")
    }),
    camera: /*#__PURE__*/React.createElement(CameraScreen, {
      onBack: () => setScreen("scans"),
      onFinish: () => setScreen("pages")
    }),
    pages: /*#__PURE__*/React.createElement(PagesScreen, {
      onBack: () => setScreen("scans"),
      onAdjust: () => setScreen("adjust"),
      onMakePdf: () => setScreen("done")
    }),
    adjust: /*#__PURE__*/React.createElement(AdjustScreen, {
      onBack: () => setScreen("pages"),
      onDone: () => setScreen("pages")
    }),
    done: /*#__PURE__*/React.createElement(DoneScreen, {
      onBack: () => setScreen("scans"),
      onChangePages: () => setScreen("pages")
    })
  }[screen];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gap: "var(--space-4)",
      justifyItems: "center"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: "relative",
      width: 390,
      height: 844,
      background: "var(--bg)",
      border: "1px solid var(--divider)",
      borderRadius: 40,
      overflow: "hidden",
      display: "grid",
      gridTemplateRows: "auto 1fr",
      boxShadow: "var(--shadow-md)"
    }
  }, /*#__PURE__*/React.createElement(StatusLine, null), /*#__PURE__*/React.createElement("div", {
    style: {
      position: "relative",
      minHeight: 0
    }
  }, view)), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: "var(--space-2)",
      alignItems: "center",
      font: "var(--weight-body) var(--text-meta)/1.4 var(--font-body)",
      color: "var(--text-muted)"
    }
  }, ["scans", "camera", "pages", "adjust", "done"].map(s => /*#__PURE__*/React.createElement("button", {
    key: s,
    type: "button",
    onClick: () => setScreen(s),
    style: {
      background: "transparent",
      border: `1px solid ${screen === s ? "var(--accent)" : "var(--divider)"}`,
      color: screen === s ? "var(--accent-700)" : "var(--text-muted)",
      borderRadius: "var(--radius-sm)",
      padding: "3px 8px",
      font: "var(--weight-body) var(--text-meta)/1.4 var(--font-body)",
      cursor: "pointer"
    }
  }, s)), /*#__PURE__*/React.createElement("button", {
    type: "button",
    onClick: () => setTheme(theme === "light" ? "dark" : "light"),
    style: {
      background: "transparent",
      border: "1px solid var(--divider)",
      color: "var(--text-muted)",
      borderRadius: "var(--radius-sm)",
      padding: "3px 8px",
      font: "var(--weight-body) var(--text-meta)/1.4 var(--font-body)",
      cursor: "pointer"
    }
  }, theme === "light" ? "dark" : "light")));
}
ReactDOM.createRoot(document.getElementById("root")).render(/*#__PURE__*/React.createElement(App, null));
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/iphone/App.jsx", error: String((e && e.message) || e) }); }

// ui_kits/iphone/CameraScreen.jsx
try { (() => {
const {
  Viewfinder,
  PageCounter,
  Shutter,
  Button,
  PageImage,
  ErrorLine
} = window.FreePDFDesignSystem_43ff31;
function CameraScreen({
  onFinish,
  onBack
}) {
  const [pages, setPages] = React.useState(6);
  const [writing, setWriting] = React.useState(false);
  const shoot = () => {
    setWriting(true);
    setTimeout(() => {
      setPages(p => p + 1);
      setWriting(false);
    }, 550);
  };
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(AppBar, {
    title: `Page ${pages + 1}`,
    back: true,
    onBack: onBack
  }), /*#__PURE__*/React.createElement(Screen, {
    footer: /*#__PURE__*/React.createElement(Button, {
      variant: "primary",
      fullWidth: true,
      disabled: pages === 0,
      onClick: () => onFinish(pages)
    }, pages === 0 ? "Photograph at least one page" : `Scan ${pages} pages`)
  }, /*#__PURE__*/React.createElement(Viewfinder, {
    note: writing ? "Writing the photo…" : null
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      inset: "14% 16%",
      background: "#38352f",
      boxShadow: "0 0 40px rgba(0,0,0,.5) inset"
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      top: "var(--space-2)",
      left: "var(--space-2)"
    }
  }, /*#__PURE__*/React.createElement(PageCounter, {
    onDark: true
  }, `Page ${pages + 1}`))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      placeItems: "center"
    }
  }, /*#__PURE__*/React.createElement(Shutter, {
    label: `Photograph page ${pages + 1}`,
    disabled: writing,
    onPress: shoot
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: "var(--space-2)",
      overflow: "auto",
      paddingBottom: 2
    }
  }, Array.from({
    length: pages
  }, (_, i) => /*#__PURE__*/React.createElement(PageImage, {
    key: i,
    label: String(i + 1),
    style: {
      width: 44,
      flex: "0 0 auto"
    }
  })))));
}
Object.assign(window, {
  CameraScreen
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/iphone/CameraScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/iphone/Chrome.jsx
try { (() => {
const {
  SectionLabel,
  IconButton,
  Icon
} = window.FreePDFDesignSystem_43ff31;
const appBarStyle = {
  display: "flex",
  alignItems: "center",
  gap: "var(--space-2)",
  minHeight: 52,
  padding: "0 var(--screen-padding)",
  borderBottom: "1px solid var(--divider)"
};
function AppBar({
  title,
  back,
  onBack,
  trailing
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: appBarStyle
  }, back ? /*#__PURE__*/React.createElement(IconButton, {
    icon: "chevron-left",
    label: "Back",
    onClick: onBack,
    style: {
      marginLeft: -10
    }
  }) : null, /*#__PURE__*/React.createElement("h1", {
    style: {
      margin: 0,
      flex: 1,
      font: "var(--weight-heading) var(--text-h4)/var(--leading-heading) var(--font-heading)",
      letterSpacing: "var(--tracking-heading)",
      fontVariantNumeric: "tabular-nums"
    }
  }, title), trailing);
}
function Screen({
  children,
  footer
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateRows: "1fr auto",
      minHeight: 0,
      height: "100%"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      overflow: "auto",
      padding: "var(--screen-padding)",
      display: "grid",
      gap: "var(--space-4)",
      alignContent: "start"
    }
  }, children), footer ? /*#__PURE__*/React.createElement("div", {
    style: {
      padding: "var(--screen-padding)",
      borderTop: "1px solid var(--divider)",
      display: "grid",
      gap: "var(--space-2)"
    }
  }, footer) : null);
}

/* The status line: iPhone-shaped, but drawn in the app's own type — the app never
   inherits the platform's font, not even here. */
function StatusLine({
  onDark = false
}) {
  const c = onDark ? "rgba(248,244,244,.8)" : "var(--text-muted)";
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      justifyContent: "space-between",
      alignItems: "center",
      padding: "8px var(--screen-padding) 2px",
      font: "var(--weight-body) var(--text-meta)/1 var(--font-body)",
      fontVariantNumeric: "tabular-nums",
      color: c
    }
  }, /*#__PURE__*/React.createElement("span", null, "20:14"), /*#__PURE__*/React.createElement("span", {
    style: {
      display: "flex",
      gap: 5,
      alignItems: "center"
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "wifi",
    size: 11,
    color: c
  }), /*#__PURE__*/React.createElement(Icon, {
    name: "battery-full",
    size: 13,
    color: c
  })));
}
Object.assign(window, {
  AppBar,
  Screen,
  StatusLine
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/iphone/Chrome.jsx", error: String((e && e.message) || e) }); }

// ui_kits/iphone/DoneScreen.jsx
try { (() => {
const {
  TextField,
  Button,
  ConfirmDialog,
  PageImage,
  SectionLabel
} = window.FreePDFDesignSystem_43ff31;
function DoneScreen({
  onChangePages,
  onBack
}) {
  const [name, setName] = React.useState("");
  const [photos, setPhotos] = React.useState(true);
  const [confirm, setConfirm] = React.useState(false);
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(AppBar, {
    title: "PDF ready",
    back: true,
    onBack: onBack
  }), /*#__PURE__*/React.createElement(Screen, {
    footer: /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(Button, {
      variant: "primary",
      fullWidth: true
    }, "Open PDF"), /*#__PURE__*/React.createElement(Button, {
      variant: "primary",
      fullWidth: true
    }, "Share PDF"), /*#__PURE__*/React.createElement(Button, {
      variant: "ghost",
      fullWidth: true,
      onClick: onChangePages
    }, "Change pages"))
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: "var(--space-2)"
    }
  }, [1, 2, 3, 4].map(i => /*#__PURE__*/React.createElement(PageImage, {
    key: i,
    label: String(i),
    style: {
      width: 62
    }
  }))), /*#__PURE__*/React.createElement(TextField, {
    label: "Name for the shared copy",
    value: name,
    placeholder: "scan",
    suffix: ".pdf",
    onChange: setName
  }), photos ? /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gap: "var(--space-2)",
      paddingTop: "var(--space-2)",
      borderTop: "1px solid var(--divider)"
    }
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "destructive",
    fullWidth: true,
    onClick: () => setConfirm(true)
  }, "Delete the 40 photos (78 MB)"), /*#__PURE__*/React.createElement("p", {
    style: {
      margin: 0,
      font: "var(--weight-body) var(--text-meta)/1.45 var(--font-body)",
      color: "var(--text-muted)",
      textWrap: "pretty"
    }
  }, "The PDF stays. Deleted photos cannot be brought back.")) : null), confirm ? /*#__PURE__*/React.createElement(ConfirmDialog, {
    title: "Delete the 40 photos?",
    body: "The PDF stays. Without the photos the pages can no longer be adjusted.",
    confirmLabel: "Delete photos",
    onConfirm: () => {
      setPhotos(false);
      setConfirm(false);
    },
    onCancel: () => setConfirm(false)
  }) : null);
}
Object.assign(window, {
  DoneScreen
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/iphone/DoneScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/iphone/PagesScreen.jsx
try { (() => {
const {
  PageImage,
  PageCounter,
  IconButton,
  MenuList,
  Switch,
  Button,
  ConfirmDialog
} = window.FreePDFDesignSystem_43ff31;
function PagesScreen({
  total = 12,
  onAdjust,
  onMakePdf,
  onBack
}) {
  const [page, setPage] = React.useState(3);
  const [grey, setGrey] = React.useState(false);
  const [menu, setMenu] = React.useState(false);
  const [confirm, setConfirm] = React.useState(false);
  const [making, setMaking] = React.useState(false);
  const refused = page === 5;
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(AppBar, {
    title: `Page ${page} of ${total}`,
    back: true,
    onBack: onBack,
    trailing: /*#__PURE__*/React.createElement(IconButton, {
      icon: "ellipsis",
      label: "Page menu",
      onClick: () => setMenu(!menu)
    })
  }), /*#__PURE__*/React.createElement(Screen, {
    footer: /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(Switch, {
      label: "Grey",
      checked: grey,
      onChange: setGrey
    }), /*#__PURE__*/React.createElement(Button, {
      variant: "primary",
      fullWidth: true,
      busy: making,
      onClick: () => {
        setMaking(true);
        setTimeout(() => {
          setMaking(false);
          onMakePdf();
        }, 700);
      }
    }, making ? "Making the PDF…" : "Make PDF"))
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: "relative"
    }
  }, /*#__PURE__*/React.createElement(PageImage, {
    state: refused ? "refused" : "page",
    grey: grey,
    style: {
      width: "100%"
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      left: "var(--space-2)",
      bottom: "var(--space-2)"
    }
  }, /*#__PURE__*/React.createElement(PageCounter, null, `${page} / ${total}`))), refused ? /*#__PURE__*/React.createElement(Button, {
    variant: "secondary",
    fullWidth: true
  }, "Scan this page again") : /*#__PURE__*/React.createElement(Button, {
    variant: "ghost",
    fullWidth: true,
    onClick: () => onAdjust(page)
  }, "Adjust page"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: "var(--space-2)",
      overflow: "auto",
      paddingBottom: 2
    }
  }, Array.from({
    length: total
  }, (_, i) => /*#__PURE__*/React.createElement(PageImage, {
    key: i,
    label: String(i + 1),
    grey: grey,
    state: i + 1 === 5 ? "refused" : "page",
    selected: i + 1 === page,
    onClick: () => setPage(i + 1),
    style: {
      width: 40,
      flex: "0 0 auto"
    }
  })))), menu ? /*#__PURE__*/React.createElement("div", {
    onClick: () => setMenu(false),
    style: {
      position: "absolute",
      inset: 0,
      background: "color-mix(in srgb, var(--neutral-900) 22%, transparent)",
      padding: "var(--space-4)",
      display: "grid",
      justifyItems: "end",
      alignContent: "start"
    }
  }, /*#__PURE__*/React.createElement(MenuList, {
    title: "Page",
    items: [{
      label: "Retake this page",
      icon: "camera"
    }, {
      label: "Adjust page",
      icon: "sun"
    }, {
      label: "Shoot another page",
      icon: "plus"
    }, {
      label: "Delete page",
      icon: "trash-2",
      destructive: true
    }],
    onSelect: item => {
      setMenu(false);
      if (item.label === "Delete page") setConfirm(true);
      if (item.label === "Adjust page") onAdjust(page);
    },
    style: {
      marginTop: 52
    }
  })) : null, confirm ? /*#__PURE__*/React.createElement(ConfirmDialog, {
    title: "Delete this page?",
    body: "The photo goes too. This cannot be undone.",
    confirmLabel: "Delete page",
    onConfirm: () => setConfirm(false),
    onCancel: () => setConfirm(false)
  }) : null);
}
Object.assign(window, {
  PagesScreen
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/iphone/PagesScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/iphone/ScansScreen.jsx
try { (() => {
const {
  ScanRow,
  EmptyState,
  Button,
  ConfirmDialog,
  ProgressLine
} = window.FreePDFDesignSystem_43ff31;
const SCANS = [{
  id: "a",
  title: "11 Aug 2026, 20:14",
  subtitle: "40 pages — PDF ready"
}, {
  id: "b",
  title: "11 Aug 2026, 09:02",
  subtitle: "12 of 40 pages scanned",
  progress: [12, 40]
}, {
  id: "c",
  title: "10 Aug 2026, 18:47",
  subtitle: "8 pages — keep shooting"
}, {
  id: "d",
  title: "09 Aug 2026, 14:31",
  subtitle: "40 pages — PDF ready, photos deleted"
}, {
  id: "e",
  title: "08 Aug 2026, 11:20",
  subtitle: "No pages yet"
}];
function ScansScreen({
  onOpen,
  onNew
}) {
  const [scans, setScans] = React.useState(SCANS);
  const [swiped, setSwiped] = React.useState(null);
  const [confirm, setConfirm] = React.useState(null);
  const empty = scans.length === 0;
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(AppBar, {
    title: "Scans"
  }), /*#__PURE__*/React.createElement(Screen, {
    footer: /*#__PURE__*/React.createElement(Button, {
      variant: "primary",
      fullWidth: true,
      onClick: onNew
    }, "New scan")
  }, empty ? /*#__PURE__*/React.createElement(EmptyState, {
    title: "No scans yet",
    body: "Tap New scan and photograph the pages, one after another. You can stop whenever you like."
  }) : /*#__PURE__*/React.createElement("div", null, scans.map(s => /*#__PURE__*/React.createElement(ScanRow, {
    key: s.id,
    title: s.title,
    subtitle: s.subtitle,
    swiped: swiped === s.id,
    onPress: () => swiped === s.id ? setSwiped(null) : swiped ? setSwiped(null) : onOpen(s),
    onDelete: () => setConfirm(s),
    onContextMenu: e => {
      e.preventDefault();
      setSwiped(swiped === s.id ? null : s.id);
    }
  }))), scans.some(s => s.progress) ? /*#__PURE__*/React.createElement(ProgressLine, {
    line: "Scanning page 12 of 40",
    note: "You can close the app. It carries on from here.",
    value: 12,
    max: 40
  }) : null), confirm ? /*#__PURE__*/React.createElement(ConfirmDialog, {
    title: "Delete this scan?",
    body: "40 pages, the PDF and 40 photos go. This cannot be undone.",
    confirmLabel: "Delete scan",
    onConfirm: () => {
      setScans(scans.filter(s => s.id !== confirm.id));
      setSwiped(null);
      setConfirm(null);
    },
    onCancel: () => setConfirm(null)
  }) : null);
}
Object.assign(window, {
  ScansScreen
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/iphone/ScansScreen.jsx", error: String((e && e.message) || e) }); }

__ds_ns.Button = __ds_scope.Button;

__ds_ns.Icon = __ds_scope.Icon;

__ds_ns.IconButton = __ds_scope.IconButton;

__ds_ns.SectionLabel = __ds_scope.SectionLabel;

__ds_ns.Shutter = __ds_scope.Shutter;

__ds_ns.Tag = __ds_scope.Tag;

__ds_ns.PageCounter = __ds_scope.PageCounter;

__ds_ns.PageImage = __ds_scope.PageImage;

__ds_ns.Viewfinder = __ds_scope.Viewfinder;

__ds_ns.ConfirmDialog = __ds_scope.ConfirmDialog;

__ds_ns.EmptyState = __ds_scope.EmptyState;

__ds_ns.ErrorLine = __ds_scope.ErrorLine;

__ds_ns.ProgressLine = __ds_scope.ProgressLine;

__ds_ns.Slider = __ds_scope.Slider;

__ds_ns.Switch = __ds_scope.Switch;

__ds_ns.TextField = __ds_scope.TextField;

__ds_ns.MenuList = __ds_scope.MenuList;

__ds_ns.ScanRow = __ds_scope.ScanRow;

})();
