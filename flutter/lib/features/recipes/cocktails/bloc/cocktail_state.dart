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
  const CocktailsLoaded(this.cocktails);

  final List<Cocktail> cocktails;

  @override
  List<Object?> get props => [cocktails];
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
