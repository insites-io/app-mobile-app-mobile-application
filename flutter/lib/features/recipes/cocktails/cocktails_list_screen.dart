import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import 'bloc/cocktail_bloc.dart';
import 'bloc/cocktail_event.dart';
import 'bloc/cocktail_state.dart';
import 'cocktail_detail_screen.dart';
import 'data/models/cocktail_model.dart';

class CocktailsListScreen extends StatefulWidget {
  const CocktailsListScreen({super.key});

  @override
  State<CocktailsListScreen> createState() => _CocktailsListScreenState();
}

class _CocktailsListScreenState extends State<CocktailsListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CocktailBloc>().add(const CocktailsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const AppHeader(title: 'Cocktails', showBackButton: true),
          Expanded(
            child: BlocBuilder<CocktailBloc, CocktailState>(
              builder: (context, state) {
                if (state is CocktailLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is CocktailError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => context
                                .read<CocktailBloc>()
                                .add(const CocktailsLoadRequested()),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is CocktailsLoaded) {
                  if (state.cocktails.isEmpty) {
                    return const Center(
                      child: Text('No cocktails yet. Add your first recipe!'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    itemCount: state.cocktails.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Cocktails',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                        );
                      }

                      final cocktail = state.cocktails[index - 1];
                      return _CocktailListCard(
                        cocktail: cocktail,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                CocktailDetailScreen(cocktail: cocktail),
                          ),
                        ),
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CocktailListCard extends StatelessWidget {
  const _CocktailListCard({
    required this.cocktail,
    required this.onTap,
  });

  final Cocktail cocktail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: _buildImage(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    cocktail.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (cocktail.rating != null) ...[
                  Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 4),
                  Text(
                    cocktail.rating!.toStringAsFixed(1),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (cocktail.image != null && cocktail.image!.isNotEmpty) {
      return Image.network(
        cocktail.image!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(Icons.local_bar, size: 48, color: Colors.grey.shade400),
    );
  }
}
