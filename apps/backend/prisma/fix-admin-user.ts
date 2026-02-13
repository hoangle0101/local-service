import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function fixAdminUser() {
  console.log('🔧 Checking and fixing admin user 0900000000...\n');

  // Find user
  let user = await prisma.user.findUnique({
    where: { phone: '0900000000' },
    include: {
      userRoles: {
        include: {
          role: true,
        },
      },
    },
  });

  if (!user) {
    console.log('❌ User 0900000000 not found');
    console.log('   Creating admin user...\n');

    // Get super_admin role
    const adminRole = await prisma.role.findUnique({
      where: { name: 'super_admin' },
    });

    if (!adminRole) {
      console.log('❌ super_admin role not found. Please run: npm run seed');
      return;
    }

    // Create admin user
    const hashedPassword = await bcrypt.hash('Admin123!@#', 10);
    
    user = await prisma.user.create({
      data: {
        phone: '0900000000',
        email: 'admin@gmail.com',
        passwordHash: hashedPassword,
        status: 'active',
        isVerified: true,
        profile: {
          create: {
            fullName: 'ADMIN',
          },
        },
        wallet: {
          create: {
            balance: 0,
            currency: 'VND',
          },
        },
        userRoles: {
          create: {
            roleId: adminRole.id,
          },
        },
      },
      include: {
        userRoles: {
          include: {
            role: true,
          },
        },
      },
    });

    console.log('✅ Admin user created successfully!');
    console.log(`   Phone: 0900000000`);
    console.log(`   Password: Admin123!@#`);
    console.log(`   Role: super_admin\n`);
  } else {
    console.log('✅ User found');
    console.log(`   Roles: ${user.userRoles.map(ur => ur.role.name).join(', ') || 'NONE'}\n`);

    // Check if user has admin role
    const hasAdminRole = user.userRoles.some(
      ur => ur.role.name === 'super_admin' || ur.role.name === 'admin'
    );

    if (!hasAdminRole) {
      console.log('⚠️  User does NOT have admin role. Fixing...\n');

      // Get super_admin role
      const adminRole = await prisma.role.findUnique({
        where: { name: 'super_admin' },
      });

      if (!adminRole) {
        console.log('❌ super_admin role not found. Please run: npm run seed');
        return;
      }

      // Assign super_admin role
      await prisma.userRole.create({
        data: {
          userId: user.id,
          roleId: adminRole.id,
        },
      });

      console.log('✅ super_admin role assigned successfully!\n');
    } else {
      console.log('✅ User already has admin role - no fix needed\n');
    }
  }

  console.log('🎉 Done! You can now login with:');
  console.log('   Phone: 0900000000');
  console.log('   Password: Admin123!@#');
}

fixAdminUser()
  .catch((e) => {
    console.error('❌ Error:', e);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
