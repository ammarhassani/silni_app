import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../wrapped/providers/wrapped_providers.dart';

const _dismissedDateKey = 'wrapped_entry_dismissed_date';

/// Home screen card that prompts users to view their Monthly Wrapped.
///
/// Visible during the first 7 days of each month. Shows a teaser of the
/// personality label from the previous month and navigates to the full
/// Monthly Wrapped experience on tap.
class WrappedEntryCard extends ConsumerStatefulWidget {
  const WrappedEntryCard({super.key});

  @override
  ConsumerState<WrappedEntryCard> createState() => _WrappedEntryCardState();
}

class _WrappedEntryCardState extends ConsumerState<WrappedEntryCard> {
  bool _dismissed = false;
  bool _checkedDismissState = false;

  @override
  void initState() {
    super.initState();
    _checkDismissState();
  }

  Future<void> _checkDismissState() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedMonth = prefs.getString(_dismissedDateKey);
    if (dismissedMonth != null) {
      final now = DateTime.now();
      // Dismissed for the whole month (won't reappear until next month)
      final currentMonthKey = '${now.year}-${now.month}';
      if (dismissedMonth == currentMonthKey) {
        if (mounted) setState(() => _dismissed = true);
      }
    }
    if (mounted) setState(() => _checkedDismissState = true);
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final currentMonthKey = '${now.year}-${now.month}';
    await prefs.setString(_dismissedDateKey, currentMonthKey);
    if (mounted) setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    // Only show during first 7 days of the month
    final now = DateTime.now();
    if (now.day > 7 || !_checkedDismissState || _dismissed) {
      return const SizedBox.shrink();
    }

    final previousMonth = DateTime(now.year, now.month - 1, 1);
    final wrappedAsync = ref.watch(monthlyWrappedProvider(previousMonth));

    return wrappedAsync.when(
      data: (wrapped) {
        if (wrapped.totalInteractions == 0) return const SizedBox.shrink();
        return _buildCard(context, wrapped.personalityEmoji, wrapped.personalityLabel, wrapped.totalInteractions);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildCard(BuildContext context, String emoji, String label, int interactions) {
    final themeColors = ref.watch(themeColorsProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ملخص الشهر الماضي جاهز!',
                      style: AppTypography.titleSmall.copyWith(
                        color: themeColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$label • $interactions تفاعل',
                      style: AppTypography.bodySmall.copyWith(
                        color: themeColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _dismiss,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: themeColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push(AppRoutes.monthlyWrapped),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'شوف ملخصك',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppAnimations.normal).slideY(begin: 0.1, end: 0),
    );
  }
}
