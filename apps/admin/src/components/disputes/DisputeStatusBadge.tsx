"use client";

import { cn } from "@/lib/utils";
import {
  Clock,
  CheckCircle,
  AlertTriangle,
  XCircle,
  MessageCircle,
  ArrowUp,
  Loader2,
} from "lucide-react";
import {
  DisputeStatus,
  DISPUTE_STATUS_LABELS,
  DISPUTE_STATUS_COLORS,
} from "@/types/dispute";

interface DisputeStatusBadgeProps {
  status: DisputeStatus | string;
  showIcon?: boolean;
  className?: string;
}

const STATUS_ICONS: Record<string, React.ReactNode> = {
  open: <Clock className="h-3 w-3" />,
  under_review: <Loader2 className="h-3 w-3" />,
  awaiting_response: <MessageCircle className="h-3 w-3" />,
  escalated: <ArrowUp className="h-3 w-3" />,
  resolved: <CheckCircle className="h-3 w-3" />,
  closed: <XCircle className="h-3 w-3" />,
  cancelled: <XCircle className="h-3 w-3" />,
};

export function DisputeStatusBadge({
  status,
  showIcon = true,
  className,
}: DisputeStatusBadgeProps) {
  const label = DISPUTE_STATUS_LABELS[status as DisputeStatus] || status;
  const colorClass =
    DISPUTE_STATUS_COLORS[status as DisputeStatus] ||
    "bg-zinc-100 text-zinc-800";
  const icon = STATUS_ICONS[status];

  return (
    <span
      className={cn(
        "inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium",
        colorClass,
        className
      )}
    >
      {showIcon && icon}
      <span>{label}</span>
    </span>
  );
}
