import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:openapi/api.dart';

class ImageDao {
  ImageApi imageApi = ImageApi();
  final ApiClient _client;
  final http.Client? _imageClient;
  final _accessCache = <String, OssImageAccess>{};

  ImageDao(ApiClient apiClient, {http.Client? imageClient})
      : _client = apiClient,
        _imageClient = imageClient {
    imageApi = ImageApi(apiClient);
  }

  ImageDao.empty() : this(ApiClient());

  /// Only metadata travels through the authenticated API. Image downloads use
  /// a separate client so the app's bearer token is never sent to OSS.
  Future<OssImageAccess> getImageAccess(String uri, {bool? fullImage}) async {
    final key = '${fullImage == true}:$uri';
    final cached = _accessCache.remove(key);
    if (cached != null &&
        cached.expiresAt
            .isAfter(DateTime.now().add(const Duration(seconds: 30)))) {
      _accessCache[key] = cached;
      return cached;
    }
    final response = await _client.invokeAPI(
      '/api/onepiece/image/get_image_url',
      'POST',
      <QueryParam>[],
      {'uri': uri, 'full_image': fullImage == true},
      <String, String>{},
      <String, String>{},
      'application/json',
    );
    if (response.statusCode != 200) {
      throw ApiException(
          response.statusCode, 'Could not resolve OSS image access');
    }
    final access = OssImageAccess.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
    while (_accessCache.length + (fullImage == true ? 1 : 2) > 200) {
      _accessCache.remove(_accessCache.keys.first);
    }
    _accessCache[key] = access;
    // A thumbnail response also grants access to the original. Reuse that
    // signature when opening an image at full resolution.
    if (fullImage != true) {
      _accessCache['true:$uri'] = OssImageAccess(
          access.originalUrl, access.originalUrl, access.expiresAt);
    }
    return access;
  }

  Future<Uint8List> loadImageBytes(String uri, {bool? fullImage}) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final access = await getImageAccess(uri, fullImage: fullImage);
      var response = await _download(access.url);
      if (response.statusCode != 200 && access.url != access.originalUrl) {
        response = await _download(access.originalUrl);
      }
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
      if (response.statusCode == 403 && attempt == 0) {
        _accessCache.remove('true:$uri');
        _accessCache.remove('false:$uri');
        continue; // Refresh an expired signature once, without expiring login.
      }
      throw StateError('OSS image download failed (${response.statusCode})');
    }
    throw StateError('OSS image access expired');
  }

  Future<http.Response> _download(String url) async {
    final target = Uri.parse(url);
    if (target.scheme != 'https' || target.host.isEmpty) {
      throw StateError('Expected an HTTPS OSS image URL');
    }
    try {
      return await (_imageClient?.get(target) ?? http.get(target));
    } on http.ClientException {
      // Do not leak signed URLs into error logs.
      throw StateError('Cannot read OSS image; check CORS and connectivity');
    }
  }

  Future<UploadImageResponse?> addImage(UploadImageRequest uploadImageRequest) {
    return imageApi.uploadImage(uploadImageRequest);
  }

  Future<GetImageResponse?> getImage(GetImageRequest getImageRequest) {
    return imageApi.getImage(getImageRequest: getImageRequest);
  }
}

class OssImageAccess {
  const OssImageAccess(this.url, this.originalUrl, this.expiresAt);
  final String url;
  final String originalUrl;
  final DateTime expiresAt;

  factory OssImageAccess.fromJson(Map<String, dynamic> json) => OssImageAccess(
        json['url'] as String,
        json['original_url'] as String,
        DateTime.fromMillisecondsSinceEpoch(
            (json['expires_at'] as num).toInt()),
      );
}
