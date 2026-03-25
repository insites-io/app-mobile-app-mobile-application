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

  /// GET with optional Authorization header. Returns parsed JSON map.
  Future<Map<String, dynamic>> get(
    String path, {
    String? authToken,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<String>(
        path,
        queryParameters: queryParameters,
        options: Options(
          headers: {
            if (authToken != null) 'Authorization': authToken,
          },
        ),
      );

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

  /// POST with JSON body and Authorization header.
  Future<Map<String, dynamic>> jsonPost(
    String path, {
    Map<String, dynamic>? data,
    String? authToken,
  }) async {
    try {
      final response = await _dio.post<String>(
        path,
        data: jsonEncode(data),
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {
            if (authToken != null) 'Authorization': authToken,
          },
        ),
      );

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

  /// PUT with JSON body and Authorization header.
  Future<Map<String, dynamic>> jsonPut(
    String path, {
    Map<String, dynamic>? data,
    String? authToken,
  }) async {
    try {
      final response = await _dio.put<String>(
        path,
        data: jsonEncode(data),
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {
            if (authToken != null) 'Authorization': authToken,
          },
        ),
      );

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

  /// POST with multipart form data (for file uploads).
  Future<Map<String, dynamic>> multipartPost(
    String path, {
    required FormData formData,
    String? authToken,
  }) async {
    try {
      final response = await _dio.post<String>(
        path,
        data: formData,
        options: Options(
          contentType: Headers.multipartFormDataContentType,
          headers: {
            if (authToken != null) 'Authorization': authToken,
          },
        ),
      );

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

  /// POST multipart form data to an external URL (e.g. S3 presigned upload).
  /// Returns the raw response body as a string (S3 returns XML).
  Future<String> externalMultipartPost(
    String url, {
    required FormData formData,
  }) async {
    try {
      final response = await Dio().post<String>(
        url,
        data: formData,
        options: Options(
          contentType: Headers.multipartFormDataContentType,
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return response.data ?? '';
    } on DioException catch (e) {
      throw ApiException('Upload failed: ${e.message}');
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
