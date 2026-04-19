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

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(authRepository: widget.authRepository)
      ..add(const AuthCheckRequested());

    _resetLinkSubscription =
        widget.deepLinkService.resetLinkStream.listen(_onResetLink);
    widget.deepLinkService.start();
  }

  @override
  void dispose() {
    _resetLinkSubscription?.cancel();
    widget.deepLinkService.dispose();
    _authBloc.close();
    super.dispose();
  }

  /// When a password reset deep link arrives:
  /// 1. If the user is currently signed in, sign them out locally so they
  ///    land on the reset flow and not a mixed-session state.
  /// 2. Navigate to the reset screen, clearing the stack so Back does not
  ///    return to the logged-in app.
  Future<void> _onResetLink(PasswordResetLink link) async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    if (_authBloc.state is AuthAuthenticated) {
      // Fire-and-forget: clear local credentials immediately so the
      // auth UI does not briefly show the Home screen behind the reset
      // screen if the user taps Back.
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
