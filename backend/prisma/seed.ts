import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding DealSouk database...');

  // Seed AdminSettings singleton
  await prisma.adminSettings.upsert({
    where: { id: 1 },
    update: {},
    create: { id: 1, tokenEarnRate: 50, voucherThreshold: 500, dailySubmissionCap: 30 },
  });

  // Seed Badges
  const badges = [
    { id: 'first_submission', name: 'First Price', emoji: '🏷️', description: 'Submit your first price' },
    { id: 'streak_7', name: '7-Day Streak', emoji: '🔥', description: 'Submit 7 days in a row' },
    { id: 'streak_30', name: 'Monthly Regular', emoji: '📅', description: '30-day submission streak' },
    { id: 'first_request', name: 'Price Detective', emoji: '🔍', description: 'Fulfill your first price request' },
    { id: 'accuracy_90', name: 'Trusted Sourcer', emoji: '✅', description: 'Maintain 90%+ accuracy rating' },
    { id: 'voucher_earned', name: 'Voucher Winner', emoji: '🎁', description: 'Earn your first voucher' },
  ];

  for (const badge of badges) {
    await prisma.badge.upsert({ where: { id: badge.id }, update: {}, create: badge });
  }

  // Seed Stores (Dubai + Abu Dhabi major grocery chains with real coordinates)
  const stores = [
    { chain: 'Lulu Hypermarket', branchName: 'Al Barsha', area: 'Al Barsha', lat: 25.1151, lng: 55.1898 },
    { chain: 'Lulu Hypermarket', branchName: 'Deira City Centre', area: 'Deira', lat: 25.2523, lng: 55.3318 },
    { chain: 'Carrefour', branchName: 'Mall of the Emirates', area: 'Al Barsha', lat: 25.1183, lng: 55.1992 },
    { chain: 'Carrefour', branchName: 'Downtown Dubai', area: 'Downtown', lat: 25.1972, lng: 55.2744 },
    { chain: 'Carrefour', branchName: 'Mirdif City Centre', area: 'Mirdif', lat: 25.2185, lng: 55.4141 },
    { chain: 'Spinneys', branchName: 'JLT', area: 'JLT', lat: 25.0686, lng: 55.1411 },
    { chain: 'Spinneys', branchName: 'Jumeirah', area: 'Jumeirah', lat: 25.1862, lng: 55.2288 },
    { chain: 'Union Coop', branchName: 'Al Wasl', area: 'Al Wasl', lat: 25.1931, lng: 55.2368 },
    { chain: 'Union Coop', branchName: 'Al Barsha South', area: 'Al Barsha South', lat: 25.1023, lng: 55.2011 },
    { chain: 'Nesto', branchName: 'Deira', area: 'Deira', lat: 25.2723, lng: 55.3317 },
    { chain: 'Nesto', branchName: 'Muhaisnah', area: 'Muhaisnah', lat: 25.2614, lng: 55.3784 },
    { chain: 'Waitrose', branchName: 'Dubai Marina', area: 'Dubai Marina', lat: 25.0771, lng: 55.1328 },
    { chain: 'Waitrose', branchName: 'Jumeirah Lakes Towers', area: 'JLT', lat: 25.0712, lng: 55.1398 },
    { chain: 'Choithrams', branchName: 'Jumeirah Beach', area: 'Jumeirah', lat: 25.1951, lng: 55.2351 },
    { chain: 'Choithrams', branchName: 'Karama', area: 'Karama', lat: 25.2419, lng: 55.3099 },
    { chain: 'Al Madina', branchName: 'International City', area: 'International City', lat: 25.1706, lng: 55.4126 },
  ];

  const createdStores: Record<string, string> = {};
  for (const store of stores) {
    const key = `${store.chain}__${store.branchName}`;
    const existing = await prisma.store.findFirst({
      where: { chain: store.chain, branchName: store.branchName },
    });
    if (existing) {
      createdStores[key] = existing.id;
    } else {
      const created = await prisma.store.create({ data: store });
      createdStores[key] = created.id;
    }
  }

  // Seed Products
  const products = [
    { name: 'Organic Spinach', brand: 'Fresh Farms', packSize: '300 gm', category: 'Fresh', imageUrl: 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=300&q=80' },
    { name: 'Fresh Fuji Apples', brand: 'Apple Farm', packSize: '500 gm', category: 'Fruits', imageUrl: 'https://images.unsplash.com/photo-1567306226416-28f0efdc88ce?w=300&q=80' },
    { name: 'Baby Bananas', brand: 'Tropical', packSize: '1 kg', category: 'Fruits', imageUrl: 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=300&q=80' },
    { name: 'Greek Yoghurt', brand: 'Activia', packSize: '400 gm', category: 'Dairy', imageUrl: 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=300&q=80' },
    { name: 'Labneh', brand: 'Puck', packSize: '500 gm', category: 'Dairy', imageUrl: 'https://images.unsplash.com/photo-1625938143796-afe929e32eaa?w=300&q=80' },
    { name: 'Free Range Eggs', brand: 'Happy Farm', packSize: '12 pcs', category: 'Dairy', imageUrl: 'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=300&q=80' },
    { name: 'Basmati Rice', brand: 'Tilda', packSize: '2 kg', category: 'Pantry', imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=300&q=80' },
    { name: 'Extra Virgin Olive Oil', brand: 'Borges', packSize: '750 ml', category: 'Pantry', imageUrl: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=300&q=80' },
    { name: 'Whole Milk', brand: 'Almarai', packSize: '2 L', category: 'Dairy', imageUrl: 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=300&q=80' },
    { name: 'Orange Juice', brand: 'Tropicana', packSize: '1 L', category: 'Beverages', imageUrl: 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=300&q=80' },
    { name: 'Cherry Tomatoes', brand: 'Local Farms', packSize: '500 gm', category: 'Fresh', imageUrl: 'https://images.unsplash.com/photo-1546094096-0df4bcaaa337?w=300&q=80' },
    { name: 'English Cucumbers', brand: 'Garden Fresh', packSize: '3 pcs', category: 'Fresh', imageUrl: 'https://images.unsplash.com/photo-1449300079323-02e209d9d3a6?w=300&q=80' },
    { name: 'Chicken Breast', brand: 'Americana', packSize: '1 kg', category: 'Meat', imageUrl: 'https://images.unsplash.com/photo-1604503468506-a8da13d11bff?w=300&q=80' },
    { name: 'Pasta Penne', brand: 'Barilla', packSize: '500 gm', category: 'Pantry', imageUrl: 'https://images.unsplash.com/photo-1551462147-ff29053bfc14?w=300&q=80' },
    { name: 'Canned Chickpeas', brand: 'Al Alali', packSize: '400 gm', category: 'Pantry', imageUrl: 'https://images.unsplash.com/photo-1515543904379-3d757afe72e4?w=300&q=80' },
    { name: 'Medjool Dates', brand: 'Al Foah', packSize: '500 gm', category: 'Fruits', imageUrl: 'https://images.unsplash.com/photo-1611071536226-69b7a97c3a02?w=300&q=80' },
    { name: 'Halloumi Cheese', brand: 'Almarai', packSize: '250 gm', category: 'Dairy', imageUrl: 'https://images.unsplash.com/photo-1559561853-08451507cbe7?w=300&q=80' },
    { name: 'Sparkling Water', brand: 'Al Ain', packSize: '1.5 L', category: 'Beverages', imageUrl: 'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=300&q=80' },
    { name: 'Pita Bread', brand: 'Sunbulah', packSize: '6 pcs', category: 'Pantry', imageUrl: 'https://images.unsplash.com/photo-1534620808146-d33bb39128b2?w=300&q=80' },
    { name: 'Hummus', brand: 'Casablanca', packSize: '400 gm', category: 'Pantry', imageUrl: 'https://images.unsplash.com/photo-1577805947697-89e18249d767?w=300&q=80' },
  ];

  const createdProducts: Record<string, string> = {};
  for (const product of products) {
    const existing = await prisma.product.findFirst({ where: { name: product.name } });
    if (existing) {
      createdProducts[product.name] = existing.id;
    } else {
      const created = await prisma.product.create({ data: product });
      createdProducts[product.name] = created.id;
    }
  }

  console.log(`Seeded ${stores.length} stores, ${products.length} products, ${badges.length} badges.`);
  console.log('Done!');
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
