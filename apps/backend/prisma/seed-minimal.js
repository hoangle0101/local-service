const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding minimal data (roles + admin only)...');

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
  console.log('✅ Created 3 roles');

  // Create Admin
  console.log('👨‍💼 Creating admin...');
  const adminPassword = await bcrypt.hash('Admin@123', 10);
  
  const admin = await prisma.user.upsert({
    where: { phone: '0123456789' },
    update: {},
    create: {
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
  console.log('✅ Admin created (phone=0123456789, password=Admin@123)');

  console.log('\n🎉 Minimal seed completed!');
  console.log('');
  console.log('📊 Summary:');
  console.log('- Roles: 3 (customer, provider, admin)');
  console.log('- Admin: 1');
  console.log('');
  console.log('🚀 Now run: npx ts-node prisma/seed-marketplace.ts');
  console.log('   to add 5 categories and 8 services');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
