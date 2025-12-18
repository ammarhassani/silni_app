import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../models/relative_model.dart';

/// Unified avatar widget for displaying relative photos
/// Shows photo if available, emoji fallback otherwise
class RelativeAvatar extends StatelessWidget {
  final Relative relative;
  final double size;
  final bool showNeedsAttentionBadge;
  final bool showFavoriteBadge;
  final String? heroTag;
  final Gradient? gradient;

  const RelativeAvatar({
    super.key,
    required this.relative,
    this.size = 60,
    this.showNeedsAttentionBadge = true,
    this.showFavoriteBadge = true,
    this.heroTag,
    this.gradient,
  });

  /// Predefined sizes for consistency
  static const double sizeSmall = 40;
  static const double sizeMedium = 60;
  static const double sizeLarge = 85;
  static const double sizeXLarge = 120;

  @override
  Widget build(BuildContext context) {
    final needsAttention = relative.needsContact;
    final effectiveGradient = gradient ??
        (needsAttention ? AppColors.streakFire : AppColors.primaryGradient);

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
                        : AppColors.islamicGreenPrimary)
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

    return avatar;
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
        border: Border.all(color: Colors.white, width: 2),
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
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? fallbackText;
  final double size;
  final Gradient? gradient;
  final String? heroTag;
  final VoidCallback? onTap;
  final bool showEditButton;

  const UserAvatar({
    super.key,
    this.photoUrl,
    this.fallbackText,
    this.size = 60,
    this.gradient,
    this.heroTag,
    this.onTap,
    this.showEditButton = false,
  });

  @override
  Widget build(BuildContext context) {
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
          child: _buildAvatarContent(),
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
                gradient: AppColors.primaryGradient,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.camera_alt,
                color: Colors.white,
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
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildAvatarContent() {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          fit: BoxFit.cover,
          width: size,
          height: size,
          placeholder: (context, url) => _buildFallbackAvatar(),
          errorWidget: (context, url, error) => _buildFallbackAvatar(),
        ),
      );
    }
    return _buildFallbackAvatar();
  }

  Widget _buildFallbackAvatar() {
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
          color: Colors.white,
        ),
      ),
    );
  }
}
