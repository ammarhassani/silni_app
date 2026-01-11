import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/sync_status_provider.dart';
import '../../core/services/sync_service.dart';

/// A subtle sync status indicator widget.
/// Shows pending operations count and sync status.
class SyncStatusIndicator extends ConsumerWidget {
  /// Whether to show the indicator as a badge (for app bar).
  final bool asBadge;

  /// Size of the indicator.
  final double size;

  /// Callback when tapped (to show details).
  final VoidCallback? onTap;

  const SyncStatusIndicator({
    super.key,
    this.asBadge = true,
    this.size = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataStatus = ref.watch(dataStatusProvider);

    // Don't show if everything is synced and online
    if (!dataStatus.shouldShowIndicator) {
      return const SizedBox.shrink();
    }

    final color = _getStatusColor(dataStatus);
    final icon = _getStatusIcon(dataStatus);

    if (asBadge) {
      return _buildBadge(context, dataStatus, color, icon);
    }

    return _buildChip(context, dataStatus, color, icon);
  }

  Widget _buildBadge(
    BuildContext context,
    DataStatus status,
    Color color,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
        ),
        child: Center(
          child: status.syncStatus == SyncStatus.syncing
              ? SizedBox(
                  width: size * 0.6,
                  height: size * 0.6,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              : status.hasUnsyncedChanges
                  ? Text(
                      _formatCount(status.pendingOperations + status.deadLetterOperations),
                      style: TextStyle(
                        color: color,
                        fontSize: size * 0.5,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Icon(icon, size: size * 0.6, color: color),
        ),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context,
    DataStatus status,
    Color color,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha:0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status.syncStatus == SyncStatus.syncing)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            else
              Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              status.arabicStatusText,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(DataStatus status) {
    if (!status.isOnline) return Colors.grey;
    if (status.deadLetterOperations > 0) return Colors.red;
    if (status.syncStatus == SyncStatus.syncing) return Colors.blue;
    if (status.pendingOperations > 0) return Colors.orange;
    return Colors.green;
  }

  IconData _getStatusIcon(DataStatus status) {
    if (!status.isOnline) return Icons.cloud_off;
    if (status.deadLetterOperations > 0) return Icons.error_outline;
    if (status.syncStatus == SyncStatus.syncing) return Icons.sync;
    if (status.pendingOperations > 0) return Icons.cloud_upload;
    return Icons.cloud_done;
  }

  String _formatCount(int count) {
    if (count > 99) return '99+';
    return count.toString();
  }
}

/// A widget that shows sync status in the app bar.
class SyncStatusAppBarAction extends ConsumerWidget {
  final VoidCallback? onTap;

  const SyncStatusAppBarAction({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataStatus = ref.watch(dataStatusProvider);

    if (!dataStatus.shouldShowIndicator) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SyncStatusIndicator(
        asBadge: true,
        size: 24,
        onTap: onTap ?? () => _showSyncDialog(context, ref, dataStatus),
      ),
    );
  }

  void _showSyncDialog(BuildContext context, WidgetRef ref, DataStatus status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              status.isOnline ? Icons.cloud : Icons.cloud_off,
              color: status.isOnline ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 8),
            const Text('حالة المزامنة'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow(
              'الاتصال',
              status.isOnline ? 'متصل' : 'غير متصل',
              status.isOnline ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 8),
            _buildStatusRow(
              'عمليات معلقة',
              status.pendingOperations.toString(),
              status.pendingOperations > 0 ? Colors.orange : Colors.green,
            ),
            if (status.deadLetterOperations > 0) ...[
              const SizedBox(height: 8),
              _buildStatusRow(
                'عمليات فاشلة',
                status.deadLetterOperations.toString(),
                Colors.red,
              ),
            ],
          ],
        ),
        actions: [
          if (status.isOnline && status.hasUnsyncedChanges)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(syncNotifierProvider.notifier).processQueue();
              },
              child: const Text('مزامنة الآن'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
