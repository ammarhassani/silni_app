import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/router/app_routes.dart';
import '../models/relative_model.dart';
import 'dart:math' as math;

class AvatarCarousel extends StatefulWidget {
  final List<Relative> relatives;
  final VoidCallback? onAddRelative;

  const AvatarCarousel({
    super.key,
    required this.relatives,
    this.onAddRelative,
  });

  @override
  State<AvatarCarousel> createState() => _AvatarCarouselState();
}

class _AvatarCarouselState extends State<AvatarCarousel> {
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.35, // Show parts of adjacent items
      initialPage: 0,
    );

    // Listen to page changes for smooth animations
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void didUpdateWidget(AvatarCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the number of relatives changed, reset to first page
    if (oldWidget.relatives.length != widget.relatives.length) {
      // Jump to first page to show new relative
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Include add button as last item
    final totalItems = widget.relatives.length + 1;

    return Column(
      children: [
        // Carousel
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pageController,
            itemCount: totalItems,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              if (index == widget.relatives.length) {
                // Add relative button
                return _buildCarouselItem(
                  index: index,
                  child: _buildAddButton(),
                );
              }

              final relative = widget.relatives[index];
              return _buildCarouselItem(
                key: ValueKey(relative.id), // Add unique key for each relative
                index: index,
                child: _buildRelativeAvatar(relative),
              );
            },
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Page indicators (dots)
        if (totalItems > 1) _buildPageIndicators(totalItems),
      ],
    );
  }

  Widget _buildCarouselItem({
    Key? key,
    required int index,
    required Widget child,
  }) {
    // Calculate scale based on distance from center
    final difference = (index - _currentPage).abs();
    final scale = 1.0 - math.min(difference * 0.3, 0.4);
    final opacity = 1.0 - math.min(difference * 0.3, 0.5);

    return Transform.scale(
      key: key,
      scale: scale,
      child: Opacity(
        opacity: opacity.clamp(0.5, 1.0),
        child: child,
      ),
    );
  }

  Widget _buildRelativeAvatar(Relative relative) {
    final needsAttention = relative.needsContact;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push('${AppRoutes.relativeDetail}/${relative.id}');
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar with hero animation
          Hero(
            tag: 'avatar-${relative.id}',
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing ring for attention
                if (needsAttention)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 2),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 1.0 + (value * 0.2),
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.joyfulOrange.withOpacity(1.0 - value),
                              width: 3,
                            ),
                          ),
                        ),
                      );
                    },
                    onEnd: () {
                      if (mounted) {
                        setState(() {}); // Restart animation
                      }
                    },
                  ),

                // Main avatar container
                Container(
                  width: 85,
                  height: 85,
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
                            .withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Avatar content
                      Center(
                        child: Text(
                          relative.displayEmoji,
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),

                      // Notification badge
                      if (needsAttention)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.joyfulOrange,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.notifications_active,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Name
          SizedBox(
            width: 90,
            child: Text(
              relative.fullName.split(' ').first,
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Relationship
          SizedBox(
            width: 90,
            child: Text(
              relative.relationshipType.arabicName,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        if (widget.onAddRelative != null) {
          widget.onAddRelative!();
        } else {
          context.push(AppRoutes.addRelative);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.islamicGreenPrimary.withOpacity(0.3),
                  AppColors.premiumGold.withOpacity(0.2),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 2,
                style: BorderStyle.solid,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.premiumGold.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'إضافة قريب',
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = (_currentPage.round() == index);
        final difference = (index - _currentPage).abs();
        final size = isActive ? 8.0 : 6.0;
        final opacity = 1.0 - math.min(difference * 0.5, 0.7);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(opacity.clamp(0.3, 1.0)),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
