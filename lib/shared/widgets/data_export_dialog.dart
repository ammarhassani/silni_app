import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/theme_provider.dart';
import '../providers/data_export_provider.dart';
import '../services/data_export_service.dart';
import '../../shared/utils/ui_helpers.dart';
import '../../shared/widgets/theme_aware_dialog.dart';

/// Dialog for data export progress and completion
class DataExportDialog extends ConsumerStatefulWidget {
  final String userId;

  const DataExportDialog({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<DataExportDialog> createState() => _DataExportDialogState();
}

class _DataExportDialogState extends ConsumerState<DataExportDialog> {
  bool _exportStarted = false;

  @override
  void initState() {
    super.initState();
    // Start export when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startExport();
    });
  }

  Future<void> _startExport() async {
    if (_exportStarted) return;
    _exportStarted = true;

    await ref.read(dataExportNotifierProvider.notifier).exportData(widget.userId);
  }

  Future<void> _shareFile(String filePath) async {
    try {
      // Get the render box for share position (required on iPad)
      final box = context.findRenderObject() as RenderBox?;
      final sharePositionOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : const Rect.fromLTWH(0, 0, 100, 100);

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Silni - تصدير البيانات',
        text: 'ملف تصدير بيانات تطبيق صلني',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'حدث خطأ أثناء المشاركة: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    final exportState = ref.watch(dataExportNotifierProvider);
    final progress = exportState.progress;

    return Dialog(
      backgroundColor: themeColors.background1.withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'تصدير البيانات',
              style: AppTypography.headlineSmall.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Progress indicator or completion state
            if (progress.status == ExportStatus.complete)
              _buildCompletionContent(themeColors, exportState)
            else if (progress.status == ExportStatus.error)
              _buildErrorContent(themeColors, progress)
            else
              _buildProgressContent(themeColors, progress),

            const SizedBox(height: AppSpacing.lg),

            // Actions
            _buildActions(themeColors, progress, exportState),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressContent(ThemeColors themeColors, ExportProgress progress) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress.progress,
                strokeWidth: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(themeColors.primary),
              ),
              Text(
                '${(progress.progress * 100).toInt()}%',
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          progress.currentStepAr,
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCompletionContent(ThemeColors themeColors, DataExportState state) {
    final result = state.result;
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: themeColors.primary.withValues(alpha: 0.2),
          ),
          child: Icon(
            Icons.check_circle_outline,
            size: 48,
            color: themeColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'تم التصدير بنجاح!',
          style: AppTypography.titleMedium.copyWith(
            color: Colors.white,
          ),
        ),
        if (result != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'تم تصدير ${result.totalRecords} سجل',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        // Compliance badges
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            _buildComplianceBadge('GDPR', themeColors),
            _buildComplianceBadge('Saudi PDPL', themeColors),
          ],
        ),
      ],
    );
  }

  Widget _buildComplianceBadge(String label, ThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: themeColors.accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
        border: Border.all(
          color: themeColors.accent.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: themeColors.accent,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildErrorContent(ThemeColors themeColors, ExportProgress progress) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withValues(alpha: 0.2),
          ),
          child: const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'حدث خطأ أثناء التصدير',
          style: AppTypography.titleMedium.copyWith(
            color: Colors.white,
          ),
        ),
        if (progress.error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            progress.error!,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildActions(
    ThemeColors themeColors,
    ExportProgress progress,
    DataExportState state,
  ) {
    if (progress.status == ExportStatus.complete && state.result != null) {
      return Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'إغلاق',
                style: AppTypography.buttonMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => _shareFile(state.result!.filePath),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                ),
              ),
              icon: const Icon(Icons.share, size: 20),
              label: const Text('مشاركة'),
            ),
          ),
        ],
      );
    }

    if (progress.status == ExportStatus.error) {
      return Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'إغلاق',
                style: AppTypography.buttonMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(dataExportNotifierProvider.notifier).reset();
                _exportStarted = false;
                _startExport();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('إعادة المحاولة'),
            ),
          ),
        ],
      );
    }

    // In progress - show cancel button
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: Text(
        'إلغاء',
        style: AppTypography.buttonMedium.copyWith(
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

/// Show the data export confirmation dialog
Future<bool?> showDataExportConfirmationDialog(
  BuildContext context,
  ThemeColors themeColors,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) => ThemeAwareAlertDialog(
      title: 'تصدير بياناتي',
      titleIcon: const Icon(Icons.download_rounded, color: Colors.white),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'هل تريد تصدير جميع بياناتك؟ سيتم إنشاء ملف يحتوي على:',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDataItem(Icons.person_outline, 'الملف الشخصي ونقاط اللعب'),
          _buildDataItem(Icons.people_outline, 'قائمة الأقارب'),
          _buildDataItem(Icons.history, 'سجل التفاعلات'),
          _buildDataItem(Icons.notifications_outlined, 'جداول التذكير'),
          _buildDataItem(Icons.mail_outline, 'سجل الإشعارات'),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: themeColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.xs),
              border: Border.all(
                color: themeColors.accent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: 16,
                  color: themeColors.accent,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'متوافق مع GDPR و نظام حماية البيانات السعودي',
                    style: AppTypography.labelSmall.copyWith(
                      color: themeColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'إلغاء',
            style: AppTypography.buttonMedium.copyWith(
              color: themeColors.primary,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColors.primary,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.download, size: 18),
          label: const Text('تصدير'),
        ),
      ],
    ),
  );
}

Widget _buildDataItem(IconData icon, String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      children: [
        Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.7)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    ),
  );
}
