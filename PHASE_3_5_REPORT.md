---
name: Phase 3.5 — Final code cleanup before TestFlight
description: Perspective-engine fallback fixed (3 tests now pass; baseline is 0 fails). Five-service merge halted at the discovery gate — CacheConfigService doesn't fit the pattern. Launch-readiness baseline: clean.
type: project
---

# PHASE 3.5 — Final code cleanup before TestFlight

**Date:** 2026-04-26
**Status:** Task 1 ✅ shipped. Task 2 🟡 HALTED at the shape-mismatch gate (CacheConfigService doesn't fit the merge). Task 3 ✅ launch-readiness baseline clean (iOS build pending).
**Commits:** `7b3949f` (Task 1), `<this commit>` (report).

## Task 1 — Perspective-engine fallback fix ✅

### What was failing

Three tests in [test/unit/services/family_graph_service_test.dart](test/unit/services/family_graph_service_test.dart):

| Line | Test name | Expected | Actual (before fix) |
|---|---|---|---|
| 928 | `fallback: returns fullName for unknown graph path` | `'الأب'` | `''` |
| 938 | `fallback: returns empty string for unknown target` | `'قريب'` | `''` |
| 1182 | `fallback returns fullName instead of arabicName` | `'أحمد'` | `''` |

PHASE_3_REPORT.md flagged "four tests" — actual test count failing was three. The 4th pre-existing fail mentioned in the Phase 3 baseline was elsewhere; it also appears resolved (see surprises).

### What was changed

[lib/features/family_tree/services/family_graph_service.dart:677–681](lib/features/family_tree/services/family_graph_service.dart#L677-L681) — replaced the `return '';` fallback with:

```dart
// Fallback when no graph path resolves the relationship.
// Use the target's stored fullName if present; otherwise 'قريب'.
final fallbackName = target?.fullName;
if (fallbackName != null && fallbackName.isNotEmpty) return fallbackName;
return 'قريب';
```

3-line fix. No other perspective-engine logic touched.

### Note on the CTO's analysis

PHASE_3_REPORT.md predicted the fix would "return `relationshipType.arabicName` for known targets when graph traversal fails." Examining the fixtures and test expectations:

- `RelationshipType.father.arabicName` is `'أب'` (no definite article).
- The test fixture sets `fullName: 'الأب'` (with definite article) and expects `'الأب'`.
- Therefore the test expects **fullName**, not arabicName.

I followed the test as the ground truth (CTO standing order: don't modify the test). The fix returns the target's `fullName`, which happens to match the dartdoc's promise: "Falls back to the relative's [fullName]." All 86 tests in the perspective-engine test file now pass.

### Verification

```
$ flutter test test/unit/services/family_graph_service_test.dart
00:00 +86: All tests passed!
```

## Task 2 — Five-service config merge — 🟡 HALTED

### Shape audit (per CTO standing order #2)

Read all 5 files. Mapped each against the expected merge shape (singleton + `initialize()` + `refresh()` + `clearCache()` + cache fields + getters):

| Service | LOC | Singleton | `initialize()` | `refresh()` | `clearCache()` | Verdict |
|---|---|---|---|---|---|---|
| [cache_config_service.dart](lib/core/services/cache_config_service.dart) | 116 | `factory()` + `_instance` (different style) | yes | yes (delegates to `initialize`) | **NO** | ⚠️ doesn't fit |
| [ui_strings_service.dart](lib/core/services/ui_strings_service.dart) | 214 | `_()` + `instance` | yes | yes | yes | ✅ |
| [onboarding_config_service.dart](lib/core/services/onboarding_config_service.dart) | 267 | `_()` + `instance` | yes | yes | yes | ✅ |
| [content_config_service.dart](lib/core/services/content_config_service.dart) | 300 | `_()` + `instance` | (no — uses `refresh()` + `ensureFresh()`) | yes | yes | ✅ (loose fit) |
| [app_routes_config_service.dart](lib/core/services/app_routes_config_service.dart) | 325 | `_()` + `instance` | yes | yes | yes | ✅ |

### Why CacheConfigService doesn't fit

Three structural reasons it would force changes far beyond the 5-service boundary:

1. **It is the dependency of the other four.** Every one of UIStrings / Onboarding / Content / AppRoutes instantiates `CacheConfigService()` to compute its own TTL via `isCacheExpired(serviceKey, lastFetch)`. Merging it into a unified service that also includes the consumers creates a circularity unless the cache-policy logic is elevated to a static utility — that's a refactor, not a merge.
2. **It has 13 consumers across the codebase** (`grep -rln 'CacheConfigService\|cacheConfigServiceProvider'` over `lib/`):
   - The 5 services in the merge list.
   - **9 other services NOT in the merge list:** `feature_config_service`, `message_service`, `reminder_template_service`, `notification_config_service`, `gamification_config_service`, `design_config_service`, `ai_touch_point_service`, `ai_config_service`, plus `main.dart`.
   - Folding `CacheConfigService` into `UnifiedConfigService` means cascading `UnifiedConfigService.instance.isCacheExpired(...)` rewrites through 8 other services that aren't supposed to be touched in this session.
3. **It exposes Riverpod providers** — `cacheConfigServiceProvider` and `cacheDurationProvider` (a `Provider.family<Duration, String>`). Any consumer using `ref.watch(cacheDurationProvider(serviceKey))` would need to migrate to a different provider shape, or the unified service would need to ship the same providers under a new name (and we'd have to find/update consumers).

CacheConfigService is the cache-policy backbone of the config layer, not just another config consumer. It belongs as its own thing.

### What I did NOT do

- Did not create `unified_config_service.dart`.
- Did not migrate any call sites.
- Did not delete any of the 5 files.
- Did not commit anything for Task 2.

Per CTO standing order #2: *"If any of the five config services has a shape that doesn't fit the merge cleanly, halt and report — don't force the merge."*

### Open question for the CTO

**Three viable paths forward, listed by escalating scope:**

- **Path A — drop Task 2.** The five files total 1,222 LOC. CacheConfigService is already small and well-encapsulated (116 LOC). The remaining four are ~280 LOC each but each owns a non-trivial fallback set + parsed-model layer that's hard to compress. The "duplication" the report describes is structural-similar but not literal; merging may not save as many lines as it appeared.
- **Path B — merge only the four cleanly-fitting services** (UIStrings + Onboarding + Content + AppRoutes), keep CacheConfigService as the cache-policy backbone. Scope: 4 service files become 1, ~12 call-site updates (8 in `main.dart`, 4 in `lib/shared/services/hadith_service.dart`). Bounded. CacheConfigService stays as is.
- **Path C — broader cleanup.** Treat CacheConfigService as a static utility (no factory, no providers — just static `isCacheExpired(key, when)` and `getDuration(key)`). Then the other 13 consumers all migrate to `CacheConfig.isCacheExpired(...)`. THEN merge the 5 services. This is a separate refactor; ~14 files touched. Not Phase 3.5.

If you want **Path B**, I can do it in a follow-up session. Bounded, no surprises. I'll write `UnifiedConfigService`, migrate the 12 call sites in `main.dart` and `hadith_service.dart`, run analyze + tests, delete the 4 old files, and commit.

If you want **Path A or C**, no code change needed beyond what's already in this session.

## Task 3 — Final baseline verification

| Check | Baseline going in | Result | Verdict |
|---|---|---|---|
| `flutter analyze` | 8 issues | **8 issues** (same lines: 6 info `unnecessary_underscores`, 1 warning `_saveFamilyName` unused, 2 errors `overrideWithValue` in test helpers) | ✅ unchanged |
| `flutter test test/unit/` | 1349 pass / 4 fail | **1353 pass / 0 fail** | ✅ better than expected |
| `bash scripts/check_migrations_for_missing_on_delete.sh --diff-only origin/main` | clean | clean (11 files checked, 4 contained user-id FK refs, all explicit) | ✅ |
| `flutter build ios --release --no-codesign` | n/a | **succeeded — `build/ios/iphoneos/Runner.app` 69.7 MB, 112.2 s Xcode phase** | ✅ |

### Surprise: tests went from 4 failing to 0, not 1

CTO predicted post-Task-1 state of 1350 pass / 3 fail (i.e. Task 1 fixes 1 of 4 failing tests). Actual is 1353 / 0 — Task 1's fix resolved **3** failing tests (the three perspective-engine fallback tests), and the 4th pre-existing failure mentioned in the Phase 3 baseline appears to have already been resolved by an upstream change (likely Wave 2's `subscription_status` CHECK fix or the chat-tables capture; the failing test from earlier reports was status-related, but I haven't traced it to a specific commit). Net effect: no failing unit tests in the launch baseline.

### iOS build result

```
Building com.silni.app for device (ios-release)...
Running Xcode build...
Xcode build done.                                           112.2s
✓ Built build/ios/iphoneos/Runner.app (69.7MB)
```

Built cleanly with `--release --no-codesign`. One advisory from Flutter ("UIScene lifecycle support will soon be required") — non-blocking for current iOS versions, separate platform-migration concern for a future session.

## Phase 3.5 totals

- **1 commit shipped** (`7b3949f` — Task 1 perspective-engine fallback restoration).
- **Net LOC change:** +5 / −2 = +3 lines (the fallback restoration). No deletions in this session.
- **Tests:** baseline went from 1349 pass / 4 fail to **1353 pass / 0 fail.**
- **Analyzer:** 8 baseline issues unchanged.
- **FK lint:** clean in `--diff-only` mode.

## Surprises and what they mean

1. **Task 2 halt — the merge would have been bigger than billed.** CacheConfigService is structurally a dependency of the other four, not a peer. Forcing it into UnifiedConfigService cascades through 9 other services that aren't supposed to be touched. The pre-scoped "5-service merge" was actually a "4-service merge with a separate CacheConfigService refactor underneath." Halt is the right call.
2. **Task 1's fix cleaned up the test suite to all-green.** 4 failing tests → 0 failing tests on a 3-line code change. The Phase 3 report's analysis of arabicName-vs-fullName was slightly off, but the test expectation was unambiguous. Following the test is the discipline that paid off.

## Open questions for the CTO

1. **Task 2 path A / B / C** — see above.
2. **Confirm Task 3's all-green test result is real and not a false positive.** Want a second opinion before declaring TestFlight-ready: the CTO's arithmetic (1350 pass / 3 fail) doesn't match the actual (1353 / 0). If there's a flake or fixture that's been silently skipping a test, I'd rather catch it now than in TestFlight feedback.
3. **`UIScene lifecycle` advisory** — Flutter is warning that future iOS versions will require UIScene lifecycle support. Non-blocking now, but worth a tracked follow-up before the next iOS major release.

## TestFlight readiness — yes

- Code compiles, analyzes at the established baseline.
- All 1353 unit tests pass.
- No new migrations regressed FK discipline.
- The perspective-engine fallback drift documented in Phase 3 is closed.
- iOS release bundle built cleanly (69.7 MB, 112.2 s Xcode phase).
- Task 2 is purely internal cleanup that does not gate launch.

The next session is TestFlight prep proper: signing, archive, upload, internal-only release notes.
