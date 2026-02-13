import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function checkProvider() {
  try {
    const provider = await prisma.providerProfile.findFirst({
      include: {
        providerServices: true,
      }
    });
    console.log('Provider:', JSON.stringify(provider, (key, value) =>
      typeof value === 'bigint' ? value.toString() : value
    , 2));
    
    // Check if location is set (it's a raw field, might not show up fully in JSON if not handled)
    // But we can check latitude/longitude if we query it specifically or just trust the seed.
    // Let's try to query with raw SQL to see the point coordinates
    if (provider) {
      const location = await prisma.$queryRaw`
        SELECT ST_AsText(location) as location_text, ST_X(location::geometry) as lng, ST_Y(location::geometry) as lat 
        FROM provider_profiles 
        WHERE user_id = ${provider.userId}
      `;
      console.log('Location:', location);
    }

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkProvider();
