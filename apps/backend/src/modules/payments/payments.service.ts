import {
    BadRequestException,
    Injectable,
    NotFoundException,
    UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CheckoutDto } from './dto/payment.dto';
import { Decimal } from '@prisma/client/runtime/library';

@Injectable()
export class PaymentsService {
    constructor(private prisma: PrismaService) { }

    /**
     * Checkout booking
     */
    async checkout(userId: bigint, dto: CheckoutDto) {
        const booking = await this.prisma.booking.findUnique({
            where: { id: BigInt(dto.bookingId) },
            include: { customer: { include: { wallet: true } } },
        });

        if (!booking || booking.customerId !== userId) {
            throw new NotFoundException('Booking not found');
        }

        if (booking.status === 'completed' || booking.status === 'cancelled') {
            throw new BadRequestException('Booking is already completed or cancelled');
        }

        // Check if already paid (via payment status or completed booking)
        // Note: Schema doesn't have paymentStatus on Booking, checking via Payment table or logic
        const successPayment = await this.prisma.payment.findFirst({
            where: {
                bookingId: booking.id,
                status: 'succeeded'
            }
        });

        if (successPayment) {
            throw new BadRequestException('Booking already paid');
        }

        const totalAmount = booking.estimatedPrice || new Decimal(0); // Use estimated price for now

        // Wallet payment
        if (dto.paymentMethod === 'wallet') {
            const wallet = booking.customer.wallet;

            if (!wallet) {
                throw new BadRequestException('User wallet not found');
            }

            if (wallet.balance.lessThan(totalAmount)) {
                throw new BadRequestException('Insufficient wallet balance');
            }

            return this.prisma.$transaction(async (tx) => {
                // Deduct from wallet
                await tx.wallet.update({
                    where: { userId: wallet.userId },
                    data: { balance: { decrement: totalAmount } },
                });

                // Create wallet transaction
                await tx.walletTransaction.create({
                    data: {
                        walletUserId: wallet.userId,
                        type: 'payment',
                        amount: totalAmount,
                        balanceAfter: wallet.balance.minus(totalAmount),
                        status: 'completed',
                        metadata: { description: `Payment for booking #${booking.id}` },
                    },
                });

                // Create payment record
                const payment = await tx.payment.create({
                    data: {
                        bookingId: booking.id,
                        amount: totalAmount,
                        currency: 'VND',
                        method: 'wallet',
                        gateway: 'wallet',
                        gatewayTxId: `wallet_${Date.now()}`,
                        status: 'succeeded',
                        payload: {},
                    },
                });

                // Update booking status to accepted (if pending) or just mark as paid logic
                // For now, we assume payment confirms the booking if it was pending
                if (booking.status === 'pending') {
                    await tx.booking.update({
                        where: { id: booking.id },
                        data: { status: 'accepted' }
                    });
                }

                return {
                    message: 'Payment successful',
                    paymentId: payment.id.toString(),
                    status: 'succeeded'
                };
            });
        }

        // Gateway payment (Momo/Stripe)
        return this.prisma.$transaction(async (tx) => {
            const payment = await tx.payment.create({
                data: {
                    bookingId: booking.id,
                    amount: totalAmount,
                    currency: 'VND',
                    method: dto.paymentMethod === 'momo' ? 'momo' : dto.paymentMethod === 'stripe' ? 'card' : 'bank_transfer',
                    gateway: dto.paymentMethod,
                    gatewayTxId: `pending_${Date.now()}`,
                    status: 'initiated',
                    payload: {},
                },
            });

            // Generate payment URL
            const paymentUrl = this.generatePaymentUrl(
                payment.id,
                dto.paymentMethod,
                Number(totalAmount),
            );

            return {
                paymentId: payment.id.toString(),
                paymentUrl,
                amount: totalAmount.toString(),
                status: 'initiated'
            };
        });
    }

    /**
     * Handle payment webhook
     */
    async handleWebhook(gateway: string, body: any, signature: string) {
        // 1. Verify signature
        const isValid = this.verifyWebhookSignature(gateway, body, signature);
        if (!isValid) {
            throw new UnauthorizedException('Invalid webhook signature');
        }

        // 2. Extract payment info (gateway-specific)
        const { transactionId, status, amount } = this.parseWebhookData(
            gateway,
            body,
        );

        // 3. Find payment
        // Note: gatewayTxId in DB might be 'pending_...' initially, but real gateways return their own ID.
        // For this mock, we assume the gateway returns the ID we sent (orderId) or we look up by our ID.
        // In real world, we store gateway's ID after first response or use our ID as reference.
        // Here we assume transactionId from webhook matches what we stored or is our payment ID.

        // Strategy: We stored `pending_${timestamp}` or `pending_${txId}`.
        // If we sent payment.id as orderId to gateway, we should look up by payment.id.
        // Let's assume transactionId is our payment.id for simplicity in this mock.

        let payment = await this.prisma.payment.findFirst({
            where: { id: BigInt(transactionId) }
        });

        if (!payment) {
            // Try finding by gatewayTxId if it was updated
            payment = await this.prisma.payment.findFirst({
                where: { gatewayTxId: transactionId, gateway }
            });
        }

        if (!payment) {
            console.error(`Payment not found: ${transactionId}`);
            return { message: 'Payment not found' };
        }

        // 4. Check idempotency (prevent double processing)
        if (payment.status === 'succeeded') {
            console.log(`Payment already processed: ${transactionId}`);
            return { message: 'Already processed' };
        }

        // 5. Process based on status
        if (status === 'success') {
            await this.processSuccessfulPayment(payment, amount);
        } else if (status === 'failed') {
            await this.processFailedPayment(payment);
        }

        // 6. Log to audit
        await this.prisma.auditLog.create({
            data: {
                actorUserId: null,
                action: 'payment_webhook',
                objectType: 'payment',
                objectId: payment.id,
                detail: {
                    gateway,
                    transactionId,
                    status,
                    amount,
                },
            },
        });

        return { message: 'Webhook processed' };
    }

    private async processSuccessfulPayment(payment: any, amount: number) {
        return this.prisma.$transaction(async (tx) => {
            // Update payment status
            await tx.payment.update({
                where: { id: payment.id },
                data: { status: 'succeeded' },
            });

            const payload = payment.payload as any;

            // If deposit: Update wallet
            if (payload?.type === 'deposit') {
                const transactionId = BigInt(payload.walletTransactionId);

                const transaction = await tx.walletTransaction.findUnique({
                    where: { id: transactionId },
                });

                if (transaction) {
                    // Update transaction status
                    await tx.walletTransaction.update({
                        where: { id: transaction.id },
                        data: { status: 'completed' },
                    });

                    // Update wallet balance
                    await tx.wallet.update({
                        where: { userId: transaction.walletUserId },
                        data: { balance: { increment: new Decimal(amount) } },
                    });
                }
            }

            // If booking: Update booking
            if (payment.bookingId) {
                // Update booking status if needed
                const booking = await tx.booking.findUnique({
                    where: { id: payment.bookingId }
                });

                if (booking && booking.status === 'pending') {
                    await tx.booking.update({
                        where: { id: payment.bookingId },
                        data: { status: 'accepted' }
                    });
                }

                // Notify provider
                if (booking && booking.providerId) {
                    await tx.notification.create({
                        data: {
                            userId: booking.providerId,
                            type: 'payment_received',
                            title: 'Payment Received',
                            body: `Payment received for booking #${booking.id}`,
                            payload: { bookingId: booking.id.toString() },
                            isRead: false,
                        },
                    });
                }
            }

            // Notify user
            const userId = payment.bookingId
                ? (await tx.booking.findUnique({ where: { id: payment.bookingId } }))?.customerId
                : (payload?.userId ? BigInt(payload.userId) : null);

            if (userId) {
                await tx.notification.create({
                    data: {
                        userId: userId,
                        type: 'payment_success',
                        title: 'Payment Successful',
                        body: `Your payment of ${amount} VND was successful`,
                        payload: { paymentId: payment.id.toString() },
                        isRead: false,
                    },
                });
            }
        });
    }

    private async processFailedPayment(payment: any) {
        await this.prisma.payment.update({
            where: { id: payment.id },
            data: { status: 'failed' },
        });

        // Notify user
        const payload = payment.payload as any;
        const userId = payment.bookingId
            ? (await this.prisma.booking.findUnique({ where: { id: payment.bookingId } }))?.customerId
            : (payload?.userId ? BigInt(payload.userId) : null);

        if (userId) {
            await this.prisma.notification.create({
                data: {
                    userId: userId,
                    type: 'payment_failed',
                    title: 'Payment Failed',
                    body: `Your payment of ${payment.amount} VND failed`,
                    payload: { paymentId: payment.id.toString() },
                    isRead: false,
                },
            });
        }
    }

    private verifyWebhookSignature(
        gateway: string,
        body: any,
        signature: string,
    ): boolean {
        // TODO: Implement signature verification
        // Momo: HMAC SHA256
        // Stripe: stripe.webhooks.constructEvent

        if (process.env.NODE_ENV !== 'production') {
            return true; // Skip verification in dev
        }

        // Production implementation
        // const secret = process.env[`${gateway.toUpperCase()}_WEBHOOK_SECRET`];
        // ... verify signature

        return true;
    }

    private parseWebhookData(gateway: string, body: any): any {
        // Parse gateway-specific webhook data
        if (gateway === 'momo') {
            return {
                transactionId: body.orderId, // We sent payment.id as orderId
                status: body.resultCode === 0 ? 'success' : 'failed',
                amount: body.amount,
            };
        }

        if (gateway === 'stripe') {
            // Mock stripe structure
            return {
                transactionId: body.data?.object?.metadata?.paymentId || body.data?.object?.id,
                status: body.type === 'payment_intent.succeeded' ? 'success' : 'failed',
                amount: (body.data?.object?.amount || 0) / 100,
            };
        }

        // Default/Mock
        return {
            transactionId: body.orderId || body.id,
            status: 'success',
            amount: body.amount || 0
        };
    }

    private generatePaymentUrl(
        paymentId: bigint,
        gateway: string,
        amount: number,
    ): string {
        // TODO: Integrate with real payment gateway
        const baseUrl = process.env.APP_URL || 'http://localhost:3000';
        return `${baseUrl}/api/v1/payments/checkout/${paymentId}?gateway=${gateway}&amount=${amount}`;
    }
}
