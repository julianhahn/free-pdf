import * as React from "react";
/**
 * The one raised surface in the system. All three deletions ask, always.
 * @startingPoint section="Destructive" subtitle="Confirmation dialog over a screen" viewport="700x380"
 */
export interface ConfirmDialogProps {
  title: string;
  body: React.ReactNode;
  /** Destructive action, e.g. "Delete photos". */
  confirmLabel: string;
  cancelLabel?: string;
  onConfirm?: () => void;
  onCancel?: () => void;
  style?: React.CSSProperties;
}
/**
 * The one raised surface in the system. All three deletions ask, always.
 */
export declare function ConfirmDialog(props: ConfirmDialogProps): JSX.Element;
