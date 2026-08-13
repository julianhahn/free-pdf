import * as React from "react";
/**
 * Icon, title, body — shown when there are no scan folders.
 * @startingPoint section="Scans" subtitle="Empty scans screen" viewport="700x340"
 */
export interface EmptyStateProps {
  /** Lucide icon name; defaults to a stack of sheets. */
  icon?: string;
  title: string;
  body: React.ReactNode;
  /** Usually the primary "New scan" button. */
  action?: React.ReactNode;
  style?: React.CSSProperties;
}
/**
 * Icon, title, body — shown when there are no scan folders.
 */
export declare function EmptyState(props: EmptyStateProps): JSX.Element;
