import React from "react";
import { Switch } from "../ds.js";

export default {
  title: "Forms/Switch",
  component: Switch,
  render: (args) => {
    const [checked, setChecked] = React.useState(args.checked);
    React.useEffect(() => setChecked(args.checked), [args.checked]);
    return <Switch {...args} checked={checked} onChange={setChecked} />;
  },
};

export const Off = { args: { label: "Grey", checked: false } };
export const On = { args: { label: "Grey", checked: true } };
export const WithNote = { args: { label: "Apply to all pages", sub: "Keep the app open.", checked: true } };
export const Disabled = { args: { label: "Grey", checked: false, disabled: true } };
