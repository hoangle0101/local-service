// Dispute types matching backend responses

// Dispute statuses
export type DisputeStatus =
  | "open"
  | "under_review"
  | "awaiting_response"
  | "escalated"
  | "resolved"
  | "closed"
  | "cancelled";

// Dispute categories
export type DisputeCategory =
  | "service_not_completed"
  | "poor_quality"
  | "price_disagreement"
  | "no_show_provider"
  | "no_show_customer"
  | "damage_caused"
  | "unprofessional_behavior"
  | "payment_issue"
  | "other";

// Resolution types
export type DisputeResolutionType =
  | "full_refund_to_customer"
  | "partial_refund_to_customer"
  | "full_payment_to_provider"
  | "mutual_cancellation"
  | "no_action";

// Evidence types
export type EvidenceType =
  | "image"
  | "video"
  | "audio"
  | "document"
  | "screenshot";

// Timeline entry
export interface DisputeTimelineEntry {
  id: string;
  disputeId: string;
  action: string;
  description: string;
  actorUserId: string | null;
  metadata: Record<string, unknown> | null;
  createdAt: string;
  actor: {
    id: string;
    profile: {
      fullName: string;
      avatarUrl: string | null;
    } | null;
  } | null;
}

// Evidence
export interface DisputeEvidence {
  id: string;
  disputeId: string;
  uploaderId: string;
  type: EvidenceType;
  url: string;
  description: string | null;
  createdAt: string;
  uploader: {
    id: string;
    profile: {
      fullName: string;
    } | null;
  };
}

// Main dispute interface
export interface Dispute {
  id: string;
  bookingId: string;
  raisedBy: string;
  category: DisputeCategory;
  reason: string;
  status: DisputeStatus;
  resolutionType: DisputeResolutionType | null;
  resolution: string | null;
  refundAmount: string | number | null;
  adminNotes: string | null;
  resolvedByAdminId: string | null;
  escalatedAt: string | null;
  respondedAt: string | null;
  appealCount: number;
  lastAppealAt: string | null;
  createdAt: string;
  resolvedAt: string | null;

  // Relations
  booking?: {
    id: string;
    customerId: string;
    providerId: string;
    status: string;
    actualPrice: string | number | null;
    scheduledAt: string | null;
    service: {
      name: string;
      description?: string;
    } | null;
    customer?: {
      phone: string;
      profile: {
        fullName: string;
      } | null;
    };
    providerUser?: {
      phone: string;
      profile: {
        fullName: string;
      } | null;
    };
    // Legacy fields for compatibility
    serviceName?: string;
    customerPhone?: string;
    providerPhone?: string;
  } | null;

  raiser?: {
    id: string;
    phone: string;
    profile: {
      fullName: string;
      avatarUrl: string | null;
    } | null;
  };

  resolvedBy?: {
    id: string;
    profile: {
      fullName: string;
    } | null;
  } | null;

  // Counts
  _count?: {
    evidence: number;
    timeline: number;
  };

  // Included data
  timeline?: DisputeTimelineEntry[];
  evidence?: DisputeEvidence[];

  // Legacy compatibility
  reporter?: {
    id: string;
    phone: string;
    email: string | null;
    profile: {
      fullName: string;
    } | null;
  };
}

// Input types
export interface ResolveDisputeInput {
  resolution: DisputeResolutionType;
  refundAmount?: number;
  notes?: string;
  applyPenalty?: boolean;
  penaltyType?: "warning" | "temporary_ban" | "fee_deduction";
  penaltySeverity?: "low" | "medium" | "high";
  banDurationDays?: number;
  feeAmount?: number;
}

export interface EscalateDisputeInput {
  reason: string;
  priority?: "normal" | "high" | "urgent";
}

export interface RequestResponseInput {
  targetParty: "customer" | "provider";
  message?: string;
  deadlineHours?: number;
}

// Display helpers
export const DISPUTE_STATUS_LABELS: Record<DisputeStatus, string> = {
  open: "Mở",
  under_review: "Đang xem xét",
  awaiting_response: "Chờ phản hồi",
  escalated: "Đã leo thang",
  resolved: "Đã giải quyết",
  closed: "Đã đóng",
  cancelled: "Đã hủy",
};

export const DISPUTE_STATUS_COLORS: Record<DisputeStatus, string> = {
  open: "bg-yellow-100 text-yellow-800",
  under_review: "bg-blue-100 text-blue-800",
  awaiting_response: "bg-orange-100 text-orange-800",
  escalated: "bg-red-100 text-red-800",
  resolved: "bg-green-100 text-green-800",
  closed: "bg-zinc-100 text-zinc-800",
  cancelled: "bg-zinc-100 text-zinc-500",
};

export const DISPUTE_CATEGORY_LABELS: Record<DisputeCategory, string> = {
  service_not_completed: "Dịch vụ chưa hoàn thành",
  poor_quality: "Chất lượng kém",
  price_disagreement: "Bất đồng giá",
  no_show_provider: "Nhà cung cấp không đến",
  no_show_customer: "Khách không có mặt",
  damage_caused: "Gây hư hỏng",
  unprofessional_behavior: "Hành vi thiếu chuyên nghiệp",
  payment_issue: "Vấn đề thanh toán",
  other: "Khác",
};

export const RESOLUTION_TYPE_LABELS: Record<DisputeResolutionType, string> = {
  full_refund_to_customer: "Hoàn tiền đầy đủ cho khách",
  partial_refund_to_customer: "Hoàn tiền một phần cho khách",
  full_payment_to_provider: "Thanh toán đầy đủ cho nhà cung cấp",
  mutual_cancellation: "Hủy đồng thuận",
  no_action: "Không xử lý",
};
