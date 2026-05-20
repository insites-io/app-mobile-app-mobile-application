import 'package:equatable/equatable.dart';

import '../data/models/cocktail_model.dart';

abstract class CocktailState extends Equatable {
  const CocktailState();

  @override
  List<Object?> get props => [];
}

class CocktailInitial extends CocktailState {
  const CocktailInitial();
}

class CocktailLoading extends CocktailState {
  const CocktailLoading();
}

class CocktailsLoaded extends CocktailState {
  const CocktailsLoaded({
    required this.cocktails,
    required this.currentPage,
    required this.totalPages,
    this.isLoadingMore = false,
  });

  final List<Cocktail> cocktails;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;

  bool get hasReachedMax => currentPage >= totalPages;

  CocktailsLoaded copyWith({
    List<Cocktail>? cocktails,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
  }) {
    return CocktailsLoaded(
      cocktails: cocktails ?? this.cocktails,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [cocktails, currentPage, totalPages, isLoadingMore];
}

class CocktailAddInProgress extends CocktailState {
  const CocktailAddInProgress();
}

class CocktailAddSuccess extends CocktailState {
  const CocktailAddSuccess();
}

class CocktailUpdateSuccess extends CocktailState {
  const CocktailUpdateSuccess(this.cocktail);

  final Cocktail cocktail;

  @override
  List<Object?> get props => [cocktail.id];
}

class CocktailError extends CocktailState {
  const CocktailError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
