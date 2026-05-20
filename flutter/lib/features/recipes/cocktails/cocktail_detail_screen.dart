import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../authentication/bloc/auth_bloc.dart';
import '../../authentication/bloc/auth_state.dart';
import '../../favorites/bloc/favorites_bloc.dart';
import '../../favorites/bloc/favorites_event.dart';
import '../../favorites/bloc/favorites_state.dart';
import 'add_cocktail_screen.dart';
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
  late Cocktail _cocktail;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _cocktail = widget.cocktail;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cocktail = _cocktail;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero Image ──
                  _HeroImage(
                    cocktail: cocktail,
                    onEdit: () async {
                      final updated =
                          await Navigator.of(context).push<Cocktail>(
                        MaterialPageRoute<Cocktail>(
                          builder: (_) =>
                              AddCocktailScreen(cocktail: cocktail),
                        ),
                      );
                      if (updated != null) {
                        setState(() => _cocktail = updated);
                      }
                    },
                  ),

                  // ── Content ──
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category tag
                        const AppBadge(label: 'Cocktail'),
                        const SizedBox(height: 8),

                        // Rating
                        if (cocktail.rating != null)
                          Row(
                            children: [
                              Icon(Icons.star,
                                  size: 18, color: AppColors.ratingGold),
                              const SizedBox(width: 4),
                              Text(
                                cocktail.rating!.toStringAsFixed(1),
                                style:
                                    theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),

                        // Name & Favorites
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                cocktail.name,
                                style: theme.textTheme.headlineMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            BlocBuilder<FavoritesBloc, FavoritesState>(
                              builder: (context, favState) {
                                final isFav =
                                    favState.isFavorite(cocktail.id);
                                return GestureDetector(
                                  onTap: () {
                                    final authState =
                                        context.read<AuthBloc>().state;
                                    if (authState is AuthAuthenticated) {
                                      context.read<FavoritesBloc>().add(
                                            FavoritesToggleRequested(
                                              userId: authState.user.id,
                                              cocktail: cocktail,
                                            ),
                                          );
                                    }
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isFav
                                            ? 'REMOVE FAVORITE'
                                            : 'ADD TO FAVORITES',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        isFav
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isFav
                                            ? Colors.red
                                            : AppColors.primary,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Duration & Amount
                        Row(
                          children: [
                            if (cocktail.duration != null)
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Duration: ',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '${cocktail.duration} minutes',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (cocktail.duration != null &&
                                cocktail.amount != null)
                              const SizedBox(width: 16),
                            if (cocktail.amount != null)
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Amount: ',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '${cocktail.amount} servings',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                  // ── Tab Bar ──
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textPrimary,
                      labelStyle:
                          const TextStyle(fontWeight: FontWeight.w600),
                      indicator: const BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(8)),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Ingredients'),
                        Tab(text: 'Instructions'),
                      ],
                    ),
                  ),

                  // ── Tab Content (inline, no nested scroll) ──
                  _buildTabContent(context, cocktail),
                ],
              ),
            ),
          ),

          // // ── Leave a Review ──
          // SafeArea(
          //   child: Padding(
          //     padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          //     child: AppPrimaryButton(
          //       label: 'LEAVE A REVIEW',
          //       onPressed: () {},
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, Cocktail cocktail) {
    final content = _tabController.index == 0
        ? cocktail.ingredients
        : cocktail.instructions;
    final emptyMessage = _tabController.index == 0
        ? 'No ingredients listed.'
        : 'No instructions provided.';

    if (content == null || content.trim().isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(emptyMessage)),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: AppMarkdownView(data: content),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.cocktail, required this.onEdit});

  final Cocktail cocktail;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        SizedBox(
          height: 320,
          width: double.infinity,
          child: cocktail.image != null && cocktail.image!.isNotEmpty
              ? Image.network(
                  cocktail.image!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, _, _) => _placeholder(),
                )
              : _placeholder(),
        ),
        // Top bar with back and edit buttons
        Positioned(
          top: topPadding + 8,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Go back',
                icon: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 26),
              ),
              IconButton(
                onPressed: onEdit,
                tooltip: 'Edit cocktail',
                icon: const Icon(Icons.edit_outlined,
                    color: Colors.white, size: 26),
              ),
            ],
          ),
        ),
        // Rounded white overlap at the bottom of the image
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.placeholderBg,
      child: Icon(Icons.local_bar, size: 64, color: AppColors.placeholderIcon),
    );
  }
}
