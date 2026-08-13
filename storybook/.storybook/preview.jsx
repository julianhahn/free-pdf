import React from "react";
import "@ds/styles.css";

export const globalTypes = {
  theme: {
    description: "Light or dark ground",
    toolbar: {
      title: "Theme",
      items: [
        { value: "light", title: "Light" },
        { value: "dark", title: "Dark" },
      ],
    },
  },
};

export const initialGlobals = {
  theme: "light",
  viewport: { value: "iphone", isRotated: false },
};

export const decorators = [
  (Story, { globals }) => {
    document.documentElement.dataset.theme = globals.theme ?? "light";
    return (
      <div style={{ background: "var(--bg)", color: "var(--text)", padding: "var(--space-4)", minHeight: "100vh" }}>
        <Story />
      </div>
    );
  },
];

export const parameters = {
  layout: "fullscreen",
  viewport: {
    options: {
      iphone: { name: "iPhone", styles: { width: "390px", height: "844px" }, type: "mobile" },
    },
  },
};
