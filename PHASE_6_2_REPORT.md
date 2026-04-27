---
name: Phase 6.2 — Hadith metadata fill (founder data approved)
description: Closes the Phase 6.1 Task 4 halt. Three Wave-2-captured admin_hadith rows updated with founder-researched narrators + corrected reference numbers + Arabic-numeral citations. Self-verify passed; 0 NULL narrators, 0 Latin-letter citations remain.
type: project
---

# PHASE 6.2 — Hadith Metadata Fill

**Date:** 2026-04-27
**Status:** ✅ Migration applied. Self-verification passed. Content audit closed except for 3 unnumbered legacy rows (open question for the CTO).
**Commit:** `<this commit>`.

---

## Pre-state (MCP-introspected before writing migration)

The 3 Wave-2-captured rows had English-letter source citations and `narrator IS NULL`:

| id | display_priority | source | narrator | grade | hadith_text (excerpt) |
|---|---|---|---|---|---|
| `b037fec4-c972-4712-a8b9-fac03c7fc01e` | 101 | `Sahih Al-Bukhari 6138` | NULL | صحيح | "...من كان يؤمن بالله واليوم الآخر فليصل رحمه" |
| `a9397166-f622-4384-942b-7c206bd41d68` | 102 | `Musnad Ahmad 7563` | NULL | حسن | "...صلة الرحم محبة في الأهل، مثراة في المال، منسأة في الأثر" |
| `a328ece9-dbf5-4bb6-b1dd-e79b29a3228f` | 103 | `Musnad Ahmad 16033` | NULL | حسن | "...إن أعجل الطاعة ثواباً صلة الرحم" |

(All 3 grades were already correct on prod from the original Wave 2 capture; only narrator + source needed updating.)

## Migration

[supabase/migrations/20260428300000_hadith_metadata_fill.sql](supabase/migrations/20260428300000_hadith_metadata_fill.sql)

### What it does

Three defensive `UPDATE` statements, each matching on (`display_priority`, English-substring of `source`, `narrator IS NULL`). The third predicate (`narrator IS NULL`) is the idempotency guard — re-running the migration after the rows are populated is a no-op because the WHERE clause no longer matches.

| Row | Match key | New narrator | New source |
|---|---|---|---|
| 101 | `display_priority=101 AND source LIKE '%Bukhari%6138%' AND narrator IS NULL` | `أبو هريرة` | `صحيح البخاري ٦١٣٨` |
| 102 | `display_priority=102 AND source LIKE '%Ahmad%7563%' AND narrator IS NULL` | `أبو هريرة` | `مسند أحمد ٨٨٦٨` |
| 103 | `display_priority=103 AND source LIKE '%Ahmad%16033%' AND narrator IS NULL` | `أبو بكرة` | `صحيح ابن حبان ٤٤٠` |

Reference number changes per founder + CTO research:
- Row 102: original 7563 not found in standard scholarly editions. Corrected to **مسند أحمد ٨٨٦٨** (al-Risala edition).
- Row 103: original Ahmad 16033 not found in standard editions; the hadith text is reliably cited from **صحيح ابن حبّان ٤٤٠** instead. Both narrator and source corrected.

### Self-verification block (DO $$ ... $$)

Aborts the transaction if any of:
1. Any `admin_hadith` row has `NULL narrator` after the fill (expected 0)
2. Any source matches `Bukhari` / `Ahmad` / `Sahih` / `Hibban` / any Latin-letter pattern (expected 0)
3. Each of the three target rows has the expected new `narrator` + `source` values (one assertion per row)

The migration applied without `RAISE` — all 3 assertions passed.

### Arabic comment block

The migration's header comment (per CTO standing order #4) documents in Arabic:
- That this corrects the Wave 2 capture
- The two original numbers (7563, 16033) didn't appear in standard editions
- Founder approved the corrections on 2026-04-27 with CTO research
- Cross-references: al-Risala edition for Ahmad 8868, Sahih Ibn Hibban 440 for the Abu Bakra hadith
- A pointer for future contributors to `git show` the Wave 2 source data

## Post-state (MCP-verified after `supabase db push`)

```
display_priority=101: source='صحيح البخاري ٦١٣٨'   narrator='أبو هريرة'  grade='صحيح'
display_priority=102: source='مسند أحمد ٨٨٦٨'      narrator='أبو هريرة'  grade='حسن'
display_priority=103: source='صحيح ابن حبان ٤٤٠'   narrator='أبو بكرة'   grade='حسن'
```

Aggregate checks:
- `SELECT COUNT(*) FROM admin_hadith WHERE narrator IS NULL` → **0**
- `SELECT COUNT(*) FROM admin_hadith WHERE source ~ '[A-Za-z]'` → **0**
- `SELECT COUNT(*) FROM admin_hadith` → 10

## Verification

| Check | Result | Verdict |
|---|---|---|
| `flutter analyze` | 6 issues (baseline) | ✅ no Dart touched |
| `flutter test test/unit/` | 1354 / 0 | ✅ no Dart touched |
| `supabase db push` (this migration) | applied cleanly; self-verify passed | ✅ |
| MCP post-apply: NULL narrators | 0 | ✅ |
| MCP post-apply: Latin-letter sources | 0 | ✅ |
| MCP post-apply: 3 target rows | match expected values verbatim | ✅ |

## Surprises

1. **Phase 6.1's CTO note about row 103's grade was inaccurate.** The Phase 6.1 prompt said "grade stays unchanged (already صحيح on prod)" for the row formerly Ahmad 16033, but the actual prod grade was `حسن` (and remains `حسن` after this migration — I didn't touch grade). The text is now sourced from Ibn Hibban 440 which al-Albani graded `صحيح`. Founder may want to update the grade column from `حسن` to `صحيح` to match Ibn Hibban's verification — flagged below as an open question.
2. **The Phase 6.1 plan's "5. The founder's research data" section had `[FOUNDER FILLS]` placeholders** that the Phase 6.2 prompt resolved. Two of the three reference numbers were **changed** during research (Ahmad 7563→8868 and Ahmad 16033→Ibn Hibban 440), not just looked up. The migration documents the change rationale in the Arabic comment.
3. **The defensive `narrator IS NULL` guard makes the migration genuinely idempotent**, not just safe-to-rerun. A re-run after the rows are filled matches zero rows and the self-verify still passes.

## Rows still missing data after this migration

The Content Audit Cat 4 originally flagged six metadata gaps: 3 in the Wave 2 rows (closed by this migration) plus 3 legacy rows lacking hadith numbers. Those 3 legacy rows are unchanged:

| display_priority | source | narrator | grade | Issue |
|---|---|---|---|---|
| 96 | `صحيح البخاري` | أبو هريرة | صحيح | 🟡 missing hadith number |
| 95 | `مسند الإمام أحمد` | علي بن أبي طالب | حسن | 🟡 missing hadith number |
| 94 | `سنن الترمذي` | أبو هريرة | حسن | 🟡 missing hadith number |

These are out-of-scope for Phase 6.2 per the prompt. Surfaced for CTO triage.

## Open questions for the CTO

1. **Row 103 grade.** The new source (صحيح ابن حبّان ٤٤٠) is graded `صحيح` by al-Albani — but the row's grade column is still `حسن` from the original Wave 2 capture. Want me to update grade column to `صحيح` in a follow-up, or leave as-is? Pure data decision, no urgency.
2. **The 3 unnumbered legacy rows (94, 95, 96).** Pattern matches the founder's research approach for the 3 Wave 2 rows. Worth a follow-up session with founder data, or punt to v1.1?
3. **Content audit closure.** With Phase 6.2 done, the audit's 4 categories are:
   - Cat 1 (English leakage): closed in Phase 6.0
   - Cat 2 (hardcoded copy): 16 🟡 candidates flagged for admin-table migration; deferred to post-TestFlight per CTO triage
   - Cat 3 (terminology): closed in Phase 6.1
   - Cat 4 (hadith): **closed except for 3 unnumbered legacy rows**, surfaced above
   
   Recommend declaring the audit closed with the open questions above tracked for v1.1.

## TestFlight readiness

Unchanged — app remains TestFlight-ready. This phase only updated 3 prod admin_hadith rows; no Dart, no code paths altered.
