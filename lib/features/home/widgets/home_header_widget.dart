import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/services/notification_history_service.dart';
import '../../../shared/widgets/sync_status_indicator.dart';
import 'streak_badge_bar.dart';

/// Islamic greeting header with notification bell
class HomeHeaderWidget extends ConsumerWidget {
  const HomeHeaderWidget({
    super.key,
    required this.displayName,
    required this.userId,
  });

  final String displayName;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider(userId));
    final user = ref.watch(currentUserProvider);
    final profilePhotoUrl = user?.userMetadata?['profile_picture_url'] as String?;
    final hour = DateTime.now().hour;
    String greeting = 'السلام عليكم';
    if (hour < 12) {
      greeting = 'صباح الخير';
    } else if (hour < 18) {
      greeting = 'مساء الخير';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                greeting,
                style: AppTypography.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Sync status indicator
            const SyncStatusIndicator(
              asBadge: true,
              size: 24,
            ),
            const SizedBox(width: 8),
            // Notification bell icon with unread badge
            GestureDetector(
              onTap: () => context.push(AppRoutes.notificationHistory),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
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
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Center(
                                  child: Text(
                                    count > 99 ? '99+' : count.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
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
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Streak & Badge Bar with username
        StreakBadgeBar(
          userId: userId,
          displayName: displayName,
          profilePhotoUrl: profilePhotoUrl,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '"ومن أحب أن يُبسَط له في رزقه، وأن يُنسَأ له في أثره، فليصل رحمه"',
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
            fontStyle: FontStyle.italic,
            height: 1.6,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 600))
        .slideY(begin: -0.1, end: 0);
  }
}
