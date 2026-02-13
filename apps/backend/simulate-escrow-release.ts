import { PrismaClient } from '@prisma/client';
import { BookingPaymentService } from './src/modules/payment/booking-payment.service';
import { WalletsService } from './src/modules/wallets/wallets.service';
import { PrismaService } from './src/prisma/prisma.service';

async function main() {
  const prismaService = new PrismaService();
  const walletsService = new WalletsService(prismaService, null as any); // Mocking momoService
  const bookingPaymentService = new BookingPaymentService(
    prismaService,
    null as any,
    walletsService,
    null as any,
    null as any,
  );

  const bookingId = BigInt(113);
  const customerId = BigInt(54);
  const providerId = BigInt(51);

  console.log('💰 Initial Wallet Balance (Provider 51):');
  const initialWallet = await prismaService.wallet.findUnique({
    where: { userId: providerId },
  });
  console.log(initialWallet?.balance.toString());

  console.log('\n🔓 Releasing Escrow for Booking 113...');
  try {
    const result = await bookingPaymentService.releaseEscrow(
      bookingId,
      customerId,
    );
    console.log('✅ Result:', result);

    console.log('\n💰 Final Wallet Balance (Provider 51):');
    const finalWallet = await prismaService.wallet.findUnique({
      where: { userId: providerId },
    });
    console.log(finalWallet?.balance.toString());

    const finalBooking = await prismaService.booking.findUnique({
      where: { id: bookingId },
    });
    console.log(
      '📝 Final Booking Payment Status:',
      finalBooking?.paymentStatus,
    );
  } catch (e: any) {
    console.error('❌ Error Message:', e.message);
    if (e.response) {
      console.error('❌ Detailed Error:', JSON.stringify(e.response, null, 2));
    }
  } finally {
    await prismaService.$disconnect();
  }
}

main();
