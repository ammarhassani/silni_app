import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui' as ui;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/theme_provider.dart';
import '../utils/ui_helpers.dart';

// Provider to persist the current navigation selection
final navigationIndexProvider = StateProvider<int>((ref) => 0);

// Provider to control bottom navigation visibility
final bottomNavVisibilityProvider = StateProvider<bool>((ref) => true);

/// Simple persistent bottom navigation bar with auto-hide functionality
class PersistentBottomNav extends ConsumerStatefulWidget {
  const PersistentBottomNav({super.key, required this.onNavTapped});

  final Function(String route) onNavTapped;

  @override
  ConsumerState<PersistentBottomNav> createState() =>
      _PersistentBottomNavState();
}

class _PersistentBottomNavState extends ConsumerState<PersistentBottomNav>
    with TickerProviderStateMixin {
  late AnimationController _hideController;
  late Animation<double> _hideAnimation;
  bool _isScrollingDown = false;
  double _lastScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for hide/show behavior
    _hideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _hideAnimation = CurvedAnimation(
      parent: _hideController,
      curve: Curves.easeInOutCubic,
    );

    // Show navigation initially
    _hideController.forward();

    // Initialize the navigation index based on current route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialIndex = _getCurrentIndex(context);
      ref.read(navigationIndexProvider.notifier).state = initialIndex;
    });
  }

  @override
  void dispose() {
    _hideController.dispose();
    super.dispose();
  }

  /// Handle scroll events to show/hide navigation
  void handleScrollUpdate(ScrollNotification scrollNotification) {
    if (scrollNotification is ScrollUpdateNotification) {
      final currentScrollOffset = scrollNotification.metrics.pixels;

      // Only hide/show if user is actually scrolling (not just bounce effects)
      if (scrollNotification.metrics.axis == Axis.vertical) {
        if (currentScrollOffset > _lastScrollOffset) {
          // Scrolling down
          if (!_isScrollingDown && currentScrollOffset > 50) {
            _isScrollingDown = true;
            _hideNavigation();
          }
        } else {
          // Scrolling up
          if (_isScrollingDown) {
            _isScrollingDown = false;
            _showNavigation();
          }
        }
        _lastScrollOffset = currentScrollOffset;
      }
    }
  }

  void _hideNavigation() {
    ref.read(bottomNavVisibilityProvider.notifier).state = false;
    _hideController.reverse();
  }

  void _showNavigation() {
    ref.read(bottomNavVisibilityProvider.notifier).state = true;
    _hideController.forward();
  }

  @override
  void didUpdateWidget(PersistentBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Capture context values before the callback
    final newIndex = _getCurrentIndex(context);

    // Use addPostFrameCallback for more reliable timing on real iOS devices
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final currentState = ref.read(navigationIndexProvider.notifier).state;
      if (currentState != newIndex) {
        ref.read(navigationIndexProvider.notifier).state = newIndex;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    final currentIndex = ref.watch(navigationIndexProvider);

    final items = [
      (icon: Icons.home_rounded, label: 'الرئيسية', route: AppRoutes.home),
      (
        icon: Icons.people_rounded,
        label: 'الأقارب',
        route: AppRoutes.relatives,
      ),
      (
        icon: Icons.emoji_events_rounded,
        label: 'الإنجازات',
        route: AppRoutes.achievements,
      ),
      (
        icon: Icons.bar_chart_rounded,
        label: 'الإحصائيات',
        route: AppRoutes.statistics,
      ),
      (
        icon: Icons.settings_rounded,
        label: 'الإعدادات',
        route: AppRoutes.settings,
      ),
    ];

    return AnimatedBuilder(
      animation: _hideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _hideAnimation.value) * 100),
          child: Opacity(
            opacity: _hideAnimation.value,
            child: Container(
              height: 75,
              margin: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.1,
                ), // Semi-transparent background
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: themeColors.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: UIHelpers.withOpacity(themeColors.primary, 0.5),
                    blurRadius: 50,
                    spreadRadius: -5,
                  ),
                  BoxShadow(
                    color: UIHelpers.withOpacity(AppColors.premiumGold, 0.4),
                    blurRadius: 40,
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(items.length, (index) {
                      final isSelected = index == currentIndex;
                      final item = items[index];

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // Update the persisted navigation index
                            ref.read(navigationIndexProvider.notifier).state =
                                index;
                            widget.onNavTapped(item.route);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedScale(
                                  scale: isSelected ? 1.2 : 1.0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  child: Icon(
                                    item.icon,
                                    color: isSelected
                                        ? Colors.white
                                        : UIHelpers.withOpacity(
                                            Colors.white,
                                            0.5,
                                          ),
                                    size: 26,
                                    shadows: isSelected
                                        ? [
                                            Shadow(
                                              color: themeColors.primary,
                                              blurRadius: 20,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 300),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : UIHelpers.withOpacity(Colors.white, 0.5),
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    shadows: isSelected
                                        ? [
                                            Shadow(
                                              color: themeColors.primary,
                                              blurRadius: 10,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Get current index based on current route
  int _getCurrentIndex(BuildContext context) {
    final router = GoRouter.of(context);
    final location = router.routeInformationProvider.value.uri.toString();

    // Use location-based matching for accurate state detection
    if (location.startsWith(AppRoutes.home)) {
      return 0;
    }
    if (location.startsWith(AppRoutes.relatives)) {
      return 1;
    }
    if (location.startsWith(AppRoutes.achievements)) {
      return 2;
    }
    if (location.startsWith(AppRoutes.statistics)) {
      return 3;
    }
    if (location.startsWith(AppRoutes.settings)) {
      return 4;
    }

    // Check for parent routes (for subpages, show parent as active)
    if (location.startsWith('${AppRoutes.relativeDetail}/')) {
      return 1; // Show relatives tab for relative detail pages
    }
    if (location.startsWith('${AppRoutes.editRelative}/')) {
      return 1; // Show relatives tab for edit relative pages
    }
    if (location.startsWith('${AppRoutes.addRelative}')) {
      return 1; // Show relatives tab for add relative page
    }

    // Profile is a subpage of settings, so it should show settings tab as parent
    if (location.startsWith(AppRoutes.profile)) {
      return 4;
    }

    // Special handling for other routes that don't have navigation
    if (location.startsWith(AppRoutes.importContacts) ||
        location.startsWith(AppRoutes.notifications) ||
        location.startsWith('${AppRoutes.badges}/') ||
        location.startsWith('${AppRoutes.detailedStats}/') ||
        location.startsWith('${AppRoutes.leaderboard}/')) {
      return 0; // Show home tab for routes without navigation
    }

    return 0; // Default to home
  }
}
