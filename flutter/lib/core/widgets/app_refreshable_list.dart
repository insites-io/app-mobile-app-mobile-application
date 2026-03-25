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
  });

  final List<T>? items;
  final Future<void> Function() onRefresh;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final bool isLoading;
  final String? errorMessage;
  final String emptyMessage;
  final Widget? header;
  final EdgeInsetsGeometry padding;

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
    final itemCount = items!.length + (hasHeader ? 1 : 0);

    return RefreshIndicator(
      onRefresh: onRefresh,
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
          final itemIndex = hasHeader ? index - 1 : index;
          return itemBuilder(context, items![itemIndex]);
        },
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
