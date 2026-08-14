#!/usr/bin/env node
// The tokens in this folder are the source of truth. Every client reads them from
// here instead of copying numbers, so a colour is changed in one place.
//
//   node design/system/tokens/build-tokens.mjs            # write every target
//   node design/system/tokens/build-tokens.mjs --check    # write nothing, fail if stale
//   node design/system/tokens/build-tokens.mjs --self-check
//
// Today there is one target, Swift. A second client adds an emitter to TARGETS and
// nothing else: the parsing above it is client-blind.

import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, "..", "..", "..");

/* ---------- read the CSS ---------- */

// Declarations of one selector, in file order. Later files win, as the cascade has them.
const declarations = (css, selector) => {
  const out = {};
  const re = new RegExp(`${selector.replace(/[[\]"]/g, "\\$&")}\\s*\\{([^}]*)\\}`, "g");
  for (const [, body] of css.matchAll(re)) {
    for (const [, name, value] of body.matchAll(/--([\w-]+)\s*:\s*([^;]+)/g)) {
      out[name] = value.trim().replace(/\/\*.*?\*\//g, "").trim();
    }
  }
  return out;
};

const read = (f) => readFileSync(join(HERE, f), "utf8");
const FILES = ["colors.css", "spacing.css", "radius.css", "typography.css", "fonts.css", "elevation.css"];
const css = FILES.map(read).join("\n");

const light = declarations(css, ":root");
const dark = { ...light, ...declarations(css, '[data-theme="dark"]') };

/* ---------- resolve ---------- */

const resolve = (value, vars, seen = new Set()) =>
  value.replace(/var\(\s*--([\w-]+)\s*\)/g, (_, name) => {
    if (seen.has(name)) throw new Error(`--${name} refers to itself`);
    if (!(name in vars)) throw new Error(`--${name} is used but never defined`);
    return resolve(vars[name], vars, new Set([...seen, name]));
  });

// A colour as r,g,b in 0-255 and a in 0-1, or null if the value is not a colour.
export function toRGBA(value) {
  const v = value.trim();

  const mix = v.match(/^color-mix\(\s*in srgb\s*,\s*(.+?)\s+([\d.]+)%\s*,\s*transparent\s*\)$/);
  if (mix) {
    const base = toRGBA(mix[1]);
    return base && { ...base, a: base.a * (Number(mix[2]) / 100) };
  }
  if (v === "transparent") return { r: 0, g: 0, b: 0, a: 0 };

  const hex = v.match(/^#([0-9a-f]{3}|[0-9a-f]{6})$/i);
  if (hex) {
    const h = hex[1].length === 3 ? [...hex[1]].map((c) => c + c).join("") : hex[1];
    return { r: parseInt(h.slice(0, 2), 16), g: parseInt(h.slice(2, 4), 16), b: parseInt(h.slice(4, 6), 16), a: 1 };
  }
  const rgba = v.match(/^rgba?\(([^)]+)\)$/);
  if (rgba) {
    const [r, g, b, a = "1"] = rgba[1].split(/[,/]/).map((n) => n.trim());
    return { r: Number(r), g: Number(g), b: Number(b), a: Number(a) };
  }
  return null;
}

const px = (value) => {
  const m = value.trim().match(/^(-?[\d.]+)px$/);
  return m ? Number(m[1]) : null;
};

// { name: {light, dark} } for colours, { name: number } for lengths.
function collect() {
  const colors = {};
  const lengths = {};
  const numbers = {};
  for (const name of Object.keys(light)) {
    const l = resolve(light[name], light);
    const d = resolve(dark[name] ?? light[name], dark);
    const lc = toRGBA(l);
    if (lc) {
      colors[name] = { light: lc, dark: toRGBA(d) ?? lc };
      continue;
    }
    const lp = px(l);
    if (lp !== null) {
      lengths[name] = lp;
      continue;
    }
    if (/^-?[\d.]+$/.test(l)) numbers[name] = Number(l);
  }
  const family = (name) => resolve(light[name], light).split(",")[0].replace(/["']/g, "").trim();
  return { colors, lengths, numbers, fonts: { heading: family("font-heading"), body: family("font-body") } };
}

/* ---------- emit ---------- */

const camel = (name) => name.replace(/-([a-z0-9])/g, (_, c) => c.toUpperCase());
const swiftName = (name) => {
  const c = camel(name);
  return /^\d/.test(c) ? `_${c}` : c;
};
const f = (n) => (Number.isInteger(n) ? `${n}` : `${n}`);

function swift({ colors, lengths, numbers, fonts }) {
  // Four places: an 8-bit channel needs three, and the fourth keeps the rounding honest.
  const ch = (n) => Number(n.toFixed(4));
  const channel = (c) => `red: ${ch(c.r / 255)}, green: ${ch(c.g / 255)}, blue: ${ch(c.b / 255)}, alpha: ${ch(c.a)}`;
  const color = (name, { light: l, dark: d }) =>
    `    /// --${name}\n` +
    `    static let ${swiftName(name)} = Color(light: UIColor(${channel(l)}),\n` +
    `${" ".repeat(15 + swiftName(name).length)}dark: UIColor(${channel(d)}))`;

  const group = (title, body) => `enum ${title} {\n${body}\n}`;

  return `//  Tokens.swift — GENERATED. Do not edit.
//
//  Written by design/system/tokens/build-tokens.mjs out of design/system/tokens/*.css,
//  which is where a colour, a step or a size is changed. Run the script after changing
//  one; \`--check\` in CI fails when this file is behind.
//
//  What is not here: the two shadows and the .fp-on-dark override, because nothing on
//  the phone draws them yet. Add them to the script, not to this file.

import SwiftUI
import UIKit

extension Color {
    /// One value per theme, resolved by the view's own trait collection.
    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}

enum Token {
    ${group("Palette", Object.entries(colors).map(([n, v]) => color(n, v)).join("\n")).replace(/\n/g, "\n    ")}

    ${group("Size", Object.entries(lengths).map(([n, v]) => `    /// --${n}\n    static let ${swiftName(n)}: CGFloat = ${f(v)}`).join("\n")).replace(/\n/g, "\n    ")}

    ${group("Number", Object.entries(numbers).map(([n, v]) => `    /// --${n}\n    static let ${swiftName(n)}: CGFloat = ${f(v)}`).join("\n")).replace(/\n/g, "\n    ")}

    enum Face {
        /// --font-heading. Falls back to the system serif when the family is missing.
        static func heading(_ size: CGFloat) -> Font { .custom("${fonts.heading}", size: size) }
        /// --font-body
        static func body(_ size: CGFloat) -> Font { .custom("${fonts.body}", size: size) }
    }
}
`;
}

const TARGETS = [{ path: join(REPO, "ios", "FreePDF", "Tokens.swift"), emit: swift }];

/* ---------- run ---------- */

function selfCheck() {
  const eq = (a, b, what) => {
    if (JSON.stringify(a) !== JSON.stringify(b)) throw new Error(`${what}: ${JSON.stringify(a)} != ${JSON.stringify(b)}`);
  };
  eq(toRGBA("#f3f2f2"), { r: 243, g: 242, b: 242, a: 1 }, "six-digit hex");
  eq(toRGBA("rgba(32,31,29,.16)"), { r: 32, g: 31, b: 29, a: 0.16 }, "rgba");
  eq(toRGBA("color-mix(in srgb,#b68235 14%,transparent)"), { r: 182, g: 130, b: 53, a: 0.14 }, "color-mix");
  eq(toRGBA("15px"), null, "a length is not a colour");
  eq(resolve("var(--a)", { a: "var(--b)", b: "#fff" }), "#fff", "var chains");
  eq(px("4.6px"), 4.6, "px");

  const t = collect();
  // --destructive is var(--accent-700) light and var(--accent-300) dark: the one role
  // that would silently become one colour if the dark cascade were dropped.
  eq(t.colors.destructive.light, toRGBA("#7d5411"), "destructive, light");
  eq(t.colors.destructive.dark, toRGBA("#facb8d"), "destructive, dark");
  eq(t.lengths.space1, undefined, "names keep their digits");
  eq(t.lengths["space-1"], 4.6, "--space-1");
  console.log("self-check ok");
}

const mode = process.argv[2];
if (mode === "--self-check") {
  selfCheck();
} else {
  const tokens = collect();
  let stale = false;
  for (const { path, emit } of TARGETS) {
    const next = emit(tokens);
    const now = (() => { try { return readFileSync(path, "utf8"); } catch { return null; } })();
    if (next === now) continue;
    if (mode === "--check") {
      console.error(`stale: ${path}`);
      stale = true;
    } else {
      writeFileSync(path, next);
      console.log(`wrote ${path}`);
    }
  }
  if (stale) process.exit(1);
  if (mode === "--check") console.log("tokens ok");
}
