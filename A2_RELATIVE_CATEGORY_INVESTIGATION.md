---
name: A2 follow-up — relative_category investigation
description: Read-only investigation. The 3-value relative_category enum (household / extended / distant) is in active use across UI, AI prompts, briefing logic, and layout caching. Recommend Path A — wizard collects household/extended only; distant stays accessible from the regular add/edit form for power users.
type: project
---

# A2 Investigation — `relative_category`

**Date:** 2026-04-28
**Method:** MCP read-only + git+filesystem grep. No code changes.

---

## 1. Current value distribution on prod

| Value | Row count |
|---|---|
| `extended` | **29** |
| `household` | **28** |
| `distant` | **1** |

Total relatives: 58. Of those, only **one row** uses `distant`. (TestFlight scale; founder data.)

---

## 2. CHECK constraint definition

```
constraint: chk_relative_category
definition: CHECK ((relative_category = ANY (ARRAY['household'::text, 'extended'::text, 'distant'::text])))
```

Index also exists: `idx_relatives_category ON relatives(user_id, relative_category)`.

---

## 3. Migration that created it

**[supabase/migrations/20260302100000_add_relative_category.sql](supabase/migrations/20260302100000_add_relative_category.sql)** (2026-03-02):

```sql
ALTER TABLE relatives
  ADD COLUMN relative_category TEXT NOT NULL DEFAULT 'extended';

ALTER TABLE relatives
  ADD CONSTRAINT chk_relative_category
  CHECK (relative_category IN ('household', 'extended', 'distant'));

CREATE INDEX idx_relatives_category ON relatives(user_id, relative_category);
```

**Design rationale** (recovered from semantics encoded across UI + AI prompts — there's no header comment in the migration itself):

| Value | Semantic | Source |
|---|---|---|
| `household` | أهل البيت — تواصل يومي — *"doesn't need contact tracking"* | [`relative_category_picker.dart:25-31`](lib/shared/widgets/relative_category_picker.dart#L25-L31) hint + [`ai_prompts.dart:224`](lib/core/ai/ai_prompts.dart#L224) Arabic gloss |
| `extended` | تواصل دائم — تواصل أسبوعي — *"needs regular follow-up"* | Same |
| `distant` | مناسبات — أعياد ومناسبات — *"occasions only"* | Same |

The 3 values encode three distinct cadences. Not redundant.

Re-affirmed by `20260427300000_capture_core_tables.sql:113,367-369` (the schema-snapshot migration).

---

## 4. lib/ read sites — all three values are actively consumed

### Model + form

- [`relative_model.dart:4-13`](lib/shared/models/relative_model.dart#L4-L13) — `RelativeCategory` enum has all 3 values. `fromString` defaults to `extended`. Default for new relatives: `RelativeCategory.extended`.
- [`add_relative_screen.dart:68,582`](lib/features/relatives/screens/add_relative_screen.dart#L68) + [`edit_relative_screen.dart:55,379`](lib/features/relatives/screens/edit_relative_screen.dart#L55) — both surface `RelativeCategoryPicker`, all 3 selectable.
- [`relative_category_picker.dart:25-44`](lib/shared/widgets/relative_category_picker.dart) — three-tile picker UI with emoji + label + hint per value.

### Filter UI

- [`relatives_screen.dart:266-275`](lib/features/relatives/screens/relatives_screen.dart#L266-L275) — three filter chips visible to users: 🏠 أهل البيت / 📞 ممتدة / 🌙 مناسبات. Each chip filters the list to its category.

### Home rendering

- [`family_circles_widget.dart:41-49`](lib/features/home/widgets/family_circles_widget.dart#L41-L49) — splits relatives into three sections (household / extended / distant). Each renders as a horizontal carousel in the home screen.
- [`family_circles_widget.dart:205`](lib/features/home/widgets/family_circles_widget.dart#L205) — special check: relatives where `relativeCategory != household` (distant + extended grouped for that purpose).

### AI surfaces (all 3 values matter)

- [`ai_prompts.dart:222-226`](lib/core/ai/ai_prompts.dart#L222-L226) — `_getCategoryArabic()` switch returns explicit Arabic descriptions ending in:
  - `household` → "أهل البيت — لا يحتاج تتبع تواصل"
  - `extended` → "تواصل دائم — يحتاج متابعة منتظمة"
  - `distant` → "مناسبات — أعياد ومناسبات فقط"
- [`ai_prompts.dart:446-449`](lib/core/ai/ai_prompts.dart#L446-L449) — bracket-tag switch `[أهل البيت] / [تواصل دائم] / [مناسبات]` for prompt context.
- [`ai_briefing_provider.dart:87-172`](lib/features/home/providers/ai_briefing_provider.dart#L87-L172) — branches differently per category in 5 places. `extended` for follow-up generation, `distant` for occasion-only logic, `household` for household-aware briefings.
- [`ai_context_engine.dart:422-424`](lib/core/ai/ai_context_engine.dart#L422-L424) — counts each category separately for the prompt summary block (household / extended / distant).

### Layout

- [`family_tree_layout_service.dart:107`](lib/features/family_tree/services/family_tree_layout_service.dart#L107) — uses `relativeCategory.name` as part of the layout cache key.

### Persistence on signup

- [`add_relative_screen.dart:230`](lib/features/relatives/screens/add_relative_screen.dart#L230) writes `_selectedCategory.name` to DB.
- [`edit_relative_screen.dart:165`](lib/features/relatives/screens/edit_relative_screen.dart#L165) updates `relative_category` field.
- [`contacts_import_screen.dart:283`](lib/features/contacts/screens/contact_import_screen.dart#L283) imports with category preserved.

**Net: every value in the 3-value enum is read from at least 5 distinct surfaces** (UI filter chips, picker tiles, home circles, AI prompts, AI briefing branching). Collapsing to 2 would degrade AI behavior (lose the "occasions-only" cadence semantics) and remove a user-visible filter chip + carousel section.

---

## Recommendation: **Path A**

The existing 3-value enum is **in active use and semantically meaningful**. AI prompts encode distinct cadences for each. UI surfaces all 3 with explicit emoji/label/hint. Briefing logic branches differently per value.

**Wizard scope:**
- The Track B wizard surfaces only **household** and **extended** (the binary the founder cares about for first-run setup — daily-contact vs needs-active-maintenance).
- `distant` ("occasions only") stays as a **post-wizard option** accessible from the regular add-relative / edit-relative form via the existing `RelativeCategoryPicker`. Power users who want to mark someone as occasions-only can still do it; the wizard just doesn't ask the question upfront.

**No migration needed.** No CHECK constraint change. No data migration of the 1 existing `distant` row. No Dart enum change.

**Rationale this is the right call:**
1. 1 of 58 rows uses `distant` — too low to bother forcing migration, high enough to mean the option matters when it matters
2. The AI prompts encode a meaningful cadence distinction (`distant` = occasions-only); collapsing it would degrade AI behavior on relationships that genuinely shouldn't get weekly nudges
3. The existing UI shows all 3 already; the wizard simply asks the user-friendly binary and lets them refine post-wizard if they want
4. Zero engineering work to land — wizard's category step asks 2 buttons; existing schema/code unchanged

**Path B (keep 3-value, treat as 2-value for wizard purposes)** is functionally identical to Path A. Choose Path A for clarity.

**Path C (migrate to 2-value)** is rejected:
- Loses AI prompt distinction
- Removes a filter chip + a home carousel section
- Forces re-categorization of the 1 existing `distant` row
- Adds engineering work for no user benefit

---

## Founder action

CTO confirms Path A → Track B wizard team builds the category step with two buttons (household / extended). No backend changes needed. `distant` continues to exist as a refinement option from the regular relative-detail screen.
