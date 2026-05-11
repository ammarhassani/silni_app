import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:silni_app/core/utils/contact_launcher.dart';
import '../../../shared/widgets/directional_icon.dart';

import 'package:silni_app/core/constants/app_animations.dart';
import 'package:silni_app/core/constants/app_spacing.dart';
import 'package:silni_app/core/constants/app_typography.dart';
import 'package:silni_app/core/models/subscription_tier.dart';
import 'package:silni_app/core/providers/subscription_provider.dart';
import 'package:silni_app/core/theme/theme_provider.dart';
import 'package:silni_app/shared/utils/ui_helpers.dart';
import 'package:silni_app/features/ai_assistant/providers/occasion_messages_provider.dart';
import 'package:silni_app/features/ai_assistant/services/occasion_message_service.dart';
import 'package:silni_app/features/ai_assistant/widgets/ai_loading_indicator.dart';
import 'package:silni_app/features/home/providers/home_providers.dart';
import 'package:silni_app/features/subscription/screens/paywall_screen.dart';
import 'package:silni_app/shared/models/relative_model.dart';
import 'package:silni_app/shared/utils/relationship_label_helper.dart';
import 'package:silni_app/shared/widgets/glass_card.dart';
import 'package:silni_app/shared/widgets/glass_pill_title.dart';
import 'package:silni_app/shared/widgets/glass_dialog.dart';
import 'package:silni_app/shared/widgets/gradient_background.dart';
import 'package:silni_app/shared/widgets/share_bottom_sheet.dart';
import 'package:silni_app/shared/widgets/share_cards/occasion_share_card.dart';
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
      return PaywallScreen(
        featureToUnlock: FeatureIds.occasionMessages,
        contextHeadline: PaywallContext.headlineForFeature(FeatureIds.occasionMessages),
      );
    }

    // Family graph for perspective-aware labels
    final groupInfo = ref.watch(activeFamilyGroupProvider).valueOrNull;
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
          title: GlassPillTitle(
            text: '${_occasionEmoji(widget.occasion)} رسائل ${widget.occasion.arabicName}',
            style: AppTypography.titleLarge.copyWith(
              color: themeColors.textOnGradient,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          leading: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Center(
              child: GlassIconButton(
                tooltip: 'رجوع',
                icon: DirectionalIcon(
                  Icons.arrow_back_ios_rounded,
                  color: themeColors.textOnGradient,
                  size: 18,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
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

            return ListView.builder(
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
                  occasionEmoji: _occasionEmoji(widget.occasion),
                  occasionName: widget.occasion.arabicName,
                );
              },
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

}

/// Individual message card with copy and share actions.
class _OccasionMessageCard extends StatelessWidget {
  const _OccasionMessageCard({
    required this.message,
    required this.themeColors,
    required this.index,
    required this.occasionEmoji,
    required this.occasionName,
  });

  final OccasionMessage message;
  final dynamic themeColors;
  final int index;
  final String occasionEmoji;
  final String occasionName;

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
                    UIHelpers.showSnackBar(
                      context,
                      'تم نسخ رسالة ${message.relativeName}',
                      duration: const Duration(seconds: 2),
                    );
                  },
                  icon: Icon(
                    Icons.copy_rounded,
                    size: AppSpacing.iconSm,
                    color: themeColors.textSecondary,
                  ),
                  tooltip: 'نسخ',
                ),
                IconButton(
                  onPressed: () {
                    ShareBottomSheet.show(
                      context,
                      cardBuilder: (format, {String? aiCopy}) => OccasionShareCard(
                        format: format,
                        occasionEmoji: occasionEmoji,
                        occasionName: occasionName,
                        greetingText: message.message,
                        copyText: aiCopy,
                      ),
                      shareText: '${message.message} #صِلْني',
                    );
                  },
                  icon: Icon(
                    Icons.image_rounded,
                    size: AppSpacing.iconSm,
                    color: themeColors.textSecondary,
                  ),
                  tooltip: 'مشاركة كبطاقة',
                ),
                if (message.phoneNumber != null &&
                    message.phoneNumber!.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ContactLauncher.openWhatsApp(
                        message.phoneNumber!,
                        context: context,
                        message: message.message,
                      );
                    },
                    icon: FaIcon(
                      FontAwesomeIcons.whatsapp,
                      size: AppSpacing.iconSm,
                      color: themeColors.textSecondary,
                    ),
                    tooltip: 'واتساب',
                  )
                else
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
