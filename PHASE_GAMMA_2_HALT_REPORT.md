# Phase γ.2 — HALT before bulk seed

**Date:** 2026-05-03
**Status:** Halted at pre-flight. Bulk migration NOT applied. Awaiting CTO direction.
**Reason:** Substantial row-key divergence between source document and live database.

---

## The problem

The runbook anticipates partial key match ("if a row referenced in the document doesn't exist in the table, the UPDATE matches nothing — flag in report, don't INSERT speculatively"). What I found exceeds that anticipated case: **only 9 of 38 source-doc rows have a matching key in the live DB.** The other 29 would silently no-op.

A 9/38 bulk seed would (a) leave a skewed prompt corpus where 5 of 6 tables are partially seeded, (b) require the founder to interpret a confusing mismatch in the post-seed admin panel state, and (c) silently lose 29 carefully-authored prompt assets.

This is large enough to warrant a halt + decision rather than proceeding to bulk-apply with 29 silent skips.

---

## Per-table divergence

### `admin_ai_personality` — 5 doc rows ↔ 5 DB rows, **0 strict key matches**

| Source doc `section_key` | Live DB `section_key` |
|---|---|
| `core_identity` | `base` |
| `voice_and_register` | `style` |
| `interaction_patterns` | `precision` |
| `cultural_grounding` | `values` |
| `meta_behavior` | `emotional` |

Same row count, completely different keys. This is **almost certainly a wholesale rewrite intent**: the CTO designed a richer 5-section structure and gave each section a more descriptive name. Updating the existing 5 rows by *position* (e.g., `core_identity` content → `base` row) plus rewriting `section_name_ar` would produce the CTO's intended schema. But that requires a mapping decision I can't make unilaterally.

### `admin_ai_touch_points` — 7 doc rows ↔ 7 DB rows, **1 strict match**

| Source doc | Live DB | Match? |
|---|---|---|
| `home/greeting` | `home/greeting` | ✅ |
| `ai_hub/greeting` | (absent) | ❌ |
| `interaction/post_log` | (absent) | ❌ |
| `streak/break_consolation` | (absent) | ❌ |
| `occasion/reminder` | (absent) | ❌ |
| `weekly_report/intro` | (absent) | ❌ |
| `suggested_prompts/header` | (absent) | ❌ |

Live DB has 6 different surfaces the doc doesn't address: `home/priority_contacts`, `home/insight`, `relative_detail/health_explanation`, `relative_detail/conversation_starters`, `reminders/time_suggestion`, `reminders/frequency_recommendation`.

These appear to be entirely different touch-point taxonomies. Doc surfaces ≈ "render moments" (greeting, post-log, break-consolation). DB surfaces ≈ "AI-augmented widgets per screen" (priority contacts list, health explanation widget, conversation starters). They overlap by accident on `home/greeting`.

### `admin_counseling_modes` — 4 doc rows ↔ 4 DB rows, **1 strict match**

| Source doc | Live DB | Match? |
|---|---|---|
| `general` | `general` | ✅ |
| `scripture_grounded` | (absent) | ❌ |
| `writing_help` | (absent) | ❌ |
| `reflection` | (absent) | ❌ |

Live DB modes: `general`, `relationship`, `conflict`, `communication`. Same row count, different mode taxonomy. CTO's modes are about *how أنيس responds* (scripture-led, writing-helper, reflective). DB modes are about *what the user is dealing with* (relationships, conflicts, communication).

### `admin_message_occasions` — 12 doc rows ↔ 12 DB rows, **4 strict matches**

| Source doc | Live DB | Match? |
|---|---|---|
| `eid_fitr` | (absent — DB has `eid`) | ⚠️ rename |
| `eid_adha` | (absent — DB has `eid`) | ⚠️ rename — and there's only one `eid` row in DB, not two |
| `ramadan` | `ramadan` | ✅ |
| `condolences` | (absent — DB has `condolence` singular) | ⚠️ rename |
| `marriage` | (absent — DB has `wedding`) | ⚠️ rename |
| `newborn` | `newborn` | ✅ |
| `illness` | (absent) | ❌ |
| `recovery` | `recovery` | ✅ |
| `graduation` | `graduation` | ✅ |
| `travel` | (absent) | ❌ |
| `return` | (absent) | ❌ |
| `general` | (absent) | ❌ |

Live DB has 4 occasions the doc doesn't address: `birthday`, `checkin`, `apology`, `thanks`, `missing`. **4 are clean matches, 4 are renames, 4 are absent in DB.**

### `admin_communication_scenarios` — 6 doc rows ↔ 6 DB rows, **1 strict match**

| Source doc | Live DB | Match? |
|---|---|---|
| `apology` | `apology` | ✅ |
| `reconnect_after_long_absence` | (absent — DB has `reconnect`) | ⚠️ rename |
| `difficult_conversation` | (absent) | ❌ |
| `expressing_gratitude` | (absent — DB has `thanks`) | ⚠️ rename |
| `sharing_news` | (absent) | ❌ |
| `regular_check_in` | (absent — DB has `checkin`) | ⚠️ rename |

Live DB has 2 scenarios the doc doesn't: `condolence`, `congratulate`.

### `admin_message_tones` — 4 doc rows ↔ 4 DB rows, **2 strict matches**

| Source doc | Live DB | Match? |
|---|---|---|
| `warm` | `warm` | ✅ |
| `formal` | `formal` | ✅ |
| `brief` | (absent) | ❌ |
| `encouraging` | (absent) | ❌ |

Live DB has 2 tones the doc doesn't: `humorous`, `religious`.

---

## The numbers

| Table | Doc rows | Strict matches | Renames | Absent in DB | Live DB has extras? |
|---|---|---|---|---|---|
| `admin_ai_personality` | 5 | 0 | 0 | 5 | (5 with different keys) |
| `admin_ai_touch_points` | 7 | 1 | 0 | 6 | (6 different surfaces) |
| `admin_counseling_modes` | 4 | 1 | 0 | 3 | (3 different modes) |
| `admin_message_occasions` | 12 | 4 | 4 | 4 | yes (5 extras) |
| `admin_communication_scenarios` | 6 | 1 | 3 | 2 | yes (2 extras) |
| `admin_message_tones` | 4 | 2 | 0 | 2 | yes (2 extras) |
| **Total** | **38** | **9** | **7** | **22** | |

If the migration runs as-is with literal-key WHERE clauses: **9 rows updated, 29 silent no-ops.**

If renames are also performed (i.e., the engineer interprets `eid_fitr` → `eid`, `marriage` → `wedding`, `condolences` → `condolence`, etc.): **16 rows updated, 22 silent no-ops.**

If the engineer maps positionally (e.g., `core_identity` content → `base` row regardless of name match) for the same-row-count tables: **~26-28 rows updated**, but with judgment calls the runbook doesn't authorize.

---

## What's likely going on

The CTO's source document was authored against a **redesigned schema** the CTO had in mind, not against the schema currently live in production. There are three plausible histories:

1. **The doc author worked from a wishful schema.** The CTO drafted γ.2 content imagining the schema as it *should be* organized, and the engineer's job was supposed to include schema-renames + new-row inserts + obsolete-row archives. That work wasn't called out in this session's runbook.

2. **The doc author worked from outdated keys.** Earlier phase work (γ.1 inventory, γ.2-prep) referenced these tables but I don't see evidence in repo of an intent to rename existing rows. The doc keys look fresh-authored, not migrated-from.

3. **Naming drift only.** Some pairs (`marriage`/`wedding`, `condolences`/`condolence`) are obviously the same concept under different keys. Renames are easy. But `core_identity`/`base` is more than a rename — the doc has 5 sections of substantively different *intent* than the DB's 5 (e.g., `meta_behavior` vs `emotional` describe different scopes).

---

## Options for the CTO

### Option A — Schema migration first, then bulk seed
1. Author migrations to rename existing keys (`eid` → `eid_fitr` etc.), insert net-new rows (`scripture_grounded`, `interaction/post_log`, etc.), and archive/delete obsolete rows (`humorous` tone? `birthday` occasion? CTO's call).
2. Then bulk-seed γ.2 content via the same migration pattern as planned.
3. Highest correctness; most engineering work; gets the schema and content into one coherent state.

### Option B — Map content into existing keys
For same-row-count tables (personality, modes), update existing rows positionally, replacing both `*_key` and content. For different-taxonomy tables (touch-points), do nothing — the doc rows simply don't apply. For renamable rows (occasions, scenarios), apply renames inline.

This requires a CTO-authored mapping table. ~25-28 rows updated; cleanest single-migration outcome.

### Option C — Update the source doc to match live keys
Re-author γ.2 content using the existing DB keys (`base`, `style`, `emotional`, `home/insight`, `relationship` mode, etc.). Live schema stays. The new content fits into the old shape.

Lowest engineering work; risks losing CTO's intent for the new sectioning structure (e.g., the perspective-inversion guard in `core_identity` would land in `base`; the "voice and register" detailed work would land in `style` even though `style` is currently a 73-char one-liner about "ودي ومحترم").

### Option D — Accept the 9/38 partial seed
Run the literal-key bulk migration. 9 rows update, 29 stay as-is. Document which 29 didn't apply, ship anyway, founder iterates the rest manually. Aggressively partial. Not recommended.

### Option E — Hybrid (likely best)
- Strict-match: apply (9 rows: `home/greeting`, `general` mode, `ramadan`, `newborn`, `recovery`, `graduation`, `apology` scenario, `warm`, `formal`).
- Renames: apply if CTO confirms the rename pairs (likely 4 occasions + 3 scenarios).
- Same-row-count rewrites (personality, modes): require explicit CTO mapping decision — too consequential for me to map unilaterally.
- Truly absent (touch-points 6 of 7, modes 3 of 4): defer; CTO chooses Option A path for these or rewrites the doc to drop them.

---

## What I did NOT do (per "halt and report")

- Did **NOT** apply the bulk migration.
- Did **NOT** snapshot before-state (no point until we know what we're changing).
- Did **NOT** do the test-write on `brief` tone — the row doesn't exist, so the test as specified can't be performed.
- Did **NOT** run behavioral validation tests.

---

## What's safe to ship right now

The 9 strict-match rows could be seeded immediately with no risk:

- `admin_ai_touch_points` row `home/greeting` — replaces "أنت واصل" leak with the doc's content. **High value, low risk, single-row.**
- `admin_counseling_modes` row `general` — expands the one-liner to the doc's expanded version. Low risk.
- `admin_message_occasions` rows `ramadan`, `newborn`, `recovery`, `graduation` — they're all currently NULL `prompt_addition`, so any content is an improvement.
- `admin_communication_scenarios` row `apology` — currently NULL `prompt_context`, content is an improvement.
- `admin_message_tones` rows `warm`, `formal` — replaces 1-line modifiers with richer prose; modest risk of over-specification but reversible.

If the CTO wants me to ship just these 9 as a "γ.2-strict" partial seed and defer the rest pending direction, I can produce that migration in ~5 minutes. It would resolve the highest-priority Phase 6.1 leak (`home/greeting`) and unblock the founder's panel-iteration workflow on the established subset.

---

## Open questions for the CTO

1. **Is the source doc the new schema or content overlay on the existing schema?** Determines whether we go Option A (migrate schema) or Option C (rewrite doc). This is the crux question.

2. **Personality sections (5 ↔ 5):** Is the intent that `core_identity` *replaces* `base`, `voice_and_register` *replaces* `style`, etc. — i.e., the existing 5 rows get renamed AND rewritten in place? If yes, please confirm the mapping. My best-guess pairing was: `core_identity↔base`, `voice_and_register↔style`, `interaction_patterns↔precision`, `cultural_grounding↔values`, `meta_behavior↔emotional`.

3. **Touch-points:** Do the 6 doc-only surfaces (`ai_hub/greeting`, `interaction/post_log`, `streak/break_consolation`, `occasion/reminder`, `weekly_report/intro`, `suggested_prompts/header`) need to be added as new rows? If yes, do they need corresponding code wiring in `AITouchPointService` to actually fire? If no — i.e., they're vestigial concepts that didn't make the cut — should the doc drop them?

4. **Modes:** The CTO's 4 modes (`general`, `scripture_grounded`, `writing_help`, `reflection`) are oriented around *how أنيس responds*. The DB's 4 (`general`, `relationship`, `conflict`, `communication`) are oriented around *what the user is dealing with*. These are different paradigms. Pick one — keep DB's, restructure to doc's, or ship both as a 7-mode union?

5. **Occasions/Scenarios renames:** Confirm the rename pairs:
   - `eid_fitr` + `eid_adha` → both become `eid` (doc has 2, DB has 1 — content collision)
   - `condolences` → `condolence`
   - `marriage` → `wedding`
   - `reconnect_after_long_absence` → `reconnect`
   - `expressing_gratitude` → `thanks`
   - `regular_check_in` → `checkin`

6. **Should the strict-match 9-row partial seed go ahead now** as a "low-risk subset" while the larger structural decisions are made? The `home/greeting` `أنت واصل` leak fix alone is worth shipping standalone.

---

## Recommendation

Pause γ.2 bulk seed. Get CTO direction on questions 1–6 above. The likely answer is **Option E (hybrid)** — strict 9 + renames after CTO confirms + a separate schema-design conversation for personality/modes/touch-points where the structures differ.

If CTO authorizes the strict-9 partial seed as a hotfix-tier deliverable, I can ship it within the same session.

Tag CTO. Tag founder for awareness — they don't need to do anything until CTO decides.
