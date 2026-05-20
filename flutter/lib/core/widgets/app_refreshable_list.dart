import 'package:flutter/material.dart';

/// A reusable pull-to-refresh wrapper for list screens.
///
/// Wraps content in a [RefreshIndicator] and handles loading, error, and empty
/// states so every list screen behaves consistently.
class AppRefreshableList<T> extends StatelessWidget {
  const AppRefreshableList({
    super.key,
    required this.items,
    required this.onRefresh,
    required this.itemBuilder,
    this.isLoading = false,
    this.errorMessage,
    this.emptyMessage = 'No items yet.',
    this.header,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 32),
    this.onEndReached,
    this.isLoadingMore = false,
  });

  final List<T>? items;
  final Future<void> Function() onRefresh;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final bool isLoading;
  final String? errorMessage;
  final String emptyMessage;
  final Widget? header;
  final EdgeInsetsGeometry padding;

  /// Called when the user scrolls within ~200px of the bottom. Use to trigger
  /// the next page in an infinite-scroll list. Safe to invoke repeatedly —
  /// the caller is expected to guard against duplicate loads.
  final VoidCallback? onEndReached;

  /// When true, shows a small spinner below the last item to indicate that
  /// the next page is being fetched.
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    if (isLoading && (items == null || items!.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null && (items == null || items!.isEmpty)) {
      return _ErrorBody(
        message: errorMessage!,
        onRetry: onRefresh,
      );
    }

    if (items == null || items!.isEmpty) {
      return _EmptyBody(
        message: emptyMessage,
        onRefresh: onRefresh,
      );
    }

    final hasHeader = header != null;
    final hasFooter = isLoadingMore;
    final itemCount =
        items!.length + (hasHeader ? 1 : 0) + (hasFooter ? 1 : 0);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (onEndReached != null &&
              notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 200) {
            onEndReached!();
          }
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (hasHeader && index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: header,
              );
            }
            if (hasFooter && index == itemCount - 1) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            final itemIndex = hasHeader ? index - 1 : index;
            return itemBuilder(context, items![itemIndex]);
          },
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
        onRefresh: () async => onRetry(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: onRetry,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.message, required this.onRefresh});

  final String message;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: Text(message)),
          ),
        ),
      ),
    );
  }
}
