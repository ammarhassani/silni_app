import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/ai_identity.dart';
import '../../../core/ai/ai_models.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../providers/ai_chat_provider.dart';

/// Soft persona greeting block at the top of every conversation.
///
/// Letter-paradigm welcome: avatar + name + mode subtitle + hairline.
/// Scrolls away with the conversation — does NOT sticky-pin. After the user
/// is in the conversation, the AI's left-edge accent line carries the
/// persona signature.
class PersonaGreetingBlock extends ConsumerWidget {
  const PersonaGreetingBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final mode = ref.watch(counselingModeProvider);
    final accent = themeColors.accent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        themeColors.primary,
                        themeColors.primaryLight,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: themeColors.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: themeColors.textOnGradient,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AIIdentity.name,
                        style: AppTypography.titleMedium.copyWith(
                          color: accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _modeArabic(mode),
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }

  String _modeArabic(CounselingMode mode) {
    return mode.arabicName;
  }
}
