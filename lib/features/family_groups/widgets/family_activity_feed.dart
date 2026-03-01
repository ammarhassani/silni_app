import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_card.dart';

/// Cache timeout for activity feed data.
const _feedCacheTimeout = Duration(minutes: 5);

/// Provider for recent family group interactions (last 48h).
final _familyActivityFeedProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, groupId) {
    final link = ref.keepAlive();
    Timer? timer;

    ref.onDispose(() => timer?.cancel());
    ref.onCancel(() {
      timer = Timer(_feedCacheTimeout, () => link.close());
    });
    ref.onResume(() => timer?.cancel());

    return _fetchRecentActivity(groupId);
  },
);

Future<List<Map<String, dynamic>>> _fetchRecentActivity(String groupId) async {
  final client = SupabaseConfig.client;
  final since =
      DateTime.now().subtract(const Duration(hours: 48)).toUtc().toIso8601String();

  // Get member user IDs
  final members = await client
      .from('family_group_members')
      .select('user_id, relative_id_in_tree')
      .eq('group_id', groupId);

  final memberIds = members.map((m) => m['user_id'] as String).toList();
  if (memberIds.isEmpty) return [];

  // Build a user_id -> display name map from relatives
  final relativeIds = members
      .where((m) => m['relative_id_in_tree'] != null)
      .map((m) => m['relative_id_in_tree'] as String)
      .toList();

  Map<String, String> userToName = {};
  if (relativeIds.isNotEmpty) {
    final namesData = await client
        .from('relatives')
        .select('id, full_name')
        .inFilter('id', relativeIds);

    final relIdToName = <String, String>{
      for (final r in namesData) r['id'] as String: r['full_name'] as String,
    };

    for (final m in members) {
      final relId = m['relative_id_in_tree'] as String?;
      if (relId != null && relIdToName.containsKey(relId)) {
        userToName[m['user_id'] as String] = relIdToName[relId]!;
      }
    }
  }

  // Fetch recent interactions by group members
  final interactions = await client
      .from('interactions')
      .select('id, user_id, relative_id, interaction_type, interaction_date')
      .inFilter('user_id', memberIds)
      .gte('interaction_date', since)
      .order('interaction_date', ascending: false)
      .limit(10);

  // Get relative names for the interactions
  final interactionRelativeIds = interactions
      .map((i) => i['relative_id'] as String?)
      .where((id) => id != null)
      .cast<String>()
      .toSet()
      .toList();

  Map<String, String> relativeNames = {};
  if (interactionRelativeIds.isNotEmpty) {
    final relData = await client
        .from('relatives')
        .select('id, full_name')
        .inFilter('id', interactionRelativeIds);
    relativeNames = {
      for (final r in relData) r['id'] as String: r['full_name'] as String,
    };
  }

  // Build activity items
  return interactions.map((i) {
    final userId = i['user_id'] as String;
    final memberName = userToName[userId] ?? 'عضو';
    final relativeName =
        relativeNames[i['relative_id'] as String? ?? ''] ?? 'قريب';
    final type = i['interaction_type'] as String? ?? 'call';
    final dateStr = i['interaction_date'] as String?;

    return {
      'memberName': memberName,
      'relativeName': relativeName,
      'type': type,
      'date': dateStr,
    };
  }).toList();
}

/// Widget showing recent family activity as a warm timeline.
class FamilyActivityFeed extends ConsumerWidget {
  final String groupId;

  const FamilyActivityFeed({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final activityAsync = ref.watch(_familyActivityFeedProvider(groupId));

    return activityAsync.when(
      data: (activities) {
        if (activities.isEmpty) return const SizedBox.shrink();

        return GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    size: 20,
                    color: themeColors.onSurface,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'آخر أخبار العائلة',
                    style: AppTypography.titleSmall.copyWith(
                      color: themeColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ...activities.take(5).map((activity) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _buildActivityItem(activity, themeColors),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildActivityItem(
    Map<String, dynamic> activity,
    ThemeColors themeColors,
  ) {
    final memberName = activity['memberName'] as String;
    final relativeName = activity['relativeName'] as String;
    final type = activity['type'] as String;
    final dateStr = activity['date'] as String?;

    final icon = switch (type) {
      'call' => Icons.phone_rounded,
      'visit' => Icons.home_rounded,
      'message' => Icons.chat_bubble_rounded,
      'gift' => Icons.card_giftcard_rounded,
      _ => Icons.favorite_rounded,
    };

    final verb = switch (type) {
      'call' => 'اتصل بـ',
      'visit' => 'زار',
      'message' => 'راسل',
      'gift' => 'أهدى',
      _ => 'تواصل مع',
    };

    final timeAgo = _formatTimeAgo(dateStr);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: themeColors.onSurface.withValues(alpha: 0.7)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTypography.bodySmall.copyWith(
                color: themeColors.onSurface,
              ),
              children: [
                TextSpan(
                  text: memberName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' $verb '),
                TextSpan(
                  text: relativeName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (timeAgo.isNotEmpty)
                  TextSpan(
                    text: ' — $timeAgo',
                    style: TextStyle(
                      color: themeColors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';

    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'قبل ${diff.inHours} ساعة';
    if (diff.inDays == 1) return 'أمس';
    return 'قبل ${diff.inDays} أيام';
  }
}
