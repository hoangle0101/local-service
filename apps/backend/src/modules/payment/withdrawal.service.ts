import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

export interface CreateWithdrawalDto {
  amount: number;
  method: 'BANK' | 'MOMO';
  bankName?: string;
  bankAccount?: string;
  bankHolder?: string;
  momoPhone?: string;
}

const MINIMUM_WITHDRAWAL = 100000; // 100k VND
const MOMO_WITHDRAWAL_FEE_PERCENT = 0.01; // 1%
const MOMO_MAX_FEE = 50000; // 50k VND

@Injectable()
export class WithdrawalService {
  constructor(private prisma: PrismaService) {}

  /**
   * Calculate withdrawal fee
   */
  calculateFee(amount: number, method: string): number {
    if (method === 'MOMO') {
      const fee = Math.round(amount * MOMO_WITHDRAWAL_FEE_PERCENT);
      return Math.min(fee, MOMO_MAX_FEE);
    }
    return 0; // Bank transfer is free
  }

  /**
   * Create withdrawal request
   */
  async createWithdrawal(providerId: bigint, dto: CreateWithdrawalDto) {
    // Check minimum amount
    if (dto.amount < MINIMUM_WITHDRAWAL) {
      throw new BadRequestException(
        `Số tiền rút tối thiểu là ${MINIMUM_WITHDRAWAL.toLocaleString('vi-VN')}đ`,
      );
    }

    // Get provider wallet
    const wallet = await this.prisma.wallet.findUnique({
      where: { userId: providerId },
    });

    if (!wallet) {
      throw new NotFoundException('Ví không tồn tại');
    }

    const balance = Number(wallet.balance);
    if (balance < dto.amount) {
      throw new BadRequestException(
        `Số dư không đủ. Số dư hiện tại: ${balance.toLocaleString('vi-VN')}đ`,
      );
    }

    // Validate bank info
    if (dto.method === 'BANK') {
      if (!dto.bankName || !dto.bankAccount || !dto.bankHolder) {
        throw new BadRequestException(
          'Vui lòng cung cấp đầy đủ thông tin ngân hàng',
        );
      }
    }

    // Validate MoMo phone
    if (dto.method === 'MOMO') {
      if (!dto.momoPhone) {
        throw new BadRequestException('Vui lòng cung cấp số điện thoại MoMo');
      }
    }

    // Calculate fee
    const fee = this.calculateFee(dto.amount, dto.method);
    const netAmount = dto.amount - fee;

    // Create withdrawal and deduct from wallet in transaction
    const [withdrawal] = await this.prisma.$transaction([
      this.prisma.withdrawal.create({
        data: {
          providerId,
          amount: dto.amount,
          fee,
          netAmount,
          method: dto.method,
          bankName: dto.bankName,
          bankAccount: dto.bankAccount,
          bankHolder: dto.bankHolder,
          momoPhone: dto.momoPhone,
          status: 'pending',
        },
      }),
      this.prisma.wallet.update({
        where: { userId: providerId },
        data: {
          balance: { decrement: dto.amount },
        },
      }),
    ]);

    // Create wallet transaction
    const updatedWallet = await this.prisma.wallet.findUnique({
      where: { userId: providerId },
    });

    await this.prisma.walletTransaction.create({
      data: {
        walletUserId: providerId,
        type: 'withdrawal',
        amount: -dto.amount, // Negative for withdrawal
        balanceAfter: updatedWallet?.balance || 0,
        status: 'pending',
        metadata: {
          withdrawalId: withdrawal.id.toString(),
          fee,
          netAmount,
          method: dto.method,
        },
      },
    });

    console.log('[Withdrawal] Created:', {
      id: withdrawal.id.toString(),
      amount: dto.amount,
      fee,
      netAmount,
      method: dto.method,
    });

    return this.formatWithdrawal(withdrawal);
  }

  /**
   * Get provider's withdrawals
   */
  async getProviderWithdrawals(providerId: bigint, status?: string) {
    const where: any = { providerId };
    if (status) {
      where.status = status;
    }

    const withdrawals = await this.prisma.withdrawal.findMany({
      where,
      orderBy: { createdAt: 'desc' },
    });

    return withdrawals.map((w) => this.formatWithdrawal(w));
  }

  /**
   * Get pending withdrawals (admin)
   */
  async getPendingWithdrawals() {
    const withdrawals = await this.prisma.withdrawal.findMany({
      where: { status: 'pending' },
      include: {
        provider: {
          include: { profile: true },
        },
      },
      orderBy: { createdAt: 'asc' },
    });

    return withdrawals.map((w) => ({
      ...this.formatWithdrawal(w),
      provider: w.provider?.profile
        ? {
            id: w.provider.id.toString(),
            fullName: w.provider.profile.fullName,
            phone: w.provider.phone,
          }
        : undefined,
    }));
  }

  /**
   * Process withdrawal (admin)
   */
  async processWithdrawal(
    withdrawalId: bigint,
    adminId: bigint,
    approve: boolean,
    note?: string,
  ) {
    const withdrawal = await this.prisma.withdrawal.findUnique({
      where: { id: withdrawalId },
    });

    if (!withdrawal) {
      throw new NotFoundException('Yêu cầu rút tiền không tồn tại');
    }

    if (withdrawal.status !== 'pending') {
      throw new BadRequestException('Yêu cầu đã được xử lý');
    }

    if (approve) {
      // Approve withdrawal
      const updated = await this.prisma.withdrawal.update({
        where: { id: withdrawalId },
        data: {
          status: 'completed',
          processedBy: adminId,
          processedAt: new Date(),
          adminNote: note,
        },
      });

      // Update wallet transaction status
      await this.prisma.walletTransaction.updateMany({
        where: {
          walletUserId: withdrawal.providerId,
          metadata: { path: ['withdrawalId'], equals: withdrawalId.toString() },
        },
        data: { status: 'completed' },
      });

      console.log('[Withdrawal] Approved:', withdrawalId.toString());
      return this.formatWithdrawal(updated);
    } else {
      // Reject withdrawal - refund to wallet
      const [updated] = await this.prisma.$transaction([
        this.prisma.withdrawal.update({
          where: { id: withdrawalId },
          data: {
            status: 'cancelled',
            processedBy: adminId,
            processedAt: new Date(),
            adminNote: note,
          },
        }),
        this.prisma.wallet.update({
          where: { userId: withdrawal.providerId },
          data: {
            balance: { increment: withdrawal.amount },
          },
        }),
      ]);

      // Update wallet transaction status
      await this.prisma.walletTransaction.updateMany({
        where: {
          walletUserId: withdrawal.providerId,
          metadata: { path: ['withdrawalId'], equals: withdrawalId.toString() },
        },
        data: { status: 'failed' },
      });

      console.log('[Withdrawal] Rejected:', withdrawalId.toString());
      return this.formatWithdrawal(updated);
    }
  }

  /**
   * Format withdrawal for response
   */
  private formatWithdrawal(withdrawal: any) {
    return {
      id: withdrawal.id.toString(),
      providerId: withdrawal.providerId.toString(),
      amount: Number(withdrawal.amount),
      fee: Number(withdrawal.fee),
      netAmount: Number(withdrawal.netAmount),
      method: withdrawal.method,
      bankName: withdrawal.bankName,
      bankAccount: withdrawal.bankAccount,
      bankHolder: withdrawal.bankHolder,
      momoPhone: withdrawal.momoPhone,
      status: withdrawal.status,
      note: withdrawal.note,
      adminNote: withdrawal.adminNote,
      createdAt: withdrawal.createdAt,
      processedAt: withdrawal.processedAt,
    };
  }
}
