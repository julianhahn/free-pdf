import { fileURLToPath } from "node:url";
import path from "node:path";

const here = path.dirname(fileURLToPath(import.meta.url));
const ds = path.resolve(here, "../../design/system");
const kit = path.join(ds, "ui_kits/iphone");
const brand = path.resolve(here, "../../design/flows/brand");

/**
 * The delivered iPhone kit is written for <script type="text/babel"> globals:
 * it reads window.FreePDFDesignSystem_43ff31, uses a global React, and exports
 * nothing. This rewrites those two things at transform time so the files stay
 * untouched on disk and can still be imported as modules.
 */
const kitAsModules = {
  name: "freepdf-ui-kit-as-modules",
  enforce: "pre",
  transform(code, id) {
    const file = id.split("?")[0];
    if (!file.startsWith(kit) || !file.endsWith(".jsx")) return null;
    const names = [...code.matchAll(/^function (\w+)/gm)].map((m) => m[1]);
    const head = `import React from "react";\nimport * as __DS from "${path.resolve(here, "../ds.js")}";\n`;
    const body = code.replaceAll("window.FreePDFDesignSystem_43ff31", "__DS");
    return `${head}${body}\nexport { ${names.join(", ")} };\n`;
  },
};

export default {
  stories: ["../stories/**/*.stories.jsx"],
  framework: { name: "@storybook/react-vite", options: {} },
  viteFinal: (config) => ({
    ...config,
    plugins: [...(config.plugins ?? []), kitAsModules],
    resolve: {
      ...config.resolve,
      alias: {
        ...config.resolve?.alias,
        "@ds": ds,
        // design/system has no node_modules of its own
        react: path.resolve(here, "../node_modules/react"),
        "react-dom": path.resolve(here, "../node_modules/react-dom"),
      },
    },
    server: { ...config.server, fs: { ...config.server?.fs, allow: [path.resolve(here, ".."), ds, brand] } },
  }),
};
