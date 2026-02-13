import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  try {
    const bookings = await prisma.booking.findMany({
      take: 10,
      orderBy: { updatedAt: 'desc' },
      select: {
        id: true,
        code: true,
        status: true,
        paymentStatus: true,
        paymentMethod: true,
        customerId: true,
        providerId: true,
        updatedAt: true,
      },
    });
    console.log(
      JSON.stringify(
        bookings,
        (key, value) => (typeof value === 'bigint' ? value.toString() : value),
        2,
      ),
    );
  } catch (e) {
    console.error(e);
  } finally {
    await prisma.$disconnect();
  }
}

main();
