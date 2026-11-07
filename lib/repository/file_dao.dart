import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:openapi/api.dart';

class FileDao {
  final ApiClient _client;
  final http.Client? _fileClient;

  FileDao(ApiClient apiClient, {http.Client? fileClient})
      : _client = apiClient,
        _fileClient = fileClient;

  FileDao.empty() : this(ApiClient());

  /// Resolves a short-lived signed OSS URL for a stored file (e.g. a battle-report
  /// PDF), then downloads the bytes directly from OSS. Only the file id travels
  /// through the authenticated API; the bearer token is never sent to OSS, and the
  /// app server no longer buffers the whole file into memory and base64-encodes it.
  Future<FileDownload> downloadFileBytes(String fileId) async {
    final response = await _client.invokeAPI(
      '/api/onepiece/file/get_file_url',
      'POST',
      <QueryParam>[],
      {'id': fileId},
      <String, String>{},
      <String, String>{},
      'application/json',
    );
    if (response.statusCode != 200) {
      throw ApiException(
          response.statusCode, 'Could not resolve file download URL');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final target = Uri.parse(json['url'] as String);
    if (target.scheme != 'https' || target.host.isEmpty) {
      throw StateError('Expected an HTTPS OSS file URL');
    }
    final download = await (_fileClient?.get(target) ?? http.get(target));
    if (download.statusCode != 200 || download.bodyBytes.isEmpty) {
      throw StateError('OSS file download failed (${download.statusCode})');
    }
    return FileDownload(
      download.bodyBytes,
      json['file_name'] as String?,
      json['mime_type'] as String?,
    );
  }
}

class FileDownload {
  const FileDownload(this.bytes, this.fileName, this.mimeType);
  final Uint8List bytes;
  final String? fileName;
  final String? mimeType;
}
