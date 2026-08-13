import React from "react";
import { Slider } from "../ds.js";

export default {
  title: "Forms/Slider",
  component: Slider,
  render: (args) => {
    const [value, setValue] = React.useState(args.value);
    React.useEffect(() => setValue(args.value), [args.value]);
    return <Slider {...args} value={value} onChange={setValue} />;
  },
};

export const Brightness = {
  args: { label: "Brightness", value: 12, min: -50, max: 50, suggested: 12, minLabel: "darker", maxLabel: "brighter" },
};
export const MovedOffTheSuggestion = {
  args: { ...Brightness.args, value: -28 },
};
export const WithUnit = {
  args: { label: "Straighten", value: 0, min: -15, max: 15, step: 0.5, unit: "°", suggested: 1.5 },
};
export const Disabled = { args: { ...Brightness.args, disabled: true } };
