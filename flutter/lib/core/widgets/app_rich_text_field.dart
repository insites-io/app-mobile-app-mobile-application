import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

/// Reusable multi-line text field with a decorative toolbar.
class AppRichTextField extends StatefulWidget {
  const AppRichTextField({
    super.key,
    required this.controller,
    this.label = 'Instructions',
    this.hintText,
    this.minLines = 5,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final int minLines;

  @override
  State<AppRichTextField> createState() => _AppRichTextFieldState();
}

class _AppRichTextFieldState extends State<AppRichTextField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.inputBorder),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Toolbar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                  child: const Wrap(
                    spacing: 4,
                    children: [
                      _ToolbarIcon(Icons.format_bold),
                      _ToolbarIcon(Icons.format_italic),
                      _ToolbarIcon(Icons.title),
                      _ToolbarIcon(Icons.format_quote),
                      _ToolbarIcon(Icons.format_list_bulleted),
                      _ToolbarIcon(Icons.format_list_numbered),
                      _ToolbarIcon(Icons.link),
                      _ToolbarIcon(Icons.image_outlined),
                      _ToolbarIcon(Icons.visibility),
                      _ToolbarIcon(Icons.vertical_split),
                      _ToolbarIcon(Icons.fullscreen),
                    ],
                  ),
                ),
                // Text area
                TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  minLines: widget.minLines,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  const _ToolbarIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Icon(icon, size: 20, color: AppColors.textSecondary),
    );
  }
}
