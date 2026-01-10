import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/ai_touch_point_provider.dart';
import '../../../../core/providers/subscription_provider.dart';
import '../../../../core/services/ai_touch_point_service.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/models/relative_model.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/skeleton_loader.dart';

/// AI-powered conversation starters bottom sheet (MAX subscription only)
///
/// Shows AI-generated conversation topics for a specific relative based on:
/// - Their interests
/// - Recent interaction history
/// - Personality type
/// - Relationship context
class AIConversationStartersSheet extends ConsumerStatefulWidget {
  const AIConversationStartersSheet({
    super.key,
    required this.relative,
  });

  final Relative relative;

  /// Show the sheet - returns null if user is not MAX subscriber
  static Future<void> show(BuildContext context, WidgetRef ref, Relative relative) async {
    final isMax = ref.read(isMaxProvider);
    if (!isMax) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AIConversationStartersSheet(relative: relative),
    );
  }

  @override
  ConsumerState<AIConversationStartersSheet> createState() => _AIConversationStartersSheetState();
}

class _AIConversationStartersSheetState extends ConsumerState<AIConversationStartersSheet> {
  bool _isRefreshing = false;

  void _handleRefresh() async {
    HapticFeedback.lightImpact();

    // Show loading state
    setState(() => _isRefreshing = true);

    // Clear service cache
    AITouchPointService.instance.clearResponseCache();

    // Invalidate provider to trigger refresh
    final request = AITouchPointRequest(
      screenKey: 'relative_detail',
      touchPointKey: 'conversation_starters',
      focusRelative: widget.relative,
    );
    ref.invalidate(aiTouchPointProvider(request));

    // Wait a brief moment then let the async state take over
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    final isMax = ref.watch(isMaxProvider);

    if (!isMax) {
      return const SizedBox.shrink();
    }

    // Request AI conversation starters from touch point service with relative context
    final request = AITouchPointRequest(
      screenKey: 'relative_detail',
      touchPointKey: 'conversation_starters',
      focusRelative: widget.relative,
    );
    final resultAsync = ref.watch(aiTouchPointProvider(request));

    // Check if loading (initial load or refresh)
    final isLoading = resultAsync.isLoading || _isRefreshing;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: themeColors.background1,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: themeColors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        themeColors.primary,
                        themeColors.primaryLight,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.messageCircle,
                    color: themeColors.onPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مواضيع للحديث',
                        style: AppTypography.titleMedium.copyWith(
                          color: themeColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'مع ${widget.relative.fullName}',
                        style: AppTypography.bodySmall.copyWith(
                          color: themeColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // AI Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        themeColors.primary,
                        themeColors.primaryLight,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.sparkles,
                        size: 14,
                        color: themeColors.onPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AI',
                        style: AppTypography.labelSmall.copyWith(
                          color: themeColors.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: isLoading
                  ? _buildLoadingState(themeColors)
                  : resultAsync.when(
                      data: (result) {
                        if (!result.success || result.content == null || result.content!.isEmpty) {
                          return _buildErrorState(themeColors);
                        }

                        // Parse conversation starters from AI response
                        final starters = _parseConversationStarters(result.content!);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...starters.asMap().entries.map((entry) {
                              final index = entry.key;
                              final starter = entry.value;
                              return _ConversationStarterCard(
                                topic: starter,
                                themeColors: themeColors,
                                index: index,
                              );
                            }),
                            const SizedBox(height: AppSpacing.md),
                            // Refresh button - styled like AI label
                            Center(
                              child: GestureDetector(
                                onTap: _handleRefresh,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        themeColors.primary,
                                        themeColors.primaryLight,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: themeColors.primary.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.refreshCw,
                                        size: 16,
                                        color: themeColors.onPrimary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'اقتراحات جديدة',
                                        style: AppTypography.labelMedium.copyWith(
                                          color: themeColors.onPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => _buildLoadingState(themeColors),
                      error: (_, _) => _buildErrorState(themeColors),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _parseConversationStarters(String content) {
    final starters = <String>[];

    // Try to parse as JSON first
    try {
      // Extract JSON array from response (might be wrapped in markdown code block)
      var jsonStr = content.trim();

      // Remove markdown code block if present
      if (jsonStr.contains('```')) {
        final match = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(jsonStr);
        if (match != null) {
          jsonStr = match.group(1) ?? jsonStr;
        }
      }

      // Find JSON array in the content
      final arrayMatch = RegExp(r'\[[\s\S]*\]').firstMatch(jsonStr);
      if (arrayMatch != null) {
        jsonStr = arrayMatch.group(0)!;
        final List<dynamic> parsed = json.decode(jsonStr);

        for (final item in parsed) {
          if (item is Map) {
            // Handle {"topic": "...", "opener": "..."} format
            final topic = item['topic'] as String? ?? '';
            final opener = item['opener'] as String? ?? '';
            if (topic.isNotEmpty) {
              starters.add(opener.isNotEmpty ? '$topic\n$opener' : topic);
            }
          } else if (item is String && item.isNotEmpty) {
            starters.add(item);
          }
        }

        if (starters.isNotEmpty) {
          return starters.take(5).toList();
        }
      }
    } catch (_) {
      // JSON parsing failed, fall back to line parsing
    }

    // Fallback: parse as numbered list or bullet points
    final lines = content.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Skip JSON-like lines
      if (trimmed.startsWith('{') || trimmed.startsWith('}') ||
          trimmed.startsWith('[') || trimmed.startsWith(']') ||
          trimmed.startsWith('"topic"') || trimmed.startsWith('"opener"')) {
        continue;
      }

      // Remove numbering, bullets, dashes
      var cleaned = trimmed
          .replaceFirst(RegExp(r'^[\d]+[.)\-:]\s*'), '')
          .replaceFirst(RegExp(r'^[-•*]\s*'), '')
          .trim();

      if (cleaned.isNotEmpty && cleaned.length > 3) {
        starters.add(cleaned);
      }
    }

    // If no starters found, return the whole content as one starter
    if (starters.isEmpty && content.trim().isNotEmpty) {
      starters.add(content.trim());
    }

    return starters.take(5).toList();
  }

  Widget _buildLoadingState(dynamic themeColors) {
    return Column(
      children: [
        // Loading message with animation
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // Animated sparkle icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeColors.primary,
                      themeColors.primaryLight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: themeColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  LucideIcons.sparkles,
                  color: themeColors.onPrimary,
                  size: 28,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 800.ms),
              const SizedBox(height: AppSpacing.md),
              Text(
                'جاري توليد مواضيع للحديث...',
                style: AppTypography.bodyMedium.copyWith(
                  color: themeColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Skeleton cards
        ...List.generate(3, (index) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SkeletonLoader(width: 28, height: 28, borderRadius: 8),
                    const Spacer(),
                    SkeletonLoader(width: 50, height: 24, borderRadius: 6),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const SkeletonLoader(width: double.infinity, height: 16, borderRadius: 4),
                const SizedBox(height: AppSpacing.xs),
                const SkeletonLoader(width: 200, height: 14, borderRadius: 4),
              ],
            ),
          ),
        )
            .animate(delay: Duration(milliseconds: 100 * index))
            .fadeIn(duration: AppAnimations.fast)
            .slideY(begin: 0.1, end: 0)),
      ],
    );
  }

  Widget _buildErrorState(dynamic themeColors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: themeColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'تعذر تحميل الاقتراحات',
              style: AppTypography.bodyMedium.copyWith(
                color: themeColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Retry button
            GestureDetector(
              onTap: _handleRefresh,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeColors.primary,
                      themeColors.primaryLight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'إعادة المحاولة',
                  style: AppTypography.labelMedium.copyWith(
                    color: themeColors.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationStarterCard extends StatelessWidget {
  const _ConversationStarterCard({
    required this.topic,
    required this.themeColors,
    required this.index,
  });

  final String topic;
  final dynamic themeColors;
  final int index;

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: topic));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ الموضوع',
          style: TextStyle(color: themeColors.onPrimary),
        ),
        backgroundColor: themeColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with number and copy button
          Row(
            children: [
              // Number badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeColors.primary,
                      themeColors.primaryLight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: AppTypography.labelMedium.copyWith(
                      color: themeColors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Copy button
              GestureDetector(
                onTap: () => _copyToClipboard(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: themeColors.glassBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: themeColors.glassBorder,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.copy,
                        size: 14,
                        color: themeColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'نسخ',
                        style: AppTypography.labelSmall.copyWith(
                          color: themeColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Topic text
          Text(
            topic,
            style: AppTypography.bodyMedium.copyWith(
              color: themeColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 50 * index))
        .fadeIn(duration: AppAnimations.fast)
        .slideY(begin: 0.1, end: 0);
  }
}
