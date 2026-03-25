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
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    context.read<CocktailBloc>().add(const CocktailsLoadRequested());
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<CocktailBloc>();
    bloc.add(const CocktailsLoadRequested());
    await bloc.stream.firstWhere(
      (state) => state is CocktailsLoaded || state is CocktailError,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: const AppCategoryDrawer(),
      body: Column(
        children: [
          AppHeader(
            title: 'Cocktails',
            showBackButton: true,
            onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
          Expanded(
            child: BlocBuilder<CocktailBloc, CocktailState>(
              builder: (context, state) {
                return AppRefreshableList<Cocktail>(
                  items: state is CocktailsLoaded ? state.cocktails : null,
                  isLoading: state is CocktailLoading,
                  errorMessage:
                      state is CocktailError ? state.message : null,
                  emptyMessage:
                      'No cocktails yet. Add your first recipe!',
                  onRefresh: _onRefresh,
                  header: Text(
                    'Cocktails',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  itemBuilder: (context, cocktail) => _CocktailListCard(
                    cocktail: cocktail,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            CocktailDetailScreen(cocktail: cocktail),
                      ),
                    ),
                  ),
                );
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
