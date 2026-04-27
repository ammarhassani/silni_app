---
name: Content Audit — findings
description: Severity-classified findings across 4 categories — English leakage, hardcoded copy, terminology consistency, hadith metadata. Investigation only.
type: project
---

# CONTENT AUDIT — Findings

**Date:** 2026-04-27
**Method:** 3 parallel general-purpose subagents (Cats 1, 2, 3) + copy-review extraction; Cat 4 (hadith) handled in main context via MCP + grep. No code changes.
**Companion file:** `COPY_REVIEW.md` — every user-facing Arabic string organized for human grading.

Severity legend: 🔴 launch blocker · 🟡 pre-launch worth fixing · 🟢 post-launch backlog · ⚪ documentation only.

## Executive summary

| Category | 🔴 | 🟡 | 🟢 | ⚪ |
|---|---|---|---|---|
| 1 — English leakage | 2 | 5 | 5 | 5 |
| 2 — Hardcoded copy | 0 | 16 | 11 | 2 |
| 3 — Terminology consistency | 3 (concepts) | 3 (concepts) | 0 | 0 |
| 4 — Hadith metadata | 0 | 5 | 1 | 4 |
| **Totals** | **5** | **29** | **17** | **11** |

### The 5 launch blockers

1. **`phone_verification_screen.dart:88`** — `e.message` raw English `AuthException` text shown in SnackBar after a failed OTP send.
2. **`phone_verification_screen.dart:93`** — `e.toString()` raw exception in SnackBar on unexpected error.
3. **Cat 3 — Reminder vs Notification mental model.** OS pushes titled `تذكير`, history screen labelled `الإشعارات`, schedule edit screen labelled `جدول التذكير` — three labels for what feels like one thing.
4. **Cat 3 — AI persona name collision.** `واصل` is the AI persona AND the gamification noun (used in badges, level titles, wrapped labels). User can't tell whether "واصل متمكن" is the AI's badge level or theirs.
5. **Cat 3 — Brand-name diacritic split.** `صِلني` (kasra, 19 sites) vs `صلني` (no diacritic, 11 sites — including paywall MAX, notifications screen, tree-share fallback) vs `صِلْني` (one MaterialApp title with extra sukun). User sees three brands.

### Highest-leverage prioritized fixes

1. Fix the 2 phone-verification SnackBar leaks (one-line edits each).
2. Pick a brand spelling and migrate the 11 sites to it.
3. Decide on the AI persona name (rename badge nouns OR rename the AI).
4. Standardize "reminder vs notification" terminology and apply across notification fallback titles.
5. Translate Android notification channel display names + descriptions.

---

## Category 1 — English leakage

### True user-facing leaks 🔴

| File:line | Current English | Where it surfaces | Suggested Arabic |
|---|---|---|---|
| [phone_verification_screen.dart:88](lib/features/auth/screens/phone_verification_screen.dart#L88) | `e.message` (raw `AuthException`, e.g. *"Phone number is invalid"*, *"Token has expired"*) | SnackBar after OTP-send failure on phone-verification screen | Route through `AuthService.getErrorMessage(e.message)` (already exists) or use `'تعذّر إرسال رمز التحقق. تحقق من الرقم وحاول مجدداً'` |
| [phone_verification_screen.dart:93](lib/features/auth/screens/phone_verification_screen.dart#L93) | `e.toString()` (raw English Dart exception format) | SnackBar on unexpected OTP error | `'حدث خطأ غير متوقع. حاول مرة أخرى'` |

### Worth fixing 🟡

| File:line | Current English | Where it surfaces | Suggested Arabic |
|---|---|---|---|
| [biometric_service.dart:123](lib/shared/services/biometric_service.dart#L123) | `'Unexpected error occurred'` | Surfaces via `login_screen.dart:189` SnackBar `result.errorMessage ?? 'فشل المصادقة البيومترية'` when biometric SDK throws non-PlatformException | `'حدث خطأ غير متوقع في المصادقة البيومترية'` |
| [biometric_service.dart:103](lib/shared/services/biometric_service.dart#L103) | `'Authentication failed'` | Returned when `local_auth` reports `isAuthenticated == false`. Currently no UI calls the `failed` branch, but reachable | `'فشل التحقق'` |
| [supabase_notification_service.dart:174,280,340,407](lib/shared/services/supabase_notification_service.dart) and [fcm_notification_service.dart:35,173,374](lib/shared/services/fcm_notification_service.dart) | `'Silni Notifications'`, `'Reminders'` (Android channel display names) + `'Notifications for Silni app'`, `'Reminders to contact relatives'` (descriptions) | Visible in **Android Settings → Apps → Silni → Notifications** category list | `'إشعارات صلني'`, `'تذكيرات'`, `'إشعارات تطبيق صلني'`, `'تذكيرات للتواصل مع الأقارب'` |

### Backlog 🟢 (debug/dev-only — not user-visible in release builds)

- [logger_overlay.dart:140,177,203,209,212,422,432](lib/shared/widgets/logger_overlay.dart) — `'Search logs...'`, `'Category'`, `'All'`, log-level names, `'Clear'`, `'Copy'`. Renders only when `kDebugMode && isVisible`.
- [error_boundary.dart:226-271](lib/shared/widgets/error_boundary.dart) — `_DebugErrorWidget` strings (`'Debug Error View'`, `'Exception'`, etc.). Renders only in `kDebugMode`; release path uses Arabic.
- [static_logo_generator.dart:242,252,274](lib/shared/widgets/static_logo_generator.dart) — `LogoExportScreen` is unreferenced. Dev tooling. Consider deleting.
- [semantic_labels.dart](lib/core/accessibility/semantic_labels.dart) — `*En` variant constants (homeTabEn, saveEn, etc.) are defined but unused (`grep` returns zero call sites). Dead code.

### Documentation-only ⚪

- [data_export_dialog.dart:54](lib/shared/widgets/data_export_dialog.dart#L54) — `'Silni - تصدير البيانات'` email subject mixes brand + Arabic. Brand can stay English; minor cosmetic.
- [biometric_service.dart:172,174](lib/shared/services/biometric_service.dart) — `'Face ID'`, `'Touch ID'` are Apple-trademarked names; keep English.
- [subscription_card.dart, theme_carousel.dart](lib/features/settings/widgets/) — `'MAX'` is the literal product-tier name; keep English.
- [relationship_inference_service.dart:236-237](lib/features/relatives/services/relationship_inference_service.dart) — LLM system prompt; never rendered to user.

### Phase 4 verification

The three email-hint sites Phase 4 fixed remain Arabic ([login_screen.dart:520, 873](lib/features/auth/screens/login_screen.dart), [signup_screen.dart:347](lib/features/auth/screens/signup_screen.dart#L347)). No regression.

---

## Category 2 — Hardcoded copy that should be admin-driven

### Worth fixing pre-launch 🟡 (high-churn copy)

| File:line | Excerpt (first 60 chars) | Admin table that could host |
|---|---|---|
| [paywall_screen.dart:43](lib/features/subscription/screens/paywall_screen.dart#L43) | `لا تنسَ أحداً — تذكيرات بلا حدود` | new `admin_paywall_copy` (or extend `admin_in_app_messages`) |
| [paywall_screen.dart:206](lib/features/subscription/screens/paywall_screen.dart#L206) | `لقد جربت واصل — مساعدك الذكي للعائلة` | new `admin_paywall_copy` |
| [paywall_screen.dart:253](lib/features/subscription/screens/paywall_screen.dart#L253) | `جرّب MAX مجاناً — ٠ ريال لمدة $trialDuration` | new `admin_paywall_copy` |
| [subscription_congrats_dialog.dart:121](lib/features/subscription/widgets/subscription_congrats_dialog.dart#L121) | `أنت الآن من أعضاء صلني المميزين` | new `admin_paywall_copy` |
| [send-scheduled-reminders/index.ts:201](supabase/functions/send-scheduled-reminders/index.ts#L201) | `حان وقت التواصل مع ${namesText}` (default body) | new `admin_notification_templates` |
| [check-streak-alerts/index.ts:75-76](supabase/functions/check-streak-alerts/index.ts) | `أقل من ساعة لحماية شعلة … يوم! تفاعل الآن` | new `admin_notification_templates` keyed by `streak_alert_*` |
| [send-smart-nudges/index.ts:113-119](supabase/functions/send-smart-nudges/index.ts) | `أنت تبني عناوين إشعارات عربية…` (LLM system prompt) | `admin_ai_modes` (or new `admin_ai_prompts`) |
| [occasion_message_service.dart:112-127, 130-132](lib/features/ai_assistant/services/occasion_message_service.dart) | `كل عام وأنت بخير يا {name}، عساك من عوّاده 🌙` (16 fallback messages: Eid Fitr, Eid Adha, Ramadan, National Day) | `admin_message_occasions` |
| [hadith_service.dart:23-100](lib/shared/services/hadith_service.dart) | 8 hadiths/quotes with English translations + narrators (duplicated fallback list) | `admin_hadith` / `admin_quotes` |
| [ai_identity.dart:33,98-118](lib/core/ai/ai_identity.dart) | AI greeting `السلام عليكم! أنا واصل…` + system prompt persona | `admin_ai_modes` |
| [ai_chat_provider.dart:728-746](lib/features/ai_assistant/providers/ai_chat_provider.dart) | 9 chat starter prompts (`كيف أتواصل مع أقاربي البعيدين؟` etc.) | new `admin_ai_suggested_prompts` |
| [weekly_report_screen.dart:133-157](lib/features/ai_assistant/screens/weekly_report_screen.dart) | LLM prompt template for the weekly report | `admin_ai_modes` |
| [proactive_insight_service.dart:113,196,215,245](lib/core/services/proactive_insight_service.dart) | `ما كلمت X من Y، وش رأيك تسلم …` (insight quips) | new `admin_insight_templates` |
| [islamic_calendar_service.dart:24-81](lib/core/services/islamic_calendar_service.dart) | 9 contextual nudges (`الجمعة يوم مبارك للتواصل مع الأهل 🤍`, `رمضان قرب…`) | new `admin_islamic_calendar_nudges` (or `admin_in_app_messages`) |
| [streak_milestone_modal.dart:118,121,133-135](lib/shared/widgets/streak_milestone_modal.dart) | `ما شاء الله! 500 يوم من حفظ الودّ` / `أنت قدوة في صلة الرحم — جزاك الله خير` | extend `admin_streak_config` with milestone copy |
| [reminder_template_service.dart:63,95](lib/core/services/reminder_template_service.dart) + [reminder_schedule_model.dart:252,267](lib/shared/models/reminder_schedule_model.dart) | Template descriptions (`للأقارب الأقرب…`) duplicated in two files | new `admin_reminder_templates` |
| [shareable_card_generator.dart:36-127](lib/shared/widgets/shareable_card_generator.dart) | Share text templates: `سلسلة $streak يوم من التواصل…` / `الحمدلله، حصلت على وسام…` / `ملخص $periodName: …` | new `admin_share_templates` |

### Backlog 🟢 (stable copy, low-churn)

- [onboarding_screen.dart:30,36,42,48](lib/features/auth/screens/onboarding_screen.dart) — `admin_onboarding_screens` exists; migration path is clear but not urgent.
- [content_config_service.dart:202-232,279-288](lib/core/services/content_config_service.dart) — 5 hadith fallbacks + quote fallbacks. Already DB-backed in `admin_hadith` / `admin_quotes`; in-code list duplicates DB seed.
- [interaction_type_inference_service.dart:59,61](lib/core/services/interaction_type_inference_service.dart) — time-of-day suggestion strings.
- [gamification_config_service.dart:493-513,554-563,730-782](lib/core/services/gamification_config_service.dart) — badge/level/challenge fallback list. Already DB-backed; offline fallback is intentional.
- [freeze_inventory_widget.dart:198](lib/shared/widgets/freeze_inventory_widget.dart#L198) — streak-protection explainer.
- [health_status_picker.dart:196-205](lib/shared/widgets/health_status_picker.dart) — 4 health-status hint sentences.
- [data_export_dialog.dart:434,468](lib/shared/widgets/data_export_dialog.dart) — GDPR + Saudi data-protection compliance copy (legal-adjacent; consider centralizing).

### Documentation-only ⚪

- [auth_service.dart:1389-1439](lib/shared/services/auth_service.dart) and [app_errors.dart:101-115](lib/core/errors/app_errors.dart) — ~12 auth/error message strings, some duplicated. Could centralize in `admin_ui_strings` (error namespace) but not urgent.
- [biometric_service.dart:131-149](lib/shared/services/biometric_service.dart) — 7 biometric error messages.

### Tables that don't yet exist but are referenced as targets

`admin_notification_templates`, `admin_paywall_copy`, `admin_ai_prompts`, `admin_ai_suggested_prompts`, `admin_insight_templates`, `admin_share_templates`, `admin_reminder_templates`, `admin_islamic_calendar_nudges`. Founder + CTO call: which of these are post-TestFlight admin work and which (if any) gate launch.

---

## Category 3 — Terminology consistency

### Concepts at 🔴 severity

#### "Reminder vs notification"

A user receives an OS push titled `تذكير` (reminder), opens the app, taps the bell, and lands on a screen labelled `الإشعارات` (notifications). Then edits a `جدول التذكير` (reminder schedule). Three labels for what feels like one thing.

Variants in `lib/`:
- `تذكير` / `التذكيرات` — ~45 sites, the scheduled object (correct)
- `إشعار` / `الإشعارات` — ~20 sites, the OS push (correct)
- `تنبيه` — 3 sites in [supabase_notification_service.dart:398](lib/shared/services/supabase_notification_service.dart), [ai_prompts.dart:963,984](lib/core/ai/ai_prompts.dart). **Bleeds across both concepts.**
- `تذكير` used as fallback push title — 6 sites in [fcm_notification_service.dart:60,397](lib/shared/services/fcm_notification_service.dart), [supabase_notification_service.dart:169,456](lib/shared/services/supabase_notification_service.dart). **Mixes the two: the OS thing is labelled with the scheduled-object noun.**

**Recommendation:** founder picks. Either: (a) `تذكير` = the user-created object only, `إشعار` = anything that arrives as an OS push (including scheduled reminders), so push titles read `إشعار: تذكير يومي`; OR (b) collapse to one term `تذكير` everywhere user-facing, with `إشعار` reserved for backend/admin-only.

#### "AI persona name collision"

`واصل` is both:
- The AI persona name (15+ sites; routed through `AIIdentity.name`).
- A gamification noun meaning "one who maintains ties" — used in badges (`واصل متمكن`, `واصل محترف`), level titles (level 10 = `واصل`), wrapped labels (`الواصل الدائم`, `واصل العائلة`).

A user reading the badge `واصل متمكن` could plausibly think it's the AI's badge level. The audit prompt assumed the AI persona was `هلال` — that name is **not used anywhere** in the code.

**Recommendation:** founder picks. Either rename the AI (e.g. to `هلال` as the audit prompt suggested), or rename the gamification badge prefix to a non-overlapping word (`الحريص`, `الموصول`).

#### "Brand-name diacritic"

| Spelling | Count | Notable sites |
|---|---|---|
| `صِلني` (kasra) | 19 | home title, AI prompts, invite link, most onboarding |
| `صلني` (no diacritic) | 11 | **paywall MAX**, **notifications screen**, **tree-share fallback**, profile dialogs, data-export |
| `صِلْني` (kasra + sukun on lām) | 1 | `main.dart:763` (window title `صِلْني - Silni`) |
| `Silni` | several | English/system contexts (fine) |

**Recommendation:** standardize on `صِلني`. The 11 plain-spelling sites are concentrated in paywall/notifications — high-visibility surfaces. The 1 sukun outlier is the app-switcher title; even more visible.

### Concepts at 🟡 severity

#### "Relative" / family member

Dominant: `قريب` / `الأقارب` (~80 sites). Sentimental synonyms leak in:

- `أحبائك` — [onboarding_screen.dart:30,36](lib/features/auth/screens/onboarding_screen.dart) (1 site, only on onboarding)
- `أحبابك` — [occasion_messages_screen.dart:70](lib/features/ai_assistant/screens/occasion_messages_screen.dart#L70) (1 site)
- `أحبتك` — [reminders_screen.dart:178,296](lib/features/reminders/screens/reminders_screen.dart) (2 sites, reminders body)
- `الأهل` / `أهلك` — ~10 sites in [home_screen.dart:167](lib/features/home/screens/home_screen.dart#L167), [islamic_calendar_service.dart:24,55](lib/core/services/islamic_calendar_service.dart), [streak_milestone_modal.dart:137](lib/shared/widgets/streak_milestone_modal.dart#L137), [ai_hub_screen.dart:81](lib/features/ai_assistant/screens/ai_hub_screen.dart#L81)
- `العائلة` / `أفراد العائلة` — used for the *unit* (tree, group, leaderboard); ~25 sites. Not interchangeable with `الأقارب`. Intentional.

**Recommendation:** keep `قريب`/`الأقارب` as canonical for the entity. Reserve `الأهل` for warm Friday/Eid voice intentionally; reserve `العائلة` for the unit. Retire `أحبائك`/`أحبابك`/`أحبتك` — sentimental synonyms with no distinct meaning.

#### "Interaction"

- `تفاعل` / `التفاعلات` — ~15 sites in [badge_prestige.dart](lib/core/utils/badge_prestige.dart), [gamification_config_service.dart](lib/core/services/gamification_config_service.dart), [todays_activity_widget.dart](lib/features/home/widgets/todays_activity_widget.dart). Umbrella noun used by **gamification**.
- `تواصل` (gerund/noun) — ~80+ sites everywhere else. Used by **everything outside gamification**.

Same data, two names. Subtypes (`زيارة`, `محادثة`, `مكالمة`, `اتصال`) are clean and intentional.

**Recommendation:** unify on `تواصل` for user-facing copy; keep `تفاعل` for gamification internals/logs only. Or vice versa.

#### "Streak"

Mostly clean — `سلسلة` everywhere user-facing. One outlier: AI internal context uses `شعلة` (flame) in [ai_prompts.dart:297,329](lib/core/ai/ai_prompts.dart) where the UI uses `سلسلة`. User normally doesn't see `شعلة` directly, but if the AI quotes its own context back ("شعلتك ١٢ يوم") the user will.

**Recommendation:** rename the AI prompt variable from `الشعلات` to `السلاسل`.

---

## Category 4 — Hadith content

10 hadiths in `admin_hadith` (DB), plus duplicated hardcoded fallback lists in [hadith_service.dart](lib/shared/services/hadith_service.dart) (8 entries) and [content_config_service.dart](lib/core/services/content_config_service.dart) (~5 entries). Surfaces in [home_screen.dart:54](lib/features/home/screens/home_screen.dart#L54) → [IslamicReminderWidget](lib/features/home/widgets/islamic_reminder_widget.dart).

### `admin_hadith` rows (MCP-introspected)

| display_priority | Source | Narrator | Grade | Issue |
|---|---|---|---|---|
| 103 | `Musnad Ahmad 16033` | **null** | حسن | 🟡 narrator missing; English source format |
| 102 | `Musnad Ahmad 7563` | **null** | حسن | 🟡 narrator missing; English source format |
| 101 | `Sahih Al-Bukhari 6138` | **null** | صحيح | 🟡 narrator missing; English source format |
| 100 | `صحيح البخاري ٥٩٨٦` | أنس بن مالك | صحيح | ⚪ complete |
| 99 | `صحيح البخاري ٥٩٨٨` | عبد الرحمن بن عوف | صحيح | ⚪ complete |
| 98 | `صحيح البخاري ٥٩٨٤` | جبير بن مطعم | صحيح | ⚪ complete |
| 97 | `صحيح البخاري ٥٩٩١` | عبد الله بن عمرو | صحيح | ⚪ complete |
| 96 | `صحيح البخاري` | أبو هريرة | صحيح | 🟡 missing hadith number |
| 95 | `مسند الإمام أحمد` | علي بن أبي طالب | حسن | 🟡 missing hadith number |
| 94 | `سنن الترمذي` | أبو هريرة | حسن | 🟡 missing hadith number |

### Findings

- **🟡 5 issues** — 3 rows missing narrators (the Wave 2 migrated rows), 3 rows missing hadith numbers in citation, citation format split between English and Arabic. (One row has both issues, hence 5 distinct fixes for 5 rows.)
- **🟢 1** — All hadith text uses classical narrator-style phrasing; none look paraphrased or modernized. Worth a human accuracy check by a religious advisor before launch but no flagged issues from the audit.
- **⚪ 4** — Rows 100, 99, 98, 97 are fully cited and graded; no action needed.

### Specific recommendations

1. **Standardize citation format.** Either Arabic-with-Arabic-Indic-numerals (`صحيح البخاري ٥٩٨٦`) for all 10 rows, or English (`Sahih Al-Bukhari 6138`) for all 10. Currently 3 are English (the Wave 2 migrated) and 7 are Arabic. Recommend Arabic for consistency with the rest of the app.
2. **Fill in narrator for the 3 Wave 2 migrated rows** (display_priority 101/102/103). The original `hadith` table dropped in Wave 2 didn't carry narrators — the founder may need to look up the standard narrator chains.
3. **Fill in hadith numbers** for the 3 rows currently citing only the book name (`صحيح البخاري`, `مسند الإمام أحمد`, `سنن الترمذي`). These should have specific reference numbers.
4. **Consolidate hardcoded fallbacks.** [hadith_service.dart](lib/shared/services/hadith_service.dart) (8 entries) and [content_config_service.dart](lib/core/services/content_config_service.dart) (5 entries) duplicate effort and drift from the DB. Trim to a 2-3 row safety net mirroring the DB seed (already covered in Cat 2 🟡).

### Religious-content human-review reminder

This audit does **not** grade hadith authenticity — that's the founder + a religious advisor's call. The 10 rows on prod have all been reviewed for citation completeness and grading metadata; substance review is out of scope.

---

## Cross-cutting findings

1. **AI-generated content surfaces use slightly different framing** — the `AIIdentity.name` (`واصل`) is referenced in prompt templates ([ai_identity.dart](lib/core/ai/ai_identity.dart)), but the surfacing copy ranges from "مساعدك الشخصي لصلة الرحم" (greeting) to "مساعدك الذكي للعائلة" (paywall) to "مستشارك الإسلامي" elsewhere. Three different framings of the same persona.

2. **Hadith fallbacks duplicated across two files** — [hadith_service.dart](lib/shared/services/hadith_service.dart) and [content_config_service.dart](lib/core/services/content_config_service.dart) both ship hardcoded hadith lists that have drifted from the `admin_hadith` DB seed. Consolidate.

3. **Brand spelling and AI persona name collide** — `صِلني` brand, `صلة الرحم` concept, `وصِل رحمك` brand pun, `واصل` AI persona, `واصل` gamification noun. The lexical neighborhood is crowded; future copy needs care.

4. **Notification copy is split across 3 stacks:**
   - Edge function defaults (`send-scheduled-reminders/index.ts:201`, `check-streak-alerts/index.ts:75-76`, `send-smart-nudges/index.ts:113-119`)
   - Local-notification fallbacks ([fcm_notification_service.dart:60,397](lib/shared/services/fcm_notification_service.dart), [supabase_notification_service.dart](lib/shared/services/supabase_notification_service.dart))
   - In-app templates ([notification_templates.dart:78-79](lib/core/constants/notification_templates.dart))
   
   No single source of truth. A single `admin_notification_templates` table would unify all three.

5. **Onboarding strings are duplicated.** `onboarding_screen.dart` (the 4-page carousel) AND `admin_onboarding_screens` (the table) AND `onboarding_config_service.dart` (fallback list) all have onboarding copy. Three copies that need to stay in sync.

## Open questions for the CTO + founder

1. **Brand spelling decision** — `صِلني` or `صلني` (no diacritic) or `صِلْني` (sukun)? Settle so launch copy is uniform.
2. **AI persona name** — keep `واصل` and rename gamification badges, OR rename the AI?
3. **`تذكير` vs `إشعار`** — pick a usage policy.
4. **Hadith citation format** — Arabic (`صحيح البخاري ٥٩٨٦`) or English (`Sahih Al-Bukhari 6138`)? Recommend Arabic.
5. **How many `admin_*` tables to add for v1?** Cat 2 surfaces 8 candidate new tables. None are launch blockers, but each one shipped post-TestFlight reduces app-update friction for copy edits.
