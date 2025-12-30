import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/models/notification_history_model.dart';
import '../../../shared/services/notification_history_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/premium_loading_indicator.dart';
import '../../../shared/utils/ui_helpers.dart';

/// Screen that shows notification history
class NotificationHistoryScreen extends ConsumerStatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  ConsumerState<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState
    extends ConsumerState<NotificationHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';
    final notificationsAsync =
        ref.watch(notificationHistoryStreamProvider(userId));
    final themeColors = ref.watch(themeColorsProvider);

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(animated: true, child: SizedBox.expand()),
          SafeArea(
            child: Semantics(
              label: 'شاشة سجل الإشعارات',
              child: Column(
              children: [
                _buildHeader(context, userId, themeColors),
                Expanded(
                  child: notificationsAsync.when(
                    data: (notifications) =>
                        _buildContent(context, notifications, themeColors),
                    loading: () => const Center(
                      child: PremiumLoadingIndicator(
                        message: 'جاري تحميل الإشعارات...',
                      ),
                    ),
                    error: (_,_) => _buildError(),
                  ),
                ),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userId, dynamic themeColors) {
    final service = ref.read(notificationHistoryServiceProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Semantics(
            label: 'رجوع',
            button: true,
            child: IconButton(
              onPressed: () => context.pop(),
              icon: Icon(Icons.arrow_back_ios_rounded, color: themeColors.textOnGradient),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الإشعارات',
                  style: AppTypography.headlineLarge.copyWith(
                    color: themeColors.textOnGradient,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'سجل الإشعارات السابقة',
                  style: AppTypography.bodyMedium.copyWith(
                    color: themeColors.textOnGradient.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          // Mark all as read button
          IconButton(
            onPressed: () async {
              await service.markAllAsRead(userId);
              // Invalidate providers to refresh the stream
              ref.invalidate(notificationHistoryStreamProvider(userId));
              ref.invalidate(unreadNotificationCountProvider(userId));
              if (context.mounted) {
                UIHelpers.showSnackBar(
                  context,
                  'تم تحديد جميع الإشعارات كمقروءة',
                );
              }
            },
            icon: const Icon(Icons.done_all_rounded, color: Colors.white),
            tooltip: 'تحديد الكل كمقروء',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<NotificationHistoryItem> notifications,
    ThemeColors themeColors,
  ) {
    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: notifications.length,
      itemBuilder: (context, index) {

        final notification = notifications[index];
        return Semantics(
          label: 'إشعار ${notification.typeLabel}',
          hint: 'اسحب للحذف أو اضغط للتفاصيل',
          child: _buildNotificationCard(context, notification, themeColors, index),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: index * 50))
            .slideX(begin: 0.1, delay: Duration(milliseconds: index * 50));
      },
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationHistoryItem notification,
    ThemeColors themeColors,
    int index,
  ) {
    final service = ref.read(notificationHistoryServiceProvider);
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) async {
        await service.deleteNotification(notification.id);
        // Invalidate providers to refresh the stream
        final userId = ref.read(currentUserProvider)?.id ?? '';
        ref.invalidate(notificationHistoryStreamProvider(userId));
        ref.invalidate(unreadNotificationCountProvider(userId));
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: GlassCard(
          onTap: () => _handleNotificationTap(notification, service),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: isUnread
                ? BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: themeColors.primary,
                        width: 4,
                      ),
                    ),
                  )
                : null,
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getTypeColor(notification.notificationType)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      notification.typeIcon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight:
                                    isUnread ? FontWeight.bold : FontWeight.normal,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: themeColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: isUnread ? 0.9 : 0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getTypeColor(notification.notificationType)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              notification.typeLabel,
                              style: AppTypography.labelSmall.copyWith(
                                color:
                                    _getTypeColor(notification.notificationType),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatTime(notification.sentAt),
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'reminder':
        return Colors.blue;
      case 'achievement':
        return Colors.amber;
      case 'announcement':
        return Colors.purple;
      case 'streak':
        return Colors.orange;
      default:
        return Colors.teal;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _handleNotificationTap(
    NotificationHistoryItem notification,
    NotificationHistoryService service,
  ) async {
    // Mark as read
    if (!notification.isRead) {
      await service.markAsRead(notification.id);
      // Invalidate providers to refresh the stream
      final userId = ref.read(currentUserProvider)?.id ?? '';
      ref.invalidate(notificationHistoryStreamProvider(userId));
      ref.invalidate(unreadNotificationCountProvider(userId));
    }

    if (!mounted) return;

    // Navigate based on type
    switch (notification.notificationType) {
      case 'reminder':
        final relativeIds = notification.data?['relative_ids']?.toString();
        if (relativeIds != null && relativeIds.isNotEmpty) {
          context.push('${AppRoutes.remindersDue}?ids=$relativeIds');
        } else {
          context.push(AppRoutes.remindersDue);
        }
        break;
      case 'achievement':
        context.push(AppRoutes.profile);
        break;
      case 'streak':
        context.push(AppRoutes.statistics);
        break;
      case 'announcement':
        // Stay on current screen or go home
        context.go(AppRoutes.home);
        break;
      default:
        context.go(AppRoutes.home);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'لا توجد إشعارات',
            style: AppTypography.headlineSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'ستظهر إشعاراتك هنا',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'حدث خطأ في تحميل الإشعارات',
            style: AppTypography.bodyLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
