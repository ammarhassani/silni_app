---
name: Onboarding Archaeology — what existed, what was deleted, what was never wired
description: Forensic git+filesystem archaeology in response to the founder's "I think a setup wizard with backend support existed at some point" hypothesis. Evidence: the founder is partially correct. A configurable-from-admin onboarding system was scaffolded end-to-end (DB table, seed data, Dart service, app-route registry) and the seed even points at a real setup-wizard intent (Add Relatives, Set Reminders steps). The consumer screen that would render the admin-configured screens was never written.
type: project
---

# ONBOARDING_ARCHAEOLOGY.md

**Date:** 2026-04-28
**Method:** Git history + filesystem grep across all branches and migrations. MCP read-only intent (MCP disconnected mid-session — schema queried via migration files instead).
**Conclusion:** The founder's memory is partially correct. Backend + service + seeded content for a setup wizard exists in prod schema. The Dart consumer that would render it was never written.

---

## Section 1 — Did onboarding ever exist?

**PARTIAL — three onboarding systems exist or have existed; none of them is a true first-run setup wizard.**

### 1.1 — Marketing carousel (live in current code)

[`lib/features/auth/screens/onboarding_screen.dart`](lib/features/auth/screens/onboarding_screen.dart) — 4 hardcoded `OnboardingPage`s. Gated by SharedPreferences `onboarding_completed` flag. Currently the only "onboarding" the user actually sees. Phase 9.X.a (`11c2d10`) cleaned page 3's stale gamification copy.

### 1.2 — Admin-configurable onboarding (orphaned in current code, schema fully built)

This is the smoking gun for the founder's "backend support existed" memory.

**Backend (live in prod):**
- [`supabase/migrations/20260101100004_admin_onboarding.sql`](supabase/migrations/20260101100004_admin_onboarding.sql) (2026-01-01) — creates `admin_onboarding_screens` table. Full schema: screen_order, title_ar/en, subtitle_ar/en, image_url, animation_name (Lottie), background colors/gradients, button text, skip_enabled, auto_advance_seconds, show_for_tiers TEXT[], is_active. RLS + updated_at trigger.
- [`supabase/migrations/20260101100005_add_ui_onboarding_cache.sql`](supabase/migrations/20260101100005_add_ui_onboarding_cache.sql) (2026-01-01) — registers `onboarding_config` cache key in `admin_cache_config` (3600s TTL).
- [`supabase/migrations/20260111120000_reseed_all_admin_tables.sql`](supabase/migrations/20260111120000_reseed_all_admin_tables.sql) (2026-01-11) — **rewrote the seed** from generic marketing into wizard-shaped content (see Section 3).
- [`supabase/migrations/20251231200003_seed_app_routes.sql`](supabase/migrations/20251231200003_seed_app_routes.sql) — registers `/onboarding` as an `auth` category route.

**Service code (live in current Dart code, fully wired):**
- [`lib/core/services/onboarding_config_service.dart`](lib/core/services/onboarding_config_service.dart) — 230+ lines. Singleton service. `OnboardingScreenConfig` model class. Loads from `admin_onboarding_screens` via Supabase. Has fallback list of 3 hardcoded screens. Methods: `initialize()`, `refresh()`, `clearCache()`, `getScreens({String? forTier})`, `getScreen(int order)`, `getScreensForTier(String tier)`.
- [`lib/main.dart:488`](lib/main.dart#L488) — `OnboardingConfigService.instance.initialize()` is called during app boot, parallel with all other config services.
- [`lib/main.dart:740`](lib/main.dart#L740) — `OnboardingConfigService.instance.refresh()` is called on app foreground (didChangeAppLifecycleState resumed).

**Consumer code (what would render the admin-configured screens):**
- **None.** Searches:

```
grep -rnE "\.getScreens|\.getScreen\b|getScreensForTier|onboardingConfigService\." lib/
```

Returns only the definition site inside `onboarding_config_service.dart` itself. **Zero callers in the rest of the codebase.**

The architecture clearly intended `OnboardingScreen` (auth/onboarding_screen.dart) to consume `OnboardingConfigService.getScreens()` and render admin-configured screens with the hardcoded `_pages` list as a fallback. But the consumer wiring was never written. The current carousel is the hardcoded fallback rendered as if it were the source of truth.

### 1.3 — Premium onboarding paywall walkthrough (live in current code)

Different feature, common name. Triggered after MAX subscription purchase. Different schema, different UX surface.

**Backend (live in prod):**
- `users.onboarding_metadata JSONB DEFAULT '{}'` column ([`supabase/migrations/20251229_premium_onboarding.sql`](supabase/migrations/20251229_premium_onboarding.sql)) — stores premium walkthrough state: `hasStarted`, `isCompleted`, `stepProgress`, `viewedScreens`.
- `onboarding_events` table — analytics events for premium walkthrough only (event types: `onboarding_started`, `step_viewed`, `step_completed`, `step_skipped`, `showcase_skipped`, `onboarding_completed`, `tip_shown`, `tip_dismissed`).
- `get_onboarding_analytics(p_start_date, p_end_date)` RPC — analytics summary for the premium walkthrough.

**Frontend (live in current code):**
- [`lib/features/premium_onboarding/screens/premium_onboarding_screen.dart`](lib/features/premium_onboarding/screens/premium_onboarding_screen.dart)
- [`lib/features/premium_onboarding/providers/onboarding_storage_provider.dart`](lib/features/premium_onboarding/providers/onboarding_storage_provider.dart) — reads/writes `users.onboarding_metadata`
- Triggered from [`lib/features/subscription/screens/paywall_screen.dart:760, 796`](lib/features/subscription/screens/paywall_screen.dart#L760)

This is **not** what the founder is asking about — it's the post-paywall feature tour, currently 3 steps (AI Counselor, Unlimited Reminders, Weekly Reports) per [`c686e0b refactor(onboarding): cut premium carousel to 3 steps`](https://github.com/anthropics/claude-code/commit/c686e0b).

### 1.4 — True first-run setup wizard (relative-add + household-categorize)

**Never existed.** Searches:
- `grep -rnE "OnboardingRepository|OnboardingService|SetupRepository|SetupService" lib/` — only the `OnboardingConfigService` (the admin-configurable screens service from §1.2)
- `grep -rnE "OnboardingState|SetupState|WizardState|OnboardingStep|SetupStep" lib/` — only the premium-onboarding state from §1.3
- `grep -rnE "/setup|/wizard" lib/core/router/` — zero hits
- `git log --all --diff-filter=D --name-only` filtered for setup/wizard/welcome — only matches are React-era artifacts in `old_react_project/` (which is the pre-Flutter codebase) and `setup_reminders_prompt.dart` / `setup_reminders_section.dart` (different feature — reminder configuration, not first-run setup)

No "AddFirstRelativeScreen", no "HouseholdSetupScreen", no `users.first_run_completed_at` column, no router redirect that would force a brand-new authenticated user through such a flow.

---

## Section 2 — Timeline of onboarding code

| Date | Commit / Migration | What happened |
|---|---|---|
| 2025-12-29 | `20251229_premium_onboarding.sql` | Premium walkthrough's `onboarding_metadata` column + `onboarding_events` table + analytics RPC. **Premium feature tour, NOT setup wizard.** |
| 2025-12-31 | `20251231200003_seed_app_routes.sql` | Registers `/onboarding` route in `admin_app_routes` under `auth` category. |
| 2026-01-01 | `20260101100004_admin_onboarding.sql` | **`admin_onboarding_screens` TABLE created**, 5 marketing screens seeded (the original seed sold the gamification "Rewards System" on screen 4). |
| 2026-01-01 | `20260101100005_add_ui_onboarding_cache.sql` | Cache config for `onboarding_config` registered. |
| 2026-01-11 | `20260111000000_sync_schema_to_staging.sql` | Among other columns, ensures `users.onboarding_metadata JSONB` exists. (Premium walkthrough's column.) |
| 2026-01-11 | `20260111120000_reseed_all_admin_tables.sql` | **Reseed pivots `admin_onboarding_screens` into a setup-wizard-shaped flow** — see Section 3. This is the strongest evidence that someone was trying to build a real setup wizard. |
| 2026-01-12 | `20260112100000_sync_app_routes.sql` | App-route sync. |
| Sometime in early 2026 | `OnboardingConfigService` Dart code written | The service that would consume `admin_onboarding_screens`. Wired into `main.dart` boot. **Consumer screen was never written.** |
| 2026-04-25 | `c686e0b refactor(onboarding): cut premium carousel to 3 steps` | Phase 3 cut the premium walkthrough from 5 to 3 steps. Killed the home-screen auto re-show. **Affects premium walkthrough only.** |
| 2026-04-25 | `3585840 chore(phase-0)` | Phase 0 deleted 10 dart screens (gamification, AI features, **`yearly_wrapped_screen.dart`**) but **NO onboarding screens were touched**. The orphaned `OnboardingConfigService` survived. |
| 2026-04-28 | Phase 9.X | This investigation discovered the orphan. |

**Key insight:** the founder may be conflating the Jan 11 reseed (which DID design a setup wizard's content) with a working setup wizard. The content was designed; the renderer was never written.

---

## Section 3 — `admin_onboarding_screens` content

### Original seed (2026-01-01, from `20260101100004_admin_onboarding.sql`)

Marketing carousel, 5 generic screens, screen 4 sold gamification:

| # | Title (AR) | Title (EN) | Animation | Note |
|---|---|---|---|---|
| 1 | مرحباً بك في صِلني | Welcome to Silni | onboarding_welcome | Marketing |
| 2 | تذكيرات ذكية | Smart Reminders | onboarding_reminders | Marketing |
| 3 | مستشار واصل | Wasil Assistant | onboarding_ai | Marketing |
| 4 | نظام المكافآت | Rewards System | onboarding_gamification | **Marketing — sells points/badges/levels (cut in Phase 9.1)** |
| 5 | ابدأ رحلتك | Start Your Journey | onboarding_start | Sign-up CTA |

### Reseed (2026-01-11, from `20260111120000_reseed_all_admin_tables.sql`)

**Setup-wizard-shaped flow.** Same migration's reseed block deleted all rows and reinserted with this content:

| # | Title (AR) | Title (EN) | Animation | Intent |
|---|---|---|---|---|
| 1 | مرحباً بك في واصل | Welcome to Wasel | welcome | Marketing intro |
| 2 | **أضف أقاربك** | **Add Your Relatives** | relatives | **🔴 SETUP STEP — was supposed to wire to the add-relative flow** |
| 3 | **ضع تذكيرات** | **Set Reminders** | reminders | **🔴 SETUP STEP — was supposed to wire to reminder configuration** |
| 4 | تابع سلسلتك | Track Your Streak | streak | Streak explainer |
| 5 | استشر واصل | Ask Wasel | ai | AI counselor explainer |

**The reseed is the founder's memory.** Someone was clearly designing a setup wizard: screens 2 and 3 are not marketing — they're labeled as user-action prompts. The fact that step 2 is "Add Your Relatives" and step 3 is "Set Reminders" matches the founder's expectation exactly: "an onboarding flow with relative-add and household setup."

### Current prod state

**Cannot query directly** — MCP disconnected mid-session. The most recent migration (the 2026-01-11 reseed) is the last evidence of what's in the table unless an admin-panel UI has overwritten it since (no evidence of that in the codebase).

---

## Section 4 — Currently-orphaned references

### 4.1 — `OnboardingConfigService` (orphaned consumer-side)

- **Service exists, runs on boot.** Initialize at `main.dart:488`, refresh at `main.dart:740`.
- **No Dart code consumes its `getScreens()` / `getScreensForTier()` methods.** Verified by grep across `lib/`.
- **Net effect:** every app cold-start fetches the admin-configured onboarding screens from `admin_onboarding_screens`, caches them in memory for 3600s, and discards them when the process dies. Wasted bandwidth + Supabase quota, no user-visible effect.

### 4.2 — Hardcoded carousel diverged from admin-configurable seed

- [`lib/features/auth/screens/onboarding_screen.dart`](lib/features/auth/screens/onboarding_screen.dart) hardcodes 4 pages with fixed icons + Arabic copy.
- The Jan 11 admin-configured seed has 5 screens, including the setup-step intent.
- The hardcoded carousel and the admin seed have **drifted in count and intent**. Any admin updating the seed today would not affect what users see.

### 4.3 — `/onboarding` route registry

- [`supabase/migrations/20260112100000_sync_app_routes.sql`](supabase/migrations/20260112100000_sync_app_routes.sql) registers `/onboarding` as a `main` category route with `is_navigable=true`.
- [`supabase/migrations/20251231200003_seed_app_routes.sql`](supabase/migrations/20251231200003_seed_app_routes.sql) registers `/onboarding` as an `auth` category route.
- Two migrations register the same route differently. The latter probably wins per ordering, but both seeds exist in history.
- `/achievements` and `/statistics` routes are also registered in the Jan 12 sync but **don't exist** in current Dart router. Symptom of the same scope-cut pattern as the orphan onboarding service.

### 4.4 — Premium onboarding paywall walkthrough (NOT orphaned)

The premium walkthrough is fully wired and live. Reading `users.onboarding_metadata` is its sole purpose. **Do not confuse with first-run setup.**

---

## Section 5 — Reconstructibility verdict

### 5.1 — Was a true setup wizard ever built?

**No.** The renderer was never written. There are no deleted `*WizardScreen.dart` or `*SetupScreen.dart` files anywhere in git history (verified via `git log --all --diff-filter=D --name-only` filtered for setup/wizard/welcome — only React-era hits in `old_react_project/`).

### 5.2 — Is the foundation reconstructible?

**Yes — about 60% of the work is already done.**

What exists already and can be reused:
- ✅ `admin_onboarding_screens` table schema in prod
- ✅ `admin_cache_config` entry for `onboarding_config`
- ✅ `OnboardingConfigService` Dart service with full provider-cache lifecycle
- ✅ `OnboardingScreenConfig` model class with fromJson + tier-targeting
- ✅ Seeded screen content shaped like a setup wizard (Welcome → Add Relatives → Set Reminders → Streak → AI)
- ✅ `/onboarding` route registered in admin route registry
- ✅ Lottie animation slot (`animation_name` column) — anim files would need to be created or referenced

What needs to be built:
- 🔨 The actual `SetupWizardScreen` widget that consumes `OnboardingConfigService.getScreens()` and renders each as a page
- 🔨 Per-screen action wiring: screen 2 ("Add Your Relatives") needs to push to the add-relative flow and capture completion. Screen 3 ("Set Reminders") needs to push to reminder configuration.
- 🔨 A "wizard completion" marker. Cleanest option: add a `users.onboarding_metadata->>'setupComplete'` JSON path (column already exists, used today by premium walkthrough — co-tenant the column).
- 🔨 Router redirect: authenticated user with no setupComplete marker → `/onboarding` (or new `/setup`); deep-link `/join/:code` should bypass.
- 🔨 Backfill: existing users with relatives.user_id rows get their `onboarding_metadata.setupComplete = true` marker set, so they don't accidentally re-enter the wizard on next login.
- 🔨 Lottie animations referenced by the seed (`welcome`, `relatives`, `reminders`, `streak`, `ai`) — need to be created or found.

**Effort estimate:** 4-6 hours of focused work for a v1 MVP. The schema-first approach is much cleaner than building from scratch.

### 5.3 — Was the deletion clean?

**There was no deletion.** The setup wizard's renderer was never written; no commit removed it. The orphan is a "scope-cut mid-sprint" pattern, not a "removed in cleanup" pattern.

The closest deletion in the engagement was Phase 0 (`3585840 chore(phase-0)`), which removed:
- 7 gamification screens (badges, challenges, detailed_stats, gaming_center, leaderboard, etc.)
- 3 AI feature screens (memory_viewer, message_composer, relationship_analysis)
- `yearly_wrapped_screen.dart`
- 4 social-* edge functions
- `gyroscope_service.dart`

**None of these were onboarding.** Phase 0's deletions were about cutting unmaintained features, not removing a setup wizard.

### 5.4 — Backend cleanup verdict

If the founder decides to **build the wizard:** the backend is sound, no schema changes needed beyond the new `onboarding_metadata->>'setupComplete'` JSON path.

If the founder decides to **rip out the orphan:** delete the `admin_onboarding_screens` table, the `admin_cache_config 'onboarding_config'` row, the `/onboarding` admin-route entries, and `OnboardingConfigService` from Dart. ~5 files affected.

---

## Section 6 — Open questions for the CTO

1. **Confirm the founder's memory.** The Jan 11 reseed of `admin_onboarding_screens` (with "Add Your Relatives" + "Set Reminders" as steps 2-3) is the most likely artifact of the founder's "I remember a setup wizard with backend support" recollection. Is this what the founder remembers, or do they remember a different artifact (e.g., a fully working renderer that was deleted later)? If the latter, my searches did not find it — would need to know which calendar window the founder is recalling and what bundle ID/branch the fully-working version was on.

2. **Yearly Wrapped (deleted in Phase 0) is parallel evidence.** `yearly_wrapped_screen.dart` was a fully-built screen Phase 0 deleted, even though the model + provider + generator service were preserved. If the founder remembers Yearly Wrapped working, that's a real memory of a real working feature that got deleted. The setup wizard does NOT have the same shape — its schema + service exist but the screen never did.

3. **Re Phase 9.X options**, the archaeology updates the recommendation:
   - 🅰 (full setup wizard from scratch) → revise to **🅰' (build wizard atop the existing scaffold)**: 4-6 hours instead of 4-8, since the schema + service + seed already exist.
   - 🅱 (beef up empty state) → still valid as a quick alternative
   - 🅲 (reorder home + accept) → still valid
   - **New option 🅳 (rip the orphan):** if the founder doesn't want to build the wizard, the cleanest move is to delete `admin_onboarding_screens`, the cache config row, the orphan service, and the `/onboarding` admin-route registry entries. About 1-2 hours of cleanup. Removes confusion, frees up future cycles to be unambiguous.

4. **The orphaned `/achievements` and `/statistics` route registrations** also point at scope-cut features. Out of scope for this report but worth a separate v1.1 cleanup.

5. **The `OnboardingConfigService` runs on every cold-start fetching admin screens that nobody renders.** This is wasted bandwidth + Supabase quota. Independent of any wizard decision, this should be removed if the wizard isn't being built.

---

## Closing state

The founder's memory is **partially correct** — there was a real attempt to build admin-configurable onboarding with a setup-wizard intent (the Jan 11 reseed), but the consumer Dart code was never written. The system is ~60% scaffolded and recoverable; not deleted, just abandoned.

This archaeology session: pure forensic discovery. No code changes. No commits. Findings only.
