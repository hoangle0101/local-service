// System types matching backend responses

export interface ApiResponse<T> {
  statusCode: number;
  message: string;
  data: T;
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

// Dashboard types
export interface DashboardStats {
  overview: {
    totalUsers: number;
    activeProviders: number;
    totalBookings: number;
    completedBookings: number;
    openDisputes: number;
    completionRate: string;
    disputeResolutionRate: string;
  };
  financials: {
    totalRevenue: number;
    avgBookingValue: number;
    platformRevenue: number;
    pendingPayouts: number;
  };
  recentActivity: Array<{
    id: string;
    service: string;
    price: number;
    status: string;
    createdAt: string;
  }>;
  charts?: {
    revenue: Array<{ date: string; revenue: number; bookings: number }>;
    users: Array<{ date: string; newUsers: number }>;
  };
}

// Announcements types
export interface Announcement {
  id: string;
  title: string;
  body: string;
  type: 'maintenance' | 'promotion' | 'alert' | 'general';
  targetRole: 'all' | 'customers' | 'providers' | 'admins';
  createdById: string;
  createdBy: {
    id: string;
    email: string;
    profile: {
      fullName: string;
    } | null;
  };
  sendNotification: boolean;
  scheduledAt: string | null;
  sentAt: string | null;
  status: 'active' | 'scheduled' | 'archived';
  createdAt: string;
  updatedAt: string;
}

export interface CreateAnnouncementInput {
  title: string;
  body: string;
  type?: 'maintenance' | 'promotion' | 'alert' | 'general';
  targetRole?: 'all' | 'customers' | 'providers' | 'admins';
  sendNotification?: boolean;
  scheduledAt?: string;
}

// Report types
export interface RevenueReport {
  summary: {
    totalRevenue: number;
    totalCommission: number;
    totalProviderEarnings: number;
    platformFees: number;
    bookingCount: number;
  };
  timeSeriesData: Array<{
    date: string;
    revenue: number;
    bookings: number;
    commission: number;
  }>;
  serviceBreakdown?: Array<{
    serviceId: number;
    serviceName: string;
    revenue: number;
    bookings: number;
  }>;
  providerBreakdown?: Array<{
    providerId: string;
    providerName: string;
   revenue: number;
    bookings: number;
  }>;
}

export interface ServicesReport {
  topServices: Array<{
    id: number;
    name: string;
    category: string;
    totalBookings: number;
    totalRevenue: number;
    avgRating: number;
    providerCount: number;
  }>;
  categoryBreakdown: Array<{
    categoryId: number;
    categoryName: string;
    serviceCount: number;
    bookings: number;
    revenue: number;
  }>;
}

export interface UsersReport {
  summary: {
    totalUsers: number;
    newUsers: number;
    activeUsers: number;
    totalCustomers: number;
    totalProviders: number;
    verifiedUsers: number;
  };
  timeSeriesData: Array<{
    date: string;
    newUsers: number;
    activeUsers: number;
    bookings: number;
    walletValue: number;
  }>;
  topUsers: Array<{
    userId: string;
    fullName: string;
    email: string;
    bookings: number;
    totalSpent: number;
  }>;
}
