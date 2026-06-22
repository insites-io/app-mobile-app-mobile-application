import 'dart:io';

import 'package:dio/dio.dart';

import '../api/api_client.dart';

/// 3-step IIA presigned-S3 upload.
///
/// 1. `GET /crm/api/v2/attachments/credentials` returns the policy + signature
///    + the S3 `direct_upload_url`.
/// 2. POST the file plus those fields as `multipart/form-data` to S3.
/// 3. S3 returns XML; pull the public URL out of the `<Location>` element.
///
/// Returns the decoded URL. Throws [ApiException] when the local file is
/// gone (image_picker's tmp file got swept up), when the response is
/// missing the `<Location>` element (S3 reported failure or the response
/// shape changed), or any other recoverable failure. Network failures
/// propagate from the caller's [ApiClient].
Future<String> uploadImageToS3({
  required ApiClient apiClient,
  required String iiaApiKey,
  required String filePath,
}) async {
  // Fail loudly-but-cleanly when image_picker's temp file has been swept
  // away (Android caches, iOS background eviction) before we got to read
  // it. Without this, `MultipartFile.fromFile` throws a raw
  // PathNotFoundException that surfaces a stack-trace-looking toast.
  if (!await File(filePath).exists()) {
    throw ApiException(
      "Selected image isn't available anymore. Please pick it again.",
    );
  }

  final creds = await apiClient.get(
    '/crm/api/v2/attachments/credentials',
    authToken: iiaApiKey,
  );

  final directUploadUrl = creds['direct_upload_url'] as String;
  final key = creds['key'] as String;
  final fileName = filePath.split('/').last;
  // The credentials endpoint returns a key with a `${filename}` template
  // placeholder; substitute the actual filename before sending to S3.
  final resolvedKey = key.replaceAll(r'${filename}', fileName);

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

  final locationMatch = RegExp(r'<Location>(.*?)</Location>').firstMatch(xml);
  if (locationMatch == null) {
    throw ApiException('Failed to parse S3 upload response.');
  }

  return Uri.decodeFull(locationMatch.group(1)!);
}
