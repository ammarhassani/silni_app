import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/utils/relationship_label_helper.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';

/// Compact family members widget — all three categories in one card
class FamilyCirclesWidget extends ConsumerWidget {
  const FamilyCirclesWidget({
    super.key,
    required this.relatives,
    this.relationshipLabels,
  });

  final List<Relative> relatives;
  final Map<String, String>? relationshipLabels;

  static const double _avatarSize = 54.0;
  static const double _itemWidth = 68.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    if (relatives.isEmpty) {
      return _buildEmptyState(context, themeColors);
    }

    final household = relatives
        .where((r) => r.relativeCategory == RelativeCategory.household)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final extended = relatives
        .where((r) => r.relativeCategory == RelativeCategory.extended)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final distant = relatives
        .where((r) => r.relativeCategory == RelativeCategory.distant)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    bool addButtonAssigned = false;
    VoidCallback? getAddCallback() {
      if (!addButtonAssigned) {
        addButtonAssigned = true;
        return () => context.push(AppRoutes.addRelative);
      }
      return null;
    }

    final categories = <({String emoji, String label, List<Relative> items})>[];
    if (household.isNotEmpty) {
      categories.add((emoji: '\u{1F3E0}', label: 'أهل البيت', items: household.take(10).toList()));
    }
    if (extended.isNotEmpty) {
      categories.add((emoji: '\u{1F4DE}', label: 'تواصل دائم', items: extended.take(10).toList()));
    }
    if (distant.isNotEmpty) {
      categories.add((emoji: '\u{1F319}', label: 'مناسبات', items: distant.take(10).toList()));
    }

    return Semantics(
      label: 'قسم العائلة - ${relatives.length} قريب',
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'عائلتك',
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.relatives),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'عرض الكل',
                          style: AppTypography.labelMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Category rows ──
            for (int i = 0; i < categories.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              _buildCategoryRow(
                context,
                categories[i].emoji,
                categories[i].label,
                categories[i].items,
                getAddCallback(),
                themeColors,
              ),
            ],

            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    )
        .animate(delay: AppAnimations.modal)
        .fadeIn(duration: AppAnimations.normal)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildCategoryRow(
    BuildContext context,
    String emoji,
    String label,
    List<Relative> items,
    VoidCallback? onAdd,
    dynamic themeColors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.55),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Horizontal scroll of avatars
          SizedBox(
            height: _avatarSize + 38, // avatar stack (54+6) + gap + name + label
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              physics: const BouncingScrollPhysics(),
              itemCount: items.length + (onAdd != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == items.length && onAdd != null) {
                  return _buildAddButton(context, onAdd, themeColors);
                }
                return _buildAvatarItem(context, items[index], themeColors);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarItem(BuildContext context, Relative relative, dynamic themeColors) {
    final needsAttention =
        relative.relativeCategory != RelativeCategory.household &&
        relative.needsContact;
    final label = relationshipLabels?[relative.id] ??
        getSideAwareLabel(relative.relationshipType, relative.familySide, relative.gender);
    final firstName = relative.fullName.split(' ').first;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('${AppRoutes.relativeDetail}/${relative.id}');
      },
      child: Container(
        width: _itemWidth,
        margin: const EdgeInsets.only(left: AppSpacing.sm),
        child: Column(
          children: [
            // Avatar with optional attention ring
            SizedBox(
              width: _avatarSize + 6,
              height: _avatarSize + 6,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing ring
                  if (needsAttention)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 1.15),
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeInOut,
                      builder: (_, value, child) => Transform.scale(
                        scale: value,
                        child: Container(
                          width: _avatarSize + 4,
                          height: _avatarSize + 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.joyfulOrange.withValues(
                                alpha: (1.6 - value).clamp(0.0, 1.0),
                              ),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      onEnd: () {},
                    ),
                  // Avatar circle
                  Hero(
                    tag: 'avatar-${relative.id}',
                    child: Container(
                      width: _avatarSize,
                      height: _avatarSize,
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
                                .withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: relative.photoUrl != null
                            ? CachedNetworkImage(
                                imageUrl: relative.photoUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, _) => Center(
                                  child: Text(
                                    relative.displayEmoji,
                                    style: const TextStyle(fontSize: 26),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  relative.displayEmoji,
                                  style: const TextStyle(fontSize: 26),
                                ),
                              ),
                      ),
                    ),
                  ),
                  // Attention badge
                  if (needsAttention)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.joyfulOrange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          size: 9,
                          color: Colors.white,
                        ),

                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            // Name + relationship label
            Text(
              firstName,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, VoidCallback onAdd, dynamic themeColors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onAdd();
      },
      child: Container(
        width: _itemWidth,
        margin: const EdgeInsets.only(left: AppSpacing.sm),
        child: Column(
          children: [
            Container(
              width: _avatarSize,
              height: _avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Icon(
                Icons.add_rounded,
                color: Colors.white.withValues(alpha: 0.6),
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'إضافة',
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, dynamic themeColors) {
    return GlassCard(
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: themeColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'ابدأ بإضافة أفراد عائلتك',
            style: AppTypography.titleMedium.copyWith(
              color: themeColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'أضف والديك، إخوتك، أجدادك وباقي أقاربك',
            style: AppTypography.bodySmall.copyWith(
              color: themeColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          GradientButton(
            text: 'إضافة أول قريب',
            onPressed: () => context.push(AppRoutes.addRelative),
            icon: Icons.person_add,
          ),
        ],
      ),
    );
  }
}
