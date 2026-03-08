import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/family_groups/providers/node_invitation_providers.dart';
import '../../../shared/services/notification_history_service.dart';
import '../../../shared/widgets/sync_status_indicator.dart';
import 'streak_badge_bar.dart';

/// Islamic greeting header with notification bell
class HomeHeaderWidget extends ConsumerStatefulWidget {
  const HomeHeaderWidget({
    super.key,
    required this.displayName,
    required this.userId,
  });

  final String displayName;
  final String userId;

  @override
  ConsumerState<HomeHeaderWidget> createState() => _HomeHeaderWidgetState();
}

class _HomeHeaderWidgetState extends ConsumerState<HomeHeaderWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    final unreadCountAsync =
        ref.watch(unreadNotificationCountProvider(widget.userId));
    final user = ref.watch(currentUserProvider);
    final profilePhotoUrl =
        user?.userMetadata?['profile_picture_url'] as String?;
    final pendingInvitationCount =
        ref.watch(pendingInvitationCountProvider).valueOrNull ?? 0;

    // Start or stop glow animation based on pending invitations
    if (pendingInvitationCount > 0) {
      if (!_glowController.isAnimating) {
        _glowController.repeat(reverse: true);
      }
    } else {
      if (_glowController.isAnimating) {
        _glowController.stop();
        _glowController.reset();
      }
    }

    final hour = DateTime.now().hour;
    String greeting = 'السلام عليكم';
    if (hour < 12) {
      greeting = 'صباح الخير';
    } else if (hour < 18) {
      greeting = 'مساء الخير';
    }

    return Semantics(
      label: '$greeting ${widget.displayName}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  greeting,
                  style: AppTypography.headlineSmall.copyWith(
                    color: themeColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Sync status indicator
              const SyncStatusIndicator(
                asBadge: true,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.md),
              // Notification bell icon with unread badge and glow
              Semantics(
                label: 'الإشعارات',
                button: true,
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.notificationHistory),
                  child: AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      final glowAlpha = pendingInvitationCount > 0
                          ? 0.2 + (_glowController.value * 0.4)
                          : 0.0;
                      final glowBlur = pendingInvitationCount > 0
                          ? 8.0 + (_glowController.value * 8.0)
                          : 0.0;

                      return Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: themeColors.glassBackground,
                          boxShadow: pendingInvitationCount > 0
                              ? [
                                  BoxShadow(
                                    color: AppColors.premiumGold
                                        .withValues(alpha: glowAlpha),
                                    blurRadius: glowBlur,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: child,
                      );
                    },
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.notifications_outlined,
                            color: themeColors.textPrimary,
                            size: 24,
                          ),
                        ),
                        // Unread badge
                        unreadCountAsync.when(
                          data: (count) => count > 0
                              ? Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.energeticRed,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Center(
                                      child: Text(
                                        count > 99 ? '99+' : count.toString(),
                                        style:
                                            AppTypography.labelSmall.copyWith(
                                          color: themeColors.onPrimary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Streak & Badge Bar with username
          StreakBadgeBar(
            userId: widget.userId,
            displayName: widget.displayName,
            profilePhotoUrl: profilePhotoUrl,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppAnimations.slow)
        .slideY(begin: -0.1, end: 0);
  }
}
