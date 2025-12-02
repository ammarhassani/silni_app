import 'package:flutter/material.dart';

/// A Row widget that automatically switches to Column on small screens
///
/// This widget prevents overflow on narrow screens by switching from horizontal
/// to vertical layout when the available width is below a threshold.
///
/// Example:
/// ```dart
/// ResponsiveRow(
///   breakpoint: 360,
///   children: [
///     ElevatedButton(...),
///     ElevatedButton(...),
///     ElevatedButton(...),
///   ],
/// )
/// ```
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final double breakpoint;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double spacing;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.breakpoint = 360,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.spacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Switch to Column if width is below breakpoint
        if (constraints.maxWidth < breakpoint) {
          return Column(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: _convertCrossAlignment(crossAxisAlignment),
            mainAxisSize: mainAxisSize,
            children: _addSpacing(children, spacing, isColumn: true),
          );
        }

        // Use Row for wider screens
        return Row(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: mainAxisSize,
          children: _addSpacing(children, spacing, isColumn: false),
        );
      },
    );
  }

  /// Convert CrossAxisAlignment for Row to CrossAxisAlignment for Column
  CrossAxisAlignment _convertCrossAlignment(CrossAxisAlignment alignment) {
    switch (alignment) {
      case CrossAxisAlignment.start:
        return CrossAxisAlignment.start;
      case CrossAxisAlignment.end:
        return CrossAxisAlignment.end;
      case CrossAxisAlignment.center:
        return CrossAxisAlignment.center;
      case CrossAxisAlignment.stretch:
        return CrossAxisAlignment.stretch;
      case CrossAxisAlignment.baseline:
        return CrossAxisAlignment.start; // Fallback for baseline
    }
  }

  /// Add spacing between children
  List<Widget> _addSpacing(List<Widget> children, double spacing,
      {required bool isColumn}) {
    if (spacing == 0 || children.isEmpty) return children;

    final spacedChildren = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(
          isColumn
              ? SizedBox(height: spacing)
              : SizedBox(width: spacing),
        );
      }
    }
    return spacedChildren;
  }
}
