// Payment and transaction types matching backend responses

export interface Payment {
  id: string;
  bookingId: string;
  amount: string | number;
  status: 'initiated' | 'succeeded' | 'failed';
  gateway: string;
  gatewayTransactionId: string | null;
  metadata: Record<string, any>;
  booking: {
    id: string;
    customer: {
      id: string;
      phone: string;
      profile: {
        fullName: string;
      } | null;
    };
  } | null;
  createdAt: string;
  updatedAt: string;
}

export interface Transaction {
  id: string;
  walletId: string;
  type: 'deposit' | 'withdrawal' | 'payment' | 'refund' | 'commission' | 'payout';
  amount: string | number;
  balanceAfter: string | number;
  status: 'pending' | 'approved' | 'rejected' | 'processing' | 'completed' | 'failed';
  description: string | null;
  metadata: Record<string, any>;
  wallet: {
    userId: string;
    user: {
      id: string;
      phone: string;
      email: string | null;
      profile: {
        fullName: string;
      } | null;
    };
  };
  createdAt: string;
  updatedAt: string;
}

export interface Wallet {
  id: string;
  userId: string;
  balance: string | number;
  lockedBalance: string | number;
  totalDeposits: string | number;
  totalWithdrawals: string | number;
  user: {
    id: string;
    phone: string;
    email: string | null;
    profile: {
      fullName: string;
    } | null;
  };
  transactions: Transaction[];
  createdAt: string;
  updatedAt: string;
}

export interface WithdrawalRequest {
  id: string;
  amount: string | number;
  status: 'pending' | 'approved' | 'rejected' | 'processing' | 'completed' | 'failed';
  type: 'withdrawal';
  description: string | null;
  metadata: {
    bankName?: string;
    bankAccount?: string;
    accountHolderName?: string;
    rejectionReason?: string;
    approvalNotes?: string;
    [key: string]: any;
  };
  wallet: {
    userId: string;
    user: {
      id: string;
      phone: string;
      email: string | null;
      profile: {
        fullName: string;
      } | null;
    };
  };
  createdAt: string;
  updatedAt: string;
}
