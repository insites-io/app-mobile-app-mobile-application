import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_client.dart';
import '../data/models/cocktail_model.dart';
import '../data/repositories/cocktail_repository.dart';
import 'cocktail_event.dart';
import 'cocktail_state.dart';

class CocktailBloc extends Bloc<CocktailEvent, CocktailState> {
  CocktailBloc({required this.cocktailRepository})
      : super(const CocktailInitial()) {
    on<CocktailsLoadRequested>(_onLoadRequested);
    on<CocktailAddRequested>(_onAddRequested);
    on<CocktailUpdateRequested>(_onUpdateRequested);
  }

  final CocktailRepository cocktailRepository;

  Future<void> _onLoadRequested(
    CocktailsLoadRequested event,
    Emitter<CocktailState> emit,
  ) async {
    emit(const CocktailLoading());
    try {
      final cocktails = await cocktailRepository.getCocktails();
      emit(CocktailsLoaded(cocktails));
    } on ApiException catch (e) {
      emit(CocktailError(e.message));
    } catch (e) {
      emit(CocktailError('Failed to load cocktails: $e'));
    }
  }

  Future<void> _onAddRequested(
    CocktailAddRequested event,
    Emitter<CocktailState> emit,
  ) async {
    emit(const CocktailAddInProgress());
    try {
      final cocktail = Cocktail(
        name: event.name,
        keywords: event.keywords,
        instructions: event.instructions,
        ingredients: event.ingredients,
        duration: event.duration,
        amount: event.amount,
      );
      await cocktailRepository.addCocktail(
        cocktail,
        imagePath: event.imagePath,
      );
      emit(const CocktailAddSuccess());
    } on ApiException catch (e) {
      emit(CocktailError(e.message));
    } catch (e) {
      emit(CocktailError('Failed to add cocktail: $e'));
    }
  }

  Future<void> _onUpdateRequested(
    CocktailUpdateRequested event,
    Emitter<CocktailState> emit,
  ) async {
    emit(const CocktailAddInProgress());
    try {
      final cocktail = Cocktail(
        id: event.id,
        name: event.name,
        keywords: event.keywords,
        instructions: event.instructions,
        ingredients: event.ingredients,
        duration: event.duration,
        amount: event.amount,
      );
      final updated = await cocktailRepository.updateCocktail(
        cocktail,
        imagePath: event.imagePath,
      );
      emit(CocktailUpdateSuccess(updated));
    } on ApiException catch (e) {
      emit(CocktailError(e.message));
    } catch (e) {
      emit(CocktailError('Failed to update cocktail: $e'));
    }
  }
}
