# V1.1 Backlog

**Date:** 2026-05-03
**Status:** Active. Items here have explicit resurrection triggers; pull when triggered.

This is the deferred queue from the v1.0 engagement. Each item has:
- A reason it's deferred (not "we forgot")
- An explicit trigger ("do this when X happens")
- A pointer to the engagement report or PR where the deferral was decided

The active queue is empty; everything not in this file is shipped or actively in flight.

---

## 1. Token budget enforcement in `AIContextEngine`

**What:** [lib/core/ai/ai_context_engine.dart](lib/core/ai/ai_context_engine.dart) — `buildContext({tokenBudget: 2000})` advertises a budget parameter that is never read. Every relative + memory + occasion gets concatenated into the system prompt without truncation. Inventory finding §11.4.

**Trigger:** **Any production user has > 30 relatives.** Below that, prompts comfortably fit in the model's context window. Above that, the chat will start eating tail content and quality drops in ways the user can't see.

**Reference:** [AI_PROMPT_INVENTORY.md](AI_PROMPT_INVENTORY.md) §11 surprise 4.

**Estimated effort:** 1-2 days. Implementation: simple token estimator (`Arabic chars / 2.5`), accumulator pattern in context assembly, drop-priority order: older interactions → lower-priority distant relatives → older memories. Never truncate `admin_ai_personality`.

---

## 2. `home/greeting` touch-point UI wiring

**What:** The DB row `admin_ai_touch_points / home/greeting` has rich Phase γ.2 content but is **dormant** — no Flutter widget invokes `AITouchPointService.generate(screenKey: 'home', touchPointKey: 'greeting')`. Per [GAMMA_2_DB_CODE_VERIFICATION.md](GAMMA_2_DB_CODE_VERIFICATION.md): only `relative_detail/conversation_starters` is actively consumed.

**Trigger:** **When home-screen redesign goes on the product agenda.** Until then, the seeded content waits.

**Reference:** [PHASE_GAMMA_2_TRACK_3_REPORT.md](PHASE_GAMMA_2_TRACK_3_REPORT.md) §S4. [GAMMA_2_DB_CODE_VERIFICATION.md](GAMMA_2_DB_CODE_VERIFICATION.md).

**Estimated effort:** 0.5-1 day per surface. The wiring is small — `aiTouchPointDataProvider(request)` exists. The product call is what to render and where.

---

## 3. Dormant touch-points triage

**What:** 6 of the 7 DB touch-points have no code consumer (only `relative_detail/conversation_starters` is alive). The dormant ones: `home/greeting`, `home/priority_contacts`, `home/insight`, `relative_detail/health_explanation`, `reminders/time_suggestion`, `reminders/frequency_recommendation`.

**Trigger:** **Post-TestFlight, when real users surface AI-assisted-widget needs.** Don't pre-build widgets for surfaces nobody asks for. When users say "I wish the home screen suggested who to call today," wire `home/priority_contacts`. Etc.

**Reference:** [GAMMA_2_DB_CODE_VERIFICATION.md](GAMMA_2_DB_CODE_VERIFICATION.md) "Touch-points active-consumer audit".

**Estimated effort:** Per-surface ~1 day. Or decommission via `is_active = false` on rows that don't get user demand within 60 days post-TestFlight.

---

## 4. Sixteen hardcoded copy candidates (Content Audit Cat 2)

**What:** Per the earlier `CONTENT_AUDIT_FINDINGS.md` work, ~16 user-facing strings are hardcoded in widgets/screens that should live in the admin-controlled `admin_ui_strings` table for fast iteration without code deploys.

**Trigger:** **Post-TestFlight, when a marketing/copy-edit pass is needed.** Iteration on copy is highest-value when you have real users seeing the strings. Pre-TestFlight migration is busywork.

**Reference:** `CONTENT_AUDIT_FINDINGS.md` (if file exists) or the engagement's content-audit work. Engineer should grep for "Cat 2" / "Category 2" findings to locate.

**Estimated effort:** ~1 day to sweep all 16 + wire the affected widgets to read from `admin_ui_strings`.

---

## 5. Phone-invite subsystem reactivation

**What:** The phone-invite UI was cut in Phase 5. The database tables (`node_invitations`) and RPCs (`create_node_invitation`, `get_my_pending_invitations`) were preserved as dormant infrastructure. The RPC column-name bug (referencing `r.name` where the column is `r.full_name`) was fixed in Phase δ.A; the subsystem is now ready for reactivation.

**Trigger:** **Real users request "invite by phone" via TestFlight feedback.** Until users explicitly ask for it, the WhatsApp-link-share path is sufficient.

**Reference:** [PHASE_DELTA_A_CLEANUP_REPORT.md](PHASE_DELTA_A_CLEANUP_REPORT.md) Task 5.

**Estimated effort:** 2-3 days. Phone verification flow + invitation status UI + Twilio/SMS provider integration.

---

## 6. Notification topic-subscription infrastructure

**What:** FCM topic-publish + client-subscribe + offline reconciliation for per-category notification toggles. SharedPreferences keys for the toggles are preserved in the codebase for readback compatibility.

**Trigger:** **Users request per-category notification toggles.** Currently all notifications are on/off as a single switch.

**Reference:** Earlier engagement work (engineer should grep for `topic` / `subscribe` / `notification_topics` to locate the preserved scaffolding).

**Estimated effort:** 3-4 days. FCM topic registration + Flutter subscription state + reconciliation worker.

---

## 7. Inline weekly-report prompt migration to admin

**What:** The weekly-report screen ([lib/features/ai_assistant/screens/weekly_report_screen.dart:133-153](lib/features/ai_assistant/screens/weekly_report_screen.dart#L133-L153)) builds two AI prompts inline (insight + tip). They should live in admin-editable rows. Phase δ.A's runbook framing assumed `AIPrompts.weeklyReportPrompt` was the production const; live audit found that const was unused and the screen has its own inline prompts. Migration deferred.

**Trigger:** **When admin-editability of weekly-report prompts becomes a marketing/copy priority.** Until someone asks to edit them, inline-in-screen is fine.

**Reference:** [PHASE_DELTA_A_CLEANUP_REPORT.md](PHASE_DELTA_A_CLEANUP_REPORT.md) Task 6.

**Estimated effort:** Half-day. Two surfaces (`weekly_report/insight` + `weekly_report/tip`) with placeholder substitution similar to `relative_detail/conversation_starters`. Or one richer surface if the CTO prefers.

---

## 8. Reseed migration safety pre-flight

**What:** Per CONTRIBUTING.md, "applied migrations are immutable history." But future "reseed all admin tables" migrations could re-introduce stale content (legacy persona name `واصل`/`Wasel`, `premium` tier, dropped gamification rows) if written without auditing the historical seed sources.

**Trigger:** **Whenever a future "reseed all admin tables"-style migration is being authored.** Search-and-replace these stale tokens BEFORE writing the new reseed:
- `واصل` (legacy AI persona name) → `أنيس`
- `Wasel` (legacy English transliteration) → `Anees`
- `premium` (legacy subscription tier) → `max`
- Any gamification table references (level_titles, badges, points) — those tables are dropped; should not be reseeded.

**Reference:** [CONTRIBUTING.md](CONTRIBUTING.md) database migration rules; [PHASE_DELTA_A_CLEANUP_REPORT.md](PHASE_DELTA_A_CLEANUP_REPORT.md) §S2 + Q3.

**Estimated effort:** 5 min per reseed authored — just include the substitutions BEFORE INSERTing.

---

## How to use this file

1. When a trigger fires (e.g., a user reports they have 35 relatives and the AI is acting weird), open this file, scroll to the relevant item, follow the references.
2. When implementing, move the item out of this file into a phase report. Don't leave it here as "in progress" — it's either deferred (here) or active (a phase plan / GitHub issue).
3. When the trigger condition has been demonstrably stable for the v1 lifetime AND the item still hasn't fired, archive it with a "no longer relevant" note rather than deleting.

Keep this file lean. Items with vague triggers ("we should do this someday") are CTO-cruft, not backlog.
