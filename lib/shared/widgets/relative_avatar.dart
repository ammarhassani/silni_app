import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/theme_provider.dart';
import '../models/relative_model.dart';

/// Unified avatar widget for displaying relative photos
/// Shows photo if available, emoji fallback otherwise
class RelativeAvatar extends ConsumerWidget {
  final Relative relative;
  final double size;
  final bool showNeedsAttentionBadge;
  final bool showFavoriteBadge;
  final String? heroTag;
  final Gradient? gradient;
  final String? semanticsLabel;

  const RelativeAvatar({
    super.key,
    required this.relative,
    this.size = 60,
    this.showNeedsAttentionBadge = true,
    this.showFavoriteBadge = true,
    this.heroTag,
    this.gradient,
    this.semanticsLabel,
  });

  /// Predefined sizes for consistency
  static const double sizeSmall = 40;
  static const double sizeMedium = 60;
  static const double sizeLarge = 85;
  static const double sizeXLarge = 120;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final needsAttention = relative.needsContact;
    final effectiveGradient = gradient ??
        (needsAttention ? AppColors.streakFire : themeColors.primaryGradient);

    Widget avatar = Stack(
      children: [
        // Main avatar container
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: effectiveGradient,
            boxShadow: [
              BoxShadow(
                color: (needsAttention
                        ? AppColors.joyfulOrange
                        : themeColors.primary)
                    .withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: _buildAvatarContent(),
        ),

        // Needs attention badge
        if (showNeedsAttentionBadge && needsAttention)
          Positioned(
            top: 0,
            right: 0,
            child: _buildBadge(
              icon: Icons.warning_rounded,
              color: AppColors.joyfulOrange,
              borderColor: themeColors.surface,
            ),
          ),

        // Favorite badge
        if (showFavoriteBadge && relative.isFavorite)
          Positioned(
            bottom: 0,
            left: 0,
            child: _buildBadge(
              icon: Icons.star_rounded,
              gradient: AppColors.goldenGradient,
              borderColor: themeColors.surface,
            ),
          ),
      ],
    );

    // Wrap with Hero animation if tag provided
    if (heroTag != null) {
      avatar = Hero(
        tag: heroTag!,
        child: avatar,
      );
    }

    // Wrap with Semantics for accessibility
    final label = semanticsLabel ??
        'صورة ${relative.fullName}'
            '${needsAttention ? '، يحتاج تواصل' : ''}'
            '${relative.isFavorite ? '، مفضل' : ''}';

    return Semantics(
      label: label,
      image: true,
      child: avatar,
    );
  }

  Widget _buildAvatarContent() {
    if (relative.photoUrl != null && relative.photoUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: relative.photoUrl!,
          fit: BoxFit.cover,
          width: size,
          height: size,
          placeholder: (context, url) => _buildEmojiAvatar(),
          errorWidget: (context, url, error) => _buildEmojiAvatar(),
        ),
      );
    }
    return _buildEmojiAvatar();
  }

  Widget _buildEmojiAvatar() {
    // Calculate emoji size based on avatar size
    final emojiSize = size * 0.5;
    return Center(
      child: Text(
        relative.displayEmoji,
        style: TextStyle(fontSize: emojiSize),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    Color? color,
    Gradient? gradient,
    required Color borderColor,
  }) {
    final badgeSize = size * 0.3;
    final iconSize = badgeSize * 0.55;

    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: gradient == null ? color : null,
        gradient: gradient,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: Colors.white,
      ),
    );
  }
}

/// Simple avatar widget for displaying user profile pictures
class UserAvatar extends ConsumerWidget {
  final String? photoUrl;
  final String? fallbackText;
  final double size;
  final Gradient? gradient;
  final String? heroTag;
  final VoidCallback? onTap;
  final bool showEditButton;
  final String? semanticsLabel;

  const UserAvatar({
    super.key,
    this.photoUrl,
    this.fallbackText,
    this.size = 60,
    this.gradient,
    this.heroTag,
    this.onTap,
    this.showEditButton = false,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final effectiveGradient = gradient ?? AppColors.goldenGradient;

    Widget avatar = Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: effectiveGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.premiumGold.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: _buildAvatarContent(themeColors),
        ),

        // Edit button
        if (showEditButton)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.33,
              height: size * 0.33,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: themeColors.primaryGradient,
                border: Border.all(color: themeColors.surface, width: 2),
              ),
              child: Icon(
                Icons.camera_alt,
                color: themeColors.onPrimary,
                size: size * 0.17,
              ),
            ),
          ),
      ],
    );

    // Wrap with Hero animation if tag provided
    if (heroTag != null) {
      avatar = Hero(
        tag: heroTag!,
        child: avatar,
      );
    }

    // Wrap with GestureDetector if onTap provided
    if (onTap != null) {
      avatar = Semantics(
        label: semanticsLabel ?? 'الصورة الشخصية',
        button: true,
        hint: showEditButton ? 'انقر لتغيير الصورة' : null,
        child: GestureDetector(
          onTap: onTap,
          child: avatar,
        ),
      );
    } else {
      avatar = Semantics(
        label: semanticsLabel ?? 'الصورة الشخصية',
        image: true,
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildAvatarContent(ThemeColors themeColors) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          fit: BoxFit.cover,
          width: size,
          height: size,
          placeholder: (context, url) => _buildFallbackAvatar(themeColors),
          errorWidget: (context, url, error) => _buildFallbackAvatar(themeColors),
        ),
      );
    }
    return _buildFallbackAvatar(themeColors);
  }

  Widget _buildFallbackAvatar(ThemeColors themeColors) {
    final initial = (fallbackText?.isNotEmpty == true)
        ? fallbackText![0].toUpperCase()
        : '?';
    final textSize = size * 0.4;

    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: textSize,
          fontWeight: FontWeight.bold,
          color: themeColors.onPrimary,
        ),
      ),
    );
  }
}
