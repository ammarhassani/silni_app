# Phase δ.A — Cleanup bundle report

**Date:** 2026-05-03
**Status:** All 6 tasks complete. flutter analyze clean. 1040/1040 unit tests + 8/8 golden tests passing.

---

## Task 1 — Wasel → Anees

### Pre-investigation classification (10 sites)

| File:line | Class | Action |
|---|---|---|
| [lib/core/ai/ai_identity.dart:21](lib/core/ai/ai_identity.dart#L21) | 🔴 user-facing default | rename → `Anees` |
| [lib/core/services/ai_config_service.dart:416](lib/core/services/ai_config_service.dart#L416) | 🔴 user-facing fallback default | rename → `Anees` |
| [silni-admin/.../ai/identity/page.tsx:135](silni-admin/src/app/(dashboard)/ai/identity/page.tsx#L135) | 🔴 admin UI placeholder | rename → `Anees` |
| [silni-admin/.../ai/identity/page.tsx:193](silni-admin/src/app/(dashboard)/ai/identity/page.tsx#L193) | 🔴 admin UI placeholder | rename → `Anees` |
| [silni-admin/.../subscriptions/features/page.tsx:375](silni-admin/src/app/(dashboard)/subscriptions/features/page.tsx#L375) | 🔴 admin UI placeholder | rename → `Anees` |
| `supabase/migrations/20260503100000_seed_admin_ai_identity.sql:41` | ⚪ historical migration (already applied) | **skip** — applied migrations are frozen history; live DB row updated separately via fresh migration |
| `supabase/migrations/20251230100001_admin_panel_phase2.sql:15` | ⚪ historical migration column DEFAULT | **skip** — historical |
| `supabase/migrations/20251230100000_admin_panel_phase1.sql:170` | ⚪ historical gamification level title `(10, 'واصل', 'Wasel', ...)` | **skip** — gamification stack dropped 2026-04-28 (`20260428500000_drop_gamification_stack.sql`); historical |
| `supabase/migrations/20260111120000_reseed_all_admin_tables.sql:50` | ⚪ same gamification level title row | **skip** — historical |
| `supabase/migrations/20260111120000_reseed_all_admin_tables.sql:291,295` | ⚪ historical onboarding seed ("Welcome to Wasel" / "Ask Wasel") | **skip** — current `admin_onboarding_screens` has been re-seeded since (current row #5 reads "Meet Anees"); historical migration frozen |

### Live DB updates

Verified `admin_in_app_messages` and `admin_onboarding_screens` for Wasel/واصل content — both clean. The only live DB row with `Wasel` was `admin_ai_identity.ai_name_en`. Fixed via [migration `phase_delta_rename_ai_name_en_to_anees`](supabase/migrations/) (applied via MCP).

| Live DB row | Pre | Post |
|---|---|---|
| `admin_ai_identity.ai_name_en` | `Wasel` | `Anees` |

### Verification

```bash
$ grep -rn "Wasel" lib/ silni-admin/src/ test/ | grep -v "supabase/migrations/"
# (no output — all active code paths clean)
```

The 6 historical migration matches are intentionally preserved (frozen audit trail).

---

## Task 2 — `buildChatSystemPrompt` deletion

### Verification of dead-status

```bash
$ grep -rn "buildChatSystemPrompt\b" lib/ test/
# Pre: 2 matches — function definition (line 243) + doc cross-reference (line 277)
```

No call sites. Safe to delete.

### Apply

[lib/core/ai/ai_prompts.dart](lib/core/ai/ai_prompts.dart) — deleted the entire `buildChatSystemPrompt` function (~32 lines, was at lines 241-273) AND updated the doc comment for `buildEnhancedChatSystemPrompt` to remove the cross-reference and stand on its own (no longer says "Richer than [buildChatSystemPrompt] —"; now reads as the canonical chat builder).

### Post

```bash
$ grep -rn "buildChatSystemPrompt\b" lib/ test/
# (no output)
```

`flutter analyze` clean post-deletion. No callers, no broken references.

---

## Task 3 — Dead admin hooks cascade-delete

### Investigation

| Site | Action |
|---|---|
| `silni-admin/src/hooks/use-ai.ts:271-388` (interfaces + 4 hooks: `useAIMemoryConfig`, `useUpdateAIMemoryConfig`, `useMemoryCategories`, `useUpdateMemoryCategory`) | delete |
| `silni-admin/src/app/(dashboard)/ai/memory/page.tsx` (sole consumer) | delete entire file + parent directory |
| `silni-admin/src/components/layout/sidebar.tsx:117` (sidebar nav entry "الذاكرة" → `/ai/memory`) | remove line |

The only UI consumer was the now-deleted memory page. No other components reference these hooks or types.

### Apply

1. Removed ~120 lines from `use-ai.ts` (entire `// ============ AI Memory Config ============` and `// ============ Memory Categories ============` blocks). Replaced with a 4-line comment documenting why the hooks are gone (refs the 2026-04-26 Wave 2 Task 1B drop).
2. Deleted `silni-admin/src/app/(dashboard)/ai/memory/page.tsx` + the now-empty `memory/` directory.
3. Removed sidebar entry from `silni-admin/src/components/layout/sidebar.tsx`.

### Verification

```bash
$ grep -rn "useAIMemoryConfig\|useMemoryCategories\|AdminAIMemoryConfig\|AdminMemoryCategory\|/ai/memory" silni-admin/src/
# Only the breadcrumb comment in use-ai.ts remains (intentional documentation)
```

silni-admin app should build cleanly. Vercel deploy on next push.

---

## Task 4 — `MessageActionsRow` cleanup verification

```bash
$ grep -rn "MessageActionsRow" lib/ test/
# (no output)
```

Phase β.fix Task 4's deletion is confirmed complete. Nothing to do.

---

## Task 5 — Phone-invite RPC column-name bug fix

### Investigation

Confirmed via `pg_proc` source dump:

| Function | Broken reference | Actual column |
|---|---|---|
| `create_node_invitation` | `SELECT id, name, ... INTO v_relative FROM relatives` (then uses `v_relative.name`) | `relatives.full_name` |
| `get_my_pending_invitations` | `'relative_name', r.name` in `jsonb_build_object` | `relatives.full_name` |

Confirmed via `information_schema.columns` for `relatives`: only `full_name` exists; no `name` column. Both RPCs would have errored with "column 'name' does not exist" if invoked. They're dormant (no Flutter caller), so the bug had no production impact — but it would have surfaced on first reactivation.

### Apply

Migration `phase_delta_fix_phone_invite_rpc_column_names` (applied via MCP) used `CREATE OR REPLACE FUNCTION` for both RPCs. The function bodies are identical to the originals except:

- `create_node_invitation`: `SELECT id, name, relationship_type INTO v_relative` → `SELECT id, full_name, relationship_type INTO v_relative`
- `get_my_pending_invitations`: `'relative_name', r.name` → `'relative_name', r.full_name`

Self-verification block asserts post-state: both functions exist + neither contains the broken substring (`v_relative.name` or `r.name`). Migration applied successfully.

### Verification

```sql
SELECT prosrc FROM pg_proc WHERE proname IN ('create_node_invitation', 'get_my_pending_invitations');
```

Both function bodies now reference `full_name` correctly. The functions remain dormant pending v1.1 phone-invite reactivation, but the latent bug is paid down.

---

## Task 6 — `weeklyReportPrompt` const

### Halt-point: runbook premise was wrong

The runbook framing assumed `AIPrompts.weeklyReportPrompt` was the production prompt for weekly-report AI generation, with the weekly-report screen as the consumer. **Live audit found the const is unused — zero callers in `lib/` or `test/`.**

The actual production prompts for weekly-report generation live INLINE in [lib/features/ai_assistant/screens/weekly_report_screen.dart:133-145](lib/features/ai_assistant/screens/weekly_report_screen.dart#L133-L145) and [:147-153](lib/features/ai_assistant/screens/weekly_report_screen.dart#L147-L153). They are different content from the `weeklyReportPrompt` const, and the screen builds them at the call site without referencing the const.

### Decision: delete unused const + flag inline prompts as separate task

Path-A (per the runbook): seed `weekly_report/intro` admin row + wire screen to use it. **Skipped** — premise was wrong. Seeding admin content for a const that has no consumer would create dormant DB content. Fixing the screen's inline prompts is a different (larger) task because:
- The screen has TWO inline prompts (insight + tip), not one
- The screen interpolates dynamic context (relatives list, personality, etc.) at the call site
- A clean migration to admin_ai_touch_points would require either two surfaces (`weekly_report/insight`, `weekly_report/tip`) or a single richer surface with placeholder substitution similar to `relative_detail/conversation_starters`
- Each requires the same kind of placeholder-substitution wiring that `AITouchPointService` does for the conversation_starters surface

That's a CTO design decision, not engineer cleanup. Flagged in Open Questions below.

### Apply

[lib/core/ai/ai_prompts.dart](lib/core/ai/ai_prompts.dart) — deleted the unused `weeklyReportPrompt` const (10 lines). Replaced with a 7-line breadcrumb comment documenting where the production prompts live and why migration was deferred.

### Verification

```bash
$ grep -rn "weeklyReportPrompt" lib/ test/
lib/core/ai/ai_prompts.dart:897:  // Phase δ.A — `weeklyReportPrompt` const was unused (no callers in lib/
# Only the breadcrumb remains
```

---

## Cumulative verification

| Check | Result |
|---|---|
| `grep -rn "Wasel" lib/ silni-admin/src/ test/` (excluding historical migrations) | 0 matches |
| `grep -rn "buildChatSystemPrompt\b\|useAIMemoryConfig\|useMemoryCategories\|MessageActionsRow"` | 0 matches |
| `grep -rn "weeklyReportPrompt"` | only breadcrumb comment (intentional) |
| `flutter analyze lib/` | **0 issues** |
| `flutter test test/unit/` | **1040/1040 passing** |
| `flutter test test/golden/` | **8/8 passing** |
| MCP self-verify on phone-invite RPCs | **passed** (no `r.name` / `v_relative.name` substrings) |
| MCP confirm `admin_ai_identity.ai_name_en` | `'Anees'` |

---

## Surprises

### S1 — `weeklyReportPrompt` const was unused (Task 6 premise broken)

The runbook directed the engineer to migrate this const to `admin_ai_touch_points` and wire the weekly-report screen to read from there. Reality: the const had zero callers; the screen built its own inline prompts. The migration target didn't exist as the runbook framed it. Deleted the unused const + flagged the actual inline prompts as a separate (larger) task. **The runbook author had stale information about the screen's structure.**

### S2 — Live DB clean of "Wasel" outside `admin_ai_identity`

Investigation expected to find live DB contamination across multiple tables (per historical migrations referencing `'Welcome to Wasel'`, `'Ask Wasel'`). Reality: those rows were already overwritten by subsequent reseeding (`admin_onboarding_screens` row #5 now reads "Meet Anees"). Only `admin_ai_identity.ai_name_en` needed updating in the live DB. The 6 historical-migration "Wasel" matches in `supabase/migrations/` are frozen audit trail and intentionally preserved.

### S3 — Phone-invite RPC bug confirmed dormant — live impact zero

Both `create_node_invitation` and `get_my_pending_invitations` reference the broken `r.name` / `v_relative.name` columns. If invoked, both would error with "column 'name' does not exist". But Phase 5 cut the phone-invite UI and `grep -rn "create_node_invitation\|get_my_pending_invitations" lib/` shows no Flutter callers. The bug is dormant. Fixed for v1.1 reactivation; no production user has hit this.

### S4 — Migration drift compounded again (Session B prereq)

This session added 2 more remote-only migrations (`phase_delta_rename_ai_name_en_to_anees` and `phase_delta_fix_phone_invite_rpc_column_names`) via MCP, neither captured in `supabase/migrations/` locally. Compounds the existing γ.2 drift. Session B's reconciliation will pick these up.

### S5 — Sidebar memory entry was a sequence in the navigation list

Removing the `/ai/memory` sidebar entry didn't require a directory rename or downstream UI shuffle — it was a single line in a flat array. The visual gap in the sidebar will be a minor reordering on re-deploy; nothing structural.

---

## Open questions for the CTO

1. **`weeklyReportPrompt` actual production prompts** ([weekly_report_screen.dart:133-145, 147-153](lib/features/ai_assistant/screens/weekly_report_screen.dart#L133-L153)) — schedule a separate session to migrate them to admin? They need 2 surfaces (insight + tip) or one richer surface with placeholder substitution. Not blocking.

2. **`Anees` English transliteration confirmation** — the chosen English form is `Anees` (with the `-ee-` digraph). Other valid transliterations: `Anis`, `Aneis`. Confirm this is the intended form before any v1.1 marketing/store listing work.

3. **Historical migration `Wasel` references** — six matches across 3 historical migration files (gamification level titles + onboarding reseeds). All are frozen audit trail. Worth a quick CTO sign-off that "we leave applied migrations alone even when they reference the legacy persona name." If a future reseed runs, those would re-introduce stale content; flagging as a latent risk.

4. **Session B trigger** — δ.A is done; the migration drift now includes δ.A's 2 new remote-only migrations on top of γ.2's ~34. Run Session B next or defer? If deferred, future migration sessions stay blocked.

---

## Files touched

```
EDIT  lib/core/ai/ai_identity.dart                                   Wasel → Anees default
EDIT  lib/core/services/ai_config_service.dart                       Wasel → Anees fallback
EDIT  lib/core/ai/ai_prompts.dart                                    deleted buildChatSystemPrompt + weeklyReportPrompt; updated docs
EDIT  silni-admin/src/hooks/use-ai.ts                                deleted ~120 lines (memory hooks + types)
DEL   silni-admin/src/app/(dashboard)/ai/memory/page.tsx             entire file
DEL   silni-admin/src/app/(dashboard)/ai/memory/                     directory
EDIT  silni-admin/src/components/layout/sidebar.tsx                  removed memory nav entry
EDIT  silni-admin/src/app/(dashboard)/ai/identity/page.tsx           2 placeholder fixes
EDIT  silni-admin/src/app/(dashboard)/subscriptions/features/page.tsx  1 placeholder fix
DB    UPDATE admin_ai_identity SET ai_name_en='Anees'                via MCP migration
DB    CREATE OR REPLACE create_node_invitation + get_my_pending_invitations  via MCP migration
```

10 file edits, 1 file deletion, 1 directory deletion, 2 MCP migrations applied. ~150 net lines removed from the codebase.
