import 'package:flutter/material.dart';

/// Responsive breakpoints for the application
///
/// This class defines breakpoints for different device sizes and provides
/// utilities for responsive design decisions.
class AppBreakpoints {
  AppBreakpoints._();

  // Breakpoint values (in logical pixels)
  static const double mobileSmall = 320;
  static const double mobile = 375;
  static const double mobileLarge = 428;
  static const double tablet = 768;
  static const double desktop = 1024;

  /// Returns true if the current screen width is in mobile range (< 768px)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tablet;
  }

  /// Returns true if the current screen width is in tablet range (768px - 1023px)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tablet && width < desktop;
  }

  /// Returns true if the current screen width is in desktop range (>= 1024px)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }

  /// Returns true if the current screen width is considered small (< 360px)
  /// Useful for detecting very small phones like iPhone SE
  static bool isSmallMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  /// Returns a value based on the current screen size
  ///
  /// Example:
  /// ```dart
  /// final padding = AppBreakpoints.value(
  ///   context,
  ///   mobile: 16.0,
  ///   tablet: 24.0,
  ///   desktop: 32.0,
  /// );
  /// ```
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width >= AppBreakpoints.desktop && desktop != null) {
      return desktop;
    }

    if (width >= AppBreakpoints.tablet && tablet != null) {
      return tablet;
    }

    return mobile;
  }

  /// Returns the number of columns for a grid based on screen size
  ///
  /// Default values:
  /// - Mobile: 2 columns
  /// - Tablet: 3 columns
  /// - Desktop: 4 columns
  static int gridColumns(
    BuildContext context, {
    int mobile = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    return value(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}
