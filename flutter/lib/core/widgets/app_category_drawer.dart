import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../features/recipes/cocktails/cocktails_list_screen.dart';

/// Reusable category drawer shown from the right side of the screen.
class AppCategoryDrawer extends StatelessWidget {
  const AppCategoryDrawer({super.key});

  static const _categories = [
    'Sandwiches',
    'Cocktails',
    'Pasta',
    'Meat',
    'Seafood',
    'Dessert',
  ];

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final theme = Theme.of(context);

    return Drawer(
      shape: const RoundedRectangleBorder(),
      child: Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.only(top: topPadding > 0 ? topPadding : 16),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.menu,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24),
                  title: Text(
                    category,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    if (category == 'Cocktails') {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CocktailsListScreen(),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
