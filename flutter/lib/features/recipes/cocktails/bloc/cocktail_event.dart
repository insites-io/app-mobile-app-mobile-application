import 'package:equatable/equatable.dart';

abstract class CocktailEvent extends Equatable {
  const CocktailEvent();

  @override
  List<Object?> get props => [];
}

/// Load the first page of cocktails from the database.
class CocktailsLoadRequested extends CocktailEvent {
  const CocktailsLoadRequested();
}

/// Append the next page of cocktails to the currently loaded list.
class CocktailsLoadMoreRequested extends CocktailEvent {
  const CocktailsLoadMoreRequested();
}

/// Submit a new cocktail to the database.
class CocktailAddRequested extends CocktailEvent {
  const CocktailAddRequested({
    required this.name,
    this.keywords,
    this.instructions,
    this.ingredients,
    this.duration,
    this.amount,
    this.imagePath,
  });

  final String name;
  final String? keywords;
  final String? instructions;
  final String? ingredients;
  final int? duration;
  final int? amount;
  final String? imagePath;

  @override
  List<Object?> get props => [
        name,
        keywords,
        instructions,
        ingredients,
        duration,
        amount,
        imagePath,
      ];
}

/// Update an existing cocktail in the database.
class CocktailUpdateRequested extends CocktailEvent {
  const CocktailUpdateRequested({
    required this.id,
    required this.name,
    this.keywords,
    this.instructions,
    this.ingredients,
    this.duration,
    this.amount,
    this.imagePath,
  });

  final int id;
  final String name;
  final String? keywords;
  final String? instructions;
  final String? ingredients;
  final int? duration;
  final int? amount;
  final String? imagePath;

  @override
  List<Object?> get props => [
        id,
        name,
        keywords,
        instructions,
        ingredients,
        duration,
        amount,
        imagePath,
      ];
}
