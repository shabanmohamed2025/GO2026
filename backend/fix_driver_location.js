const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  try {
    const drivers = await prisma.driver.findMany();
    if (drivers.length > 0) {
      const updated = await prisma.driver.updateMany({
        data: {
          currentLat: 30.0450,
          currentLng: 31.2360,
          isOnline: true,
          approvalStatus: 'APPROVED'
        }
      });
      console.log(`Updated ${updated.count} drivers with location.`);
    } else {
      console.log('No drivers found to update.');
    }
  } catch (error) {
    console.error('Error updating drivers:', error);
  } finally {
    await prisma.$disconnect();
  }
}

main();
