import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

/// App-styled search bar with placeholder, search icon and an optional
/// clear button that appears once the user has typed something.
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    this.placeholder = 'Search',
    this.controller,
    this.onChanged,
    this.onSubmitted,
  });

  final String placeholder;

  /// Optional external controller. When provided, the parent owns the text
  /// state and can clear it programmatically. When omitted, the search bar
  /// owns its own controller for the widget's lifetime.
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late TextEditingController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _ownsController = widget.controller == null;
    _controller.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(covariant AppSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-attach if the parent swapped controllers.
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_handleChange);
      if (_ownsController) _controller.dispose();
      _controller = widget.controller ?? TextEditingController();
      _ownsController = widget.controller == null;
      _controller.addListener(_handleChange);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleChange);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _handleChange() {
    // Rebuild so the suffix icon swaps between search and clear.
    setState(() {});
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;
    return SizedBox(
      height: 42,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.8),
              fontSize: 14,
            ),
            suffixIcon: hasText
                ? IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                    onPressed: _clear,
                  )
                : const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
      ),
    );
  }
}
