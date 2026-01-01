import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/services/content_config_service.dart';
import '../../../core/router/navigation_service.dart';
import '../../../shared/widgets/glass_card.dart';

/// Message of the Day widget displayed on the home screen
/// Dismiss state is in-memory only - reappears on app restart/refresh
class MOTDWidget extends ConsumerStatefulWidget {
  const MOTDWidget({super.key});

  @override
  ConsumerState<MOTDWidget> createState() => _MOTDWidgetState();
}

class _MOTDWidgetState extends ConsumerState<MOTDWidget> {
  bool _isDismissed = false;
  AdminMOTD? _motd;

  @override
  void initState() {
    super.initState();
    _loadMOTD();
  }

  void _loadMOTD() {
    final motd = ContentConfigService.instance.getCurrentMOTD();
    if (mounted) {
      setState(() {
        _motd = motd;
        _isDismissed = motd == null;
      });
    }
  }

  void _dismissMOTD() {
    if (mounted) {
      setState(() => _isDismissed = true);
    }
  }

  void _handleAction() {
    if (_motd?.actionType == null || _motd?.actionTarget == null) return;

    switch (_motd!.actionType) {
      case 'route':
        // Use pushTo to preserve back stack (so back button works)
        NavigationService.pushTo(_motd!.actionTarget!);
        break;
      case 'url':
        // Could launch URL if needed
        break;
      case 'action':
        // Handle custom actions
        break;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'tip':
        return Icons.lightbulb_outline;
      case 'motivation':
        return Icons.favorite_outline;
      case 'reminder':
        return Icons.notifications_active_outlined;
      case 'announcement':
        return Icons.campaign_outlined;
      case 'celebration':
        return Icons.celebration_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _getColorForType(String type, ThemeColors themeColors) {
    switch (type) {
      case 'tip':
        return AppColors.info;
      case 'motivation':
        return AppColors.emotionalPurple;
      case 'reminder':
        return AppColors.warning;
      case 'announcement':
        return themeColors.primary;
      case 'celebration':
        return AppColors.joyfulOrange;
      default:
        return themeColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed || _motd == null) {
      return const SizedBox.shrink();
    }

    final themeColors = ref.watch(themeColorsProvider);
    final typeColor = _getColorForType(_motd!.messageType, themeColors);
    // Only show as clickable if there's a valid action route (not null, not empty)
    final hasAction = _motd!.actionType != null &&
        _motd!.actionType != 'none' &&
        _motd!.actionTarget != null &&
        _motd!.actionTarget!.isNotEmpty;

    return Semantics(
      label: 'رسالة اليوم: ${_motd!.titleAr}',
      button: hasAction,
      child: GestureDetector(
        onTap: hasAction ? _handleAction : null,
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.sm),
          gradient: LinearGradient(
            colors: [
              typeColor.withValues(alpha: 0.15),
              typeColor.withValues(alpha: 0.05),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon/Emoji
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: typeColor.withValues(alpha: 0.2),
                ),
                child: Center(
                  child: _motd!.emoji != null
                      ? Text(_motd!.emoji!, style: const TextStyle(fontSize: 20))
                      : Icon(
                          _getIconForType(_motd!.messageType),
                          color: typeColor,
                          size: 22,
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _motd!.titleAr,
                            style: AppTypography.labelMedium.copyWith(
                              color: typeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Dismiss button
                        GestureDetector(
                          onTap: _dismissMOTD,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: themeColors.textHint,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _motd!.contentAr,
                      style: AppTypography.bodySmall.copyWith(
                        color: themeColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Action hint with arrow
                    if (hasAction) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'اضغط للمزيد',
                            style: AppTypography.labelSmall.copyWith(
                              color: typeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_back_ios,
                            size: 12,
                            color: typeColor,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: AppAnimations.fast)
        .fadeIn(duration: AppAnimations.normal)
        .slideY(begin: -0.2, end: 0);
  }
}
