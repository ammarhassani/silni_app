import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
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

/// Simple persistent bottom navigation bar
class PersistentBottomNav extends ConsumerStatefulWidget {
  const PersistentBottomNav({super.key, required this.onNavTapped});

  final Function(String route) onNavTapped;

  @override
  ConsumerState<PersistentBottomNav> createState() =>
      _PersistentBottomNavState();
}

class _PersistentBottomNavState extends ConsumerState<PersistentBottomNav> {
  @override
  void initState() {
    super.initState();
    // Initialize the navigation index based on current route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialIndex = _getCurrentIndex(context);
      ref.read(navigationIndexProvider.notifier).state = initialIndex;
    });
  }

  @override
  void didUpdateWidget(PersistentBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Debug logging
    if (kDebugMode) {
      print('🧭 [NAV] didChangeDependencies called');
      print(
        '🧭 [NAV] Current route: ${GoRouter.of(context).routeInformationProvider.value.uri.toString()}',
      );
      final newIndex = _getCurrentIndex(context);
      print('🧭 [NAV] Calculated new index: $newIndex');
      print(
        '🧭 [NAV] Current provider state: ${ref.read(navigationIndexProvider.notifier).state}',
      );

      // Use Future.microtask to safely update state after widget tree is built
      Future.microtask(() {
        if (mounted) {
          final currentState = ref.read(navigationIndexProvider.notifier).state;
          if (currentState != newIndex) {
            print(
              '🧭 [NAV] Updating navigation index from $currentState to $newIndex (delayed)',
            );
            ref.read(navigationIndexProvider.notifier).state = newIndex;
          }
        }
      });
    } else {
      // Use Future.microtask to safely update state after widget tree is built
      Future.microtask(() {
        if (mounted) {
          final newIndex = _getCurrentIndex(context);
          final currentState = ref.read(navigationIndexProvider.notifier).state;
          if (currentState != newIndex) {
            ref.read(navigationIndexProvider.notifier).state = newIndex;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    final currentIndex = ref.watch(navigationIndexProvider);

    // Debug logging
    if (kDebugMode) {
      print('🧭 [NAV] build called');
      print(
        '🧭 [NAV] Current route: ${GoRouter.of(context).routeInformationProvider.value.uri.toString()}',
      );
      print('🧭 [NAV] Using provider currentIndex: $currentIndex');
      final calculatedIndex = _getCurrentIndex(context);
      print('🧭 [NAV] Calculated index for comparison: $calculatedIndex');
    }

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

    return Container(
      height: 75,
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            UIHelpers.withOpacity(Colors.black, 0.15),
            UIHelpers.withOpacity(Colors.black, 0.25),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: UIHelpers.withOpacity(Colors.white, 0.4),
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
                    ref.read(navigationIndexProvider.notifier).state = index;
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
                                : UIHelpers.withOpacity(Colors.white, 0.5),
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
    );
  }

  /// Get current index based on current route
  int _getCurrentIndex(BuildContext context) {
    final router = GoRouter.of(context);
    final location = router.routeInformationProvider.value.uri.toString();

    // Debug logging
    if (kDebugMode) {
      print('🧭 [NAV] _getCurrentIndex called with location: $location');
    }

    // Use location-based matching for accurate state detection
    if (location.startsWith(AppRoutes.home)) {
      if (kDebugMode) print('🧭 [NAV] Matched home route, returning 0');
      return 0;
    }
    if (location.startsWith(AppRoutes.relatives)) {
      if (kDebugMode) print('🧭 [NAV] Matched relatives route, returning 1');
      return 1;
    }
    if (location.startsWith(AppRoutes.achievements)) {
      if (kDebugMode) print('🧭 [NAV] Matched achievements route, returning 2');
      return 2;
    }
    if (location.startsWith(AppRoutes.statistics)) {
      if (kDebugMode) print('🧭 [NAV] Matched statistics route, returning 3');
      return 3;
    }
    if (location.startsWith(AppRoutes.settings)) {
      if (kDebugMode) print('🧭 [NAV] Matched settings route, returning 4');
      return 4;
    }

    // Check for parent routes (for subpages, show parent as active)
    if (location.startsWith('${AppRoutes.relativeDetail}/')) {
      if (kDebugMode)
        print(
          '🧭 [NAV] Matched relative detail route, returning 1 (relatives parent)',
        );
      return 1; // Show relatives tab for relative detail pages
    }
    if (location.startsWith('${AppRoutes.editRelative}/')) {
      if (kDebugMode)
        print(
          '🧭 [NAV] Matched edit relative route, returning 1 (relatives parent)',
        );
      return 1; // Show relatives tab for edit relative pages
    }
    if (location.startsWith('${AppRoutes.addRelative}')) {
      if (kDebugMode)
        print(
          '🧭 [NAV] Matched add relative route, returning 1 (relatives parent)',
        );
      return 1; // Show relatives tab for add relative page
    }

    // Profile is a subpage of settings, so it should show settings tab as parent
    if (location.startsWith(AppRoutes.profile)) {
      if (kDebugMode)
        print('🧭 [NAV] Matched profile route, returning 4 (settings parent)');
      return 4;
    }

    // Special handling for other routes that don't have navigation
    if (location.startsWith(AppRoutes.importContacts) ||
        location.startsWith(AppRoutes.notifications) ||
        location.startsWith('${AppRoutes.badges}/') ||
        location.startsWith('${AppRoutes.detailedStats}/') ||
        location.startsWith('${AppRoutes.leaderboard}/')) {
      if (kDebugMode)
        print('🧭 [NAV] Matched special route, returning 0 (home default)');
      return 0; // Show home tab for routes without navigation
    }

    if (kDebugMode)
      print('🧭 [NAV] No route matched, returning 0 (home default)');
    return 0; // Default to home
  }
}
