import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

/// Card displaying a cocktail with image, name, and rating.
class CocktailCard extends StatelessWidget {
  const CocktailCard({
    super.key,
    this.imagePath,
    this.imageUrl,
    required this.name,
    this.rating,
    this.onTap,
  });

  final String? imagePath;
  final String? imageUrl;
  final String name;
  final double? rating;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1,
                child: _buildImage(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (rating != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 14,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    rating!.toStringAsFixed(1),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }
    if (imagePath != null && imagePath!.isNotEmpty) {
      return Image.asset(imagePath!, fit: BoxFit.cover);
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(Icons.local_bar, size: 36, color: Colors.grey.shade400),
    );
  }
}
