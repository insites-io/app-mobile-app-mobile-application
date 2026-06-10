import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/app_theme.dart';
import 'core/api/api_client.dart';
import 'core/services/deep_link_service.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/authentication/bloc/auth_bloc.dart';
import 'features/authentication/bloc/auth_event.dart';
import 'features/authentication/bloc/auth_state.dart';
import 'features/authentication/data/repositories/auth_repository.dart';
import 'features/authentication/forgot_password/reset_password_screen.dart';
import 'features/favorites/bloc/favorites_bloc.dart';
import 'features/favorites/data/repositories/favorites_repository.dart';
import 'features/notifications/bloc/notification_bloc.dart';
import 'features/notifications/data/repositories/notification_repository.dart';
import 'features/recipes/cocktails/bloc/cocktail_bloc.dart';
import 'features/recipes/cocktails/data/repositories/cocktail_repository.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  final apiClient = ApiClient();
  final secureStorage = SecureStorageService();
  final authRepository = AuthRepository(
    apiClient: apiClient,
    secureStorage: secureStorage,
  );
  final cocktailRepository = CocktailRepository(
    apiClient: apiClient,
  );
  final favoritesRepository = FavoritesRepository();
  final notificationRepository = NotificationRepository();
  final deepLinkService = DeepLinkService();

  runApp(InsitesApp(
    apiClient: apiClient,
    authRepository: authRepository,
    cocktailRepository: cocktailRepository,
    favoritesRepository: favoritesRepository,
    notificationRepository: notificationRepository,
    deepLinkService: deepLinkService,
  ));
}

class InsitesApp extends StatefulWidget {
  const InsitesApp({
    super.key,
    required this.apiClient,
    required this.authRepository,
    required this.cocktailRepository,
    required this.favoritesRepository,
    required this.notificationRepository,
    required this.deepLinkService,
  });

  final ApiClient apiClient;
  final AuthRepository authRepository;
  final CocktailRepository cocktailRepository;
  final FavoritesRepository favoritesRepository;
  final NotificationRepository notificationRepository;
  final DeepLinkService deepLinkService;

  @override
  State<InsitesApp> createState() => _InsitesAppState();
}

class _InsitesAppState extends State<InsitesApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final AuthBloc _authBloc;
  StreamSubscription<PasswordResetLink>? _resetLinkSubscription;

  // Cold-start race buffer. `DeepLinkService.start()` awaits
  // `getInitialLink()` from `initState`, so the first reset link can be
  // emitted before the MaterialApp's Navigator is mounted. When that
  // happens, [_onResetLink] stores the link here and the post-frame
  // callback drains it after the first build.
  PasswordResetLink? _pendingResetLink;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(authRepository: widget.authRepository)
      ..add(const AuthCheckRequested());

    _resetLinkSubscription =
        widget.deepLinkService.resetLinkStream.listen(_onResetLink);
    widget.deepLinkService.start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = _pendingResetLink;
      if (pending == null || !mounted) return;
      _pendingResetLink = null;
      _routeToResetScreen(pending);
    });
  }

  @override
  void dispose() {
    _resetLinkSubscription?.cancel();
    widget.deepLinkService.dispose();
    _authBloc.close();
    super.dispose();
  }

  /// Listener for reset links from [DeepLinkService.resetLinkStream].
  ///
  /// If the Navigator is mounted, routes immediately. Otherwise buffers
  /// the link in [_pendingResetLink] for the post-frame drain registered
  /// in [initState] — this prevents cold-start links from being dropped
  /// when [DeepLinkService.start] resolves `getInitialLink()` before the
  /// first build phase completes.
  Future<void> _onResetLink(PasswordResetLink link) async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      _pendingResetLink = link;
      return;
    }
    // Clear the buffer first so the post-frame drain does not also navigate
    // to the same screen if it has not yet fired.
    _pendingResetLink = null;
    await _routeToResetScreen(link);
  }

  /// Sign the user out locally if currently authenticated, then navigate
  /// to the reset screen, clearing the stack so Back does not return to
  /// the previous app state.
  Future<void> _routeToResetScreen(PasswordResetLink link) async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    if (_authBloc.state is AuthAuthenticated) {
      await widget.authRepository.secureStorage.clearAll();
      _authBloc.add(const AuthLogoutRequested());
    }

    await navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => ResetPasswordScreen(
          email: link.email,
          token: link.token,
        ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<ApiClient>.value(
      value: widget.apiClient,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: _authBloc),
          BlocProvider(
            create: (_) =>
                CocktailBloc(cocktailRepository: widget.cocktailRepository),
          ),
          BlocProvider(
            create: (_) => FavoritesBloc(
              favoritesRepository: widget.favoritesRepository,
            ),
          ),
          BlocProvider(
            create: (_) => NotificationBloc(
              notificationRepository: widget.notificationRepository,
              cocktailRepository: widget.cocktailRepository,
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Insites',
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
