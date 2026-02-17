import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/badge_prestige.dart';
import '../../../shared/widgets/badge_unlock_modal.dart';
import '../../../shared/widgets/floating_points_overlay.dart';
import '../../../shared/widgets/level_up_modal.dart';
import '../../../shared/widgets/streak_milestone_modal.dart';
import '../../premium_onboarding/widgets/onboarding_completion_modal.dart';
import '../../subscription/widgets/subscription_congrats_dialog.dart';

/// Admin-only dev tools bottom sheet for QA-testing event-driven UI.
class DevToolsSheet extends ConsumerStatefulWidget {
  const DevToolsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DevToolsSheet(),
    );
  }

  @override
  ConsumerState<DevToolsSheet> createState() => _DevToolsSheetState();
}

class _DevToolsSheetState extends ConsumerState<DevToolsSheet> {
  // Level Up config
  int _oldLevel = 4;
  int _newLevel = 5;

  // Badge config
  String _selectedBadgeId = 'first_interaction';

  // Streak config
  int _selectedStreak = 7;

  // Subscription config
  bool _isAnnual = true;

  // Floating points config
  int _selectedPoints = 100;

  // Wrapped config
  int _selectedYear = DateTime.now().year;
  late String _selectedMonth = _recentMonths().first;

  static const _streakOptions = [3, 7, 14, 30, 100, 365];
  static const _pointsOptions = [50, 100, 250, 500];

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeColorsProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle + title
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.developer_mode,
                      color: colors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Dev Tools',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: colors.divider, height: 1),

          // Scrollable sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('Celebrations', Icons.celebration,
                    colors),

                  // Level Up
                  _buildTriggerCard(
                    title: 'Level Up',
                    icon: Icons.stars_rounded,
                    colors: colors,
                    config: Row(
                      children: [
                        _buildStepper(
                          label: 'Old',
                          value: _oldLevel,
                          onChanged: (v) =>
                              setState(() => _oldLevel = v),
                          min: 1,
                          max: 49,
                          colors: colors,
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.arrow_forward,
                            size: 16, color: colors.textSecondary),
                        const SizedBox(width: 12),
                        _buildStepper(
                          label: 'New',
                          value: _newLevel,
                          onChanged: (v) =>
                              setState(() => _newLevel = v),
                          min: 2,
                          max: 50,
                          colors: colors,
                        ),
                      ],
                    ),
                    onTrigger: () {
                      Navigator.pop(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        LevelUpModal.show(
                          context,
                          oldLevel: _oldLevel,
                          newLevel: _newLevel,
                          currentXP: 120,
                          xpToNextLevel: 200,
                        );
                      });
                    },
                  ),

                  // Badge Unlock
                  _buildTriggerCard(
                    title: 'Badge Unlock',
                    icon: Icons.military_tech,
                    colors: colors,
                    config: _buildBadgeDropdown(colors),
                    onTrigger: () {
                      final info =
                          BadgePrestige.getBadgeInfo(_selectedBadgeId);
                      Navigator.pop(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        BadgeUnlockModal.show(
                          context,
                          badgeId: _selectedBadgeId,
                          badgeName: info.name,
                          badgeDescription:
                              'تم فتح الوسام عبر أدوات المطور',
                        );
                      });
                    },
                  ),

                  // Streak Milestone
                  _buildTriggerCard(
                    title: 'Streak Milestone',
                    icon: Icons.local_fire_department,
                    colors: colors,
                    config: _buildChipSelector<int>(
                      options: _streakOptions,
                      selected: _selectedStreak,
                      labelBuilder: (v) => '$v',
                      onSelected: (v) =>
                          setState(() => _selectedStreak = v),
                      colors: colors,
                    ),
                    onTrigger: () {
                      Navigator.pop(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        StreakMilestoneModal.show(context,
                            streak: _selectedStreak);
                      });
                    },
                  ),

                  // Subscription Congrats
                  _buildTriggerCard(
                    title: 'Subscription Congrats',
                    icon: Icons.workspace_premium,
                    colors: colors,
                    config: _buildChipSelector<bool>(
                      options: const [true, false],
                      selected: _isAnnual,
                      labelBuilder: (v) => v ? 'Annual' : 'Monthly',
                      onSelected: (v) =>
                          setState(() => _isAnnual = v),
                      colors: colors,
                    ),
                    onTrigger: () {
                      Navigator.pop(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        SubscriptionCongratsDialog.show(context,
                            isAnnual: _isAnnual);
                      });
                    },
                  ),

                  // Onboarding Complete
                  _buildTriggerCard(
                    title: 'Onboarding Complete',
                    icon: Icons.check_circle_outline,
                    colors: colors,
                    onTrigger: () {
                      Navigator.pop(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        OnboardingCompletionModal.show(context);
                      });
                    },
                  ),

                  const SizedBox(height: AppSpacing.md),
                  _buildSectionHeader(
                      'Effects', Icons.auto_awesome, colors),

                  // Floating Points
                  _buildTriggerCard(
                    title: 'Floating Points',
                    icon: Icons.add_circle_outline,
                    colors: colors,
                    config: _buildChipSelector<int>(
                      options: _pointsOptions,
                      selected: _selectedPoints,
                      labelBuilder: (v) => '+$v',
                      onSelected: (v) =>
                          setState(() => _selectedPoints = v),
                      colors: colors,
                    ),
                    onTrigger: () {
                      Navigator.pop(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        context.showFloatingPoints(
                            points: _selectedPoints);
                      });
                    },
                  ),

                  const SizedBox(height: AppSpacing.md),
                  _buildSectionHeader(
                      'Wrapped', Icons.auto_stories, colors),

                  // Yearly Wrapped
                  _buildTriggerCard(
                    title: 'Yearly Wrapped',
                    icon: Icons.calendar_today,
                    colors: colors,
                    config: _buildChipSelector<int>(
                      options: [
                        DateTime.now().year - 1,
                        DateTime.now().year,
                      ],
                      selected: _selectedYear,
                      labelBuilder: (v) => '$v',
                      onSelected: (v) =>
                          setState(() => _selectedYear = v),
                      colors: colors,
                    ),
                    onTrigger: () {
                      Navigator.pop(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        context.push(
                          '${AppRoutes.yearlyWrapped}?year=$_selectedYear',
                        );
                      });
                    },
                  ),

                  // Monthly Wrapped
                  _buildTriggerCard(
                    title: 'Monthly Wrapped',
                    icon: Icons.date_range,
                    colors: colors,
                    config: _buildChipSelector<String>(
                      options: _recentMonths(),
                      selected: _selectedMonth,
                      labelBuilder: (v) =>
                          _monthLabel(DateTime.parse(v)),
                      onSelected: (v) =>
                          setState(() => _selectedMonth = v),
                      colors: colors,
                    ),
                    onTrigger: () {
                      Navigator.pop(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        context.push(
                          '${AppRoutes.monthlyWrapped}?month=$_selectedMonth',
                        );
                      });
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
    );
  }

  // ── Helpers ──

  Widget _buildSectionHeader(
      String title, IconData icon, dynamic colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriggerCard({
    required String title,
    required IconData icon,
    required dynamic colors,
    Widget? config,
    required VoidCallback onTrigger,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: onTrigger,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Trigger',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (config != null) ...[
            const SizedBox(height: 10),
            config,
          ],
        ],
      ),
    );
  }

  Widget _buildStepper({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    required int min,
    required int max,
    required dynamic colors,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: colors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: value > min ? () => onChanged(value - 1) : null,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.remove, size: 14, color: colors.primary),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '$value',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
        GestureDetector(
          onTap: value < max ? () => onChanged(value + 1) : null,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.add, size: 14, color: colors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildChipSelector<T>({
    required List<T> options,
    required T selected,
    required String Function(T) labelBuilder,
    required ValueChanged<T> onSelected,
    required dynamic colors,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: options.map((option) {
        final isSelected = option == selected;
        return GestureDetector(
          onTap: () => onSelected(option),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primary
                  : colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? colors.primary
                    : colors.divider,
              ),
            ),
            child: Text(
              labelBuilder(option),
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    isSelected ? colors.onPrimary : colors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBadgeDropdown(dynamic colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.divider),
      ),
      child: DropdownButton<String>(
        value: _selectedBadgeId,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: colors.surface,
        icon: Icon(Icons.expand_more, color: colors.textSecondary),
        style: GoogleFonts.cairo(
          fontSize: 13,
          color: colors.textPrimary,
        ),
        items: BadgePrestige.prestigeOrder.map((id) {
          final info = BadgePrestige.getBadgeInfo(id);
          return DropdownMenuItem<String>(
            value: id,
            child: Text(
              '${info.emoji}  ${info.name}',
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: colors.textPrimary,
              ),
            ),
          );
        }).toList(),
        onChanged: (v) {
          if (v != null) setState(() => _selectedBadgeId = v);
        },
      ),
    );
  }

  List<String> _recentMonths() {
    final now = DateTime.now();
    return List.generate(3, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return d.toIso8601String().split('T').first;
    });
  }

  String _monthLabel(DateTime d) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month]} ${d.year}';
  }
}
