/**
 * Route Sync Script
 * Parses Flutter app_routes.dart and syncs to Supabase admin_app_routes table
 * Run: npm run sync-routes (or automatically on npm run dev)
 */

import { createClient } from "@supabase/supabase-js";
import * as fs from "fs";
import * as path from "path";

// Load .env.local manually (tsx doesn't auto-load it)
const envPath = path.resolve(__dirname, "../.env.local");
if (fs.existsSync(envPath)) {
  const envContent = fs.readFileSync(envPath, "utf-8");
  envContent.split("\n").forEach((line) => {
    const trimmed = line.trim();
    if (trimmed && !trimmed.startsWith("#")) {
      const eqIndex = trimmed.indexOf("=");
      if (eqIndex > 0) {
        const key = trimmed.substring(0, eqIndex);
        const value = trimmed.substring(eqIndex + 1);
        process.env[key] = value;
      }
    }
  });
}

// Route category mappings based on route patterns
const CATEGORY_MAPPINGS: Record<string, { category: string; icon: string; requiresPremium?: boolean; featureId?: string }> = {
  // Main routes
  home: { category: "main", icon: "🏠" },
  relatives: { category: "main", icon: "👥" },
  achievements: { category: "main", icon: "🏆" },
  statistics: { category: "main", icon: "📊" },
  settings: { category: "main", icon: "⚙️" },
  profile: { category: "main", icon: "👤" },

  // Relatives
  relativeDetail: { category: "relatives", icon: "👤" },
  addRelative: { category: "relatives", icon: "➕" },
  editRelative: { category: "relatives", icon: "✏️" },
  importContacts: { category: "relatives", icon: "📱" },

  // Reminders
  reminders: { category: "reminders", icon: "📅" },
  remindersDue: { category: "reminders", icon: "⏰" },

  // AI routes (premium)
  aiHub: { category: "ai", icon: "🧠" },
  aiChat: { category: "ai", icon: "💬", requiresPremium: true, featureId: "ai_chat" },
  aiMemories: { category: "ai", icon: "🧠", requiresPremium: true, featureId: "ai_chat" },
  aiMessages: { category: "ai", icon: "✍️", requiresPremium: true, featureId: "message_composer" },
  aiAnalysis: { category: "ai", icon: "📈", requiresPremium: true, featureId: "relationship_analysis" },
  aiScripts: { category: "ai", icon: "📝", requiresPremium: true, featureId: "communication_scripts" },
  aiReport: { category: "ai", icon: "📋", requiresPremium: true, featureId: "weekly_reports" },

  // Gamification
  badges: { category: "gamification", icon: "🎖️" },
  detailedStats: { category: "gamification", icon: "📉" },
  leaderboard: { category: "gamification", icon: "🏅" },
  challenges: { category: "gamification", icon: "🎯" },

  // Family
  familyTree: { category: "family", icon: "🌳" },

  // Notifications
  notifications: { category: "notifications", icon: "🔔" },
  notificationHistory: { category: "notifications", icon: "📜" },

  // Auth (public)
  splash: { category: "auth", icon: "✨" },
  onboarding: { category: "auth", icon: "👋" },
  login: { category: "auth", icon: "🔑" },
  signup: { category: "auth", icon: "📝" },
  emailVerification: { category: "auth", icon: "📧" },
};

// Arabic labels for routes
const ARABIC_LABELS: Record<string, string> = {
  home: "الرئيسية",
  relatives: "الأقارب",
  relativeDetail: "تفاصيل القريب",
  achievements: "الإنجازات",
  statistics: "الإحصائيات",
  settings: "الإعدادات",
  addRelative: "إضافة قريب",
  editRelative: "تعديل قريب",
  reminders: "التذكيرات",
  remindersDue: "التذكيرات المستحقة",
  familyTree: "شجرة العائلة",
  profile: "الملف الشخصي",
  importContacts: "استيراد جهات الاتصال",
  notifications: "الإشعارات",
  notificationHistory: "سجل الإشعارات",
  badges: "الأوسمة",
  detailedStats: "إحصائيات تفصيلية",
  leaderboard: "لوحة المتصدرين",
  challenges: "التحديات",
  aiHub: "مركز الذكاء",
  aiChat: "المستشار الذكي",
  aiMemories: "الذكريات",
  aiMessages: "منشئ الرسائل",
  aiAnalysis: "تحليل العلاقات",
  aiScripts: "سيناريوهات التواصل",
  aiReport: "التقرير الأسبوعي",
  splash: "شاشة البداية",
  onboarding: "التعريف",
  login: "تسجيل الدخول",
  signup: "إنشاء حساب",
  emailVerification: "تأكيد البريد",
};

// Public routes that don't require auth
const PUBLIC_ROUTES = ["splash", "onboarding", "login", "signup", "emailVerification"];

// Routes that require parameters (e.g., :id) - these should not be selectable
const PARAMETERIZED_ROUTES = ["relativeDetail", "editRelative"];

interface ParsedRoute {
  name: string;
  path: string;
}

async function main() {
  console.log("🔄 Syncing Flutter routes to database...\n");

  // Load environment variables
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

  if (!supabaseUrl || !supabaseKey) {
    console.log("⚠️  Missing Supabase credentials - skipping route sync (OK for CI/build)");
    process.exit(0);  // Exit successfully to allow build to continue
  }

  // Read Flutter routes file
  const flutterRoutesPath = path.resolve(__dirname, "../../lib/core/router/app_routes.dart");

  if (!fs.existsSync(flutterRoutesPath)) {
    console.log("⚠️  Flutter routes file not found - skipping (OK for CI/build)");
    process.exit(0);  // Exit successfully to allow build to continue
  }

  const content = fs.readFileSync(flutterRoutesPath, "utf-8");

  // Parse routes using regex
  // Matches: static const String routeName = '/path';
  const routeRegex = /static\s+const\s+String\s+(\w+)\s*=\s*['"]([^'"]+)['"]/g;
  const routes: ParsedRoute[] = [];
  let match;

  while ((match = routeRegex.exec(content)) !== null) {
    const [, name, routePath] = match;
    // Skip non-route constants (like publicRoutes set)
    if (routePath.startsWith("/")) {
      routes.push({ name, path: routePath });
    }
  }

  console.log(`📍 Found ${routes.length} routes in app_routes.dart\n`);

  // Connect to Supabase
  const supabase = createClient(supabaseUrl, supabaseKey);

  // Get existing routes
  const { data: existingRoutes, error: fetchError } = await supabase
    .from("admin_app_routes")
    .select("route_key, path");

  if (fetchError) {
    console.error("❌ Failed to fetch existing routes:", fetchError.message);
    process.exit(1);
  }

  const existingKeys = new Set(existingRoutes?.map((r) => r.route_key) || []);
  const existingPaths = new Set(existingRoutes?.map((r) => r.path) || []);

  // Find new routes (check both original and parameterized paths)
  const newRoutes = routes.filter((r) => {
    if (existingKeys.has(r.name)) return false;

    // For parameterized routes, check if the transformed path exists
    const isParameterized = PARAMETERIZED_ROUTES.includes(r.name);
    const checkPath = isParameterized ? `${r.path}/:id` : r.path;

    return !existingPaths.has(checkPath) && !existingPaths.has(r.path);
  });

  if (newRoutes.length === 0) {
    console.log("✅ All routes are already synced!\n");
    return;
  }

  console.log(`🆕 Found ${newRoutes.length} new routes to add:\n`);

  // Prepare routes for insertion
  const routesToInsert = newRoutes.map((route, index) => {
    const mapping = CATEGORY_MAPPINGS[route.name] || { category: "main", icon: "📍" };
    const isPublic = PUBLIC_ROUTES.includes(route.name);
    const isAuth = mapping.category === "auth";
    const requiresParam = PARAMETERIZED_ROUTES.includes(route.name);

    // Mark parameterized routes with :id suffix
    const displayPath = requiresParam ? `${route.path}/:id` : route.path;

    console.log(`   ${mapping.icon} ${route.name} → ${displayPath}${requiresParam ? " (requires ID)" : ""}`);

    return {
      path: displayPath,
      route_key: route.name,
      label_ar: ARABIC_LABELS[route.name] || route.name,
      label_en: route.name.replace(/([A-Z])/g, " $1").trim(),
      icon: mapping.icon,
      category_key: mapping.category,
      sort_order: index + 100, // High sort order for new routes
      is_active: !isAuth && !requiresParam, // Auth and parameterized routes are inactive
      is_public: isPublic,
      requires_auth: !isPublic,
      requires_premium: mapping.requiresPremium || false,
      feature_id: mapping.featureId || null,
      description_ar: requiresParam ? "يتطلب معرف (ID) - غير متاح للاختيار المباشر" : null,
    };
  });

  // Insert new routes
  const { error: insertError } = await supabase
    .from("admin_app_routes")
    .upsert(routesToInsert, { onConflict: "route_key" });

  if (insertError) {
    console.error("\n❌ Failed to insert routes:", insertError.message);
    process.exit(1);
  }

  console.log(`\n✅ Successfully synced ${newRoutes.length} new routes!\n`);
}

main().catch((error) => {
  console.error("❌ Sync failed:", error);
  process.exit(1);
});
