// API Endpoints
export const API_ENDPOINTS = {
  // Auth
  AUTH: {
    LOGIN: "/auth/login",
    REGISTER: "/auth/register",
    VERIFY_OTP: "/auth/verify-otp",
    LOGOUT: "/auth/logout",
  },

  // Users
  USERS: {
    LIST: "/users",
    DETAIL: (id: string) => `/users/${id}`,
    UPDATE_STATUS: (id: string) => `/users/${id}/status`,
    ME: "/users/me",
  },

  // Providers
  PROVIDERS: {
    LIST: "/provider",
    DETAIL: (id: string) => `/provider/${id}`,
    APPROVE: (id: string) => `/provider/${id}/approve`,
    REJECT: (id: string) => `/provider/${id}/reject`,
    STATISTICS: (id: string) => `/provider/${id}/statistics`,
  },

  // Services
  SERVICES: {
    LIST: "/services",
    DETAIL: (id: string) => `/services/${id}`,
    CREATE: "/services",
    UPDATE: (id: string) => `/services/${id}`,
    DELETE: (id: string) => `/services/${id}`,
    SEARCH: "/services/search",
  },

  // Categories
  CATEGORIES: {
    LIST: "/services/categories",
    DETAIL: (id: string) => `/services/categories/${id}`,
    CREATE: "/services/categories",
    UPDATE: (id: string) => `/services/categories/${id}`,
    DELETE: (id: string) => `/services/categories/${id}`,
  },

  // Bookings
  BOOKINGS: {
    LIST: "/bookings",
    DETAIL: (id: string) => `/bookings/${id}`,
    CANCEL: (id: string) => `/bookings/${id}/cancel`,
    ESTIMATE: "/bookings/estimate",
  },

  // Payments & Transactions
  PAYMENTS: {
    TRANSACTIONS: "/admin/transactions",
    WALLETS: "/admin/wallets",
    REFUND: (id: string) => `/payments/${id}/refund`,
  },

  // Disputes
  DISPUTES: {
    LIST: "/admin/disputes",
    DETAIL: (id: string) => `/disputes/${id}`,
    RESOLVE: (id: string) => `/disputes/${id}/resolve`,
  },

  // System
  SYSTEM: {
    SETTINGS: "/system/admin/settings",
    SETTING_BY_KEY: (key: string) => `/system/admin/settings/${key}`,
    UPLOAD: "/system/upload",
    AUDIT_LOGS: "/admin/audit-logs",
  },

  // Admin Stats
  ADMIN: {
    STATS: "/admin/stats",
    DASHBOARD: "/admin/dashboard",
  },
};

// Status Constants
export const USER_STATUS = {
  ACTIVE: "active",
  INACTIVE: "inactive",
  BANNED: "banned",
} as const;

export const PROVIDER_STATUS = {
  PENDING: "pending",
  APPROVED: "approved",
  REJECTED: "rejected",
  SUSPENDED: "suspended",
} as const;

export const BOOKING_STATUS = {
  PENDING: "pending",
  CONFIRMED: "confirmed",
  ACCEPTED: "accepted",
  IN_PROGRESS: "in_progress",
  COMPLETED: "completed",
  CANCELLED: "cancelled",
  DISPUTED: "disputed",
} as const;

export const PAYMENT_STATUS = {
  PENDING: "pending",
  COMPLETED: "completed",
  FAILED: "failed",
  REFUNDED: "refunded",
} as const;

export const DISPUTE_STATUS = {
  OPEN: "open",
  INVESTIGATING: "investigating",
  RESOLVED: "resolved",
  CLOSED: "closed",
} as const;

export const TRANSACTION_TYPE = {
  DEPOSIT: "deposit",
  WITHDRAWAL: "withdrawal",
  PAYMENT: "payment",
  REFUND: "refund",
  COMMISSION: "commission",
} as const;

// Status Badge Colors
export const STATUS_COLORS = {
  // User Status
  active: "bg-green-100 text-green-600 border-green-200",
  inactive: "bg-zinc-100 text-zinc-600 border-zinc-200",
  banned: "bg-red-100 text-red-600 border-red-200",

  // Provider Status
  pending: "bg-yellow-100 text-yellow-600 border-yellow-200",
  approved: "bg-green-100 text-green-600 border-green-200",
  rejected: "bg-red-100 text-red-600 border-red-200",
  suspended: "bg-red-100 text-red-600 border-red-200",

  // Booking Status
  confirmed: "bg-blue-100 text-blue-600 border-blue-200",
  accepted: "bg-blue-100 text-blue-600 border-blue-200",
  in_progress: "bg-orange-100 text-orange-600 border-orange-200",
  completed: "bg-green-100 text-green-600 border-green-200",
  cancelled: "bg-red-100 text-red-600 border-red-200",
  disputed: "bg-purple-100 text-purple-600 border-purple-200",

  // Payment Status
  failed: "bg-red-100 text-red-600 border-red-200",
  refunded: "bg-purple-100 text-purple-600 border-purple-200",

  // Dispute Status (enhanced)
  open: "bg-yellow-100 text-yellow-600 border-yellow-200",
  under_review: "bg-blue-100 text-blue-600 border-blue-200",
  awaiting_response: "bg-orange-100 text-orange-600 border-orange-200",
  escalated: "bg-red-100 text-red-600 border-red-200",
  resolved: "bg-green-100 text-green-600 border-green-200",
  closed: "bg-zinc-100 text-zinc-600 border-zinc-200",

  // Verification Status
  verified: "bg-green-100 text-green-600 border-green-200",
  unverified: "bg-zinc-100 text-zinc-600 border-zinc-200",

  // Provider availability
  available: "bg-green-100 text-green-600 border-green-200",
  unavailable: "bg-zinc-100 text-zinc-600 border-zinc-200",
  offline: "bg-zinc-100 text-zinc-600 border-zinc-200",

  // Transaction
  initiated: "bg-yellow-100 text-yellow-600 border-yellow-200",
  succeeded: "bg-green-100 text-green-600 border-green-200",
  processing: "bg-blue-100 text-blue-600 border-blue-200",
} as const;

// Pagination
export const DEFAULT_PAGE_SIZE = 20;
export const PAGE_SIZE_OPTIONS = [10, 20, 50, 100];
