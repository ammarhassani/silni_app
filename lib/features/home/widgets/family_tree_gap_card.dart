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
import '../../../shared/models/relative_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/home_providers.dart';

const _dismissedDateKey = 'family_tree_gap_dismissed_date';

/// Detects gaps in the user's family tree and suggests who to add next.
///
/// Shows one suggestion at a time based on priority: parents first,
/// then grandparents, then siblings, then extended family balance.
class FamilyTreeGapCard extends ConsumerStatefulWidget {
  const FamilyTreeGapCard({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<FamilyTreeGapCard> createState() => _FamilyTreeGapCardState();
}

class _FamilyTreeGapCardState extends ConsumerState<FamilyTreeGapCard> {
  bool _dismissed = false;
  bool _checkedDismissState = false;

  @override
  void initState() {
    super.initState();
    _checkDismissState();
  }

  Future<void> _checkDismissState() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedDate = prefs.getString(_dismissedDateKey);
    if (dismissedDate != null) {
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month}-${today.day}';
      if (dismissedDate == todayStr) {
        if (mounted) setState(() => _dismissed = true);
      }
    }
    if (mounted) setState(() => _checkedDismissState = true);
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    await prefs.setString(_dismissedDateKey, todayStr);
    if (mounted) setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checkedDismissState || _dismissed) return const SizedBox.shrink();

    final relativesAsync = ref.watch(viewerFilteredRelativesProvider);

    return relativesAsync.when(
      data: (relatives) {
        final gap = _detectGap(relatives);
        if (gap == null) return const SizedBox.shrink();
        return _buildCard(context, gap);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  _TreeGap? _detectGap(List<Relative> relatives) {
    final types = relatives.map((r) => r.relationshipType).toSet();

    // No parents at all
    final hasFather = types.contains(RelationshipType.father);
    final hasMother = types.contains(RelationshipType.mother);
    if (!hasFather && !hasMother) {
      return _TreeGap(
        emoji: '👨‍👩‍👧',
        message: 'أضف والديك لبناء شجرة العائلة',
        subtitle: 'الوالدين أساس الشجرة',
      );
    }

    // Has parents but no siblings
    final hasSiblings = types.contains(RelationshipType.brother) ||
        types.contains(RelationshipType.sister);
    if (!hasSiblings && (hasFather || hasMother)) {
      return _TreeGap(
        emoji: '👫',
        message: 'أضف إخوانك وأخواتك',
        subtitle: 'كمّل العائلة المباشرة',
      );
    }

    // Has parents but no grandparents
    final hasGrandparents = types.contains(RelationshipType.grandfather) ||
        types.contains(RelationshipType.grandmother);
    if (!hasGrandparents && (hasFather || hasMother)) {
      return _TreeGap(
        emoji: '👴',
        message: 'ما أضفت أجدادك بعد',
        subtitle: 'أضفهم لتكبر الشجرة',
      );
    }

    // Has father but no paternal uncles/aunts
    final hasPaternal = relatives.any((r) =>
        r.relationshipType == RelationshipType.uncle ||
        r.relationshipType == RelationshipType.aunt);
    if (hasFather && !hasPaternal) {
      return _TreeGap(
        emoji: '👨‍👦',
        message: 'أضف إخوان أبوك لتكمل الشجرة',
        subtitle: 'أعمامك وعماتك',
      );
    }

    // Has mother but check maternal side (simplified - check if any uncle/aunt exists)
    // If paternal uncles exist but no way to distinguish maternal, suggest adding more
    final totalUnclesAunts = relatives.where((r) =>
        r.relationshipType == RelationshipType.uncle ||
        r.relationshipType == RelationshipType.aunt).length;
    if (hasMother && totalUnclesAunts < 2) {
      return _TreeGap(
        emoji: '👩‍👦',
        message: 'أضف أخوال وخالات أمك',
        subtitle: 'كمّل طرف أمك في الشجرة',
      );
    }

    // No cousins
    final hasCousins = types.contains(RelationshipType.cousin);
    if (!hasCousins && totalUnclesAunts > 0) {
      return _TreeGap(
        emoji: '🤝',
        message: 'أضف أبناء عمومتك وخؤولتك',
        subtitle: 'وسّع دائرة التواصل',
      );
    }

    return null;
  }

  Widget _buildCard(BuildContext context, _TreeGap gap) {
    final themeColors = ref.watch(themeColorsProvider);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.addRelative),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Text(gap.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gap.message,
                    style: AppTypography.titleSmall.copyWith(
                      color: themeColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    gap.subtitle,
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
      ),
    ).animate().fadeIn(duration: AppAnimations.normal).slideY(begin: 0.1, end: 0);
  }
}

class _TreeGap {
  final String emoji;
  final String message;
  final String subtitle;

  const _TreeGap({
    required this.emoji,
    required this.message,
    required this.subtitle,
  });
}
