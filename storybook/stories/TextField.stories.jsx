import React from "react";
import { TextField } from "../ds.js";

export default {
  title: "Forms/TextField",
  component: TextField,
  render: (args) => {
    const [value, setValue] = React.useState(args.value);
    React.useEffect(() => setValue(args.value), [args.value]);
    return <TextField {...args} value={value} onChange={setValue} />;
  },
};

export const Empty = {
  args: { label: "Name for the shared copy", value: "", placeholder: "scan", suffix: ".pdf" },
};
export const Filled = { args: { ...Empty.args, value: "11 Aug 2026, 20:14" } };
export const Disabled = { args: { ...Filled.args, disabled: true } };
