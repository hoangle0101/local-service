import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log('🌱 Creating Completed Booking for Review Test (Raw SQL)...');

    // 1. Get IDs
    const users = await prisma.user.findMany({
        where: { phone: { in: ['0912345678', '0901234567'] } },
    });

    const customer = users.find(u => u.phone === '0912345678');
    const provider = users.find(u => u.phone === '0901234567');

    if (!customer || !provider) {
        console.error('❌ Users not found. Run seed.');
        return;
    }

    // 2. Get Service
    const providerService = await prisma.providerService.findFirst({
        where: { providerUserId: provider.id },
    });

    if (!providerService) {
        console.error('❌ Provider service not found.');
        return;
    }

    const bookingCode = 'REV_' + Math.floor(Math.random() * 10000);
    const price = 200000;

    // 3. Insert Booking
    await prisma.$executeRawUnsafe(`
    INSERT INTO bookings (
      code, customer_id, provider_id, service_id, provider_service_price, 
      status, scheduled_at, address_text, location, 
      estimated_price, actual_price, completed_at, created_at, updated_at
    ) VALUES (
      '${bookingCode}',
      ${customer.id},
      ${provider.id},
      ${providerService.serviceId},
      ${price},
      'completed',
      NOW() - INTERVAL '1 day',
      '123 Test Location',
      ST_SetSRID(ST_MakePoint(106.7, 10.7), 4326),
      ${price},
      ${price},
      NOW(),
      NOW(),
      NOW()
    );
  `);

    // Get the ID
    const newBooking = await prisma.booking.findUnique({
        where: { code: bookingCode }
    });

    console.log('✅ Created Booking:');
    console.log(`   - ID: ${newBooking?.id}`);
    console.log(`   - Code: ${bookingCode}`);
    console.log(`   - Status: completed`);
    console.log(`   - Customer: 0912345678`);
    console.log(`   - Provider: 0901234567`);
    console.log('👉 You can now log in as Customer 1 and review this booking.');
}

main()
    .catch((e) => console.error(e))
    .finally(async () => await prisma.$disconnect());
