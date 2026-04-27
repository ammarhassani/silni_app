---
name: Phase 6.1 — Content audit decisions 1–3 applied; Task 4 halted
description: Brand normalized to صِلْني, AI persona renamed to أنيس, terminology sweep applied to mismatched fallback push titles. Task 4 (hadith metadata) halted at the founder-data gate — narrator placeholders unfilled in the prompt.
type: project
---

# PHASE 6.1 — Content Audit Fixes (decisions 1–3)

**Date:** 2026-04-27
**Status:** Tasks 1, 2, 3 ✅ shipped. Task 4 🟡 **HALTED** at the founder-data gate (the `[FOUNDER FILLS]` narrator placeholders in the prompt were not filled in).
**Commit:** `<this commit>`.

---

## Halt note (Task 4)

The Phase 6.1 prompt's hadith block (Task 4 step 5) preserves the literal placeholders:

```
Bukhari 6138:
  Narrator: [FOUNDER FILLS]
  Grade: [FOUNDER FILLS — likely صحيح]
  ...
```

Without the founder's research data for the three narrators, Task 4 cannot proceed. Halting per CTO standing order #1 ("Halt at every gate").

**Note: grades are already filled in prod** — MCP confirms the 3 Wave 2 rows have `حسن`/`حسن`/`صحيح` from the original Wave 2 migration. Only the **3 narrators** are missing. When the founder supplies the narrators, the migration is mechanical:

```sql
UPDATE admin_hadith
  SET narrator = '<founder data>',
      source = 'صحيح البخاري ٦١٣٨'
  WHERE source = 'Sahih Al-Bukhari 6138';
-- (and 2 more analogous statements for the Ahmad rows)
```

Pre-written migration scaffold: `supabase/migrations/20260428200000_hadith_metadata_fill.sql.TEMPLATE` — **NOT created in this session** to avoid landing a stub. Will be written and applied in the next session once the narrators arrive.

---

## Task 1 — Brand normalization to `صِلْني` ✅

### lib/ replacements

24 distinct files, ~36 string occurrences. Two-pass `sed`:

- Pass 1: `صِلني` (kasra-only) → `صِلْني` — 15 files, ~19 occurrences.
- Pass 2: `صلني` (no diacritic) → `صِلْني` — 9 files, ~17 occurrences.

Verification: `grep -rln "صِلني\|صلني" lib/` → 0 matches. `grep -rln "صِلْني" lib/` → 23 files.

### Launch artifacts

- [CLAUDE.md](CLAUDE.md), [LAUNCH_DESCRIPTION.md](LAUNCH_DESCRIPTION.md), [LAUNCH_DEMO_SCRIPT.md](LAUNCH_DEMO_SCRIPT.md), [silni_financial_projections.md](silni_financial_projections.md) — all normalized.

### Prod migration

[supabase/migrations/20260428000000_brand_normalization.sql](supabase/migrations/20260428000000_brand_normalization.sql)

MCP introspection found exactly one prod row with the bare `صلني` form:
- `admin_in_app_messages` row `cf02f758-398e-40c3-ad94-05936a85ed94` — the founder's launch greeting, mentioned `تطبيق صلني` twice.

Migration: defensive `REPLACE(body_ar, 'صلني', 'صِلْني')` with `WHERE id = '...'` (single-row scope), idempotent on re-run, self-verifies that the bare form is gone and the canonical form is present.

**Applied to prod.** MCP post-apply check returns `has_canonical=true, has_bare_only=false`. ✅

### Migration files / append-only

`supabase/migrations/*.sql` files containing the old brand spellings (~6 historical migrations) were **NOT** modified — append-only discipline. Those files write to admin tables that are now corrected by the new migration above. No need to touch the historical record.

### BRAND.md

[BRAND.md](BRAND.md) created in repo root with the canonical brand form, the AI persona name, and the explicit decision dates.

---

## Task 2 — AI persona `واصل` → `أنيس` ✅

### Disambiguation

`grep -rln "واصل" lib/` returned 65 files. Almost all were substring matches inside `تواصل` ("communication") or `الواصل` (gamification noun). Re-greped with word-boundary regex (`grep -rEn "(^|[[:space:]\"'(),.…])واصل([[:space:]\"'(),.…]|$)"`) which narrowed to **28 standalone hits** in code.

Of those 28:
- **11 sites** are AI-persona usages (renamed to `أنيس`).
- **7 sites** are gamification (`واصل متمكن`, `واصل محترف`, level 10 title, wrapped persona "واصل العائلة"). **Kept** per Decision 2.

### AI-persona sites updated

| File:line | Surface | Change |
|---|---|---|
| [ai_identity.dart:18](lib/core/ai/ai_identity.dart#L18) | `defaultName = 'واصل'` | → `'أنيس'` |
| [ai_identity.dart:33](lib/core/ai/ai_identity.dart#L33) | greeting `أنا واصل، مساعدك الشخصي` | → `أنا أنيس، مساعدك الشخصي` |
| [ai_identity.dart:98](lib/core/ai/ai_identity.dart#L98) | system prompt `أنت "واصل"` | → `أنت "أنيس"` |
| [ai_identity.dart:10, 40](lib/core/ai/ai_identity.dart) | dartdoc references | updated |
| [ai_models.dart:28](lib/core/ai/ai_models.dart#L28) | `assistant('assistant', 'واصل')` | → `'أنيس'` |
| [ai_prompts.dart:34, 36](lib/core/ai/ai_prompts.dart) | dartdoc + system prompt `أنت "واصل"` | updated |
| [ai_config_service.dart:354, 402, 415, 419, 455](lib/core/services/ai_config_service.dart) | system prompt + 2 fallback `aiName` + greeting + content | all updated |
| [deepseek_ai_service.dart:735, 760](lib/core/ai/deepseek_ai_service.dart) | mock-mode greetings `أنا واصل، مساعدك` | → `أنا أنيس، مساعدك` |
| [islamic_calendar_service.dart:45](lib/core/services/islamic_calendar_service.dart#L45) | Eid nudge `واصل يقدر يكتب` | → `أنيس يقدر يكتب` |
| [paywall_screen.dart:206](lib/features/subscription/screens/paywall_screen.dart#L206) | post-trial CTA `لقد جربت واصل` | → `لقد جربت أنيس` |
| [follow_up_question_sheet.dart:100](lib/shared/widgets/follow_up_question_sheet.dart#L100) | label `واصل يسألك` | → `أنيس يسألك` |
| [ai_chat_screen.dart:22](lib/features/ai_assistant/screens/ai_chat_screen.dart#L22) | dartdoc | updated |
| [relationship_label_helper.dart:62](lib/shared/utils/relationship_label_helper.dart#L62) | dartdoc | updated |

### Gamification sites preserved

- [gamification_config_service.dart:501-504](lib/core/services/gamification_config_service.dart) — badge displayNameAr `واصل متمكن`, `واصل محترف`, `واصل خبير`, `واصل أسطوري` (4 badges).
- [gamification_config_service.dart:563](lib/core/services/gamification_config_service.dart#L563) — Level 10 title `واصل` / `Wasel`.
- [wrapped_generator_service.dart:108, 153](lib/features/wrapped/services/wrapped_generator_service.dart) — wrapped persona `واصل العائلة 🤝`.
- [ai_prompts.dart:1138](lib/core/ai/ai_prompts.dart#L1138) — `"واصل العائلة"` inside an AI prompt template that asks the AI to **generate** wrapped labels — gamification context, kept.

### Prod migration

[supabase/migrations/20260428100000_ai_persona_rename_to_anees.sql](supabase/migrations/20260428100000_ai_persona_rename_to_anees.sql)

MCP-introspected:
- `admin_ai_identity` is **empty** (0 rows). v1 falls back to `AIIdentityConfig.fallback()` which now returns `aiName='أنيس'`. No update needed.
- `admin_ai_personality` had 1 row with `content_ar` starting `أنت واصل،…`. Migration updates that row.
- `admin_counseling_modes` and `admin_suggested_prompts` had 0 rows matching the standalone-`واصل` pattern.

Migration: defensive `REPLACE` scoped by id with a `WHERE content_ar LIKE 'أنت واصل،%'` guard. Self-verifies that the row no longer starts with `أنت واصل،` AND now starts with `أنت أنيس،`.

**Applied to prod.** MCP post-apply: `LEFT(content_ar, 50) → 'أنت أنيس، مساعد ذكي متخصص في تعزيز صلة الرحم والعل'`. ✅

---

## Task 3 — Terminology sweep ✅

### Inventory

| Term | Total occurrences in lib/ |
|---|---|
| `تذكير` | 107 |
| `إشعار` | 39 |
| `تنبيه` | 3 |

The Cat 3 audit had pre-identified the 4 misuse sites — fallback push titles where the title used `تذكير` (or `تنبيه`) but the body said `لديك إشعار جديد`. Per Decision 3, when title and body are misaligned with the OS-push fallback context, the title should match `إشعار` (the OS-delivery surface).

### Per-site decisions

| File:line | Title before | Body | Decision | Change |
|---|---|---|---|---|
| [fcm_notification_service.dart:60](lib/shared/services/fcm_notification_service.dart#L60) | `'تذكير'` | `'لديك إشعار جديد'` | Mismatch → align with body | → `'إشعار'` |
| [fcm_notification_service.dart:397](lib/shared/services/fcm_notification_service.dart#L397) | `'تذكير'` | `'لديك إشعار جديد'` | Same | → `'إشعار'` |
| [supabase_notification_service.dart:169](lib/shared/services/supabase_notification_service.dart#L169) | `'تذكير'` | `'لديك تذكير جديد'` | Aligned (reminder-framed) | KEEP |
| [supabase_notification_service.dart:398](lib/shared/services/supabase_notification_service.dart#L398) | `'تنبيه'` | `'لديك إشعار جديد'` | Decision 3: `تنبيه` ≠ OS-push title | → `'إشعار'` |
| [supabase_notification_service.dart:456-457](lib/shared/services/supabase_notification_service.dart#L456) | `'تذكير'` (title) + `'لديك تذكير'` (body) | — | Aligned (schedule-reminder path) | KEEP |
| [ai_prompts.dart:963](lib/core/ai/ai_prompts.dart#L963) | `4. تنبيهات مهمة (إن وجدت)` (AI prompt template) | — | Decision 3: `تنبيه` = urgent in-app banner; AI is being asked to surface those | KEEP |
| [ai_prompts.dart:984](lib/core/ai/ai_prompts.dart#L984) | `"تنبيه مهم إن وجد"` (JSON example in AI prompt) | — | Same | KEEP |

3 sites changed; 4 sites confirmed correct. The remaining 142 occurrences across `تذكير` and `إشعار` were spot-checked and are correctly used per Decision 3.

### TERMINOLOGY.md

[TERMINOLOGY.md](TERMINOLOGY.md) created in repo root with the three-term policy, surface mappings, and the explicit decision date.

---

## Test fix

The brand normalization broke 4 unit tests in [shareable_card_generator_test.dart](test/unit/shared/shareable_card_generator_test.dart) that asserted the old `#صِلني` hashtag form. Updated the assertions to `#صِلْني` (4 lines: 69, 84, 97, 117). The tests were correctly testing the share-card output — they just needed to track the brand decision.

After fix: 1354 / 0.

---

## Verification

| Check | Phase 6.0 baseline | Phase 6.1 result | Verdict |
|---|---|---|---|
| `flutter analyze` | 6 issues | **6 issues** (same lines) | ✅ baseline preserved |
| `flutter test test/unit/` | 1354 / 0 | **1354 / 0** | ✅ |
| `flutter test test/golden/` | 8 / 0 | **8 / 0** | ✅ |
| `flutter build ios --release --no-codesign` | 70.0 MB | **70.0 MB / 44.1 s** | ✅ |
| `grep -rln "صِلني\|صلني" lib/` | n/a | **0 matches** | ✅ |
| `grep -rEn "standalone واصل" lib/features/ai/ lib/core/ai/` | n/a | gamification-only matches (4 in ai_prompts.dart wrapped section) | ✅ |
| MCP `admin_ai_personality` row prefix | `أنت واصل،...` | `أنت أنيس، مساعد ذكي...` | ✅ |
| MCP `admin_in_app_messages` row | bare `صلني` | canonical `صِلْني` only | ✅ |
| MCP `admin_hadith narrator IS NULL` | 3 rows | 3 rows (Task 4 halt — unchanged) | 🟡 **expected halt** |
| MCP English citations in `admin_hadith` | 3 rows | 3 rows (Task 4 halt — unchanged) | 🟡 **expected halt** |

---

## Surprises

1. **`admin_ai_identity` is empty on prod.** The CTO's plan assumed a row to update. There isn't one — v1 routes through the in-code `AIIdentityConfig.fallback()`. The migration handled this correctly (no-op for empty table), but worth noting that the AI persona name lives only in code today.
2. **Gamification level 10 is also named `واصل`** — same word as the (now-renamed) AI persona. This is the **gamification side** of the collision the audit flagged; it's intentionally preserved per Decision 2. So a user reaching level 10 will see "Level 10: واصل" while the AI is "أنيس". Worth documenting in BRAND.md (already done).
3. **Hadith grades are already correct on prod** — the `[FOUNDER FILLS — likely صحيح]` placeholder for the Bukhari row is technically already `صحيح` on prod, and the two Ahmad rows are `حسن`. So Task 4 halt is narrowed: only the 3 narrators are missing. The grade column is fine. The migration when narrators arrive is a 3-statement update + citation reformat (English → Arabic-with-Arabic-Indic), nothing else.
4. **The `سنن الترمذي` row (display_priority 94) and the unnumbered Bukhari/Ahmad rows (96, 95)** — the Cat 4 audit flagged these as missing hadith numbers. Founder may want to research and supply numbers in a follow-up session, but they're not Task 4 scope per the prompt (which named only the 3 Wave 2 rows).
5. **One unit-test regression** caught by the test suite — the brand-form assertions in `shareable_card_generator_test.dart`. Fixed by updating expectations. Tests properly tracked the brand string and caught the change.

---

## Open questions for the CTO

1. **Task 4 narrators** — please supply the 3 narrators (Bukhari 6138, Musnad Ahmad 7563, Musnad Ahmad 16033) so the hadith metadata migration can land. Grades are already correct on prod; only the narrators + the citation reformat (English → Arabic-with-Arabic-Indic) are needed.
2. **3 other rows in `admin_hadith` lack hadith numbers** in their citations: display_priority 96 (`صحيح البخاري`), 95 (`مسند الإمام أحمد`), 94 (`سنن الترمذي`). These were flagged in Cat 4 of the original audit. Want me to ask the founder to research these too, or leave for v1.1?
3. **`admin_ai_identity` is empty** — should we seed a row with `أنيس` as a defensive measure, OR rely solely on the in-code fallback? The fallback works fine today; no urgency.

---

## What's NOT done

- **Task 4 (hadith metadata fill).** Narrator placeholders unfilled in the prompt. Halted per CTO standing order. Once the founder supplies narrators, the follow-up migration is mechanical (~30 lines).
- **3 admin_hadith rows with missing hadith numbers** (display_priority 94, 95, 96) — outside Phase 6.1 scope per the prompt; flagged for CTO triage.
