// Provider types matching backend responses

export interface Provider {
  id: string;
  userId: string;
  displayName: string; // Backend returns displayName, not businessName
  bio: string | null;
  avatarUrl: string | null;
  coverImageUrl: string | null;
  status: 'pending' | 'approved' | 'rejected' | 'suspended';
  verificationStatus: 'unverified' | 'pending' | 'verified' | 'rejected';
  availabilityStatus: 'available' | 'busy' | 'offline';
  rating: { average: number; count: number } | number; // Backend returns object
  totalReviews: number;
  responseTime: number | null;
  completionRate: string | number | null;
  services: ProviderService[];
  user: {
    id: string;
    phone: string;
    email: string | null;
    status: 'active' | 'inactive' | 'banned';
    isVerified: boolean;
    profile: {
      fullName: string;
      avatarUrl: string | null;
    } | null;
  };
  createdAt: string;
  updatedAt: string;
  verifiedAt?: string | null;
  rejectionReason?: string | null;
}

export interface ProviderService {
  id: number;
  providerId: string;
  serviceId: number;
  basePrice: string | number;
  description: string | null;
  isActive: boolean;
  service: Service;
}

export interface Service {
  id: number;
  name: string;
  description: string | null;
  categoryId: number;
  imageUrl: string | null;
  basePrice: string | number;
  durationMinutes: number;
  isActive: boolean;
  category: ServiceCategory | null;
  createdAt: string;
  updatedAt: string;
}

export interface ServiceCategory {
  id: number;
  name: string;
  slug: string;
  description: string | null;
  icon: string | null;
  imageUrl: string | null;
  parentId: number | null;
  isActive: boolean;
  children?: ServiceCategory[];
}
