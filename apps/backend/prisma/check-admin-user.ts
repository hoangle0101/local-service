import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function checkAdminUser() {
  console.log('🔍 Checking admin user 0900000000...\n');

  // Find user
  const user = await prisma.user.findUnique({
    where: { phone: '0900000000' },
    include: {
      userRoles: {
        include: {
          role: true,
        },
      },
      profile: true,
    },
  });

  if (!user) {
    console.log('❌ User 0900000000 not found in database');
    console.log('   This user needs to be created first');
    return;
  }

  console.log('✅ User found:');
  console.log(`   ID: ${user.id}`);
  console.log(`   Phone: ${user.phone}`);
  console.log(`   Email: ${user.email || 'N/A'}`);
  console.log(`   Status: ${user.status}`);
  console.log(`   Verified: ${user.isVerified}`);
  console.log(`   Full Name: ${user.profile?.fullName || 'N/A'}`);
  console.log(`\n   Roles:`);
  
  if (user.userRoles.length === 0) {
    console.log('   ❌ NO ROLES ASSIGNED - This is the problem!');
  } else {
    user.userRoles.forEach((ur) => {
      console.log(`   - ${ur.role.name} (${ur.role.description})`);
    });
  }

  // Check if user has admin role
  const hasAdminRole = user.userRoles.some(
    (ur) => ur.role.name === 'super_admin' || ur.role.name === 'admin'
  );

  console.log('\n📊 Analysis:');
  if (!hasAdminRole) {
    console.log('❌ User does NOT have admin/super_admin role');
    console.log('   This is why /admin/dashboard returns 401');
    console.log('\n💡 Solution: Assign super_admin role to this user');
  } else {
    console.log('✅ User has admin role - authorization should work');
    console.log('   If still getting 401, check:');
    console.log('   1. Token is being sent in Authorization header');
    console.log('   2. Token is valid and not expired');
    console.log('   3. Backend RolesGuard is working correctly');
  }
}

checkAdminUser()
  .catch((e) => {
    console.error('❌ Error:', e);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
