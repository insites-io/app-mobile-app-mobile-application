import '../../../../../config/api_config.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/services/image_upload_service.dart';
import '../models/cocktail_model.dart';

/// One page of cocktails plus the pagination metadata from the IIA list
/// endpoint. Used by the bloc to track infinite-scroll progress.
class CocktailPage {
  const CocktailPage({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalEntries,
  });

  final List<Cocktail> items;
  final int currentPage;
  final int totalPages;
  final int totalEntries;
}

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

  /// Fetch a single page of cocktails, sorted newest-first by id.
  ///
  /// The IIA list endpoint paginates (default size 6). Use `sort_by=id` with
  /// `sort_order=desc` so the most-recently-created cocktails appear first.
  Future<CocktailPage> getCocktailsPage({int page = 1, int size = 10}) async {
    final response = await apiClient.get(
      _itemsPath,
      authToken: ApiConfig.iiaApiKey,
      queryParameters: {
        'page': page,
        'size': size,
        'sort_by': 'id',
        'sort_order': 'desc',
      },
    );

    final results = response['results'] as List<dynamic>? ?? [];
    final items = results
        .map((item) => Cocktail.fromJson(item as Map<String, dynamic>))
        .toList();
    final totalPages = (response['total_pages'] as num?)?.toInt() ?? 1;
    final totalEntries = (response['total_entries'] as num?)?.toInt() ?? items.length;
    return CocktailPage(
      items: items,
      currentPage: page,
      totalPages: totalPages,
      totalEntries: totalEntries,
    );
  }

  /// Fetch every cocktail id across all pages.
  ///
  /// Used by the notification diff: the notifications tab needs to see all
  /// cocktails, not just the page currently visible in the list UI.
  Future<List<int>> getAllCocktailIds() async {
    final ids = <int>[];
    var page = 1;
    while (true) {
      final result = await getCocktailsPage(page: page, size: 100);
      ids.addAll(result.items.where((c) => c.id != null).map((c) => c.id!));
      if (page >= result.totalPages) break;
      page++;
    }
    return ids;
  }

  /// Create a new cocktail. Optionally uploads an image via S3.
  ///
  /// [imagePath] accepts either a local filesystem path (uploaded here)
  /// or an already-public `http(s)://…` URL (passed through). The URL
  /// pass-through path is what the cocktail-add screen uses today — it
  /// uploads at pick time so save never depends on a temp file the OS
  /// may have evicted.
  Future<Cocktail> addCocktail(
    Cocktail cocktail, {
    String? imagePath,
  }) async {
    final data = cocktail.toCreateJson();

    if (imagePath != null) {
      data['properties.image'] = await _resolveImageUrl(imagePath);
    }

    final response = await apiClient.jsonPost(
      _itemsPath,
      data: data,
      authToken: ApiConfig.iiaApiKey,
    );
    return Cocktail.fromJson(response);
  }

  /// Update an existing cocktail. Optionally uploads a new image via S3.
  /// See [addCocktail] for the [imagePath] dual-use semantics.
  Future<Cocktail> updateCocktail(
    Cocktail cocktail, {
    String? imagePath,
  }) async {
    final data = cocktail.toCreateJson();

    if (imagePath != null) {
      data['properties.image'] = await _resolveImageUrl(imagePath);
    }

    final response = await apiClient.jsonPut(
      '$_itemsPath/${cocktail.id}',
      data: data,
      authToken: ApiConfig.iiaApiKey,
    );
    return Cocktail.fromJson(response);
  }

  /// Treat an already-public URL as authoritative; otherwise upload the
  /// local file and return the S3 URL.
  Future<String> _resolveImageUrl(String pathOrUrl) async {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    return uploadImageToS3(
      apiClient: apiClient,
      iiaApiKey: ApiConfig.iiaApiKey,
      filePath: pathOrUrl,
    );
  }
}
