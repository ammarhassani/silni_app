import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Custom scroll behavior that enables mouse drag scrolling for Flutter web.
///
/// By default, Flutter web only allows touch and stylus scrolling.
/// This class adds mouse drag support so users can click-and-drag to scroll.
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse, // Enable mouse drag for web
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
      };
}
