// User types matching backend responses

export interface User {
  id: string;
  phone: string;
  email: string | null;
  roles: string[]; // Backend returns array of role names
  status: 'active' | 'inactive' | 'banned';
  isVerified: boolean;
  profile: UserProfile | null;
  createdAt: string;
  updatedAt: string;
  banReason?: string | null;
  bannedAt?: string | null;
  bannedUntil?: string | null;
}

export interface UserProfile {
  fullName: string;
  avatarUrl: string | null;
  dateOfBirth: string | null;
  gender: 'male' | 'female' | 'other' | null;
  address: string | null;
}

// UserDetail for admin detail page
export interface UserDetail extends User {
  provider?: any | null;
  wallet?: {
    balance: string | number;
    lockedBalance: string | number;
    totalDeposits: string | number;
    totalWithdrawals: string | number;
  } | null;
  bookingsAsCustomer?: any[];
  bookingsAsProvider?: any[];
}
