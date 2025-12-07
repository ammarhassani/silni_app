import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/app_logger_service.dart';
import '../../core/providers/logger_provider.dart';

/// Full-screen logger overlay
class LoggerOverlay extends ConsumerStatefulWidget {
  const LoggerOverlay({super.key});

  @override
  ConsumerState<LoggerOverlay> createState() => _LoggerOverlayState();
}

class _LoggerOverlayState extends ConsumerState<LoggerOverlay> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loggerService = ref.watch(loggerServiceProvider);
    final filterLevel = ref.watch(logFilterLevelProvider);
    final filterCategory = ref.watch(logFilterCategoryProvider);
    final searchQuery = ref.watch(logSearchQueryProvider);

    // Filter logs
    final logs = loggerService.logs.where((entry) {
      // Level filter
      if (filterLevel != null && entry.level != filterLevel) {
        return false;
      }

      // Category filter
      if (filterCategory != null && entry.category != filterCategory) {
        return false;
      }

      // Search filter
      if (searchQuery.isNotEmpty &&
          !entry.message.toLowerCase().contains(searchQuery.toLowerCase())) {
        return false;
      }

      return true;
    }).toList();

    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, ref, loggerService, logs.length),

            // Filters
            _buildFilters(ref),

            // Log list
            Expanded(
              child: logs.isEmpty ? _buildEmptyState() : _buildLogList(logs),
            ),

            // Action buttons
            _buildActions(context, ref, loggerService, logs),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    AppLoggerService loggerService,
    int logCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.islamicGreenDark,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          if (kDebugMode) ...[
            const Icon(Icons.bug_report, color: Colors.white),
            const SizedBox(width: AppSpacing.sm),
          ] else
            ...[],
          Text(
            'App Logger',
            style: AppTypography.headlineSmall.copyWith(color: Colors.white),
          ),
          const Spacer(),
          Text(
            '$logCount logs',
            style: AppTypography.bodySmall.copyWith(color: Colors.white70),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              ref.read(loggerVisibilityProvider.notifier).state = false;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      color: Colors.black54,
      child: Column(
        children: [
          // Search bar
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search logs...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: Colors.white30),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: Colors.white30),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(
                  color: AppColors.islamicGreenPrimary,
                ),
              ),
              filled: true,
              fillColor: Colors.black38,
            ),
            onChanged: (value) {
              ref.read(logSearchQueryProvider.notifier).state = value;
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Level filters
                ...LogLevel.values.map((level) {
                  final isSelected = ref.watch(logFilterLevelProvider) == level;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: FilterChip(
                      label: Text(level.name.toUpperCase()),
                      selected: isSelected,
                      backgroundColor: _getLevelColor(
                        level,
                      ).withValues(alpha: 0.3),
                      selectedColor: _getLevelColor(level),
                      labelStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        ref.read(logFilterLevelProvider.notifier).state =
                            selected ? level : null;
                      },
                    ),
                  );
                }),

                const SizedBox(width: AppSpacing.sm),

                // Category filter dropdown
                DropdownButton<LogCategory?>(
                  value: ref.watch(logFilterCategoryProvider),
                  hint: const Text(
                    'Category',
                    style: TextStyle(color: Colors.white70),
                  ),
                  dropdownColor: Colors.black87,
                  style: const TextStyle(color: Colors.white),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ...LogCategory.values.map(
                      (cat) =>
                          DropdownMenuItem(value: cat, child: Text(cat.name)),
                    ),
                  ],
                  onChanged: (value) {
                    ref.read(logFilterCategoryProvider.notifier).state = value;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(List<LogEntry> logs) {
    // Auto-scroll to bottom when new logs arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_autoScroll && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _buildLogItem(log);
      },
    );
  }

  Widget _buildLogItem(LogEntry log) {
    final color = _getLevelColor(log.level);
    final time =
        '${log.timestamp.hour.toString().padLeft(2, '0')}:'
        '${log.timestamp.minute.toString().padLeft(2, '0')}:'
        '${log.timestamp.second.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border(left: BorderSide(color: color, width: 3)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Level badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                child: Text(
                  log.level.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),

              // Category badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                child: Text(
                  log.tag != null
                      ? '${log.category.name}.${log.tag}'
                      : log.category.name,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ),

              const Spacer(),

              // Timestamp
              Text(
                time,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Message
          Text(
            log.message,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),

          // Metadata (if any)
          if (log.metadata != null && log.metadata!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              log.metadata.toString(),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // Stack trace (if any)
          if (log.stackTrace != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              log.stackTrace.toString(),
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 64, color: Colors.white38),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No logs found',
            style: AppTypography.headlineSmall.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Try adjusting your filters',
            style: AppTypography.bodySmall.copyWith(color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    WidgetRef ref,
    AppLoggerService loggerService,
    List<LogEntry> logs,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: Colors.black54,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Toggle auto-scroll
          ElevatedButton.icon(
            icon: Icon(_autoScroll ? Icons.pause : Icons.play_arrow),
            label: Text(_autoScroll ? 'Pause' : 'Resume'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.calmBlue,
            ),
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });
            },
          ),

          // Clear logs
          ElevatedButton.icon(
            icon: const Icon(Icons.delete),
            label: const Text('Clear'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () {
              loggerService.clear();
            },
          ),

          // Export logs
          ElevatedButton.icon(
            icon: const Icon(Icons.content_copy),
            label: const Text('Copy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.islamicGreenPrimary,
            ),
            onPressed: () async {
              final exported = loggerService.exportLogs();
              await Clipboard.setData(ClipboardData(text: exported));

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${logs.length} logs copied to clipboard'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return AppColors.calmBlue;
      case LogLevel.warning:
        return AppColors.warning;
      case LogLevel.error:
        return AppColors.error;
      case LogLevel.critical:
        return AppColors.energeticRed;
    }
  }
}
