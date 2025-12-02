# Security Policy

## Overview

This document outlines the security measures and best practices for the Silni app. We take security seriously and have implemented multiple layers of protection to safeguard user data.

## Recent Security Fixes (2025-01-30)

### Critical Vulnerabilities Resolved

1. **Removed Service Role Keys from Client Code** =4 CRITICAL
   - Service role keys were previously stored in `.env` and bundled with the app
   - These keys bypass Row Level Security and grant full database access
   - **Fix:** Removed all service_role keys from client-side code
   - **Impact:** Prevents unauthorized database access through app decompilation

2. **Removed .env from App Assets**
   - `.env` file was previously included in `pubspec.yaml` assets
   - This bundled all secrets into the APK/IPA files
   - **Fix:** Removed `.env` from assets, kept only in local development
   - **Impact:** Secrets are no longer extractable from compiled apps

3. **Created .env.example Template**
   - Added template file with placeholder values
   - Includes security documentation and usage instructions
   - Helps developers set up environment correctly

## Current Security Measures

### 1. Authentication & Authorization

- **PKCE Auth Flow:** Secure authentication using Proof Key for Code Exchange
- **Auto Token Refresh:** Prevents session expiry without compromising security
- **Row Level Security (RLS):** All database tables protected by RLS policies
- **User Data Isolation:** Users can only access their own data via RLS

### 2. API Key Management

**Supabase Keys:**
-  **Anon Keys:** Public keys protected by RLS (safe for client-side)
- L **Service Role Keys:** REMOVED from client code (server-only)

**Firebase Keys:**
- Used only for Firebase Cloud Messaging (push notifications)
- Web API keys are public by design, protected by Firebase security rules

**Cloudinary Keys:**
- API keys for image upload functionality
- Protected by upload presets and signed requests

### 3. Data Protection

**Database Security:**
```sql
-- All tables have RLS enabled
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE relatives ENABLE ROW LEVEL SECURITY;
ALTER TABLE interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminder_schedules ENABLE ROW LEVEL SECURITY;

-- Users can only access their own data
CREATE POLICY "Users can only view their own data"
ON users FOR SELECT
USING (auth.uid() = id);
```

**Network Security:**
- All API calls use HTTPS
- Supabase: `https://*.supabase.co`
- Cloudinary: `https://api.cloudinary.com`

**Local Storage:**
- Session tokens managed by Supabase SDK
- Hadith rotation index stored in SharedPreferences
- No sensitive data stored in plain text

### 4. Code Security

**Debug Logging:**
```dart
if (kDebugMode) {
  print('Debug info here');
}
```
- All debug logs guarded by `kDebugMode`
- Production builds automatically strip debug code

**Error Handling:**
- Graceful error messages that don't expose system internals
- Try-catch blocks throughout services
- Timeout handling for network requests

## Environment Variables

### Development Setup

1. Copy the template:
   ```bash
   cp .env.example .env
   ```

2. Fill in your actual API keys in `.env`:
   ```env
   SUPABASE_STAGING_ANON_KEY=your_actual_key_here
   ```

3. **IMPORTANT:** Never commit `.env` to version control
   - `.env` is in `.gitignore`
   - Only commit `.env.example` with placeholder values

### What Keys to Use

**In Client Code (Mobile/Web):**
-  Supabase **anon** keys only
-  Firebase web API keys
-  Cloudinary API keys (with upload presets)

**NEVER in Client Code:**
- L Supabase **service_role** keys
- L Cloudinary API secrets (use in backend only)
- L Admin credentials
- L Private signing keys

### Build-time Variables (Recommended for Production)

For even better security, use `--dart-define`:

```bash
flutter build apk \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key_here
```

This prevents secrets from being in any file and injects them at build time.

## Security Checklist for Production

### Before Release

- [x] Remove service role keys from all files
- [x] Remove .env from assets
- [ ] Rotate all exposed API keys (see below)
- [ ] Enable ProGuard/R8 obfuscation (Android)
- [ ] Configure certificate pinning
- [ ] Add network security config (Android)
- [ ] Implement App Transport Security (iOS)
- [ ] Add crash reporting (Sentry)
- [ ] Test on physical devices
- [ ] Security audit/penetration testing

### API Key Rotation

**If your keys were exposed (in git history or published apps):**

1. **Supabase Keys:**
   - Go to Dashboard ’ Settings ’ API
   - Rotate anon keys (requires Supabase support)
   - Update all apps with new keys

2. **Firebase Keys:**
   - Firebase Console ’ Project Settings ’ General
   - Regenerate web API key
   - Add restrictions (HTTP referrers, app bundles)

3. **Cloudinary Keys:**
   - Dashboard ’ Settings ’ Access Keys
   - Regenerate API key and secret
   - Update upload presets

## Reporting Security Issues

If you discover a security vulnerability:

1. **DO NOT** open a public GitHub issue
2. Email security concerns to: [your-email@example.com]
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We will respond within 48 hours and work on a fix immediately.

## Security Best Practices for Developers

### When Adding New Features

1. **Always use RLS for new tables:**
   ```sql
   ALTER TABLE new_table ENABLE ROW LEVEL SECURITY;
   CREATE POLICY "Users can only view own data"
   ON new_table FOR SELECT
   USING (auth.uid() = user_id);
   ```

2. **Never bypass RLS in client code:**
   ```dart
   // L BAD: Using service role key
   final supabase = SupabaseClient(url, serviceRoleKey);

   //  GOOD: Using anon key (protected by RLS)
   final supabase = SupabaseConfig.client;
   ```

3. **Validate all user input:**
   ```dart
   if (email.isEmpty || !isValidEmail(email)) {
     throw ValidationException('Invalid email');
   }
   ```

4. **Sanitize outputs:**
   ```dart
   // Prevent XSS in web builds
   final safeText = HtmlEscape().convert(userInput);
   ```

5. **Use prepared statements (automatic with Supabase SDK)**

### Code Review Checklist

Before merging code, verify:
- [ ] No hardcoded secrets or keys
- [ ] No service role keys in client code
- [ ] All database queries use RLS
- [ ] User input is validated
- [ ] Errors don't expose sensitive info
- [ ] Debug logs are guarded by `kDebugMode`

## Security Tools & Monitoring

### Recommended Tools

1. **Static Analysis:**
   - `flutter analyze` (built-in)
   - `riverpod_lint` (already integrated)
   - `flutter_lints` (already integrated)

2. **Dependency Scanning:**
   ```bash
   flutter pub outdated
   flutter pub upgrade --major-versions
   ```

3. **Crash Reporting:**
   - Sentry (to be integrated)
   - Firebase Crashlytics (alternative)

4. **Penetration Testing:**
   - OWASP Mobile Security Testing Guide
   - Regular security audits before major releases

## Compliance

### Data Protection

- **GDPR Compliance (EU):** User data deletion via account deletion flow
- **Data Retention:** User data deleted within 30 days of account deletion
- **Data Export:** To be implemented (data_export_requested field exists)

### Privacy Policy

- Privacy policy required before production launch
- Must disclose:
  - What data is collected
  - How it's used
  - Third-party services (Supabase, Firebase, Cloudinary)
  - User rights (access, deletion, export)

## Security Contacts

- **Security Lead:** [Your Name]
- **Emergency Contact:** [Your Email]
- **Supabase Support:** https://supabase.com/support

---

**Last Updated:** 2025-01-30
**Security Version:** 1.1
**Next Audit:** Before production launch (estimated 2025-04-01)
