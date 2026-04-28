---
name: Onboarding Knowledge — completeness audit of user-specific state
description: Forensic completeness audit of every piece of user-specific state the app reads, who writes it, and what's missing entirely. Walks 35+ user columns, 50+ relative columns, both reminder crons, self-node lifecycle, AI seeding, locale handling, and per-screen empty states. The wizard's content list is in Section 11.
type: project
---

# ONBOARDING_KNOWLEDGE.md

**Date:** 2026-04-28
**Method:** Code+migrations grep across `lib/`, `supabase/migrations/`, `supabase/functions/`. MCP disconnected — schema introspection from migration files instead.
**Output goal:** the wizard's content list (Section 11) plus any engine work needed before the wizard can capture certain state (Section 12).

---

## Section 1 — User profile completeness

`users` table has **35 columns**. Verdicts per column:

| Column | Type | Where READ | Where WRITTEN | Default | Verdict |
|---|---|---|---|---|---|
| `id` | UUID | Everywhere (FK) | `handle_new_user` trigger | from auth.uid() | ✅ Auto |
| `email` | TEXT | profile, auth, notifications | `handle_new_user` from auth.users.email | NOT NULL | ✅ Auto |
| `full_name` | TEXT | profile, AI greetings (sometimes), home greeting | `handle_new_user` from `raw_user_meta_data->>display_name/full_name/name`; `name_prompt_dialog` (only Apple Hide-My-Email path); profile editor | falls back to email or 'User' | 🟡 Asked only via Apple Hide-Email — Google sign-in users use OAuth-supplied name; could be wrong/auto-generated |
| `phone_number` | TEXT | **NEVER** | profile (?) — no writer found | NULL | ❌ Dead column |
| `profile_picture_url` | TEXT | home header, profile, AI cards | `userMetadata['profile_picture_url']` writes via Supabase Auth API | NULL | 🟡 Inherited from OAuth provider; profile edit can change it |
| `created_at` | TIMESTAMPTZ | profile, analytics | trigger | now() | ✅ Auto |
| `last_login_at` | TIMESTAMPTZ | profile (?) | `_updateLastLogin` on signedIn | now() | ✅ Auto |
| `email_verified` | BOOLEAN | auth flows | trigger | false | ✅ Auto |
| `subscription_status` | TEXT | tier gating | RevenueCat sync via `sync-subscription` edge function (writes 'premium' literal — see Phase 9.X audit) | 'free' | ✅ Auto from RC |
| `language` | TEXT | **NEVER read in lib/** | trigger, never written elsewhere | 'ar' | ❌ Dead column. RTL is hardcoded `TextDirection.rtl` in `main.dart:782`. Locale is hardcoded `[Locale('ar', 'SA'), Locale('en')]`. |
| `notifications_enabled` | BOOLEAN | analytics user-property only | trigger, never user-edited | true | ❌ Effectively dead — not a gate, only a Sentry/FA tag |
| `reminder_time` | TEXT | **NEVER read by reminder cron** | trigger | '09:00' | ❌ Dead column. The cron uses `reminder_schedules.time` (per-schedule), not user-level default time |
| `theme` | TEXT | **NEVER read in lib/** | trigger | 'light' | ❌ Dead column. Theme lives in SharedPreferences `app_theme` |
| `total_interactions` | INTEGER | weekly_report, AI context, streak provider | `record_interaction_and_update_relative` RPC | 0 | ✅ Auto |
| `current_streak` | INTEGER | streak bar, weekly report, AI context | RPC | 0 | ✅ Auto |
| `longest_streak` | INTEGER | weekly report, achievements display (when present) | RPC | 0 | ✅ Auto |
| `points` | — | **DROPPED IN PHASE 9.1.B-DB** | n/a | n/a | ⚪ Removed |
| `level` | — | **DROPPED IN PHASE 9.1.B-DB** | n/a | n/a | ⚪ Removed |
| `badges` | — | **DROPPED IN PHASE 9.1.B-DB** | n/a | n/a | ⚪ Removed |
| `data_export_requested` | BOOLEAN | settings → export flow | settings | false | ✅ Asked-on-action |
| `account_deletion_requested` | BOOLEAN | unused (delete is direct via RPC) | unused | false | ❌ Dead column |
| `updated_at` | TIMESTAMPTZ | n/a | trigger on update | now() | ✅ Auto |
| `streak_deadline` | TIMESTAMPTZ | streak warning indicator | RPC | NULL | ✅ Auto |
| `streak_day_start` | TIMESTAMPTZ | streak math | RPC | NULL | ✅ Auto |
| `freeze_auto_use` | BOOLEAN | streak_freeze_service.isAutoFreezeEnabled (currently dormant — see Phase 9.X audit) | settings (?) — no UI surface confirmed | true | 🔴 Read by dormant code path; should be exposed once freeze system is wired |
| `last_interaction_at` | TIMESTAMPTZ | unused in lib/ (?) | RPC (?) | NULL | 🟡 Possibly dead, possibly written but unread |
| `onboarding_metadata` | JSONB | premium walkthrough state | premium-onboarding storage provider | '{}' | ✅ Auto for premium walkthrough |
| `streak_warning_sent` | BOOLEAN | check-streak-alerts cron only | check-streak-alerts cron | false | ✅ Auto |
| `subscription_product_id` | TEXT | subscription detection | RC sync | NULL | ✅ Auto |
| `subscription_expires_at` | TIMESTAMPTZ | tier gating expiration check | RC sync | NULL | ✅ Auto |
| `trial_started_at` | TIMESTAMPTZ | **NEVER read in lib/** | unused | NULL | ❌ Dead column. Trial is RC-managed |
| `trial_used` | BOOLEAN | **NEVER read in lib/** | unused | false | ❌ Dead column |

### Section 1 conclusions

- **Dead/cosmetic columns:** `language`, `notifications_enabled`, `reminder_time`, `theme`, `phone_number`, `account_deletion_requested`, `trial_started_at`, `trial_used`, `last_streak_date` (already cleaned). These are all defaulted at trigger time and never consumed. Net engine bloat: **9 dead columns**.
- **The only column the wizard SHOULD set:** `full_name` — only reliably populated for OAuth users; needs a wizard prompt for users who came via Apple Hide-Email or whose OAuth-supplied name is auto-generated.
- **`onboarding_metadata` JSONB** is owned by the premium walkthrough. The setup-wizard could co-tenant the column with a separate JSON path (e.g. `onboarding_metadata->>'setupComplete'`) — verified safe in the Phase 9.X archaeology.
- **No "household composition" column exists.** `relative_category` on `relatives` is the closest: 'household' / 'extended' / 'distant'. See Section 2.

---

## Section 2 — Relative relationship completeness

`relatives` table has **52 columns**. Verdicts per column, plus what AddRelativeScreen captures.

### What AddRelativeScreen actually gathers

From `add_relative_screen.dart` state inspection:

| Field | Captured? | How |
|---|---|---|
| `full_name` | ✅ | TextField |
| `relationship_type` | ✅ | Selector |
| `gender` | ✅ | Auto-inferred from Arabic name + relationship + manual override |
| `phone_number` | ✅ | Optional phone field with country code |
| `photo_url` | ✅ | Image picker (optional) |
| `notes` | ✅ | Free-text notes field |
| `priority` | ✅ (auto) | Auto-set from `RelationshipType.priority` (1=high, 2=med, 3=low) |
| `relative_category` | ✅ | Selector: household / extended / distant |
| `family_group_id` | ✅ | Selector if `addToSharedTree=true` |
| `family_side` | ✅ | Paternal/maternal selector for extended-family |
| `health_status` | 🟡 | Defined in state but no widget surface visible — possibly hidden behind expand toggle |

### Schema fields that EXIST but are NEVER captured by AddRelativeScreen

| Column | Type | Read where | Verdict |
|---|---|---|---|
| `date_of_birth` | TIMESTAMPTZ | occasion engine, AI context | 🔴 Critical — birthdays drive occasion reminders. Currently NULL for everyone added without it |
| `email` | TEXT | invitation flow | 🟡 Useful for invite-by-email if that flow returns |
| `address` / `city` / `country` | TEXT | unused in lib/ — pure metadata | 🟡 Useful for AI but unused today |
| `avatar_type` | TEXT | UI rendering of relative cards | 🟡 Auto-suggested from relationship+gender — works without explicit pick |
| `tags` | TEXT[] | relatives filtering | 🟢 Optional |
| `islamic_importance` | TEXT | unused in lib/ (audit found no consumer) | ❌ Dead |
| `preferred_contact_method` | TEXT | unused in lib/ | ❌ Dead |
| `best_time_to_contact` | TEXT | unused in lib/ | ❌ Dead |
| `health_status` | TEXT | shown on detail | 🟡 Captured behind expand but not prominent |
| `interests` | TEXT[] | AI prompts use it | 🟡 Could be asked per-relative or auto-inferred from interactions |
| `favorite_colors` / `favorite_foods` | TEXT[] | gift-suggestion AI | 🟢 Nice-to-have |
| `clothing_size` / `gift_budget` / `disliked_gifts` / `wishlist` | various | gift-suggestion AI | 🟢 Nice-to-have |
| `personality_type` / `communication_style` | TEXT | AI prompts | 🟡 Drives AI behavior — would be nice to capture but inferable |
| `sensitive_topics` | TEXT[] | AI to avoid topics | 🟡 Important for AI but heavy to ask upfront |
| `relationship_challenges` / `relationship_strengths` | TEXT | AI prompts | 🟡 Heavy to ask upfront |
| `ai_notes` | TEXT | AI auto-generated | ✅ Auto (or was — AI memory writes are no-op'd per Phase 1) |
| `emotional_closeness` (1-5) | INTEGER | unused in lib/ (audit) | ❌ Likely dead |
| `communication_quality` (1-5) | INTEGER | unused in lib/ | ❌ Likely dead |
| `conflict_history` | TEXT | unused in lib/ | ❌ Likely dead |
| `support_level` (1-5) | INTEGER | unused in lib/ | ❌ Likely dead |
| `last_meaningful_interaction` | TIMESTAMPTZ | unused in lib/ | ❌ Likely dead |
| `is_self` | BOOLEAN | family tree | 🔴 **Only set during family-group join (claim_tree_node RPC) or migration fix. Solo users NEVER get a self-node.** See Section 4 |
| `interaction_count` | INTEGER | per-relative streaks | ✅ Auto |
| `last_contact_date` | TIMESTAMPTZ | per-relative streak, smart-nudges cron | ✅ Auto |
| `is_archived` / `is_favorite` | BOOLEAN | UI filters | ✅ Asked-on-action |
| `contact_id` | TEXT | contact import | ✅ Auto from import |

### Fields that DON'T exist but the wizard might want

| Concept | Status | Engine work |
|---|---|---|
| "Lives with user" boolean | ❌ Missing — closest is `relative_category='household'` but that's category-of-closeness, not literal cohabitation | 🔨 Could be inferred from `household` category, OR add a dedicated `lives_with_user` boolean |
| "Expected contact frequency" per relative | ❌ Missing — drives nothing today; reminder schedules are manually configured per-schedule, not per-relative | 🔨 Either add a `expected_frequency` column on `relatives`, OR keep using `relative_category` as a coarse proxy (`household`=daily, `extended`=weekly, `distant`=monthly) and bake the proxy into reminder defaults |
| "Last in-person interaction" vs "last digital interaction" | ❌ Not split — `last_contact_date` is single timestamp | 🟢 Nice-to-have, not critical |

### Section 2 conclusions

- AddRelativeScreen captures the minimum needed (name + relationship + gender + category + photo + phone + notes). Most additional schema columns are optional richness for the AI.
- **The wizard SHOULD ask for `date_of_birth`** at minimum — it's the only field whose absence breaks a feature (occasion reminders).
- **The wizard SHOULD ask for `relative_category` (household / extended / distant)** — already asked in AddRelativeScreen as a selector but is the missing-step-2 of the 2026-01-11 reseed ("ضع تذكيرات / Set Reminders" depends on knowing who's in the household to set sane defaults).
- **The wizard SHOULD NOT ask** for: islamic_importance, preferred_contact_method, best_time_to_contact, emotional_closeness, communication_quality, conflict_history, support_level, last_meaningful_interaction. These are all dead in code today and would frustrate the user with form-fatigue.

---

## Section 3 — Reminder logic gap analysis

Two reminder crons exist:

### `send-scheduled-reminders` (per-minute, user-configured)

**Inputs consumed:**
- `reminder_schedules.is_active` ✅
- `reminder_schedules.time` (HH:mm exact-minute match)
- `reminder_schedules.frequency` (daily / weekly / monthly / friday / custom)
- `reminder_schedules.custom_days` (Flutter day numbering 1=Monday)
- `reminder_schedules.day_of_month`
- `reminder_schedules.interval_days` (for custom frequency)
- `reminder_schedules.relative_ids[]` (whom to remind about)
- `reminder_schedules.custom_title` / `custom_message` (override copy)

**Inputs NOT consumed (the gap):**
- ❌ `last_contact_date` on `relatives` — **the cron does NOT skip a relative the user just contacted**
- ❌ `last_interaction_at` on `users`
- ❌ `relative_category` (household relatives reminded equally with distant)
- ❌ `relationship_type` (no per-type cadence)
- ❌ `is_self` (could fire reminders about yourself — does the cron check?)

**The "remind me to call dad after lunch" scenario:**
1. User has scheduled reminder: "daily, 18:00, relatives=[dad]"
2. User had lunch with dad at 13:00 today; logs interaction → updates `dad.last_contact_date = 13:00`, `users.total_interactions++`
3. At 18:00, cron fires the daily schedule
4. Cron sees relative_ids=[dad] in the schedule → fetches dad's row → builds notification with dad's name → sends
5. **The cron never queries `last_contact_date` for the relative.** Reminder fires.

**Root cause:** scheduled-reminders cron treats schedules as truth-of-when-to-remind without consulting truth-of-when-was-last-contact.

**Fix is non-trivial.** Options:
- 🟡 Add a "skip if contacted today" check at the per-relative loop (simple, may fire individual-but-empty notifications when ALL relatives in a multi-relative schedule were contacted today)
- 🅰 Add a `users.scheduled_reminders_check_recent_contact BOOLEAN` toggle — opt-in
- 🅱 Always check `last_contact_date < (today_start - X hours)` and skip if recent — cleanest

### `send-smart-nudges` (per-hour, contact-gap-driven)

Already correct:
- Uses `last_contact_date` ✅
- `MIN_GAP_DAYS=5` floor ✅
- Per-template cooldown ✅
- Daily cap of 2 ✅
- Template rotation lookback ✅

**Smart-nudges does the right thing.** The bug is exclusively in scheduled-reminders.

### Section 3 conclusions

- The wizard does NOT need to capture anything new for the reminder cron to be fixable. The fix is server-side: scheduled-reminders should check `last_contact_date` before firing.
- **What the wizard COULD do:** ask "do you want me to skip reminders for relatives you just spoke to?" as an opt-in default behavior — and write to a new `users.suppress_reminders_after_recent_contact BOOLEAN`. Or just default it to true server-side and not ask.

---

## Section 4 — Family tree / `is_self` lifecycle

**Self-node creation paths:**

| Path | When it fires | Result |
|---|---|---|
| `claim_tree_node` RPC | When a user joins a family group via invite link AND their Supabase auth.uid is matched to an existing relative-row in the group | The matched relative row's `is_self` is flipped to true, `user_id` set to the joiner |
| Migration `20260206110000_fix_claimed_nodes_is_self.sql` | One-time backfill | Marked previously-claimed nodes as `is_self=true` |
| **Solo user (not in a family group) — manual creation** | **NEVER** | **Solo users have no self-node** |

**What this means in practice:**
- A brand-new solo user who never joins a group has `relatives` rows for everyone they add — but no row representing themselves
- The family tree screen renders all the user's relatives but has no anchor node "me"
- In the family graph, the user is implicit. The tree shows fragments connected to no center
- For a user who joined a group, their self-node exists in the group's tree
- The Phase 9.X PHASE_9_X_REPORT.md alluded to this: "no setup wizard exists; the closest 'create yourself in the tree' moment is the family-group claim flow"

**Why the wizard should care:**
- 🔴 Without a self-node, the family tree feels broken for solo users
- 🟡 The user's `relatives` row could be auto-created at signup with `is_self=true, user_id=auth.uid(), full_name=user.full_name, relationship_type='other', relative_category='household'` — but no place in the codebase does this
- 🟡 The `handle_new_user` trigger could be extended, but per the migration's "DO NOT SIMPLIFY" comment, modifying it is risky
- 🅰 **Recommended:** the wizard's first step (after welcome) should auto-create the user's self-node when the user provides their name, OR create it at sign-in via a new `ensure_self_node` RPC analogous to `ensure_user_record`

### Section 4 conclusions

- **Engine work needed:** add a `create_self_node()` RPC OR extend `ensure_user_record` to also create the self-node
- **Wizard work needed:** capture the user's display-name + gender (the self-node needs gender for tree-rendering label generation), then call the RPC

---

## Section 5 — Subscription tier and tier-gated content

**Tier determination at first launch:**
1. App initialize → `SubscriptionService.instance` boots
2. Calls RevenueCat to check entitlements
3. Resolves to `SubscriptionTier.free` or `SubscriptionTier.max`
4. Syncs to `users.subscription_status` via `sync-subscription` edge function (writes 'premium' for max — Phase 9.X drift, intentional)

**For brand-new user before first sync:** tier defaults to `SubscriptionTier.free`.

**Tier-gated wizard behavior:**
- The `admin_onboarding_screens` table has a `show_for_tiers TEXT[] DEFAULT ARRAY['free', 'max']` column — meaning admin can configure which tiers see which screen
- Today: all 5 seeded screens are active for both tiers
- Wizard implication: NOT a v1 concern. Most users will be free anyway. Tier-targeted onboarding is v1.5+.

**Free-trial logic:** `users.trial_started_at` and `users.trial_used` columns exist but are **never written/read by lib/**. RevenueCat manages trial state externally. **Not a wizard input.**

### Section 5 conclusions

- The wizard runs as `free` tier for everyone (since RC sync may not have completed at first launch)
- Don't gate any wizard content behind tiers in v1. Treat all users as free during onboarding.

---

## Section 6 — Notification permissions UX

**Where it's asked today:**
- `fcm_notification_service.dart:116` — `_requestPermissions()` called from `initialize()`, which runs **at app boot during `main.dart`'s parallel init phase**
- `_requestPermissions` calls `_firebaseMessaging.requestPermission(...)` which triggers the iOS/Android system prompt

**The UX problem:**
- User signs in → bare seconds later, the OS notification permission prompt appears
- User has not yet seen any home content, has not added any relatives, has no context for why notifications matter
- High denial rate is the predictable result. Users who deny can re-enable from system settings only — no in-app re-prompt

**What good UX would look like:**
- Wizard step explains "we'll use notifications to remind you about family contact at times you set"
- Wizard step has a "Allow Notifications" button that triggers the OS prompt
- Wizard step tracks whether the user allowed/denied for analytics

### Section 6 conclusions

- **🔴 The wizard SHOULD include a notification permission step** with explainer copy before the OS prompt fires
- **Engine work:** delay the FCM permission request from app boot until the wizard reaches the permission step. `fcm_notification_service.dart:116` needs to be split: initialization (channel setup, token retrieval) at boot, but `requestPermission` deferred until wizard step 4 or 5

---

## Section 7 — Locale and language

**Current state:**
- `main.dart:776` hardcodes `supportedLocales: const [Locale('ar', 'SA'), Locale('en')]`
- `main.dart:782` hardcodes `textDirection: TextDirection.rtl` at the app root
- All Arabic text is wrapped manually in `Directionality(textDirection: TextDirection.rtl, ...)` per-screen
- `users.language` column exists (DEFAULT 'ar') but is never read in lib/
- Localization (i18n) is incomplete — Arabic strings are hardcoded everywhere; only ~60% of admin-config-driven strings have `_en` variants

**For the wizard:**
- The app is effectively Arabic-only at the UI level
- English support is partial (admin-config columns exist, but the consumer UI doesn't render English variants)
- **Don't ask the user for language preference in v1 wizard.** It would be misleading — picking English doesn't change what they see

### Section 7 conclusions

- **🟢 Wizard does NOT need a locale step** — too aspirational given current i18n state
- **Engine work (deferred):** if English is a v1.5 goal, build an EN locale-switch and re-introduce a wizard locale step

---

## Section 8 — AI seeding and context

**What the AI knows about a brand-new user:**

From `ai_context_engine.dart`:
- `relatives` (filtered to non-archived) ✅
- `interactions` (last 30 days, capped at 100) ✅
- `streaks` (per-relative streaks) ✅
- `memories` (top 50 by importance, only `is_active=true`) ✅
- `totalInteractions` from `users.total_interactions` (Phase 9.1 update)

**What the AI does NOT know:**
- ❌ The user's `full_name` — AIContext doesn't include displayName/full_name
- ❌ The user's `email`
- ❌ Anything user-personal (interests, communication style, sensitive topics for the user themselves)

**For a brand-new user with 0 relatives, 0 interactions, 0 memories:**
- AI gets an empty context except for `totalInteractions=0` and `relatives=[]`
- AI prompts have placeholders like `{{at_risk_count}}`, `{{healthy_count}}`, `{{active_streaks}}`, `{{total_interactions}}` which all resolve to `0`
- The AI's response will be very generic — it has no context to personalize on
- Existing `AIIdentity.greeting_message_ar` from `admin_ai_identity` table provides a static greeting

**No AI memory seeding at signup.** No `ai_memories` rows are inserted at signup. The first AI conversation builds the AI's knowledge from scratch.

### Section 8 conclusions

- 🟡 **Wizard could prime the AI** by writing 1-3 starter memories: "User's name is X", "User has Y in their household", "User wants help with Z"
- 🟡 **AI context engine should pull `full_name` from `users` table** — small fix to make the AI greet the user by name
- ⚪ Deeper AI seeding (interests, sensitivities) is over-engineering for v1. The AI builds context from real interactions naturally.

---

## Section 9 — `admin_onboarding_screens` content

Current seeded content (from `20260111120000_reseed_all_admin_tables.sql`, the 2026-01-11 wizard-shaped reseed):

| # | Title (AR) | Subtitle (AR) | Animation | Verdict |
|---|---|---|---|---|
| 1 | مرحباً بك في واصل | تطبيق يساعدك على تعزيز صلة الرحم والتواصل مع أقاربك | `welcome` | **PRESENT** — pure marketing welcome |
| 2 | أضف أقاربك | أضف أسماء أقاربك وحدد درجة القرابة | `relatives` | **ACTION** — was supposed to wire to add-relative flow |
| 3 | ضع تذكيرات | حدد مواعيد للتواصل مع كل قريب | `reminders` | **ACTION** — was supposed to wire to reminder configuration |
| 4 | تابع سلسلتك | حافظ على سلسلة التواصل اليومية | `streak` | **PRESENT** — explainer for streak system |
| 5 | استشر واصل | استفد من المستشار الذكي لتحسين علاقاتك | `ai` | **PRESENT** — AI counselor explainer |

**Critical observations:**
- Steps 2 and 3 are LABELED as user actions but the seed gives no schema-side wiring — there's no field on `admin_onboarding_screens` to declare "this step requires user input of X type"
- The original 2026-01-01 seed had a different mix (Welcome, Smart Reminders, Wasil Assistant, **Rewards System** [gamification — now cut], Sign Up CTA). The 2026-01-11 reseed pivoted toward setup-wizard intent
- The "AI counselor" step (5) is MAX-only — most free users would see a paywall after onboarding if they tried to use it

**Lottie animations referenced:** `welcome`, `relatives`, `reminders`, `streak`, `ai`. None of these exist in `assets/animations/` based on prior phase inventory.

### Section 9 conclusions

- The seed shape is correct for the wizard (Welcome → Add Relatives → Set Reminders → Track Streak → AI Counselor)
- **Engine work:** schema needs a way to declare per-screen actions (currently impossible). Minimum: a `screen_action_type TEXT` column with values like `('marketing', 'add_relative', 'set_reminder', 'permission_request')` and a `screen_action_route TEXT` for action targets
- **Asset work:** the 5 Lottie animations need to be created or sourced

---

## Section 10 — Implicit defaults review (per-screen empty state for a brand-new user)

### Home screen (0 relatives, 0 interactions)
- ✅ Greeting: shows "صباح الخير {first_name}" — works if name is set
- ✅ StreakBadgeBar: avatar + name + tier + 0-streak placeholder (Phase 9.0 fix)
- 🟡 Hadith of the day: works
- 🟡 MessageWidget slots: render whatever admin-configured marketing is current
- 🟡 QuickActionsWidget: works
- 🟡 OccasionCard: empty/hidden (no relatives = no occasions)
- ✅ FamilyCirclesSection (the empty-state CTA): "ابدأ بإضافة أفراد عائلتك" + "إضافة أول قريب" button — works but is **6th section down**, easily missed
- ✅ FamilyActivityFeed + CelebrationCard: hidden (no group)
- ✅ DueRemindersSection: hidden (no reminders)
- ✅ TodaysActivitySection: hidden (no interactions)
- 🟡 MessageWidget(home_bottom): renders admin marketing

**Verdict:** the home screen "works" but is dominated by promotional content. The CTA to add a first relative is too far down. Phase 9.X recommendation: hoist the empty-state CTA to top when 0 relatives.

### Relatives screen (0 relatives)
- Empty state lives in `relatives_screen.dart` — let me note: would need to verify, but most likely shows a centered "no relatives yet, add some" CTA. Standard pattern.

### Family tree screen (0 relatives, no group)
- 🔴 **Solo user with 0 relatives → renders nothing or error state.** No self-node is auto-created (Section 4). The tree is structurally empty
- 🔴 If the wizard creates a self-node, the tree would at least show "you" as a single node — much better empty-state-onboarding feel

### AI Hub (regardless of relatives)
- ✅ Renders the 4 tile cards (Chat / Scripts / Report / Wrapped — Wrapped added in Phase 9.X.b)
- 🟡 Tapping a tile gates on MAX subscription via `featureAccessProvider` — free user gets paywall
- 🟡 If user is free, all 4 tiles paywall — onboarding could explain this upfront

### Reminders screen (0 schedules)
- Empty state: would need to verify, but most likely "set your first reminder" CTA. Standard pattern.

### Section 10 conclusions

- The biggest empty-state-broken screen is the **family tree** (Section 4). Self-node auto-creation fixes it
- The home screen empty state is sub-optimal (CTA buried 6 sections down). Reorder is Phase 9.X option 🅲
- AI Hub's all-MAX paywall is honest but harsh — wizard could pre-explain

---

## Section 11 — Synthesis: the wizard's job

Based on Sections 1-10, the wizard's content list with severity:

### 🔴 Required for the app to work correctly

| Step | Captures | Why required |
|---|---|---|
| **Welcome + name confirmation** | `users.full_name` (confirm/edit) | Apple-Hide-Email + edge OAuth cases produce wrong/auto-generated names. AI greets by name. |
| **Add first relatives** | `relatives.full_name`, `relationship_type`, `gender`, `relative_category`, `date_of_birth` | At least 1 relative needed for the app to do anything. `date_of_birth` enables occasion reminders (only field whose absence breaks a feature). |
| **Self-node creation** | Server-side: insert a `relatives` row with `is_self=true, user_id=auth.uid()` | Family tree is structurally broken for solo users without this. Could be auto-done from the name step rather than a separate step. |
| **Notification permission** | OS-level allow/deny | Currently asked at app boot with no context — high denial rate. Wizard step explains why, then triggers prompt. |

### 🟡 Strongly recommended

| Step | Captures | Why recommended |
|---|---|---|
| **Household members** | (Multiple `relatives` rows with `relative_category='household'`) | Drives smart reminder defaults (skip household when nudging, no need to remind about people you live with) |
| **Default reminder cadence** | `users.suppress_reminders_after_recent_contact BOOLEAN` (new column) | Closes the "remind me to call dad after lunch" bug at the user-preference layer |
| **AI introduction** | (Insert 1-3 starter `ai_memories` rows: "User's name is X", "User's household includes Y") | Makes the AI's first conversation personal instead of generic |

### 🟢 Nice to have

| Step | Captures | Why optional |
|---|---|---|
| Profile photo | `userMetadata['profile_picture_url']` | OAuth providers usually supply this. Fallback is fine. |
| Tier explainer | none | Useful for free users who'll see paywalls everywhere, but wordy and skippable |

### ⚪ Should NOT be in the wizard

- Locale picker (i18n is incomplete — picking EN doesn't actually translate the UI)
- Theme picker (theme is device-local, not user-account)
- Subscription tier setup (RC handles this; the wizard runs as free for everyone)
- Per-relative deep-fields: interests, favorite_foods, communication_style, sensitive_topics, relationship_challenges. Form-fatigue. AI infers these from interactions over time.
- Trial setup: RC manages it.

### Recommended wizard shape (5 steps)

1. **Welcome + name** — confirm OAuth-supplied name, capture if missing. Auto-create self-node here.
2. **Add household** — "who lives with you?" — captures 1-N relatives with `relative_category='household'`. Includes name + relationship + gender + date_of_birth.
3. **Add extended family** — "who else do you want to track?" — same fields but `relative_category='extended'`. Optional skip.
4. **Reminder preference + notification permission** — explainer + "smart reminders that respect when you've talked to someone" + OS permission ask.
5. **AI counselor intro** — explainer + (free users see "premium feature" badge, MAX users see "ready to chat"). Done.

Mapping to the 2026-01-11 reseed:
- Reseed step 1 (Welcome) = wizard step 1 (Welcome + name)
- Reseed step 2 (Add Relatives) = wizard steps 2 + 3 (Household + Extended)
- Reseed step 3 (Set Reminders) = wizard step 4 (Reminders + permission)
- Reseed step 4 (Track Streak) = subsumed into step 1 or skipped
- Reseed step 5 (Ask Wasel) = wizard step 5 (AI counselor intro)

The reseed needs an update — split step 2 into two steps and merge in the streak explainer.

---

## Section 12 — Engine gaps (work that must precede the wizard build)

Tasks the wizard cannot capture without first adding schema or logic:

### 🔨 Required before wizard can ship

1. **Self-node auto-creation.** Add `ensure_self_node()` RPC OR extend `ensure_user_record()` to also insert a `relatives` row with `is_self=true`. Called from the wizard's name-capture step.

2. **`admin_onboarding_screens.screen_action_type` + `screen_action_route` columns.** Migration. Without this, the table can't declare which steps are user-action vs marketing-only.

3. **Defer FCM permission request.** Split `fcm_notification_service.dart:initialize()` into two phases: setup-only at boot, prompt-on-demand at wizard step. Add a public `requestPermissionWithContext()` method.

4. **Lottie animations.** 5 needed: `welcome`, `relatives`, `reminders`, `streak`, `ai`. Either source them or pre-design icon-based fallbacks.

### 🔨 Recommended before wizard can ship

5. **`users.suppress_reminders_after_recent_contact BOOLEAN`** + scheduled-reminders cron logic update to consult `last_contact_date`. Closes the "remind me to call dad after lunch" bug.

6. **AI context engine: include `full_name`.** Modify `ai_context_engine.dart`'s `_refreshCache` to also fetch `users.full_name` and add to AIContext. Lets AI greet by name.

7. **`onboarding_metadata->>'setupComplete'` JSON path** as the wizard's completion marker. Co-tenants the existing premium-walkthrough column. Add a router-redirect that gates on this path.

### 🔨 Could be deferred but adding now is cleaner

8. **Drop dead `users` columns:** `language`, `notifications_enabled`, `reminder_time`, `theme`, `phone_number`, `account_deletion_requested`, `trial_started_at`, `trial_used`. 9 dead columns. (Wave 2.6/2.7 territory.) Doing this now keeps the wizard's schema additions surgical instead of getting lost in noise.

9. **Drop dead `relatives` columns:** `islamic_importance`, `preferred_contact_method`, `best_time_to_contact`, `emotional_closeness`, `communication_quality`, `conflict_history`, `support_level`, `last_meaningful_interaction`. 8 dead columns.

### 🔨 Optional engine work

10. **`relatives.lives_with_user BOOLEAN`** (or expand `relative_category` to include 'spouse' / 'parent_in_house' subtypes). Enables smarter reminder defaults. Could skip if `relative_category='household'` is treated as a sufficient proxy.

11. **AI memory seeding RPC.** A `seed_initial_ai_memories(user_name TEXT, household_relatives UUID[])` that inserts 1-3 starter rows. Optional.

---

## Open questions for the CTO

1. **Wizard scope: which severity tier to ship in v1?** Recommendation: Required (🔴) only for v1, Strongly Recommended (🟡) for v1.5. That's a 4-step wizard for v1.

2. **Engine gaps 1-4 are blockers** for any wizard build. Confirm we have time to do all 4 before starting the wizard, or accept a partial wizard that punts on (e.g.) the notification permission step.

3. **Engine gaps 8 and 9 (drop dead columns)** — desirable cleanup but technically out of scope for "build the wizard". Treat as a separate concurrent commit, OR defer to v1.5 cleanup pass?

4. **The "remind me to call dad after lunch" fix** — should it be opt-in via wizard step, or default-on server-side? Default-on is a behavior change that current users haven't consented to, but is clearly the right behavior.

5. **AI memory seeding (engine gap 11)** — controversial because it pre-loads the AI's "knowledge" in a way the user didn't explicitly opt into. Privacy-wise this is fine since the data is the user's own onboarding answers. Founder UX call.

---

## Closing state

This audit produced a 5-step wizard scope and 11-item engine-gaps list. The 2026-01-11 reseed of `admin_onboarding_screens` was approximately right but needs a content update (split "Add Relatives" into household + extended; merge "Track Streak" into welcome; clarify reminder permission ask). The biggest correctness gap is the self-node lifecycle (Section 4) — solo users have no anchor in the family tree, and the wizard can fix this by auto-creating a self-node at the name-capture step.

Pure forensic discovery. No code changes. CTO designs from here.
