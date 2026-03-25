import 'dart:io';

import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import 'app_secondary_button.dart';

/// Reusable image picker field with upload area and preview.
class AppImagePicker extends StatelessWidget {
  const AppImagePicker({
    super.key,
    required this.onTap,
    this.selectedImage,
    this.existingImageUrl,
    this.label = 'Image',
    this.hint = 'Drag and drop\nthe file or add\nan image',
    this.formats = 'JPG, PNG, WEBP or GIF',
    this.dimensions = '800px by 600px',
    this.maxFileSize = '10 MB',
  });

  final VoidCallback onTap;
  final File? selectedImage;
  final String? existingImageUrl;
  final String label;
  final String hint;
  final String formats;
  final String dimensions;
  final String maxFileSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.inputBorder),
              borderRadius: BorderRadius.circular(4),
            ),
            child: selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      selectedImage!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : existingImageUrl != null && existingImageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          existingImageUrl!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => SizedBox(
                            height: 160,
                            child: Icon(
                              Icons.cloud_upload_outlined,
                              size: 40,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                : Column(
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 40,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hint,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'File Formats: $formats.\n'
          'Recommended Dimensions: $dimensions\n'
          'Recommended File Size: $maxFileSize',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        AppSecondaryButton(
          label: 'UPLOAD IMAGE',
          onPressed: onTap,
        ),
      ],
    );
  }
}
