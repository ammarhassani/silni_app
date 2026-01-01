import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/services/content_config_service.dart';
import '../../../core/router/navigation_service.dart';
import '../../../shared/widgets/glass_card.dart';

/// Banner widget for displaying promotional/informational banners
/// Behaves like MOTD - single banner, dismiss in-memory only
/// Supports home_top, home_bottom, profile, reminders positions
class BannerWidget extends ConsumerStatefulWidget {
  final String position;
  final String? audience; // all, free, max, new_users

  const BannerWidget({
    super.key,
    required this.position,
    this.audience,
  });

  @override
  ConsumerState<BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends ConsumerState<BannerWidget> {
  bool _isDismissed = false;
  AdminBanner? _banner;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    List<AdminBanner> banners;
    if (widget.audience != null) {
      banners = ContentConfigService.instance
          .getBannersForAudience(widget.audience!, widget.position);
    } else {
      banners = ContentConfigService.instance
          .getBannersForPosition(widget.position);
    }

    if (mounted) {
      setState(() {
        _banner = banners.isNotEmpty ? banners.first : null;
        _isDismissed = _banner == null;
      });

      // Track impression
      if (_banner != null) {
        ContentConfigService.instance.trackBannerImpression(_banner!.id);
      }
    }
  }

  void _dismissBanner() {
    if (mounted) {
      setState(() => _isDismissed = true);
    }
  }

  void _handleAction() {
    if (_banner?.actionType == null || _banner?.actionTarget == null) return;

    // Track click
    ContentConfigService.instance.trackBannerClick(_banner!.id);

    switch (_banner!.actionType) {
      case 'route':
        // Use pushTo to preserve back stack (so back button works)
        NavigationService.pushTo(_banner!.actionTarget!);
        break;
      case 'url':
        _launchUrl(_banner!.actionTarget!);
        break;
      case 'action':
        // Handle custom actions if needed
        break;
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed || _banner == null) {
      return const SizedBox.shrink();
    }

    final themeColors = ref.watch(themeColorsProvider);

    // Only show as clickable if there's a valid action (not 'none', has target)
    final hasAction = _banner!.actionType != 'none' &&
        _banner!.actionTarget != null &&
        _banner!.actionTarget!.isNotEmpty;

    // Determine gradient colors from banner or use theme default
    final gradientColors = _banner!.gradientColors;
    final gradient = gradientColors != null
        ? LinearGradient(
            colors: [
              Color(gradientColors[0]).withValues(alpha: 0.9),
              Color(gradientColors[1]).withValues(alpha: 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              themeColors.primary.withValues(alpha: 0.9),
              themeColors.primary.withValues(alpha: 0.7),
            ],
          );

    return Semantics(
      label: 'بانر: ${_banner!.title}',
      button: hasAction,
      child: GestureDetector(
        onTap: hasAction ? _handleAction : null,
        child: _banner!.imageUrl != null
            ? _buildImageBanner(themeColors, hasAction)
            : _buildGradientBanner(themeColors, gradient, hasAction),
      ),
    )
        .animate(delay: AppAnimations.fast)
        .fadeIn(duration: AppAnimations.normal)
        .slideY(begin: -0.2, end: 0);
  }

  Widget _buildGradientBanner(
    ThemeColors themeColors,
    LinearGradient gradient,
    bool hasAction,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      gradient: gradient,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: const Center(
              child: Icon(
                Icons.campaign_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _banner!.title,
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Dismiss button
                    GestureDetector(
                      onTap: _dismissBanner,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_banner!.description != null &&
                    _banner!.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _banner!.description!,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Action hint
                if (hasAction) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _banner!.actionType == 'url'
                            ? 'اضغط لفتح الرابط'
                            : 'اضغط للمزيد',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _banner!.actionType == 'url'
                            ? Icons.open_in_new
                            : Icons.arrow_back_ios,
                        size: 12,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBanner(ThemeColors themeColors, bool hasAction) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Stack(
        children: [
          // Background image
          Image.network(
            _banner!.imageUrl!,
            width: double.infinity,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to gradient if image fails
              return Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeColors.primary.withValues(alpha: 0.9),
                      themeColors.primary.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              );
            },
          ),

          // Gradient overlay for text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),

          // Content
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _banner!.title,
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_banner!.description != null &&
                    _banner!.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _banner!.description!,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (hasAction) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _banner!.actionType == 'url'
                            ? 'اضغط لفتح الرابط'
                            : 'اضغط للمزيد',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _banner!.actionType == 'url'
                            ? Icons.open_in_new
                            : Icons.arrow_back_ios,
                        size: 12,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Dismiss button
          Positioned(
            top: AppSpacing.xs,
            left: AppSpacing.xs, // RTL: left side
            child: GestureDetector(
              onTap: _dismissBanner,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
