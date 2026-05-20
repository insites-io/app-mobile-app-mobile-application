import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../recipes/cocktails/bloc/cocktail_bloc.dart';
import '../recipes/cocktails/bloc/cocktail_event.dart';
import '../recipes/cocktails/bloc/cocktail_state.dart';
import '../recipes/cocktails/cocktail_detail_screen.dart';
import '../recipes/cocktails/cocktails_list_screen.dart';
import '../recipes/cocktails/data/models/cocktail_model.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<CocktailBloc>().add(const CocktailsLoadRequested());
  }

  void _navigateToDetail(Cocktail cocktail) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CocktailDetailScreen(cocktail: cocktail),
      ),
    );
  }

  void _navigateToList() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CocktailsListScreen(),
      ),
    );
  }

  /// Case-insensitive substring match against name, keywords and ingredients.
  /// Ingredients are included so users can search by what's in their bar
  /// ("vodka", "gin") and surface drinks accordingly.
  List<Cocktail> _filter(List<Cocktail> cocktails, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return cocktails;
    return cocktails.where((c) {
      if (c.name.toLowerCase().contains(q)) return true;
      if ((c.keywords ?? '').toLowerCase().contains(q)) return true;
      if ((c.ingredients ?? '').toLowerCase().contains(q)) return true;
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5),
      body: BlocBuilder<CocktailBloc, CocktailState>(
        builder: (context, state) {
          final cocktails =
              state is CocktailsLoaded ? state.cocktails : <Cocktail>[];
          final isSearching = _searchQuery.trim().isNotEmpty;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _HomeHeader(
                  onSearchChanged: (value) =>
                      setState(() => _searchQuery = value),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      if (isSearching)
                        _SearchResults(
                          query: _searchQuery,
                          results: _filter(cocktails, _searchQuery),
                          onCocktailTap: _navigateToDetail,
                        )
                      else
                        _DefaultHomeBody(
                          cocktails: cocktails,
                          onSeeAll: _navigateToList,
                          onCocktailTap: _navigateToDetail,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DefaultHomeBody extends StatelessWidget {
  const _DefaultHomeBody({
    required this.cocktails,
    required this.onSeeAll,
    required this.onCocktailTap,
  });

  final List<Cocktail> cocktails;
  final VoidCallback onSeeAll;
  final ValueChanged<Cocktail> onCocktailTap;

  @override
  Widget build(BuildContext context) {
    // Sort by rating descending for "Most Popular"
    final popular = List<Cocktail>.from(cocktails)
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    final mostPopular = popular.take(4).toList();

    // API returns newest-first (sort_order=desc), so the first items are
    // the most recently added.
    final newlyAdded = cocktails.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PromoBanner(
          title: 'Cocktail Party',
          subtitle: 'We got you!',
          buttonLabel: 'SEE ALL RECIPES',
          backgroundImagePath: 'assets/images/Home-Banner.webp',
          onButtonTap: onSeeAll,
        ),
        const SizedBox(height: 32),
        SectionHeader(title: 'Most Popular', seeAllOnTap: onSeeAll),
        _HorizontalCocktailRow(
          cocktails: mostPopular,
          onCocktailTap: onCocktailTap,
        ),
        const SizedBox(height: 32),
        SectionHeader(title: 'Newly Added', seeAllOnTap: onSeeAll),
        _HorizontalCocktailRow(
          cocktails: newlyAdded,
          onCocktailTap: onCocktailTap,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _HorizontalCocktailRow extends StatelessWidget {
  const _HorizontalCocktailRow({
    required this.cocktails,
    required this.onCocktailTap,
  });

  final List<Cocktail> cocktails;
  final ValueChanged<Cocktail> onCocktailTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cocktails.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final cocktail = cocktails[index];
          return CocktailCard(
            key: ValueKey(cocktail.id),
            imageUrl: cocktail.image,
            name: cocktail.name,
            rating: cocktail.rating,
            onTap: () => onCocktailTap(cocktail),
          );
        },
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.query,
    required this.results,
    required this.onCocktailTap,
  });

  final String query;
  final List<Cocktail> results;
  final ValueChanged<Cocktail> onCocktailTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = results.isEmpty
        ? 'No matches for "$query"'
        : '${results.length} result${results.length == 1 ? '' : 's'} '
            'for "$query"';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headline,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Try a different name, keyword, or ingredient.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.78,
            ),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final cocktail = results[index];
              return CocktailCard(
                key: ValueKey(cocktail.id),
                imageUrl: cocktail.image,
                name: cocktail.name,
                rating: cocktail.rating,
                onTap: () => onCocktailTap(cocktail),
              );
            },
          ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.onSearchChanged,
  });

  final void Function(String) onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final topPadding = MediaQuery.paddingOf(context).top;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          clipper: _CurvedBottomClipper(),
          child: Container(
            color: AppColors.primary,
            padding: EdgeInsets.only(top: topPadding > 0 ? topPadding : 16),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/images/Insites-Logo.svg',
                        height: 36,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'What are you looking for?',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 68),
              ],
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 10,
          child: AppSearchBar(
            placeholder: 'Search cocktail recipes',
            onChanged: onSearchChanged,
          ),
        ),
      ],
    );
  }
}

class _CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 54);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 32,
      size.width,
      size.height - 54,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

