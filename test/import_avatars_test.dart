import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:one_piece_battles_flutter/ai/import_avatars.dart';
import 'package:one_piece_battles_flutter/ai/import_models.dart';

ImportItem _item(String key, String zh, String? en,
        {String type = ImportType.character, String? existingId}) =>
    ImportItem(
      key: key,
      type: type,
      existingId: existingId,
      data: {
        'name': {'zh_CN': zh, if (en != null) 'en_US': en}
      },
    );

const _img = 'https://lain.bgm.tv/r/400/pic/crt/l';

Map<String, Object> _character(int id, String name, String zh,
        [List<String> aliases = const []]) =>
    {
      'id': id,
      'name': name,
      'images': {'medium': '$_img/$id.jpg', 'large': ''},
      'infobox': [
        {'key': '简体中文名', 'value': zh},
        {
          'key': '别名',
          'value': [
            for (final alias in aliases) {'k': '别名', 'v': alias}
          ]
        },
      ],
    };

final _perona = _character(4291, 'ペローナ', '佩罗娜', ['Perona']);
final _moria =
    _character(4287, 'ゲッコー・モリア', '月光·摩利亚', ['月光·莫利亚', 'Gecko Moria']);
final _shanks = _character(2479, 'シャンクス', '香克斯', ['杰克斯', 'Shanks']);
final _otherPerona = _character(90001, 'ペローナ', '佩罗娜'); // another anime

/// Bangumi: search answers by keyword, subjects by character id.
MockClient _bangumi(Map<String, List<Map>> search,
        {List<String>? keywords, Set<int> inOnePiece = const {4291, 4287}}) =>
    MockClient((request) async {
      if (request.url.path == '/v0/search/characters') {
        final keyword = jsonDecode(request.body)['keyword'] as String;
        keywords?.add(keyword);
        return http.Response(jsonEncode({'data': search[keyword] ?? []}), 200,
            headers: {'content-type': 'application/json; charset=utf-8'});
      }
      final id = int.parse(request.url.pathSegments[2]);
      return http.Response(
          jsonEncode([
            {'id': inOnePiece.contains(id) ? 975 : 123}
          ]),
          200);
    });

Future<Uint8List> _png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(Rect.fromLTWH(0, 0, width + .0, height + .0),
      Paint()..color = const Color(0xFF3366FF));
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void main() {
  test('uses a hit only when it carries a drafted name and is in One Piece',
      () async {
    final keywords = <String>[];
    final avatars = ImportAvatars(
        client: _bangumi(
            {
              '佩罗娜': [_otherPerona, _perona],
              // A wrong Chinese name: Shanks has the alias 杰克斯 but not this name.
              '杰克斯·莫利亚': [_shanks],
              'Gecko Moria': [_moria],
              '杰克斯': [_shanks],
            },
            keywords: keywords,
            inOnePiece: {4291, 4287, 2479}));

    final found = await avatars.find([
      _item('c1', '佩罗娜', 'Perona'),
      _item('c2', '杰克斯·莫利亚', 'Gecko Moria'),
      _item('c3', '杰克斯', null, existingId: 'shanks'), // reused, no avatar
      _item('f1', '幽灵果实', 'Horo Horo no Mi', type: ImportType.fruit),
    ]);

    expect(found, {'c1': '$_img/4291.jpg', 'c2': '$_img/4287.jpg'});
    expect(keywords, unorderedEquals(['佩罗娜', '杰克斯·莫利亚', 'Gecko Moria']));
  });

  test('finds nothing for a name outside One Piece', () async {
    final avatars = ImportAvatars(
        client: _bangumi({
      '佩罗娜': [_otherPerona]
    }));
    expect(await avatars.find([_item('c1', '佩罗娜', null)]), isEmpty);
  });

  test('fails only when Bangumi cannot be reached at all', () async {
    final down = ImportAvatars(
        client: MockClient((_) async => http.Response('busy', 503)));
    await expectLater(
        down.find([_item('c1', '佩罗娜', 'Perona')]), throwsA(isA<StateError>()));
    expect(await down.find([_item('f1', '幽灵果实', null, type: ImportType.fruit)]),
        isEmpty);
  });

  test('crops the head end of a full-body portrait', () {
    expect(ImportAvatars.avatarSource(const Size(400, 795)),
        const Rect.fromLTWH(0, 0, 400, 400));
    expect(ImportAvatars.avatarSource(const Size(500, 300)),
        const Rect.fromLTWH(100, 0, 300, 300));
  });

  testWidgets('prepares a square PNG avatar from the downloaded portrait',
      (tester) async {
    await tester.runAsync(() async {
      final portrait = await _png(100, 220);
      final avatars = ImportAvatars(
          client: MockClient((_) async => http.Response.bytes(portrait, 200)));
      final avatar = await avatars.prepare('$_img/4291.jpg');
      final decoded =
          await (await ui.instantiateImageCodec(avatar)).getNextFrame();
      expect(decoded.image.width, ImportAvatars.size);
      expect(decoded.image.height, ImportAvatars.size);
      expect(avatar.sublist(1, 4), utf8.encode('PNG'));
    });
  });
}
