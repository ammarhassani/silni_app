import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silni_app/shared/services/data_export_service.dart';

/// Provider for the DataExportService
final dataExportServiceProvider = Provider<DataExportService>((ref) {
  return DataExportService();
});

/// State class for data export progress
class DataExportState {
  final ExportProgress progress;
  final ExportResult? result;
  final bool isExporting;

  const DataExportState({
    required this.progress,
    this.result,
    this.isExporting = false,
  });

  factory DataExportState.initial() => DataExportState(
        progress: ExportProgress.idle(),
        result: null,
        isExporting: false,
      );

  DataExportState copyWith({
    ExportProgress? progress,
    ExportResult? result,
    bool? isExporting,
  }) {
    return DataExportState(
      progress: progress ?? this.progress,
      result: result ?? this.result,
      isExporting: isExporting ?? this.isExporting,
    );
  }
}

/// StateNotifier for managing export state
class DataExportNotifier extends StateNotifier<DataExportState> {
  final DataExportService _exportService;

  DataExportNotifier(this._exportService) : super(DataExportState.initial());

  /// Start exporting user data
  Future<ExportResult?> exportData(String userId) async {
    if (state.isExporting) return null;

    state = state.copyWith(
      isExporting: true,
      progress: ExportProgress.idle(),
      result: null,
    );

    try {
      final result = await _exportService.exportUserData(
        userId: userId,
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );

      state = state.copyWith(
        isExporting: false,
        result: result,
        progress: ExportProgress.complete(),
      );

      return result;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        progress: ExportProgress.withError(e.toString()),
      );
      return null;
    }
  }

  /// Reset export state
  void reset() {
    state = DataExportState.initial();
  }
}

/// Provider for the export state notifier
final dataExportNotifierProvider =
    StateNotifierProvider<DataExportNotifier, DataExportState>((ref) {
  final exportService = ref.watch(dataExportServiceProvider);
  return DataExportNotifier(exportService);
});
