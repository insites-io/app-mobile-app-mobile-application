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
import '../profile/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// Switches the bottom-nav tab from anywhere inside the home stack.
  /// Used by screens like AddCocktail to bounce the user back to Home
  /// after cancelling without relying on pop, since the tabs each have
  /// their own Navigator.
  static void switchTab(BuildContext context, int index) {
    context.findAncestorStateOfType<_HomeScreenState>()?._switchTab(index);
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  static const int _notificationsTabIndex = 1;
  static const Duration _checkDebounce = Duration(seconds: 10);
  DateTime? _lastCheckAt;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    5,
    (_) => GlobalKey<NavigatorState>(),
  );

  late final List<_TabNavObserver> _navObservers = List.generate(
    5,
    (_) => _TabNavObserver(() {
      // Guard against the post-frame callback firing after the tab
      // navigator has been disposed (e.g. during a route push/pop right
      // before this State is torn down).
      if (mounted) setState(() {});
    }),
  );

  bool get _isOnSubPage => _navObservers[_selectedIndex].isOnSubPage;

  void _switchTab(int index) {
    if (index < 0 || index >= _navigatorKeys.length) return;
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
  }

  /// Fire the notification diff if the user is authenticated. When
  /// [debounced] is true, skip if a check ran within [_checkDebounce] —
  /// used for the resume / tab-switch paths that can fire repeatedly.
  /// A successful add bypasses the debounce since it's a discrete user
  /// action and the freshly added cocktail wouldn't be reflected
  /// otherwise.
  void _dispatchNotificationCheck({required bool debounced}) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    if (debounced) {
      final now = DateTime.now();
      final last = _lastCheckAt;
      if (last != null && now.difference(last) < _checkDebounce) return;
      _lastCheckAt = now;
    } else {
      _lastCheckAt = DateTime.now();
    }
    context
        .read<NotificationBloc>()
        .add(NotificationsCheckNewCocktails(authState.user.id));
  }

  void _onNavTap(int index) {
    final wasOnSameTab = _selectedIndex == index;
    if (wasOnSameTab) {
      _navigatorKeys[index]
          .currentState
          ?.popUntil((route) => route.isFirst);
    } else {
      setState(() => _selectedIndex = index);
      if (index == _notificationsTabIndex) {
        // Trigger 3: refresh when the user opens the Notifications tab —
        // matches the "I tapped the bell, show me what's new" mental model.
        _dispatchNotificationCheck(debounced: true);
      }
    }
  }

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
      // Seed the initial check and the debounce timestamp in one go.
      _dispatchNotificationCheck(debounced: false);
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
        // Trigger 1: when the user adds a cocktail in this session, re-run
        // the notification diff so they don't have to log out / back in to
        // see the new entry. The check itself is idempotent (the known set
        // dedupes), so duplicate fires are safe.
        BlocListener<CocktailBloc, CocktailState>(
          listenWhen: (previous, current) => current is CocktailAddSuccess,
          listener: (context, state) {
            _dispatchNotificationCheck(debounced: false);
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
                padding: const EdgeInsets.fromLTRB(8, 20, 8, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    _navItems.length,
                    (index) => _NavBarItem(
                      item: _navItems[index],
                      isSelected: _selectedIndex == index && !_isOnSubPage,
                      badge: index == _notificationsTabIndex && unread > 0
                          ? unread
                          : null,
                      onTap: () => _onNavTap(index),
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

