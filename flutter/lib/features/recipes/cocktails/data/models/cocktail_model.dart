import '../../../../../config/api_config.dart';

/// Represents a cocktail recipe from the IIA database.
class Cocktail {
  const Cocktail({
    this.id,
    required this.name,
    this.keywords,
    this.image,
    this.instructions,
    this.ingredients,
    this.duration,
    this.amount,
    this.rating,
  });

  final int? id;
  final String name;
  final String? keywords;
  final String? image;
  final String? instructions;
  final String? ingredients;
  final int? duration;
  final int? amount;
  final double? rating;

  /// Parses a cocktail from the IIA database item response.
  ///
  /// Expects `{ "id": ..., "properties": { "name": ..., ... } }`.
  factory Cocktail.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'] as Map<String, dynamic>? ?? json;
    return Cocktail(
      id: _parseInt(json['id']),
      name: (properties['name'] as String?) ?? '',
      keywords: properties['keywords'] as String?,
      image: _parseImage(properties['image']),
      instructions: properties['instructions'] as String?,
      ingredients: properties['ingredients'] as String?,
      duration: _parseInt(properties['duration']),
      amount: _parseInt(properties['amount']),
      rating: _parseDouble(properties['rating']),
    );
  }

  /// Builds the dot-notation body for the IIA create-item endpoint.
  Map<String, dynamic> toCreateJson() {
    final map = <String, dynamic>{
      'properties.name': name,
    };
    if (keywords != null && keywords!.isNotEmpty) {
      map['properties.keywords'] = keywords;
    }
    if (instructions != null && instructions!.isNotEmpty) {
      map['properties.instructions'] = instructions;
    }
    if (ingredients != null && ingredients!.isNotEmpty) {
      map['properties.ingredients'] = ingredients;
    }
    if (duration != null) {
      map['properties.duration'] = duration;
    }
    if (amount != null) {
      map['properties.amount'] = amount;
    }
    if (rating != null) {
      map['properties.rating'] = rating;
    }
    return map;
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// The API returns image as an object `{"path": "...", ...}`, `{}`, or null.
  /// Constructs the full S3 URL from the path when present.
  static String? _parseImage(dynamic value) {
    if (value is String && value.isNotEmpty) return value;
    if (value is Map<String, dynamic>) {
      final path = value['path'] as String?;
      if (path != null && path.isNotEmpty) {
        return ApiConfig.imageUrl(path);
      }
    }
    return null;
  }
}
