import 'package:flutter/material.dart';
import '../../core/constants/app_spacing.dart';

/// Configuration for pagination
class PaginationConfig {
  final int pageSize;
  final double loadMoreThreshold;

  const PaginationConfig({
    this.pageSize = 20,
    this.loadMoreThreshold = 200.0,
  });
}

/// State for paginated data
class PaginatedState<T> {
  final List<T> items;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int currentPage;

  const PaginatedState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 0,
  });

  PaginatedState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? currentPage,
    bool clearError = false,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// A reusable paginated ListView with infinite scroll support
/// Optimized for 10K+ items with efficient memory usage
class PaginatedListView<T> extends StatefulWidget {
  /// The paginated state containing items and loading status
  final PaginatedState<T> state;

  /// Callback to load more items
  final Future<void> Function() onLoadMore;

  /// Callback to refresh the list
  final Future<void> Function()? onRefresh;

  /// Builder for each item
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Widget to show when the list is empty
  final Widget? emptyWidget;

  /// Widget to show while initially loading
  final Widget? loadingWidget;

  /// Widget to show at the bottom while loading more
  final Widget? loadMoreWidget;

  /// Widget to show when there's an error
  final Widget Function(String error)? errorBuilder;

  /// Pagination configuration
  final PaginationConfig config;

  /// Padding for the list
  final EdgeInsetsGeometry? padding;

  /// Whether to use a sliver list (for CustomScrollView)
  final bool useSliver;

  /// Scroll physics
  final ScrollPhysics? physics;

  /// Separator between items
  final Widget? separator;

  const PaginatedListView({
    super.key,
    required this.state,
    required this.onLoadMore,
    required this.itemBuilder,
    this.onRefresh,
    this.emptyWidget,
    this.loadingWidget,
    this.loadMoreWidget,
    this.errorBuilder,
    this.config = const PaginationConfig(),
    this.padding,
    this.useSliver = false,
    this.physics,
    this.separator,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.state.hasMore || widget.state.isLoading) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final threshold = widget.config.loadMoreThreshold;

    if (maxScroll - currentScroll <= threshold) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initial loading state
    if (widget.state.isLoading && widget.state.items.isEmpty) {
      return widget.loadingWidget ?? _buildDefaultLoading();
    }

    // Error state with no items
    if (widget.state.error != null && widget.state.items.isEmpty) {
      return widget.errorBuilder?.call(widget.state.error!) ??
          _buildDefaultError(widget.state.error!);
    }

    // Empty state
    if (widget.state.items.isEmpty && !widget.state.hasMore) {
      return widget.emptyWidget ?? _buildDefaultEmpty();
    }

    // Build the list
    if (widget.onRefresh != null) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: _buildList(),
      );
    }

    return _buildList();
  }

  Widget _buildList() {
    final itemCount = widget.state.items.length +
        (widget.state.hasMore || widget.state.isLoading ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
      padding: widget.padding ??
          const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.xxxl,
          ),
      itemCount: widget.separator != null ? itemCount * 2 - 1 : itemCount,
      itemBuilder: (context, index) {
        // Handle separator
        if (widget.separator != null) {
          if (index.isOdd) {
            return widget.separator!;
          }
          index = index ~/ 2;
        }

        // Loading more indicator at the end
        if (index >= widget.state.items.length) {
          return widget.loadMoreWidget ?? _buildDefaultLoadMore();
        }

        return widget.itemBuilder(
          context,
          widget.state.items[index],
          index,
        );
      },
    );
  }

  Widget _buildDefaultLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildDefaultLoadMore() {
    if (!widget.state.isLoading) return const SizedBox.shrink();

    return const Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildDefaultError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'لا توجد عناصر',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
