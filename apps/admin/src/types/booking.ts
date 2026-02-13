// Booking types matching backend responses
import { Dispute } from "./dispute";
import { Payment } from "./payment";

export interface Booking {
  id: string;
  customerId: string;
  providerId: string;
  serviceId: number;
  status:
    | "pending"
    | "accepted"
    | "in_progress"
    | "completed"
    | "cancelled"
    | "disputed"
    | "pending_payment";
  scheduledAt: string;
  startedAt: string | null;
  completedAt: string | null;
  cancelledAt: string | null;
  actualPrice: string | number;
  totalAmount: string | number;
  notes: string | null;
  cancellationReason: string | null;
  customer: {
    id: string;
    phone: string;
    email: string | null;
    profile: {
      fullName: string;
      avatarUrl: string | null;
    } | null;
  };
  provider: {
    id: string;
    displayName: string;
    avatarUrl: string | null;
    user: {
      id: string;
      phone: string;
    };
  } | null;
  service: {
    id: number;
    name: string;
    category: {
      name: string;
    } | null;
  };
  payment: Payment | null;
  dispute: Dispute | null;
  createdAt: string;
  updatedAt: string;
}

export interface BookingDetail extends Booking {
  // Address
  addressText?: string;

  // Pricing details
  estimatedPrice?: string | number;
  platformFee?: string | number;
  providerEarning?: string | number;

  // Payment
  paymentStatus?: string;
  paymentMethod?: string;

  // Events/Timeline
  events?: BookingEvent[];
  timeline?: BookingTimeline[];
}

export interface BookingEvent {
  id: string;
  previousStatus: string;
  newStatus: string;
  note?: string;
  createdAt: string;
}

export interface BookingTimeline {
  timestamp: string;
  event: string;
  description: string;
}
