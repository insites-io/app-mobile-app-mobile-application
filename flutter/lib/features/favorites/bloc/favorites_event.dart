import 'package:equatable/equatable.dart';

import '../../recipes/cocktails/data/models/cocktail_model.dart';

sealed class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

final class FavoritesLoadRequested extends FavoritesEvent {
  const FavoritesLoadRequested(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

final class FavoritesToggleRequested extends FavoritesEvent {
  const FavoritesToggleRequested({required this.userId, required this.cocktail});

  final String userId;
  final Cocktail cocktail;

  @override
  List<Object?> get props => [userId, cocktail.id];
}
