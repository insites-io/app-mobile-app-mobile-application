import 'package:equatable/equatable.dart';

abstract class CocktailEvent extends Equatable {
  const CocktailEvent();

  @override
  List<Object?> get props => [];
}

/// Load all cocktails from the database.
class CocktailsLoadRequested extends CocktailEvent {
  const CocktailsLoadRequested();
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
