import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'share_card_widget.dart';
import 'share_cards/share_card_base.dart';

/// A modal bottom sheet that previews a share card and lets the user
/// pick between story (9:16) and square (1:1) formats before sharing.
class ShareBottomSheet extends StatefulWidget {
  /// Builds the card widget for the given [ShareCardFormat].
  /// Accepts an optional [aiCopy] string for AI-generated caption text.
  final Widget Function(ShareCardFormat format, {String? aiCopy}) cardBuilder;

  /// Caption text sent alongside the shared image.
  final String shareText;

  /// Optional future that resolves to an AI-generated share copy string.
  /// When provided, the card will update with the AI copy once loaded.
  final Future<String>? aiCopyFuture;

  const ShareBottomSheet({
    super.key,
    required this.cardBuilder,
    required this.shareText,
    this.aiCopyFuture,
  });

  /// Convenience method to show the bottom sheet.
  static void show(
    BuildContext context, {
    required Widget Function(ShareCardFormat format, {String? aiCopy}) cardBuilder,
    required String shareText,
    Future<String>? aiCopyFuture,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareBottomSheet(
        cardBuilder: cardBuilder,
        shareText: shareText,
        aiCopyFuture: aiCopyFuture,
      ),
    );
  }

  @override
  State<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<ShareBottomSheet> {
  ShareCardFormat _format = ShareCardFormat.story;
  bool _sharing = false;
  String? _aiCopy;

  @override
  void initState() {
    super.initState();
    widget.aiCopyFuture?.then((copy) {
      if (mounted) setState(() => _aiCopy = copy);
    }).catchError((_) {
      // Silently ignore AI failures — card works without copy
    });
  }

  Size get _cardSize => switch (_format) {
        ShareCardFormat.story => const Size(360, 640),
        ShareCardFormat.square => const Size(360, 360),
      };

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      await ShareCardWidget.captureWidgetAndShare(
        context,
        widget.cardBuilder(_format, aiCopy: _aiCopy),
        shareText: widget.shareText,
        size: _cardSize,
      );
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Card preview
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: AspectRatio(
                aspectRatio: _cardSize.width / _cardSize.height,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: _cardSize.width,
                    height: _cardSize.height,
                    child: widget.cardBuilder(_format, aiCopy: _aiCopy),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Format toggle chips
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FormatChip(
                  label: 'ستوري',
                  selected: _format == ShareCardFormat.story,
                  onTap: () => setState(() => _format = ShareCardFormat.story),
                ),
                const SizedBox(width: 12),
                _FormatChip(
                  label: 'مربع',
                  selected: _format == ShareCardFormat.square,
                  onTap: () => setState(() => _format = ShareCardFormat.square),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Share button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _sharing ? null : _share,
                icon: _sharing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.share),
                label: Text(
                  'مشاركة',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D7A3E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// A selectable format chip for story / square toggle.
class _FormatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FormatChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2D7A3E)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF2D7A3E)
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
