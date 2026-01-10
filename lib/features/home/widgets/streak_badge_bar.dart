import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/subscription_tier.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/badge_prestige.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/home_providers.dart';

/// Beautiful streak/badge bar for the home header
/// Displays: Username | Highest badge | Streak count | Countdown timer
class StreakBadgeBar extends ConsumerStatefulWidget {
  const StreakBadgeBar({
    super.key,
    required this.userId,
    required this.displayName,
    this.profilePhotoUrl,
  });

  final String userId;
  final String displayName;
  final String? profilePhotoUrl;

  @override
  ConsumerState<StreakBadgeBar> createState() => _StreakBadgeBarState();
}

class _StreakBadgeBarState extends ConsumerState<StreakBadgeBar> {
  ThemeColors get _themeColors => ref.watch(themeColorsProvider);

  @override
  Widget build(BuildContext context) {
    final gamificationData =
        ref.watch(userGamificationDataProvider(widget.userId));

    return Semantics(
      label: 'شريط الإنجازات',
      child: gamificationData.when(
        data: (data) => _buildBar(data),
        loading: () => _buildSkeletonLoader(),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildBar(Map<String, dynamic> data) {
    final currentStreak = data['current_streak'] as int? ?? 0;
    final badges = List<String>.from(data['badges'] ?? []);
    final highestBadge = BadgePrestige.getHighestPrestigeBadge(badges);

    // Parse streak deadline for warning indicator
    final deadlineStr = data['streak_deadline'] as String?;
    final deadline = deadlineStr != null ? DateTime.tryParse(deadlineStr)?.toUtc() : null;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _themeColors.glassHighlight,
          _themeColors.glassBackground,
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Username Section
          _buildUsernameSection(),

          // Divider
          _buildDivider(),

          // Badge Section
          _buildBadgeSection(highestBadge),

          // Divider
          _buildDivider(),

          // Streak Section with deadline for warning indicator
          _buildStreakSection(currentStreak, deadline: deadline),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: AppAnimations.fast, duration: AppAnimations.modal)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildUsernameSection() {
    final tier = ref.watch(subscriptionTierProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: widget.profilePhotoUrl == null
                ? _themeColors.primaryGradient
                : null,
          ),
          child: widget.profilePhotoUrl != null
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: widget.profilePhotoUrl!,
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildDefaultAvatar(),
                    errorWidget: (context, url, error) => _buildDefaultAvatar(),
                  ),
                )
              : _buildDefaultAvatar(),
        ),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 80),
          child: Text(
            widget.displayName.split(' ').first,
            style: AppTypography.labelMedium.copyWith(
              color: _themeColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Subscription tier badge
        if (tier != SubscriptionTier.free) ...[
          const SizedBox(width: 4),
          _buildTierBadge(tier),
        ],
      ],
    );
  }

  Widget _buildTierBadge(SubscriptionTier tier) {
    final isMax = tier.isMax;
    final badgeColor = isMax ? AppColors.premiumGold : AppColors.islamicGreenPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: isMax
            ? AppColors.goldenGradient
            : LinearGradient(
                colors: [
                  badgeColor,
                  badgeColor.withValues(alpha: 0.8),
                ],
              ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Text(
        tier.badgeLabel,
        style: AppTypography.labelSmall.copyWith(
          color: isMax ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 8,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Center(
      child: Icon(
        Icons.person_rounded,
        color: _themeColors.onPrimary,
        size: 16,
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _themeColors.divider.withValues(alpha: 0),
            _themeColors.divider,
            _themeColors.divider.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeSection(String? badgeId) {
    if (badgeId == null) {
      // No badge earned yet
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _themeColors.glassBorder,
                width: 1.5,
              ),
              color: _themeColors.glassBackground,
            ),
            child: Center(
              child: Text(
                '?',
                style: TextStyle(
                  color: _themeColors.textHint,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'ابدأ رحلتك',
            style: AppTypography.labelSmall.copyWith(
              color: _themeColors.textHint,
            ),
          ),
        ],
      );
    }

    final badgeInfo = BadgePrestige.getBadgeInfo(badgeId);
    final isHighPrestige = ['streak_365', 'interactions_1000', 'streak_100']
        .contains(badgeId);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badge container with gradient border
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isHighPrestige ? AppColors.goldenGradient : null,
            border: isHighPrestige
                ? null
                : Border.all(
                    color: badgeInfo.color.withValues(alpha: 0.7),
                    width: 1.5,
                  ),
            boxShadow: isHighPrestige
                ? [
                    BoxShadow(
                      color: AppColors.premiumGold.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Container(
            margin: isHighPrestige ? const EdgeInsets.all(2) : null,
            decoration: isHighPrestige
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    color: _themeColors.primaryDark,
                  )
                : null,
            alignment: Alignment.center,
            child: Text(
              badgeInfo.emoji,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        )
            .animate(
              onPlay: (controller) =>
                  isHighPrestige ? controller.repeat() : null,
            )
            .shimmer(
              duration: isHighPrestige ? 3.seconds : Duration.zero,
              color: isHighPrestige
                  ? AppColors.premiumGold.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
        const SizedBox(width: 6),
        Text(
          badgeInfo.name,
          style: AppTypography.labelSmall.copyWith(
            color: _themeColors.textPrimary.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakSection(int streak, {DateTime? deadline}) {
    // Determine warning state
    final isEndangered = _isStreakEndangered(deadline);
    final isCritical = _isStreakCritical(deadline);
    final timeRemaining = _getTimeRemaining(deadline);

    // Choose emoji based on state
    final emoji = isEndangered ? '⏳' : '🔥';
    final glowColor = isCritical
        ? _themeColors.statusError
        : (isEndangered ? _themeColors.statusWarning : AppColors.joyfulOrange);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Emoji with glow and animation
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: streak > 0
                ? [
                    BoxShadow(
                      color: glowColor.withValues(alpha: isEndangered ? 0.6 : 0.5),
                      blurRadius: isEndangered ? 10 : 8,
                      spreadRadius: isEndangered ? 2 : 1,
                    ),
                  ]
                : null,
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 18),
          ),
        )
            .animate(
              onPlay: (controller) => streak > 0 ? controller.repeat() : null,
            )
            .then() // Chain animations based on state
            .custom(
              builder: (context, value, child) {
                if (isCritical) {
                  // Critical: shake animation
                  return child;
                } else if (isEndangered) {
                  // Warning: faster pulse
                  return child;
                }
                // Normal: subtle pulse
                return child;
              },
            )
            .scale(
              begin: const Offset(1.0, 1.0),
              end: Offset(isCritical ? 1.15 : 1.1, isCritical ? 1.15 : 1.1),
              duration: streak > 0
                  ? (isCritical
                      ? AppAnimations.fast
                      : (isEndangered
                          ? AppAnimations.modal
                          : AppAnimations.celebration))
                  : Duration.zero,
              curve: Curves.easeInOut,
            )
            .then()
            .scale(
              begin: Offset(isCritical ? 1.15 : 1.1, isCritical ? 1.15 : 1.1),
              end: const Offset(1.0, 1.0),
              duration: streak > 0
                  ? (isCritical
                      ? AppAnimations.fast
                      : (isEndangered
                          ? AppAnimations.modal
                          : AppAnimations.celebration))
                  : Duration.zero,
              curve: Curves.easeInOut,
            )
            .then(delay: isCritical ? 50.ms : Duration.zero)
            .shake(
              hz: isCritical ? 4 : 0,
              offset: Offset(isCritical ? 1.5 : 0, 0),
              duration: isCritical ? AppAnimations.fast : Duration.zero,
            ),
        const SizedBox(width: 4),
        // Streak number
        Text(
          '$streak',
          style: AppTypography.numberSmall.copyWith(
            color: isEndangered ? glowColor : _themeColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 4),
        // Show countdown if endangered, otherwise just "يوم"
        if (isEndangered && timeRemaining != null) ...[
          Text(
            _formatTimeRemaining(timeRemaining),
            style: AppTypography.labelSmall.copyWith(
              color: isCritical ? _themeColors.statusError : _themeColors.statusWarning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ] else
          Text(
            'يوم',
            style: AppTypography.labelSmall.copyWith(
              color: _themeColors.textSecondary,
            ),
          ),
      ],
    );
  }

  /// Check if streak is endangered (less than 4 hours remaining)
  bool _isStreakEndangered(DateTime? deadline) {
    if (deadline == null) return false;
    final remaining = deadline.difference(DateTime.now().toUtc());
    return !remaining.isNegative && remaining.inHours < 4;
  }

  /// Check if streak is critical (less than 1 hour remaining)
  bool _isStreakCritical(DateTime? deadline) {
    if (deadline == null) return false;
    final remaining = deadline.difference(DateTime.now().toUtc());
    return !remaining.isNegative && remaining.inMinutes < 60;
  }

  /// Get time remaining until deadline
  Duration? _getTimeRemaining(DateTime? deadline) {
    if (deadline == null) return null;
    return deadline.difference(DateTime.now().toUtc());
  }

  /// Format time remaining as a readable string
  String _formatTimeRemaining(Duration duration) {
    if (duration.isNegative) return 'انتهى';
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '$hoursس $minutesد';
    }
    return '$minutesد';
  }

  Widget _buildSkeletonLoader() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // Badge placeholder
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _themeColors.shimmerBase,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 50,
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _themeColors.shimmerBase,
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: AppAnimations.loop, color: _themeColors.shimmerHighlight);
  }
}
