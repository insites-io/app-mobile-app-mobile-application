import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../recipes/cocktails/cocktails_list_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _mostPopularCocktails = [
    ('assets/images/Old-Fashioned.webp', 'Old Fashioned', 4.3),
    ('assets/images/Negroni.webp', 'Negroni', 5.0),
    ('assets/images/Margarita.webp', 'Margarita', 4.8),
    ('assets/images/Daiquiri.webp', 'Daiquiri', 4.5),
  ];

  static const _newlyAddedCocktails = [
    ('assets/images/Dry-Martini.webp', 'Dry Martini', 4.9),
    ('assets/images/Old-Fashioned.webp', 'Whiskey Sour', 4.6),
    ('assets/images/Negroni.webp', 'Aperol Spritz', 4.7),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5),
      endDrawer: const _CategoryDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _HomeHeader(
              onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
              onSearchChanged: (_) {},
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  PromoBanner(
                    title: 'Cocktail Party',
                    subtitle: 'We got you!',
                    buttonLabel: 'SEE ALL RECIPES',
                    backgroundImagePath: 'assets/images/Home-Banner.webp',
                    onButtonTap: () {},
                  ),
                  const SizedBox(height: 32),
                  SectionHeader(
                    title: 'Most Popular',
                    seeAllOnTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CocktailsListScreen(),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _mostPopularCocktails.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final (path, name, rating) =
                            _mostPopularCocktails[index];
                        return CocktailCard(
                          imagePath: path,
                          name: name,
                          rating: rating,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  SectionHeader(
                    title: 'Newly Added',
                    seeAllOnTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CocktailsListScreen(),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _newlyAddedCocktails.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final (path, name, rating) =
                            _newlyAddedCocktails[index];
                        return CocktailCard(
                          imagePath: path,
                          name: name,
                          rating: rating,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.onMenuTap,
    required this.onSearchChanged,
  });

  final VoidCallback onMenuTap;
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
                      IconButton(
                        onPressed: onMenuTap,
                        icon: const Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
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

class _CategoryDrawer extends StatelessWidget {
  const _CategoryDrawer();

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
          // Blue header area matching the app bar height
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.only(top: topPadding > 0 ? topPadding : 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          // Category list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  title: Text(
                    category,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop(); // close drawer
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
