# Shareable Moments Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform Silni's internal celebrations into shareable visual cards with AI-generated copy for MAX users, supporting Instagram Stories, WhatsApp, and general sharing.

**Architecture:** Extend the existing `ShareCardWidget` + `ShareableCardData` pattern with a new `ShareBottomSheet` that presents platform-specific sharing options and format toggling (story 9:16 / square 1:1). New card widgets render premium visuals per card type. AI copy generation uses the existing `DeepSeekAIService` pattern with a new `generateShareCopy()` method.

**Tech Stack:** Flutter widgets, RepaintBoundary image capture, share_plus, DeepSeek AI via Supabase edge function, Riverpod for state.

**Design Doc:** `docs/plans/2026-02-13-shareable-moments-design.md`

---

## Task 1: ShareableCardData — Add Occasion and Wrapped Factories

**Files:**
- Modify: `lib/shared/widgets/shareable_card_generator.dart`
- Test: `test/unit/shared/shareable_card_generator_test.dart`

**Step 1: Write the failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/shared/widgets/shareable_card_generator.dart';

void main() {
  group('ShareableCardData', () {
    test('occasion factory produces correct card for eid', () {
      final card = ShareableCardData.occasion(
        occasionName: 'عيد الفطر',
        occasionEmoji: '🌙',
        familyName: 'الشمري',
      );
      expect(card.emoji, '🌙');
      expect(card.title, contains('عيد الفطر'));
      expect(card.shareText, contains('الشمري'));
    });

    test('occasion factory works for personal card with relative name', () {
      final card = ShareableCardData.occasion(
        occasionName: 'رمضان',
        occasionEmoji: '🕌',
        relativeName: 'عمي سعد',
      );
      expect(card.title, contains('رمضان'));
      expect(card.shareText, contains('عمي سعد'));
    });

    test('wrapped factory produces correct card', () {
      final card = ShareableCardData.wrapped(
        periodName: 'يناير ٢٠٢٦',
        personalityEmoji: '🤝',
        personalityLabel: 'الوصّال',
        totalInteractions: 47,
        uniqueRelatives: 12,
      );
      expect(card.emoji, '🤝');
      expect(card.title, contains('الوصّال'));
      expect(card.subtitle, contains('47'));
      expect(card.shareText, contains('يناير'));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/shared/shareable_card_generator_test.dart -v`
Expected: FAIL — factories don't exist yet

**Step 3: Implement the factories**

Add to `ShareableCardData` in `lib/shared/widgets/shareable_card_generator.dart`:

```dart
factory ShareableCardData.occasion({
  required String occasionName,
  required String occasionEmoji,
  String? familyName,
  String? relativeName,
}) {
  final target = relativeName ?? 'عائلة ${familyName ?? ''}';
  return ShareableCardData(
    emoji: occasionEmoji,
    title: '$occasionName مبارك',
    subtitle: 'كل عام و$target بخير',
    shareText: '$occasionName مبارك — كل عام و$target بخير 🤲 #صِلني',
  );
}

factory ShareableCardData.wrapped({
  required String periodName,
  required String personalityEmoji,
  required String personalityLabel,
  required int totalInteractions,
  required int uniqueRelatives,
}) {
  return ShareableCardData(
    emoji: personalityEmoji,
    title: personalityLabel,
    subtitle: '$totalInteractions تواصل مع $uniqueRelatives قريب',
    shareText:
        '$periodName: $totalInteractions تواصل مع $uniqueRelatives قريب — شخصيتي "$personalityLabel" $personalityEmoji #صِلني',
  );
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/unit/shared/shareable_card_generator_test.dart -v`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/shared/widgets/shareable_card_generator.dart test/unit/shared/shareable_card_generator_test.dart
git commit -m "feat: add occasion and wrapped factories to ShareableCardData"
```

---

## Task 2: ShareCardBase — Story and Square Format Renderer

**Files:**
- Create: `lib/shared/widgets/share_cards/share_card_base.dart`

**Step 1: Create the base card widget**

This widget renders either story (1080x1920 at 3x = 360x640) or square (1080x1080 at 3x = 360x360) format. It provides the branded layout shell: app icon at top, hero content in the middle, copy text at bottom, watermark.

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ShareCardFormat { story, square }

class ShareCardBase extends StatelessWidget {
  final ShareCardFormat format;
  final LinearGradient gradient;
  final Widget heroContent;
  final String? copyText;
  final String? userName;

  const ShareCardBase({
    super.key,
    required this.format,
    required this.gradient,
    required this.heroContent,
    this.copyText,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final isStory = format == ShareCardFormat.story;
    final width = 360.0;
    final height = isStory ? 640.0 : 360.0;

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // App icon + branding
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Image.asset(
                  'assets/images/app_icon.png',
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: 8),
                Text(
                  'صِلني',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            // Hero content
            Expanded(
              child: Center(child: heroContent),
            ),
            // AI/static copy text
            if (copyText != null) ...[
              Text(
                copyText!,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
            ],
            // User name
            if (userName != null)
              Text(
                userName!,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/shared/widgets/share_cards/share_card_base.dart
git commit -m "feat: add ShareCardBase with story/square format support"
```

---

## Task 3: Individual Share Card Widgets

**Files:**
- Create: `lib/shared/widgets/share_cards/streak_share_card.dart`
- Create: `lib/shared/widgets/share_cards/badge_share_card.dart`
- Create: `lib/shared/widgets/share_cards/level_up_share_card.dart`
- Create: `lib/shared/widgets/share_cards/occasion_share_card.dart`
- Create: `lib/shared/widgets/share_cards/wrapped_share_card.dart`

Each card widget wraps `ShareCardBase` with type-specific hero content and gradient.

**Step 1: Create streak share card**

```dart
// lib/shared/widgets/share_cards/streak_share_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'share_card_base.dart';

class StreakShareCard extends StatelessWidget {
  final ShareCardFormat format;
  final int streak;
  final String? copyText;
  final String? userName;

  const StreakShareCard({
    super.key,
    required this.format,
    required this.streak,
    this.copyText,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return ShareCardBase(
      format: format,
      gradient: const LinearGradient(
        colors: [Color(0xFFFF8A00), Color(0xFFE52E71)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      copyText: copyText,
      userName: userName,
      heroContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text(
            '$streak',
            style: GoogleFonts.cairo(
              fontSize: 72,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            'يوم متتالي',
            style: GoogleFonts.cairo(
              fontSize: 20,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 2: Create badge share card**

```dart
// lib/shared/widgets/share_cards/badge_share_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'share_card_base.dart';

class BadgeShareCard extends StatelessWidget {
  final ShareCardFormat format;
  final String badgeEmoji;
  final String badgeName;
  final Color badgeColor;
  final String? copyText;
  final String? userName;

  const BadgeShareCard({
    super.key,
    required this.format,
    required this.badgeEmoji,
    required this.badgeName,
    required this.badgeColor,
    this.copyText,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return ShareCardBase(
      format: format,
      gradient: LinearGradient(
        colors: [badgeColor, badgeColor.withValues(alpha: 0.7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      copyText: copyText,
      userName: userName,
      heroContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(badgeEmoji, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 16),
          Text(
            badgeName,
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            'وسام جديد!',
            style: GoogleFonts.cairo(
              fontSize: 18,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 3: Create level-up share card**

```dart
// lib/shared/widgets/share_cards/level_up_share_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'share_card_base.dart';

class LevelUpShareCard extends StatelessWidget {
  final ShareCardFormat format;
  final int level;
  final String? copyText;
  final String? userName;

  const LevelUpShareCard({
    super.key,
    required this.format,
    required this.level,
    this.copyText,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return ShareCardBase(
      format: format,
      gradient: const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFF7B2FF7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      copyText: copyText,
      userName: userName,
      heroContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text(
            'مستوى $level',
            style: GoogleFonts.cairo(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 4: Create occasion share card**

```dart
// lib/shared/widgets/share_cards/occasion_share_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'share_card_base.dart';

class OccasionShareCard extends StatelessWidget {
  final ShareCardFormat format;
  final String occasionEmoji;
  final String occasionName;
  final String greetingText;
  final String? copyText;
  final String? userName;

  const OccasionShareCard({
    super.key,
    required this.format,
    required this.occasionEmoji,
    required this.occasionName,
    required this.greetingText,
    this.copyText,
    this.userName,
  });

  LinearGradient get _occasionGradient {
    if (occasionName.contains('رمضان')) {
      return const LinearGradient(
        colors: [Color(0xFF0D47A1), Color(0xFF00897B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (occasionName.contains('اليوم الوطني')) {
      return const LinearGradient(
        colors: [Color(0xFF2E7D32), Color(0xFFFFFFFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    // Eid default
    return const LinearGradient(
      colors: [Color(0xFF2E7D32), Color(0xFFFFD700)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShareCardBase(
      format: format,
      gradient: _occasionGradient,
      copyText: copyText,
      userName: userName,
      heroContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(occasionEmoji, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text(
            '$occasionName مبارك',
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              greetingText,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 5: Create wrapped share card**

```dart
// lib/shared/widgets/share_cards/wrapped_share_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:silni_app/core/theme/app_colors.dart';
import 'share_card_base.dart';

class WrappedShareCard extends StatelessWidget {
  final ShareCardFormat format;
  final String personalityEmoji;
  final String personalityLabel;
  final String periodName;
  final int totalInteractions;
  final int uniqueRelatives;
  final int? longestStreak;
  final String? copyText;
  final String? userName;

  const WrappedShareCard({
    super.key,
    required this.format,
    required this.personalityEmoji,
    required this.personalityLabel,
    required this.periodName,
    required this.totalInteractions,
    required this.uniqueRelatives,
    this.longestStreak,
    this.copyText,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return ShareCardBase(
      format: format,
      gradient: AppColors.primaryGradient,
      copyText: copyText,
      userName: userName,
      heroContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(personalityEmoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 8),
          Text(
            personalityLabel,
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            periodName,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _stat('$totalInteractions', 'تواصل'),
              const SizedBox(width: 24),
              _stat('$uniqueRelatives', 'قريب'),
              if (longestStreak != null && longestStreak! > 0) ...[
                const SizedBox(width: 24),
                _stat('$longestStreak', 'سلسلة 🔥'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
```

**Step 6: Commit**

```bash
git add lib/shared/widgets/share_cards/
git commit -m "feat: add share card widgets for streak, badge, level-up, occasion, wrapped"
```

---

## Task 4: ShareBottomSheet — Unified Share Flow

**Files:**
- Create: `lib/shared/widgets/share_bottom_sheet.dart`
- Modify: `lib/shared/widgets/share_card_widget.dart` (extend with format support)

**Step 1: Extend ShareCardWidget with new capture method**

Add a new static method to `lib/shared/widgets/share_card_widget.dart` that captures any arbitrary widget (not just ShareableCardData):

```dart
/// Captures any widget to image and shares via the platform share sheet.
static Future<void> captureWidgetAndShare(
  BuildContext context,
  Widget cardWidget, {
  required String shareText,
  Size size = const Size(360, 360),
}) async {
  final box = context.findRenderObject() as RenderBox?;
  final sharePositionOrigin =
      box != null ? box.localToGlobal(Offset.zero) & box.size : null;

  final boundary = GlobalKey();
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (context) => Positioned(
      left: -2000,
      child: RepaintBoundary(
        key: boundary,
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: cardWidget,
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  await Future.delayed(const Duration(milliseconds: 100));

  File? tempFile;
  try {
    final renderObject =
        boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (renderObject == null) return;

    final image = await renderObject.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) return;

    final tempDir = await getTemporaryDirectory();
    tempFile = File(
        '${tempDir.path}/silni_card_${DateTime.now().millisecondsSinceEpoch}.png');
    await tempFile.writeAsBytes(byteData.buffer.asUint8List());

    await Share.shareXFiles(
      [XFile(tempFile.path)],
      text: shareText,
      sharePositionOrigin: sharePositionOrigin,
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء المشاركة')),
      );
    }
  } finally {
    entry.remove();
    if (tempFile != null) {
      final fileToDelete = tempFile;
      Future.delayed(const Duration(seconds: 5), () async {
        try {
          if (await fileToDelete.exists()) {
            await fileToDelete.delete();
          }
        } catch (_) {}
      });
    }
  }
}
```

**Step 2: Create ShareBottomSheet**

```dart
// lib/shared/widgets/share_bottom_sheet.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:url_launcher/url_launcher.dart';

import 'share_card_widget.dart';
import 'share_cards/share_card_base.dart';

/// Shows a bottom sheet with card preview, format toggle, and platform share buttons.
///
/// [storyCard] and [squareCard] are the card widgets for each format.
/// [shareText] is the text caption sent alongside the image.
class ShareBottomSheet extends StatefulWidget {
  final Widget Function(ShareCardFormat format) cardBuilder;
  final String shareText;

  const ShareBottomSheet({
    super.key,
    required this.cardBuilder,
    required this.shareText,
  });

  /// Convenience method to show the sheet.
  static void show(
    BuildContext context, {
    required Widget Function(ShareCardFormat format) cardBuilder,
    required String shareText,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareBottomSheet(
        cardBuilder: cardBuilder,
        shareText: shareText,
      ),
    );
  }

  @override
  State<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<ShareBottomSheet> {
  ShareCardFormat _format = ShareCardFormat.story;
  bool _isSharing = false;

  Size get _cardSize => _format == ShareCardFormat.story
      ? const Size(360, 640)
      : const Size(360, 360);

  Future<void> _share() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      await ShareCardWidget.captureWidgetAndShare(
        context,
        widget.cardBuilder(_format),
        shareText: widget.shareText,
        size: _cardSize,
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Card preview (scaled down)
          SizedBox(
            height: _format == ShareCardFormat.story ? 320 : 180,
            child: FittedBox(
              fit: BoxFit.contain,
              child: widget.cardBuilder(_format),
            ),
          ),
          const SizedBox(height: 16),

          // Format toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _formatChip('ستوري', ShareCardFormat.story),
              const SizedBox(width: 12),
              _formatChip('مربع', ShareCardFormat.square),
            ],
          ),
          const SizedBox(height: 20),

          // Share button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSharing ? null : _share,
              icon: _isSharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share_rounded),
              label: Text(
                'مشاركة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formatChip(String label, ShareCardFormat format) {
    final selected = _format == format;
    return GestureDetector(
      onTap: () => setState(() => _format = format),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
```

**Step 3: Commit**

```bash
git add lib/shared/widgets/share_card_widget.dart lib/shared/widgets/share_bottom_sheet.dart
git commit -m "feat: add ShareBottomSheet with format toggle and captureWidgetAndShare"
```

---

## Task 5: AI Share Copy Generation

**Files:**
- Modify: `lib/core/ai/ai_prompts.dart` (add share copy prompt)
- Modify: `lib/core/ai/ai_service.dart` (add abstract method)
- Modify: `lib/core/ai/deepseek_ai_service.dart` (implement method)
- Test: `test/unit/core/ai/ai_prompts_share_test.dart`

**Step 1: Write test for prompt building**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/core/ai/ai_prompts.dart';

void main() {
  group('AIPrompts.shareCopyPrompt', () {
    test('streak prompt contains streak count', () {
      final prompt = AIPrompts.shareCopyPrompt(
        cardType: 'streak',
        context: {'streak': 30, 'tier': 'rare'},
      );
      expect(prompt, contains('30'));
      expect(prompt, contains('سعودي'));
    });

    test('badge prompt contains badge name', () {
      final prompt = AIPrompts.shareCopyPrompt(
        cardType: 'badge',
        context: {'badgeName': 'الوفي', 'badgeCriteria': '50 مكالمة'},
      );
      expect(prompt, contains('الوفي'));
    });

    test('occasion prompt contains occasion name', () {
      final prompt = AIPrompts.shareCopyPrompt(
        cardType: 'occasion',
        context: {'occasionName': 'عيد الفطر', 'familyName': 'الشمري'},
      );
      expect(prompt, contains('عيد الفطر'));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/core/ai/ai_prompts_share_test.dart -v`
Expected: FAIL — method doesn't exist

**Step 3: Add prompt builder to AIPrompts**

Add to `lib/core/ai/ai_prompts.dart`:

```dart
static String shareCopyPrompt({
  required String cardType,
  required Map<String, dynamic> context,
}) {
  final contextLines = context.entries
      .map((e) => '- ${e.key}: ${e.value}')
      .join('\n');

  final typeInstruction = switch (cardType) {
    'streak' => 'اكتب جملة فخر عن سلسلة التواصل مع العائلة. نبرة فخر ودفء.',
    'badge' => 'اكتب جملة احتفال بحصولك على وسام عائلي. نبرة فرح.',
    'level_up' => 'اكتب جملة عن الوصول لمستوى جديد في صلة الرحم. نبرة تحفيز.',
    'occasion' => 'اكتب تهنئة قصيرة بالمناسبة للمشاركة. نبرة دفء وحب.',
    'wrapped' => 'اكتب ملخص فخر عن فترة التواصل مع العائلة. نبرة فخر.',
    _ => 'اكتب جملة قصيرة مناسبة.',
  };

  return '''
أنت كاتب محتوى قصير باللهجة السعودية العامية.

## المطلوب:
$typeInstruction

## البيانات:
$contextLines

## القواعد:
- جملة واحدة فقط، ٢٠ كلمة كحد أقصى
- لهجة سعودية طبيعية (مو فصحى)
- لا تفترض أي معلومة غير مذكورة
- لا إيموجي إلا في نهاية الجملة (واحد فقط)
- الجملة للمشاركة في السوشال ميديا

أجب بالجملة فقط، بدون تنسيق أو علامات اقتباس.
''';
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/unit/core/ai/ai_prompts_share_test.dart -v`
Expected: PASS

**Step 5: Add abstract method to AIService**

Add to `lib/core/ai/ai_service.dart`:

```dart
/// Generate a one-line share copy for a card.
Future<String> generateShareCopy({
  required String cardType,
  required Map<String, dynamic> context,
});
```

**Step 6: Implement in DeepSeekAIService**

Add to `lib/core/ai/deepseek_ai_service.dart`:

```dart
@override
Future<String> generateShareCopy({
  required String cardType,
  required Map<String, dynamic> context,
}) async {
  try {
    final prompt = AIPrompts.shareCopyPrompt(
      cardType: cardType,
      context: context,
    );

    final response = await getChatCompletion(
      messages: [
        ChatMessage(
          id: '',
          conversationId: '',
          userId: '',
          role: MessageRole.user,
          content: 'اكتب الجملة',
          createdAt: DateTime.now(),
        ),
      ],
      systemPrompt: prompt,
      temperature: 0.8,
      maxTokens: 100,
      timeoutSeconds: 3,
    );

    // Clean up: remove quotes, markdown, extra whitespace
    return response
        .replaceAll(RegExp(r'^["\s]+|["\s]+$'), '')
        .replaceAll(RegExp(r'```[\s\S]*```'), '')
        .trim();
  } catch (e) {
    _logger.error(
      'Share copy generation error',
      category: LogCategory.network,
      tag: 'DeepSeekAIService',
      metadata: {'cardType': cardType, 'error': e.toString()},
    );
    rethrow;
  }
}
```

**Step 7: Add mock implementation**

If a `MockAIService` exists, add:

```dart
@override
Future<String> generateShareCopy({
  required String cardType,
  required Map<String, dynamic> context,
}) async {
  await Future.delayed(const Duration(milliseconds: 200));
  return 'الحمدلله على نعمة الصلة 🤲';
}
```

**Step 8: Commit**

```bash
git add lib/core/ai/ai_prompts.dart lib/core/ai/ai_service.dart lib/core/ai/deepseek_ai_service.dart test/unit/core/ai/ai_prompts_share_test.dart
git commit -m "feat: add generateShareCopy AI method for shareable card copy"
```

---

## Task 6: Wire Up Celebration Modals

Replace the existing share buttons in the 3 celebration modals with the new `ShareBottomSheet`.

**Files:**
- Modify: `lib/shared/widgets/badge_unlock_modal.dart` (~line 312-349)
- Modify: `lib/shared/widgets/streak_milestone_modal.dart` (~line 512-541)
- Modify: `lib/shared/widgets/level_up_modal.dart` (~line 291-320)

**Step 1: Update badge unlock modal**

In `badge_unlock_modal.dart`, replace the share button's `onPressed` (around line 313) with:

```dart
onPressed: () {
  Navigator.of(context).pop(); // Close modal first
  ShareBottomSheet.show(
    context,
    cardBuilder: (format) => BadgeShareCard(
      format: format,
      badgeEmoji: badgeEmoji,
      badgeName: widget.badgeName,
      badgeColor: badgeColor,
      userName: null, // Will add user name in a later pass if needed
    ),
    shareText: ShareableCardData.badge(
      badgeName: widget.badgeName,
      badgeEmoji: badgeEmoji,
    ).shareText,
  );
},
```

Add imports at top:
```dart
import 'share_bottom_sheet.dart';
import 'share_cards/badge_share_card.dart';
```

**Step 2: Update streak milestone modal**

In `streak_milestone_modal.dart`, replace the share button's `onPressed` (around line 513) with:

```dart
onPressed: () {
  Navigator.of(context).pop();
  ShareBottomSheet.show(
    context,
    cardBuilder: (format) => StreakShareCard(
      format: format,
      streak: widget.streak,
    ),
    shareText: ShareableCardData.streak(
      streak: widget.streak,
    ).shareText,
  );
},
```

Add imports:
```dart
import 'share_bottom_sheet.dart';
import 'share_cards/streak_share_card.dart';
```

**Step 3: Update level up modal**

In `level_up_modal.dart`, replace the share button's `onPressed` (around line 292) with:

```dart
onPressed: () {
  Navigator.of(context).pop();
  ShareBottomSheet.show(
    context,
    cardBuilder: (format) => LevelUpShareCard(
      format: format,
      level: widget.newLevel,
    ),
    shareText: ShareableCardData.levelUp(
      newLevel: widget.newLevel,
    ).shareText,
  );
},
```

Add imports:
```dart
import 'share_bottom_sheet.dart';
import 'share_cards/level_up_share_card.dart';
```

**Step 4: Commit**

```bash
git add lib/shared/widgets/badge_unlock_modal.dart lib/shared/widgets/streak_milestone_modal.dart lib/shared/widgets/level_up_modal.dart
git commit -m "feat: wire celebration modals to ShareBottomSheet with new card designs"
```

---

## Task 7: Wire Up Wrapped Screens

**Files:**
- Modify: `lib/features/wrapped/screens/monthly_wrapped_screen.dart` (~line 589-606)
- Modify: `lib/features/wrapped/screens/yearly_wrapped_screen.dart` (~line 429-452)

**Step 1: Update monthly wrapped share**

Replace the existing share button logic (around line 589) with:

```dart
ShareBottomSheet.show(
  context,
  cardBuilder: (format) => WrappedShareCard(
    format: format,
    personalityEmoji: wrapped.personalityEmoji,
    personalityLabel: wrapped.personalityLabel,
    periodName: wrapped.arabicMonthName,
    totalInteractions: wrapped.totalInteractions,
    uniqueRelatives: wrapped.uniqueRelativesContacted,
    longestStreak: wrapped.longestStreak,
  ),
  shareText: ShareableCardData.wrapped(
    periodName: wrapped.arabicMonthName,
    personalityEmoji: wrapped.personalityEmoji,
    personalityLabel: wrapped.personalityLabel,
    totalInteractions: wrapped.totalInteractions,
    uniqueRelatives: wrapped.uniqueRelativesContacted,
  ).shareText,
);
```

Add imports:
```dart
import 'package:silni_app/shared/widgets/share_bottom_sheet.dart';
import 'package:silni_app/shared/widgets/share_cards/wrapped_share_card.dart';
```

**Step 2: Update yearly wrapped share**

Replace the share button logic (around line 429) with similar pattern using the yearly wrapped model data.

**Step 3: Commit**

```bash
git add lib/features/wrapped/screens/monthly_wrapped_screen.dart lib/features/wrapped/screens/yearly_wrapped_screen.dart
git commit -m "feat: wire wrapped screens to ShareBottomSheet with new card designs"
```

---

## Task 8: Add Share to Occasion Messages Screen

**Files:**
- Modify: `lib/features/ai_assistant/screens/occasion_messages_screen.dart`

**Step 1: Add share card button to each occasion message card**

In the `_OccasionMessageCard` widget (around line 231), add a share icon button alongside the existing copy/WhatsApp buttons:

```dart
IconButton(
  onPressed: () {
    ShareBottomSheet.show(
      context,
      cardBuilder: (format) => OccasionShareCard(
        format: format,
        occasionEmoji: occasionEmoji,
        occasionName: occasionName,
        greetingText: message.message,
      ),
      shareText: '${message.message} #صِلني',
    );
  },
  icon: const Icon(Icons.image_rounded),
  tooltip: 'مشاركة كبطاقة',
),
```

The `occasionEmoji` and `occasionName` are derived from the occasion type passed to the screen.

Add imports:
```dart
import 'package:silni_app/shared/widgets/share_bottom_sheet.dart';
import 'package:silni_app/shared/widgets/share_cards/occasion_share_card.dart';
```

**Step 2: Commit**

```bash
git add lib/features/ai_assistant/screens/occasion_messages_screen.dart
git commit -m "feat: add share-as-card button to occasion message cards"
```

---

## Task 9: Add Share to Family Tree Header

**Files:**
- Modify: `lib/features/family_tree/screens/family_tree_screen.dart` (~line 311-415, `_buildHeader`)

**Step 1: Add share icon to header**

In the `_buildHeader` method, add an `IconButton` to the trailing side of the header Row. This captures the current tree view as a shareable image using the existing `RepaintBoundary` + screenshot pattern already in the file.

Find the header Row (around line 332) and add a trailing share button:

```dart
IconButton(
  onPressed: () async {
    // Use the existing tree viewport key to capture the tree
    // Show share sheet with the captured image
    await ShareCardWidget.captureWidgetAndShare(
      context,
      _buildTreeForShare(), // Method that renders a clean tree snapshot
      shareText: 'شجرة عائلتي 🌳 #صِلني',
      size: const Size(360, 640),
    );
  },
  icon: Icon(
    Icons.share_rounded,
    color: theme.colorScheme.onSurface,
    size: 22,
  ),
),
```

Note: The exact implementation of `_buildTreeForShare()` needs to capture the current tree viewport. The file already has screenshot detection logic (`_screenshotCallback`) — reuse that pattern to capture the InteractiveViewer content with the watermark applied.

**Step 2: Commit**

```bash
git add lib/features/family_tree/screens/family_tree_screen.dart
git commit -m "feat: add share button to family tree header"
```

---

## Task 10: Add Share to Gaming Center Stats Card

**Files:**
- Modify: `lib/features/gamification/screens/gaming_center_screen.dart` (~line 390-455, `_buildMainStatsDisplay`)

**Step 1: Add share button to stats card**

In the `_buildMainStatsDisplay` method, wrap the existing GlassCard in a Stack and add a positioned share button at the top-right corner:

```dart
Stack(
  children: [
    // Existing GlassCard content
    existingGlassCard,
    // Share button
    Positioned(
      top: 8,
      left: 8, // RTL: left is the trailing side
      child: IconButton(
        onPressed: () {
          final user = ref.read(currentUserProvider).valueOrNull;
          if (user == null) return;
          ShareBottomSheet.show(
            context,
            cardBuilder: (format) => WrappedShareCard(
              format: format,
              personalityEmoji: '🏆',
              personalityLabel: 'مستوى ${user.level}',
              periodName: 'إنجازاتي في صِلني',
              totalInteractions: user.totalInteractions,
              uniqueRelatives: 0, // Not readily available here
              longestStreak: user.longestStreak,
            ),
            shareText:
                'مستوى ${user.level} — ${user.totalInteractions} تواصل مع العائلة 🏆 #صِلني',
          );
        },
        icon: Icon(
          Icons.share_rounded,
          color: Colors.white.withValues(alpha: 0.7),
          size: 20,
        ),
      ),
    ),
  ],
)
```

Add imports:
```dart
import 'package:silni_app/shared/widgets/share_bottom_sheet.dart';
import 'package:silni_app/shared/widgets/share_cards/wrapped_share_card.dart';
```

**Step 2: Commit**

```bash
git add lib/features/gamification/screens/gaming_center_screen.dart
git commit -m "feat: add share button to gaming center stats card"
```

---

## Task 11: Integrate AI Copy into Share Cards (MAX Users)

**Files:**
- Modify: `lib/shared/widgets/share_bottom_sheet.dart`

**Step 1: Add AI copy loading to ShareBottomSheet**

Enhance the `ShareBottomSheet` to accept an optional `Future<String>` for AI copy that loads asynchronously. The card renders immediately with no copy; when AI resolves, it rebuilds with the copy text.

Add to `ShareBottomSheet`:
- `aiCopyFuture` parameter (optional `Future<String>?`)
- In `initState`, listen to the future and update state with AI copy
- Pass the resolved copy to `cardBuilder`

Update the `show()` method signature:
```dart
static void show(
  BuildContext context, {
  required Widget Function(ShareCardFormat format, {String? aiCopy}) cardBuilder,
  required String shareText,
  Future<String>? aiCopyFuture,
})
```

In the celebration modals, pass the AI future:
```dart
ShareBottomSheet.show(
  context,
  cardBuilder: (format, {aiCopy}) => StreakShareCard(
    format: format,
    streak: widget.streak,
    copyText: aiCopy,
  ),
  shareText: ShareableCardData.streak(streak: widget.streak).shareText,
  aiCopyFuture: isMaxUser
      ? ref.read(aiServiceProvider).generateShareCopy(
            cardType: 'streak',
            context: {'streak': widget.streak, 'tier': tierName},
          )
      : null,
);
```

**Step 2: Commit**

```bash
git add lib/shared/widgets/share_bottom_sheet.dart lib/shared/widgets/badge_unlock_modal.dart lib/shared/widgets/streak_milestone_modal.dart lib/shared/widgets/level_up_modal.dart
git commit -m "feat: integrate AI-generated share copy for MAX users"
```

---

## Task 12: Manual Testing & Polish

**Step 1: Test each share entry point**

Test all 8 entry points on a real device (not simulator — share sheet differs):
1. Trigger badge unlock → share → verify card + share sheet
2. Trigger streak milestone → share → verify card
3. Trigger level up → share → verify card
4. Open monthly wrapped → share → verify card
5. Open yearly wrapped → share → verify card (last page)
6. Open occasion messages → share individual card → verify
7. Open family tree → tap share icon → verify tree capture
8. Open gaming center → tap share on stats → verify card

**Step 2: Test format toggling**

For each entry point, toggle between story/square and verify both formats render correctly.

**Step 3: Test AI copy (MAX account)**

Log in as MAX user, trigger a share, verify AI copy appears after brief loading.

**Step 4: Test free user fallback**

Log in as free user, trigger a share, verify static copy appears (no loading, no errors).

**Step 5: Final commit**

```bash
git add -A
git commit -m "polish: shareable moments final adjustments"
```
