---
name: Phase 9.X.D.A.fix — self-node leak fixed; Bug 2 + Bug 3 halted for founder clarification
description: Bug 1 fixed end-to-end (5 surfaces). Bug 2 swept clean — every contact-recency rendering null-guards correctly; lying behavior most likely a symptom of Bug 1. Bug 3 has no reproducer in current code (no date input exists in add/edit relative screens).
type: project
---

# PHASE 9.X.D.A.fix Report

**Date:** 2026-04-28
**Commit:** `7b81820` (Bug 1 fix; Bug 2 + 3 halted)

---

## Bug 1 — Self-node leak into relatives surfaces — FIXED

### Root cause

Phase 9.X.D Track A4 began inserting `is_self=true` relatives rows for **solo users** (previously only group-joiners had one). The `viewerFilteredRelativesProvider` — the canonical "relatives to display" gateway — only excluded the self-node when in **group mode** (via the `viewerNodeId` check). Solo users had `viewerNodeId=null`, so the gateway returned the self-node alongside actual relatives. Plus 4 direct-bypass screens read `relativesStreamProvider` without going through the gateway.

### Per-site classification

#### EXCLUDE is_self (5 sites fixed)

| Site | Surface | Rationale |
|---|---|---|
| [`viewerFilteredRelativesProvider`](lib/features/home/providers/home_providers.dart) | Home carousel, relatives list, today's activity, due reminders, briefing, relationship labels | Canonical user-display gateway. Self-node is internal anchor, not user data. |
| [`ai_context_engine._fetchRelatives`](lib/core/ai/ai_context_engine.dart) | AI relative counts, prompt context | AI uses `_userFullNameCache` (Phase 9.X.D.A5) for user identity; relatives cache is for actual family. |
| [`add_relative_screen.dart:408`](lib/features/relatives/screens/add_relative_screen.dart#L408) | Duplicate-detection lookup in review step | User shouldn't trigger "duplicate name" against themselves. |
| [`create_group_screen.dart:327`](lib/features/family_groups/screens/create_group_screen.dart#L327) | Group-creation member picker | Creator IS the group; no self-pick. |
| [`weekly_report_stats_provider.dart:107`](lib/features/ai_assistant/providers/weekly_report_stats_provider.dart#L107) | Weekly report top relatives | Self-node has 0 interactions, but defense-in-depth. |

#### INCLUDE is_self (verified, no change)

| Site | Surface | Rationale |
|---|---|---|
| [`family_tree_screen.dart:183, 453, 778, 1284`](lib/features/family_tree/screens/family_tree_screen.dart) | Family tree visualization | Tree anchors on the self-node (legitimate inclusion). |
| [`family_graph_providers.dart:199`](lib/features/family_tree/providers/family_graph_providers.dart#L199) | Graph provider for tree rendering | Same — graph topology requires the self anchor. |
| [`add_relative_screen.dart:295`](lib/features/relatives/screens/add_relative_screen.dart#L295) | `existingRelatives` for `FamilyGraphService.inferEdges` | Edge inference uses self-node to compute parent_of / sibling_of / spouse_of through the user. |
| [`edit_relative_screen.dart:221`](lib/features/relatives/screens/edit_relative_screen.dart#L221) | Same — edge inference | Same. |
| [`contact_import_screen.dart:254`](lib/features/contacts/screens/contact_import_screen.dart#L254) | Same — batch edge inference | Same. |
| [`reminders_screen.dart:92`](lib/features/reminders/screens/reminders_screen.dart#L92) | `relativesMap` for relationship-label context | Label-lookup map, not a display list. Self-node enriches label semantics. |

### AI context update

`ai_context_engine._fetchRelatives` now filters `is_self=false`. AI does NOT count the user as one of their own relatives. The user's name is sourced from `_userFullNameCache` (added in Phase 9.X.D.A5), so the AI still has user identity context — just not via the relatives table.

---

## Bug 2 — "Last contacted X ago" lying — SWEEP CLEAN, HALT FOR RETEST

### Investigation

Audited every "آخر تواصل" / "منذ X يوم" rendering site in `lib/`. Verified each correctly null-guards before emitting a recency string:

| Site | Rendering | Null-guard | Verdict |
|---|---|---|---|
| [`swipeable_relative_card.dart:287-294`](lib/shared/widgets/swipeable_relative_card.dart#L287-L294) | "منذ N يوم" / "لم يتم التواصل" | `daysSinceLastContact != null ? ... : 'لم يتم التواصل'` | ✅ Clean |
| [`relative_stats_card.dart:32-37`](lib/features/relatives/widgets/detail/relative_stats_card.dart#L32-L37) | "اليوم" / "منذ N يوم" / "لم يتم" | `daysSince == null ? 'لم يتم' : ...` | ✅ Clean |
| [`reminders_due_screen.dart:411-417`](lib/features/reminders/screens/reminders_due_screen.dart#L411-L417) | "آخر تواصل: ..." | `if (daysSinceContact != null) ...` | ✅ Clean |
| [`avatar_carousel.dart:308-316`](lib/shared/widgets/avatar_carousel.dart#L308-L316) | Extended-category subtitle | `if (relative.lastContactDate != null) ... else return null` | ✅ Clean |
| [`ai_prompts.dart:154-167, 444-466`](lib/core/ai/ai_prompts.dart#L154-L167) | AI prompt context "آخر تواصل: منذ X" | `if (relative.lastContactDate != null) {...}` | ✅ Clean |

### Schema default check

```sql
last_contact_date TIMESTAMPTZ,  -- no DEFAULT, NULLs allowed
```

Insert paths: `add_relative`, `contact_import_service`, `family_sharing_service` — none set `last_contact_date` on insert. Newly-added relatives have `last_contact_date = NULL`.

The `Relative` model's `daysSinceLastContact` getter:
```dart
int? get daysSinceLastContact {
  if (lastContactDate == null) return null;
  return DateTime.now().difference(lastContactDate!).inDays;
}
```

Returns null for fresh relatives. UI null-guards handle it correctly.

### Hypothesis

Bug 2 is most likely a **symptom of Bug 1**. The self-node leaking into the carousel showed up as a "household member you contacted today" or similar — depending on which subtitle path the founder was looking at. Once Bug 1 is fixed (this commit), the founder retests on a fresh account.

If the lying behavior persists for a freshly-added (non-self) relative, deeper investigation needed:
- `family_sharing_service` flows — does claim_tree_node or similar set `last_contact_date`?
- `record_interaction_and_update_relative` RPC — verify it only sets on actual interaction
- Test path — is there a hidden interaction being created during add-relative flow?

**Halt for founder retest.**

---

## Bug 3 — Date format/value in AddRelative — NO REPRODUCER, HALT

### Investigation

Comprehensive grep of `add_relative_screen.dart` and `edit_relative_screen.dart` for date inputs:
- `DatePicker`, `showDatePicker`, `CupertinoDatePicker`, `DateField` → **zero matches**
- `date_of_birth`, `dateOfBirth`, `DOB`, `birthday`, `تاريخ`, `ميلاد` → **zero matches in either screen**
- Only date code: `createdAt: DateTime.now()` on the new Relative construction (auto-derived from system time, not user input)

### Schema check

`relatives.date_of_birth TIMESTAMPTZ` exists in schema but is **never captured by the form**. The Relative model has `dateOfBirth: DateTime?` field, but `AddRelativeScreen` doesn't render any picker for it.

### Possible interpretations

1. The founder saw a date displayed on a relative card *after* adding (e.g., next-birthday calculation falling back to a wrong default when `date_of_birth` is null)
2. The founder saw "today's date" in a header / breadcrumb / debug overlay that was wrong
3. The founder is referring to a date input on the **reminder schedule** flow (separate screen)
4. The founder expected a `date_of_birth` field that doesn't exist (ahead-of-spec — schema has the column, form doesn't capture it)

**Halt for founder clarification:** which screen, what date, what was shown vs what was expected. With that detail, fix is straightforward.

---

## Defaults-rendered-as-data sweep

The CTO note: "ask if there are other instances of this default-as-data pattern."

| Default | Rendered as data? | Verdict |
|---|---|---|
| **Self-node default `relative_category='household'`** | Yes — Bug 1 | **Fixed in this commit** |
| `relatives.last_contact_date=NULL` | No — null-guarded everywhere | ✅ Clean |
| `relatives.priority=2` (medium) | Rendered correctly as "متوسطة" | ✅ Semantically correct default |
| `relatives.relative_category='extended'` | Rendered correctly as "تواصل دائم" | ✅ Sensible default |
| `users.subscription_status='free'` | Rendered correctly as free tier | ✅ Correct |
| `users.onboarding_metadata='{}'` | JSONB empty object, no rendering | ✅ Correct |
| `users.full_name` (from auth metadata) | Rendered as user's name | 🟡 Falls back to email if metadata missing — defensible but worth a wizard polish step (Track B) |

No other "default-as-data" leaks found. The pattern was self-node-specific.

---

## Founder real-device verification gates Track B+C

After this commit (`7b81820`), founder runs through the verification list:

1. **Home `أهل البيت` carousel** — should show ZERO entries on a fresh account (was: showing self-node leak)
2. **Relatives list** — ZERO entries on fresh account
3. **Family tree** — self-node still anchors the tree (positive verification — the fix preserves this)
4. **Add a relative + look at the resulting card** — should say "لم يتم التواصل" or skip the chip entirely; should NOT claim recent contact recency
5. **AI chat** — should not reference user as a relative; should not double-count user in any "you have N relatives" statements
6. **Bug 3 reproduction** — founder shows engineer the screen + date specifics so we can fix targeted

If 1-3 pass, Bug 1 is closed. If 4 still shows lying, Bug 2 needs deeper investigation. If 5 still mis-counts, the AI fix is incomplete (but the surfaces are clean per code audit). Bug 3 needs founder data point.

---

## Verification (engineer-side)

| Check | Result |
|---|---|
| `flutter analyze` | 0 issues |
| `flutter test test/unit/` | 1175 / 0 |
| `flutter test test/golden/` | 8 / 0 |

---

## Open questions for the CTO

1. **Bug 2 retest result** — does the lying behavior persist on a fresh relative AFTER Bug 1 fix? If yes, deeper probe of write paths needed.
2. **Bug 3 specifics** — which screen + which date + what's wrong. Could be a non-obvious surface (e.g., next-birthday calc, reminder date input, debug header).
3. **`users.full_name` fallback to email when auth metadata is missing** — minor edge case; arguably a wizard's job to surface a name confirmation step. Defer to Track B.
4. **A2 (relative_category 3-value)** — already resolved in `A2_RELATIVE_CATEGORY_INVESTIGATION.md` (Path A: keep 3-value, wizard surfaces only household/extended). No action here.

---

## Closing state

Bug 1 fixed at 5 surfaces (gateway + 4 direct-bypass). Bug 2 swept clean — every rendering null-guards correctly; persistence depends on retest. Bug 3 has no current reproducer. Track B+C wait for founder real-device verification.
