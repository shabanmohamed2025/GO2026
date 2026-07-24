require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const { Pool } = require('pg');
const { PrismaPg } = require('@prisma/adapter-pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  try {
    const updated = await prisma.driver.updateMany({
      data: {
        currentLat: 30.0450,
        currentLng: 31.2360,
        isOnline: true
      }
    });
    console.log(`Updated ${updated.count} drivers with valid coordinates.`);
  } catch (err) {
    console.error('Error:', err);
  } finally {
    await prisma.$disconnect();
    await pool.end();
  }
}

main();
