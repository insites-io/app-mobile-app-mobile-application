import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/app_theme.dart';
import 'core/api/api_client.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/authentication/bloc/auth_bloc.dart';
import 'features/authentication/bloc/auth_event.dart';
import 'features/authentication/data/repositories/auth_repository.dart';
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

  runApp(InsitesApp(
    apiClient: apiClient,
    authRepository: authRepository,
    cocktailRepository: cocktailRepository,
    favoritesRepository: favoritesRepository,
    notificationRepository: notificationRepository,
  ));
}

class InsitesApp extends StatelessWidget {
  const InsitesApp({
    super.key,
    required this.apiClient,
    required this.authRepository,
    required this.cocktailRepository,
    required this.favoritesRepository,
    required this.notificationRepository,
  });

  final ApiClient apiClient;
  final AuthRepository authRepository;
  final CocktailRepository cocktailRepository;
  final FavoritesRepository favoritesRepository;
  final NotificationRepository notificationRepository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<ApiClient>.value(
      value: apiClient,
      child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(authRepository: authRepository)
            ..add(const AuthCheckRequested()),
        ),
        BlocProvider(
          create: (_) => CocktailBloc(cocktailRepository: cocktailRepository),
        ),
        BlocProvider(
          create: (_) =>
              FavoritesBloc(favoritesRepository: favoritesRepository),
        ),
        BlocProvider(
          create: (_) => NotificationBloc(
              notificationRepository: notificationRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Insites',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
      ),
      ),
    );
  }
}
