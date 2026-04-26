---
name: Database Wave 2 + Wave 2.5 — HALTED at Task 1 lib/-reference gate
description: Re-verification of orphan-table references caught 4 tables that are actively read from lib/. Halted before any drop migration was written. Tasks 2–5 prerequisites verified clean and ready to ship once Task 1 direction is confirmed.
type: project
---

# DATABASE WAVE 2 + WAVE 2.5 — HALTED at Task 1 lib/-reference gate

**Date:** 2026-04-26
**Status:** HALTED before any destructive migration was written.
**Gate that caught it:** the standing order — *"Before dropping each: re-verify zero `lib/` references via grep."* The Wave 2 reconnaissance asserted zero references for the entire drop list; re-grepping found four tables with active reads.
**This file supersedes the prior `DATABASE_WAVE_2_REPORT.md`** (which documented the earlier reconnaissance halt at the ghost-tables gate).

## Executive summary

- **Pre-task `hadith`:** halted as a drop candidate. 3 of 8 rows contain unique content not present in `admin_hadith` (different schemas, different hadith collections — Bukhari 6138, Musnad Ahmad 7563, Musnad Ahmad 16033). Excluded from any drop until founder decides on migration path.
- **Pre-task subscription_status:** 22 'free' / 5 'premium' / 0 'pro' / 0 'max'. Task 3's UPDATE will affect 5 rows.
- **Task 1 drop list re-verification:** failed for 4 of the 18 tables. `ai_memories` (5 refs — actively used by chat features and was JUST captured in 20260427200000_capture_chat_tables.sql, so its inclusion in this drop list is a wave-plan error), and three admin_* tables read by live services with silent-fail try/catch + hardcoded fallbacks (`admin_challenges`, `admin_memory_categories`, `admin_ai_memory_config`).
- **Tasks 2–5:** prerequisites all verified clean. Migrations not written because the standing order is to halt and report; founder may greenlight 2–5 separately.

## Pre-task 1 — `hadith` content verification

**Result: 3 of 8 rows in `hadith` are unique content not present in `admin_hadith`. Excluded from any drop list.**

The two tables have entirely different schemas:
- `hadith`: `arabic_text`, `english_translation`, `source`, `reference`, `topic`, `type`, `narrator`, `scholar`, `is_authentic`, `display_order` — bilingual, with English translations.
- `admin_hadith`: `hadith_text` (Arabic only), `source`, `narrator`, `grade`, `category`, `tags[]`, `is_active`, `display_priority` — Arabic-only with admin-curated tags.

Direct row-by-row comparison (by reference / source):

| `hadith` row (reference) | Present in `admin_hadith`? |
|---|---|
| Bukhari 5986 (provision/lifespan) | ✓ |
| Bukhari 5988 (womb suspended from Throne) | ✓ |
| Bukhari 5991 (not the one who reciprocates) | ✓ |
| **Bukhari 6138 (believer in Allah and Last Day)** | ✗ unique |
| **Musnad Ahmad 7563 (love among relatives, wealth, lifespan)** | ✗ unique (admin_hadith has a different Ahmad hadith, not 7563) |
| At-Tirmidhi 1979 (learn lineage to maintain ties) | ✓ |
| **Musnad Ahmad 16033 (quickest act of obedience)** | ✗ unique |
| Bukhari 5984 (severs ties → no Paradise) | ✓ |

Per standing order, `hadith` is **excluded from Task 1's drop list**. Founder decides:

- **Option H1** — migrate the 3 unique rows into `admin_hadith` (manual SQL — schemas don't auto-translate; need to map `arabic_text` ← `hadith` field, drop English, infer `tags`, set `display_priority`). Then drop `hadith`.
- **Option H2** — keep `hadith` table indefinitely as a bilingual content store; no admin uses it but the rows aren't lost. Add it to migration history as a "captured but unused" table (Wave 1.5-style).
- **Option H3** — drop `hadith` accepting the loss of the 3 unique rows + the English translations. (Not recommending, but it's a valid decision if the rows aren't worth the migration work.)

## Pre-task 2 — `subscription_status` row check

**Current CHECK (verified via `pg_get_constraintdef`):**
```sql
CHECK (subscription_status = ANY (ARRAY['free'::text, 'premium'::text, 'pro'::text]))
```

**Row counts:**

| status | count |
|---|---|
| free | 22 |
| premium | 5 |
| (pro) | 0 |
| (max) | 0 |

Task 3's `UPDATE users SET subscription_status = 'max' WHERE subscription_status NOT IN ('free', 'max')` will affect exactly 5 rows.

## Task 1 — HALTED. Drop-list re-verification failures

Re-grepped `lib/` with `grep -rEnI --include='*.dart' "from\\(['\"]<table>['\"]\\)" lib/` for every table on the drop list. Wave 2's reconnaissance asserted zero refs everywhere; re-verification disagreed for **4 tables**:

| Table | refs | Where | Risk |
|---|---|---|---|
| `ai_memories` | **5** | `lib/core/ai/ai_context_engine.dart:158`, `lib/shared/services/chat_history_service.dart:222,243,264,280` | **CRITICAL** — actively used by chat features. Also captured in [20260427200000_capture_chat_tables.sql](supabase/migrations/20260427200000_capture_chat_tables.sql). Dropping it would obliterate the Wave 1 closing migration just shipped on `d0a65c2`. **Wave-plan error: remove from drop list.** |
| `admin_challenges` | 1 | `lib/core/services/gamification_config_service.dart:329` | Read inside try/catch + silent fail. `ChallengeConfig.fallbackChallenges()` exists. App degrades gracefully if dropped. |
| `admin_memory_categories` | 1 | `lib/core/services/ai_config_service.dart:292` | Read inside try/catch + silent fail. `AIMemoryCategoryConfig.fallbackCategories()` exists. App degrades gracefully if dropped. |
| `admin_ai_memory_config` | 1 | `lib/core/services/ai_config_service.dart:274` | Read inside try/catch + silent fail. `AIMemorySystemConfig.fallback()` exists. App degrades gracefully if dropped. |

The other 14 entries on the drop list (7 social_*, `challenge_streaks`, `daily_challenges`, `gifts`, `wisdom_entries`, `occasions`, `fcm_tokens`, plus `hadith` excluded above) re-verified at zero references. Those are still safe to drop.

### Why `ai_memories` is on this list at all (analysis)

The Wave 2 reconnaissance and the original Wave 2 plan were drafted before Wave 1 closing landed. `ai_memories` was treated as "ghost / unused" in the recon. But Wave 1 Task 1 followup (chat-tables capture) explicitly captured it with full schema, FKs, indexes, RLS, and 4 owner-only policies. It is now a load-bearing table for the chat feature.

Conclusion: the wave plan's drop-list inclusion of `ai_memories` is stale relative to what shipped. Wave 1 closing made it canonical. Drop list error.

### Why the admin_* tables show "1 ref" each (analysis)

The Wave 2 reconnaissance grepped for the table name; the services use the literal string inside `.from('admin_challenges')`. The recon's pattern likely missed `.from()` calls or the file was excluded by some other filter. Either way, the references are real. All three are read inside try/catch with silent failure and hardcoded `fallback*()` static methods, so the app will not crash if the tables disappear — but the dead read sites remain.

### CTO decision needed for Task 1

Three coupled decisions:

**Decision T1A — `ai_memories`**
- **Recommend: REMOVE from drop list.** It's part of the chat-tables migration shipped in `d0a65c2`. Dropping it would break chat features.

**Decision T1B — admin_* tables (`admin_challenges`, `admin_memory_categories`, `admin_ai_memory_config`)**
- **Option B1** — drop the tables AND keep the dead Dart fetch code (silent-fail forever). App works, log noise on every startup. Not recommended.
- **Option B2** — drop the tables AND remove the Dart fetch + getters that read them. Force fallbacks to be the only path. Cleaner but expands wave scope into Dart code.
- **Option B3** — keep the tables. Some still have data (admin_memory_categories has 5 rows, admin_ai_memory_config has 1) — they may be re-populated when an admin panel ships. Move them out of the drop list and into Wave 1.5-style "captured but tolerated."

**Decision T1C — `hadith`**
- See Pre-task 1 above (H1 / H2 / H3).

## Tasks 2 — 5: prerequisites verified, migrations NOT written

Per standing order, halting. These tasks are independent of Task 1 and ready to ship as soon as the founder greenlights direction.

### Task 2 — drop debug RPCs

| RPC | lib/ refs |
|---|---|
| `debug_admin_stats` | 0 |
| `debug_with_gamification_test` | 0 |
| `debug_subscription_status` | 0 |
| `debug_add_interactions` | 0 |

Clean. Migration is one-shot `DROP FUNCTION IF EXISTS … CASCADE` × 4 + self-verification that they're gone.

### Task 3 — fix `users_subscription_status_check`

Current CHECK: `('free', 'premium', 'pro')`. Affected rows: 5 'premium', 0 'pro'.
Migration order is fixed: UPDATE → DROP CONSTRAINT → ADD CONSTRAINT → self-verify via `pg_get_constraintdef`.

### Task 4 — add unique constraints

| Check | Duplicates |
|---|---|
| `family_group_members(group_id, user_id)` | 0 |
| `node_invitations(group_id, relative_id) WHERE status='pending'` | 0 |

Both clean. Both constraints can be added directly. The pending-only one is a partial unique index.

### Task 5 — flip 4 historical FKs to ON DELETE CASCADE

All 4 FKs exist on prod with **no `ON DELETE` clause** (default `NO ACTION`). All reference `auth.users(id)`:

```
family_group_members.user_id      → auth.users(id)
family_groups.created_by          → auth.users(id)
node_invitations.accepted_by      → auth.users(id)
node_invitations.invited_by       → auth.users(id)
```

Flip pattern: DROP CONSTRAINT, ADD CONSTRAINT … ON DELETE CASCADE, self-verify via `pg_get_constraintdef`.

## What I did NOT do

- Wrote no .sql migration files.
- Touched no Dart code.
- Made no MCP writes (it's read-only by mandate).
- Did not run `flutter analyze`, `flutter test`, or the FK-on-delete lint script — there's nothing to validate yet.

## Open asks for the CTO

1. **Decision T1A** — confirm `ai_memories` is removed from Task 1's drop list (recommend yes).
2. **Decision T1B** — pick B1, B2, or B3 for the three admin_* tables.
3. **Decision T1C** — pick H1, H2, or H3 for `hadith`.
4. **Greenlight Tasks 2–5 independently?** All 4 prereqs are clean. They can ship as 4 separate migrations + 4 separate self-verify blocks regardless of how Task 1 resolves. Confirm OK to write and apply them in this session, or wait.

## Wave 2.6 still tracked

Per the original plan: after Wave 2.5 ships and is verified, the procedural teardown loop in `delete_user_account` becomes redundant. That cleanup is Wave 2.6 — separate commit, separate session if needed. Logging it here so it doesn't fall off the radar.

## Wave 3 / Wave 2.7 still post-TestFlight

- **Wave 3** — FK-target unification (the `auth.users` vs `public.users` mixed-target issue from the audit's H2). Post-TestFlight.
- **Wave 2.7** — RLS policy dedup (the `users` table has 12 policies, the others have several duplicates per Wave 1.5 recon). Post-TestFlight.
