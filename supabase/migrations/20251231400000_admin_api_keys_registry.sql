-- Admin API Keys Registry
-- Stores metadata about API keys (NOT the actual secrets)
-- For documentation, rotation tracking, and key management guidance

-- Create enum for key categories
CREATE TYPE key_category AS ENUM (
  'backend',      -- Supabase, databases
  'auth',         -- OAuth, identity providers
  'payments',     -- RevenueCat, Stripe
  'messaging',    -- Firebase, push notifications
  'ai',           -- DeepSeek, OpenAI
  'monitoring',   -- Sentry, analytics
  'storage',      -- Cloudinary, S3
  'signing',      -- App Store, Play Store, code signing
  'other'
);

-- Create enum for key environments
CREATE TYPE key_environment AS ENUM (
  'all',
  'production',
  'staging',
  'development'
);

-- Create enum for key usage locations
CREATE TYPE key_usage_location AS ENUM (
  'flutter_app',
  'admin_panel',
  'edge_functions',
  'ci_cd',
  'multiple'
);

-- Main registry table
CREATE TABLE admin_api_keys_registry (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Key identification
  service_name TEXT NOT NULL,           -- e.g., "Supabase", "Firebase", "RevenueCat"
  key_name TEXT NOT NULL,               -- e.g., "Anon Key", "Service Role Key", "API Key"
  key_identifier TEXT,                  -- Variable name, e.g., "SUPABASE_ANON_KEY"

  -- Categorization
  category key_category NOT NULL DEFAULT 'other',
  environment key_environment NOT NULL DEFAULT 'all',
  usage_location key_usage_location NOT NULL DEFAULT 'flutter_app',

  -- Description
  description_ar TEXT,
  description_en TEXT,
  purpose TEXT,                         -- What this key is used for

  -- Configuration location
  config_file_path TEXT,                -- e.g., ".env", "google-services.json"
  config_variable_name TEXT,            -- e.g., "NEXT_PUBLIC_SUPABASE_URL"

  -- Security level
  is_secret BOOLEAN DEFAULT true,       -- Is this a secret key (vs public identifier)?
  is_obfuscated BOOLEAN DEFAULT false,  -- Is it obfuscated in binary?
  exposure_level TEXT DEFAULT 'server', -- 'client', 'server', 'binary'

  -- Source and rotation
  source_url TEXT,                      -- URL to get/rotate the key
  source_path TEXT,                     -- Navigation path in dashboard
  rotation_guide TEXT,                  -- Step-by-step rotation instructions
  rotation_frequency TEXT,              -- e.g., "90 days", "yearly", "never"
  last_rotated_at TIMESTAMPTZ,
  next_rotation_at TIMESTAMPTZ,

  -- Notes
  notes TEXT,                           -- Additional notes
  dependencies TEXT[],                  -- Other keys/services this depends on

  -- Status
  is_active BOOLEAN DEFAULT true,
  sort_order INT DEFAULT 0,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  -- Constraints
  UNIQUE(service_name, key_name, environment)
);

-- Enable RLS
ALTER TABLE admin_api_keys_registry ENABLE ROW LEVEL SECURITY;

-- Read policy - admins only (sensitive data)
CREATE POLICY "Only admins can view keys registry"
  ON admin_api_keys_registry FOR SELECT
  USING (is_admin());

-- Admin write policy
CREATE POLICY "Admins can manage keys registry"
  ON admin_api_keys_registry FOR ALL
  USING (is_admin());

-- Create updated_at trigger
CREATE TRIGGER update_admin_api_keys_registry_updated_at
  BEFORE UPDATE ON admin_api_keys_registry
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create index for common queries
CREATE INDEX idx_api_keys_category ON admin_api_keys_registry(category);
CREATE INDEX idx_api_keys_service ON admin_api_keys_registry(service_name);
CREATE INDEX idx_api_keys_environment ON admin_api_keys_registry(environment);

-- =====================
-- SEED DATA WITH ALL DISCOVERED KEYS
-- =====================

-- 1. SUPABASE KEYS
INSERT INTO admin_api_keys_registry (service_name, key_name, key_identifier, category, environment, usage_location, description_en, description_ar, purpose, config_file_path, config_variable_name, is_secret, exposure_level, source_url, source_path, rotation_guide, rotation_frequency, notes, sort_order) VALUES

-- Supabase Production
('Supabase', 'Production URL', 'SUPABASE_PRODUCTION_URL', 'backend', 'production', 'multiple',
 'Supabase project URL for production', 'رابط مشروع Supabase للإنتاج',
 'Main API endpoint for production database',
 '.env', 'SUPABASE_PRODUCTION_URL',
 false, 'client',
 'https://supabase.com/dashboard/project/_/settings/api', 'Project Settings → API → Project URL',
 '1. Go to Supabase Dashboard
2. Select production project (bapwklwxmwhpucutyras)
3. Go to Settings → API
4. Copy Project URL
5. Update .env file
6. Run: flutter pub run build_runner build',
 'never', 'URL never changes unless project is migrated', 1),

('Supabase', 'Production Anon Key', 'SUPABASE_PRODUCTION_ANON_KEY', 'backend', 'production', 'multiple',
 'Public anonymous key for production', 'مفتاح عام للإنتاج',
 'Client-side authentication and RLS-protected queries',
 '.env', 'SUPABASE_PRODUCTION_ANON_KEY',
 false, 'client',
 'https://supabase.com/dashboard/project/_/settings/api', 'Project Settings → API → anon public',
 '1. Go to Supabase Dashboard → production project
2. Settings → API → Project API keys
3. Copy "anon public" key
4. Update .env file
5. Rebuild Flutter app
Note: Anon key rotation requires updating all deployed apps',
 'yearly', 'Safe to expose - protected by RLS policies', 2),

('Supabase', 'Production Service Role Key', 'SUPABASE_SERVICE_ROLE_KEY', 'backend', 'production', 'edge_functions',
 'Server-side admin key - NEVER expose to client', 'مفتاح الخادم - لا تكشفه أبداً',
 'Full database access, bypasses RLS - only for edge functions',
 'Supabase Secrets', 'SUPABASE_SERVICE_ROLE_KEY',
 true, 'server',
 'https://supabase.com/dashboard/project/_/settings/api', 'Project Settings → API → service_role secret',
 '1. ⚠️ CRITICAL: Never expose this key
2. Go to Supabase Dashboard → production project
3. Settings → API → service_role (reveal)
4. Run: supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<new_key>
5. Redeploy all edge functions
6. Old key is immediately invalid',
 '90 days', 'DANGER: Full DB access. Rotation invalidates old key immediately.', 3),

('Supabase', 'Staging URL', 'SUPABASE_STAGING_URL', 'backend', 'staging', 'multiple',
 'Supabase project URL for staging', 'رابط مشروع Supabase للتجربة',
 'Staging/development database endpoint',
 '.env', 'SUPABASE_STAGING_URL',
 false, 'client',
 'https://supabase.com/dashboard/project/_/settings/api', 'Project Settings → API → Project URL',
 'Same as production URL rotation', 'never', 'Staging project: dqqyhmydodjpqboykzow', 4),

('Supabase', 'Staging Anon Key', 'SUPABASE_STAGING_ANON_KEY', 'backend', 'staging', 'multiple',
 'Public anonymous key for staging', 'مفتاح عام للتجربة',
 'Client-side key for staging environment',
 '.env', 'SUPABASE_STAGING_ANON_KEY',
 false, 'client',
 'https://supabase.com/dashboard/project/_/settings/api', 'Project Settings → API → anon public',
 'Same as production anon key rotation', 'yearly', NULL, 5),

-- 2. FIREBASE KEYS
('Firebase', 'iOS API Key', 'FIREBASE_IOS_API_KEY', 'messaging', 'all', 'flutter_app',
 'Firebase API key for iOS app', 'مفتاح Firebase لتطبيق iOS',
 'FCM push notifications, Analytics, Performance on iOS',
 'ios/Runner/GoogleService-Info.plist', 'API_KEY',
 false, 'binary',
 'https://console.firebase.google.com/project/_/settings/general', 'Project Settings → Your apps → iOS → GoogleService-Info.plist',
 '1. Go to Firebase Console → Project Settings
2. Select iOS app (com.silni.app)
3. Download new GoogleService-Info.plist
4. Replace ios/Runner/GoogleService-Info.plist
5. Clean and rebuild iOS app',
 'yearly', 'Bundled in iOS binary. Key rotation requires app update.', 10),

('Firebase', 'Android API Key', 'FIREBASE_ANDROID_API_KEY', 'messaging', 'all', 'flutter_app',
 'Firebase API key for Android app', 'مفتاح Firebase لتطبيق Android',
 'FCM push notifications, Analytics, Performance on Android',
 'android/app/google-services.json', 'current_key',
 false, 'binary',
 'https://console.firebase.google.com/project/_/settings/general', 'Project Settings → Your apps → Android → google-services.json',
 '1. Go to Firebase Console → Project Settings
2. Select Android app (com.silni.app)
3. Download new google-services.json
4. Replace android/app/google-services.json
5. Clean and rebuild Android app',
 'yearly', 'Bundled in Android binary. Key rotation requires app update.', 11),

('Firebase', 'Service Account JSON', 'FIREBASE_SERVICE_ACCOUNT', 'messaging', 'production', 'edge_functions',
 'Firebase Admin SDK credentials', 'بيانات اعتماد Firebase Admin',
 'Server-side FCM for sending push notifications from edge functions',
 'Supabase Secrets', 'FIREBASE_SERVICE_ACCOUNT',
 true, 'server',
 'https://console.firebase.google.com/project/_/settings/serviceaccounts/adminsdk', 'Project Settings → Service accounts → Generate new private key',
 '1. Go to Firebase Console → Project Settings
2. Service accounts tab
3. Click "Generate new private key"
4. Download JSON file
5. Minify JSON (remove whitespace)
6. Run: supabase secrets set FIREBASE_SERVICE_ACCOUNT=''<json>''
7. Redeploy push notification functions
8. Delete old service account in Firebase Console',
 '90 days', 'CRITICAL: Contains private key. Old key can be revoked in Firebase Console.', 12),

-- 3. REVENUECAT KEYS
('RevenueCat', 'Apple API Key', 'REVENUECAT_APPLE_API_KEY', 'payments', 'all', 'flutter_app',
 'RevenueCat public key for iOS', 'مفتاح RevenueCat العام لـ iOS',
 'In-app purchases and subscription management on iOS',
 '.env', 'REVENUECAT_APPLE_API_KEY',
 false, 'binary',
 'https://app.revenuecat.com/projects/_/api-keys', 'Project → API Keys → Public Apple API Key',
 '1. Go to RevenueCat Dashboard
2. Select project → API Keys
3. Find "Public Apple API Key" (starts with appl_)
4. Note: Public keys cannot be rotated, only revoked
5. To change: Create new key, update app, revoke old key',
 'never', 'Public key safe to expose. Revocation requires app update.', 20),

('RevenueCat', 'Google API Key', 'REVENUECAT_GOOGLE_API_KEY', 'payments', 'all', 'flutter_app',
 'RevenueCat public key for Android', 'مفتاح RevenueCat العام لـ Android',
 'In-app purchases and subscription management on Android',
 '.env', 'REVENUECAT_GOOGLE_API_KEY',
 false, 'binary',
 'https://app.revenuecat.com/projects/_/api-keys', 'Project → API Keys → Public Google API Key',
 'Same as Apple API Key rotation', 'never', 'Public key safe to expose.', 21),

('RevenueCat', 'Secret API Key V2', 'REVENUECAT_API_KEY_V2', 'payments', 'production', 'admin_panel',
 'RevenueCat server-side secret key', 'مفتاح RevenueCat السري للخادم',
 'Server-side API access for admin panel to fetch offerings',
 'silni-admin/.env.local', 'REVENUECAT_API_KEY_V2',
 true, 'server',
 'https://app.revenuecat.com/projects/_/api-keys', 'Project → API Keys → Secret API keys → V2',
 '1. Go to RevenueCat Dashboard → API Keys
2. Under "Secret API keys", click "Show key" for V2
3. Copy key (starts with sk_)
4. Update silni-admin/.env.local
5. Set in Vercel environment variables
6. To rotate: Generate new V2 key, update configs, delete old key',
 '90 days', 'Server-side only. Starts with sk_. Never expose to client.', 22),

('RevenueCat', 'Project ID', 'REVENUECAT_PROJECT_ID', 'payments', 'all', 'admin_panel',
 'RevenueCat project identifier', 'معرف مشروع RevenueCat',
 'Identifies the RevenueCat project for API calls',
 'silni-admin/.env.local', 'REVENUECAT_PROJECT_ID',
 false, 'server',
 'https://app.revenuecat.com/overview', 'Dashboard → Project name → URL contains project ID',
 'Project ID never changes', 'never', 'Format: projXXXXXXXX', 23),

-- 4. GOOGLE OAUTH
('Google', 'iOS Client ID', 'GOOGLE_IOS_CLIENT_ID', 'auth', 'all', 'flutter_app',
 'OAuth client ID for iOS Google Sign-In', 'معرف OAuth لتسجيل الدخول بـ Google على iOS',
 'Enables "Sign in with Google" button on iOS',
 '.env', 'GOOGLE_IOS_CLIENT_ID',
 false, 'binary',
 'https://console.cloud.google.com/apis/credentials', 'APIs & Services → Credentials → OAuth 2.0 Client IDs',
 '1. Go to Google Cloud Console
2. Select project (silni-31811)
3. APIs & Services → Credentials
4. Find iOS OAuth client
5. To rotate: Create new client, update app, delete old',
 'yearly', 'Bundled in iOS Info.plist. Rotation requires app update.', 30),

('Google', 'Web Client ID', 'GOOGLE_WEB_CLIENT_ID', 'auth', 'all', 'flutter_app',
 'OAuth client ID for Supabase OAuth integration', 'معرف OAuth لتكامل Supabase',
 'Used by Supabase Auth for Google OAuth flow',
 '.env', 'GOOGLE_WEB_CLIENT_ID',
 false, 'client',
 'https://console.cloud.google.com/apis/credentials', 'APIs & Services → Credentials → OAuth 2.0 Client IDs → Web client',
 '1. Go to Google Cloud Console → Credentials
2. Find Web client OAuth 2.0 Client ID
3. Copy Client ID
4. Also update in Supabase: Auth → Providers → Google',
 'yearly', 'Must match Supabase OAuth provider config', 31),

-- 5. DEEPSEEK AI
('DeepSeek', 'API Key', 'DEEPSEEK_API_KEY', 'ai', 'production', 'edge_functions',
 'DeepSeek AI API key for chat completions', 'مفتاح DeepSeek للذكاء الاصطناعي',
 'Powers AI chat assistant through deepseek-proxy edge function',
 'Supabase Secrets', 'DEEPSEEK_API_KEY',
 true, 'server',
 'https://platform.deepseek.com/api_keys', 'API Keys → Create new secret key',
 '1. Go to DeepSeek Platform → API Keys
2. Click "Create new secret key"
3. Copy key (starts with sk-)
4. Run: supabase secrets set DEEPSEEK_API_KEY=<new_key>
5. Redeploy deepseek-proxy function
6. Delete old key in DeepSeek dashboard',
 '90 days', 'Usage-based billing. Monitor usage in DeepSeek dashboard.', 40),

-- 6. SENTRY
('Sentry', 'DSN', 'SENTRY_DSN', 'monitoring', 'all', 'flutter_app',
 'Sentry Data Source Name for error tracking', 'رابط Sentry لتتبع الأخطاء',
 'Remote error logging and crash reporting',
 '.env', 'SENTRY_DSN',
 true, 'binary',
 'https://sentry.io/settings/_/projects/_/keys/', 'Settings → Projects → [project] → Client Keys (DSN)',
 '1. Go to Sentry → Settings → Projects → silni
2. Client Keys (DSN)
3. Copy DSN URL
4. Update .env file
5. Rebuild app
Note: Old DSN continues working, new errors go to new key',
 'yearly', 'Obfuscated in binary. DSN is project-specific.', 50),

-- 7. CLOUDINARY (Optional)
('Cloudinary', 'Cloud Name', 'CLOUDINARY_CLOUD_NAME', 'storage', 'all', 'flutter_app',
 'Cloudinary account identifier', 'معرف حساب Cloudinary',
 'Image processing and CDN (optional feature)',
 '.env', 'CLOUDINARY_CLOUD_NAME',
 false, 'client',
 'https://console.cloudinary.com/settings/account', 'Settings → Account → Cloud name',
 'Cloud name is permanent', 'never', 'Current: dli79vqgg', 60),

('Cloudinary', 'API Key', 'CLOUDINARY_API_KEY', 'storage', 'all', 'flutter_app',
 'Cloudinary API key', 'مفتاح Cloudinary',
 'Authentication for image uploads',
 '.env', 'CLOUDINARY_API_KEY',
 false, 'binary',
 'https://console.cloudinary.com/settings/api-keys', 'Settings → Security → API Keys',
 '1. Go to Cloudinary Console → Settings
2. Security → Access Keys
3. Generate new key pair
4. Update both API Key and API Secret
5. Rebuild app',
 'yearly', NULL, 61),

('Cloudinary', 'API Secret', 'CLOUDINARY_API_SECRET', 'storage', 'all', 'flutter_app',
 'Cloudinary API secret', 'سر Cloudinary',
 'Secret for signed uploads',
 '.env', 'CLOUDINARY_API_SECRET',
 true, 'binary',
 'https://console.cloudinary.com/settings/api-keys', 'Settings → Security → API Keys',
 'Rotated together with API Key', 'yearly', 'Obfuscated in binary', 62),

-- 8. ANDROID APP SIGNING
('Android', 'Release Keystore', 'ANDROID_KEYSTORE', 'signing', 'production', 'ci_cd',
 'Android app signing keystore file', 'ملف توقيع تطبيق Android',
 'Signs release APK/AAB for Google Play Store distribution',
 'android/silni-release-key.jks', 'storeFile',
 true, 'server',
 'https://developer.android.com/studio/publish/app-signing', 'Android Studio → Build → Generate Signed Bundle/APK',
 '1. ⚠️ CRITICAL: Backup current keystore securely
2. Generate new keystore (NOT recommended - same keystore forever)
3. If lost, must contact Google Play for key upgrade
4. Store password in secure password manager
5. Never commit to git
Note: Same keystore must be used for ALL future app updates',
 'never', 'CRITICAL: Loss = cannot update app. Google Play App Signing recommended.', 70),

('Android', 'Keystore Password', 'ANDROID_KEYSTORE_PASSWORD', 'signing', 'production', 'ci_cd',
 'Password for Android keystore', 'كلمة مرور مخزن مفاتيح Android',
 'Unlocks the .jks keystore file',
 'android/key.properties', 'storePassword',
 true, 'server',
 NULL, 'Stored in key.properties (gitignored)',
 '1. Update key.properties with new password
2. Update CI/CD secrets (GitHub Actions, etc.)
3. Test signing locally before deploying
Note: Change if keystore password was exposed',
 'on-exposure', 'NEVER commit. Use environment variables in CI/CD.', 71),

('Android', 'Key Alias', 'ANDROID_KEY_ALIAS', 'signing', 'production', 'ci_cd',
 'Alias name for signing key in keystore', 'اسم مستعار لمفتاح التوقيع',
 'Identifies which key to use from keystore',
 'android/key.properties', 'keyAlias',
 false, 'server',
 NULL, 'Stored in key.properties',
 'Key alias is set when keystore is created. Cannot be changed.', 'never', 'Current: silni-key-alias', 72),

('Android', 'Key Password', 'ANDROID_KEY_PASSWORD', 'signing', 'production', 'ci_cd',
 'Password for the specific key in keystore', 'كلمة مرور المفتاح',
 'Unlocks the signing key within keystore',
 'android/key.properties', 'keyPassword',
 true, 'server',
 NULL, 'Stored in key.properties (gitignored)',
 '1. Same rotation process as keystore password
2. Can be different from keystore password
3. Update in key.properties and CI/CD secrets',
 'on-exposure', 'Often same as storePassword but can be different.', 73),

-- 9. APPLE APP SIGNING
('Apple', 'Team ID', 'APPLE_TEAM_ID', 'signing', 'all', 'flutter_app',
 'Apple Developer Team identifier', 'معرف فريق Apple Developer',
 'Identifies your Apple Developer account/team',
 'ios/Runner.xcodeproj', 'DEVELOPMENT_TEAM',
 false, 'binary',
 'https://developer.apple.com/account', 'Account → Membership → Team ID',
 'Team ID is permanent for your developer account', 'never', 'Current: 3SPV37F368', 80),

('Apple', 'Bundle ID', 'APPLE_BUNDLE_ID', 'signing', 'all', 'flutter_app',
 'iOS app unique identifier', 'معرف التطبيق الفريد',
 'Unique identifier for app on App Store',
 'ios/Runner.xcodeproj', 'PRODUCT_BUNDLE_IDENTIFIER',
 false, 'binary',
 'https://developer.apple.com/account/resources/identifiers', 'Certificates, Identifiers & Profiles → Identifiers',
 'Bundle ID cannot be changed after app is published', 'never', 'Current: com.silni.app', 81),

('Apple', 'Sign in with Apple Key ID', 'APPLE_KEY_ID', 'auth', 'production', 'edge_functions',
 'Key ID for Sign in with Apple', 'معرف مفتاح تسجيل الدخول بـ Apple',
 'Used to generate client secret for Apple OAuth',
 'Supabase Auth Settings', 'Key ID',
 false, 'server',
 'https://developer.apple.com/account/resources/authkeys', 'Certificates, Identifiers & Profiles → Keys',
 '1. Go to Apple Developer → Keys
2. Find "Sign in with Apple" key
3. Key ID is shown in the list
4. To rotate: Create new key, update Supabase, delete old key
5. Also update scripts/generate_apple_secret.js',
 'yearly', 'Current: H49QU2J6LU. Linked to .p8 private key file.', 82),

('Apple', 'Sign in with Apple Private Key (.p8)', 'APPLE_AUTH_KEY_P8', 'auth', 'production', 'edge_functions',
 'Private key file for Sign in with Apple', 'ملف المفتاح الخاص لتسجيل الدخول بـ Apple',
 'Used with Key ID to generate JWT for Apple OAuth',
 'Secure storage (not in repo)', 'AuthKey_XXXXX.p8',
 true, 'server',
 'https://developer.apple.com/account/resources/authkeys', 'Keys → Download (only once!)',
 '1. ⚠️ CRITICAL: Key can only be downloaded ONCE
2. Go to Apple Developer → Keys
3. Create new key with "Sign in with Apple"
4. Download .p8 file immediately
5. Store securely (password manager, secure vault)
6. Update Supabase Auth provider settings
7. Update scripts/generate_apple_secret.js with new key content',
 'yearly', 'CRITICAL: Download only available ONCE. Store securely!', 83),

('Apple', 'APNs Auth Key (.p8)', 'APPLE_APNS_KEY_P8', 'messaging', 'production', 'edge_functions',
 'APNs authentication key for push notifications', 'مفتاح APNs للإشعارات',
 'Used by Firebase to send push notifications to iOS devices',
 'Firebase Console', 'APNs Authentication Key',
 true, 'server',
 'https://developer.apple.com/account/resources/authkeys', 'Keys → Create key with APNs',
 '1. Go to Apple Developer → Keys
2. Create new key with "Apple Push Notifications service (APNs)"
3. Download .p8 file (only once!)
4. Upload to Firebase Console → Project Settings → Cloud Messaging → APNs
5. Enter Key ID and Team ID',
 'yearly', 'Same .p8 file can be used for both APNs and Sign in with Apple.', 84),

-- 10. APP STORE CONNECT
('Apple', 'App Store Connect API Key', 'ASC_API_KEY', 'signing', 'production', 'ci_cd',
 'App Store Connect API key for automation', 'مفتاح API لـ App Store Connect',
 'Automates TestFlight uploads, app metadata, and releases',
 'CI/CD Secrets', 'ASC_KEY_ID, ASC_ISSUER_ID, ASC_PRIVATE_KEY',
 true, 'server',
 'https://appstoreconnect.apple.com/access/api', 'Users and Access → Keys → App Store Connect API',
 '1. Go to App Store Connect → Users and Access → Keys
2. Click "+" to generate new API key
3. Select "Admin" or "App Manager" role
4. Download .p8 file (only once!)
5. Note the Key ID and Issuer ID
6. Store in CI/CD secrets:
   - ASC_KEY_ID: Key identifier
   - ASC_ISSUER_ID: Your issuer ID (same for all keys)
   - ASC_PRIVATE_KEY: Contents of .p8 file',
 'yearly', 'Used by Fastlane, Xcode Cloud, or GitHub Actions for automated deployments.', 85),

-- 11. GOOGLE PLAY CONSOLE
('Google Play', 'Service Account JSON', 'GOOGLE_PLAY_SERVICE_ACCOUNT', 'signing', 'production', 'ci_cd',
 'Service account for Google Play API', 'حساب خدمة Google Play',
 'Automates Play Store uploads and releases',
 'CI/CD Secrets', 'GOOGLE_PLAY_JSON_KEY',
 true, 'server',
 'https://play.google.com/console/developers/_/api-access', 'Setup → API access → Service accounts',
 '1. Go to Google Play Console → Setup → API access
2. Create new service account or link existing
3. Go to Google Cloud Console for the service account
4. Create new JSON key
5. Download JSON file
6. Grant "Release manager" permission in Play Console
7. Store JSON in CI/CD secrets',
 'yearly', 'Used by Fastlane or GitHub Actions for automated Play Store deployments.', 90);

-- Add comment
COMMENT ON TABLE admin_api_keys_registry IS 'Centralized registry for tracking API keys, credentials, and their rotation schedules. Stores metadata only - NOT actual secret values.';
