const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting seed (simplified version)...');
  
  // Delete all data
  console.log('🗑️  Clearing database...');
  await prisma.walletTransaction.deleteMany();
  await prisma.payment.deleteMany();
  await prisma.review.deleteMany();
  await prisma.dispute.deleteMany();
  await prisma.booking.deleteMany();
  await prisma.providerService.deleteMany();
  await prisma.service.deleteMany();
  await prisma.serviceCategory.deleteMany();
  await prisma.providerProfile.deleteMany();
  await prisma.wallet.deleteMany();
  await prisma.userRole.deleteMany();
  await prisma.user.deleteMany();
  
  console.log('✅ Database cleared!');

  // Create Roles
  console.log('👥 Creating roles...');
  const customerRole = await prisma.role.upsert({
    where: { name: 'customer' },
    update: {},
    create: { name: 'customer', description: 'Regular customer' },
  });
  
  const providerRole = await prisma.role.upsert({
    where: { name: 'provider' },
    update: {},
    create: { name: 'provider', description: 'Service provider' },
  });
  
  const adminRole = await prisma.role.upsert({
    where: { name: 'admin' },
    update: {},
    create: { name: 'admin', description: 'Platform admin' },
  });

  // Create Admin
  console.log('👨‍💼 Creating admin...');
  const adminPassword = await bcrypt.hash('Admin@123', 10);
  
  await prisma.user.create({
    data: {
      phone: '0123456789',
      email: 'admin@localservice.com',
      passwordHash: adminPassword,
      status: 'active',
      isVerified: true,
      profile: {
        create: { fullName: 'Admin User', gender: 'male' },
      },
      userRoles: {
        create: { roleId: adminRole.id },
      },
    },
  });

 //  Categories & Services
  console.log('📂 Creating categories & services...');
  const cleaningCat = await prisma.serviceCategory.create({
    data: { code: 'cleaning', name: 'Cleaning', slug: 'cleaning' },
  });

  const plumbingCat = await prisma.serviceCategory.create({
    data: { code: 'plumbing', name: 'Plumbing', slug: 'plumbing' },
  });

  const service1 = await prisma.service.create({
    data: {
      categoryId: cleaningCat.id,
      name: 'House Cleaning',
      basePrice: 200000,
      durationMinutes: 120,
    },
  });

  const service2 = await prisma.service.create({
    data: {
      categoryId: plumbingCat.id,
      name: 'Pipe Repair',
      basePrice: 150000,
      durationMinutes: 60,
    },
  });

  const services = [service1, service2];

  // Create Customers
  console.log('🙎 Creating 20 customers...');
  const customers = [];
  const testPassword = await bcrypt.hash('Test@123', 10);

  for (let i = 1; i <= 20; i++) {
    const customer = await prisma.user.create({
      data: {
        phone: `0900${String(i).padStart(6, '0')}`,
        email: `customer${i}@test.com`,
        passwordHash: testPassword,
        status: 'active',
        isVerified: true,
        profile: {
          create: { fullName: `Customer ${i}`, gender: i % 2 === 0 ? 'male' : 'female' },
        },
        userRoles: {
          create: { roleId: customerRole.id },
        },
        wallet: {
          create: { balance: 1000000, currency: 'VND' },
        },
      },
    });
    customers.push(customer);
  }

  // Create Providers
  console.log('👷 Creating 10 providers...');
  const providers = [];

  for (let i = 1; i <= 10; i++) {
    const provider = await prisma.user.create({
      data: {
        phone: `0910${String(i).padStart(6, '0')}`,
        email: `provider${i}@test.com`,
        passwordHash: testPassword,
        status: 'active',
        isVerified: true,
        profile: {
          create: { fullName: `Provider ${i}`, gender: 'male' },
        },
        userRoles: {
          create: { roleId: providerRole.id },
        },
        providerProfile: {
          create: {
            displayName: `Provider Service ${i}`,
            ratingAvg: 4.0 + (i * 0.1),
            ratingCount: 10 + i,
            isAvailable: true,
            verificationStatus: i <= 7 ? 'verified' : 'pending',
          },
        },
        wallet: {
          create: { balance: 500000, currency: 'VND' },
        },
      },
    });
    providers.push(provider);
  }

  // Link providers to services
  console.log('🔗 Linking services...');
  for (const provider of providers) {
    for (const service of services) {
      await prisma.providerService.create({
        data: {
          providerUserId: provider.id,
          serviceId: service.id,
          price: Number(service.basePrice),
          currency: 'VND',
          isActive: true,
        },
      });
    }
  }

  // Create Bookings
  console.log('📅 Creating 50 bookings...');
  const statuses = ['pending', 'accepted', 'in_progress', 'completed', 'cancelled'];

  for (let i = 0; i < 50; i++) {
    const customer = customers[i % customers.length];
    const provider = providers[i % providers.length];
    const service = services[i % services.length];
    const status = statuses[i % statuses.length];
    
    const actualPrice = status === 'completed' ? 200000 : null;
    const lat = 10.7769 + (Math.random() * 0.1);
    const lng = 106.7009 + (Math.random() * 0.1);
    const completedAt = status === 'completed' ? new Date().toISOString() : null;
    const cancelledAt = status === 'cancelled' ? new Date().toISOString() : null;

    // Use raw SQL to insert booking with PostGIS location
    await prisma.$executeRawUnsafe(`
      INSERT INTO bookings (
        code, customer_id, provider_id, service_id, status,
        scheduled_at, address_text, location,
        estimated_price, actual_price, platform_fee, provider_earning,
        completed_at, cancelled_at, created_at, updated_at
      ) VALUES (
        'BK${Date.now()}-${i}',
        ${customer.id},
        ${provider.id},
        ${service.id},
        '${status}',
        NOW(),
        '${i + 1} Test Address, HCMC',
        ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326),
        200000,
        ${actualPrice || 'NULL'},
        ${actualPrice ? 20000 : 0},
        ${actualPrice ? 180000 : 0},
        ${completedAt ? `'${completedAt}'` : 'NULL'},
        ${cancelledAt ? `'${cancelledAt}'` : 'NULL'},
        NOW(),
        NOW()
      )
    `);
    
    if ((i + 1) % 10 === 0) console.log(`  Created ${i + 1} bookings...`);
  }

  console.log('\n✅ Seed completed!\n');
  console.log('📊 Summary:');
  console.log('- Admin: 1 (phone=0123456789, password=Admin@123)');
  console.log('- Customers: 20');
  console.log('- Providers: 10 (7 verified, 3 pending)');
  console.log('- Services: 2');
  console.log('- Provider Services: 20');
  console.log('- Bookings: 50\n');
  console.log('🚀 Login with phone=0123456789, password=Admin@123\n');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
