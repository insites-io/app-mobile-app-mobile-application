import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../recipes/cocktails/data/models/cocktail_model.dart';

class FavoritesRepository {
  FavoritesRepository();

  final _storage = const FlutterSecureStorage();

  String _key(String userId) => 'favorites_$userId';

  Future<List<Cocktail>> getFavorites(String userId) async {
    final raw = await _storage.read(key: _key(userId));
    if (raw == null || raw.isEmpty) return [];

    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Cocktail.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveFavorites(String userId, List<Cocktail> favorites) async {
    final json = jsonEncode(favorites.map((c) => c.toStorageJson()).toList());
    await _storage.write(key: _key(userId), value: json);
  }

  Future<bool> isFavorite(String userId, int cocktailId) async {
    final favorites = await getFavorites(userId);
    return favorites.any((c) => c.id == cocktailId);
  }

  Future<List<Cocktail>> toggleFavorite(
      String userId, Cocktail cocktail) async {
    final favorites = await getFavorites(userId);
    final index = favorites.indexWhere((c) => c.id == cocktail.id);

    if (index >= 0) {
      favorites.removeAt(index);
    } else {
      favorites.add(cocktail);
    }

    await saveFavorites(userId, favorites);
    return favorites;
  }
}
