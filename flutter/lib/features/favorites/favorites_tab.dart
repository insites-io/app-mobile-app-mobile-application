import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../config/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../authentication/bloc/auth_bloc.dart';
import '../authentication/bloc/auth_state.dart';
import '../recipes/cocktails/cocktail_detail_screen.dart';
import '../recipes/cocktails/cocktails_list_screen.dart';
import '../recipes/cocktails/data/models/cocktail_model.dart';
import 'bloc/favorites_bloc.dart';
import 'bloc/favorites_event.dart';
import 'bloc/favorites_state.dart';

class FavoritesTab extends StatefulWidget {
  const FavoritesTab({super.key});

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context
          .read<FavoritesBloc>()
          .add(FavoritesLoadRequested(authState.user.id));
    }
  }

  void _navigateToDetail(Cocktail cocktail) {
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (_) => CocktailDetailScreen(cocktail: cocktail),
      ),
    )
        .then((_) => _loadFavorites());
  }

  void _navigateToCocktails() {
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (_) => const CocktailsListScreen(),
      ),
    )
        .then((_) => _loadFavorites());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          AppHeader(
            title: 'Favorites',
            showMenuIcon: false,
          ),
          Expanded(
            child: BlocBuilder<FavoritesBloc, FavoritesState>(
              builder: (context, state) {
                if (state is! FavoritesLoaded || state.favorites.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No favorites added',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'There are no recipes added in your favorites.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        AppPrimaryButton(
                          label: 'ADD FAVORITES',
                          onPressed: _navigateToCocktails,
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: state.favorites.length,
                  itemBuilder: (context, index) {
                    final cocktail = state.favorites[index];
                    return CocktailCard(
                      imageUrl: cocktail.image,
                      name: cocktail.name,
                      rating: cocktail.rating,
                      onTap: () => _navigateToDetail(cocktail),
                    );
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
