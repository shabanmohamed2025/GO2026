const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function execute() {
  await prisma.driver.deleteMany();
  console.log('Successfully deleted all drivers from the database to allow fresh testing.');
  await prisma.$disconnect();
}

execute().catch(e => {
  console.error(e);
  process.exit(1);
});
