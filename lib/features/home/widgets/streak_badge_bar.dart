import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
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

  @override
  Widget build(BuildContext context) {
    final gamificationData =
        ref.watch(userGamificationDataProvider(widget.userId));

    return gamificationData.when(
      data: (data) => _buildBar(data),
      loading: () => _buildSkeletonLoader(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildBar(Map<String, dynamic> data) {
    final currentStreak = data['current_streak'] as int? ?? 0;
    final badges = List<String>.from(data['badges'] ?? []);
    final highestBadge = BadgePrestige.getHighestPrestigeBadge(badges);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.05),
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

          // Streak Section
          _buildStreakSection(currentStreak),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildUsernameSection() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: widget.profilePhotoUrl == null
                ? AppColors.primaryGradient
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
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return const Center(
      child: Icon(
        Icons.person_rounded,
        color: Colors.white,
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
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0),
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
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              color: Colors.white.withValues(alpha: 0.1),
            ),
            child: const Center(
              child: Text(
                '?',
                style: TextStyle(
                  color: Colors.white70,
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
              color: Colors.white70,
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
                ? const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1B3D1E),
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
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakSection(int streak) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fire emoji with glow
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: streak > 0
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: const Text(
            '🔥',
            style: TextStyle(fontSize: 18),
          ),
        )
            .animate(
              onPlay: (controller) => streak > 0 ? controller.repeat() : null,
            )
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.1, 1.1),
              duration: streak > 0 ? 1.seconds : Duration.zero,
              curve: Curves.easeInOut,
            )
            .then()
            .scale(
              begin: const Offset(1.1, 1.1),
              end: const Offset(1.0, 1.0),
              duration: streak > 0 ? 1.seconds : Duration.zero,
              curve: Curves.easeInOut,
            ),
        const SizedBox(width: 4),
        // Streak number
        Text(
          '$streak',
          style: AppTypography.numberSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'يوم',
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
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
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 50,
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.1));
  }
}
