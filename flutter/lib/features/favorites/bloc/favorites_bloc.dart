import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/favorites_repository.dart';
import 'favorites_event.dart';
import 'favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  FavoritesBloc({required this.favoritesRepository})
      : super(const FavoritesInitial()) {
    on<FavoritesLoadRequested>(_onLoadRequested);
    on<FavoritesToggleRequested>(_onToggleRequested);
  }

  final FavoritesRepository favoritesRepository;

  Future<void> _onLoadRequested(
    FavoritesLoadRequested event,
    Emitter<FavoritesState> emit,
  ) async {
    final favorites = await favoritesRepository.getFavorites(event.userId);
    emit(FavoritesLoaded(favorites));
  }

  Future<void> _onToggleRequested(
    FavoritesToggleRequested event,
    Emitter<FavoritesState> emit,
  ) async {
    final updated = await favoritesRepository.toggleFavorite(
      event.userId,
      event.cocktail,
    );
    emit(FavoritesLoaded(updated));
  }
}
