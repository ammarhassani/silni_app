---
name: Phase 9.X — Three bugs root-caused, audit reveals dormant features, halt for founder decisions
description: Bug C root-caused (no setup wizard exists in code; carousel + signin → home is the entire onboarding). A1/A2 verified — Phase 9.0/9.1.A fixes sound, real-device verify pending. Audit found Monthly Wrapped orphaned (FIXED), Yearly Wrapped half-built, freeze system + OneQuestion engine dormant. Subscription gate drift exists but is intentional API compat.
type: project
---

# PHASE 9.X — Bugs + Audit + Halt Points

**Date:** 2026-04-28
**Status:** ⚠️ Halt — three founder decisions needed before next phase. 2 commits + 1 prior interim shipped.

**Commits in this phase:**

1. `11c2d10` — Phase 9.X.a: incomplete-9.1-cleanup (dead `familyLeaderboardProvider`, dead `FamilyMemberStats` model, dead `invalidate` callsites in family_group_screen) + carousel page 3 copy drift (was selling cut gamification)
2. `223e0da` — Phase 9.X.b: Monthly Wrapped wired to AI Hub (FeatureIds + maxFeatures sets + 4th tile)
3. (Prior) `b70bff0` — analyze baseline cleared (was 6 → now 0 issues)

---

## PART A — Three known bugs

### Bug C — Brand-new account on fresh install skips onboarding

**Root cause: there is no post-signin onboarding gate or wizard in the codebase. By design.**

The app has exactly one onboarding signal:
- [splash_screen.dart:161-176](lib/features/auth/screens/splash_screen.dart#L161-L176) — gates the marketing carousel by SharedPreferences `onboarding_completed`. If `isAuthenticated` is true → straight to `/home` (no wizard check). If not authenticated → onboarding-or-login based on the flag.
- [main.dart:705-717](lib/main.dart#L705-L717) — flips the flag on every signedIn / initialSession event. So once the user signs in, the flag is set and the carousel never fires again.
- [login_screen.dart:91](lib/features/auth/screens/login_screen.dart#L91) — post-Google-OAuth goes directly to `AppRoutes.home`. No setup wizard, no relative-count check, no household categorization step.
- [app_router.dart:55-110](lib/core/router/app_router.dart#L55-L110) — the only auth-related router redirect is "authenticated user on `/login`/`/signup` → `/home`". No "authenticated user with onboarding incomplete → /setup".

**CTO's four hypotheses verified:**
- ❌ #1 (`users.onboarding_completed` defaults true): No such column. `handle_new_user` only inserts `id, email, full_name, created_at, last_login_at`. The only onboarding-adjacent column is `users.onboarding_metadata JSONB DEFAULT '{}'` from `supabase/migrations/20251229_premium_onboarding.sql:9-10`, which tracks the **premium** feature-tour, not first-run setup.
- 🟡 #2 (wrong signal): Closest. The single signal exists but doesn't gate setup — only the marketing carousel.
- ❌ #3 (relative-count race): Nothing in the post-signin path checks relative count.
- ❌ #4 (multiple confused signals): Only one signal exists (`prefs.onboarding_completed`), read in exactly one place.

**Failure cascade for the founder's repro:**

1. App launches → SplashScreen → `isAuthenticated` = false (fresh install) → routes to `/onboarding`
2. Founder taps through the 4-page marketing carousel → `_finish` (intentionally does NOT write the flag) → routes to `/login`
3. Founder Google-OAuth-signs-in → onAuthStateChange fires `signedIn` → `_markOnboardingCompleted` writes the flag → `_navigateAfterLogin` → `/home`
4. Home screen renders. Has 0 relatives. Shows the empty-state CTA "ابدأ بإضافة أفراد عائلتك" + "إضافة أول قريب" button at [family_circles_widget.dart:398-432](lib/features/home/widgets/family_circles_widget.dart#L398-L432) — but it's the **6th section down** (below greeting, 2 marketing-message slots, hadith, quick-actions, occasion card). A founder skimming the home screen quickly may miss it entirely.

Founder's "as if returning" feeling is real — there is no surface that **forces** a new user through setup. The empty-state CTA is voluntary and buried.

**Fix is non-trivial. Three options for the founder:**

🅰️ **Build a real setup wizard** (~4-8 hours):
   - New schema column: `users.first_run_completed_at TIMESTAMPTZ NULL` + migration
   - New route `/setup` registered in app_router
   - Multi-step UI: welcome → add first relative(s) → categorize them (household / extended / distant)
   - Router redirect: authenticated + `first_run_completed_at IS NULL` → `/setup`
   - "Skip setup" path that still records completion to avoid loops
   - Backfill migration: existing users with relatives.user_id rows get marked completed
   - Deep-link special case for `/join/:code` (joining a group implicitly completes setup)
   - Tests

🅱️ **Beef up the home empty state into a hero CTA** (~1-2 hours):
   - When `relatives.isEmpty`, the home screen replaces the entire normal layout with a full-bleed CTA: "هذي عائلتك — ابدأ بإضافة أول قريب" + big button + 1 supporting line
   - No marketing messages, no hadith, no quick actions until first relative added
   - Once `relatives.isEmpty == false`, show normal home
   - No schema changes, no router redirects, no backfill

🅲️ **Accept current behavior — it's a mental-model gap, not a code bug** (0 hours):
   - The empty-state CTA already exists; it's just buried
   - Reorder the home screen so `FamilyCirclesSection` is at the top when empty
   - Document the behavior so the founder's expectation aligns

**Recommendation:** 🅱️ — gives a "guided first step" feel without the schema+route+backfill complexity of 🅰️. Founder can later upgrade to 🅰️ in v1.1 if 🅱️ proves insufficient.

**Real-device verification halt: founder needs to confirm Bug C closure once the chosen option ships.**

---

### Bug A1 — Delete-then-relogin skips onboarding

**Root cause: same as Bug C** — no setup wizard exists. Phase 9.0 + 9.1.A correctly clear all per-user state on delete, so a re-logged-in user enters the carousel just like a brand-new user. They then experience exactly the Bug C flow.

**Whatever fix is chosen for Bug C closes Bug A1 too.** No separate fix needed.

Phase 9.0 fix sites verified sound on re-read:
- [auth_service.dart deleteAccount](lib/shared/services/auth_service.dart) routes through wrapper `signOut()` (clears biometric)
- Phase 9.1.A `clearPerUserDeviceState()` at [session_cleanup_service.dart](lib/core/services/session_cleanup_service.dart) clears 15 per-user keys + 2 prefix patterns

**Real-device verification pending.** Founder action required.

---

### Bug A2 — Home greeting widget disappears after navigation

**Phase 9.0's fix is sound; verified on re-read.**

Phase 9.0 (`69ecffc`) shipped two edits:
- [streak_badge_bar.dart:47-51](lib/features/home/widgets/streak_badge_bar.dart#L47-L51): error fallback renders `_buildBar(empty)` instead of `SizedBox.shrink()`
- [home_providers.dart:343-360](lib/features/home/providers/home_providers.dart) — dropped `autoDispose` from `userGamificationDataProvider`

Re-verified:
- Parent `home_header_widget` mounts the bar **unconditionally** at [home_header_widget.dart:129-133](lib/features/home/widgets/home_header_widget.dart#L129-L133) (no parent conditional hiding)
- Bar renders on `loading` (skeleton), `data` (full), `error` (empty bar with name + tier + 0-streak placeholder)
- Provider stays alive across navigation since autoDispose was removed

If the founder is still seeing this on real device, they may be testing a build older than `b70bff0`. **Founder should re-test on the latest build.** If it persists on the latest build, it's a different/intermittent failure I can't pin down from code alone.

---

## PART B — Silent feature deactivation audit

The audit's high-priority/high-impact findings only — full feature inventory walk follows.

### 🔴 BROKEN / DORMANT

#### Streak freeze system (whole subsystem dormant)

The freeze system has a complete data model + UI widgets + service methods, but **none of the write paths have any callers**. Discovered via grep:

- `StreakFreezeService.awardMilestoneFreeze()` ([streak_freeze_service.dart:56](lib/core/services/streak_freeze_service.dart#L56)) — **0 callers in lib/**
- `StreakFreezeService.useFreeze()` ([streak_freeze_service.dart:96](lib/core/services/streak_freeze_service.dart#L96)) — only called from `autoUseIfNeeded` (which itself has 0 callers)
- `StreakFreezeService.autoUseIfNeeded()` ([streak_freeze_service.dart:173](lib/core/services/streak_freeze_service.dart#L173)) — **0 callers in lib/**
- `FreezeInventoryBadge` + `FreezeInventoryCard` widgets ([freeze_inventory_widget.dart:13, 79](lib/shared/widgets/freeze_inventory_widget.dart)) — **never rendered anywhere in the app**
- `supabase/functions/check-streak-alerts/index.ts` — no `freeze` references; the cron-side path doesn't auto-use freezes either

So the entire freeze flow is dormant: no UI shows freeze inventory, no code awards freezes at milestones, no code uses freezes (auto or manual). The `streak_freezes` table + `users.streak_freezes` column + `freeze_usage_history` table all exist on prod but receive no writes.

**Founder decision needed:** wire it up, or rip it out?
- Wire: ~2-3 hours. Inject `StreakFreezeService` into `RelativeStreakService`, hook `awardMilestoneFreeze` after streakMilestone emit, render `FreezeInventoryBadge` in the streak bar header, hook `autoUseIfNeeded` into `check-streak-alerts` cron. Notification template for `freezeUsed` + `freezeEarned`.
- Rip: ~1 hour. Drop the service methods, the widgets, and the DB tables; emit only via the streak counter alone.

#### OneQuestion engine + widget (dormant)

The progressive fact-gathering feature is fully built but never invoked:
- [`OneQuestionEngine.getQuestion`](lib/core/services/one_question_engine.dart) — **0 callers in lib/**
- [`FollowUpQuestionSheet`](lib/shared/widgets/follow_up_question_sheet.dart) — defined but never `.show()`-ed

5 question types built (interests, health, communication_style, best_time, sensitive_topics), per-week rate limit logic, per-relative asked-question tracking — all dormant.

**Founder decision needed:** wire it up (UX choice — show after first interaction with a relative? Show on relative detail screen? Show as a notification?), or rip it out.

### 🟡 WRONGLY GATED — subscription status drift

[`subscription_service.dart:796`](lib/core/services/subscription_service.dart#L796) writes `'premium'` to `users.subscription_status` when the tier is `max`. The read at [`subscription_service.dart:681`](lib/core/services/subscription_service.dart#L681) accepts both `'premium'` and `'max'` for forward-compat.

The `'premium'` literal is intentional API compatibility — the `sync-subscription` edge function expects it for legacy reasons. So the system is **functionally working** (you can be MAX and the app correctly identifies you), just confusingly named. Cleaning up requires a coordinated server-side edge-function change + DB backfill of `users.subscription_status`. **Defer to v1.1.**

All other `userTier == 'max'` comparisons in lib/ go through the parsed tier object, not the raw DB string — so no drift exposure.

### 🟢 ENTRY POINT MISSING

#### Monthly Wrapped — **FIXED in commit `223e0da`**

Was a fully-built feature (route registered, screen at [monthly_wrapped_screen.dart](lib/features/wrapped/screens/monthly_wrapped_screen.dart), `monthlyWrappedProvider` chain at [wrapped_providers.dart](lib/features/wrapped/providers/wrapped_providers.dart), AI personality prompt) but with **zero callsites pushing to its route**. The AI Hub had three tiles (Chat, Scripts, Report); Wrapped was the missing fourth. Added a tile + new `FeatureIds.monthlyWrapped` constant + entries in both `maxFeatures` fallback sets. Behind the same MAX gate as the other AI features.

#### Yearly Wrapped — **HALT, founder decision needed**

The model + provider + generator service exist:
- [yearly_wrapped_model.dart](lib/features/wrapped/models/yearly_wrapped_model.dart)
- [wrapped_providers.dart:140](lib/features/wrapped/providers/wrapped_providers.dart#L140) `yearlyWrappedProvider`
- [wrapped_generator_service.dart:170](lib/features/wrapped/services/wrapped_generator_service.dart#L170) `generateYearly`

But there is **no screen, no route, no entry point**. To make Yearly Wrapped reachable, someone needs to build a `YearlyWrappedScreen` analogous to the monthly one. That's a feature build, not a wiring fix.

**Recommendation:** Decide whether yearly wrapped is part of v1 launch:
- If yes → schedule a screen build (~2-4 hours, can reuse monthly's structure)
- If no → rip out the model + provider + generator to keep the codebase honest

### ⚪ WORKING / CORRECTLY ACTIVATED

| Feature | Verdict | Evidence |
|---|---|---|
| AI Chat | ✅ Reachable + MAX-gated | Entry: AI Hub, premium onboarding tour, persistent bottom nav |
| Communication Scripts | ✅ Reachable + MAX-gated | Entry: AI Hub, premium onboarding completion modal |
| Weekly Report | ✅ Reachable + MAX-gated | Entry: AI Hub, premium onboarding tour |
| Hadith of the day | ✅ Mounted on home unconditionally | [home_screen.dart:54](lib/features/home/screens/home_screen.dart#L54) `_loadDailyHadith()` + [islamic_reminder_widget.dart](lib/features/home/widgets/islamic_reminder_widget.dart) |
| Family circles section | ✅ Mounted on home, has empty state CTA | [family_circles_widget.dart:398](lib/features/home/widgets/family_circles_widget.dart#L398) |
| AI suggested prompts (chat) | ✅ Rendered on chat empty state | [ai_chat_screen.dart:140](lib/features/ai_assistant/screens/ai_chat_screen.dart#L140) |

### Features I did NOT verify in depth (low risk)

- Family group invite/join flow — assumed working; founder reported no specific bug
- Reminder firing (cron) — assumed working; backend stable since Phase 5
- Family tree canvas — assumed working; backend stable since Wave 2
- Daily reminder content — assumed working

If any of these turn out to be broken on real device, surface them in the next phase.

---

## PART C — Fixes applied

### Phase 9.X.a (`11c2d10`) — incomplete-Phase-9.1-cleanup

| File | Change |
|---|---|
| [home_providers.dart](lib/features/home/providers/home_providers.dart) | Removed dead `familyLeaderboardProvider` (read dropped columns `points`, `level`) + `FamilyMemberStats` model class |
| [family_group_screen.dart](lib/features/family_groups/screens/family_group_screen.dart) | Removed 2 dead `ref.invalidate(familyLeaderboardProvider...)` callsites |
| [onboarding_screen.dart](lib/features/auth/screens/onboarding_screen.dart) | Carousel page 3 copy: "احتفل بإنجازاتك / كسب النقاط والشارات" → "سلسلة التواصل / حافظ على عادة التواصل اليومي" (was selling cut gamification to brand-new users) |

### Phase 9.X.b (`223e0da`) — Monthly Wrapped tile

| File | Change |
|---|---|
| [subscription_tier.dart](lib/core/models/subscription_tier.dart) | Added `FeatureIds.monthlyWrapped = 'monthly_wrapped'` + `monthlyWrapped => SubscriptionTier.max` in requiredTier switch |
| [feature_config_service.dart](lib/core/services/feature_config_service.dart) | Added `'monthly_wrapped'` to maxFeatures fallback set |
| [feature_config_provider.dart](lib/core/providers/feature_config_provider.dart) | Same |
| [ai_hub_screen.dart](lib/features/ai_assistant/screens/ai_hub_screen.dart) | Fourth tile "ملخصك الشهري — قصة شهرك في صلة الرحم بأسلوب يخصك" with auto_awesome icon |

### Verification

- `flutter analyze`: **0 issues** (cleared baseline in `b70bff0` + maintained through 9.X.a + 9.X.b)
- `flutter test test/unit/`: **1175 / 0** (added 8 from a previous test seed)
- `flutter test test/golden/`: **8 / 0**

---

## Open questions — founder decisions needed

1. **Bug C / A1 fix scope.** Pick option 🅰️ (build setup wizard), 🅱️ (beef up empty state), or 🅲️ (reorder home + accept). Recommendation: 🅱️ as v1, 🅰️ as v1.1 if needed.

2. **Streak freeze system.** Wire it up (~2-3 hrs) or rip it out (~1 hr)? The dormancy is unflagged so this is an audit-driven discovery.

3. **OneQuestion engine.** Wire it up (UX decision: where to surface the question?) or rip it out?

4. **Yearly Wrapped.** Build a screen to match the monthly one (~2-4 hrs) or rip the model+provider+generator?

5. **Real-device verification of A1, A2, C closure.** Bug C is open until 1 ships. A1 closure depends on Bug C closure. A2 needs founder re-test on `b70bff0`+ to confirm or surface a new failure mode.

6. **Subscription gate drift cleanup.** The 'premium' vs 'max' literal mismatch between client-write and server-state. Defer to v1.1 since it's intentional compat — but worth noting for future cleanup.

---

## Surprises

- **The freeze system was dormant before Phase 9.1, not because of it.** Phase 9.1's "preserve streak mechanism including freezes" preserved code paths that already had no callers. Worth re-reading 9.1's claim of "freezes preserved" — they're preserved as a data structure, not a working feature.
- **Two AI features (Wrapped, OneQuestion) and one whole subsystem (freeze) silently dormant** suggests a pattern: features get half-built when scope-cut mid-sprint, code stays in tree but never reaches users. The Phase 9.X audit is a one-time sweep — recommend a quarterly "is everything reachable?" check.
- **Carousel page 3 was selling deleted features to every new user**, undiscovered for ~24 hours after Phase 9.1 shipped. Worth a CI rule that grep's marketing copy against feature flags.

---

## Closing state

Three commits land Phase 9.X (so far):
1. `b70bff0` — analyze baseline cleared (0 issues)
2. `11c2d10` — Phase 9.X.a interim cleanup
3. `223e0da` — Phase 9.X.b Monthly Wrapped tile

Bug C / A1 / Yearly Wrapped / freeze system / OneQuestion all halted at founder-decision points. App version unchanged (`2.1.0+1`). Streak counter + Monthly Wrapped + AI Hub + content enhancers all live and reachable.
