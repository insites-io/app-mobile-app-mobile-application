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
    on<CocktailsLoadMoreRequested>(_onLoadMoreRequested);
    on<CocktailAddRequested>(_onAddRequested);
    on<CocktailUpdateRequested>(_onUpdateRequested);
  }

  final CocktailRepository cocktailRepository;

  static const int _pageSize = 10;

  Future<void> _onLoadRequested(
    CocktailsLoadRequested event,
    Emitter<CocktailState> emit,
  ) async {
    emit(const CocktailLoading());
    try {
      final page = await cocktailRepository.getCocktailsPage(
        page: 1,
        size: _pageSize,
      );
      emit(CocktailsLoaded(
        cocktails: page.items,
        currentPage: page.currentPage,
        totalPages: page.totalPages,
      ));
    } on ApiException catch (e) {
      emit(CocktailError(e.message));
    } catch (e) {
      emit(CocktailError('Failed to load cocktails: $e'));
    }
  }

  Future<void> _onLoadMoreRequested(
    CocktailsLoadMoreRequested event,
    Emitter<CocktailState> emit,
  ) async {
    final current = state;
    if (current is! CocktailsLoaded) return;
    if (current.hasReachedMax || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.currentPage + 1;
      final page = await cocktailRepository.getCocktailsPage(
        page: nextPage,
        size: _pageSize,
      );
      emit(CocktailsLoaded(
        cocktails: [...current.cocktails, ...page.items],
        currentPage: page.currentPage,
        totalPages: page.totalPages,
      ));
    } on ApiException catch (e) {
      emit(current.copyWith(isLoadingMore: false));
      emit(CocktailError(e.message));
    } catch (e) {
      emit(current.copyWith(isLoadingMore: false));
      emit(CocktailError('Failed to load more cocktails: $e'));
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
      // Reset to page 1 so the new (newest-first) cocktail appears at the top.
      final page = await cocktailRepository.getCocktailsPage(
        page: 1,
        size: _pageSize,
      );
      emit(CocktailsLoaded(
        cocktails: page.items,
        currentPage: page.currentPage,
        totalPages: page.totalPages,
      ));
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
      // Reset to page 1 so any reordering/edits are reflected.
      final page = await cocktailRepository.getCocktailsPage(
        page: 1,
        size: _pageSize,
      );
      emit(CocktailsLoaded(
        cocktails: page.items,
        currentPage: page.currentPage,
        totalPages: page.totalPages,
      ));
    } on ApiException catch (e) {
      emit(CocktailError(e.message));
    } catch (e) {
      emit(CocktailError('Failed to update cocktail: $e'));
    }
  }
}
