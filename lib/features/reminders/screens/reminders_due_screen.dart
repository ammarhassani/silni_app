import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/models/reminder_schedule_model.dart';
import '../../../shared/providers/interactions_provider.dart';
import '../../../shared/models/interaction_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/screens/home_screen.dart';

/// Screen that shows relatives due for contact from reminder notifications
class RemindersDueScreen extends ConsumerStatefulWidget {
  const RemindersDueScreen({super.key, this.relativeIds});

  /// List of relative IDs to show (passed from notification payload)
  final List<String>? relativeIds;

  @override
  ConsumerState<RemindersDueScreen> createState() => _RemindersDueScreenState();
}

class _RemindersDueScreenState extends ConsumerState<RemindersDueScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';
    final relativesAsync = ref.watch(relativesStreamProvider(userId));
    final schedulesAsync = ref.watch(reminderSchedulesStreamProvider(userId));
    // Watch today's contacted relatives from database (persists across navigation)
    final todayContactedAsync = ref.watch(todayContactedRelativesProvider(userId));

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(animated: true, child: SizedBox.expand()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: relativesAsync.when(
                    data: (relatives) {
                      // Get contacted relatives, default to empty set if loading/error
                      final contactedToday = todayContactedAsync.valueOrNull ?? {};
                      final schedules = schedulesAsync.valueOrNull ?? [];
                      return _buildContent(context, relatives, contactedToday, schedules);
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => _buildError(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حان وقت التواصل',
                  style: AppTypography.headlineLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تواصل مع أحبتك اليوم',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Relative> allRelatives,
    Set<String> contactedToday,
    List<ReminderSchedule> schedules,
  ) {
    // Filter relatives based on notification payload or show all due
    List<Relative> dueRelatives;
    if (widget.relativeIds != null && widget.relativeIds!.isNotEmpty) {
      dueRelatives = allRelatives
          .where((r) => widget.relativeIds!.contains(r.id))
          .toList();
    } else {
      // If no specific IDs, show relatives that haven't been contacted recently
      dueRelatives = allRelatives.where((r) {
        if (r.lastContactDate == null) return true;
        final daysSinceContact =
            DateTime.now().difference(r.lastContactDate!).inDays;
        return daysSinceContact >= 7; // Due if not contacted in 7+ days
      }).toList();
    }

    if (dueRelatives.isEmpty) {
      return _buildEmptyState();
    }

    // Build frequency map for all due relatives
    final relativeFrequencies = _buildRelativeFrequencyMap(schedules);

    return RefreshIndicator(
      onRefresh: () async {
        final user = ref.read(currentUserProvider);
        if (user != null) {
          ref.invalidate(relativesStreamProvider(user.id));
          ref.invalidate(todayContactedRelativesProvider(user.id));
          ref.invalidate(reminderSchedulesStreamProvider(user.id));
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: dueRelatives.length + 1, // +1 for summary card
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSummaryCard(dueRelatives, contactedToday);
          }
          final relative = dueRelatives[index - 1];
          final isContacted = contactedToday.contains(relative.id);
          final frequencies = relativeFrequencies[relative.id] ?? {};
          return _buildRelativeCard(relative, isContacted, frequencies)
              .animate()
              .fadeIn(delay: Duration(milliseconds: 50 * index))
              .slideX(begin: 0.1, end: 0);
        },
      ),
    );
  }

  /// Build a map of relative IDs to their active frequencies for today
  Map<String, Set<ReminderFrequency>> _buildRelativeFrequencyMap(List<ReminderSchedule> schedules) {
    final result = <String, Set<ReminderFrequency>>{};
    for (final schedule in schedules) {
      if (schedule.isActive && schedule.shouldFireToday()) {
        for (final relativeId in schedule.relativeIds) {
          result.putIfAbsent(relativeId, () => <ReminderFrequency>{});
          result[relativeId]!.add(schedule.frequency);
        }
      }
    }
    return result;
  }

  /// Build frequency badges for a relative (e.g., [🕌 جمعة] [يومي])
  List<Widget> _buildFrequencyBadges(List<ReminderFrequency> frequencies) {
    // Sort: Friday first, then alphabetically
    final sorted = frequencies.toList()
      ..sort((a, b) {
        if (a == ReminderFrequency.friday) return -1;
        if (b == ReminderFrequency.friday) return 1;
        return a.arabicName.compareTo(b.arabicName);
      });

    return sorted.map((freq) => Padding(
      padding: const EdgeInsets.only(left: 4),
      child: _buildFrequencyBadge(freq),
    )).toList();
  }

  /// Build a single frequency badge with special styling for Friday
  Widget _buildFrequencyBadge(ReminderFrequency frequency) {
    final isFriday = frequency == ReminderFrequency.friday;

    // Friday special green styling
    const fridayGreen = Color(0xFF1B5E20);
    const fridayGreenLight = Color(0xFF4CAF50);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isFriday
            ? fridayGreen.withOpacity(0.6)
            : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: isFriday
            ? Border.all(color: fridayGreenLight.withOpacity(0.5), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFriday) ...[
            const Text('🕌', style: TextStyle(fontSize: 10)),
            const SizedBox(width: 2),
          ],
          Text(
            frequency.arabicName,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontSize: 9,
              fontWeight: isFriday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<Relative> dueRelatives, Set<String> contactedToday) {
    final themeColors = ref.watch(themeColorsProvider);
    // Count how many of the due relatives have been contacted today
    final contactedCount = dueRelatives.where((r) => contactedToday.contains(r.id)).length;
    final totalCount = dueRelatives.length;
    final progress = totalCount > 0 ? contactedCount / totalCount : 0.0;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('', style: TextStyle(fontSize: 40)),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalCount أقارب للتواصل',
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'تم التواصل مع $contactedCount',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(themeColors.primary),
              minHeight: 8,
            ),
          ),
          if (contactedCount == totalCount && totalCount > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'أحسنت! أكملت صلة رحمك اليوم',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildRelativeCard(Relative relative, bool isContacted, Set<ReminderFrequency> frequencies) {
    final themeColors = ref.watch(themeColorsProvider);
    final daysSinceContact = relative.lastContactDate != null
        ? DateTime.now().difference(relative.lastContactDate!).inDays
        : null;
    final hasFriday = frequencies.contains(ReminderFrequency.friday);

    // Friday special green color
    const fridayGreen = Color(0xFF1B5E20);
    const fridayGreenLight = Color(0xFF4CAF50);

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      gradient: isContacted
          ? null
          : hasFriday
              ? LinearGradient(
                  colors: [
                    fridayGreen.withOpacity(0.25),
                    fridayGreenLight.withOpacity(0.1),
                  ],
                )
              : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: hasFriday && !isContacted
                      ? LinearGradient(colors: [fridayGreen, fridayGreenLight])
                      : themeColors.primaryGradient,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    hasFriday && !isContacted ? '🕌' : relative.displayEmoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            relative.fullName,
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: isContacted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (isContacted)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green,
                            size: 24,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          relative.relationshipType.arabicName,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        if (frequencies.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          ..._buildFrequencyBadges(frequencies.toList()),
                        ],
                      ],
                    ),
                    if (daysSinceContact != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        daysSinceContact == 0
                            ? 'آخر تواصل: اليوم'
                            : daysSinceContact == 1
                                ? 'آخر تواصل: أمس'
                                : 'آخر تواصل: منذ $daysSinceContact يوم',
                        style: AppTypography.bodySmall.copyWith(
                          color: daysSinceContact > 7
                              ? Colors.orange
                              : Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: Colors.white24),
          const SizedBox(height: AppSpacing.sm),
          // Action buttons - compact layout
          Row(
            children: [
              // Call button
              if (relative.phoneNumber != null &&
                  relative.phoneNumber!.isNotEmpty)
                Expanded(
                  child: _buildCompactButton(
                    icon: Icons.call_rounded,
                    label: 'اتصال',
                    color: Colors.green.shade600,
                    onTap: () => _makeCall(relative),
                  ),
                ),
              if (relative.phoneNumber != null &&
                  relative.phoneNumber!.isNotEmpty)
                const SizedBox(width: 6),
              // WhatsApp button
              if (relative.phoneNumber != null &&
                  relative.phoneNumber!.isNotEmpty)
                Expanded(
                  child: _buildCompactButton(
                    icon: FontAwesomeIcons.whatsapp,
                    label: 'واتساب',
                    color: const Color(0xFF25D366),
                    onTap: () => _openWhatsApp(relative),
                    useFaIcon: true,
                  ),
                ),
              if (relative.phoneNumber != null &&
                  relative.phoneNumber!.isNotEmpty)
                const SizedBox(width: 6),
              // SMS button
              if (relative.phoneNumber != null &&
                  relative.phoneNumber!.isNotEmpty)
                Expanded(
                  child: _buildCompactButton(
                    icon: Icons.sms_rounded,
                    label: 'رسالة',
                    color: Colors.blue.shade600,
                    onTap: () => _sendSMS(relative),
                  ),
                ),
              if (relative.phoneNumber != null &&
                  relative.phoneNumber!.isNotEmpty)
                const SizedBox(width: 6),
              // Mark as contacted / View details
              Expanded(
                child: _buildCompactButton(
                  icon: isContacted ? Icons.visibility_rounded : Icons.check_rounded,
                  label: isContacted ? 'التفاصيل' : 'تم',
                  color: isContacted ? Colors.purple.shade400 : themeColors.primary,
                  onTap: isContacted
                      ? () => _viewRelativeDetail(relative)
                      : () => _markAsContacted(relative),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('', style: TextStyle(fontSize: 64)),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'لا يوجد أقارب للتواصل الآن',
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'أحسنت! أنت متواصل مع جميع أحبتك',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              GradientButton(
                onPressed: () => context.go(AppRoutes.home),
                text: 'العودة للرئيسية',
                icon: Icons.home_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: GlassCard(
        margin: const EdgeInsets.all(AppSpacing.xl),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'حدث خطأ في تحميل البيانات',
              style: AppTypography.bodyLarge.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.lg),
            GradientButton(
              onPressed: () {
                final user = ref.read(currentUserProvider);
                if (user != null) {
                  ref.invalidate(relativesStreamProvider(user.id));
                }
              },
              text: 'إعادة المحاولة',
              icon: Icons.refresh_rounded,
            ),
          ],
        ),
      ),
    );
  }

  void _makeCall(Relative relative) async {
    if (relative.phoneNumber == null) return;

    final uri = Uri(scheme: 'tel', path: relative.phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      _markAsContacted(relative);
    }
  }

  void _openWhatsApp(Relative relative) async {
    if (relative.phoneNumber == null) return;

    // Clean phone number and format for WhatsApp
    final phone = relative.phoneNumber!.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$phone');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      _markAsContacted(relative);
    }
  }

  void _markAsContacted(Relative relative) async {
    // Record the interaction in the database
    // The UI will auto-update via the todayContactedRelativesProvider stream
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final interactionsService = ref.read(interactionsServiceProvider);
      final interaction = Interaction(
        id: '',
        userId: user.id,
        relativeId: relative.id,
        type: InteractionType.call,
        date: DateTime.now(),
        notes: 'تم التواصل من شاشة التذكيرات',
        createdAt: DateTime.now(),
      );
      await interactionsService.createInteraction(interaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تسجيل التواصل مع ${relative.fullName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تسجيل التواصل'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewRelativeDetail(Relative relative) {
    context.push('${AppRoutes.relativeDetail}/${relative.id}');
  }

  void _sendSMS(Relative relative) async {
    if (relative.phoneNumber == null) return;

    final uri = Uri(scheme: 'sms', path: relative.phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      _markAsContacted(relative);
    }
  }

  /// Compact button widget for action buttons
  Widget _buildCompactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool useFaIcon = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.9), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            useFaIcon
                ? FaIcon(icon, color: Colors.white, size: 16)
                : Icon(icon, color: Colors.white, size: 16),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
