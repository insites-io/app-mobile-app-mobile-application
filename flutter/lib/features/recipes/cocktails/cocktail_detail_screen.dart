import 'package:flutter/material.dart';

import '../../../config/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import 'data/models/cocktail_model.dart';

class CocktailDetailScreen extends StatefulWidget {
  const CocktailDetailScreen({super.key, required this.cocktail});

  final Cocktail cocktail;

  @override
  State<CocktailDetailScreen> createState() => _CocktailDetailScreenState();
}

class _CocktailDetailScreenState extends State<CocktailDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cocktail = widget.cocktail;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── Hero Image ──
                SliverToBoxAdapter(child: _HeroImage(cocktail: cocktail)),

                // ── Content ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.textSecondary),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Cocktail',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Rating
                        if (cocktail.rating != null)
                          Row(
                            children: [
                              Icon(Icons.star,
                                  size: 18, color: Colors.amber.shade700),
                              const SizedBox(width: 4),
                              Text(
                                cocktail.rating!.toStringAsFixed(1),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),

                        // Name & Favorites
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                cocktail.name,
                                style:
                                    theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {},
                              icon: Icon(
                                Icons.favorite_border,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              label: Text(
                                'ADD TO FAVORITES',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Duration & Amount
                        Row(
                          children: [
                            if (cocktail.duration != null)
                              Text(
                                'Duration: ${cocktail.duration} minutes',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            if (cocktail.duration != null &&
                                cocktail.amount != null)
                              const SizedBox(width: 16),
                            if (cocktail.amount != null)
                              Text(
                                'Amount: ${cocktail.amount} servings',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // ── Tab Bar ──
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(tabController: _tabController),
                ),

                // ── Tab Content ──
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _IngredientsTab(ingredients: cocktail.ingredients),
                      _InstructionsTab(instructions: cocktail.instructions),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Leave a Review ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: AppPrimaryButton(
                label: 'LEAVE A REVIEW',
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.cocktail});

  final Cocktail cocktail;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        SizedBox(
          height: 300,
          width: double.infinity,
          child: cocktail.image != null && cocktail.image!.isNotEmpty
              ? Image.network(
                  cocktail.image!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _placeholder(),
                )
              : _placeholder(),
        ),
        Positioned(
          top: topPadding + 8,
          left: 16,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade300,
      child: Icon(Icons.local_bar, size: 64, color: Colors.grey.shade500),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate({required this.tabController});

  final TabController tabController;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textPrimary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        indicator: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(4),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Ingredients'),
          Tab(text: 'Instructions'),
        ],
      ),
    );
  }
}

class _IngredientsTab extends StatelessWidget {
  const _IngredientsTab({required this.ingredients});

  final String? ingredients;

  @override
  Widget build(BuildContext context) {
    if (ingredients == null || ingredients!.isEmpty) {
      return const Center(child: Text('No ingredients listed.'));
    }

    final lines = ingredients!
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '${index + 1}. ${lines[index].trim()}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
        );
      },
    );
  }
}

class _InstructionsTab extends StatelessWidget {
  const _InstructionsTab({required this.instructions});

  final String? instructions;

  @override
  Widget build(BuildContext context) {
    if (instructions == null || instructions!.isEmpty) {
      return const Center(child: Text('No instructions provided.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Text(
        instructions!,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              height: 1.6,
            ),
      ),
    );
  }
}
