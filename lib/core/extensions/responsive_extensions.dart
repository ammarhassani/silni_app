import 'package:flutter/material.dart';
import '../constants/app_breakpoints.dart';

/// Extension methods on BuildContext for easy responsive design
extension ResponsiveBuildContext on BuildContext {
  /// Get the current screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get the current screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Check if the current screen is in mobile range (< 768px)
  bool get isMobile => AppBreakpoints.isMobile(this);

  /// Check if the current screen is in tablet range (768px - 1023px)
  bool get isTablet => AppBreakpoints.isTablet(this);

  /// Check if the current screen is in desktop range (>= 1024px)
  bool get isDesktop => AppBreakpoints.isDesktop(this);

  /// Check if the current screen is very small (< 360px)
  bool get isSmallMobile => AppBreakpoints.isSmallMobile(this);

  /// Returns the number of columns for a responsive grid
  ///
  /// Example:
  /// ```dart
  /// crossAxisCount: context.responsiveGridColumns(mobile: 2, tablet: 3)
  /// ```
  int responsiveGridColumns({
    int mobile = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    return AppBreakpoints.gridColumns(
      this,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Returns a responsive value based on screen size
  ///
  /// Example:
  /// ```dart
  /// final padding = context.responsiveValue(
  ///   mobile: 16.0,
  ///   tablet: 24.0,
  ///   desktop: 32.0,
  /// );
  /// ```
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    return AppBreakpoints.value(
      this,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Returns responsive padding scaled based on screen size
  ///
  /// Example:
  /// ```dart
  /// padding: EdgeInsets.all(context.responsivePadding(16.0))
  /// ```
  double responsivePadding(double base) {
    if (isDesktop) return base * 1.5;
    if (isTablet) return base * 1.25;
    return base;
  }

  /// Returns responsive font size scaled based on screen size
  ///
  /// Example:
  /// ```dart
  /// fontSize: context.responsiveFontSize(16.0)
  /// ```
  double responsiveFontSize(double baseSize) {
    if (isSmallMobile) return baseSize * 0.9;
    if (isDesktop) return baseSize * 1.1;
    return baseSize;
  }

  /// Returns a percentage of screen width
  ///
  /// Example:
  /// ```dart
  /// width: context.widthPercent(0.8) // 80% of screen width
  /// ```
  double widthPercent(double percent) {
    return screenWidth * percent;
  }

  /// Returns a percentage of screen height
  ///
  /// Example:
  /// ```dart
  /// height: context.heightPercent(0.5) // 50% of screen height
  /// ```
  double heightPercent(double percent) {
    return screenHeight * percent;
  }
}
