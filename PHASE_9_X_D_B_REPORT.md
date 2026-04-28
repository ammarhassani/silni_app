---
name: Phase 9.X.D.B — onboarding wizard structural build (functional, not polished)
description: 6 wizard tasks shipped. Schema migration applied to prod via MCP, Dart wizard built, router redirect wired, settings escape hatch added. Functional first. Animation polish is Track C. Real-device verify gates closure.
type: project
---

# PHASE 9.X.D.B Report

**Date:** 2026-04-28
**Commit:** `c37afc4`

---

## B1 — admin_onboarding_screens schema + seed (APPLIED to prod)

### Pre-state (MCP introspection)

Schema columns existed: `id, screen_order, title_ar/en, subtitle_ar/en, image_url, animation_name, background_color, text_color, accent_color, button_text_ar/en, button_color, skip_enabled, auto_advance_seconds, show_for_tiers, is_active, created_at/updated_at`.

5 seed rows existed with old branding (`واصل` / `Wasel`) and the old wizard-shaped content.

### Migration applied

[`onboarding_wizard_columns_and_seed`](https://supabase.com) (via MCP `apply_migration`):

**Schema additions:**
| Column | Type | Default |
|---|---|---|
| `action_type` | TEXT | `'next'` (NOT NULL) |
| `route` | TEXT | `NULL` |
| `metadata` | JSONB | `'{}'` (NOT NULL) |

**Seed updates** (5 rows):
| # | title_ar | action_type | metadata |
|---|---|---|---|
| 1 | أهلاً بك في صِلْني | `confirm_name` | `{"prompt_for_name": true}` |
| 2 | من يعيش معك في نفس البيت؟ | `add_relative_household` | `{"min_count": 0, "category": "household"}` |
| 3 | من تريد أن تحافظ على صلتك بهم؟ | `add_relative_extended` | `{"min_count": 1, "category": "extended"}` |
| 4 | كيف تفضّل أن نذكّرك؟ | `set_reminder_pref_and_permission` | `{"default_time": "09:00", "default_frequency": "daily"}` |
| 5 | تعرّف على أنيس | `finish` | `{}` |

Branding normalized: `صِلْني` (with diacritics, per BRAND.md), `أنيس` (Anees) AI persona instead of `واصل/Wasel`.

Lottie animation slots renamed to `welcome`, `household`, `extended`, `reminders`, `anees` — actual Lottie files are Track C.

**Self-verify** passed: 3 new columns present, 5 active screens, all action_types valid, no English `Wasel` brand remaining.

**False-positive on first apply:** initial self-verify too aggressive — Arabic word "التواصل" (connection) contains "واصل" as a substring. Narrowed to English-only brand check on second attempt; ran clean.

---

## B5 — Backfill safety check

MCP query: 1 user lacks `setupComplete=true`. Identified as the **founder's intentional fresh test account** created post-A6 backfill to test Bug 1 fix. Halt-and-report per CTO spec satisfied: this is the expected fresh-account state — that user will see the wizard, which is exactly what's wanted.

The 27 other users have `setupComplete=true` from Track A6's backfill — they correctly bypass the wizard.

---

## B2 — Wizard renderer

[`lib/features/onboarding_wizard/onboarding_wizard_screen.dart`](lib/features/onboarding_wizard/onboarding_wizard_screen.dart) (~580 lines, single file)

### Architecture

| Component | Purpose |
|---|---|
| `WizardState` | Immutable state class — `currentStep` (0-indexed), `confirmedName`, `householdAddedCount`, `extendedAddedCount`, `reminderTime`, `permissionGranted` |
| `WizardStateNotifier` | StateNotifier — `next()`, `back()`, `setName`, `incrementHousehold`, `incrementExtended`, `setReminderTime`, `setPermissionGranted` |
| `wizardStateProvider` | StateNotifierProvider.autoDispose (state lives only while wizard is mounted) |
| `OnboardingWizardScreen` | ConsumerWidget parent. Reads `OnboardingConfigService.getScreens()`, dispatches per `action_type` |
| `_StepShell` | Shared layout (progress dots + Lottie placeholder + title + subtitle + CTA stack) |

### Per-step renderers

| Step | Action | UI |
|---|---|---|
| 1 | `confirm_name` | Pure welcome unless full_name is missing OR matches email (Apple Hide-Email auto-generated case). When prompting: TextField with "كيف تحب أن نناديك؟" hint. Save updates auth metadata + `users.full_name` |
| 2 | `add_relative_household` | Pushes `/add-relative?wizard=householdOnly`. After save, increments household count + shows secondary "Add more" button + primary "متابعة". `min_count=0` (skip allowed) |
| 3 | `add_relative_extended` | Same pattern, `min_count=1`. Shows skip link "تخطي الآن" only when count=0 (de-emphasized escape hatch) |
| 4 | `set_reminder_pref_and_permission` | Time picker (forced Western digits via `Localizations.override` Locale('en') per Phase 4 digit policy). Persists picked time to `users.onboarding_metadata.reminderTime`. Then calls `FCMNotificationService.requestPermission()` — Track A7's deferred prompt fires AFTER user picks a time, so OS prompt has context. CTA advances regardless of grant/deny |
| 5 | `finish` | Anees intro. CTA "جاهز" calls `_markSetupComplete` which writes `setupComplete=true` to DB + SharedPreferences + router cache, fires `seed_onboarding_ai_memory` RPC (Track A8), then `context.go(/home)` |

### Skip / back behavior

- Step ≥1 back → `notifier.back()` (state preserves)
- Step 0 back → exit-confirmation dialog. Confirm sets `setupComplete=true` with `setupSkipped=true` flag (analytics) and routes to home — no wizard re-prompt next launch
- Skip link on step 3 (extended) → advances with zero relatives (de-emphasized, only shown when count=0)

### Progress dots

Animated 5-dot indicator at top — current dot 24px wide + primary color, others 8px + 30%-alpha secondary.

---

## B3 — Router redirect

[`lib/core/router/app_router.dart`](lib/core/router/app_router.dart) — added Case 2b plus 4 new helper functions.

### Cache mechanism

The router redirect callback is synchronous. Checking `users.onboarding_metadata->>'setupComplete'` requires a DB roundtrip. Solution: mirror the value into SharedPreferences + an in-memory cache (`_cachedSetupComplete`) that can be read synchronously.

| Function | Purpose |
|---|---|
| `cachedSetupComplete()` | Sync read of the in-memory cache |
| `hydrateSetupCompleteCache()` | Read SharedPreferences → cache. Called at app boot from main.dart's init chain |
| `setCachedSetupComplete(bool)` | Direct cache update from wizard finish or settings re-run |

### Hydration paths

1. **App boot** — main.dart init chain calls `router.hydrateSetupCompleteCache()` (parallel with other config services)
2. **Auth listener** — main.dart's `onAuthStateChange` fires `_hydrateSetupCompleteFromDb` on signedIn/initialSession. Reads DB → writes SharedPreferences → updates cache.
3. **Login screen post-success** — `_navigateAfterLogin` AWAITS the inline DB→prefs→cache hydration BEFORE navigating, closing the race between the unawaited auth-listener call and the immediate `context.go`. Reads DB once + writes both prefs and cache, then navigates to wizard or home as appropriate.

### Redirect cases

| Case | Match | Result |
|---|---|---|
| 2 (existing) | Authenticated + on /login or /signup | `_setupCompletePathForAuthed(ref)` returns wizard or home |
| 2b (new) | Authenticated + on /home + `_setupNotComplete()` | Redirect to /onboarding-wizard |
| 3 (existing) | Unauthenticated + protected route | Redirect to /login |
| 4 (existing) | Authenticated + premium route + free tier | Redirect to /home |

### Race-window behavior

`_setupNotComplete` returns `true` only when cache value is **explicitly `false`**. Returns `false` when cache is null/uninitialized OR true. This means: in the rare race where the cache hasn't hydrated yet, the user reaches /home temporarily; the next router pass (after cache hydrates) sees the false state and redirects.

For login screen specifically, the awaited hydration in `_navigateAfterLogin` makes the race impossible — by the time `context.go` fires, the cache is fresh.

---

## B4 — AddRelativeScreen wizard mode

[`lib/features/relatives/screens/add_relative_screen.dart`](lib/features/relatives/screens/add_relative_screen.dart#L45-L62)

```dart
enum WizardMode {
  householdOnly,
  extendedOnly;
  RelativeCategory get category => switch (this) {
    WizardMode.householdOnly => RelativeCategory.household,
    WizardMode.extendedOnly => RelativeCategory.extended,
  };
}

class AddRelativeScreen extends ConsumerStatefulWidget {
  const AddRelativeScreen({super.key, this.wizardMode});
  final WizardMode? wizardMode;
  ...
}
```

**Effects in wizard mode:**
- `_selectedCategory` initialized to `wizardMode.category` in `initState`
- `RelativeCategoryPicker` widget **hidden entirely** in wizard mode (cleaner than a disabled tile)
- `context.pop(createdRelativeId)` returns the new id so wizard can increment count

**Router integration:** the `/add-relative` route reads `?wizard=householdOnly|extendedOnly` query param. Wizard pushes via `'${AppRoutes.addRelative}?wizard=${mode.name}'`. Normal users reach the route with `wizardMode=null` and full picker access (zero-impact for non-wizard flows).

---

## B6 — Settings escape hatch

[`lib/features/settings/screens/settings_screen.dart`](lib/features/settings/screens/settings_screen.dart) — new tile in Account section between Sign Out and Delete Account:

- **Title:** "إعادة الإعداد"
- **Icon:** `Icons.replay_rounded`
- **Tap:** `_confirmRerunSetup()` shows confirmation dialog ("سيتم إعادة عرض دليل الإعداد. أي إعدادات حالية تبقى كما هي")
- **Confirmed:** sets server-side `onboarding_metadata.setupComplete=false`, mirrors to SharedPreferences + router cache, navigates to /onboarding-wizard
- **Failure:** navigates anyway (user expressed intent; partial DB failure shouldn't strand them)

De-emphasized — between sign-out and delete-account, not at the top. Power-user / support-case path.

---

## session_cleanup_service updated

[`lib/core/services/session_cleanup_service.dart`](lib/core/services/session_cleanup_service.dart) — `setup_complete` SharedPreferences key added to `_exactPerUserKeys`. Cleared on logout AND account-delete (Phase 9.1.A's `clearPerUserDeviceState` is the canonical wipe path). Next account on the same device sees a fresh state.

---

## Verification (engineer-side)

| Check | Result |
|---|---|
| `flutter analyze` | **0 issues** |
| `flutter test test/unit/` | **1175 / 0** |
| `flutter test test/golden/` | **8 / 0** |
| MCP migration self-verify | passed |
| MCP post-state | 5 wizard screens with valid action_type, no Wasel brand |
| iOS build | **deferred to founder** (no iOS-specific changes; Dart-only + edge-fn-free) |

---

## Real-device verification (founder gates Track C)

Founder creates a fresh Google account and walks through the full wizard:

1. **First launch shows the wizard** (not home directly)
2. **Step 1 (Welcome + name confirmation)** — confirms or edits name, advances cleanly
3. **Step 2 (Household)** — opens AddRelativeScreen with category locked to household, picker hidden, can add 0+ relatives, "متابعة" works
4. **Step 3 (Extended)** — opens AddRelativeScreen with category locked to extended, requires at least 1 (skip link only after 0)
5. **Step 4 (Reminder pref + permission)** — time picker shows Western digits, after pick → OS notification permission prompt fires
6. **Step 5 (Anees intro)** — "جاهز" finishes
7. **After finish** — lands on /home, wizard not in back stack
8. **Cold-relaunch** — user lands on home, NOT wizard (setupComplete=true cached)
9. **Settings → "إعادة الإعداد"** — re-runs wizard
10. **AI chat** — Anees references the user's name and the relatives added during wizard

If any step misbehaves, halt and report.

---

## Surprises

1. **MCP self-verify caught Arabic substring false-positive on first apply.** The brand check `LIKE '%واصل%'` was matching legitimate Arabic word "التواصل" (connection) which shares the root و-ص-ل with the old brand "واصل" (Wasel). Narrowed to English-only `LIKE '%Wasel%'` since "Wasel" has no false positives. Reapplied clean.

2. **The cached `setup_complete` SharedPreferences mirror is necessary.** GoRouter's redirect is synchronous; checking JSONB metadata requires a DB roundtrip. The cache-and-mirror pattern (read once on auth event, sync read in redirect) is the same pattern Phase 9.0/9.1 used for `onboarding_completed`. Consistent.

3. **Login screen had to AWAIT the hydration explicitly.** The auth listener's fire-and-forget hydration races with login screen's immediate `context.go`. The awaited inline check in `_navigateAfterLogin` closes the race. Splash screen flow doesn't have this issue (auth listener fires before splash navigates).

4. **`_AddRelativeStep` reuses the same widget twice (household + extended) by switching on `WizardMode`.** Single widget definition; mode flag controls min_count, button label, and skip behavior. Saved ~200 lines vs two separate step widgets.

5. **The `_PresentationStep` fallback** handles unknown `action_type` values gracefully — admin can add new screens without crashing the wizard. Known actions handled explicitly; unknowns render as plain "Next" presentation steps.

---

## Open questions for the CTO

1. **Real-device 10-step verification by founder.** Track C waits on this.
2. **Lottie files for the 5 animation slots** (`welcome`, `household`, `extended`, `reminders`, `anees`). Currently rendering gradient circles with Material icons as placeholders. Track C wires real assets.
3. **Default daily reminder schedule creation** — wizard captures `reminderTime` and writes it to `onboarding_metadata.reminderTime`, but doesn't create a `reminder_schedules` row pre-populated with all the user's relatives. Should the wizard also create a default schedule, or leave that to the user's first manual reminder setup? Currently the latter — defer to founder UX call.
4. **The setupSkipped=true variant** marks the user as "completed" so the wizard doesn't re-prompt. Worth tracking that signal for analytics? No analytics event fires today; would need a wizard-skipped event constant in analytics_events.dart. Not in v1.
5. **The 1 user without setupComplete** — the founder's intentional fresh test account from yesterday. They'll see the wizard on next launch — which is exactly what they want for verification. Confirming this is fine and not a backfill miss.

---

## Closing state

6 of 6 Track B tasks shipped. Migration applied + verified on prod. Code analyze 0, tests 1175/0, golden 8/0. Track C (animation polish + real Lottie files) waits on founder's 10-step real-device verification.
