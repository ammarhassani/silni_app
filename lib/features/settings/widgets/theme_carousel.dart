import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/subscription_tier.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/dynamic_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_bottom_sheet.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../subscription/screens/paywall_screen.dart';

/// Dramatic glass button for the settings page.
///
/// Shows the current theme's brand logo, name, and color palette
/// with decorative background elements matching the family tree hero style.
/// Tapping opens the full carousel in a glassmorphic bottom sheet.
class ThemePickerButton extends ConsumerWidget {
  const ThemePickerButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final currentTheme = ref.watch(currentDynamicThemeProvider);
    final colors = currentTheme.colors;

    return Semantics(
      label: 'المظهر - ${currentTheme.displayNameAr} - اضغط لتغيير المظهر',
      button: true,
      child: GlassCard(
        onTap: () => _showThemeCarousel(context),
        padding: EdgeInsets.zero,
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            colors.primary.withValues(alpha: 0.3),
            colors.primaryDark.withValues(alpha: 0.4),
            AppColors.premiumGold.withValues(alpha: 0.1),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Stack(
            children: [
              // Decorative floating color orbs
              Positioned(
                left: -12,
                top: -12,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.accent.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Positioned(
                left: 30,
                bottom: -18,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.secondary.withValues(alpha: 0.1),
                  ),
                ),
              ),

              // Primary glow (top-right)
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colors.primary.withValues(alpha: 0.2),
                        colors.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Main content
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    // Brand logo (large, with glow)
                    ThemeBrandLogo(
                      themeKey: currentTheme.key,
                      themeColors: colors,
                      size: 56,
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // Text column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المظهر',
                            style: AppTypography.titleLarge.copyWith(
                              color: themeColors.textOnGradient,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentTheme.displayNameAr,
                            style: AppTypography.bodyMedium.copyWith(
                              color: themeColors.textOnGradient
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'اضغط لاستعراض المظاهر',
                            style: AppTypography.bodySmall.copyWith(
                              color: themeColors.textOnGradient
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Arrow circle
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: themeColors.textOnGradient
                            .withValues(alpha: 0.9),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showThemeCarousel(BuildContext context) {
    GlassBottomSheet.show(
      context: context,
      maxHeightFraction: 0.65,
      builder: (ctx) => GlassBottomSheet(
        icon: Icons.palette,
        iconAccentColor: AppColors.premiumGold,
        title: 'اختر المظهر',
        child: Consumer(
          builder: (_, ref, _) {
            final currentKey = ref.watch(themeKeyProvider);
            return ThemeCarousel(currentThemeKey: currentKey);
          },
        ),
      ),
    );
  }
}

/// Premium horizontal carousel theme picker with mini app previews.
///
/// Each card renders a miniature version of the app UI using that theme's
/// actual colors, complete with a unique brand logo per theme.
class ThemeCarousel extends ConsumerStatefulWidget {
  const ThemeCarousel({super.key, required this.currentThemeKey});

  final String currentThemeKey;

  @override
  ConsumerState<ThemeCarousel> createState() => _ThemeCarouselState();
}

class _ThemeCarouselState extends ConsumerState<ThemeCarousel> {
  late PageController _pageController;
  int _focusedIndex = 0;
  String? _celebratingKey;

  @override
  void initState() {
    super.initState();
    final themes = DynamicTheme.getAllThemes();
    final initialIndex =
        themes.indexWhere((t) => t.key == widget.currentThemeKey);
    _focusedIndex = initialIndex >= 0 ? initialIndex : 0;
    _pageController = PageController(
      viewportFraction: 0.65,
      initialPage: _focusedIndex,
    );
  }

  @override
  void didUpdateWidget(ThemeCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentThemeKey != widget.currentThemeKey) {
      final themes = ref.read(dynamicThemesProvider);
      final newIndex =
          themes.indexWhere((t) => t.key == widget.currentThemeKey);
      if (newIndex >= 0 && newIndex != _focusedIndex) {
        _pageController.animateToPage(
          newIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
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
    final themes = ref.watch(dynamicThemesProvider);
    final hasThemeAccess =
        ref.watch(featureAccessProvider(FeatureIds.customThemes));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              HapticFeedback.selectionClick();
              setState(() => _focusedIndex = index);
            },
            physics: const BouncingScrollPhysics(),
            itemCount: themes.length,
            itemBuilder: (context, index) {
              final theme = themes[index];
              final isSelected = widget.currentThemeKey == theme.key;
              final isLocked = theme.isPremium && !hasThemeAccess;
              final isFocused = index == _focusedIndex;

              return _ThemePreviewCard(
                theme: theme,
                isSelected: isSelected,
                isLocked: isLocked,
                isFocused: isFocused,
                isCelebrating: _celebratingKey == theme.key,
                onTap: () => _onThemeTap(theme, isLocked),
              );
            },
          ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _PageIndicator(
          count: themes.length,
          activeIndex: _focusedIndex,
        ),
      ],
    );
  }

  void _onThemeTap(DynamicTheme theme, bool isLocked) {
    if (isLocked) {
      HapticFeedback.lightImpact();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const PaywallScreen(
            featureToUnlock: FeatureIds.customThemes,
          ),
        ),
      );
      return;
    }

    // Only apply if different from current
    if (theme.key != widget.currentThemeKey) {
      HapticFeedback.heavyImpact();
      setState(() => _celebratingKey = theme.key);

      // Apply theme — AnimatedThemeColorsNotifier smoothly lerps all
      // colors over 400ms, so every UI element morphs in place.
      ref.read(themeStateProvider.notifier).setThemeByKey(theme.key);

      // Clear card celebration after animation finishes
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _celebratingKey = null);
      });
    }
  }
}

// ---------------------------------------------------------------------------
// Theme Preview Card
// ---------------------------------------------------------------------------

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.theme,
    required this.isSelected,
    required this.isLocked,
    required this.isFocused,
    required this.isCelebrating,
    required this.onTap,
  });

  final DynamicTheme theme;
  final bool isSelected;
  final bool isLocked;
  final bool isFocused;
  final bool isCelebrating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scale = isFocused ? 1.0 : 0.88;
    final opacity = isFocused ? 1.0 : 0.6;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 300),
        child: GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Card body
                Container(
                  decoration: BoxDecoration(
                    gradient: theme.colors.backgroundGradient,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXl),
                    child: Stack(
                      children: [
                        // Mini app preview
                        Positioned.fill(
                          child: _MiniAppPreview(
                            themeKey: theme.key,
                            themeColors: theme.colors,
                          ),
                        ),
                        // Bottom gradient overlay with name + color dots
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _buildBottomOverlay(),
                        ),
                        // Locked overlay
                        if (isLocked) _buildLockedOverlay(),
                      ],
                    ),
                  ),
                ),

                // Gold selection ring
                if (isSelected) _buildSelectionRing(),

                // Checkmark badge (selected)
                if (isSelected) _buildCheckBadge(),

                // Lock badge (locked)
                if (isLocked) _buildLockBadge(),

                // Celebration animation
                if (isCelebrating) ..._buildCelebration(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomOverlay() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Theme name
          Text(
            theme.displayNameAr,
            style: AppTypography.titleSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          // Color palette dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _colorDot(theme.colors.primary),
              _colorDot(theme.colors.accent),
              _colorDot(theme.colors.secondary),
              _colorDot(theme.colors.primaryLight),
            ],
          ),
        ],
      ),
    );
  }

  Widget _colorDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
    );
  }

  Widget _buildLockedOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
        ),
      ),
    );
  }

  Widget _buildSelectionRing() {
    return Positioned(
      top: -3,
      bottom: -3,
      left: -3 + AppSpacing.xs,
      right: -3 + AppSpacing.xs,
      child: Container(
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(AppSpacing.radiusXl + 3),
          border: Border.all(
            color: AppColors.premiumGold,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.premiumGold.withValues(alpha: 0.5),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckBadge() {
    return Positioned(
      top: -4,
      right: AppSpacing.xs - 4,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.premiumGold, AppColors.premiumGoldDark],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.premiumGold.withValues(alpha: 0.5),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildLockBadge() {
    return Positioned(
      top: AppSpacing.sm,
      left: AppSpacing.xs + AppSpacing.sm,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.premiumGold,
                  AppColors.premiumGoldDark,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.lock, size: 14, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.premiumGold.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'MAX',
              style: AppTypography.labelSmall.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCelebration() {
    final radius = BorderRadius.circular(AppSpacing.radiusXl);
    return [
      // White flash — quick burst then fade
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: Colors.white,
          ),
        )
            .animate()
            .fade(duration: 80.ms, begin: 0, end: 0.35)
            .then()
            .fade(duration: 400.ms, begin: 0.35, end: 0),
      ),

      // Expanding gold ring 1
      Positioned(
        top: -4,
        bottom: -4,
        left: -4 + AppSpacing.xs,
        right: -4 + AppSpacing.xs,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl + 4),
            border: Border.all(
              color: AppColors.premiumGold,
              width: 2.5,
            ),
          ),
        )
            .animate()
            .scaleXY(begin: 0.95, end: 1.12, duration: 500.ms, curve: Curves.easeOut)
            .fadeOut(delay: 200.ms, duration: 300.ms),
      ),

      // Expanding primary ring 2 (staggered)
      Positioned(
        top: -4,
        bottom: -4,
        left: -4 + AppSpacing.xs,
        right: -4 + AppSpacing.xs,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl + 4),
            border: Border.all(
              color: theme.colors.primary.withValues(alpha: 0.6),
              width: 2,
            ),
          ),
        )
            .animate(delay: 120.ms)
            .scaleXY(begin: 0.95, end: 1.18, duration: 500.ms, curve: Curves.easeOut)
            .fadeOut(delay: 200.ms, duration: 300.ms),
      ),

      // Sparkle dots — shoot outward from corners
      ..._buildSparkles(),
    ];
  }

  List<Widget> _buildSparkles() {
    const sparklePositions = [
      Alignment(-0.7, -0.8), // top-left
      Alignment(0.7, -0.8), // top-right
      Alignment(-0.8, 0.6), // bottom-left
      Alignment(0.8, 0.6), // bottom-right
      Alignment(0.0, -0.9), // top-center
      Alignment(0.0, 0.8), // bottom-center
    ];

    return List.generate(sparklePositions.length, (i) {
      final align = sparklePositions[i];
      return Positioned.fill(
        child: Align(
          alignment: align,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.premiumGold,
              boxShadow: [
                BoxShadow(
                  color: AppColors.premiumGold.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          )
              .animate(delay: (60 * i).ms)
              .scaleXY(begin: 0, end: 1.0, duration: 200.ms, curve: Curves.easeOut)
              .moveX(
                begin: 0,
                end: align.x * 20,
                duration: 500.ms,
                curve: Curves.easeOut,
              )
              .moveY(
                begin: 0,
                end: align.y * 16,
                duration: 500.ms,
                curve: Curves.easeOut,
              )
              .fadeOut(delay: 300.ms, duration: 300.ms),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Theme Brand Logo
// ---------------------------------------------------------------------------

class ThemeBrandLogo extends StatelessWidget {
  const ThemeBrandLogo({
    super.key,
    required this.themeKey,
    required this.themeColors,
    this.size = 44,
  });

  final String themeKey;
  final ThemeColors themeColors;
  final double size;

  /// Maps theme keys to their brand emoji symbols.
  static const Map<String, String> _themeEmojis = {
    'lavender': '🌸',
    'royal': '👑',
    'sunset': '🌅',
    'rose': '💎',
    'midnight': '🌙',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: themeColors.primaryGradient,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColors.primary.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(child: _buildSymbol()),
    );
  }

  Widget _buildSymbol() {
    // Default Silni theme — use the app icon
    if (themeKey == 'default') {
      return ClipOval(
        child: Image.asset(
          'assets/images/app_icon.png',
          width: size * 0.65,
          height: size * 0.65,
          fit: BoxFit.cover,
        ),
      );
    }

    // Known themes — use emoji
    final emoji = _themeEmojis[themeKey];
    if (emoji != null) {
      return Text(
        emoji,
        style: TextStyle(fontSize: size * 0.5),
      );
    }

    // Admin/unknown themes — palette icon fallback
    return Icon(
      Icons.palette_rounded,
      color: Colors.white,
      size: size * 0.5,
    );
  }
}

// ---------------------------------------------------------------------------
// Mini App Preview
// ---------------------------------------------------------------------------

class _MiniAppPreview extends StatelessWidget {
  const _MiniAppPreview({
    required this.themeKey,
    required this.themeColors,
  });

  final String themeKey;
  final ThemeColors themeColors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        60, // Space for bottom overlay
      ),
      child: Column(
        children: [
          // Brand logo
          ThemeBrandLogo(
            themeKey: themeKey,
            themeColors: themeColors,
            size: 40,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Mini glass card 1 — avatar row
          _miniGlassCard(
            child: Row(
              children: [
                // Avatar circle
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                // Text lines
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _textLine(width: 0.7),
                      const SizedBox(height: 3),
                      _textLine(width: 0.45),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Mini glass card 2 — color swatches
          _miniGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _textLine(width: 0.85),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _miniSwatch(themeColors.primary),
                    _miniSwatch(themeColors.accent),
                    _miniSwatch(themeColors.secondary),
                    _miniSwatch(themeColors.primaryLight),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Mini glass card 3 — two side-by-side cards
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _miniGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: themeColors.accent.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _textLine(width: 0.6),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _miniGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: themeColors.primary.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _textLine(width: 0.5),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: themeColors.glassBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: themeColors.glassBorder,
          width: 0.5,
        ),
      ),
      child: child,
    );
  }

  Widget _textLine({required double width}) {
    return FractionallySizedBox(
      widthFactor: width,
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: themeColors.textSecondary.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _miniSwatch(Color color) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page Indicator
// ---------------------------------------------------------------------------

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.count,
    required this.activeIndex,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: isActive ? 10 : 8,
          height: isActive ? 10 : 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? AppColors.premiumGold
                : Colors.white.withValues(alpha: 0.3),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.premiumGold.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}


