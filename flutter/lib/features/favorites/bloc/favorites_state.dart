import 'package:equatable/equatable.dart';

import '../../recipes/cocktails/data/models/cocktail_model.dart';

sealed class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object?> get props => [];

  bool isFavorite(int? cocktailId) => false;
}

final class FavoritesInitial extends FavoritesState {
  const FavoritesInitial();
}

final class FavoritesLoaded extends FavoritesState {
  const FavoritesLoaded(this.favorites);

  final List<Cocktail> favorites;

  @override
  List<Object?> get props => [favorites.map((c) => c.id).toList()];

  @override
  bool isFavorite(int? cocktailId) =>
      cocktailId != null && favorites.any((c) => c.id == cocktailId);
}
