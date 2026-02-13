"use client";

import { cn } from "@/lib/utils";
import { DisputeCategory, DISPUTE_CATEGORY_LABELS } from "@/types/dispute";

interface DisputeCategoryBadgeProps {
  category: DisputeCategory | string;
  className?: string;
}

const CATEGORY_ICONS: Record<string, string> = {
  service_not_completed: "❌",
  poor_quality: "⭐",
  price_disagreement: "💰",
  no_show_provider: "🚫",
  no_show_customer: "🏠",
  damage_caused: "💔",
  unprofessional_behavior: "😤",
  payment_issue: "💳",
  other: "❓",
};

export function DisputeCategoryBadge({
  category,
  className,
}: DisputeCategoryBadgeProps) {
  const label =
    DISPUTE_CATEGORY_LABELS[category as DisputeCategory] || category;
  const icon = CATEGORY_ICONS[category] || "❓";

  return (
    <span
      className={cn(
        "inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-medium",
        "bg-zinc-100 text-zinc-700",
        className
      )}
    >
      <span>{icon}</span>
      <span>{label}</span>
    </span>
  );
}
