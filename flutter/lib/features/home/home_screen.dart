import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../config/app_colors.dart';
import '../authentication/bloc/auth_bloc.dart';
import '../authentication/bloc/auth_state.dart';
import '../favorites/bloc/favorites_bloc.dart';
import '../favorites/bloc/favorites_event.dart';
import '../favorites/favorites_tab.dart';
import '../notifications/bloc/notification_bloc.dart';
import '../notifications/bloc/notification_event.dart';
import '../notifications/bloc/notification_state.dart';
import '../notifications/notifications_tab.dart';
import '../recipes/cocktails/add_cocktail_screen.dart';
import '../recipes/cocktails/bloc/cocktail_bloc.dart';
import '../recipes/cocktails/bloc/cocktail_state.dart';
import '../welcome/welcome_screen.dart';
import 'home_tab.dart';
import 'profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    5,
    (_) => GlobalKey<NavigatorState>(),
  );

  late final List<_TabNavObserver> _navObservers = List.generate(
    5,
    (_) => _TabNavObserver(() => setState(() {})),
  );

  bool get _isOnSubPage => _navObservers[_selectedIndex].isOnSubPage;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context
          .read<FavoritesBloc>()
          .add(FavoritesLoadRequested(authState.user.id));
      context
          .read<NotificationBloc>()
          .add(NotificationsLoadRequested(authState.user.id));
    }
  }

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_outlined, label: 'Home'),
    _NavItem(icon: Icons.mail_outline_rounded, label: 'Notifications'),
    _NavItem(icon: Icons.add_circle_outline_rounded, label: 'Add'),
    _NavItem(icon: Icons.favorite_border_rounded, label: 'Favorites'),
    _NavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  Widget _buildTabNavigator(int index, Widget child) {
    return Navigator(
      key: _navigatorKeys[index],
      observers: [_navObservers[index]],
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthUnauthenticated) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                    builder: (_) => const WelcomeScreen()),
                (_) => false,
              );
            }
          },
        ),
        BlocListener<CocktailBloc, CocktailState>(
          listener: (context, state) {
            if (state is CocktailsLoaded) {
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated) {
                final ids = state.cocktails
                    .where((c) => c.id != null)
                    .map((c) => c.id!)
                    .toList();
                context.read<NotificationBloc>().add(
                      NotificationsCheckNewCocktails(
                        userId: authState.user.id,
                        cocktailIds: ids,
                      ),
                    );
              }
            }
          },
        ),
      ],
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          final navigator = _navigatorKeys[_selectedIndex].currentState;
          if (navigator != null && navigator.canPop()) {
            navigator.pop();
          }
        },
        child: Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildTabNavigator(0, const HomeTab()),
          _buildTabNavigator(1, const NotificationsTab()),
          _buildTabNavigator(2, const AddCocktailScreen()),
          _buildTabNavigator(3, const FavoritesTab()),
          _buildTabNavigator(4, const ProfileTab()),
        ],
      ),
      bottomNavigationBar: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, notifState) {
          final unread = notifState.unreadCount;
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 20, 8, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    _navItems.length,
                    (index) => _NavBarItem(
                      item: _navItems[index],
                      isSelected: _selectedIndex == index && !_isOnSubPage,
                      badge: index == 1 && unread > 0 ? unread : null,
                      onTap: () {
                        if (_selectedIndex == index) {
                          _navigatorKeys[index]
                              .currentState
                              ?.popUntil((route) => route.isFirst);
                        } else {
                          setState(() => _selectedIndex = index);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  item.icon,
                  size: 26,
                  color: isSelected ? AppColors.primary : Colors.grey,
                ),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        badge.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TabNavObserver extends NavigatorObserver {
  _TabNavObserver(this._onChanged);

  final VoidCallback _onChanged;
  int _routeCount = 0;

  bool get isOnSubPage => _routeCount > 1;

  void _notify() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _onChanged());
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    _routeCount++;
    _notify();
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _routeCount--;
    _notify();
  }
}

