"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const prisma = new client_1.PrismaClient();
async function main() {
    console.log('Starting migration to create push_subscriptions table...');
    // Create table
    await prisma.$executeRawUnsafe(`
    CREATE TABLE IF NOT EXISTS public.push_subscriptions (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
      endpoint TEXT NOT NULL UNIQUE,
      p256dh TEXT NOT NULL,
      auth TEXT NOT NULL,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
    );
  `);
    console.log('Table created or already exists.');
    // Enable Row Level Security (RLS)
    await prisma.$executeRawUnsafe(`
    ALTER TABLE public.push_subscriptions ENABLE ROW LEVEL SECURITY;
  `);
    console.log('Row Level Security enabled.');
    // Create Policies separately
    await prisma.$executeRawUnsafe(`
    DROP POLICY IF EXISTS "Users can insert own push subscriptions" ON public.push_subscriptions;
  `);
    await prisma.$executeRawUnsafe(`
    CREATE POLICY "Users can insert own push subscriptions" ON public.push_subscriptions
      FOR INSERT WITH CHECK (auth.uid() = user_id);
  `);
    await prisma.$executeRawUnsafe(`
    DROP POLICY IF EXISTS "Users can view own push subscriptions" ON public.push_subscriptions;
  `);
    await prisma.$executeRawUnsafe(`
    CREATE POLICY "Users can view own push subscriptions" ON public.push_subscriptions
      FOR SELECT USING (auth.uid() = user_id);
  `);
    await prisma.$executeRawUnsafe(`
    DROP POLICY IF EXISTS "Users can delete own push subscriptions" ON public.push_subscriptions;
  `);
    await prisma.$executeRawUnsafe(`
    CREATE POLICY "Users can delete own push subscriptions" ON public.push_subscriptions
      FOR DELETE USING (auth.uid() = user_id);
  `);
    console.log('RLS Policies configured successfully.');
    console.log('Database migration completed successfully!');
}
main()
    .catch((e) => {
    console.error('Migration failed:', e);
    process.exit(1);
})
    .finally(async () => {
    await prisma.$disconnect();
});
