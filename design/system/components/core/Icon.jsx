import React from "react";

const LUCIDE = "https://unpkg.com/lucide-static@0.544.0/icons/";

/* Icons are Lucide, recoloured through a CSS mask so they always carry the
   current text/accent colour. See readme.md > Iconography (substitution flagged). */
export function Icon({ name, size = 20, color = "currentColor", strokeAlign, style, ...rest }) {
  return (
    <span
      aria-hidden="true"
      style={{
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
        ...style,
      }}
      {...rest}
    />
  );
}
