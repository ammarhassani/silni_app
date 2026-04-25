# PHASE 1 REPORT — Surface the Silent Features + Tail-end Phase 0 Cleanup

Branch: `phase-0-cleanup` (Phase 0 committed as `3585840`; Phase 1 work uncommitted on top).
`flutter analyze`: 8 pre-existing baseline issues (5 info-level underscore lints, 1 unused-element warning, 2 test-helper errors). **No new issues from Phase 1.**
`flutter test test/unit/`: **1349 passed, 4 pre-existing failures** in `family_graph_service_test.dart` and `relationship_label_helper_test.dart` (same as Phase 0; CTO-protected files). Test count dropped from 1366 → 1349 because the orphaned `auto_reminder_service_test.dart` was deleted with the service.

## Tail-end Phase 0 cleanup

### Cleanup 1 — Archive non-migration SQL files
- `git mv supabase/schema.sql → supabase/legacy/schema.sql`
- `git mv supabase/gamification_functions.sql → supabase/legacy/gamification_functions.sql`
- Both prepended with the exact header text the plan specified:
  `-- Historical bootstrap. Superseded by migration 20260425000000_runtime_rpc_definitions.sql. Kept for reference only — do not run against production.`

### Cleanup 2 — Delete AutoReminderService
- `git rm lib/core/services/auto_reminder_service.dart` (plan referenced `lib/shared/services/...` — wrong path; actual location was under `core/services/`).
- Confirmed via `grep -rn "AutoReminderService\|auto_reminder_service" lib --include="*.dart"`: zero remaining references.
- Also deleted the orphaned `test/unit/services/auto_reminder_service_test.dart` (caused 26 analyzer errors otherwise).

### Cleanup 3 — Stop AI memory extraction (privacy debt fix)
The plan said "find the side-effect call that persists extracted memories around line 109" but line 109 is just `ref.invalidate(aiMemoriesProvider)`, which is read-side cache invalidation. The actual extraction trigger was at the streaming-message completion (around the original line 500) inside `sendMessageStreaming`, calling `_extractAndSaveMemoriesAsync()`, which then called `_chatHistoryService.saveMemory()` (the actual `.insert` was at `chat_history_service.dart:213`).

Severance:
- `lib/features/ai_assistant/providers/ai_chat_provider.dart`: removed the trigger block that would call `_extractAndSaveMemoriesAsync()` after every 3rd assistant message. Replaced with the privacy-debt comment from the plan. Also removed the now-orphaned `_extractAndSaveMemoriesAsync` method, the `_assistantMessagesSinceExtraction`/`_memoryExtractionInterval` fields, and the now-orphaned helpers (`_isRelativeFact`, `_isInRelativesData`, `_isDuplicateMemory`, `_normalizeForComparison`, `_extractKeyTerms`, `_isCommonWord`).
- `lib/shared/services/chat_history_service.dart`: replaced `saveMemory(...)` body with `return null;` plus the privacy-debt comment. The method signature is preserved so the public `AIChatNotifier.saveMemory(...)` (which delegates here) doesn't crash for any caller I missed.
- `ai_memories` table is **not** dropped; existing rows survive intact. Future migration can clear or drop.

Net: the `ai_memories` table will not get any new writes from app code. The `getMemories()` read path still works (returns stored rows) but no UI surfaces them — those rows are now write-once historical data.

### Cleanup 4 — SKIPPED per plan STOP rule
Plan said "If grep finds any reference, STOP and report it before deleting." Grep output:
- `lib/features/gamification/widgets/stats/` (the entire directory) — zero external consumers ✓
- `lib/features/gamification/providers/stats_provider.dart` — **HAS a live consumer**: `lib/features/ai_assistant/screens/weekly_report_screen.dart:19,221` imports `detailedStatsProvider` and watches it.

Per plan instruction I stopped and did not delete anything in cleanup 4. The widgets dir alone could have been deleted (safe), but the plan grouped them and said STOP on any reference, so I treated the cleanup as a single unit. **Founder decision needed**: either (a) refactor `weekly_report_screen.dart` to compute its own stats inline so `stats_provider.dart` can go; or (b) keep `stats_provider.dart` and delete only the orphaned widgets dir; or (c) leave both in place as low-cost dead weight.

### Cleanup 5 — Remove sensors_plus dependency
- Removed `sensors_plus: ^6.1.1` from `pubspec.yaml:80`.
- `flutter pub get` reports clean. `pubspec.lock` will rewrite on next CI run; transitive `sensors_plus_platform_interface` will drop with it.

## Five surfacing fixes

### Fix 1 — Group Creation entry point
The plan said "header bar above" the canvas. The screen already had a `_buildShareTreeBanner` (a CTA card showing only when `groupInfo == null && relatives.isNotEmpty`) below the actual `_buildHeader`. I touched both for redundant discoverability:

1. **Banner button label** updated to plan wording: `'إنشاء مجموعة عائلية ✨'` (was `'إنشاء مجموعة'`).
2. **Header CTA**: added a `group_add_rounded` icon button (visible only when `groupInfo == null`) next to the share-tree icon. Tooltip: `'إنشاء مجموعة عائلية ✨'`.
3. **Profile section**: new `'👨‍👩‍👧 العائلة المشتركة'` section in `profile_screen.dart`, placed between Statistics and Account-actions. Uses `userFamilyGroupProvider` to switch states:
   - No group → `'إنشاء مجموعة عائلية ✨'` glass card → tap routes to `AppRoutes.createFamilyGroup`.
   - Has group → `'مجموعتي العائلية'` glass card → tap routes to `${AppRoutes.familyGroupDetail}/${groupId}`.

### Fix 2 — Group Join Migration Modal
Plan reference (`family_sharing_service.dart:21-96`) was off — that range is `initializeSharedTree` (admin first-create path, not a silent migration). The actual silent migration is `ensureRelativesInGroup` (lines 352-410), called once per session from `family_tree_screen.dart::_ensureRelativesMigrated` for the group admin only.

Implementation:
1. **`family_sharing_service.dart`**: added `bool migrateRelatives = true` param to `ensureRelativesInGroup`. When false, the call to `migrateRelativesToGroup(...)` is skipped but the self-node insert + member-link still run. Default is `true` so `initializeSharedTree` and any other internal/test caller keeps existing behavior.
2. **`family_tree_screen.dart::_ensureRelativesMigrated`**: now also reads `relative_id_in_tree` from `family_group_members`. If admin AND `relative_id_in_tree` is null (true first-time setup), calls a new `_resolveMigrationChoice(userId)` helper before invoking `ensureRelativesInGroup`.
3. **`_resolveMigrationChoice`**: checks `SharedPreferences.getBool('family_migration_choice')`. If set, returns the stored choice (no modal). Otherwise counts personal relatives (`family_group_id IS NULL`); if zero, returns false silently (nothing to ask about). Otherwise shows the modal with the exact plan strings:
   - Title: `'نقل أقاربك إلى الشجرة المشتركة؟'`
   - Body: `'الأقارب اللي عندك حالياً: $count. تبي تنقلهم للشجرة المشتركة عشان أهل المجموعة يقدرون يشوفونهم؟'`
   - Buttons: `[انقلهم]` / `[اتركهم منفصلين]`
4. The choice is persisted to SharedPreferences (global, not per-group, per plan: "don't ask again on subsequent group joins").

Edge cases handled:
- Already-migrated admin (has self-node) → service early-returns regardless, no modal.
- Joiner (not admin) → never enters the migration branch; existing logic.
- Zero personal relatives → no modal; defaults to false.
- Admin dismisses dialog (barrier-tap blocked, but back-button could) → defaults to false and persists that choice.

### Fix 3 — Log Interaction Toast
Plan pointed to `interactions_service.dart:48-85` but services have no UI context. The toast logic lives at the call site — specifically `relative_detail_screen.dart::_logInteraction`, the primary interaction-creation path. The other 5 callers (sync, quick-log, post-activity, relatives list quick-log, reminders-due) keep their existing minimal feedback; they're secondary surfaces and changing all six was scope creep.

After `repository.createInteraction(...)` succeeds:
1. Compute points via `gamificationService.calculateInteractionPoints(interaction)` — admin-config driven, matches what was actually awarded (modulo daily cap, which most users won't hit).
2. Read the just-updated streak via `relativeStreakService.getRelativeStreak(...)`.
3. Read relative name from the already-streamed `relativeDetailProvider`.
4. Check `streakDays` against `{7, 14, 30, 50, 100}` for milestone detection.
5. Build toast:
   - Milestone hit: `'✨ +$points نقطة · 🔥 وصلت لـ$streakDays يوم متواصل مع $name'`
   - Streak ongoing: `'+$points نقطة · 🔥 سلسلة $streakDays أيام مع $name'`
   - First interaction (no streak yet): `'+$points نقطة · تم تسجيل التواصل مع $name'`

Tradeoff: the streak read is a small extra DB roundtrip per log. For Phase 1's surfacing goal this is fine; a fuller refactor (service returns `InteractionLogResult`) was considered and rejected — it would have rippled through 6 callers and the repository for one feature.

### Fix 4 — AI-Generated Content Badge
New shared widget: `lib/shared/widgets/ai_generated_badge.dart` — a tiny `Text('✨ AI')` at 11pt with 0.55-alpha applied to the surrounding text color (subtle, secondary, per plan).

Placed at four sites:
- `lib/features/ai_assistant/widgets/conversation_message.dart` — next to the `AIIdentity.name` label inside every assistant message bubble (`_buildAIMessage`).
- `lib/features/ai_assistant/screens/weekly_report_screen.dart` — next to the `'ملخص [name]'` insight-card header AND the `'نصيحة الأسبوع'` tip-card header.
- `lib/features/ai_assistant/screens/communication_scripts_screen.dart` — under the relative-name line in the script-output header.
- `lib/features/wrapped/screens/monthly_wrapped_screen.dart` — below the personality-label text on the personality page (with an animated fade-in matching the surrounding choreography).

Not added to:
- AI Chat suggested prompts (they're admin-managed static text, not AI-generated).
- Wrapped share cards (rendered as social-share images; the badge would muddy the design).

### Fix 5 — Per-Relative Streak on Cards
Streak was only shown on the relative-detail header — not on the cards in the relatives list. Added now.

1. `lib/shared/widgets/swipeable_relative_card.dart`: new optional `streakDays` int param; renders `'🔥$streakDays'` in `AppColors.joyfulOrange` (matching the existing fire color) inside the secondary row, between `displayLabel` and the `needsAttention` hint.
2. `lib/features/relatives/screens/relatives_screen.dart::_buildRelativesList`: watches `allRelativeStreaksStreamProvider(userId)` once at list level, builds a `Map<String, int>` keyed by `relativeId`, passes the right value to each `_buildRelativeCard` call. **One stream subscription, O(1) lookup per card** — no per-card DB queries.
3. The card renders only when `streakDays != null && streakDays > 0`, so cards with no streak yet stay clean.

The home-screen `quick_log_faces.dart` and other surfaces that reuse `SwipeableRelativeCard` keep working — the new param is optional and defaults to null (no badge shown there). They can pass streaks later if useful.

## Surprises / questions for the CTO

1. **Plan-vs-FEATURE_TRUTH discrepancies on Fix 2**. The plan said "around line 21-96" but that's `initializeSharedTree` (admin create-group path), not the silent migration the plan was actually describing. I targeted `ensureRelativesInGroup` (lines 352-410) per FEATURE_TRUTH §2. Worth flagging the plan author so future plans are scoped to actual call paths.

2. **Cleanup 4 partial**. Stats widgets dir is dead, but `stats_provider.dart` is consumed by `weekly_report_screen.dart:221`. I respected the STOP rule and deleted nothing. Decision needed for Phase 2 or 3.

3. **`AutoReminderService` test deletion**. Plan didn't mention the test file; I deleted it because it caused 26 analyzer errors otherwise. Mentioning so it doesn't surprise anyone reviewing the diff.

4. **Memory writes via `chat_history_service.saveMemory`**. I no-op'd the body but kept the method signature (and the public `AIChatNotifier.saveMemory(...)` that calls it) intact. Cleaner long-term: delete both methods and audit all `_chatHistoryService.saveMemory` references. There are 2 call sites — the (now-deleted) `_extractAndSaveMemoriesAsync` and the public `saveMemory()` on the notifier (lines 973-983 of `ai_chat_provider.dart`). The public method has no external callers I could find via grep, but I left it for safety.

5. **Phase 1 toast at one call site only**. The interaction toast only fires from `relative_detail_screen`. Other call sites (quick-log faces on home, reminders-due, sync replay) don't get the enriched feedback. Phase 3 home cleanup may want to revisit.

6. **`pubspec.lock` will churn**. After the next `flutter pub get` (CI or local), the lockfile will lose `sensors_plus` + `sensors_plus_platform_interface` lines. Worth committing the regenerated lockfile in the same PR as the yaml change to keep CI clean.

7. **Streak stream load**. `allRelativeStreaksStreamProvider` adds one new realtime subscription per visit to the relatives list. The supabase realtime channel was already active (other features use streaks too) so the marginal cost is ~zero. Mentioning so it isn't a surprise on the metrics dashboard.

8. **AI badge on every assistant bubble** is intentional (plan said "anywhere AI generated visible text") but it does make every chat reply slightly busier. If founder finds it noisy in real use, easiest backout is to move the badge from per-bubble to once-in-the-app-bar.

## Summary

Phase 1 is complete. App compiles, analyzes clean (same baseline as Phase 0), 1349 unit tests pass with 4 pre-existing perspective-engine failures that were also present on `main` before Phase 0. The five silent features now have visible UI:

- Family group creation has 3 entry points (banner button, header icon, profile section).
- Personal-relatives migration on group create is no longer silent — admin gets a one-time prompt.
- Logging an interaction now shows points + streak + name with milestone celebration on 7/14/30/50/100.
- AI-generated content has the `✨ AI` tag on chat messages, communication scripts, weekly report (insight + tip), and the wrapped personality title.
- Each relative card shows `🔥N` when the per-relative streak is positive.

Plus tail-end Phase 0: sql files archived to `supabase/legacy/`, AutoReminderService gone for real, AI memory extraction stopped (privacy-debt resolved per CTO Path A), sensors_plus dependency removed.

Ready for founder review and Phase 2 authorization.
