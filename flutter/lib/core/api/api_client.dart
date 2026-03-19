import 'dart:convert';

import 'package:dio/dio.dart';

import '../../config/api_config.dart';

/// HTTP client for communicating with the IIA backend.
///
/// All responses from the IIA backend return HTTP 200 — callers must
/// inspect the `"success"` field in the parsed JSON to detect errors.
class ApiClient {
  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.plain,
        followRedirects: true,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  late final Dio _dio;

  /// POST with form-urlencoded body. Always returns parsed JSON map.
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post<String>(path, data: data);

      if (response.statusCode == 404) {
        throw ApiException(
          'Endpoint not found: ${response.realUri} (HTTP 404).',
        );
      }

      return _parseJson(response.data!);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException('Network error: ${e.message}');
    }
  }

  Map<String, dynamic> _parseJson(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) return data;
      throw ApiException('Unexpected response format.');
    } on FormatException {
      throw ApiException('Invalid response from server.');
    }
  }
}

/// Thrown for network failures or unparseable responses.
class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
