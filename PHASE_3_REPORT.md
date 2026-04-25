# PHASE 3 REPORT — Settings, Paywall, Onboarding, Dark Patterns, Launch Artifacts

Branch: `main`. Six commits this phase, all linear:
- `a12020e` — Carryover 2: observability rename (analytics_service → analytics, error_handler_service → error_reporter)
- `b3518e6` — Task 4: dark patterns + 14 orphan home widgets gone
- `e4c229d` — Task 2: paywall feature list corrected
- `c686e0b` — Task 3: premium onboarding cut to 3 steps, auto re-show killed
- `dcc4a3a` — Task 1: Settings refactored into three labeled sections, slim MAX subscription row
- (this commit) — Task 6 launch artifacts + this report

`flutter analyze`: same 8 pre-existing baseline issues, no new errors.
`flutter test test/unit/`: **1349 passed, 4 failed** — same 4 pre-existing perspective-engine failures (see Task 5).

Codebase line count: 110,372 → **104,466** (−5,906 lines, −5.4% this phase).

## Carryover 2 — Observability rename ✅

`a12020e`. Renamed file paths to match the plan-canonical names; class names kept (`AnalyticsService`, `ErrorHandlerService`) to avoid 7+ file rename storm with zero behavior gain.
- `lib/core/services/analytics_service.dart` → `lib/core/services/analytics.dart` (+ canonical `trackEvent` and `trackScreen` thin wrappers added; existing `log*` methods stay).
- `lib/core/services/error_handler_service.dart` → `lib/core/services/error_reporter.dart` (+ canonical `report` and `breadcrumb` thin wrappers; existing `reportError` and `addErrorBreadcrumb` stay).
- 12 lib + 3 test import paths updated via sed.
- AppLoggerService, PerformanceMonitoringService, AppHealthService untouched per Phase 2 Path A.

## Carryover 1 — Config consolidation: DEFERRED to Phase 3.5

The CTO authorized splitting this off if needed. Doing so. Path B (merge the 5 small services) still requires reading 5 files at ~1,200 lines combined, designing the typed-getter shape, refactoring, and migrating 47 call-sites. Doing it cleanly in the same session as the UX work above would have either truncated the UX work or rushed the refactor.

The 5 candidates I'd target in 3.5: `cache_config_service.dart` (116 lines, 21 refs), `ui_strings_service.dart` (214 lines, 7 refs), `onboarding_config_service.dart` (267 lines, 5 refs), `content_config_service.dart` (300 lines, 9 refs), `app_routes_config_service.dart` (325 lines, 5 refs). The other five (ai_config, design_config, feature_config, gamification_config, notification_config) stay separate — they have rich domain shapes that don't compress into shared key-value getters.

## Task 1 — Settings refactor ✅

`dcc4a3a`. Reorganized `lib/features/settings/screens/settings_screen.dart` from 8 unlabeled rows + admin badge into **three labeled sections**:

| Section | Rows |
|---|---|
| الحساب (Account) | Profile (link), Change Password (canonical inline form preserved), Logout |
| التطبيق (App) | Theme picker, Notifications, Invite a friend, Rate the app |
| الاشتراك (Subscription) | SubscriptionCard (compact mode for MAX users) |

Helpers `_buildSectionHeader` and `_buildSettingsTile` dedupe the row boilerplate.

**SubscriptionCard slim mode**: added a `compact` boolean. When true and user is MAX, renders a single GlassCard row with a small crown badge, gradient `MAX` label, expiry/trial subtitle, and an inline `إدارة` button — no breathing border, no shimmer, no upgrade-CTA buttons. Free users still get the full upgrade card.

**Plan items I did NOT add — would be new features (standing order #5):**
- Language switch (no i18n switching feature exists in the app)
- Biometric Auth toggle (not implemented)
- About screen (doesn't exist)
- Trial Status display row (would need plumbing; the trial info is already in the SubscriptionCard subtitle)
- Delete Account row in Settings (already exists in `profile_screen.dart` via `ProfileActionsWidget`)
- Data Export row in Settings (same — already in profile)

The "duplicate rate-app prompt" the plan called out was the auto-fire `in_app_rate_prompt.dart` — Task 4 already deleted it. Settings had only one manual rate button to begin with. The staging/admin badge was already gated to admin email only — no fix needed.

## Task 2 — Paywall corrections ✅

`e4c229d`. Replaced the feature list at `paywall_screen.dart:575-582`. Old list had three stale entries:
- "كتابة الرسائل الذكية" (Message Composer — screen deleted in Phase 0)
- "تحليل العلاقات" (Relationship Analysis — screen deleted in Phase 0)
- "إحصائيات متقدمة" (Advanced Stats — screen deleted in Phase 0)

New list per plan, all five real and working:
1. مساعد الذكاء الاصطناعي (AI Chat)
2. سيناريوهات التواصل (Communication Scripts) — added
3. التقرير الأسبوعي (Weekly Report) — added
4. تذكيرات غير محدودة (Unlimited Reminders)
5. تصدير البيانات (Data Export)

`customThemes` was already absent from the list (free post-Phase-0). `smartRemindersAI` was already absent. `dataExport` was not labeled "coming soon" anywhere in `lib/`.

## Task 3 — Premium onboarding cleanup ✅

`c686e0b`. Carousel cut to exactly 3 steps:
1. AI Counselor (المستشار الذكي) — kept
2. **Unlimited Reminders (تذكيرات غير محدودة)** — added (replaced the deleted Communication Scripts step)
3. Weekly Reports (التقرير الأسبوعي) — kept

Communication Scripts is still a feature; just doesn't get its own onboarding step. Per the plan, it's discoverable from the AI Hub.

**Auto re-show killed:** `home_screen._checkPremiumOnboarding` removed entirely along with its imports of `onboarding_provider.dart` and `premium_onboarding_screen.dart`. The onboarding now triggers only after a successful purchase or restore in `paywall_screen.dart:759,795`. Once. Not on subsequent app opens regardless of completion state.

## Task 4 — Kill dark patterns ✅

`b3518e6`. **−3,624 lines.** This was the biggest dump of the phase.

The two named dark patterns:
- `lib/shared/widgets/session_paywall_interstitial.dart` — auto-fired for free users after a few app opens. **Deleted.** `_checkSessionPaywall` and its imports are out of `home_screen.dart`.
- `lib/shared/widgets/in_app_rate_prompt.dart` — auto-fired 3 seconds after home loaded. **Deleted.** `_checkRatePrompt` is gone. The manual "قيّم التطبيق" button in Settings is now the only rate prompt.

Plus 14 orphan home widgets that exported but had **zero call sites** in `lib/` or `test/`:

The four named in the plan:
- `family_tree_gap_card.dart`
- `setup_reminders_prompt.dart` + `setup_reminders_section.dart`
- `daily_priority_card.dart`
- `premium_upgrade_banner.dart`

Plus already-orphaned others I deleted while I was in there:
- `ai_briefing_card.dart`, `ai_insight_card.dart`, `ai_priority_contacts_widget.dart` — the Phase 1 paywall edits had been on dead code.
- `proactive_insight_card.dart`, `wrapped_entry_card.dart`, `frequency_carousel.dart` (and `FrequencyCarouselSkeleton` in `skeleton_loader.dart`), `family_pulse_indicator.dart`, `post_activity_card.dart`, `quick_log_faces.dart`.

Updated `widgets.dart` barrel to export only the 12 still-live home widgets.

**The plan asked for "ONE rotating priority slot" to replace the four nag cards. Skipped — and explicitly so.** None of the four nag cards were actually rendering on home post-Phase-0. The home is already nag-free. Adding a new rotating slot would be a NEW feature and violates standing order #5.

## Task 5 — Test cleanup: 4 failures investigated, filed for CTO call

The four pre-existing failures (in `family_graph_service_test.dart` lines 935, 945, 1199 and `relationship_label_helper_test.dart` line 180) have a single root cause:

`FamilyGraphService.getLabelForViewer` ([family_graph_service.dart:535-678](lib/features/family_tree/services/family_graph_service.dart)) currently returns `''` (empty string) at its fallback path on line 678. The function's own dartdoc on line 533 says it "Falls back to the relative's [fullName] if the graph path cannot..." — and the four tests assert exactly that documented behavior:
- For an unknown target id (not in `relativesMap`): expect `'قريب'` — currently gets `''`.
- For a known target with type `RelationshipType.other` and `fullName: 'أحمد'`: expect `'أحمد'` — currently gets `''`.
- For an unknown viewer with a known target: expect the target's `relationshipType.arabicName` (e.g., `'الأب'`) — currently gets `''`.

**The implementation has drifted from the documented spec and the test expectations.** The fix is small (~10 lines: read `relativesMap[targetId]?.fullName` and return that, fall back to `'قريب'` for unknowns, return `relationshipType.arabicName` for known targets when graph traversal fails).

Per CTO standing order #3 ("Perspective engine off-limits") and the plan's instruction ("If the underlying logic has drifted, file it for a CTO call"): **I did not modify the engine.** Filing here for the CTO call.

Tests left unchanged so the failure stays visible. They've been pre-existing since at least Phase 0 — every phase report has confirmed the same 4 failures.

**Recommendation for the CTO:** lift the perspective-engine off-limits rule for this specific ~10-line fallback restoration. The intent (the dartdoc) and the contract (the tests) agree; only the implementation has drifted. This is mechanical, not creative. If you OK it I can do it in Phase 3.5 alongside the config merge.

## Task 6 — Launch artifacts ✅

Three files generated:

- [`LAUNCH_SCREENSHOTS_LIST.md`](LAUNCH_SCREENSHOTS_LIST.md) — eight App Store screenshots in order (Home, Add Relative, Reminders, Family Tree, Log Interaction with toast, AI Chat, Wrapped, Profile) with one-line Arabic captions and capture instructions for each.
- [`LAUNCH_DESCRIPTION.md`](LAUNCH_DESCRIPTION.md) — App Store description in Arabic (~1,400 chars) and English (~1,400 chars). Benefits-first. Closes with the founder's pitch line: **صِلْني يذكرك بصلة رحمك ويحسبها لك**.
- [`LAUNCH_DEMO_SCRIPT.md`](LAUNCH_DEMO_SCRIPT.md) — 60-second screen recording script: cold open → Add Relative → Reminders schedule → ingest the new relative → Log Interaction → streak milestone toast → Wrapped → AI Hub → Family Tree → closing card. Arabic narration line-by-line, with timing cues and production notes.

## Phase 3 totals

- **6 commits** (5 code + 1 launch artifacts/report)
- **−5,906 lines** of dart (110,372 → 104,466)
- **−16 files deleted** (mostly orphan home widgets and the two interstitial files)
- **+5 files created** (`weekly_report_stats_provider.dart` was Phase 2; this phase: 3 launch artifacts + this report + `INVITATION_CONSOLIDATION_NOTES.md` was Phase 2)

Across the four phases since `a8a91d3`:
- 117,861 → 104,466 lines (−13,395, −11.4% of `lib/`)
- 19 commits
- 11 deleted screens, 4 deleted edge functions, 16 deleted home widgets, 9 deleted gamification stats widgets, 2 deleted dark-pattern files, 1 deleted statistics shim, 1 deleted auto-reminder service

## Open items for the CTO

1. **Perspective-engine fallback fix.** Task 5 documented drift. I'd like to lift the off-limits rule for this one ~10-line restoration. The tests document the intent and the dartdoc agrees.
2. **Phase 3.5 scope:** (a) the deferred config merge (5 small services into `remote_config_service.dart`, ~47 call-site migrations); (b) the perspective-engine fallback fix if approved; (c) anything else that surfaces from your review of this phase.
3. **`Phase 2 Task 2 (invitation consolidation)`** is still halted per [INVITATION_CONSOLIDATION_NOTES.md](INVITATION_CONSOLIDATION_NOTES.md). My recommendation remains Path A (keep both systems).

## TestFlight status

App compiles, analyzes clean (8 baseline issues, none new), 1349 of 1353 unit tests pass. The 4 failing tests assert documented intent that the implementation no longer satisfies; nothing in those tests blocks TestFlight functionality.

The home is nag-free. The paywall is honest about what users get. The premium onboarding is 3 steps and never re-shows. Settings is grouped and labeled. The AI Hub is a navigation grid, not a drama. The codebase is 11.4% lighter than where Phase 0 started.

**Founder: app is ready for TestFlight as far as Phase 3 is concerned.** Carryover 1 (config merge) is purely internal cleanup — it doesn't gate launch. The perspective-engine fallback drift is a pre-existing issue that wasn't introduced this cycle. Pull the trigger when you're ready.
