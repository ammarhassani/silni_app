/**
 * Create Admin User Script
 *
 * Run with: npx ts-node scripts/create-admin.ts
 *
 * Or set environment variables:
 *   ADMIN_EMAIL=your@email.com ADMIN_PASSWORD=yourpassword npx ts-node scripts/create-admin.ts
 */

import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

const ADMIN_EMAIL = process.env.ADMIN_EMAIL;
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD;

async function createAdminUser() {
  if (!SUPABASE_URL) {
    console.error('❌ Error: NEXT_PUBLIC_SUPABASE_URL is required');
    console.log('\nSet it in your .env.local file or as an environment variable');
    process.exit(1);
  }

  if (!SUPABASE_SERVICE_KEY) {
    console.error('❌ Error: SUPABASE_SERVICE_ROLE_KEY is required');
    console.log('\nTo get it:');
    console.log('1. Go to your Supabase project dashboard > Settings > API');
    console.log('2. Copy the "service_role" key (NOT the anon key)');
    console.log('3. Run: SUPABASE_SERVICE_ROLE_KEY=your_key npx ts-node scripts/create-admin.ts');
    process.exit(1);
  }

  if (!ADMIN_EMAIL || !ADMIN_PASSWORD) {
    console.error('❌ Error: ADMIN_EMAIL and ADMIN_PASSWORD are required');
    console.log('\nRun with:');
    console.log('  ADMIN_EMAIL=your@email.com ADMIN_PASSWORD=YourSecurePassword npx ts-node scripts/create-admin.ts');
    process.exit(1);
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  console.log(`\n🔐 Creating admin user: ${ADMIN_EMAIL}\n`);

  // Create user with admin API
  const { data: user, error: createError } = await supabase.auth.admin.createUser({
    email: ADMIN_EMAIL,
    password: ADMIN_PASSWORD,
    email_confirm: true,
  });

  if (createError) {
    if (createError.message.includes('already been registered')) {
      console.log('ℹ️  User already exists, updating to admin...');
    } else {
      console.error('❌ Error creating user:', createError.message);
      process.exit(1);
    }
  } else {
    console.log('✅ User created:', user.user?.email);
  }

  // Update profile to admin role
  const { error: updateError } = await supabase
    .from('profiles')
    .upsert({
      id: user?.user?.id,
      email: ADMIN_EMAIL,
      display_name: 'مدير النظام',
      role: 'admin',
    }, { onConflict: 'id' });

  if (updateError) {
    // Try update by email if upsert fails
    const { error: updateByEmailError } = await supabase
      .from('profiles')
      .update({ role: 'admin' })
      .eq('email', ADMIN_EMAIL);

    if (updateByEmailError) {
      console.error('❌ Error setting admin role:', updateByEmailError.message);
    } else {
      console.log('✅ Admin role set successfully');
    }
  } else {
    console.log('✅ Admin role set successfully');
  }

  console.log('\n========================================');
  console.log('🎉 Admin user ready!');
  console.log('========================================');
  console.log(`Email:    ${ADMIN_EMAIL}`);
  console.log(`Password: ${ADMIN_PASSWORD}`);
  console.log('========================================');
  console.log('\nStart the admin panel:');
  console.log('  cd silni-admin && npm run dev');
  console.log('\nThen login at: http://localhost:3001');
}

createAdminUser();
