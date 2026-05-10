# γ.2 — DB-vs-code verification

**Date:** 2026-05-03
**Audience:** CTO (γ.2 Track 3 design)
**Scope:** Map every divergent admin row to its actual code consumer (or lack thereof) before deciding what to seed/rename/insert.

---

## Touch-points table

`AITouchPointService.getTouchPoint(screenKey, touchPointKey)` is the only invocation surface. Below: every DB row's status + every doc-only surface's existence-check.

### 7 surfaces in DB

| Surface | Status | Active code consumer | Notes |
|---|---|---|---|
| `home/greeting` | **DORMANT** | — | No call site. Row content is read by nothing today. The Phase 6.1 `أنت واصل` leak (now fixed via Track 1 §1) was leaking only into the DB row, not into runtime AI prompts. |
| `home/priority_contacts` | **DORMANT** | — | No call site. JSON-output prompt suggesting prioritized contacts; nothing renders this. |
| `home/insight` | **DORMANT** | — | No call site. Daily-insight prompt; nothing renders this. |
| `relative_detail/health_explanation` | **DORMANT** | — | No call site. Per-relative health explanation prompt; nothing renders this. |
| `relative_detail/conversation_starters` | **ACTIVE** | [ai_conversation_starters_sheet.dart:63-94](lib/features/relatives/widgets/detail/ai_conversation_starters_sheet.dart#L63-L94) | The ONLY production touch-point. Invokes via `aiTouchPointDataProvider` with `screenKey: 'relative_detail', touchPointKey: 'conversation_starters'`. |
| `reminders/time_suggestion` | **DORMANT** | — | No call site. Prompt for picking the best reminder time. |
| `reminders/frequency_recommendation` | **DORMANT** | — | No call site. Prompt for suggesting reminder cadence. |

**Implication:** 6 of 7 DB touch-points are unwired. They exist as carefully-authored content but nothing in the Flutter app reads them. **Track 1's `home/greeting` seed updated content but did not change user-visible behavior** — the leak fix is correct housekeeping but won't show on real device. The only touch-point a user actually sees is `relative_detail/conversation_starters`.

### 6 surfaces in source doc but NOT in DB

| Surface | Confirmed absent in code? | How verified |
|---|---|---|
| `ai_hub/greeting` | ✅ Absent | Grepped variants `ai_hub.*greeting`, `hub.greeting`, `aiHubScreen` — none match a touch-point invocation. The AI hub screen file exists but does NOT call `AITouchPointService`. |
| `interaction/post_log` | ✅ Absent | Grepped `post_log`, `interaction_logged`, `after_log` — no matches. |
| `streak/break_consolation` | ✅ Absent | Grepped `streak.break`, `break_consolation`, `streak_lost` — only matches are unrelated streak-event constants in `analytics_events.dart` and `streak_event.dart` (not touch-point invocations). |
| `occasion/reminder` | ✅ Absent | Grepped `occasion.reminder`, `occasion_reminder` — no matches. |
| `weekly_report/intro` | ✅ Absent | Grepped `weekly_report.intro`, `weekly_intro` — no matches. (Weekly-report screen exists but uses `AIPrompts.weeklyReportPrompt` directly, not the touch-point system.) |
| `suggested_prompts/header` | ✅ Absent | Grepped `suggested_prompts.header`, `suggested_header`, `prompt_chip_header` — no matches. |

**Implication:** If the CTO seeds these 6 doc-only surfaces, **none would have a code consumer.** They would be inert until Flutter UI is wired to invoke them via `AITouchPointService.generate(screenKey: ..., touchPointKey: ...)`.

### Touch-points strict summary

- **1 active** consumer in production (`relative_detail/conversation_starters`)
- **6 dormant** rows in DB (content authored but unread)
- **6 absent** rows in doc that have no code path to read them if seeded

---

## Modes table

Mode selection is **fully automated** — there is no user-facing mode picker UI in the app.

### 4 modes in DB

| Mode key | Code consumer | Auto-selected when |
|---|---|---|
| `general` | `CounselingMode.general` enum value (hardcoded in [ai_models.dart:5-23](lib/core/ai/ai_models.dart#L5-L23)). Read by `AIPrompts.getDynamicModeInstructions('general')` — used in chat system prompt build. | Default; or when user just logged an interaction (celebration context) |
| `relationship` | `CounselingMode.relationship` enum value | Auto-selected when relative hasn't been contacted in 30-60 days (reconnection advice) |
| `conflict` | `CounselingMode.conflict` enum value | Auto-selected when relative hasn't been contacted in 60+ days (repair/reconciliation) |
| `communication` | `CounselingMode.communication` enum value | Auto-selected when relative has low interaction count (<3) |

Mode-selection logic in [ai_mode_detector.dart:40-75](lib/features/ai_assistant/services/ai_mode_detector.dart#L40-L75) — heuristic on `daysSinceLastContact` + `interactionCount`. The user does NOT select a mode; the system selects one based on what the user is dealing with.

### Code consumers of each mode

- **System prompt build:** [ai_prompts.dart:254](lib/core/ai/ai_prompts.dart#L254), [:293](lib/core/ai/ai_prompts.dart#L293) — `buildEnhancedChatSystemPrompt(mode, context)` uses `getDynamicModeInstructions(mode.name)` to inject the mode's `mode_instructions` from the DB.
- **Mode storage in conversations:** [ai_models.dart:146](lib/core/ai/ai_models.dart#L146) — `ChatConversation.mode` persisted alongside each conversation in `chat_conversations` table.
- **Display-only switches:** `chat_history_drawer.dart:525-534` (icon per mode), `persona_greeting_block.dart:23` (mode display in greeting block), `chat_message_bubble.dart:259-267` (case statement; widget appears unused in current chat surface).

### What does the user see for "mode"?

The current AI chat UI **shows** the active mode (in the persona greeting block subtitle, e.g., "محادثة عامة") but does NOT let the user change it. Mode is set automatically by `AIModeDetector.detect()` at message-send time per [ai_chat_screen.dart:94](lib/features/ai_assistant/screens/ai_chat_screen.dart#L94).

### Implication for the CTO's 4 modes (`general`, `scripture_grounded`, `writing_help`, `reflection`)

The CTO's modes are oriented around **how أنيس responds** (scripture-led / writing-helper / reflective). The DB's modes are oriented around **what the user is dealing with** (relationship state / conflict / communication gap). **They are different paradigms — switching to the doc's modes requires:**

1. **New enum values** — extend `CounselingMode` to include the 3 new modes (or replace 3 of the existing 4).
2. **One of:**
   - **Manual mode picker UI** — none exists today. Would need to be built into the chat screen (probably as a dropdown or chip row above the composer).
   - **Heuristic-extension to AIModeDetector** — extend the auto-detection to pick scripture/writing/reflection modes based on user intent in the message text. This is harder; would need NLU on the user's message before sending.
3. **Or hybrid** — keep the 4 user-state modes for auto-detection AND surface 3 user-pickable modes as overrides.

This is non-trivial code work, **out of γ.2 scope** as a content-only seed.

---

## Personality `precision` and `emotional` rows — current content (verbatim)

Per the runbook, the CTO will read these and decide whether to overwrite with `interaction_patterns` (doc §A.3) and `meta_behavior` (doc §A.5) content respectively.

### `admin_ai_personality` row `section_key = 'emotional'`

```
section_name_ar:  الذكاء العاطفي
content_ar:       تفهم مشاعر المستخدم وتتعامل معها بحساسية، وتقدم الدعم النفسي عند الحاجة.
length_chars:     72
updated_at:       2026-01-11 14:18:50.002404+00
```

### `admin_ai_personality` row `section_key = 'precision'`

```
section_name_ar:  الدقة والاختصار
content_ar:       تجيب بإيجاز ووضوح، وتتجنب الإطالة غير الضرورية. تركز على الفائدة العملية.
length_chars:     73
updated_at:       2026-01-11 14:18:50.002404+00
```

### CTO's intent for these rows (from doc §A.3 and §A.5)

The doc's `interaction_patterns` (§A.3) is a ~1500-char section covering how أنيس handles different question types — "كيف أفعل" vs "ما حكم" vs "ساعدني أكتب" vs confessions of failure vs general fadl-of-silat-rahim asks vs hard conversations. Substantively richer than the 73-char `precision` content.

The doc's `meta_behavior` (§A.5) is a ~1500-char section covering edge cases — when أنيس doesn't know the answer, when the user requests something out-of-scope, ambiguous questions, mental-health crisis handling, cross-conversation memory, and personality-drift requests. Substantively richer than the 72-char `emotional` content.

**The mapping decision is the CTO's:**
- Option A: Overwrite `precision` row with `interaction_patterns` content + new `section_name_ar = 'أنماط التفاعل'`. Same for `emotional` ← `meta_behavior` + `section_name_ar = 'السلوك في الحالات الخاصة'`.
- Option B: Insert two new rows (`interaction_patterns`, `meta_behavior`) with their content, leave `precision` and `emotional` alone. Now the DB has 7 rows.
- Option C: Merge. Append `interaction_patterns` content to the existing `precision` content (with a separator), same for `emotional`. Hybrid; messy.
- Option D: Decommission `precision` and `emotional` entirely; insert 2 new rows. Same row count (5), but with different keys.

Per the inventory's finding 11 (two duplicated personalities in the codebase) and the doc's intent that personality is the foundation of أنيس's character, **Option A or D feels right** — wholesale rewrite of the persona, not patching on top.

---

## Surprises

1. **`home/greeting` is dormant — Track 1's leak fix is housekeeping, not behavior change.** I had assumed the seeded `home/greeting` content would surface to users via the home screen's AI greeting widget. It doesn't — no widget reads it. The `أنت واصل` leak was leaking only into a DB row, not into actual model prompts. The fix is still correct (the row will surface to the model when/if a home-screen widget is wired), but it's not a user-visible improvement today.

2. **The mode taxonomy collision is bigger than it looks.** The CTO's modes orient on response *style*, the DB's on user *situation*. Both are valid; both are useful. A Track 3 design probably needs to keep both — one as auto-selected (situation), one as user-overridable (style).

3. **One of the doc-only touch-points (`weekly_report/intro`) duplicates an existing prompt.** The weekly-report screen already invokes `AIPrompts.weeklyReportPrompt` (a hardcoded const in `ai_prompts.dart:916-924`) — adding a `weekly_report/intro` touch-point row would create a parallel content path. CTO needs to decide: migrate the hardcoded const into the touch-points table, or leave the hardcoded const + drop the proposed touch-point row.

4. **The `relative_detail/conversation_starters` row has the strongest no-fabrication guardrails of any touch-point.** Per the inventory finding §1.5, this row's `prompt_template` already includes "لا تفترض أي معلومة غير مذكورة في البيانات أعلاه — لا تفترض وفاة أو مرض أو حالة اجتماعية أو أي شيء آخر". γ.2 should preserve those guards if the CTO authors a replacement.

---

## Recommendations for the CTO's Track 3 design

1. **Touch-points:** Don't seed the 6 doc-only surfaces yet. They have no code consumer. Track 3 should pair each new surface with the Flutter widget that invokes it; otherwise the rows just bloat the table.

2. **Modes:** Pick a paradigm. If keeping auto-detection (current behavior), don't add the doc's modes — they don't fit auto-detection well. If adding a user picker, a Track 3 spec should include the picker UI + enum extension. Either way, this is a code-touching session, not a content-seed session.

3. **Personality `precision`+`emotional`:** Option A (overwrite + rename) is cleanest. Sectional names matter because `fullPersonalityPrompt` interpolates them as `## ${section.sectionNameAr}:` — leaving them stale would produce visible drift in the system prompt header.

4. **`home/greeting` dormancy:** Either wire it into the home-screen UI, or accept it as a fix-in-place and move on. Wiring it would change Phase γ.2's product impact (a user-visible AI greeting on the home screen), so this is a product-design decision, not engineering housekeeping.

---

## Files referenced

```
lib/core/services/ai_touch_point_service.dart                           Touch-point service (only one)
lib/core/providers/ai_touch_point_provider.dart                         Riverpod wrapper
lib/features/relatives/widgets/detail/ai_conversation_starters_sheet.dart   ONLY consumer of any touch-point
lib/core/ai/ai_models.dart                                              CounselingMode enum (4 hardcoded values)
lib/features/ai_assistant/services/ai_mode_detector.dart                Auto-mode-selection heuristic
lib/features/ai_assistant/providers/ai_chat_provider.dart               counselingModeProvider (StateProvider)
lib/features/ai_assistant/screens/ai_chat_screen.dart:94                Where AIModeDetector.detect() is called
lib/core/ai/ai_prompts.dart:21,254,293                                  Mode-instructions injection into system prompt
```
