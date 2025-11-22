import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../models/relative_model.dart';
import 'glass_card.dart';

class SwipeableRelativeCard extends StatelessWidget {
  final Relative relative;
  final VoidCallback? onTap;
  final Future<void> Function()? onMarkContacted;
  final bool showContactActions;

  const SwipeableRelativeCard({
    super.key,
    required this.relative,
    this.onTap,
    this.onMarkContacted,
    this.showContactActions = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showContactActions || (relative.phoneNumber == null && relative.email == null)) {
      // No swipe actions if contact info not available
      return _buildCard(context);
    }

    return Slidable(
      key: ValueKey(relative.id),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          if (relative.phoneNumber != null) ...[
            SlidableAction(
              onPressed: (_) => _makeCall(relative.phoneNumber!),
              backgroundColor: AppColors.islamicGreenPrimary,
              foregroundColor: Colors.white,
              icon: Icons.phone_rounded,
              label: 'اتصال',
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(AppSpacing.radiusLg)),
            ),
            SlidableAction(
              onPressed: (_) => _sendMessage(relative.phoneNumber!),
              backgroundColor: AppColors.royalBlue,
              foregroundColor: Colors.white,
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم تسجيل التواصل مع ${relative.fullName}'),
                      backgroundColor: AppColors.islamicGreenPrimary,
                      behavior: SnackBarBehavior.floating,
                    ),
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
      child: _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    final needsAttention = relative.needsContact;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: AppSpacing.md,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        gradient: needsAttention
            ? LinearGradient(
                colors: [
                  AppColors.joyfulOrange.withOpacity(0.2),
                  AppColors.islamicGreenPrimary.withOpacity(0.1),
                ],
              )
            : null,
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: needsAttention
                        ? AppColors.streakFire
                        : AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: (needsAttention
                                ? AppColors.joyfulOrange
                                : AppColors.islamicGreenPrimary)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: relative.photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            relative.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
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
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.joyfulOrange,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                // Favorite badge
                if (relative.isFavorite)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.goldenGradient,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),

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
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (relative.priority == 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.goldenGradient,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            'عالي',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    relative.relationshipType.arabicName,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  if (needsAttention) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppColors.joyfulOrange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          relative.daysSinceLastContact != null
                              ? 'آخر تواصل منذ ${relative.daysSinceLastContact} يوم'
                              : 'لم يتم التواصل بعد',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.joyfulOrange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Arrow icon
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Center(
      child: Text(
        relative.displayEmoji,
        style: const TextStyle(fontSize: 28),
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
