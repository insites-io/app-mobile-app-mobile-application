import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

/// Reusable keywords/tags input with chips display.
class AppKeywordsField extends StatelessWidget {
  const AppKeywordsField({
    super.key,
    required this.controller,
    required this.keywords,
    required this.onAdd,
    required this.onRemove,
    this.label = 'Keywords',
    this.placeholder = 'Keywords',
    this.tooltip = 'Add keywords to help users find your recipe',
  });

  final TextEditingController controller;
  final List<String> keywords;
  final VoidCallback onAdd;
  final void Function(String) onRemove;
  final String label;
  final String placeholder;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: tooltip,
              child: Icon(
                Icons.help_outline,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          onFieldSubmitted: (_) => onAdd(),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add, color: AppColors.primary),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
        ),
        if (keywords.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: keywords
                .map(
                  (kw) => Chip(
                    label: Text(kw),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => onRemove(kw),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
