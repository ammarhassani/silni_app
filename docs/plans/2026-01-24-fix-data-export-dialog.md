# Fix Data Export Dialog Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix the data export confirmation dialog that crashes with layout/rendering errors when opened.

**Architecture:** Replace `GlassCard` usage in `ThemeAwareAlertDialog` with a simpler `Container`-based approach that doesn't have complex animations. The `GlassCard` widget has `AnimatedContainer` + `AnimatedBuilder` + `Transform.scale` which causes rendering issues in Dialog context where clips try to paint before size is determined.

**Tech Stack:** Flutter, Dart, Riverpod

---

## Problem Analysis

The `ThemeAwareAlertDialog` uses `GlassCard` which contains:
1. `AnimatedContainer` with `borderRadius` (creates clip)
2. `AnimatedBuilder` with `Transform.scale`
3. Press animations with `AnimationController`

In a `Dialog` context, this causes:
- `_RenderCustomClip._updateClip` accessing size before layout
- Semantics parent data dirty assertions
- App crashes when opening the export confirmation dialog

The working `DataExportDialog` uses a simple `Dialog` with `SizedBox` and `Container` - no `GlassCard`.

---

### Task 1: Create SimpleDialogCard Widget

**Files:**
- Create: `lib/shared/widgets/simple_dialog_card.dart`

**Step 1: Create the simple dialog card widget**

Create a new widget that provides the glass-like styling without animations:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/theme_provider.dart';
import '../utils/ui_helpers.dart';

/// A simple card for use in dialogs - no animations to avoid layout issues
class SimpleDialogCard extends ConsumerWidget {
  final Widget child;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const SimpleDialogCard({
    super.key,
    required this.child,
    this.width,
    this.padding,
    this.borderRadius = AppSpacing.radiusLg,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return Container(
      width: width,
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: themeColors.glassBorder,
          width: 1.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeColors.glassHighlight,
            themeColors.glassBackground,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: UIHelpers.withOpacity(themeColors.primaryDark, 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
```

**Step 2: Run analyzer to verify no errors**

Run: `flutter analyze lib/shared/widgets/simple_dialog_card.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/shared/widgets/simple_dialog_card.dart
git commit -m "feat: add SimpleDialogCard widget for stable dialog rendering

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

### Task 2: Update ThemeAwareAlertDialog to Use SimpleDialogCard

**Files:**
- Modify: `lib/shared/widgets/theme_aware_dialog.dart:200-276`

**Step 1: Add import for SimpleDialogCard**

At the top of the file, after the existing imports:

```dart
import 'simple_dialog_card.dart';
```

**Step 2: Replace GlassCard with SimpleDialogCard in ThemeAwareAlertDialog**

Replace the `build` method of `ThemeAwareAlertDialog` (lines 217-275):

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth - (AppSpacing.md * 2);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: SimpleDialogCard(
        width: dialogWidth,
        padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
        borderRadius: AppSpacing.radiusLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title.isNotEmpty || titleIcon != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  children: [
                    if (titleIcon != null) ...[
                      titleIcon!,
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: AppTypography.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            Flexible(child: content),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions
                    .map((action) => Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.sm),
                          child: action,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
```

**Step 3: Run analyzer to verify no errors**

Run: `flutter analyze lib/shared/widgets/theme_aware_dialog.dart`
Expected: No issues found

**Step 4: Commit**

```bash
git add lib/shared/widgets/theme_aware_dialog.dart
git commit -m "fix: use SimpleDialogCard in ThemeAwareAlertDialog to fix layout crashes

Replaces GlassCard which has complex animations that cause rendering
issues in Dialog context (clip painting before size determined).

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

### Task 3: Test the Fix

**Step 1: Full restart the app**

Run: Stop any running flutter process and restart
```bash
# Press 'q' to quit if running, then:
flutter run
```

**Step 2: Navigate to Profile screen**

- Open the app
- Navigate to Profile/Settings screen

**Step 3: Test export dialog**

- Tap "تصدير بياناتي" (Export my data)
- Expected: Confirmation dialog appears without crashes
- Verify: Can tap "تصدير" to proceed
- Verify: Export progress dialog shows correctly

**Step 4: If successful, commit verification**

```bash
git add -A
git commit -m "test: verify data export dialog fix works

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Verification Checklist

- [ ] `SimpleDialogCard` widget created and compiles
- [ ] `ThemeAwareAlertDialog` updated to use `SimpleDialogCard`
- [ ] App compiles without errors
- [ ] Export confirmation dialog opens without crashes
- [ ] Can tap Cancel to dismiss dialog
- [ ] Can tap Export to proceed with export
- [ ] Export progress dialog shows correctly
- [ ] No error logs in console when opening dialog
