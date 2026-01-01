/**
 * Script to promote a user to admin role
 * Usage: npx tsx scripts/promote-admin.ts your@email.com
 */

import { createClient } from "@supabase/supabase-js";
import * as dotenv from "dotenv";
import { resolve } from "path";

// Load environment variables
dotenv.config({ path: resolve(__dirname, "../.env.local") });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error("❌ Missing environment variables:");
  console.error("   - NEXT_PUBLIC_SUPABASE_URL");
  console.error("   - SUPABASE_SERVICE_ROLE_KEY (add this to .env.local)");
  console.error("");
  console.error("💡 You can also promote admins directly in Supabase Dashboard:");
  console.error("   1. Go to Table Editor → profiles");
  console.error("   2. Find the user by email");
  console.error("   3. Set role = 'admin'");
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

async function promoteToAdmin(email: string) {
  console.log(`\n🔍 Looking for user: ${email}\n`);

  // Find user by email
  const { data: profile, error: findError } = await supabase
    .from("profiles")
    .select("id, email, display_name, role")
    .eq("email", email)
    .single();

  if (findError || !profile) {
    console.error(`❌ User not found: ${email}`);
    console.error("");
    console.error("💡 Make sure the user has signed up first.");
    console.error("   The profile is created automatically on first login.");
    process.exit(1);
  }

  console.log("📋 Current profile:");
  console.log(`   ID: ${profile.id}`);
  console.log(`   Email: ${profile.email}`);
  console.log(`   Name: ${profile.display_name || "(not set)"}`);
  console.log(`   Role: ${profile.role}`);
  console.log("");

  if (profile.role === "admin") {
    console.log("✅ User is already an admin!");
    process.exit(0);
  }

  // Promote to admin
  const { error: updateError } = await supabase
    .from("profiles")
    .update({ role: "admin" })
    .eq("id", profile.id);

  if (updateError) {
    console.error(`❌ Failed to promote user: ${updateError.message}`);
    process.exit(1);
  }

  console.log("✅ Successfully promoted to admin!");
  console.log("");
  console.log("🔐 The user can now login to the admin panel.");
}

// Get email from command line
const email = process.argv[2];

if (!email) {
  console.log("\n📖 Usage: npx tsx scripts/promote-admin.ts <email>");
  console.log("");
  console.log("Example:");
  console.log("  npx tsx scripts/promote-admin.ts admin@silni.app");
  console.log("");
  console.log("💡 Alternative: Promote directly in Supabase Dashboard:");
  console.log("   1. Go to Table Editor → profiles");
  console.log("   2. Find the user row");
  console.log("   3. Set role = 'admin'");
  process.exit(1);
}

promoteToAdmin(email);
