import 'package:flutter/material.dart';
import '../../core/extensions/responsive_extensions.dart';

/// A Text widget with automatic overflow handling and optional responsive sizing
///
/// This widget ensures text never causes overflow errors by automatically
/// applying maxLines and overflow properties. It can also scale font size
/// based on screen size.
///
/// Example:
/// ```dart
/// ResponsiveText(
///   'Hello World',
///   style: AppTypography.titleLarge,
///   maxLines: 2,
/// )
/// ```
class ResponsiveText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool responsiveSize;
  final StrutStyle? strutStyle;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;

  const ResponsiveText(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.responsiveSize = false,
    this.strutStyle,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.textWidthBasis,
    this.textHeightBehavior,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle? effectiveStyle = style;

    // Apply responsive font sizing if enabled
    if (responsiveSize && style != null && style!.fontSize != null) {
      final responsiveFontSize = context.responsiveFontSize(style!.fontSize!);
      effectiveStyle = style!.copyWith(fontSize: responsiveFontSize);
    }

    return Text(
      data,
      style: effectiveStyle,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
      textAlign: textAlign,
      strutStyle: strutStyle,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
    );
  }
}
