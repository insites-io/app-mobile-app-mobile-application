import 'package:dio/dio.dart';

import '../../../../../config/api_config.dart';
import '../../../../../core/api/api_client.dart';
import '../models/cocktail_model.dart';

/// Handles cocktail CRUD operations against the IIA database API.
///
/// Uses the Instance API Key (from .env) for authentication,
/// as required by the IIA database endpoints.
///
/// Image uploads follow the IIA 3-step presigned S3 flow:
/// 1. GET credentials → 2. POST file to S3 → 3. Pass S3 URL to item.
class CocktailRepository {
  const CocktailRepository({
    required this.apiClient,
  });

  final ApiClient apiClient;

  static const _itemsPath =
      '/databases/api/v2/database/${ApiConfig.cocktailsTableId}/items';

  static const _credentialsPath = '/crm/api/v2/attachments/credentials';

  /// Fetch all cocktails from the database.
  Future<List<Cocktail>> getCocktails() async {
    final response = await apiClient.get(
      _itemsPath,
      authToken: ApiConfig.iiaApiKey,
    );

    final results = response['results'] as List<dynamic>? ?? [];
    return results
        .map((item) => Cocktail.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Create a new cocktail. Optionally uploads an image via S3.
  Future<Cocktail> addCocktail(
    Cocktail cocktail, {
    String? imagePath,
  }) async {
    final data = cocktail.toCreateJson();

    if (imagePath != null) {
      final imageUrl = await _uploadImage(imagePath);
      data['properties.image'] = imageUrl;
    }

    final response = await apiClient.jsonPost(
      _itemsPath,
      data: data,
      authToken: ApiConfig.iiaApiKey,
    );
    return Cocktail.fromJson(response);
  }

  /// 3-step IIA presigned S3 upload.
  ///
  /// 1. Fetch presigned credentials from IIA.
  /// 2. POST the file + credentials to S3.
  /// 3. Extract and return the uploaded file URL.
  Future<String> _uploadImage(String filePath) async {
    // Step 1: Get presigned credentials.
    final creds = await apiClient.get(
      _credentialsPath,
      authToken: ApiConfig.iiaApiKey,
    );

    final directUploadUrl = creds['direct_upload_url'] as String;
    final key = creds['key'] as String;

    // Replace ${filename} placeholder with actual filename.
    final fileName = filePath.split('/').last;
    final resolvedKey = key.replaceAll(r'${filename}', fileName);

    // Step 2: Upload file to S3.
    final formData = FormData.fromMap({
      'key': resolvedKey,
      'policy': creds['policy'],
      'x-amz-credential': creds['x-amz-credential'],
      'x-amz-algorithm': creds['x-amz-algorithm'],
      'x-amz-date': creds['x-amz-date'],
      'x-amz-signature': creds['x-amz-signature'],
      'success_action_status': creds['success_action_status'],
      'acl': creds['acl'],
      'Content-Disposition': creds['Content-Disposition'],
      'x-amz-meta-versions': creds['x-amz-meta-versions'],
      'x-amz-meta-acl': creds['x-amz-meta-acl'],
      'x-amz-meta-content-disposition': creds['x-amz-meta-content-disposition'],
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final xml = await apiClient.externalMultipartPost(
      directUploadUrl,
      formData: formData,
    );

    // Step 3: Extract the S3 URL from the XML response.
    final locationMatch = RegExp(r'<Location>(.*?)</Location>').firstMatch(xml);
    if (locationMatch == null) {
      throw ApiException('Failed to parse S3 upload response.');
    }

    return Uri.decodeFull(locationMatch.group(1)!);
  }
}
