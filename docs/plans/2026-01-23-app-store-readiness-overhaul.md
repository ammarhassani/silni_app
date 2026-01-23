# Silni App - App Store Readiness Overhaul

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Prepare Silni app for App Store submission by fixing all critical bugs, security vulnerabilities, and production readiness issues identified in comprehensive system audit.

**Architecture:** Fix-first approach prioritizing security vulnerabilities, then production blockers, then App Store compliance, then polish items. All fixes maintain existing architecture patterns.

**Tech Stack:** Flutter/Dart, Supabase Edge Functions (Deno/TypeScript), iOS native configuration

---

# COMPREHENSIVE AUDIT REPORT

## Executive Summary

| Category | Score | Status |
|----------|-------|--------|
| Feature Completeness | 99.5% | ✅ EXCELLENT |
| Production Readiness | 75% | ❌ CRITICAL ISSUES |
| iOS/App Store Compliance | 70% | ❌ CRITICAL ISSUES |
| Security | 70% | ❌ CRITICAL ISSUES |
| UI/UX | 92% | ✅ GOOD |
| Backend Integration | 75% | ⚠️ NEEDS WORK |
| Testing | 60% | ❌ CRITICAL ISSUES |
| Subscriptions | 65% | ❌ CRITICAL ISSUES |

**Overall Readiness: 75% - Multiple critical fixes required**

---

# SECTION 1: CRITICAL ISSUES (P0 - Must Fix Before Submission)

## 1.1 SECURITY VULNERABILITIES

### Issue #1: Firebase API Keys Hardcoded
- **File:** `lib/firebase_options.dart:43-66`
- **Risk:** HIGH - Keys exposed in compiled binary
- **Impact:** Firebase project can be accessed/abused by attackers

### Issue #2: CORS Wildcard in Edge Functions
- **Files:** All Supabase edge functions
- **Risk:** HIGH - Any website can call your APIs
- **Impact:** Unauthorized access to all edge function endpoints

### Issue #3: Storage RLS Overpermissive
- **File:** Migration `20260101000000_security_fixes.sql:29`
- **Risk:** HIGH - `OR true` clause allows all users to see all photos
- **Impact:** Privacy violation - any user can enumerate all profile pictures

### Issue #4: Environment Credentials in Git History
- **Risk:** HIGH - `.env` may have been committed previously
- **Impact:** Credentials exposed in repository history
- **Action:** Rotate all keys after launch, consider git history cleanup

---

## 1.2 iOS/APP STORE BLOCKERS

### Issue #5: Universal Links NOT Configured (CRITICAL)
- **Files:** `ios/Runner/Runner.entitlements`, `ios/Runner/RunnerRelease.entitlements`
- **Missing:** `com.apple.developer.associated-domains` entitlement
- **Missing:** `apple-app-site-association` file on domain
- **Impact:** Password reset, email verification, sharing links will NOT work on iOS

### Issue #6: Missing NSPhotoLibraryAddUsageDescription
- **File:** `ios/Runner/Info.plist`
- **Risk:** App Store rejection if image_picker saves photos

### Issue #7: English Permission Descriptions Missing
- **File:** `ios/Runner/Info.plist`
- **Current:** Arabic only - Apple recommends English + localized

---

## 1.3 PRODUCTION READINESS

### Issue #8: 100+ debugPrint Statements
- **Files:** 15+ files across codebase
- **Key Files:**
  - `lib/shared/widgets/message_widget.dart` (30+ calls)
  - `lib/core/services/subscription_service.dart` (16 calls)
  - `lib/features/subscription/screens/paywall_screen.dart` (8 calls)
  - Multiple config services (~70 calls total)

### Issue #9: 82 Failing Widget Tests
- **Location:** `test/widget/` directory
- **Root Cause:** Riverpod provider mocking not properly configured
- **Failing:** settings_screen, relatives_screen, signup_screen, login_screen, reminders_screen
- **Impact:** Cannot verify UI correctness before release

### Issue #10: No CI/CD Pipeline
- **Status:** No `.github/workflows/` directory
- **Impact:** Tests not run automatically, no enforced production mode

---

## 1.4 SUBSCRIPTION CRITICAL ISSUES

### Issue #11: PRO Tier Products Orphaned
- **File:** `Products.storekit` has 4 products, code only recognizes 2
- **Products Defined:** silni_max_annual, silni_max_monthly, silni_pro_annual, silni_pro_monthly
- **Code Recognizes:** Only MAX products
- **Impact:** Users with PRO subscriptions will see FREE tier!

### Issue #12: No Offline Subscription Handling
- **Risk:** If RevenueCat is unreachable, ALL users see FREE tier
- **Impact:** Paying users lose access during outages
- **Missing:** Local cache of last-known subscription state

### Issue #13: Expired Subscriptions Not Validated
- **Current Logic:** `isActive = tier != SubscriptionTier.free`
- **Problem:** Doesn't check if `expirationDate > DateTime.now()`
- **Impact:** Expired users may retain access

### Issue #14: Billing Grace Period Disabled with No Code Handling
- **File:** `Products.storekit` shows `_billingGracePeriodEnabled: false`
- **Impact:** Users immediately lose access on payment failure

---

## 1.5 BACKEND CRITICAL ISSUES

### Issue #15: Missing Database Indexes
- **Tables:** relatives, interactions, reminder_schedules, notification_tokens
- **Impact:** Cron jobs slow at scale, potential timeout errors

### Issue #16: Weak Device ID Generation
- **File:** `lib/shared/services/supabase_notification_service.dart:111`
- **Current:** `'device_${DateTime.now().millisecondsSinceEpoch}'`
- **Impact:** Multiple installs could share device ID, miss notifications

---

## 1.6 BUNDLE SIZE ISSUES

### Issue #17: Bloated Animation File
- **File:** `assets/animations/level_up_burst.json` - **3.27 MB**
- **Cause:** Embedded base64-encoded WebP images in JSON
- **Impact:** Unnecessarily large app bundle

### Issue #18: Unminified SVG
- **File:** `assets/images/silni_logo.svg` - **909 KB**
- **Should Be:** ~50-100 KB after minification

### Issue #19: Dual Monitoring Systems
- **Both:** Firebase Analytics (2.7 MB) AND Sentry (4.5 MB) included
- **Impact:** 7+ MB of redundant telemetry code

---

# SECTION 2: HIGH PRIORITY ISSUES (P1 - Should Fix)

### Issue #20: Biometric Credentials Not Cleared on Logout
- **File:** `lib/shared/services/auth_service.dart:442-448`
- **Impact:** If phone stolen after logout, attacker can use Face ID

### Issue #21: No Proper i18n System
- **Current:** Hardcoded Arabic strings, custom UIStringsService
- **Missing:** l10n.yaml, .arb files, standard Flutter localization
- **Impact:** No scalable translation management

### Issue #22: Custom Date Formatting (Not Using intl)
- **Files:** Multiple screens with hardcoded Arabic month arrays
- **Impact:** Not locale-aware, duplicated code

### Issue #23: Race Condition in Rate Limiting
- **File:** `supabase/functions/deepseek-proxy/index.ts:149-154`
- **Impact:** Users could exceed rate limit under concurrent requests

### Issue #24: No Conflict Resolution in Sync Service
- **File:** `lib/core/services/sync_service.dart`
- **Impact:** Offline operations could create duplicates

### Issue #25: Subscription Status Never Used from Supabase
- **Written To:** `users.subscription_status` in database
- **Never Read:** Could be fallback when RevenueCat is down

---

# SECTION 3: MEDIUM PRIORITY ISSUES (P2)

### Issue #26: Long Relative Names May Overflow
### Issue #27: Missing Loading States in Some Screens
### Issue #28: Form Keyboard Handling Incomplete
### Issue #29: Inconsistent Edge Function Response Formats
### Issue #30: No Introductory Trial Offers Configured
### Issue #31: Family Sharing Disabled
### Issue #32: Unused `purchases_ui_flutter` Dependency
### Issue #33: Deprecated `FeatureIds.requiredTier()` Method Still Present

---

# SECTION 4: LOW PRIORITY ISSUES (P3 - Polish)

### Issue #34: Certificate Pinning Not Implemented
### Issue #35: Email Exposure in Sentry Logs
### Issue #36: Search State Resets on Navigation
### Issue #37: SSE Streaming Not Implemented for AI (uses simulation)
### Issue #38: Failed Sync User Notifications Not Shown
### Issue #39: Font Awesome Package Imported But Unused

---

# SECTION 5: POSITIVE FINDINGS (No Action Needed)

✅ **Feature Completeness:** 14 feature modules, 112 Dart files, all fully implemented
✅ **Sign in with Apple:** Properly implemented for iOS alongside Google
✅ **Account Deletion:** FULLY IMPLEMENTED with cascade deletion
✅ **Authentication:** OAuth 2.0 with proper PKCE, Apple/Google Sign-In working
✅ **Error Handling:** Comprehensive with Sentry integration
✅ **RTL Support:** 26 instances of proper RTL handling for Arabic
✅ **Accessibility:** 48 files with Semantics, WCAG contrast checking
✅ **Theme System:** Consistent design system across all screens
✅ **Offline Support:** Queue-based sync with dead-letter pattern
✅ **RLS Policies:** 101 policies across migrations (except storage issue)
✅ **Dependencies:** All up-to-date, no deprecated packages
✅ **Privacy Manifest:** Comprehensive PrivacyInfo.xcprivacy
✅ **App Icons:** All 15 required sizes present
✅ **Legal Docs:** Privacy policy and terms linked and accessible
✅ **Restore Purchases:** Fully implemented
✅ **Unused Code:** Minimal - codebase is clean

---

# IMPLEMENTATION PLAN

## Phase 1: Security Fixes (P0) - ~4 hours

### Task 1: Remove debugPrint Statements

**Files:** Multiple (15+ files)

**Step 1:** Find all occurrences
```bash
grep -rn "debugPrint" lib/ --include="*.dart" | wc -l
```

**Step 2:** Replace with kDebugMode check or remove entirely
```dart
// Remove or replace with:
if (kDebugMode) debugPrint('[Tag] message');
```

**Step 3:** Verify
```bash
grep -rn "debugPrint" lib/ --include="*.dart"
```

**Step 4:** Commit
```bash
git add lib/ && git commit -m "fix: remove debugPrint statements for production

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

### Task 2: Fix Firebase API Keys Exposure

**Files:**
- Create: `lib/core/config/env/env_firebase.dart`
- Modify: `lib/firebase_options.dart`
- Modify: `.env`

**Step 1:** Add Firebase keys to `.env`

**Step 2:** Create envied class for Firebase config

**Step 3:** Run build_runner
```bash
dart run build_runner build --delete-conflicting-outputs
```

**Step 4:** Update firebase_options.dart to use EnvFirebase

**Step 5:** Commit

---

### Task 3: Fix CORS in Edge Functions

**Files:**
- Create: `supabase/functions/_shared/cors.ts`
- Modify: All 6 edge functions

**Step 1:** Create shared CORS config
```typescript
export const corsHeaders = {
  "Access-Control-Allow-Origin": "https://silni-app.com",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};
```

**Step 2:** Update each function to import shared CORS

**Step 3:** Deploy
```bash
supabase functions deploy --project-ref bapwklwxmwhpucutyras
```

---

### Task 4: Fix Storage RLS Policy

**Files:**
- Create: `supabase/migrations/20260123000001_fix_storage_rls.sql`

**Step 1:** Create migration removing `OR true`

**Step 2:** Push migration
```bash
supabase db push --project-ref bapwklwxmwhpucutyras
```

---

## Phase 2: iOS/App Store Fixes (P0) - ~3 hours

### Task 5: Configure Universal Links

**Files:**
- Modify: `ios/Runner/Runner.entitlements`
- Modify: `ios/Runner/RunnerRelease.entitlements`
- Create: `.well-known/apple-app-site-association` (on server)

**Step 1:** Add Associated Domains to entitlements
```xml
<key>com.apple.developer.associated-domains</key>
<array>
  <string>applinks:silni-app.com</string>
  <string>applinks:www.silni-app.com</string>
</array>
```

**Step 2:** Create apple-app-site-association file
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "3SPV37F368.com.silni.app",
        "paths": ["*"]
      }
    ]
  }
}
```

**Step 3:** Deploy AASA file to domain root `/.well-known/`

**Step 4:** Test with Apple's validator

---

### Task 6: Add iOS Permission Descriptions

**Files:**
- Modify: `ios/Runner/Info.plist`
- Create: `ios/Runner/en.lproj/InfoPlist.strings`

**Step 1:** Add NSPhotoLibraryAddUsageDescription

**Step 2:** Create English localization strings

---

### Task 7: Add Database Indexes

**Files:**
- Create: `supabase/migrations/20260123000002_add_performance_indexes.sql`

**Step 1:** Create migration with all indexes

**Step 2:** Push migration

---

## Phase 3: Subscription Fixes (P0) - ~4 hours

### Task 8: Fix PRO Tier Mapping

**Files:**
- Modify: `lib/core/models/subscription_tier.dart`
- Modify: `lib/core/services/subscription_service.dart`

**Step 1:** Update `tierFromProductId` to map PRO products
```dart
static SubscriptionTier tierFromProductId(String productId) {
  if (productId.contains('max')) return SubscriptionTier.max;
  if (productId.contains('pro')) return SubscriptionTier.max; // Map PRO to MAX
  return SubscriptionTier.free;
}
```

**OR** Add PRO tier to enum if business model requires it.

---

### Task 9: Add Subscription Cache & Fallback

**Files:**
- Modify: `lib/core/services/subscription_service.dart`

**Step 1:** Add Hive cache for last-known subscription state

**Step 2:** Read from Supabase `subscription_status` when RevenueCat fails

**Step 3:** Add expiration date validation
```dart
isActive: tier != SubscriptionTier.free &&
          expirationDate != null &&
          expirationDate.isAfter(DateTime.now()),
```

---

### Task 10: Fix Device ID Generation

**Files:**
- Modify: `lib/shared/services/supabase_notification_service.dart`

**Step 1:** Use UUID stored in secure storage instead of timestamp

---

## Phase 4: Testing & CI (P1) - ~2 hours

### Task 11: Fix Failing Widget Tests

**Files:**
- Modify: Test files in `test/widget/`
- Modify: `test/helpers/widget_test_helpers.dart`

**Step 1:** Add proper Riverpod ProviderScope with overrides

**Step 2:** Fix each failing test file

**Step 3:** Run tests
```bash
flutter test
```

---

### Task 12: Create Basic CI Pipeline

**Files:**
- Create: `.github/workflows/ci.yml`

**Step 1:** Create workflow that runs on PR
```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
```

---

## Phase 5: Bundle Size & Polish (P2) - ~2 hours

### Task 13: Optimize Animation File

**Files:**
- Modify: `assets/animations/level_up_burst.json`

**Step 1:** Re-export without embedded images or replace with lighter animation

---

### Task 14: Minify SVG

**Files:**
- Modify: `assets/images/silni_logo.svg`

**Step 1:** Run through SVGO
```bash
npx svgo assets/images/silni_logo.svg
```

---

### Task 15: Remove Unused Dependencies

**Files:**
- Modify: `pubspec.yaml`

**Step 1:** Remove `purchases_ui_flutter` (unused)
**Step 2:** Remove `font_awesome_flutter` if not used
**Step 3:** Run `flutter pub get`

---

### Task 16: Clear Biometric on Logout

**Files:**
- Modify: `lib/shared/services/auth_service.dart`

**Step 1:** Add `clearAllBiometricData()` call in `signOut()`

---

## Phase 6: Final Build & Test (P0) - ~2 hours

### Task 17: Final Production Build

**Step 1:** Clean and rebuild
```bash
flutter clean && flutter pub get && dart run build_runner build --delete-conflicting-outputs
```

**Step 2:** Build release
```bash
flutter build ios --release
```

**Step 3:** Run analysis
```bash
flutter analyze
```

**Step 4:** Deploy functions
```bash
supabase functions deploy --project-ref bapwklwxmwhpucutyras
```

**Step 5:** Push migrations
```bash
supabase db push --project-ref bapwklwxmwhpucutyras
```

---

# SUMMARY TABLE

| # | Task | Priority | Time |
|---|------|----------|------|
| 1 | Remove debugPrint statements | P0 | 1-2h |
| 2 | Fix Firebase keys exposure | P0 | 1h |
| 3 | Fix CORS in edge functions | P0 | 30m |
| 4 | Fix Storage RLS policy | P0 | 30m |
| 5 | Configure Universal Links | P0 | 1h |
| 6 | Add iOS permission descriptions | P0 | 30m |
| 7 | Add database indexes | P0 | 30m |
| 8 | Fix PRO tier mapping | P0 | 1h |
| 9 | Add subscription cache/fallback | P0 | 2h |
| 10 | Fix device ID generation | P1 | 30m |
| 11 | Fix failing widget tests | P1 | 2h |
| 12 | Create basic CI pipeline | P1 | 1h |
| 13 | Optimize animation file | P2 | 30m |
| 14 | Minify SVG | P2 | 15m |
| 15 | Remove unused dependencies | P2 | 15m |
| 16 | Clear biometric on logout | P1 | 30m |
| 17 | Final build & test | P0 | 1h |

**Total Estimated Time: 14-16 hours**

---

# POST-IMPLEMENTATION CHECKLIST

## Before Submission
- [ ] All P0 tasks completed
- [ ] `flutter analyze` passes with no issues
- [ ] `flutter test` passes (currently 82 failing)
- [ ] Production build successful
- [ ] Edge functions deployed
- [ ] Database migrations applied
- [ ] Universal Links verified with Apple validator
- [ ] Test subscription purchase flow end-to-end
- [ ] Test restore purchases
- [ ] Test account deletion
- [ ] Test offline mode behavior

## App Store Connect
- [ ] Archive build in Xcode
- [ ] Upload to App Store Connect
- [ ] Complete age rating questionnaire
- [ ] Add App Store screenshots (Arabic + English)
- [ ] Write App Store description
- [ ] Set pricing and availability
- [ ] Configure in-app purchases
- [ ] Submit for review

## Post-Launch
- [ ] Rotate all exposed credentials
- [ ] Monitor Sentry for errors
- [ ] Monitor RevenueCat for subscription issues
- [ ] Consider git history cleanup for credentials
