import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized API configuration.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl =
      'https://insites-application-mobile-app-v100.staging.oregon.platform-os.com';

  /// S3 base URL for uploaded files.
  static const String uploadsBaseUrl =
      'https://uploads.staging.oregon.platform-os.com';

  /// Instance ID used in the S3 key prefix.
  static const String instanceId = '13395';

  /// IIA database table ID for cocktail recipes.
  static const String cocktailsTableId = '2179223';

  /// Instance API key loaded from .env at startup.
  static String get iiaApiKey => dotenv.env['IIA_API_KEY'] ?? '';

  /// Terms & Conditions page URL.
  static const String termsUrl = '$baseUrl/terms-and-conditions';

  /// Privacy Policy page URL.
  static const String privacyPolicyUrl = '$baseUrl/privacy-policy';

  /// Builds the full public URL for an uploaded file path.
  static String imageUrl(String path) =>
      '$uploadsBaseUrl/instances/$instanceId/property_uploads/$path';
}
