import * as React from "react";
export interface MenuItem {
  label: string;
  /** Lucide icon name. */
  icon?: string;
  destructive?: boolean;
  disabled?: boolean;
}
export interface MenuListProps {
  /** Menu heading, e.g. "Page". */
  title?: string;
  items?: MenuItem[];
  onSelect?: (item: MenuItem) => void;
  style?: React.CSSProperties;
}
/** The Page menu, drawn to the tokens and presented the platform's way. */
export declare function MenuList(props: MenuListProps): JSX.Element;
