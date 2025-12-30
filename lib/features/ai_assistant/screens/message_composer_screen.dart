import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/message_composer_provider.dart';
import '../widgets/ai_error_card.dart';
import '../widgets/ai_loading_indicator.dart';
import '../widgets/relative_selector.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../shared/widgets/theme_aware_dialog.dart';

/// Screen for AI-powered message composition
class MessageComposerScreen extends ConsumerWidget {
  final String? initialRelativeId;

  const MessageComposerScreen({
    super.key,
    this.initialRelativeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(messageComposerProvider);
    final themeColors = ref.watch(themeColorsProvider);

    return Scaffold(
      backgroundColor: themeColors.background1,
      appBar: AppBar(
        backgroundColor: themeColors.background1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'كتابة رسالة',
          style: AppTypography.headlineSmall.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: state.selectedRelative != null && state.selectedOccasion != null
                ? () => ref.read(messageComposerProvider.notifier).generateMessages()
                : null,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Selection area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Relative selector
                    RelativeSelector(
                      selectedRelativeId: state.selectedRelative?.id,
                      onChanged: (relative) {
                        ref.read(messageComposerProvider.notifier).selectRelative(relative);
                      },
                      hintText: 'اختر المرسل إليه',
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Occasion chips
                    Text(
                      'نوع الرسالة',
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: messageOccasions.map((occasion) {
                        final isSelected = state.selectedOccasion == occasion['id'];
                        return _OccasionChip(
                          label: occasion['label']!,
                          emoji: occasion['emoji']!,
                          isSelected: isSelected,
                          themeColors: themeColors,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref.read(messageComposerProvider.notifier).selectOccasion(
                                  isSelected ? null : occasion['id'],
                                );
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Tone chips
                    Text(
                      'نبرة الرسالة',
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: toneOptions.map((tone) {
                        final isSelected = state.selectedTone == tone['id'];
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: tone == toneOptions.first ? 0 : AppSpacing.xs,
                            ),
                            child: _ToneChip(
                              label: tone['label']!,
                              emoji: tone['emoji']!,
                              isSelected: isSelected,
                              themeColors: themeColors,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                ref.read(messageComposerProvider.notifier).selectTone(
                                      isSelected ? null : tone['id'],
                                    );
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Generate button
                    _GenerateButton(
                      isEnabled: state.selectedRelative != null &&
                          state.selectedOccasion != null,
                      isLoading: state.isLoading,
                      themeColors: themeColors,
                      onPressed: () {
                        ref.read(messageComposerProvider.notifier).generateMessages();
                      },
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Results area
                    _buildResultsArea(context, ref, state, themeColors),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsArea(
    BuildContext context,
    WidgetRef ref,
    MessageComposerState state,
    ThemeColors themeColors,
  ) {
    // Error state
    if (state.error != null) {
      return AIErrorCard(
        error: state.error!,
        onRetry: () {
          ref.read(messageComposerProvider.notifier).generateMessages();
        },
      );
    }

    // Loading state
    if (state.isLoading) {
      return AIEngagingLoader(
        emoji: '✍️',
        messages: const [
          'واصل يكتب رسائل مميزة...',
          'يختار الكلمات المناسبة...',
          'يراعي النبرة المطلوبة...',
          'يضيف لمسات شخصية...',
          'لحظات وتكون الرسالة جاهزة...',
        ],
        accentColor: themeColors.accent,
      );
    }

    // No results yet
    if (state.generatedMessages.isEmpty) {
      return const SizedBox.shrink();
    }

    // Results
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر رسالة',
          style: AppTypography.titleSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...state.generatedMessages.asMap().entries.map((entry) {
          final index = entry.key;
          final message = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _MessageCard(
              message: message,
              index: index + 1,
              themeColors: themeColors,
            ).animate(delay: Duration(milliseconds: index * 100)).fadeIn().slideY(
                  begin: 0.1,
                  end: 0,
                ),
          );
        }),
      ],
    );
  }
}

/// Occasion selection chip
class _OccasionChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeColors themeColors;

  const _OccasionChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? themeColors.primary.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? themeColors.primaryLight
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? themeColors.primaryLight : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tone selection chip
class _ToneChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeColors themeColors;

  const _ToneChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? themeColors.accent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? themeColors.accent
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? themeColors.accent : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Generate button
class _GenerateButton extends StatelessWidget {
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onPressed;
  final ThemeColors themeColors;

  const _GenerateButton({
    required this.isEnabled,
    required this.isLoading,
    required this.onPressed,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: isEnabled && !isLoading ? onPressed : null,
      gradient: isEnabled
          ? LinearGradient(
              colors: [
                themeColors.primary.withValues(alpha: 0.5),
                themeColors.primaryLight.withValues(alpha: 0.3),
              ],
            )
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ] else ...[
              Icon(
                Icons.edit_note_rounded,
                color: isEnabled ? Colors.white : Colors.white38,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(
              isLoading ? 'جاري الكتابة...' : 'اكتب رسالة',
              style: AppTypography.titleMedium.copyWith(
                color: isEnabled ? Colors.white : Colors.white38,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Message preview card with copy, share, regenerate, and edit actions
class _MessageCard extends ConsumerWidget {
  final String message;
  final int index;
  final ThemeColors themeColors;

  const _MessageCard({
    required this.message,
    required this.index,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = message == '___LOADING___';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with number
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: themeColors.primary.withValues(alpha: 0.3),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: AppTypography.labelSmall.copyWith(
                      color: themeColors.primaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Regenerate button
              IconButton(
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white54,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20),
                color: Colors.white54,
                onPressed: isLoading
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        ref.read(messageComposerProvider.notifier).regenerateSingleMessage(index - 1);
                      },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'إعادة كتابة',
              ),
              const SizedBox(width: AppSpacing.xs),
              // Edit button
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 20),
                color: Colors.white54,
                onPressed: isLoading
                    ? null
                    : () => _showEditDialog(context, ref),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'تعديل',
              ),
              const SizedBox(width: AppSpacing.xs),
              // Copy button
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 20),
                color: Colors.white54,
                onPressed: isLoading
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: message));
                        HapticFeedback.lightImpact();
                        UIHelpers.showSnackBar(
                          context,
                          'تم نسخ الرسالة',
                          backgroundColor: themeColors.primary,
                          duration: const Duration(seconds: 2),
                        );
                      },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Share button
              IconButton(
                icon: const Icon(Icons.share_rounded, size: 20),
                color: Colors.white54,
                onPressed: isLoading
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        Share.share(message);
                      },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Message text or loading indicator
          if (isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white54,
                      strokeWidth: 2,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'جاري إعادة الكتابة...',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SelectableText(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                height: 1.6,
              ),
              textDirection: TextDirection.rtl,
            ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: message);

    showDialog(
      context: context,
      builder: (context) => ThemeAwareAlertDialog(
        title: 'تعديل الرسالة',
        titleIcon: const Icon(Icons.edit_note_rounded, color: Colors.white),
        content: TextField(
          controller: controller,
          maxLines: 8,
          textDirection: TextDirection.rtl,
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white,
            height: 1.6,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide.none,
            ),
            hintText: 'اكتب رسالتك هنا...',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: Colors.white38,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: AppTypography.labelMedium.copyWith(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(messageComposerProvider.notifier).updateMessage(index - 1, controller.text);
              Navigator.pop(context);
              HapticFeedback.lightImpact();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: Text(
              'حفظ',
              style: AppTypography.labelMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
