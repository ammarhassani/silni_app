# Silni Evolution Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform Silni from a chore tracker with gamification into an AI-first family companion with compassionate celebration, three-tier relatives, and effortless logging.

**Architecture:** Evolve existing Flutter/Riverpod/Supabase stack. No new backend services. Changes are primarily UI restructuring, model additions, prompt rewrites, and gamification softening. The AI pipeline layers build on existing `AIContextEngine`, `AIPrompts`, and `DeepSeekAIService`.

**Tech Stack:** Flutter, Riverpod, Supabase (Postgres + Edge Functions), DeepSeek API, RevenueCat

**Design Doc:** `docs/plans/2026-03-02-silni-evolution-design.md`

---

## Phase 1: Foundation (De-Cringe + Quick Log)

### Task 1: Add `relativeCategory` field to Relative model

Adds `household`, `extended`, `distant` classification to every relative.

**Files:**
- Modify: `lib/shared/models/relative_model.dart`
- Create: `supabase/migrations/20260302100000_add_relative_category.sql`

**Step 1: Add the enum and field to the model**

In `lib/shared/models/relative_model.dart`, add enum before `RelationshipType`:

```dart
/// Classification of relative by proximity/contact pattern
enum RelativeCategory {
  household, // Lives with you — no contact tracking needed
  extended,  // Regular contact expected — streaks/nudges apply
  distant,   // Occasion-based — birthdays, Eid, weddings only
}
```

Add to `Relative` class fields (after `familySide`):

```dart
final RelativeCategory relativeCategory;
```

Default in constructor: `this.relativeCategory = RelativeCategory.extended`

Update `fromJson()`:
```dart
relativeCategory: RelativeCategory.values.firstWhere(
  (e) => e.name == (json['relative_category'] as String?),
  orElse: () => RelativeCategory.extended,
),
```

Update `toJson()`:
```dart
'relative_category': relativeCategory.name,
```

Update `copyWith()` to include `relativeCategory`.

**Step 2: Create the database migration**

```sql
-- Add relative_category column to relatives table
ALTER TABLE relatives
ADD COLUMN relative_category TEXT NOT NULL DEFAULT 'extended'
CHECK (relative_category IN ('household', 'extended', 'distant'));

-- Index for filtering
CREATE INDEX idx_relatives_category ON relatives(user_id, relative_category);
```

**Step 3: Push migration**

Run: `supabase db push --linked`

**Step 4: Commit**

```
feat: add relativeCategory (household/extended/distant) to Relative model
```

---

### Task 2: Add category picker to Add/Edit Relative screens

**Files:**
- Modify: `lib/features/relatives/screens/add_relative_screen.dart`
- Modify: `lib/features/relatives/screens/edit_relative_screen.dart`

**Step 1: Create a reusable category picker widget**

In `lib/shared/widgets/relative_category_picker.dart`:

```dart
class RelativeCategoryPicker extends StatelessWidget {
  final RelativeCategory selected;
  final ValueChanged<RelativeCategory> onChanged;

  const RelativeCategoryPicker({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('نوع العلاقة', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: RelativeCategory.values.map((cat) {
            final isSelected = cat == selected;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(cat),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(_emoji(cat), style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(_label(cat), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _emoji(RelativeCategory cat) => switch (cat) {
    RelativeCategory.household => '🏠',
    RelativeCategory.extended => '📞',
    RelativeCategory.distant => '🌙',
  };

  String _label(RelativeCategory cat) => switch (cat) {
    RelativeCategory.household => 'أهل البيت',
    RelativeCategory.extended => 'تواصل دائم',
    RelativeCategory.distant => 'مناسبات',
  };
}
```

**Step 2: Add picker to Add Relative screen**

In `add_relative_screen.dart`, add `RelativeCategoryPicker` after the relationship type picker. Wire `onChanged` to update the form state.

**Step 3: Add picker to Edit Relative screen**

Same pattern — add `RelativeCategoryPicker` with current value from `relative.relativeCategory`.

**Step 4: Commit**

```
feat: add relative category picker (household/extended/distant) to add/edit screens
```

---

### Task 3: Add category filter to Relatives list screen

**Files:**
- Modify: `lib/features/relatives/screens/relatives_screen.dart`

**Step 1: Add filter chips**

Above the relatives list, add a row of filter chips: All | 🏠 أهل البيت | 📞 تواصل دائم | 🌙 مناسبات

Use existing filter tab pattern from the screen (it already has All / Needs Contact / Favorites tabs).

**Step 2: Filter logic**

When a category chip is selected, filter `relatives.where((r) => r.relativeCategory == selectedCategory)`.

**Step 3: Commit**

```
feat: add category filter chips to relatives list screen
```

---

### Task 4: Simplify Quick Log — one-tap connect

The current `QuickLogFaces` widget in `lib/features/home/widgets/quick_log_faces.dart` already does one-tap logging but hardcodes `InteractionType.call`. Make it smarter.

**Files:**
- Modify: `lib/features/home/widgets/quick_log_faces.dart`

**Step 1: Change default type to generic "connected"**

The interaction still uses `InteractionType.call` as the default (since the DB requires a type). But change the UX:
- Remove the label "سجّل تواصل سريع" → "⚡ تواصل سريع"
- After tap, show a brief bottom sheet: "تواصلت مع {name} ✅" with optional "إضافة تفاصيل" link that opens the full interaction form
- Skip the full form entirely — one tap = done

**Step 2: Filter out household relatives**

Quick log should only show `extended` and `distant` relatives (household doesn't need contact tracking):
```dart
final suggestions = ContactPriorityService.getQuickLogSuggestions(
  relatives.where((r) => r.relativeCategory != RelativeCategory.household).toList(),
  limit: 4,
);
```

**Step 3: Commit**

```
feat: simplify quick log to true one-tap connect, filter out household relatives
```

---

### Task 5: Rebrand Gaming Center → "رحلتي" (My Journey)

**Files:**
- Modify: `lib/features/gamification/screens/gaming_center_screen.dart`
- Modify: `lib/shared/widgets/persistent_bottom_nav.dart`
- Modify: `lib/core/router/app_routes.dart`

**Step 1: Rename bottom nav tab**

In `persistent_bottom_nav.dart`, change the achievements tab:
```dart
// Before:
(icon: Icons.emoji_events_rounded, label: 'الإنجازات', route: AppRoutes.achievements)
// After:
(icon: Icons.route_rounded, label: 'رحلتي', route: AppRoutes.achievements)
```

**Step 2: Redesign Gaming Center header**

In `gaming_center_screen.dart`:
- Change screen title from trophy/gaming language to journey language
- Replace "الإنجازات" header with "رحلتي"
- Remove the dramatic confetti/glow ambient animations
- Replace the merged stats/XP card with a softer journey summary:
  - Current streak (kept, reframed): "٢٧ يوم تواصل مستمر 🔥"
  - Relatives connected this week: "تواصلت مع ٤ أشخاص هذا الأسبوع"
  - Meaningful milestone: latest badge or achievement

**Step 3: Soften feature grid labels**

- "Badges" → "الأوسمة" (keep)
- "Leaderboard" → "نشاط العائلة" (Family Activity)
- "Detailed Stats" → "رؤى" (Insights)
- "Challenges" → "اقتراحات" (Suggestions)

**Step 4: Commit**

```
feat: rebrand Gaming Center to "رحلتي" (My Journey) with softer language
```

---

### Task 6: Remove points display and floating points overlay

**Files:**
- Modify: `lib/features/home/screens/home_screen.dart`
- Modify: `lib/features/gamification/screens/gaming_center_screen.dart`
- Modify: `lib/features/profile/screens/profile_screen.dart`

**Step 1: Disable floating points in home screen**

In `home_screen.dart`, in `_processGamificationEvent`, comment out or remove the `pointsEarned` case:
```dart
case GamificationEventType.pointsEarned:
  // Removed: points overlay no longer shown
  break;
```

**Step 2: Remove points from gaming center stats card**

In `gaming_center_screen.dart`, remove the "points" display from the merged stats card. Keep streak and badge count.

**Step 3: Remove points/level from profile screen**

In `profile_screen.dart`, remove the statistics card that shows "Total points", "Level", etc. Replace with a simple journey summary or remove entirely.

**Step 4: Commit**

```
feat: remove visible points/XP display from all screens
```

---

### Task 7: Soften streak language across the app

**Files:**
- Modify: `lib/shared/widgets/streak_milestone_modal.dart`
- Modify: `lib/features/home/widgets/streak_badge_bar.dart`
- Modify: `lib/core/services/notification_config_service.dart`

**Step 1: Reframe streak milestone modal**

In `streak_milestone_modal.dart`:
- Change title from "سلسلة مميزة!" to "ما شاء الله! 🌟"
- Change subtitle pattern from "X أيام متتالية" to "X يوم من التواصل المستمر"
- Add compassionate recovery for broken streaks (new method):
  - Instead of "You lost your streak": "مرحبًا بعودتك — عائلتك اشتاقت لك 🤍"

**Step 2: Soften streak badge bar**

In `streak_badge_bar.dart`:
- When streak is endangered, change ⏳ warning to a gentler prompt
- Remove shake animation on critical state
- Keep countdown but soften color from red to warm amber

**Step 3: Soften notification templates**

In `notification_config_service.dart` fallback templates:
- Change `'streak_endangered'` title from "سلسلتك في خطر! 🔥" to "تذكير بسيط 💛"
- Change `'streak_broken'` title from "انتهت السلسلة 💔" to "مرحبًا بعودتك 🤍"
- Change body from loss-focused to warmth-focused

**Step 4: Commit**

```
feat: soften streak language to compassionate framing across all screens
```

---

### Task 8: Redesign leaderboard → Family Activity (collective, not competitive)

**Files:**
- Modify: `lib/features/gamification/screens/leaderboard_screen.dart`

**Step 1: Replace competitive ranking with collective stats**

Remove the 3-tab (Points/Streak/Level) competitive ranking. Replace with:
- Family collective stats: "عائلتكم تواصلت X مرة هذا الشهر"
- Activity feed: recent interactions from group members (from `groupTodayInteractionsStreamProvider`)
- No ranking numbers. Show who connected recently, not who's #1

**Step 2: Update screen title**

Change from "ترتيب العائلة" to "نشاط العائلة"

**Step 3: Commit**

```
feat: replace competitive leaderboard with collective Family Activity view
```

---

### Task 9: Remove Level Up modal, soften Badge modal

**Files:**
- Modify: `lib/features/home/screens/home_screen.dart`
- Modify: `lib/shared/widgets/badge_unlock_modal.dart`

**Step 1: Disable Level Up modal**

In `home_screen.dart` `_processGamificationEvent`:
```dart
case GamificationEventType.levelUp:
  // Removed: no more level celebrations
  break;
```

**Step 2: Soften badge unlock modal**

In `badge_unlock_modal.dart`:
- Reduce confetti to subtle particles (not explosive)
- Change title from "وسام جديد!" to a warmer message specific to the badge
- Keep share functionality

**Step 3: Commit**

```
feat: remove level-up modal, soften badge unlock celebration
```

---

## Phase 2: AI Evolution

### Task 10: Build AI Briefing Card widget

The core new widget for the home screen — a proactive, actionable card from واصل.

**Files:**
- Create: `lib/features/home/widgets/ai_briefing_card.dart`
- Create: `lib/features/home/providers/ai_briefing_provider.dart`

**Step 1: Create the briefing provider**

```dart
// lib/features/home/providers/ai_briefing_provider.dart

@riverpod
Future<AIBriefing?> aiBriefing(Ref ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;

  final relatives = await ref.watch(viewerFilteredRelativesProvider.future);
  final interactions = await ref.watch(recentInteractionsStreamProvider(userId).future);

  // Priority 1: Upcoming occasion (birthday within 3 days)
  final upcoming = relatives.where((r) =>
    r.dateOfBirth != null && _daysUntilBirthday(r.dateOfBirth!) <= 3
  ).toList();
  if (upcoming.isNotEmpty) {
    final r = upcoming.first;
    final days = _daysUntilBirthday(r.dateOfBirth!);
    return AIBriefing(
      emoji: '🎂',
      message: days == 0
          ? 'اليوم عيد ميلاد ${r.fullName}!'
          : 'عيد ميلاد ${r.fullName} بعد ${days == 1 ? "يوم" : "$days أيام"}',
      actions: [BriefingAction.call, BriefingAction.message],
      relativeId: r.id,
    );
  }

  // Priority 2: Extended relative with longest gap
  final extended = relatives
      .where((r) => r.relativeCategory == RelativeCategory.extended)
      .where((r) => r.lastContactDate != null)
      .toList()
    ..sort((a, b) => a.lastContactDate!.compareTo(b.lastContactDate!));
  if (extended.isNotEmpty) {
    final r = extended.first;
    final days = DateTime.now().difference(r.lastContactDate!).inDays;
    if (days >= 7) {
      return AIBriefing(
        emoji: '💛',
        message: 'لك ${_arabicDays(days)} ما تواصلت مع ${r.fullName}',
        actions: [BriefingAction.call, BriefingAction.message],
        relativeId: r.id,
      );
    }
  }

  // Priority 3: Household quality suggestion
  final household = relatives
      .where((r) => r.relativeCategory == RelativeCategory.household)
      .toList();
  if (household.isNotEmpty) {
    return AIBriefing(
      emoji: '🏠',
      message: 'وش رايك تسأل ${household.first.fullName} عن يومه اليوم؟',
      actions: [],
      relativeId: null,
    );
  }

  return null;
}

class AIBriefing {
  final String emoji;
  final String message;
  final List<BriefingAction> actions;
  final String? relativeId;

  const AIBriefing({
    required this.emoji,
    required this.message,
    required this.actions,
    this.relativeId,
  });
}

enum BriefingAction { call, message, visit }
```

**Step 2: Create the briefing card widget**

```dart
// lib/features/home/widgets/ai_briefing_card.dart

class AIBriefingCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefingAsync = ref.watch(aiBriefingProvider);
    return briefingAsync.when(
      data: (briefing) {
        if (briefing == null) return const SizedBox.shrink();
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('واصل يقولك:', style: ...),
                  const Spacer(),
                  // AI sparkle icon
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(briefing.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(briefing.message, style: ...),
                  ),
                ],
              ),
              if (briefing.actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: briefing.actions.map((action) =>
                    _ActionButton(action: action, relativeId: briefing.relativeId)
                  ).toList(),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
```

**Step 3: Commit**

```
feat: add AI briefing card with proactive family suggestions
```

---

### Task 11: Build One-Question Engine

Progressive fact-gathering after quick connects.

**Files:**
- Create: `lib/core/services/one_question_engine.dart`
- Create: `lib/shared/widgets/follow_up_question_sheet.dart`
- Modify: `lib/features/home/widgets/quick_log_faces.dart`

**Step 1: Create the question engine service**

```dart
// lib/core/services/one_question_engine.dart

class OneQuestionEngine {
  static const _prefsKey = 'one_question_';
  static const _maxQuestionsPerWeek = 4;

  /// Returns a follow-up question for this relative, or null if not appropriate
  static Future<FollowUpQuestion?> getQuestion({
    required Relative relative,
    required SharedPreferences prefs,
  }) async {
    // Check rate limit: max 4 questions per week
    final weekCount = prefs.getInt('${_prefsKey}week_count') ?? 0;
    final weekStart = prefs.getString('${_prefsKey}week_start');
    final now = DateTime.now();

    if (weekStart != null) {
      final start = DateTime.parse(weekStart);
      if (now.difference(start).inDays >= 7) {
        // New week — reset
        await prefs.setInt('${_prefsKey}week_count', 0);
        await prefs.setString('${_prefsKey}week_start', now.toIso8601String());
      } else if (weekCount >= _maxQuestionsPerWeek) {
        return null; // Already asked enough this week
      }
    } else {
      await prefs.setString('${_prefsKey}week_start', now.toIso8601String());
    }

    // Pick question based on what we DON'T know yet
    final asked = prefs.getStringList('${_prefsKey}asked_${relative.id}') ?? [];
    final question = _pickQuestion(relative, asked);
    return question;
  }

  static FollowUpQuestion? _pickQuestion(Relative relative, List<String> asked) {
    final questions = <String, FollowUpQuestion>{
      'interests': FollowUpQuestion(
        key: 'interests',
        text: 'وش الشي اللي يحبه ${relative.fullName} يسوّيه بوقت فراغه؟',
        field: 'interests',
      ),
      'health': FollowUpQuestion(
        key: 'health',
        text: 'كيف صحة ${relative.fullName} هالفترة؟',
        field: 'health_status',
      ),
      'communication_style': FollowUpQuestion(
        key: 'communication_style',
        text: '${relative.fullName} يفضل الاتصال ولا الرسائل؟',
        field: 'communication_style',
      ),
      'best_time': FollowUpQuestion(
        key: 'best_time',
        text: 'متى أحسن وقت تتواصل مع ${relative.fullName}؟',
        field: 'best_time_to_contact',
      ),
      'sensitive_topics': FollowUpQuestion(
        key: 'sensitive_topics',
        text: 'فيه شي يزعل ${relative.fullName} لو تكلمته عنه؟',
        field: 'sensitive_topics',
      ),
    };

    // Skip questions for fields already populated
    final candidates = questions.entries.where((e) {
      if (asked.contains(e.key)) return false;
      return switch (e.value.field) {
        'interests' => relative.interests == null || relative.interests!.isEmpty,
        'health_status' => relative.healthStatus == null,
        'communication_style' => relative.communicationStyle == null,
        'best_time_to_contact' => relative.bestTimeToContact == null,
        'sensitive_topics' => relative.sensitiveTopics == null || relative.sensitiveTopics!.isEmpty,
        _ => true,
      };
    }).toList();

    if (candidates.isEmpty) return null;
    return candidates.first.value;
  }

  /// Save the answer and update rate limit
  static Future<void> recordAnswer({
    required String relativeId,
    required String questionKey,
    required SharedPreferences prefs,
  }) async {
    final asked = prefs.getStringList('${_prefsKey}asked_$relativeId') ?? [];
    asked.add(questionKey);
    await prefs.setStringList('${_prefsKey}asked_$relativeId', asked);

    final weekCount = prefs.getInt('${_prefsKey}week_count') ?? 0;
    await prefs.setInt('${_prefsKey}week_count', weekCount + 1);
  }
}

class FollowUpQuestion {
  final String key;
  final String text;
  final String field; // maps to Relative model field

  const FollowUpQuestion({
    required this.key,
    required this.text,
    required this.field,
  });
}
```

**Step 2: Create the follow-up question bottom sheet**

A minimal bottom sheet that shows the question, a text field, and submit/skip buttons. On submit, updates the relative's field via the repository and records the answer.

**Step 3: Wire into quick log faces**

After successful one-tap log in `quick_log_faces.dart`, check `OneQuestionEngine.getQuestion()`. If non-null, show the bottom sheet after a 1-second delay.

**Step 4: Commit**

```
feat: add one-question engine for progressive family knowledge building
```

---

### Task 12: Rewrite smart nudge notification language

**Files:**
- Modify: `supabase/functions/send-smart-nudges/index.ts`
- Modify: `lib/core/services/notification_config_service.dart`

**Step 1: Update fallback notification templates**

In `notification_config_service.dart`, change nudge templates from urgency to warmth:

```dart
// Before:
'nudge_7_days': ('لهم أسبوع ما حد كلمهم 📞', '{{relative_label}} ما سمعوا منك من أسبوع')
// After:
'nudge_7_days': ('{{relative_label}} يشتاق لك 💛', 'اتصال بسيط يسعدهم — وش رايك تتواصل معاهم؟')

// Before:
'nudge_30_days': ('شهر كامل ما تواصلت 😔', '{{relative_label}} لهم شهر ما سمعوا منك')
// After:
'nudge_30_days': ('وقت مناسب تتواصل 🤍', 'لك فترة ما تواصلت مع {{relative_label}} — رسالة بسيطة تفرق')
```

**Step 2: Update edge function nudge logic**

In `send-smart-nudges/index.ts`, ensure nudge templates use the warmth framing. If admin templates override, those take precedence.

**Step 3: Commit**

```
feat: rewrite notification language from urgency/guilt to warmth/encouragement
```

---

### Task 13: Implement reverse trial model

**Files:**
- Modify: `lib/core/services/subscription_service.dart`
- Modify: `lib/core/models/subscription_state.dart`
- Modify: `lib/features/subscription/screens/paywall_screen.dart`

**Step 1: Enable automatic trial start on first launch**

The app already supports trials via RevenueCat (`isTrialEligible`). Ensure that new users are automatically presented with the trial offer during onboarding rather than waiting for them to hit a paywall.

**Step 2: Update paywall copy for reverse trial**

After trial expires, the paywall should emphasize what they're LOSING:
- "لقد جربت واصل — مساعدك الذكي للعائلة"
- "استمر بالاستمتاع بـ X ميزة كنت تستخدمها"
- Show features they actually USED during trial (track via analytics)

**Step 3: Commit**

```
feat: implement reverse trial model with loss-framed paywall copy
```

---

## Phase 3: Home Screen Redesign

### Task 14: Restructure home screen widget order

**Files:**
- Modify: `lib/features/home/screens/home_screen.dart`

**Step 1: Reorder home screen widgets**

New order in the `Column`:
1. `HomeHeaderWidget` (unchanged)
2. `AIBriefingCard` (NEW — from Task 10)
3. `QuickLogFaces` (enhanced — from Task 4)
4. `IslamicReminderWidget` (kept, same position)
5. `OccasionCard` (kept)
6. `FamilyCirclesSection` (kept)
7. `DueRemindersSection` (kept)
8. `TodaysActivitySection` (kept)
9. `MessageWidget` (bottom position, kept)

**Removed from home:**
- `PremiumUpgradeBanner` — remove the widget call entirely
- `ProactiveInsightCard` — replaced by `AIBriefingCard`
- `AIPriorityContactsWidget` — merged into `AIBriefingCard`
- `AIInsightCard` — merged into `AIBriefingCard`
- `SetupRemindersSection` — remove (one-time, not permanent)
- `QuickActionsWidget` — remove (family tree access stays via bottom nav area or inline)

**Step 2: Add family tree shortcut**

Since QuickActionsWidget contained the family tree hero card, add a simple inline link elsewhere. Add a small icon button in the header area or keep a minimal shortcut row.

**Step 3: Commit**

```
feat: restructure home screen — AI briefing first, remove premium banner and redundant widgets
```

---

### Task 15: Adapt home screen for household relatives

**Files:**
- Modify: `lib/features/home/widgets/family_circles_section.dart`

**Step 1: Visual differentiation by category**

In the family circles section, group relatives by category with subtle section headers:
- 🏠 أهل البيت (household — no "days since contact" shown)
- 📞 تواصل (extended — show contact status)
- 🌙 مناسبات (distant — show next occasion if available)

**Step 2: Commit**

```
feat: group family circles by relative category with visual differentiation
```

---

## Phase 4: Social Layer

### Task 16: Create Family Activity Feed widget

**Files:**
- Create: `lib/features/family_groups/widgets/family_activity_feed.dart`
- Modify: `lib/features/family_groups/screens/family_group_screen.dart`

**Step 1: Create the feed widget**

Shows recent group member interactions as a timeline:
```
"أحمد تواصل مع جدته اليوم 📞"
"سارة زارت خالتها أمس 🏠"
```

Uses `groupTodayInteractionsStreamProvider` and the relatives list to build human-readable activity items. No competitive stats — just warm awareness.

**Step 2: Add to group detail screen and home screen**

Add `FamilyActivityFeed` to:
- The family group detail screen
- The home screen (below family circles, only shown if user is in a group)

**Step 3: Commit**

```
feat: add family activity feed showing collective connection without competition
```

---

### Task 17: Add collective family celebration stats

**Files:**
- Create: `lib/features/family_groups/widgets/family_celebration_card.dart`

**Step 1: Create celebration card**

A card showing collective (not competitive) family stats:
- "عائلتكم تواصلت X مرة هذا الشهر 🎉"
- "X أشخاص من العائلة تواصلوا هذا الأسبوع"

No ranking, no individual scores. Just collective warmth.

**Step 2: Add to My Journey screen and home**

Show this card in the redesigned "رحلتي" screen and optionally on the home screen for group members.

**Step 3: Commit**

```
feat: add collective family celebration stats widget
```

---

## Phase 5: Advanced AI

### Task 18: Enhance AI context with relative categories

**Files:**
- Modify: `lib/core/ai/ai_context_engine.dart`
- Modify: `lib/core/ai/ai_prompts.dart`

**Step 1: Include category in context**

In `AIContextEngine`, when building relative summaries for the AI prompt, include the category:
```
- أحمد (أبوك) [أهل البيت] — لا يحتاج تتبع تواصل
- خالك سعد [تواصل دائم] — آخر تواصل: ١٤ يوم 🟡
- ابن عمك محمد [مناسبات] — عيد ميلاده بعد أسبوع
```

**Step 2: Update system prompt**

In `AIPrompts`, add category-aware instructions:
```
## أنواع الأقارب:
- أهل البيت: لا تنبّه على التواصل معهم — ركّز على جودة العلاقة ولحظات مشتركة
- تواصل دائم: نبّه لو مرت فترة بدون تواصل — اقترح طرق تواصل مناسبة
- مناسبات: ركّز على المناسبات القادمة والتهاني — لا تضغط على التواصل اليومي
```

**Step 3: Commit**

```
feat: enhance AI context and prompts with relative category awareness
```

---

### Task 19: Enhance AI briefing with compound insights

**Files:**
- Modify: `lib/features/home/providers/ai_briefing_provider.dart`

**Step 1: Add compound insight logic**

Enhance the briefing provider to combine multiple data points:
- Birthday + hobby: "عيد ميلاد أبوك بعد ٣ أيام — يحب الصيد، وش رايك تفاجئه؟"
- Health concern + gap: "أمك ذكرت إنها تعبانة + لك ٤ أيام ما اتصلت — تطمّن عليها"
- Pattern + occasion: "عادةً تتصل على جدتك يوم الجمعة — اليوم جمعة 🤍"

This uses data from: `Relative` fields (interests, health_status, dateOfBirth), interaction patterns, and AI memories.

**Step 2: Commit**

```
feat: add compound insights to AI briefing (birthday+hobby, health+gap, pattern+occasion)
```

---

### Task 20: Add seasonal/Islamic calendar intelligence

**Files:**
- Create: `lib/core/services/islamic_calendar_service.dart`
- Modify: `lib/features/home/providers/ai_briefing_provider.dart`

**Step 1: Create Islamic calendar service**

A utility that knows about:
- Ramadan start/end (approximate from Hijri calendar)
- Eid al-Fitr, Eid al-Adha dates
- Jumu'ah (every Friday)
- Current Islamic month

Uses the `hijri` package (if available) or manual calculation.

**Step 2: Wire into briefing provider**

Add seasonal awareness to AI briefings:
- Pre-Ramadan (2 weeks before): "رمضان قرب — وش رايك تجهز رسائل لأقاربك؟"
- During Ramadan: "بعد الإفطار وقت حلو تتصل على عائلتك"
- Eid: "كل عام وأنت بخير — واصل يقدر يكتب لك رسائل عيد"
- Friday: "الجمعة يوم مبارك للتواصل مع الأهل 🤍"

**Step 3: Commit**

```
feat: add Islamic calendar awareness to AI briefing (Ramadan, Eid, Jumu'ah)
```

---

## Summary

| Phase | Tasks | Focus |
|-------|-------|-------|
| Phase 1: Foundation | Tasks 1-9 | Relative categories, one-tap log, de-cringe gamification |
| Phase 2: AI Evolution | Tasks 10-13 | AI briefing card, one-question engine, warm notifications, reverse trial |
| Phase 3: Home Redesign | Tasks 14-15 | Restructured home, category-aware UI |
| Phase 4: Social | Tasks 16-17 | Family activity feed, collective celebration |
| Phase 5: Advanced AI | Tasks 18-20 | Category-aware AI, compound insights, Islamic calendar |

**Total: 20 tasks across 5 phases.**

Each phase is independently deployable. Phase 1 is the foundation that enables everything else. Phases 2-5 can be worked on in parallel after Phase 1 is complete.
