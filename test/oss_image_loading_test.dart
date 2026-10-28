import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openapi/api.dart';
import 'package:one_piece_battles_flutter/components/image_cache_manager.dart';
import 'package:one_piece_battles_flutter/config/session_aware_client.dart';
import 'package:one_piece_battles_flutter/repository/image_dao.dart';

const _image = 'https://onepiece-battles.oss-cn-shanghai.aliyuncs.com/image-id';
const _thumb = '$_image?test-thumbnail';
const _original = '$_image?test-original';
final _bytes = Uint8List.fromList([137, 80, 78, 71, 1, 2, 3]);

void main() {
  setUp(ImageCacheManager.clear);
  tearDown(() async => GetIt.I.reset());

  test('shared loaders deduplicate downloads and never send the JWT to OSS',
      () async {
    var signing = 0;
    final downloads = <String>[];
    final api = ApiClient(
        authentication: HttpBearerAuth()..accessToken = 'session-token');
    api.client = MockClient((request) async {
      signing++;
      expect(request.url.path, '/api/onepiece/image/get_image_url');
      expect(request.headers['Authorization'], 'Bearer session-token');
      expect(jsonDecode(request.body)['full_image'], isFalse);
      return http.Response(
          jsonEncode({
            'url': _thumb,
            'original_url': _original,
            'expires_at': DateTime.now()
                .add(const Duration(minutes: 15))
                .millisecondsSinceEpoch,
          }),
          200);
    });
    final dao = ImageDao(api, imageClient: MockClient((request) async {
      expect(request.headers.keys.map((key) => key.toLowerCase()),
          isNot(contains('authorization')));
      downloads.add(request.url.toString());
      return http.Response.bytes(_bytes, 200);
    }));
    GetIt.I.registerSingleton<ImageDao>(dao);
    final copies = await Future.wait(
        List.generate(20, (_) => ImageCacheManager.getImage(_image)));
    expect(copies, everyElement(orderedEquals(_bytes)));
    expect(signing, 1);
    expect(downloads, [_thumb]);
    expect(ImageCacheManager.memoryUsageBytes, _bytes.length);
    await ImageCacheManager.getImage(_image, fullImage: true);
    expect(signing, 1, reason: 'the original reuses its existing signature');
    expect(downloads, [_thumb, _original]);
  });

  test(
      'unsupported thumbnail processing falls back directly to the OSS original',
      () async {
    final downloads = <String>[];
    final dao = _dao(MockClient((request) async {
      downloads.add(request.url.toString());
      return request.url.toString() == _thumb
          ? http.Response('unsupported processing', 400)
          : http.Response.bytes(_bytes, 200);
    }));
    expect(await dao.loadImageBytes(_image), orderedEquals(_bytes));
    expect(downloads, [_thumb, _original]);
  });

  test('an expired OSS signature is refreshed without expiring app login',
      () async {
    var signing = 0;
    var expiry = 0;
    final api = ApiClient();
    api.client = SessionAwareClient(MockClient((request) async {
      signing++;
      return http.Response(
          jsonEncode({
            'url': _original,
            'original_url': _original,
            'expires_at': DateTime.now()
                .add(const Duration(minutes: 15))
                .millisecondsSinceEpoch,
          }),
          200);
    }), () => expiry++);
    var downloads = 0;
    final dao = ImageDao(api,
        imageClient: MockClient((_) async => ++downloads == 1
            ? http.Response('expired signature', 403)
            : http.Response.bytes(_bytes, 200)));
    expect(await dao.loadImageBytes(_image, fullImage: true),
        orderedEquals(_bytes));
    expect(signing, 2);
    expect(downloads, 2);
    expect(expiry, 0);
  });

  test('backend signing authorization failures do not attempt an OSS download',
      () async {
    final api = ApiClient()
      ..client = MockClient((_) async => http.Response('', 401));
    final dao = ImageDao(api, imageClient: MockClient((_) async {
      fail('No image access was granted');
    }));
    await expectLater(dao.loadImageBytes(_image), throwsA(isA<ApiException>()));
  });
}

ImageDao _dao(http.Client images) {
  final api = ApiClient()
    ..client = MockClient((request) async => http.Response(
        jsonEncode({
          'url': _thumb,
          'original_url': _original,
          'expires_at': DateTime.now()
              .add(const Duration(minutes: 15))
              .millisecondsSinceEpoch,
        }),
        200));
  return ImageDao(api, imageClient: images);
}
