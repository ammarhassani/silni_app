import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/theme_provider.dart';
import '../../features/ai_assistant/widgets/health_badge.dart';
import '../models/relative_model.dart';
import '../utils/relationship_label_helper.dart';
import '../utils/ui_helpers.dart';
import 'glass_card.dart';

class SwipeableRelativeCard extends ConsumerWidget {
  final Relative relative;
  final VoidCallback? onTap;
  final Future<void> Function()? onMarkContacted;
  final bool showContactActions;

  /// Optional perspective-shifted label computed by the parent screen.
  /// Falls back to [relative.relationshipType.arabicName] when null.
  final String? relationshipLabel;

  /// Per-relative streak count. When > 0, renders a small `🔥 N` indicator
  /// in the secondary row. Resolved by the parent (via the all-streaks
  /// stream) so the card itself does no DB work.
  final int? streakDays;

  const SwipeableRelativeCard({
    super.key,
    required this.relative,
    this.onTap,
    this.onMarkContacted,
    this.showContactActions = true,
    this.relationshipLabel,
    this.streakDays,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    if (!showContactActions || (relative.phoneNumber == null && relative.email == null)) {
      // No swipe actions if contact info not available
      return _buildCard(context, themeColors);
    }

    return Slidable(
      key: ValueKey(relative.id),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          if (relative.phoneNumber != null) ...[
            SlidableAction(
              onPressed: (_) => _makeCall(relative.phoneNumber!),
              backgroundColor: themeColors.primary,
              foregroundColor: themeColors.onPrimary,
              icon: Icons.phone_rounded,
              label: 'اتصال',
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(AppSpacing.radiusLg)),
            ),
            SlidableAction(
              onPressed: (_) => _sendMessage(relative.phoneNumber!),
              backgroundColor: themeColors.secondary,
              foregroundColor: themeColors.onSecondary,
              icon: Icons.message_rounded,
              label: 'رسالة',
            ),
          ],
          if (relative.email != null)
            SlidableAction(
              onPressed: (_) => _sendEmail(relative.email!),
              backgroundColor: AppColors.emotionalPurple,
              foregroundColor: Colors.white,
              icon: Icons.email_rounded,
              label: 'بريد',
            ),
          if (onMarkContacted != null)
            SlidableAction(
              onPressed: (_) async {
                await onMarkContacted!();
                if (context.mounted) {
                  UIHelpers.showSnackBar(
                    context,
                    'تم تسجيل التواصل مع ${relative.fullName}',
                    backgroundColor: themeColors.primary,
                  );
                }
              },
              backgroundColor: AppColors.joyfulOrange,
              foregroundColor: Colors.white,
              icon: Icons.check_circle_rounded,
              label: 'تواصلت',
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppSpacing.radiusLg)),
            ),
        ],
      ),
      child: _buildCard(context, themeColors),
    );
  }

  Widget _buildCard(BuildContext context, ThemeColors themeColors) {
    final needsAttention = relative.needsContact;

    final displayLabel = relationshipLabel ?? getSideAwareLabel(relative.relationshipType, relative.familySide, relative.gender);

    return Semantics(
      label: '${relative.fullName}، $displayLabel'
          '${needsAttention ? '، يحتاج تواصل' : ''}'
          '${relative.isFavorite ? '، مفضل' : ''}',
      button: true,
      hint: 'انقر للعرض، اسحب لخيارات التواصل',
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        margin: const EdgeInsets.only(bottom: 6),
        gradient: needsAttention
            ? LinearGradient(
                colors: [
                  AppColors.joyfulOrange.withValues(alpha: 0.2),
                  themeColors.primary.withValues(alpha: 0.1),
                ],
              )
            : null,
        child: Row(
          children: [
            // Avatar with Hero animation
            Hero(
              tag: 'avatar-${relative.id}',
              child: Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: needsAttention
                          ? AppColors.streakFire
                          : themeColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: (needsAttention
                                  ? AppColors.joyfulOrange
                                  : themeColors.primary)
                              .withValues(alpha: 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: relative.photoUrl != null && relative.photoUrl!.isNotEmpty
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: relative.photoUrl!,
                              fit: BoxFit.cover,
                              width: 50,
                              height: 50,
                              placeholder: (context, url) => _buildDefaultAvatar(),
                              errorWidget: (context, url, error) => _buildDefaultAvatar(),
                            ),
                          )
                        : _buildDefaultAvatar(),
                  ),
                // Needs attention badge
                if (needsAttention)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.joyfulOrange,
                        border: Border.all(color: themeColors.surface, width: 1.5),
                      ),
                      child: Icon(
                        Icons.warning_rounded,
                        size: 9,
                        color: themeColors.onPrimary,
                      ),
                    ),
                  ),
                // Favorite badge
                if (relative.isFavorite)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.goldenGradient,
                        border: Border.all(color: themeColors.surface, width: 1.5),
                      ),
                      child: Icon(
                        Icons.star_rounded,
                        size: 9,
                        color: themeColors.onPrimary,
                      ),
                    ),
                  ),
                // Health badge (bottom-right)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: HealthBadge(relative: relative, size: 13),
                ),
              ],
            ),
          ),
            const SizedBox(width: AppSpacing.sm),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          relative.fullName,
                          style: AppTypography.bodyLarge.copyWith(
                            color: themeColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (relative.priority == 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.goldenGradient,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            'عالي',
                            style: AppTypography.labelSmall.copyWith(
                              color: themeColors.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        displayLabel,
                        style: AppTypography.labelSmall.copyWith(
                          color: themeColors.textSecondary,
                        ),
                      ),
                      if (streakDays != null && streakDays! > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '🔥$streakDays',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.joyfulOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (needsAttention) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: AppColors.joyfulOrange,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            relative.daysSinceLastContact != null
                                ? 'منذ ${relative.daysSinceLastContact} يوم'
                                : 'لم يتم التواصل',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.joyfulOrange,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Arrow icon
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: themeColors.textHint,
              size: 14,
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Center(
      child: Text(
        relative.displayEmoji,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }

  Future<void> _makeCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendMessage(String phoneNumber) async {
    final uri = Uri.parse('sms:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
