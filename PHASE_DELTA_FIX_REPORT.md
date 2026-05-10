# Phase δ.fix — Family-tree aunt/uncle misplacement bug

**Date:** 2026-05-03
**Status:** Shipped. Code (4 commits-worth of edits in one file), DB (migration applied), verification (analyze clean + DB self-verify passed).

---

## TL;DR

When an aunt or uncle was added BEFORE the matching same-side parent existed in the tree, `inferEdges` produced **zero** family_edges for that row. The relative was persisted, but with no graph linkage. Layout fell back to orphan placement and the relative landed in the wrong column. Founder's repro: عمتي فاطمة (paternal aunt) added before a father node existed → rendered on the maternal side.

Fix shape: three layers.

| Layer | Scope | Where |
|---|---|---|
| 1 — deepen aunt/uncle inference | new aunt/uncle adds with parent already present get `parent_of` from grandparents in addition to `sibling_of` | code: `inferEdges` aunt/uncle case |
| 2 — backfill on parent/grandparent adds | when a father/mother/grandfather/grandmother is added later, scan existing relatives and emit the now-missing edges for orphan aunts/uncles | code: `inferEdges` father/mother/grandfather/grandmother branches |
| 3 — historical backfill | one-time migration: every aunt/uncle row whose matching same-side parent already exists gets the missing `sibling_of` edge inserted | DB migration |

After all three: layout's `_enrichSiblingEdges` chains the rest at view time. No layout-side code changes needed.

---

## Files touched

```
EDIT  lib/features/family_tree/services/family_graph_service.dart      Phase δ.fix + δ.fix.2
NEW   supabase/migrations/20260503300000_backfill_orphan_aunts_uncles.sql                    Phase δ.fix
NEW   supabase/migrations/20260503310000_backfill_orphan_cousins_nephews_grandparents.sql    Phase δ.fix.2
NEW   PHASE_DELTA_FIX_REPORT.md   ← this file
```

`flutter analyze` on the edited file: 0 issues.

---

## Migration application

```
Applying migration 20260503300000_backfill_orphan_aunts_uncles.sql...
Finished supabase db push.
```

The verify `DO $verify$` block did not raise. That's the proof: zero aunt/uncle rows remain where a same-side parent exists but the `sibling_of` edge is missing.

### Migration false start (worth knowing for future authors)

`family_edges.from_id` and `to_id` are TEXT (not UUID) — set in `20260201140000_family_edges.sql`. `relatives.id` is UUID. The first push attempt failed:

```
ERROR: operator does not exist: text = uuid (SQLSTATE 42883)
```

Fix: explicit `::text` casts on every `relatives.id` in cross-table comparisons (the INSERT SELECT *and* the NOT EXISTS subquery). Now applied.

This is a latent migration-author trap — anyone joining `family_edges` to `relatives` on `from_id = relative.id` will hit the same error. Worth a CONTRIBUTING.md note someday; not blocking now.

---

## Verification done

| Check | Result |
|---|---|
| `flutter analyze` (edited file) | 0 issues |
| `supabase db push --dry-run` (pre-flight) | clean before push |
| Migration apply | success, no exception |
| Self-verify DO block (every aunt/uncle with same-side parent has sibling_of) | passed (`unfixable_count = 0`) |

---

## Verification NOT done

Manual cold-start of the app to confirm عمتي فاطمة is in the paternal column visually. The DB state proves the edge now exists; the layout's `_enrichSiblingEdges` chain then handles the rendering. But the visual end-to-end is the founder's call — open the tree, confirm the move, and if anything still looks wrong, ping with the case.

---

## Phase δ.fix.2 — extending the fix to the other same-shape cases

Triggered by founder asking to extend the fix to the cases originally flagged as "same-shape unverified". Re-audit of `inferEdges` confirmed the bug pattern in three more places. **All three now fixed** in the same commit-cluster.

| Case | Bug shape | Same-shape verdict |
|---|---|---|
| **Nephew/Niece added before any sibling** | `_findFirstSibling` returns null → empty edge list → orphan | ✓ Fixed: brother/sister case now backfills orphan nephews/nieces |
| **Cousin added before any uncle/aunt** | `_findFirstUncleOrAunt` returns null → empty edge list → orphan | ✓ Fixed: uncle/aunt case now backfills orphan cousins |
| **Grandparent added before matching-side parent** | `_findParentId` returns null → empty edge list → orphan | ✓ Fixed: father/mother case now backfills orphan grandparents on matching side |
| In-laws | Not modeled in enum | n/a — `RelationshipType` has no in-law variants |
| Great-aunts/uncles | Not modeled in enum | n/a — `RelationshipType` has no great_* variants |

The original report's flag of in-laws + great-aunts as latent bugs was wrong — those types simply don't exist in [lib/shared/models/relative_model.dart:19](lib/shared/models/relative_model.dart#L19). Removed from latent-bug list.

### Migration

[supabase/migrations/20260503310000_backfill_orphan_cousins_nephews_grandparents.sql](supabase/migrations/20260503310000_backfill_orphan_cousins_nephews_grandparents.sql) — three INSERTs (nephews/nieces → first sibling, cousins → first uncle/aunt, grandparents → matching-side parent), each idempotent, plus a self-verify DO block that counts remaining orphans of each shape and raises if any are non-zero. Applied cleanly to remote; verify passed (all three counts = 0).

### Code changes

In [lib/features/family_tree/services/family_graph_service.dart](lib/features/family_tree/services/family_graph_service.dart), three additional Layer-2 backfill blocks added:
- **brother/sister case**: scan existing nephews/nieces with no incoming `parent_of` and add `parent_of` newSibling→nephew. Skips nephews already linked to another sibling.
- **uncle/aunt case**: scan existing cousins with no incoming `parent_of` and add `parent_of` newUncle→cousin. Runs even when the uncle's own anchor (parent) is missing — cousin gets a parent floor regardless.
- **father/mother case**: scan existing matching-side grandparents (`paternal` for father, `maternal` for mother) and add `parent_of` grandparent→newParent if missing. Skips null-side grandparents (can't disambiguate without the side hint).

Each block uses the same dedup-via-existingEdges-scan pattern as the aunt/uncle Layer-2 fix.

### Tradeoffs accepted

- Migration uses **first sibling / first uncle by `created_at`** when picking an anchor for orphan nephews/cousins. The code's `_findFirstSibling` / `_findFirstUncleOrAunt` doesn't have a deterministic order; this is the most stable proxy. Semantic mismatch is possible (e.g. niece is actually the user's *sister's* daughter, but the migration links her to the user's *brother* because he was created earlier). The user can manually re-parent in-app if needed; the migration prefers "any anchor over no anchor" since orphan placement was the bug.
- Forward code change uses the same first-found behavior on subsequent adds. If user adds nephew first, then sister, then brother, the nephew gets linked to the sister (the first sibling added). User can re-parent if intent was the brother.

### Scope of `_findSpouse` and similar

Reviewed all NULL-anchor return paths in `inferEdges`:
- `_findParentForSide` (uncle/aunt) — Phase δ.fix
- `_findFirstSibling` (nephew/niece) — Phase δ.fix.2
- `_findFirstUncleOrAunt` (cousin) — Phase δ.fix.2
- `_findParentId` (grandparent) — Phase δ.fix.2

The `husband/wife` and `son/daughter` cases don't call any resolver — they always succeed (anchor is always the user themselves). Brother/sister cases call resolvers but only as **enhancements** (linking to existing father/mother for parent edges); the core sibling-of-user edge always succeeds, and `enrichAllSiblingEdges` propagates parent edges later if siblings are linked. So `brother/sister` doesn't need a "Layer 2 on father-add" fix — `enrichAllSiblingEdges` covers it. ✓

That accounts for every relationship type in the enum. Bug class is closed.

---

## Phase δ.fix.3 — verification audit (tests + shared-tree)

Triggered by founder asking for stronger assurance ("can you assure me I won't hear any bug regarding relative distribution"). Done: comprehensive test pass + shared-tree audit.

### Tests added — 16 total

[test/unit/services/family_graph_service_test.dart](test/unit/services/family_graph_service_test.dart) — 11 new tests in a `inferEdges — orphan recovery` group covering:
- father-add backfills siblingOf to existing paternal aunt orphan ✓
- mother-add backfills siblingOf to existing maternal uncle orphan ✓
- father-add does NOT backfill maternal aunt (wrong-side guard) ✓
- uncle-add deepens to grandfather (parentOf grandfather→uncle) ✓
- brother-add backfills parentOf to existing nephew orphan ✓
- sister-add does NOT re-parent nephew already linked to brother (idempotency) ✓
- uncle-add backfills parentOf to existing cousin orphan ✓
- aunt-add does NOT re-parent cousin already linked (idempotency) ✓
- father-add backfills parentOf from existing paternal grandfather orphan ✓
- father-add does NOT backfill maternal grandmother (wrong-side guard) ✓
- father-add skips null-side grandparent (cannot disambiguate) ✓

[test/unit/services/family_sharing_service_test.dart](test/unit/services/family_sharing_service_test.dart) — 5 new tests in the shared-tree generation group. These pin the property "list ordering doesn't matter":
- aunt-before-father order still yields aunt↔father siblingOf ✓
- grandfather-before-father order yields grandfather→father parentOf ✓
- cousin-before-uncle order yields uncle→cousin parentOf ✓
- nephew-before-brother order yields brother→nephew parentOf ✓
- full founder repro: aunt + father + grandfather in worst-case order ✓

All 110 tests in the combined unit-test pass.

### Shared-tree audit findings

[lib/features/family_groups/services/family_sharing_service.dart](lib/features/family_groups/services/family_sharing_service.dart) reviewed end-to-end:

| Function | Behavior | Same-shape risk? |
|---|---|---|
| `generateSharedEdges` (line 104) | Calls `inferEdges` per relative with `existingRelatives: relatives` (full list) | No — anchors are visible from the start; my Phase δ.fix Layer-2 backfills handle ordering bidirectionally. Tests prove it. |
| `verifySharedEdges` (line 150) | Explicitly does NOT re-infer (line 256 comment); only `enrichAllSiblingEdges` | No — propagation only, can't create orphans |
| `ensureRelativesInGroup` (line 357) | Returns early once self-node exists; subsequent adds go through normal `inferEdges` flow | No — covered by per-add fix |
| `initializeSharedTree` (line 21) | Calls `generateSharedEdges` then upserts with `onConflict='user_id,from_id,to_id,edge_type'` | No — DB-level dedup |

**Migration coverage:** the historical backfill migrations (Phase δ.fix + δ.fix.2) JOIN on `parent.user_id = aunt.user_id` and on `family_group_id` parity, so they correctly cover both personal-tree rows AND shared-tree rows. Cross-user linkage in shared trees is intentionally NOT done (semantically different relatives).

### Hygiene fix discovered during testing

A pre-existing test failed after Phase δ.fix because the uncle/aunt case's `siblingOf newRelative→parent` add had no dedup, while the father case's δ.fix backfill now also adds the same edge. In `generateSharedEdges` this creates duplicate FamilyEdge objects in the in-memory list (DB-side `ignoreDuplicates: true` upsert kept production safe — but the function should be cleaner).

Fix applied in `inferEdges`:
- **uncle/aunt case**: dedup the siblingOf add against `existingEdges` (both directions checked).
- **uncle/aunt case**: dedup the grandparent→uncle parentOf adds (the loop over existingEdges).
- **grandfather/grandmother case**: dedup the grandparent→parent parentOf add.
- **grandfather/grandmother case**: dedup the grandparent→aunt parentOf adds in the side-aware backfill.

These were latent — production was protected by the DB upsert, but the in-memory function now matches expected idempotency.

### What I can now assure

- The four NULL-anchor patterns in `inferEdges` produce correct edges in BOTH personal mode (each add via `inferEdges`) AND shared mode (`generateSharedEdges` loop). Pinned by 16 tests.
- Historical orphan rows are backfilled via two migrations (applied to remote, verify-DO blocks passed).
- `generateSharedEdges` is now idempotent at the in-memory level (no duplicate FamilyEdge objects).

### What I still cannot assure

- **Layout-side bugs**. My fixes only ensure correct EDGES. If `FamilyTreeLayoutService` mis-positions a relative whose edges are correct, that's an unrelated bug class.
- **Mutation-after-add** (changing relationship_type on existing relative) — edge cleanup not audited.
- **Deletion cascades** — what happens to descendants when a parent is deleted, not audited.
- **Relationship types not in the enum** — half-siblings, in-laws, adopted children — not modeled at all.

So: relative *distribution* via the bug class your عمتي فاطمة triggered is now firmly closed across personal AND shared trees, with regression tests. Other distribution bugs (layout-side, mutation, deletion) remain possible but are different shapes and would need separate fixes.

---

## What changed in code (one-paragraph summary)

`lib/features/family_tree/services/family_graph_service.dart`:
- **aunt/uncle case** (was: only `sibling_of` to parent; bug: no `parent_of` from grandparents): now also adds `parent_of` edges from any existing grandparents (the parents of the matched parent).
- **father/mother case**: after adding the standard parent edges, scans existing relatives for `aunt`/`uncle` of matching `family_side` with no `sibling_of` to the new parent — and adds the missing edges. This is the "I added the aunt first" recovery.
- **grandfather/grandmother case** (only when `side != null`): after adding the standard grandparent edges, scans existing aunts/uncles on the matching side and adds `parent_of` from grandparent → aunt/uncle. This handles "I added the aunt, then the grandparent, but not the parent yet."

Each of these is a tight ~10-line addition guarded by existing-edge dedup (`existingEdges.any(...)`). No restructuring.

---

## Cumulative engagement state (post δ.fix)

- **Active queue:** empty
- **v1.1 backlog:** unchanged (8 items in `V1_1_BACKLOG.md`); could add cousin/nephew/niece + in-laws + great-aunts/uncles as items #9-11 if/when relevant
- **Migration history:** local 158 = remote 158 (159 if you count this fix)
- **Codebase:** unchanged from δ.B except family_graph_service.dart

The founder is unblocked to verify in-app.
