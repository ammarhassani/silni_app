# Phase γ.2-prep — Code prerequisites for AI prompt content overhaul

**Date:** 2026-05-03
**Source of brief:** CTO γ.2-prep runbook
**Status:** All three tasks complete. Real-device verification pending founder.

---

## Task 1 — Seed `admin_ai_identity`

### Migration

[supabase/migrations/20260503100000_seed_admin_ai_identity.sql](supabase/migrations/20260503100000_seed_admin_ai_identity.sql)

Initially wrote the migration as `INSERT … SELECT … WHERE NOT EXISTS`. That form failed in MCP `apply_migration` with `INSERT has more target columns than expressions` despite a literal column-and-value count of 10 each — likely an Arabic-string parser interaction with the `WHERE NOT EXISTS` clause. Rewrote as `DO $$ … IF NOT EXISTS … INSERT … VALUES … END $$` which applied cleanly. Local migration file updated to match what actually shipped, so a future `supabase db push` will hit the same code path.

### MCP pre/post state

| Stage | `count(*)` | active rows |
|---|---|---|
| Before migration | 0 | 0 |
| After migration | **1** | **1** |

Post-state row (verbatim from `SELECT * FROM admin_ai_identity`):

```
id:                   ec78b981-2fd1-416e-93e7-803e3faca990
ai_name:              أنيس
ai_name_en:           Wasel
ai_role_ar:           مساعد ذكي متخصص في صلة الرحم والعلاقات الأسرية
ai_role_en:           Smart assistant for family connections
greeting_message_ar:  السلام عليكم! أنا أنيس، مساعدك الشخصي لصلة الرحم. كيف يمكنني مساعدتك اليوم؟
greeting_message_en:  NULL
dialect:              saudi_arabic
personality_summary_ar: NULL
ai_avatar_url:        NULL
is_active:            true
created_at:           2026-05-03 09:58:33.689851+00
```

Values match `AIIdentityConfig.fallback()` in [lib/core/services/ai_config_service.dart:413-422](lib/core/services/ai_config_service.dart#L413-L422) verbatim. Production behavior is unchanged at apply-time — the model receives identical persona text. Founder can now open silni-admin → AI → Identity, see the row, and edit it. γ.2 content goes in via that UI.

### Note on `supabase db push`

Local migrations dir is out of sync with remote — `supabase db push` rejected with "Remote migration versions not found in local migrations directory." The remote DB has 7 migration versions that aren't in the local repo (likely from earlier work). Bypassed via MCP `apply_migration` and updated the local file to match. **CTO should run `supabase migration repair --status reverted <list>` + `supabase db pull` at a calm moment to reconcile**, but it's not blocking γ.2.

---

## Task 2 — `واصل` leak in silni-admin

### Search

`grep -rn "واصل" silni-admin/src/ silni-admin/scripts/` — raw match count: 47. After filtering substring matches inside the unrelated noun "تواصل" / "التواصل" / "بالتواصل" / "للتواصل" / "متواصل" (= "communication" in Arabic; same root letters but completely different word), persona-name candidates: **17**.

### Classification + fix table

| File | Line | Context | Verdict | Action |
|---|---|---|---|---|
| `src/app/(dashboard)/ai/personality/page.tsx` | 73 | "شخصية واصل الكاملة" info-card | 🔴 persona | → "شخصية أنيس الكاملة" |
| `src/app/(dashboard)/ai/identity/page.tsx` | 99 | `{identity?.ai_name \|\| "واصل"}` fallback display | 🔴 persona | → "أنيس" |
| `src/app/(dashboard)/ai/identity/page.tsx` | 124 | `placeholder="واصل"` (Arabic name input) | 🔴 persona | → "أنيس" |
| `src/app/(dashboard)/ai/identity/page.tsx` | 180 | "السلام عليكم! أنا واصل…" greeting placeholder | 🔴 persona | → "أنا أنيس…" |
| `src/app/(dashboard)/ai/identity/page.tsx` | 215 | "يتميز واصل بأسلوبه الودي…" summary placeholder | 🔴 persona | → "يتميز أنيس…" |
| `src/app/(dashboard)/ai/memory/page.tsx` | 139 | "إعدادات نظام ذاكرة واصل" | 🔴 persona | → "ذاكرة أنيس" |
| `src/app/(dashboard)/ai/memory/page.tsx` | 169 | "تحديد كمية المعلومات التي يحتفظ بها واصل" | 🔴 persona | → "يحتفظ بها أنيس" |
| `src/app/(dashboard)/ai/conversations/page.tsx` | 46 | "إحصائيات ونظرة عامة على استخدام واصل" | 🔴 persona | → "استخدام أنيس" |
| `src/app/(dashboard)/ai/streaming/page.tsx` | 62 | sample text "السلام عليكم! أنا واصل…" | 🔴 persona | → "أنا أنيس…" |
| `src/app/(dashboard)/ai/streaming/page.tsx` | 312 | avatar initial `<span>و</span>` | 🔴 persona | → "أ" |
| `src/app/(dashboard)/ai/streaming/page.tsx` | 315 | preview chip `<p>واصل</p>` | 🔴 persona | → "أنيس" |
| `src/app/(dashboard)/ai/touch-points/page.tsx` | 368 | placeholder "أنت واصل، مساعد صلة الرحم…" | 🔴 persona | → "أنت أنيس…" |
| `src/app/(dashboard)/ai/prompts/page.tsx` | 235 | "تسهيل التفاعل مع واصل" | 🔴 persona | → "التفاعل مع أنيس" |
| `src/app/(dashboard)/dashboard/page.tsx` | 149 | "إعداد واصل - الهوية والشخصية والذاكرة" | 🔴 persona | → "إعداد أنيس" |
| `src/app/(dashboard)/subscriptions/features/page.tsx` | 364 | placeholder "تحدث مع واصل للحصول على نصائح" | 🔴 persona | → "تحدث مع أنيس" |
| `src/components/layout/sidebar.tsx` | 108 | sidebar AI section badge `badge: "واصل"` | 🔴 persona | → "أنيس" |
| `src/app/api/social/generate/route.ts` | 151 | social-publish prompt: "مركز واصل — محادثة ذكية مع AI" | 🔴 persona | → "مركز أنيس" |
| `src/app/(dashboard)/gamification/badges/page.tsx` | 311 | badge name placeholder "واصل الأسبوع" | 🟢 **leave alone** — Arabic adjective ("Week Connector"). English placeholder on adjacent line is `Week Connector` which confirms the intended meaning. Per Phase 6.1 BRAND.md: "`واصل` continues to mean 'one who maintains ties' in badges, level titles, and wrapped labels". |

**Total: 17 persona-name references found, 16 fixed, 1 intentionally preserved.**

### English transliteration "Wasel"

The English placeholder `Wasel` (in identity/page.tsx:135) was *not* changed. Per [ai_identity.dart:21](lib/core/ai/ai_identity.dart#L21) the lib still treats `defaultNameEn = 'Wasel'` as the English transliteration — Phase 6.1 only renamed the Arabic name. Out of γ.2-prep scope; flagging as Open Question for the CTO.

### Verification

`grep -rn "واصل" silni-admin/src/ silni-admin/scripts/ | grep -v <substring-noun-pattern>` after fixes returns exactly one line: the `gamification/badges/page.tsx:311` `placeholder="واصل الأسبوع"` (intentional, preserved).

### Deploy

The Vercel-hosted admin app deploys on push to the relevant branch (per [supabase/functions/_shared/cors.ts](supabase/functions/_shared/cors.ts) which lists `https://silni-admin.vercel.app`). The 16 file edits are committed-ready but not pushed by this engineer — founder/CTO commit + push when ready, then check `silni-admin.vercel.app` after the Vercel deploy completes.

---

## Task 3 — Switch chat surface to `buildEnhancedChatSystemPrompt`

### Pre-check (Task 3a)

Read [ai_prompts.dart:282-337](lib/core/ai/ai_prompts.dart#L282-L337). Result:

| Aspect | Status |
|---|---|
| Doc comment mentions "Gamification data (level, points, streaks)" | ⚠️ stale — only streaks remain post-Phase 9.X |
| Body references `context.totalInteractions` | ✅ counter, preserved |
| Body references `context.totalActiveStreaks` | ✅ streaks preserved per Phase 9.X |
| Body references `context.healthSummary` | ✅ |
| Body references `context.upcomingOccasions` | ✅ |
| Body references `context.relatives` / `focusRelative` / `streaks` (focus) / `memories` | ✅ |
| Body references badges / points / level / XP / rank | ❌ **none** — implementation already clean |

**Verdict: safe to switch.** The doc comment was stale but the implementation never referenced cut features. Updated the doc comment to be accurate.

Additional finding during pre-check: the existing builder did NOT inject `context.userFullName` despite `AIContext` carrying it (the inventory's finding 13: "the chat surface never gives the AI the user's name"). Adding userFullName injection was the actual point of the task and was performed below.

### Changes — file:line

**[lib/core/ai/ai_prompts.dart:275-355](lib/core/ai/ai_prompts.dart#L275-L355) — `buildEnhancedChatSystemPrompt`:**

1. Doc comment rewritten — removed stale "level, points" reference; documents that γ.2-prep makes this the chat surface's prompt builder.
2. New optional parameter `Map<String, String>? relationshipLabels` so perspective-aware labels (e.g., "عمي" instead of "عم/خال") flow through to `buildAllRelativesContext` and `buildRelativeContext`.
3. New "## معلومات المستخدم" block now begins with:
   ```
   - الاسم: ${context.userFullName}
   ```
   when `userFullName` is non-empty. The inventory's finding 13 (the user is anonymous to the chat AI) is now resolved.

**[lib/features/ai_assistant/providers/ai_chat_provider.dart](lib/features/ai_assistant/providers/ai_chat_provider.dart):**

- Added import: `import '../../../core/ai/ai_context_engine.dart';` ([line 4](lib/features/ai_assistant/providers/ai_chat_provider.dart#L4))
- `aiChatProvider` ([:90-110](lib/features/ai_assistant/providers/ai_chat_provider.dart#L90-L110)) — dropped the eager reads of `viewerFilteredRelativesProvider` and `aiMemoriesProvider`; the data now flows through `AIContextEngine` (its own 5-min cache). Kept `perspectiveLabelsProvider` because AIContextEngine doesn't compute perspective-aware labels.
- `AIChatNotifier` constructor ([:181-198](lib/features/ai_assistant/providers/ai_chat_provider.dart#L181-L198)) — removed `allRelatives` and `memories` parameters (unused after switch).
- `sendMessage` ([:330-345](lib/features/ai_assistant/providers/ai_chat_provider.dart#L330-L345)):
  ```dart
  final aiContext = await AIContextEngine.instance.buildContext(
    focusRelative: relativeContext,
  );
  final systemPrompt = AIPrompts.buildEnhancedChatSystemPrompt(
    mode: mode,
    context: aiContext,
    relationshipLabels: _relationshipLabels.isNotEmpty ? _relationshipLabels : null,
  );
  ```
- `sendMessageStreaming` ([:425-440](lib/features/ai_assistant/providers/ai_chat_provider.dart#L425-L440)) — same pattern.

`buildChatSystemPrompt` is now unreferenced from the chat surface but **kept** as-is. CTO can evaluate whether to delete it once γ.2 ships and the enhanced builder has soaked.

### Verification — automated

| Check | Result |
|---|---|
| `flutter analyze lib/` | **0 issues** |
| `flutter test test/unit/` | **1040/1040 passing** |
| `flutter test test/golden/` | **8/8 passing** |

### Verification — real-device behavior

🟡 **Pending founder retest.** The expected-behavior signals to watch for, per the runbook:

- **Appropriate use of name** — AI references the user's full_name as natural conversational context. E.g., user asks "كيف أحافظ على صلة الرحم؟" → AI starts "وعليكم السلام يا [name]، …" rather than "وعليكم السلام، أخي الكريم، …".
- **Over-use** — AI prefacing every paragraph with "صديقي [name]" or "[name] إن صلة الرحم …" — that's the prompt feeding the name too prominently. γ.2 prompt-content adjustment, not a code fix.
- **Under-use** — AI never uses the name. That would mean the context isn't reaching the model.
- **Streak/occasion references** — for users with active streaks or upcoming birthdays, the AI may now reference these in suggestions. Founder should sanity-check that the model isn't *forcing* references where they don't belong (e.g., bringing up a birthday in an unrelated conflict-resolution conversation).

If over- or under-use shows up on real device, the next step is γ.2 prompt-content tuning in `admin_ai_personality` — not code work here.

---

## Surprises and observations

### S1 — `INSERT … SELECT … WHERE NOT EXISTS` failed in MCP `apply_migration`

The first attempt at the seed migration used the canonical "guard via SELECT…WHERE NOT EXISTS" pattern. MCP returned `INSERT has more target columns than expressions` despite a literal 10-and-10 column/value count. The `DO $$ … IF NOT EXISTS … END $$` form applied cleanly with the same column list and values. Either MCP's SQL parser has a quirk with that pattern when the values include Arabic comma `،` characters, or there's an interaction with how the migration is wrapped. Documented in the migration file's comment so the next engineer knows.

### S2 — The English transliteration "Wasel" is still everywhere

The `defaultNameEn = 'Wasel'` constant in [ai_identity.dart:21](lib/core/ai/ai_identity.dart#L21) is the source. The seeded `admin_ai_identity.ai_name_en` is `'Wasel'`. The admin UI placeholders for `ai_name_en` show `'Wasel'`. The wrapped-personality forbidden-list still mentions `"واصل العائلة"` ([ai_prompts.dart:1136](lib/core/ai/ai_prompts.dart#L1136)). **Phase 6.1 only renamed the Arabic.** If γ.2 also wants to rename the English transliteration (e.g., to `'Anees'`), that's a separate decision. CTO call.

### S3 — `buildChatSystemPrompt` is now unreferenced from the chat surface but still has callers via tests

`grep -rn "buildChatSystemPrompt" lib/ test/` returns matches only inside `ai_prompts.dart` (the function definition itself). After γ.2 ships and soaks, the function can be deleted. Out of γ.2-prep scope.

### S4 — `AIContextEngine` now drives chat context — its 5-min TTL governs freshness

Previously the chat context (relatives, memories) was eagerly read once at notifier creation and never refreshed for the lifetime of the chat session. Now it's `AIContextEngine.instance.buildContext()` per send, which has a 5-min cache. Net effect: a user who edits a relative's metadata mid-conversation will see the AI's understanding update on the next send (within 5 min) instead of needing to leave-and-return to the chat. This is an improvement, but it's also a behavior change worth noting.

### S5 — Local migrations dir vs remote DB drift

`supabase db push` rejects with "Remote migration versions not found in local migrations directory." The remote has 7 migration versions (e.g., `20260427215557`, `20260428122913`, …) that aren't in the local repo. Bypassed via MCP for this task; will need a `supabase migration repair … reverted <list>` + `db pull` reconciliation at some point. Not blocking γ.2 but it means future migrations should be applied via MCP until reconciled.

### S6 — The admin app still has dead-code memory hooks

Earlier inventory noted that [silni-admin/src/hooks/use-ai.ts](silni-admin/src/hooks/use-ai.ts) defines `AdminAIMemoryConfig` and queries `admin_ai_memory_config` + `admin_memory_categories` — both tables dropped 2026-04-26. The admin panel UI still loads but those queries silent-fail. Not part of γ.2-prep scope; flagged.

---

## Open questions for the CTO

1. **English transliteration `Wasel`** — keep as-is, or rename to `Anees`/`Anis`? Affects: `defaultNameEn` const, seeded DB row, all admin UI placeholders for `ai_name_en`, wrapped-personality forbidden list. (Surprise S2.)

2. **Delete `buildChatSystemPrompt` after γ.2 ships?** No production code path uses it now; the only references are the function definition itself. If γ.2 doesn't roll it back, propose removing it in a follow-up. (Surprise S3.)

3. **Behavior-change disclosure to founder** — the chat AI's understanding of relatives/memories now refreshes mid-conversation (5-min TTL via AIContextEngine) instead of being frozen at chat-session start. Worth mentioning so founder knows what to watch for. (Surprise S4.)

4. **Migration repair on remote drift** — schedule a `supabase migration repair` + `db pull` to reconcile local with remote. Not blocking γ.2. (Surprise S5.)

5. **Admin UI memory-tab dead code** — wire up a follow-up to remove `useAIMemoryConfig`/`useMemoryCategories` from the admin app since their tables are gone. (Surprise S6.)

6. **`ai_avatar_url` in seeded row is NULL** — neither lib/ nor admin UI provide a default. If γ.2 wants the AI to have an avatar URL stored at the identity level, founder pastes it in via the panel. No code change needed.

---

## Files touched

```
NEW   supabase/migrations/20260503100000_seed_admin_ai_identity.sql        Task 1
EDIT  silni-admin/src/app/(dashboard)/ai/personality/page.tsx              Task 2
EDIT  silni-admin/src/app/(dashboard)/ai/identity/page.tsx                 Task 2 (×4 placeholders)
EDIT  silni-admin/src/app/(dashboard)/ai/memory/page.tsx                   Task 2 (×2)
EDIT  silni-admin/src/app/(dashboard)/ai/conversations/page.tsx            Task 2
EDIT  silni-admin/src/app/(dashboard)/ai/streaming/page.tsx                Task 2 (×3)
EDIT  silni-admin/src/app/(dashboard)/ai/touch-points/page.tsx             Task 2
EDIT  silni-admin/src/app/(dashboard)/ai/prompts/page.tsx                  Task 2
EDIT  silni-admin/src/app/(dashboard)/dashboard/page.tsx                   Task 2
EDIT  silni-admin/src/app/(dashboard)/subscriptions/features/page.tsx      Task 2
EDIT  silni-admin/src/components/layout/sidebar.tsx                        Task 2
EDIT  silni-admin/src/app/api/social/generate/route.ts                     Task 2
EDIT  lib/core/ai/ai_prompts.dart                                          Task 3 (enhanced builder)
EDIT  lib/features/ai_assistant/providers/ai_chat_provider.dart            Task 3 (call sites + import + constructor)
```

13 files. ~70 net lines changed. One DB row inserted on production.

---

## Verification request

@founder — please verify on real device:

1. **silni-admin → AI → Identity** — the seeded row should appear. The Arabic name shows `أنيس`, the dialect dropdown is set to `saudi_arabic`. Edits save and reload correctly. No "row not found" or "create row" prompts.

2. **silni-admin sidebar** → the AI section badge now reads `أنيس` (was `واصل`).

3. **silni-admin → AI → Personality** — the info-card description reads "شخصية أنيس الكاملة" (was "شخصية واصل الكاملة").

4. **silni-admin → AI → Streaming** — the preview avatar shows `أ` initial and label `أنيس` (was `و` / `واصل`).

5. **Flutter app → AI chat** — send a message like "كيف حالك؟" or "كيف أحافظ على صلة الرحم؟". Watch how the AI uses your name:
   - Used naturally (1-2 references per message, in greeting or natural mid-sentence) → ✅ working as intended.
   - Over-used (every paragraph starts with your name) → flag for γ.2 prompt-content tuning.
   - Never used → context isn't flowing; report and we'll trace.

If 1-5 pass on real device, γ.2-prep is closed. Phase γ.2 (the actual prompt content overhaul) is next per the CTO runbook.
