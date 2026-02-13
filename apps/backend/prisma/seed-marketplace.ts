import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding database...');

  // Seed categories
  console.log('Creating categories...');
  const categories = await Promise.all([
    prisma.serviceCategory.upsert({
      where: { slug: 'home-cleaning' },
      update: {},
      create: {
        code: 'HOME_CLEANING',
        name: 'Dọn dẹp nhà cửa',
        slug: 'home-cleaning',
        description: 'Dịch vụ dọn dẹp nhà cửa chuyên nghiệp',
        iconUrl: 'https://img.icons8.com/plasticine/100/000000/cleaning-service.png',
      },
    }),
    prisma.serviceCategory.upsert({
      where: { slug: 'plumbing' },
      update: {},
      create: {
        code: 'PLUMBING',
        name: 'Sửa điện nước',
        slug: 'plumbing',
        description: 'Sửa chữa và lắp đặt điện nước tận nơi',
        iconUrl: 'https://img.icons8.com/plasticine/100/000000/plumbing.png',
      },
    }),
    prisma.serviceCategory.upsert({
      where: { slug: 'electrical-refrigeration' },
      update: {},
      create: {
        code: 'ELECTRICAL_REFRIGERATION',
        name: 'Sửa Điện Lạnh',
        slug: 'electrical-refrigeration',
        description: 'Sửa điều hòa, tủ lạnh, máy giặt',
        iconUrl: 'https://img.icons8.com/plasticine/100/000000/air-conditioner.png',
      },
    }),
    prisma.serviceCategory.upsert({
      where: { slug: 'beauty-at-home' },
      update: {},
      create: {
        code: 'BEAUTY_AT_HOME',
        name: 'Làm Đẹp tại nhà',
        slug: 'beauty-at-home',
        description: 'Cắt tóc, trang điểm, làm móng tận nơi',
        iconUrl: 'https://img.icons8.com/plasticine/100/000000/cosmetics.png',
      },
    }),
    prisma.serviceCategory.upsert({
      where: { slug: 'vehicle-repair' },
      update: {},
      create: {
        code: 'VEHICLE_REPAIR',
        name: 'Sửa Xe Tận Nơi',
        slug: 'vehicle-repair',
        description: 'Cứu hộ xe máy, thay dầu, rửa xe tại nhà',
        iconUrl: 'https://img.icons8.com/plasticine/100/000000/motorcycle.png',
      },
    }),
  ]);
  console.log(`✅ Created ${categories.length} categories`);

  // Seed services
  console.log('Creating services...');
  const services = await Promise.all([
    // Category: Home Cleaning (0)
    prisma.service.upsert({
      where: { id: 1 },
      update: { name: 'Dọn dẹp nhà cơ bản', basePrice: 150000 },
      create: {
        id: 1,
        categoryId: categories[0].id,
        name: 'Dọn dẹp nhà cơ bản',
        description: 'Quét dọn, lau chùi nhà cửa thông thường',
        basePrice: 150000,
        durationMinutes: 120,
      },
    }),
    prisma.service.upsert({
      where: { id: 2 },
      update: { name: 'Tổng vệ sinh chuyên sâu', basePrice: 450000 },
      create: {
        id: 2,
        categoryId: categories[0].id,
        name: 'Tổng vệ sinh chuyên sâu',
        description: 'Vệ sinh toàn bộ ngóc ngách, tẩy rửa vết bẩn cứng đầu',
        basePrice: 450000,
        durationMinutes: 240,
      },
    }),
    // Category: Plumbing (1)
    prisma.service.upsert({
      where: { id: 3 },
      update: { name: 'Sửa vòi nước rò rỉ', basePrice: 100000 },
      create: {
        id: 3,
        categoryId: categories[1].id,
        name: 'Sửa vòi nước rò rỉ',
        description: 'Thay thế hoặc sửa chữa vòi nước bị hỏng',
        basePrice: 100000,
        durationMinutes: 45,
      },
    }),
    // Category: Electrical Refrigeration (2)
    prisma.service.upsert({
      where: { id: 7 },
      update: {},
      create: {
        id: 7,
        categoryId: categories[2].id,
        name: 'Vệ sinh điều hòa (Máy lạnh)',
        description: 'Rửa lưới lọc, nạp gas, kiểm tra hệ thống lạnh',
        basePrice: 250000,
        durationMinutes: 60,
      },
    }),
    prisma.service.upsert({
      where: { id: 8 },
      update: {},
      create: {
        id: 8,
        categoryId: categories[2].id,
        name: 'Sửa tủ lạnh tại nhà',
        description: 'Kiểm tra lỗi máy nén, hỏng gioăng, không lạnh',
        basePrice: 300000,
        durationMinutes: 90,
      },
    }),
    // Category: Beauty (3)
    prisma.service.upsert({
      where: { id: 9 },
      update: {},
      create: {
        id: 9,
        categoryId: categories[3].id,
        name: 'Cắt tóc nam tại nhà',
        description: 'Cắt tóc, tạo kiểu chuyên nghiệp tận nơi',
        basePrice: 120000,
        durationMinutes: 40,
      },
    }),
    prisma.service.upsert({
      where: { id: 10 },
      update: {},
      create: {
        id: 10,
        categoryId: categories[3].id,
        name: 'Trang điểm dự tiệc',
        description: 'Trang điểm phong cách tự nhiên hoặc sang trọng',
        basePrice: 350000,
        durationMinutes: 60,
      },
    }),
    // Category: Vehicle Repair (4)
    prisma.service.upsert({
      where: { id: 11 },
      update: {},
      create: {
        id: 11,
        categoryId: categories[4].id,
        name: 'Cứu hộ, vá săm xe máy',
        description: 'Vá xe tận nơi khi gặp sự cố trên đường',
        basePrice: 80000,
        durationMinutes: 30,
      },
    }),
  ]);
  console.log(`✅ Created ${services.length} services`);

  // Check if user exists
  const user = await prisma.user.findFirst();
  if (!user) {
    console.log('⚠️  No users found. Please register a user first.');
    return;
  }

  // Create provider profile
  console.log('Creating provider profile...');
  const provider = await prisma.providerProfile.upsert({
    where: { userId: user.id },
    update: {},
    create: {
      userId: user.id,
      displayName: 'John Cleaning Services',
      bio: 'Professional cleaner with 5 years experience',
      ratingAvg: 4.5,
      ratingCount: 20,
      isAvailable: true,
      verificationStatus: 'verified',
      serviceRadiusM: 10000,
    },
  });
  console.log(`✅ Created provider profile for user ${user.id}`);

  // Add services to provider
  console.log('Adding services to provider...');
  await prisma.providerService.upsert({
    where: {
      providerUserId_serviceId: {
        providerUserId: user.id,
        serviceId: 1,
      },
    },
    update: {},
    create: {
      providerUserId: user.id,
      serviceId: 1,
      price: 200000,
      currency: 'VND',
      isActive: true,
    },
  });

  await prisma.providerService.upsert({
    where: {
      providerUserId_serviceId: {
        providerUserId: user.id,
        serviceId: 2,
      },
    },
    update: {},
    create: {
      providerUserId: user.id,
      serviceId: 2,
      price: 350000,
      currency: 'VND',
      isActive: true,
    },
  });
  console.log(`✅ Added 2 services to provider`);

  console.log('🎉 Seeding completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Seeding failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
