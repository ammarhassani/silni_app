# Phase δ.B — Pre-state inventory

**Date:** 2026-05-03
**Captured before:** any reconciliation action
**Source of truth:** `supabase_migrations.schema_migrations` on `bapwklwxmwhpucutyras`

---

## Summary numbers

| Side | Count |
|---|---|
| Local migration files (`supabase/migrations/`) | **51** |
| Remote applied migrations (`schema_migrations`) | **195** |
| Net divergence | **144 remote-only** + **0 local-only** + **timestamp-mismatched** |

---

## Three flavors of drift

### Flavor 1 — Pre-engagement remote-only (~75 migrations)

Remote rows from `2025-01-28` through `2026-02-06` that have no local file equivalent. These predate when the engineer started maintaining `supabase/migrations/` in the repo. ~70 of them have `name = NULL` in remote (they were applied directly to the DB without proper naming).

**Earliest:** `20250128100000 fix_profiles_sync_production`
**Latest in this band:** `20260206120000 family_sharing_hardening`

These are presumed to represent valid early-development migrations applied directly to the DB before the migration-files-in-repo convention was established. They aren't bugs — they're history that simply isn't reflected in the repo.

### Flavor 2 — Tracked-locally with timestamp drift (~7 migrations)

Both sides have these migrations applied, but the local file's timestamp prefix differs from what remote stored:

| Local file | Remote version | Same content? |
|---|---|---|
| `20260428500000_drop_gamification_stack.sql` | `20260427215557` `drop_gamification_stack` | yes |
| `20260428600000_drop_dead_user_columns.sql` | `20260428122913` `drop_dead_user_columns` | yes |
| `20260428610000_add_reminder_suppression.sql` | `20260428122926` `add_reminder_suppression` | yes |
| `20260428620000_self_node_on_signup.sql` | `20260428122948` `self_node_on_signup` | yes |
| `20260428630000_setup_complete_marker.sql` | `20260428123005` `setup_complete_marker` | yes |
| `20260428640000_seed_onboarding_ai_memory_rpc.sql` | `20260428123018` `seed_onboarding_ai_memory_rpc` | yes |
| **(no local file)** | `20260428161706` `onboarding_wizard_columns_and_seed` | — |

Plus:
| Local file | Remote version | Same content? |
|---|---|---|
| `20260503100000_seed_admin_ai_identity.sql` | `20260503095833` `seed_admin_ai_identity` | yes |

### Flavor 3 — γ.2 + δ.A per-row remote-only (38 migrations)

Applied via MCP `apply_migration` per-row (after bulk-apply timeouts on Arabic content per γ.2-prep surprise #1). **No local file equivalents** for any of these except γ.2 Track 1, which has a single bundled file (`20260503200000_seed_gamma_2_strict_match.sql`) representing 9 of these 10 remote rows in a different shape.

| Phase | Count | Range |
|---|---|---|
| γ.2-prep test/revert pre-flight | 2 | `20260503110011` – `20260503110043` |
| γ.2 Track 1 row writes + self-verify | 10 | `20260503110656` – `20260503111017` |
| γ.2 Track 3 row writes + self-verify | 24 | `20260503113903` – `20260503114720` |
| δ.A Task 1 + Task 5 | 2 | `20260503120551`, `20260503120838` |
| **Total γ.2+δ.A per-row** | **38** | |

These are the entries the runbook flagged as the immediate compounding-risk. Per CTO Approach A: don't try to bundle them into local files — accept that the audit trail lives in the engagement's reports + `MIGRATION_HISTORY_BACKUP_2026-05-03.sql`.

---

## Risk analysis

`supabase db pull` will generate a NEW migration file representing the current remote schema. Three possible outcomes:

1. **Pull succeeds and writes one large `<timestamp>_remote_schema.sql` file.** This is the expected Approach A outcome. The local migrations dir will then have:
   - All existing local files (preserved as historical breadcrumbs)
   - Plus one giant new file representing the current state diff
   - Going forward, `db push` will be no-op because the local dir matches remote

2. **Pull fails with "drift detected" error.** If the supabase CLI compares local file timestamps to remote `schema_migrations.version` and finds mismatches it considers conflicts, it'll refuse to proceed. We'd need to run `supabase migration repair --status reverted <list>` to mark conflicting versions as already-applied, then retry pull.

3. **Pull silently overwrites or removes local files.** This would be the worst outcome — local audit trail of what we wrote (Track 1 bundled file, etc.) gets clobbered. The runbook says "halt and report if the diff looks unexpected"; I'll watch for this.

---

## Mitigations in place

1. ✅ **Backup file:** [MIGRATION_HISTORY_BACKUP_2026-05-03.sql](MIGRATION_HISTORY_BACKUP_2026-05-03.sql) — manifest of all 195 remote migration entries, with recovery procedure.
2. ✅ **Reports preserved:** [PHASE_GAMMA_2_TRACK_1_2_REPORT.md](PHASE_GAMMA_2_TRACK_1_2_REPORT.md), [PHASE_GAMMA_2_TRACK_3_REPORT.md](PHASE_GAMMA_2_TRACK_3_REPORT.md), [PHASE_DELTA_A_CLEANUP_REPORT.md](PHASE_DELTA_A_CLEANUP_REPORT.md) all contain the per-row migration audit trail.
3. ✅ **Git working state:** δ.A's edits are uncommitted; pull operation should not affect those files. If it does, `git restore` resolves.

---

## Approach decision

Per CTO direction (Q4 in [PHASE_DELTA_A_CLEANUP_REPORT.md](PHASE_DELTA_A_CLEANUP_REPORT.md)) and the Session B runbook: **Approach A — `supabase db pull`**. Accept the divergence; let the local file become a current-state snapshot.

Halt-and-report triggers:
- Pull fails for any reason → halt
- Pulled diff includes unexpected schema (PII, deleted features, etc.) → halt
- `supabase db push --dry-run` reports pending changes after pull → halt (means pull didn't fully reconcile)
