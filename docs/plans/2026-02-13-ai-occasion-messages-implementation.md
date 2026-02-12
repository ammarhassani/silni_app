# AI-Powered Occasion Messages Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace static template-based occasion messages with personalized DeepSeek-generated messages, gated behind MAX subscription.

**Architecture:** Single batch DeepSeek call generates messages for all relatives at once. Reuses existing `DeepSeekAIService`, `AIPrompts`, and `AIEngagingLoader`. New Riverpod provider manages async state (loading/data/error). OccasionCard gates navigation behind MAX.

**Tech Stack:** Flutter, Riverpod, DeepSeek API (via Supabase edge function proxy), flutter_animate

---

### Task 1: Add `occasionMessages` Feature ID

**Files:**
- Modify: `lib/core/models/subscription_tier.dart:148` (after `weeklyReports`)

**Step 1: Add the feature ID constant**

In `FeatureIds` class, after line 147 (`weeklyReports`), add:

```dart
static const String occasionMessages = 'occasion_messages';
```

And in the `requiredTier` switch (after line 173), add before the default:

```dart
occasionMessages => SubscriptionTier.max,
```

**Step 2: Commit**

```bash
git add lib/core/models/subscription_tier.dart
git commit -m "feat: add occasionMessages feature ID for MAX gating"
```

---

### Task 2: Add Batch Occasion Prompt to `AIPrompts`

**Files:**
- Modify: `lib/core/ai/ai_prompts.dart` (after `messageGenerationPrompt` at line 777)

**Step 1: Add the batch prompt method**

After `messageGenerationPrompt` (line 777), add:

```dart
/// System prompt for batch occasion message generation.
/// Generates one personalized message per relative in a single API call.
static String occasionBatchPrompt({
  required List<Relative> relatives,
  required String occasionType,
  String? occasionPromptAddition,
}) {
  final personality = dynamicPersonality;

  final relativesBlock = StringBuffer();
  for (var i = 0; i < relatives.length; i++) {
    final r = relatives[i];
    relativesBlock.writeln('${i + 1}. ID: "${r.id}"');
    relativesBlock.writeln('   - الاسم: ${r.fullName}');
    relativesBlock.writeln('   - العلاقة: ${r.relationshipType.arabicName}');
    if (r.personalityType != null) {
      relativesBlock.writeln('   - نوع الشخصية: ${r.personalityType}');
    }
    if (r.communicationStyle != null) {
      relativesBlock.writeln('   - أسلوب التواصل: ${r.communicationStyle}');
    }
    if (r.interests != null && r.interests!.isNotEmpty) {
      relativesBlock.writeln('   - الاهتمامات: ${r.interests!.join("، ")}');
    }
    if (r.relationshipStrengths != null) {
      relativesBlock.writeln('   - نقاط قوة العلاقة: ${r.relationshipStrengths}');
    }
  }

  return '''
أنت كاتب رسائل محترف متخصص في الرسائل العائلية.

$personality

## المناسبة: $occasionType
${occasionPromptAddition != null ? '## تعليمات خاصة: $occasionPromptAddition' : ''}

## أفراد العائلة:
$relativesBlock

## تعليمات:
اكتب رسالة تهنئة واحدة لكل شخص. كل رسالة:
- فريدة ومختلفة عن باقي الرسائل
- مناسبة لنوع العلاقة
- دافئة وطبيعية
- 20-40 كلمة فقط
- لا تكرر نفس العبارات أو الأنماط

قدّم الإجابة بتنسيق JSON فقط:
{
  "messages": {
    "<relative_id>": "<الرسالة>",
    ...
  }
}
''';
}
```

**Step 2: Commit**

```bash
git add lib/core/ai/ai_prompts.dart
git commit -m "feat: add batch occasion message prompt to AIPrompts"
```

---

### Task 3: Add `generateOccasionMessages` to `DeepSeekAIService`

**Files:**
- Modify: `lib/core/ai/deepseek_ai_service.dart` (after `generateMessages` at ~line 275)

**Step 1: Add the batch generation method**

After `generateMessages` method (line 275), add:

```dart
/// Generate personalized occasion messages for multiple relatives in a single call.
/// Returns a map of relative ID → message string.
Future<Map<String, String>> generateOccasionMessages({
  required List<Relative> relatives,
  required String occasionType,
}) async {
  try {
    final config = AIConfigService.instance;
    final params = config.getParametersFor('message_generation');

    final occasionConfig = config.messageOccasions
        .cast<AIMessageOccasion?>()
        .firstWhere((o) => o?.occasionKey == occasionType, orElse: () => null);

    final prompt = AIPrompts.occasionBatchPrompt(
      relatives: relatives,
      occasionType: occasionType,
      occasionPromptAddition: occasionConfig?.promptAddition,
    );

    final response = await getChatCompletion(
      messages: [
        ChatMessage(
          id: '',
          conversationId: '',
          userId: '',
          role: MessageRole.user,
          content: 'اكتب رسائل المناسبة',
          createdAt: DateTime.now(),
        ),
      ],
      systemPrompt: prompt,
      temperature: params.temperature,
      maxTokens: params.maxTokens,
      timeoutSeconds: params.timeoutSeconds,
    );

    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
    if (jsonMatch == null) {
      throw AIServiceException('Invalid response format');
    }

    final data = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
    final messagesMap = data['messages'] as Map<String, dynamic>?;
    if (messagesMap == null) {
      throw AIServiceException('Missing messages in response');
    }

    return messagesMap.map((key, value) => MapEntry(key, value.toString()));
  } catch (e) {
    _logger.error(
      'Occasion message generation error',
      category: LogCategory.network,
      tag: 'DeepSeekAIService',
      metadata: {'error': e.toString()},
    );
    rethrow;
  }
}
```

**Step 2: Commit**

```bash
git add lib/core/ai/deepseek_ai_service.dart
git commit -m "feat: add generateOccasionMessages batch method to DeepSeekAIService"
```

---

### Task 4: Create Occasion Messages Provider

**Files:**
- Create: `lib/features/ai_assistant/providers/occasion_messages_provider.dart`

**Step 1: Create the Riverpod provider**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:silni_app/core/ai/deepseek_ai_service.dart';
import 'package:silni_app/features/ai_assistant/services/occasion_message_service.dart';
import 'package:silni_app/features/home/providers/home_providers.dart';
import 'package:silni_app/shared/models/relative_model.dart';

/// State for AI-generated occasion messages.
class OccasionMessagesState {
  final bool isLoading;
  final List<OccasionMessage>? messages;
  final String? error;

  const OccasionMessagesState({
    this.isLoading = false,
    this.messages,
    this.error,
  });

  OccasionMessagesState copyWith({
    bool? isLoading,
    List<OccasionMessage>? messages,
    String? error,
  }) {
    return OccasionMessagesState(
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      error: error,
    );
  }
}

/// Provider that manages AI-generated occasion messages.
/// Caches in memory — navigating back won't re-trigger generation.
class OccasionMessagesNotifier extends StateNotifier<OccasionMessagesState> {
  OccasionMessagesNotifier() : super(const OccasionMessagesState());

  final _aiService = DeepSeekAIService();

  /// Generate AI messages for all relatives for the given occasion.
  /// Falls back to templates if AI fails.
  Future<void> generate({
    required OccasionType occasion,
    required List<Relative> relatives,
  }) async {
    // Already generated — skip
    if (state.messages != null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final aiMessages = await _aiService.generateOccasionMessages(
        relatives: relatives,
        occasionType: occasion.key,
      );

      final messages = relatives.map((relative) {
        final aiMessage = aiMessages[relative.id];
        // If AI didn't return a message for this relative, use template fallback
        final message = aiMessage ??
            OccasionMessageService.generateMessages(
              occasion: occasion,
              relatives: [relative],
            ).first.message;

        return OccasionMessage(
          relativeId: relative.id,
          relativeName: relative.fullName,
          relationshipType: relative.relationshipType.arabicName,
          occasion: occasion,
          message: message,
          generatedAt: DateTime.now(),
        );
      }).toList();

      state = OccasionMessagesState(messages: messages);
    } catch (e) {
      // Fallback to templates on error
      final templateMessages = OccasionMessageService.generateMessages(
        occasion: occasion,
        relatives: relatives,
      );
      state = OccasionMessagesState(
        messages: templateMessages,
        error: e.toString(),
      );
    }
  }

  /// Reset state (e.g., for retry).
  void reset() {
    state = const OccasionMessagesState();
  }
}

/// Keyed by occasion type so each occasion has its own cached state.
final occasionMessagesProvider = StateNotifierProvider.family<
    OccasionMessagesNotifier, OccasionMessagesState, OccasionType>(
  (ref, occasion) => OccasionMessagesNotifier(),
);
```

**Step 2: Commit**

```bash
git add lib/features/ai_assistant/providers/occasion_messages_provider.dart
git commit -m "feat: add OccasionMessagesNotifier provider with AI generation and template fallback"
```

---

### Task 5: Rewrite `OccasionMessagesScreen` with AI + Loading + MAX Gate

**Files:**
- Modify: `lib/features/ai_assistant/screens/occasion_messages_screen.dart`

**Step 1: Rewrite the screen**

Replace the entire file content. Key changes:
- Add MAX subscription check at top of `build()`
- Show `PaywallScreen` if not MAX
- Use `occasionMessagesProvider` instead of direct template call
- Show `AIEngagingLoader` during generation
- Show retry button on error
- Keep existing `_OccasionMessageCard` and `_shareAll` logic

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:silni_app/core/constants/app_animations.dart';
import 'package:silni_app/core/constants/app_spacing.dart';
import 'package:silni_app/core/constants/app_typography.dart';
import 'package:silni_app/core/models/subscription_tier.dart';
import 'package:silni_app/core/providers/subscription_provider.dart';
import 'package:silni_app/core/theme/theme_provider.dart';
import 'package:silni_app/features/ai_assistant/providers/occasion_messages_provider.dart';
import 'package:silni_app/features/ai_assistant/services/occasion_message_service.dart';
import 'package:silni_app/features/ai_assistant/widgets/ai_loading_indicator.dart';
import 'package:silni_app/features/home/providers/home_providers.dart';
import 'package:silni_app/features/subscription/screens/paywall_screen.dart';
import 'package:silni_app/shared/widgets/glass_card.dart';
import 'package:silni_app/shared/widgets/gradient_background.dart';
import 'package:silni_app/core/config/supabase_config.dart';

/// Screen that shows AI-generated occasion messages for the user's relatives.
/// Gated behind MAX subscription.
class OccasionMessagesScreen extends ConsumerStatefulWidget {
  const OccasionMessagesScreen({super.key, required this.occasion});

  final OccasionType occasion;

  @override
  ConsumerState<OccasionMessagesScreen> createState() =>
      _OccasionMessagesScreenState();
}

class _OccasionMessagesScreenState
    extends ConsumerState<OccasionMessagesScreen> {
  String _occasionEmoji(OccasionType occasion) {
    switch (occasion) {
      case OccasionType.eidAlFitr:
        return '🌙';
      case OccasionType.eidAlAdha:
        return '🐑';
      case OccasionType.ramadan:
        return '🕌';
      case OccasionType.nationalDay:
        return '🇸🇦';
    }
  }

  List<String> _loadingMessages(OccasionType occasion) {
    switch (occasion) {
      case OccasionType.ramadan:
        return [
          'يكتب رسائل رمضان مميزة...',
          'يختار كلمات دافئة لعائلتك...',
          'يراعي شخصية كل فرد...',
          'لحظات وتكون الرسائل جاهزة...',
        ];
      case OccasionType.eidAlFitr:
      case OccasionType.eidAlAdha:
        return [
          'يكتب رسائل العيد لأحبابك...',
          'يختار كلمات تناسب كل شخص...',
          'يراعي شخصية كل فرد...',
          'لحظات وتكون الرسائل جاهزة...',
        ];
      case OccasionType.nationalDay:
        return [
          'يكتب رسائل اليوم الوطني...',
          'يختار كلمات وطنية مميزة...',
          'يراعي شخصية كل فرد...',
          'لحظات وتكون الرسائل جاهزة...',
        ];
    }
  }

  void _triggerGeneration(List<Relative> relatives) {
    ref
        .read(occasionMessagesProvider(widget.occasion).notifier)
        .generate(occasion: widget.occasion, relatives: relatives);
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    final userId = SupabaseConfig.currentUser?.id;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // MAX subscription gate
    final hasAccess =
        ref.watch(featureAccessProvider(FeatureIds.occasionMessages));
    if (!hasAccess) {
      return PaywallScreen(featureToUnlock: FeatureIds.occasionMessages);
    }

    final relativesAsync = ref.watch(viewerFilteredRelativesProvider);
    final occasionState = ref.watch(occasionMessagesProvider(widget.occasion));

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            '${_occasionEmoji(widget.occasion)} رسائل ${widget.occasion.arabicName}',
            style: AppTypography.titleLarge.copyWith(
              color: themeColors.textPrimary,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: themeColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: relativesAsync.when(
          data: (relatives) {
            if (relatives.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('👨‍👩‍👧‍👦', style: AppTypography.displaySmall),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'أضف أقاربك أولا لتظهر لك الرسائل',
                      style: AppTypography.bodyLarge.copyWith(
                        color: themeColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Trigger AI generation on first load
            if (occasionState.messages == null && !occasionState.isLoading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _triggerGeneration(relatives);
              });
            }

            // Loading state
            if (occasionState.isLoading) {
              return Center(
                child: AIEngagingLoader(
                  emoji: _occasionEmoji(widget.occasion),
                  messages: _loadingMessages(widget.occasion),
                  accentColor: themeColors.accent,
                ),
              );
            }

            // Messages ready
            final messages = occasionState.messages;
            if (messages == null) {
              return const SizedBox.shrink();
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return _OccasionMessageCard(
                        message: msg,
                        themeColors: themeColors,
                        index: index,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: AppSpacing.buttonHeight,
                      child: FilledButton.icon(
                        onPressed: () => _shareAll(context, messages),
                        icon: const Icon(Icons.share_rounded),
                        label: Text(
                          'مشاركة جميع الرسائل',
                          style: AppTypography.labelLarge,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: themeColors.primary,
                          foregroundColor: themeColors.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppSpacing.buttonRadius),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Text(
              'حدث خطأ في تحميل الأقارب',
              style: AppTypography.bodyLarge.copyWith(
                color: themeColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _shareAll(BuildContext context, List<OccasionMessage> messages) {
    final buffer = StringBuffer();
    buffer.writeln(
        'رسائل ${widget.occasion.arabicName} ${_occasionEmoji(widget.occasion)}');
    buffer.writeln('─────────────────');
    for (final msg in messages) {
      buffer.writeln();
      buffer.writeln('${msg.relativeName} (${msg.relationshipType}):');
      buffer.writeln(msg.message);
    }
    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box != null ? box.localToGlobal(Offset.zero) & box.size : null;
    Share.share(buffer.toString(), sharePositionOrigin: origin);
  }
}

/// Individual message card with copy and share actions.
class _OccasionMessageCard extends StatelessWidget {
  const _OccasionMessageCard({
    required this.message,
    required this.themeColors,
    required this.index,
  });

  final OccasionMessage message;
  final dynamic themeColors;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  message.relativeName,
                  style: AppTypography.titleSmall.copyWith(
                    color: themeColors.textPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: themeColors.primary.withOpacity(0.15),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    message.relationshipType,
                    style: AppTypography.labelSmall.copyWith(
                      color: themeColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message.message,
              style: AppTypography.bodyMedium.copyWith(
                color: themeColors.textPrimary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(
                        ClipboardData(text: message.message));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم نسخ رسالة ${message.relativeName}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.copy_rounded,
                    size: AppSpacing.iconSm,
                    color: themeColors.textSecondary,
                  ),
                  tooltip: 'نسخ',
                ),
                Builder(
                  builder: (btnContext) => IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      final box =
                          btnContext.findRenderObject() as RenderBox?;
                      final origin = box != null
                          ? box.localToGlobal(Offset.zero) & box.size
                          : null;
                      Share.share(message.message,
                          sharePositionOrigin: origin);
                    },
                    icon: Icon(
                      Icons.share_rounded,
                      size: AppSpacing.iconSm,
                      color: themeColors.textSecondary,
                    ),
                    tooltip: 'مشاركة',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: AppAnimations.normal,
          delay: AppAnimations.getStaggerDelay(index),
        )
        .slideY(begin: 0.1, end: 0);
  }
}
```

**Step 2: Commit**

```bash
git add lib/features/ai_assistant/screens/occasion_messages_screen.dart
git commit -m "feat: rewrite OccasionMessagesScreen with AI generation, loading UX, and MAX gate"
```

---

### Task 6: Smoke Test

**Step 1: Run build to verify no compilation errors**

```bash
flutter build ios --no-codesign --debug 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED (or at minimum no Dart compilation errors)

**Step 2: If build errors, fix imports/types and re-run**

**Step 3: Commit any fixes**

```bash
git add -A && git commit -m "fix: resolve build errors from occasion messages refactor"
```
