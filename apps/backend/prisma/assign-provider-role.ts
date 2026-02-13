import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function assignProviderRole() {
  try {
    // Get first user
    const user = await prisma.user.findFirst();
    if (!user) {
      console.log('❌ No user found');
      return;
    }

    console.log(`Found user: ${user.id}`);

    // Create or get provider role
    const providerRole = await prisma.role.upsert({
      where: { name: 'provider' },
      update: {},
      create: {
        name: 'provider',
        description: 'Service provider role',
      },
    });

    console.log(`Provider role: ${providerRole.id}`);

    // Assign role to user
    const userRole = await prisma.userRole.upsert({
      where: {
        userId_roleId: {
          userId: user.id,
          roleId: providerRole.id,
        },
      },
      update: {},
      create: {
        userId: user.id,
        roleId: providerRole.id,
      },
    });

    console.log('✅ Provider role assigned successfully!');
    console.log(`User ${user.id.toString()} now has provider role`);
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

assignProviderRole();
