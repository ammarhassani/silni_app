# Silni Intelligence & Growth Engine — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform Silni from a manual family tracker into an intelligent, shareable, multiplayer family connection platform that grows organically through word-of-mouth.

**Architecture:** Flutter app (Riverpod state management, Supabase backend) with event-driven gamification, remote-configured UI strings, and an existing celebration modal system. Changes span models, services, providers, screens, widgets, database migrations, and edge functions.

**Tech Stack:** Flutter/Dart, Riverpod, Supabase (Postgres + Edge Functions), Firebase (FCM, Analytics), share_plus, app_links, home_widget, speech_to_text, confetti

**Design Doc:** `docs/plans/2026-02-01-intelligence-and-growth-design.md`

---

## Phase 1: Quick Wins (No structural changes, high impact)

### Task 1: Notification Copy Overhaul to Saudi Dialect

Transform notification text from formal app-speak to natural Saudi Arabic dialect. The `admin_ui_strings` system already supports remote strings — we add hundreds of variations and rotate them.

**Files:**
- Create: `supabase/migrations/YYYYMMDD_notification_dialect_strings.sql`
- Create: `lib/core/constants/notification_templates.dart`
- Modify: `lib/shared/services/fcm_notification_service.dart`
- Modify: `lib/core/services/ui_strings_service.dart`
- Test: `test/unit/services/notification_templates_test.dart`

**Step 1: Write test for notification template selection**

```dart
// test/unit/services/notification_templates_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:silni/core/constants/notification_templates.dart';

void main() {
  group('NotificationTemplates', () {
    test('returns dialect reminder for 3-day gap', () {
      final text = NotificationTemplates.getReminder(
        relativeName: 'عمك سعد',
        daysSinceContact: 3,
      );
      expect(text, isNotEmpty);
      expect(text, contains('عمك سعد'));
      // Should not contain formal Arabic patterns
      expect(text, isNot(contains('تذكير:')));
    });

    test('escalates tone for 14-day gap', () {
      final text = NotificationTemplates.getReminder(
        relativeName: 'أبوك',
        daysSinceContact: 14,
      );
      expect(text, contains('أبوك'));
      expect(text, contains('أسبوعين'));
    });

    test('heavy tone for 30-day gap', () {
      final text = NotificationTemplates.getReminder(
        relativeName: 'جدتك',
        daysSinceContact: 30,
      );
      expect(text, contains('جدتك'));
      expect(text, contains('شهر'));
    });

    test('returns different text on subsequent calls (rotation)', () {
      final texts = List.generate(10, (_) =>
        NotificationTemplates.getReminder(
          relativeName: 'أمك',
          daysSinceContact: 7,
        ),
      );
      // Should have at least 2 unique variations
      expect(texts.toSet().length, greaterThan(1));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/services/notification_templates_test.dart`
Expected: FAIL — `notification_templates.dart` not found

**Step 3: Implement NotificationTemplates**

```dart
// lib/core/constants/notification_templates.dart
import 'dart:math';

class NotificationTemplates {
  static final _random = Random();

  // 1-3 day gap: gentle, casual
  static const _gentleTemplates = [
    '{name} يسلم عليك',
    '{name} وش أخبارهم؟',
    'سلّم على {name} اليوم',
    'شكلك ناسي {name}',
    '{name} لهم {days} أيام ما سمعوا صوتك',
  ];

  // 4-13 day gap: moderate nudge
  static const _moderateTemplates = [
    '{name} لهم أسبوع ما حد كلمهم',
    'وش أخبار {name}؟ لهم {days} أيام',
    '{name} يمكن يحتاجون يسمعون صوتك',
    'ما كلمت {name} من {days} يوم',
    '{name} وش سالفتهم؟ طولت عليهم',
  ];

  // 14-29 day gap: direct
  static const _directTemplates = [
    '{name} لهم أسبوعين ما سمعوا صوتك',
    'آخر مرة كلمت {name} كان قبل {days} يوم',
    '{name} ممكن يكونون مشتاقين لك، لهم {days} يوم',
    'طولت على {name}، لهم أسبوعين',
    '{name} ينتظرون اتصالك، له {days} يوم',
  ];

  // 30+ day gap: heavy
  static const _heavyTemplates = [
    'آخر مرة كلمت {name} كان قبل شهر',
    '{name} لهم أكثر من شهر ما سمعوا منك',
    'شهر كامل ما تواصلت مع {name}',
    '{name} لهم {days} يوم، الوقت يمر بسرعة',
    'صلة الرحم مع {name} محتاجة اهتمام، لهم {days} يوم',
  ];

  static String getReminder({
    required String relativeName,
    required int daysSinceContact,
  }) {
    final List<String> templates;
    if (daysSinceContact <= 3) {
      templates = _gentleTemplates;
    } else if (daysSinceContact <= 13) {
      templates = _moderateTemplates;
    } else if (daysSinceContact <= 29) {
      templates = _directTemplates;
    } else {
      templates = _heavyTemplates;
    }

    final template = templates[_random.nextInt(templates.length)];
    return template
        .replaceAll('{name}', relativeName)
        .replaceAll('{days}', daysSinceContact.toString());
  }

  // Streak celebration messages (Saudi dialect)
  static const streakMessages = [
    'يا وصّال العيلة! {streak} يوم ما وقفت 🔥',
    'سلسلة {streak} يوم! أنت قدها 🔥',
    '{streak} يوم متواصل! الله يبارك فيك',
    'ما شاء الله، {streak} يوم! كمّل',
  ];

  // Badge unlock messages
  static const badgeMessages = [
    'يا بطل، شارة جديدة تستاهلها!',
    'وسام جديد! أنت تستاهل',
    'حصلت على شارة جديدة، يا وصّال!',
  ];

  // Level up messages
  static const levelUpMessages = [
    'مستوى جديد! كل ما تتواصل كل ما ترتقي',
    'ارتقيت لمستوى {level}! الله يوفقك',
    'مستوى {level}! أنت من أفضل الوصّالين',
  ];
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/unit/services/notification_templates_test.dart`
Expected: PASS

**Step 5: Create migration for dialect strings in admin_ui_strings**

```sql
-- supabase/migrations/YYYYMMDD_notification_dialect_strings.sql
-- Add Saudi dialect notification templates to admin_ui_strings
INSERT INTO admin_ui_strings (string_key, category, value_ar, value_en, description, screen, is_active) VALUES
-- Gentle reminders (1-3 days)
('reminder_gentle_1', 'notifications', '{name} يسلم عليك', '{name} says hi', 'Gentle reminder 1-3 days', 'notification', true),
('reminder_gentle_2', 'notifications', '{name} وش أخبارهم؟', 'How is {name}?', 'Gentle reminder 1-3 days', 'notification', true),
('reminder_gentle_3', 'notifications', 'سلّم على {name} اليوم', 'Say hi to {name} today', 'Gentle reminder 1-3 days', 'notification', true),
-- Moderate reminders (4-13 days)
('reminder_moderate_1', 'notifications', '{name} لهم أسبوع ما حد كلمهم', '{name} hasn''t heard from anyone in a week', 'Moderate reminder', 'notification', true),
('reminder_moderate_2', 'notifications', 'وش أخبار {name}؟ لهم {days} أيام', 'How is {name}? It''s been {days} days', 'Moderate reminder', 'notification', true),
-- Direct reminders (14-29 days)
('reminder_direct_1', 'notifications', '{name} لهم أسبوعين ما سمعوا صوتك', '{name} hasn''t heard your voice in 2 weeks', 'Direct reminder', 'notification', true),
-- Heavy reminders (30+ days)
('reminder_heavy_1', 'notifications', 'آخر مرة كلمت {name} كان قبل شهر', 'Last time you talked to {name} was a month ago', 'Heavy reminder', 'notification', true)
ON CONFLICT (string_key) DO NOTHING;
```

**Step 6: Integrate templates into FCM notification service**

Modify `lib/shared/services/fcm_notification_service.dart` to use `NotificationTemplates.getReminder()` when constructing reminder notifications, replacing hardcoded formal strings.

**Step 7: Commit**

```bash
git add lib/core/constants/notification_templates.dart test/unit/services/notification_templates_test.dart
git commit -m "feat: add Saudi dialect notification templates with rotation"
```

---

### Task 2: Shareable Celebration Cards

Add share buttons to all three celebration modals (streak, badge, level-up). Generate branded image cards using the existing theme system.

**Files:**
- Create: `lib/shared/widgets/shareable_card_generator.dart`
- Create: `lib/shared/widgets/share_card_widget.dart`
- Modify: `lib/shared/widgets/streak_milestone_modal.dart`
- Modify: `lib/shared/widgets/badge_unlock_modal.dart`
- Modify: `lib/shared/widgets/level_up_modal.dart`
- Test: `test/widget/shared/shareable_card_generator_test.dart`

**Step 1: Write test for ShareableCardGenerator**

```dart
// test/widget/shared/shareable_card_generator_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silni/shared/widgets/shareable_card_generator.dart';

void main() {
  group('ShareableCardGenerator', () {
    test('generates streak card data correctly', () {
      final cardData = ShareableCardData.streak(
        streak: 30,
        relativeName: 'أمي',
      );
      expect(cardData.title, contains('30'));
      expect(cardData.subtitle, contains('أمي'));
      expect(cardData.shareText, isNotEmpty);
      expect(cardData.shareText, isNot(contains('Download')));
    });

    test('generates badge card data correctly', () {
      final cardData = ShareableCardData.badge(
        badgeName: 'واصل العائلة',
        badgeEmoji: '🏆',
      );
      expect(cardData.title, contains('واصل العائلة'));
      expect(cardData.shareText, isNotEmpty);
    });

    test('generates level-up card data correctly', () {
      final cardData = ShareableCardData.levelUp(
        level: 5,
      );
      expect(cardData.title, contains('5'));
      expect(cardData.shareText, isNotEmpty);
    });

    test('share text sounds natural, not promotional', () {
      final cardData = ShareableCardData.streak(
        streak: 30,
        relativeName: 'أمي',
      );
      // Should not contain download CTAs
      expect(cardData.shareText, isNot(contains('حمّل')));
      expect(cardData.shareText, isNot(contains('Download')));
      // Should contain the achievement naturally
      expect(cardData.shareText, contains('30'));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/widget/shared/shareable_card_generator_test.dart`
Expected: FAIL

**Step 3: Implement ShareableCardData model**

```dart
// lib/shared/widgets/shareable_card_generator.dart
import 'dart:math';

class ShareableCardData {
  final String title;
  final String subtitle;
  final String shareText;
  final String emoji;

  const ShareableCardData({
    required this.title,
    required this.subtitle,
    required this.shareText,
    required this.emoji,
  });

  factory ShareableCardData.streak({
    required int streak,
    required String relativeName,
  }) {
    final texts = [
      '$streak يوم ما قطعت التواصل مع $relativeName 🔥',
      'سلسلة $streak يوم مع $relativeName! 🔥',
      '$relativeName - $streak يوم متواصل 🔥',
    ];
    return ShareableCardData(
      title: '🔥 $streak يوم',
      subtitle: 'سلسلة تواصل مع $relativeName',
      shareText: texts[Random().nextInt(texts.length)],
      emoji: '🔥',
    );
  }

  factory ShareableCardData.badge({
    required String badgeName,
    required String badgeEmoji,
  }) {
    return ShareableCardData(
      title: '$badgeEmoji $badgeName',
      subtitle: 'وسام جديد في صِلني',
      shareText: 'حصلت على وسام "$badgeName" $badgeEmoji في صِلني',
      emoji: badgeEmoji,
    );
  }

  factory ShareableCardData.levelUp({
    required int level,
  }) {
    return ShareableCardData(
      title: '⭐ مستوى $level',
      subtitle: 'ارتقيت لمستوى جديد في صِلني',
      shareText: 'وصلت مستوى $level في صِلني! ⭐',
      emoji: '⭐',
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/widget/shared/shareable_card_generator_test.dart`
Expected: PASS

**Step 5: Create ShareCardWidget (the visual card for screenshots/sharing)**

```dart
// lib/shared/widgets/share_card_widget.dart
```

This widget renders a branded card with:
- Silni logo and gradient background (from theme)
- Achievement emoji and title (large, centered)
- Subtitle text
- صِلني watermark at bottom
- Fixed dimensions optimized for Twitter/WhatsApp (1080x1080 or 1080x1920)

Use `RepaintBoundary` + `RenderRepaintBoundary.toImage()` to capture as image, then share via `Share.shareXFiles()`.

**Step 6: Add share button to StreakMilestoneModal**

Modify `lib/shared/widgets/streak_milestone_modal.dart`:
- Add a "شارك" button next to the existing "رائع!" button
- On tap: generate `ShareableCardData.streak()`, render `ShareCardWidget`, capture image, call `Share.shareXFiles()`

**Step 7: Add share button to BadgeUnlockModal**

Same pattern for `lib/shared/widgets/badge_unlock_modal.dart`.

**Step 8: Add share button to LevelUpModal**

Same pattern for `lib/shared/widgets/level_up_modal.dart`.

**Step 9: Commit**

```bash
git add lib/shared/widgets/shareable_card_generator.dart lib/shared/widgets/share_card_widget.dart
git add lib/shared/widgets/streak_milestone_modal.dart lib/shared/widgets/badge_unlock_modal.dart lib/shared/widgets/level_up_modal.dart
git add test/widget/shared/shareable_card_generator_test.dart
git commit -m "feat: add shareable celebration cards to all modals"
```

---

### Task 3: Intelligent Home Screen — Daily Priority & One-Tap Logging

Replace the static home screen with an intelligent dashboard showing today's priority contact and one-tap logging.

**Files:**
- Create: `lib/core/services/contact_priority_service.dart`
- Create: `lib/features/home/widgets/daily_priority_card.dart`
- Create: `lib/features/home/widgets/quick_log_faces.dart`
- Create: `lib/features/home/widgets/family_pulse_indicator.dart`
- Modify: `lib/features/home/screens/home_screen.dart`
- Modify: `lib/features/home/providers/home_providers.dart`
- Test: `test/unit/services/contact_priority_service_test.dart`

**Step 1: Write test for ContactPriorityService**

```dart
// test/unit/services/contact_priority_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:silni/core/services/contact_priority_service.dart';
import 'package:silni/shared/models/relative_model.dart';

void main() {
  group('ContactPriorityService', () {
    test('prioritizes relatives with longest gap and highest priority', () {
      final relatives = [
        _makeRelative('1', 'أمي', RelationshipType.mother, 1, daysSince: 2),
        _makeRelative('2', 'عمي سعد', RelationshipType.uncle, 2, daysSince: 20),
        _makeRelative('3', 'ابن عمي', RelationshipType.cousin, 3, daysSince: 5),
      ];

      final prioritized = ContactPriorityService.getTodayPriority(
        relatives: relatives,
        now: DateTime.now(),
      );

      // Uncle has longest gap relative to expected frequency
      expect(prioritized.first.id, equals('2'));
    });

    test('returns top 3 for quick-log faces', () {
      final relatives = List.generate(10, (i) =>
        _makeRelative('$i', 'Relative $i', RelationshipType.cousin, 3, daysSince: i * 3),
      );

      final quickLog = ContactPriorityService.getQuickLogSuggestions(
        relatives: relatives,
        now: DateTime.now(),
        limit: 3,
      );

      expect(quickLog.length, equals(3));
    });

    test('calculates family pulse score', () {
      final relatives = [
        _makeRelative('1', 'أمي', RelationshipType.mother, 1, daysSince: 1),
        _makeRelative('2', 'أبوي', RelationshipType.father, 1, daysSince: 30),
      ];

      final pulse = ContactPriorityService.getFamilyPulse(relatives);
      // Should be between 0.0 and 1.0
      expect(pulse, greaterThanOrEqualTo(0.0));
      expect(pulse, lessThanOrEqualTo(1.0));
      // Not fully healthy because dad hasn't been contacted in 30 days
      expect(pulse, lessThan(0.8));
    });
  });
}

Relative _makeRelative(String id, String name, RelationshipType type, int priority, {required int daysSince}) {
  return Relative(
    id: id,
    userId: 'user1',
    fullName: name,
    relationshipType: type,
    priority: priority,
    lastContactDate: DateTime.now().subtract(Duration(days: daysSince)),
    // ... other required fields with defaults
  );
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/services/contact_priority_service_test.dart`
Expected: FAIL

**Step 3: Implement ContactPriorityService**

```dart
// lib/core/services/contact_priority_service.dart
```

Logic:
- `getTodayPriority()` — Score each relative: `(daysSinceContact / expectedFrequency) * priorityWeight`. Sort descending. Return top N.
- Expected frequency by relationship: parents=2 days, grandparents=7, siblings=5, uncle/aunt=14, cousin=30
- `getQuickLogSuggestions()` — Return top 3 most likely contacts based on time-of-day patterns + gap score
- `getFamilyPulse()` — Average health score across all relatives. 1.0 = everyone contacted within expected frequency. 0.0 = everyone overdue.

**Step 4: Run test to verify it passes**

Run: `flutter test test/unit/services/contact_priority_service_test.dart`
Expected: PASS

**Step 5: Build DailyPriorityCard widget**

```dart
// lib/features/home/widgets/daily_priority_card.dart
```

Shows: "كلم {name}، لها {days} {unit}" with a call/WhatsApp button. One card, one action. Uses `ContactPriorityService.getTodayPriority()`.

**Step 6: Build QuickLogFaces widget**

```dart
// lib/features/home/widgets/quick_log_faces.dart
```

Shows 2-3 avatar circles of suggested contacts. Tap a face → logs a "call" interaction instantly (one tap). Uses `ContactPriorityService.getQuickLogSuggestions()`.

**Step 7: Build FamilyPulseIndicator widget**

```dart
// lib/features/home/widgets/family_pulse_indicator.dart
```

Single circular indicator: green/amber/red based on `ContactPriorityService.getFamilyPulse()`. Compact, glanceable.

**Step 8: Integrate into HomeScreen**

Modify `lib/features/home/screens/home_screen.dart`:
- Add `DailyPriorityCard` at the top of the home screen ListView
- Add `QuickLogFaces` below it
- Add `FamilyPulseIndicator` in the stats area
- Keep existing widgets below

**Step 9: Add providers**

Modify `lib/features/home/providers/home_providers.dart`:
- Add `dailyPriorityProvider` — computed from `relativesStreamProvider`
- Add `quickLogSuggestionsProvider` — computed from relatives + time of day
- Add `familyPulseProvider` — computed from relatives

**Step 10: Commit**

```bash
git add lib/core/services/contact_priority_service.dart
git add lib/features/home/widgets/daily_priority_card.dart lib/features/home/widgets/quick_log_faces.dart lib/features/home/widgets/family_pulse_indicator.dart
git add lib/features/home/screens/home_screen.dart lib/features/home/providers/home_providers.dart
git add test/unit/services/contact_priority_service_test.dart
git commit -m "feat: intelligent home screen with daily priority and one-tap logging"
```

---

### Task 4: Auto-Generated Reminders

When a user adds a relative, automatically create an appropriate reminder based on relationship type. No manual reminder setup needed.

**Files:**
- Create: `lib/core/services/auto_reminder_service.dart`
- Modify: `lib/shared/services/relatives_service.dart` (or wherever relative creation is handled)
- Modify: `lib/shared/services/reminder_schedules_service.dart`
- Test: `test/unit/services/auto_reminder_service_test.dart`

**Step 1: Write test for AutoReminderService**

```dart
// test/unit/services/auto_reminder_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:silni/core/services/auto_reminder_service.dart';
import 'package:silni/shared/models/relative_model.dart';
import 'package:silni/shared/models/reminder_schedule_model.dart';

void main() {
  group('AutoReminderService', () {
    test('suggests daily/every-other-day for parents', () {
      final suggestion = AutoReminderService.suggestReminder(
        relationshipType: RelationshipType.mother,
      );
      expect(suggestion.frequency, equals(ReminderFrequency.daily));
    });

    test('suggests weekly for grandparents', () {
      final suggestion = AutoReminderService.suggestReminder(
        relationshipType: RelationshipType.grandmother,
      );
      expect(suggestion.frequency, equals(ReminderFrequency.weekly));
    });

    test('suggests bi-weekly for uncles/aunts', () {
      final suggestion = AutoReminderService.suggestReminder(
        relationshipType: RelationshipType.uncle,
      );
      expect(suggestion.frequency, equals(ReminderFrequency.custom));
      expect(suggestion.intervalDays, equals(14));
    });

    test('suggests monthly for cousins', () {
      final suggestion = AutoReminderService.suggestReminder(
        relationshipType: RelationshipType.cousin,
      );
      expect(suggestion.frequency, equals(ReminderFrequency.monthly));
    });
  });
}
```

**Step 2: Run test → fail. Step 3: Implement. Step 4: Run test → pass.**

AutoReminderService maps relationship types to frequencies:
- father/mother → daily
- grandfather/grandmother → weekly
- brother/sister → weekly
- uncle/aunt → bi-weekly (custom, 14 days)
- cousin/nephew/niece → monthly
- husband/wife → daily
- son/daughter → daily

**Step 5: Hook into relative creation flow**

In the relative creation service, after successfully creating a relative, call `AutoReminderService.createAutoReminder()` to create a reminder schedule. The user can always modify or delete it later.

**Step 6: Commit**

```bash
git add lib/core/services/auto_reminder_service.dart test/unit/services/auto_reminder_service_test.dart
git commit -m "feat: auto-generate reminders when adding relatives"
```

---

### Task 5: Monthly Wrapped with Personality Labels

Generate a monthly shareable summary with stats and a personality label.

**Files:**
- Create: `lib/features/wrapped/models/monthly_wrapped_model.dart`
- Create: `lib/features/wrapped/services/wrapped_generator_service.dart`
- Create: `lib/features/wrapped/screens/monthly_wrapped_screen.dart`
- Create: `lib/features/wrapped/widgets/wrapped_card_widget.dart`
- Create: `lib/features/wrapped/providers/wrapped_providers.dart`
- Modify: `lib/core/router/app_routes.dart` (add route)
- Modify: `lib/core/router/app_router.dart` (add route)
- Test: `test/unit/services/wrapped_generator_service_test.dart`

**Step 1: Write test for WrappedGeneratorService**

```dart
// test/unit/services/wrapped_generator_service_test.dart
void main() {
  group('WrappedGeneratorService', () {
    test('computes monthly stats correctly', () {
      final wrapped = WrappedGeneratorService.generate(
        interactions: mockInteractions,
        relatives: mockRelatives,
        month: DateTime(2026, 1),
      );
      expect(wrapped.totalInteractions, equals(47));
      expect(wrapped.mostContactedRelative, isNotNull);
      expect(wrapped.longestStreak, greaterThan(0));
      expect(wrapped.personalityLabel, isNotEmpty);
      expect(wrapped.relativesCoverage, greaterThan(0.0));
    });

    test('assigns personality labels based on behavior', () {
      // Heavy caller at night
      final wrapped = WrappedGeneratorService.generate(
        interactions: nightTimeInteractions,
        relatives: mockRelatives,
        month: DateTime(2026, 1),
      );
      expect(wrapped.personalityLabel, equals('بومة الليل العائلية'));
    });

    test('assigns visitor label for visit-heavy users', () {
      final wrapped = WrappedGeneratorService.generate(
        interactions: visitHeavyInteractions,
        relatives: mockRelatives,
        month: DateTime(2026, 1),
      );
      expect(wrapped.personalityLabel, equals('ملك الزيارات'));
    });
  });
}
```

**Step 2: Run test → fail. Step 3: Implement model and service.**

MonthlyWrapped model:
- `totalInteractions`, `uniqueRelativesContacted`, `relativesCoverage` (0-1)
- `mostContactedRelative` (name + count)
- `longestStreak`, `currentStreak`
- `personalityLabel` — computed from behavior patterns:
  - Most calls at night → "بومة الليل العائلية"
  - Most visits → "ملك الزيارات"
  - High variety of relatives → "واصل العائلة"
  - Heavy caller → "صاحب المكالمات"
  - Gift giver → "الكريم"
  - Morning person → "طائر الصباح العائلي"
  - Default → "وصّال الرحم"

**Step 4: Run test → pass.**

**Step 5: Build WrappedCardWidget**

Branded card with: personality emoji + label (top), key stat (center), month name, صِلني watermark. Same sharing mechanism as celebration cards (Task 2).

**Step 6: Build MonthlyWrappedScreen**

Full-screen experience showing stats in sequence, personality reveal, share button.

**Step 7: Add route and trigger**

Show a notification/card at the start of each new month prompting the user to see their Wrapped.

**Step 8: Commit**

```bash
git add lib/features/wrapped/
git add test/unit/services/wrapped_generator_service_test.dart
git commit -m "feat: monthly Wrapped with personality labels and shareable cards"
```

---

### Task 6: AI Proactive Insights (Home Screen Cards)

Surface one AI-generated insight per day on the home screen without the user asking.

**Files:**
- Create: `lib/features/home/widgets/ai_insight_card.dart`
- Create: `lib/core/services/proactive_insight_service.dart`
- Modify: `lib/features/home/screens/home_screen.dart`
- Modify: `lib/features/home/providers/home_providers.dart`
- Test: `test/unit/services/proactive_insight_service_test.dart`

**Step 1: Write test for ProactiveInsightService**

```dart
// test/unit/services/proactive_insight_service_test.dart
void main() {
  group('ProactiveInsightService', () {
    test('generates insight from relative patterns', () {
      final insight = ProactiveInsightService.generateInsight(
        relatives: mockRelatives,
        interactions: recentInteractions,
      );
      expect(insight, isNotNull);
      expect(insight!.message, isNotEmpty);
      expect(insight.type, isIn(['pattern', 'gap', 'positive', 'suggestion']));
    });

    test('detects imbalanced contact patterns', () {
      // Mom contacted daily, dad contacted monthly
      final insight = ProactiveInsightService.generateInsight(
        relatives: [momRelative, dadRelative],
        interactions: imbalancedInteractions,
      );
      expect(insight?.type, equals('pattern'));
      expect(insight?.message, contains('أبوك'));
    });

    test('returns null if no actionable insight', () {
      // All relatives contacted recently
      final insight = ProactiveInsightService.generateInsight(
        relatives: wellContactedRelatives,
        interactions: recentInteractions,
      );
      // May return a positive insight or null
      if (insight != null) {
        expect(insight.type, equals('positive'));
      }
    });
  });
}
```

**Step 2-4: Implement and test.**

ProactiveInsightService generates insights by analyzing:
- Contact frequency imbalances between relatives
- Declining streaks
- Missed patterns (user usually calls on Sundays but didn't)
- Positive reinforcement when doing well
- Contextual suggestions (upcoming occasions from cultural calendar)

**Step 5: Build AiInsightCard**

A glass card on the home screen with the AI personality name, the insight text, and a dismiss button. Shows max once per day. Stores last shown date in SharedPreferences.

**Step 6: Integrate into HomeScreen**

Add `AiInsightCard` to the home screen ListView, below DailyPriorityCard.

**Step 7: Commit**

```bash
git add lib/core/services/proactive_insight_service.dart lib/features/home/widgets/ai_insight_card.dart
git add test/unit/services/proactive_insight_service_test.dart
git commit -m "feat: proactive AI insights on home screen"
```

---

## Phase 2: Structural Intelligence (Foundation changes)

### Task 7: Intelligent Add-Relative Flow

Replace the dropdown-heavy form with a contextual, guided flow.

**Files:**
- Create: `lib/features/relatives/widgets/smart_relationship_picker.dart`
- Create: `lib/features/relatives/services/relationship_inference_service.dart`
- Modify: `lib/features/relatives/screens/add_relative_screen.dart`
- Modify: `lib/features/contacts/screens/contact_import_screen.dart`
- Test: `test/unit/services/relationship_inference_service_test.dart`

**Step 1: Write test for RelationshipInferenceService**

```dart
void main() {
  group('RelationshipInferenceService', () {
    test('suggests parents first when none exist in tree', () {
      final suggestions = RelationshipInferenceService.suggestRelationships(
        existingRelatives: [],
      );
      expect(suggestions.first, isIn([RelationshipType.father, RelationshipType.mother]));
    });

    test('suggests siblings when parents exist but no siblings', () {
      final suggestions = RelationshipInferenceService.suggestRelationships(
        existingRelatives: [motherRelative, fatherRelative],
      );
      expect(suggestions, contains(RelationshipType.brother));
      expect(suggestions, contains(RelationshipType.sister));
    });

    test('suggests extended family when immediate family exists', () {
      final suggestions = RelationshipInferenceService.suggestRelationships(
        existingRelatives: [motherRelative, fatherRelative, brotherRelative],
      );
      expect(suggestions, contains(RelationshipType.grandmother));
      expect(suggestions, contains(RelationshipType.uncle));
    });

    test('infers gender from Arabic name patterns', () {
      expect(RelationshipInferenceService.inferGender('محمد'), equals(Gender.male));
      expect(RelationshipInferenceService.inferGender('فاطمة'), equals(Gender.female));
      expect(RelationshipInferenceService.inferGender('نور'), isNull); // Ambiguous
    });
  });
}
```

**Step 2-4: Implement and test.**

RelationshipInferenceService:
- `suggestRelationships(existingRelatives)` — Analyze gaps in the family tree and suggest most likely relationship types. Priority: parents > spouse > siblings > grandparents > uncles/aunts > cousins.
- `inferGender(name)` — Common Arabic name gender patterns. Returns null if ambiguous.
- `suggestSide(relationshipType, existingRelatives)` — For extended family, check which "side" (maternal/paternal) has fewer entries and suggest that side first.

**Step 5: Build SmartRelationshipPicker**

Replace the dropdown with a contextual picker:
1. First screen: "مين هالشخص لك؟" — shows 4-6 most likely relationship types as large tappable cards (not a dropdown)
2. If uncle/aunt/cousin selected: "من طرف أبوك ولا أمك؟" — two buttons
3. Auto-fill gender, priority, avatar from the selection

**Step 6: Update AddRelativeScreen**

Replace the current form with the smart flow. Keep the option to "show all" for edge cases.

**Step 7: Update ContactImportScreen**

Replace per-contact relationship dialog with batch grouping: "هؤلاء من عائلتك المباشرة ولا الممتدة؟" → narrow down.

**Step 8: Commit**

```bash
git add lib/features/relatives/widgets/smart_relationship_picker.dart lib/features/relatives/services/relationship_inference_service.dart
git add test/unit/services/relationship_inference_service_test.dart
git commit -m "feat: intelligent relationship picker with contextual suggestions"
```

---

### Task 8: Family Tree Graph Restructure

Change the tree data model from flat labels to a real relationship graph that supports inference and perspective shifting.

**Files:**
- Create: `lib/features/family_tree/models/family_graph.dart`
- Create: `lib/features/family_tree/services/family_graph_service.dart`
- Create: `supabase/migrations/YYYYMMDD_family_graph_edges.sql`
- Modify: `lib/features/family_tree/models/tree_node.dart`
- Modify: `lib/features/family_tree/screens/family_tree_screen.dart`
- Modify: `lib/shared/models/relative_model.dart` (add parentRelativeId, spouseRelativeId)
- Test: `test/unit/services/family_graph_service_test.dart`

**Step 1: Write test for FamilyGraphService**

```dart
void main() {
  group('FamilyGraphService', () {
    test('builds graph from relatives with relationship edges', () {
      final graph = FamilyGraphService.buildGraph(
        userId: 'user1',
        relatives: [father, mother, uncle, cousin],
        edges: [
          FamilyEdge(fromId: 'user1', toId: father.id, type: EdgeType.parentOf),
          FamilyEdge(fromId: 'user1', toId: mother.id, type: EdgeType.parentOf),
          FamilyEdge(fromId: father.id, toId: uncle.id, type: EdgeType.siblingOf),
          FamilyEdge(fromId: uncle.id, toId: cousin.id, type: EdgeType.parentOf),
        ],
      );

      expect(graph.getParents('user1'), containsAll([father.id, mother.id]));
      expect(graph.getSiblings(father.id), contains(uncle.id));
      expect(graph.getChildren(uncle.id), contains(cousin.id));
    });

    test('computes label for viewer perspective', () {
      // From son's perspective: mother
      expect(graph.getLabelForViewer('user1', mother.id), equals('أمي'));
      // From father's perspective: wife
      expect(graph.getLabelForViewer(father.id, mother.id), equals('زوجتي'));
      // From cousin's perspective: aunt
      expect(graph.getLabelForViewer(cousin.id, mother.id), equals('خالتي'));
    });

    test('infers edges from relationship type', () {
      // When user adds uncle (dad's brother), infer edge: uncle is sibling of dad
      final inferredEdges = FamilyGraphService.inferEdges(
        userId: 'user1',
        newRelativeId: uncle.id,
        relationshipType: RelationshipType.uncle,
        side: FamilySide.paternal,
        existingEdges: existingEdges,
      );
      expect(inferredEdges, contains(
        FamilyEdge(fromId: father.id, toId: uncle.id, type: EdgeType.siblingOf),
      ));
    });

    test('positions generations correctly', () {
      final layout = graph.getLayout();
      // Grandparents above parents above user above children
      expect(layout.getGeneration(grandmother.id), lessThan(layout.getGeneration(father.id)));
      expect(layout.getGeneration(father.id), lessThan(layout.getGeneration('user1')));
    });
  });
}
```

**Step 2-4: Implement and test.**

FamilyGraph data model:
- `FamilyEdge`: `{fromId, toId, type}` where type is `parentOf | siblingOf | spouseOf`
- `FamilyGraph`: Adjacency list with methods for traversal, label computation, layout
- `getLabelForViewer(viewerId, targetId)` — Traverse graph to compute relationship label in Arabic based on viewer's position

Database migration:
```sql
CREATE TABLE family_edges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_group_id UUID REFERENCES family_groups(id),
  from_relative_id UUID NOT NULL,
  to_relative_id UUID NOT NULL,
  edge_type TEXT NOT NULL CHECK (edge_type IN ('parent_of', 'sibling_of', 'spouse_of')),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(family_group_id, from_relative_id, to_relative_id, edge_type)
);
```

**Step 5: Update tree visualization**

Modify `family_tree_screen.dart` to render from the graph layout instead of the current flat model. Generations as horizontal layers, marriages side-by-side, children branching down.

**Step 6: Migration for existing data**

Write a migration that infers edges from existing relationship types where possible (parents, spouse).

**Step 7: Commit**

```bash
git add lib/features/family_tree/models/family_graph.dart lib/features/family_tree/services/family_graph_service.dart
git add supabase/migrations/YYYYMMDD_family_graph_edges.sql
git add test/unit/services/family_graph_service_test.dart
git commit -m "feat: family tree graph data model with perspective-shifting labels"
```

---

### Task 9: Perspective-Shifting Labels

Integrate the graph's `getLabelForViewer()` into all UI surfaces where relationship labels appear.

**Files:**
- Modify: `lib/shared/models/relative_model.dart` — add `displayLabel(viewerId)` method
- Modify: `lib/features/relatives/screens/relative_detail_screen.dart`
- Modify: `lib/features/relatives/screens/relatives_screen.dart`
- Modify: `lib/features/family_tree/screens/family_tree_screen.dart`
- Modify: Any widget that displays `relative.relationshipType.arabicName`
- Test: `test/unit/models/family_graph_labels_test.dart`

This is a search-and-replace task across UI files. Every place that currently uses `relative.relationshipType` for display should use the graph-aware label when in a shared family context, or fall back to the current label for solo users.

**Commit:**
```bash
git commit -m "feat: perspective-shifting relationship labels across all screens"
```

---

### Task 10: Family Groups with Invite Deep Links

Enable users to create a family group, invite members via deep link, and share a tree.

**Files:**
- Create: `lib/features/family_groups/models/family_group_model.dart`
- Create: `lib/features/family_groups/services/family_group_service.dart`
- Create: `lib/features/family_groups/screens/family_group_screen.dart`
- Create: `lib/features/family_groups/screens/invite_screen.dart`
- Create: `lib/features/family_groups/widgets/invite_link_card.dart`
- Create: `lib/features/family_groups/providers/family_group_providers.dart`
- Create: `supabase/migrations/YYYYMMDD_family_groups.sql`
- Create: `supabase/functions/join-family-group/index.ts`
- Modify: `lib/main.dart` (deep link handling for invite links)
- Modify: `lib/core/router/app_routes.dart`
- Modify: `lib/core/router/app_router.dart`
- Test: `test/unit/services/family_group_service_test.dart`

**Step 1: Database migration**

```sql
-- supabase/migrations/YYYYMMDD_family_groups.sql
CREATE TABLE family_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_by UUID REFERENCES auth.users(id) NOT NULL,
  invite_code TEXT UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(6), 'hex'),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE family_group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES family_groups(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  relative_id_in_tree UUID, -- which node in the shared tree represents this user
  role TEXT DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  joined_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(group_id, user_id)
);

-- RLS policies
ALTER TABLE family_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_group_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view their groups"
  ON family_groups FOR SELECT
  USING (id IN (SELECT group_id FROM family_group_members WHERE user_id = auth.uid()));

CREATE POLICY "Members can view group members"
  ON family_group_members FOR SELECT
  USING (group_id IN (SELECT group_id FROM family_group_members WHERE user_id = auth.uid()));

CREATE POLICY "Creator can manage group"
  ON family_groups FOR ALL
  USING (created_by = auth.uid());
```

**Step 2: Implement FamilyGroupModel and FamilyGroupService**

- `createGroup(name)` — Create group, add creator as admin
- `generateInviteLink(groupId)` — Returns `https://silni.app/join/{inviteCode}`
- `joinGroup(inviteCode, userId)` — Add user to group, link their tree node
- `getGroupMembers(groupId)` — List members with their relative_id_in_tree
- `getSharedTree(groupId)` — Merge all members' relatives into one graph

**Step 3: Deep link handler for invite links**

Modify `lib/main.dart` `_handleDeepLink()`:
- Pattern: `/join/{inviteCode}`
- If user logged in → call `joinGroup(inviteCode)`
- If not logged in → store invite code, redirect to auth, join after login

**Step 4: Build InviteScreen**

Shows the invite code, a WhatsApp share button with pre-written natural message:
"انضم لعائلتنا في صِلني 🌳 {link}"

**Step 5: Build FamilyGroupScreen**

Shows group members, shared tree stats, family-wide leaderboard teaser.

**Step 6: Commit**

```bash
git add lib/features/family_groups/ supabase/migrations/YYYYMMDD_family_groups.sql supabase/functions/join-family-group/
git add test/unit/services/family_group_service_test.dart
git commit -m "feat: family groups with invite deep links and shared tree"
```

---

### Task 11: Shared Family Tree (Collaborative Adding)

When a member adds a relative to a shared tree, it appears for everyone.

**Files:**
- Modify: `lib/features/family_groups/services/family_group_service.dart`
- Modify: `lib/shared/services/relatives_service.dart`
- Modify: `lib/features/relatives/screens/add_relative_screen.dart`
- Create: `supabase/migrations/YYYYMMDD_shared_relatives.sql`
- Test: `test/unit/services/shared_tree_test.dart`

**Key changes:**
- When a user is in a family group, the `addRelative` flow offers: "ضيفه للعائلة المشتركة؟"
- If yes, the relative is created with `family_group_id` set
- All group members can see this relative via a shared view
- Each member has their own streaks/interactions with the shared relative
- Real-time updates via Supabase realtime subscriptions

**Step 1: Migration**

```sql
-- Add family_group_id to relatives table
ALTER TABLE relatives ADD COLUMN family_group_id UUID REFERENCES family_groups(id);
ALTER TABLE relatives ADD COLUMN added_by UUID REFERENCES auth.users(id);

-- Index for shared tree queries
CREATE INDEX idx_relatives_family_group ON relatives(family_group_id) WHERE family_group_id IS NOT NULL;

-- Policy: group members can view shared relatives
CREATE POLICY "Group members can view shared relatives"
  ON relatives FOR SELECT
  USING (
    family_group_id IS NULL AND user_id = auth.uid()
    OR
    family_group_id IN (SELECT group_id FROM family_group_members WHERE user_id = auth.uid())
  );
```

**Step 2-5: Implement, test, integrate, commit.**

---

## Phase 3: Enhancements & Amplification

### Task 12: Home Screen Widgets (iOS & Android)

**Files:**
- Create: `lib/features/widgets/home_widget_service.dart`
- Add dependency: `home_widget` package
- Create iOS Widget Extension (Xcode)
- Create Android Widget (XML + Kotlin/Java)
- Test: `test/unit/services/home_widget_service_test.dart`

Displays top streak: "أمي 🔥٤٥" on the device home screen. Updates via `HomeWidget.updateWidget()` after each interaction logged.

**Commit:**
```bash
git commit -m "feat: home screen widget showing top streak"
```

---

### Task 13: Yearly Wrapped Story Sequence

**Files:**
- Create: `lib/features/wrapped/screens/yearly_wrapped_screen.dart`
- Create: `lib/features/wrapped/widgets/wrapped_story_page.dart`
- Modify: `lib/features/wrapped/services/wrapped_generator_service.dart`
- Test: `test/unit/services/yearly_wrapped_test.dart`

5-6 swipeable story pages (like Instagram stories):
1. Total interactions this year
2. Most contacted relative
3. Longest streak achieved
4. Personality type (year-level)
5. Family collective stats (if in a group)
6. Share card with all highlights

Trigger at end of Ramadan or end of year (configurable).

**Commit:**
```bash
git commit -m "feat: yearly Wrapped story sequence"
```

---

### Task 14: Family Leaderboard

**Files:**
- Create: `lib/features/family_groups/widgets/family_leaderboard.dart`
- Create: `lib/features/family_groups/providers/leaderboard_provider.dart`
- Modify: `lib/features/family_groups/screens/family_group_screen.dart`
- Test: `test/unit/providers/leaderboard_provider_test.dart`

Shows weekly interaction rankings among family group members. "طلال كلم ٧ أقارب هالأسبوع 🥇" — with share button for the proud mom.

**Commit:**
```bash
git commit -m "feat: family group leaderboard with sharing"
```

---

### Task 15: Voice-to-Text Interaction Notes

**Files:**
- Add dependency: `speech_to_text` package
- Create: `lib/shared/widgets/voice_note_button.dart`
- Modify: interaction logging dialogs in `lib/features/relatives/screens/relative_detail_screen.dart`
- Test: Manual testing required (hardware dependent)

A mic button on the interaction note field. Tap to record, auto-transcribe to Arabic text. Uses `speech_to_text` package with Arabic locale.

**Commit:**
```bash
git commit -m "feat: voice-to-text for interaction notes"
```

---

### Task 16: AI Mode Auto-Detection (Remove Dropdown)

**Files:**
- Create: `lib/features/ai_assistant/services/ai_mode_detector.dart`
- Modify: `lib/features/ai_assistant/screens/ai_chat_screen.dart`
- Remove: counseling mode selector UI
- Test: `test/unit/services/ai_mode_detector_test.dart`

```dart
void main() {
  group('AIModeDetector', () {
    test('detects repair mode when relative not contacted in 30+ days', () {
      final mode = AIModeDetector.detect(
        relativeContext: relativeNotContactedIn30Days,
      );
      expect(mode, equals(CounselingMode.repair));
    });

    test('detects celebration mode after logging an interaction', () {
      final mode = AIModeDetector.detect(
        relativeContext: recentlyContactedRelative,
        lastAction: LastAction.loggedInteraction,
      );
      expect(mode, equals(CounselingMode.celebration));
    });

    test('defaults to general when no context', () {
      final mode = AIModeDetector.detect();
      expect(mode, equals(CounselingMode.general));
    });
  });
}
```

**Commit:**
```bash
git commit -m "feat: auto-detect AI counseling mode from context"
```

---

### Task 17: Pre-Generated Eid/Occasion Messages

**Files:**
- Create: `lib/features/ai_assistant/services/occasion_message_service.dart`
- Create: `lib/features/ai_assistant/screens/occasion_messages_screen.dart`
- Modify: `lib/features/home/screens/home_screen.dart` (show occasion card)
- Test: `test/unit/services/occasion_message_service_test.dart`

Before Eid (detected via Hijri calendar), auto-generate personalized greeting messages for each relative. Show a card on home screen: "رسائل العيد جاهزة لأقاربك ✉️" — tap to see all messages, copy, or share directly to WhatsApp.

**Commit:**
```bash
git commit -m "feat: pre-generated occasion messages for Eid and events"
```

---

### Task 18: Cultural Content Calendar in Pipeline

**Files:**
- Modify: `silni-admin/src/app/(dashboard)/social/generate/page.tsx`
- Create: `silni-admin/src/lib/cultural-calendar.ts`

Add a cultural/Islamic calendar module to the admin social media content generator:
- Pre-loaded dates: Ramadan start/end, Eid al-Fitr, Eid al-Adha, Hajj season, Saudi National Day, school breaks, Islamic New Year
- Each date has associated family themes and emotional angles
- Content generator auto-suggests topics weeks before each event
- Batch generation for entire event period

**Commit:**
```bash
git commit -m "feat: cultural content calendar for social media pipeline"
```

---

## Dependency Graph

```
Phase 1 (independent, parallel-safe):
  Task 1 (notifications) ─── no deps
  Task 2 (share cards) ──── no deps
  Task 3 (home screen) ──── no deps
  Task 4 (auto reminders) ─ no deps
  Task 5 (wrapped) ──────── no deps
  Task 6 (AI insights) ──── no deps

Phase 2 (sequential):
  Task 7 (smart add) ─────→ Task 8 (graph restructure) ─→ Task 9 (perspective labels)
                                    │
                                    ↓
                             Task 10 (family groups) ───→ Task 11 (shared tree)

Phase 3 (independent, after Phase 2):
  Task 12 (widgets) ─────── depends on Task 3
  Task 13 (yearly wrapped) ─ depends on Task 5
  Task 14 (leaderboard) ──── depends on Task 10
  Task 15 (voice notes) ──── no deps
  Task 16 (AI auto-mode) ─── no deps
  Task 17 (occasion msgs) ── no deps
  Task 18 (content calendar)─ no deps
```

## Execution Notes

- **Phase 1 tasks are fully parallel** — can be dispatched to 6 subagents simultaneously
- **Phase 2 is the critical path** — Task 8 (graph restructure) is the largest single task and blocks Tasks 9, 10, 11
- **Phase 3 tasks are mostly parallel** after their Phase 2 dependencies are met
- Run `flutter test` after each task. Run `flutter analyze` before each commit.
- Use `make test` for full test suite validation at end of each phase.
