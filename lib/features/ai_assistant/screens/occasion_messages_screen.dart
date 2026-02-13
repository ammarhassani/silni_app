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
import 'package:silni_app/shared/models/relative_model.dart';
import 'package:silni_app/shared/utils/relationship_label_helper.dart';
import 'package:silni_app/shared/widgets/glass_card.dart';
import 'package:silni_app/shared/widgets/gradient_background.dart';
import 'package:silni_app/core/config/supabase_config.dart';
import 'package:silni_app/features/family_tree/providers/family_graph_providers.dart';

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

  void _triggerGeneration(
      List<Relative> relatives, Map<String, String>? labels) {
    ref
        .read(occasionMessagesProvider(widget.occasion).notifier)
        .generate(
          occasion: widget.occasion,
          relatives: relatives,
          relationshipLabels: labels,
        );
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

    // Family graph for perspective-aware labels
    final groupInfo = ref.watch(userFamilyGroupProvider).valueOrNull;
    final graph = groupInfo != null
        ? ref.watch(sharedFamilyGraphProvider((
            groupId: groupInfo.groupId,
            viewerNodeId: groupInfo.nodeId,
          )))
        : ref.watch(familyGraphProvider(userId));
    final effectiveViewerId = groupInfo?.nodeId ?? userId;

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

            // Build perspective-aware relationship labels
            final relativesMap = {for (final r in relatives) r.id: r};
            final relationshipLabels = <String, String>{
              for (final r in relatives)
                r.id: getRelationshipLabel(
                  relative: r,
                  viewerId: effectiveViewerId,
                  graph: graph,
                  relativesMap: relativesMap,
                ),
            };

            // Trigger AI generation on first load
            if (occasionState.messages == null && !occasionState.isLoading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _triggerGeneration(relatives, relationshipLabels);
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
