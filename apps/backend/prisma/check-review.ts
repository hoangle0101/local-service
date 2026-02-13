import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log('🔍 Checking Provider Profile Stats...');

    const provider = await prisma.user.findUnique({ where: { phone: '0901234567' } });
    if (!provider) {
        console.log('Provider not found');
        return;
    }

    // 1. Get Profile from DB Table
    const profile = await prisma.providerProfile.findUnique({
        where: { userId: provider.id },
    });

    // 2. Get Real Stats from Reviews Table
    const reviews = await prisma.review.findMany({
        where: { revieweeId: provider.id },
    });

    const count = reviews.length;
    const sum = reviews.reduce((acc, r) => acc + r.rating, 0);
    const realAvg = count > 0 ? (sum / count).toFixed(2) : '0.00';

    console.log('--------------------------------------------------');
    console.log(`Provider: ${profile?.displayName} (ID: ${provider.id})`);
    console.log(`[Database Table] Rating Avg: ${profile?.ratingAvg}, Count: ${profile?.ratingCount}`);
    console.log(`[Real Calculation] Rating Avg: ${realAvg}, Count: ${count}`);

    if (Number(profile?.ratingAvg) !== Number(realAvg) || profile?.ratingCount !== count) {
        console.log('⚠️  MISMATCH DETECTED: ProviderProfile table is NOT updated!');
        console.log('   The "Dashboard/Profile" screens using API /statistics will be correct.');
        console.log('   The "Service List" screens using provider_profiles table might show old data.');
    } else {
        console.log('✅ Data is CONSISTENT.');
    }
    console.log('--------------------------------------------------');
}

main()
    .catch((e) => console.error(e))
    .finally(async () => await prisma.$disconnect());
