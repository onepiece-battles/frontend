import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:http/http.dart' as http;

import 'import_models.dart';

/// Avatars for the drafted characters, found on Bangumi (bgm.tv), an anime
/// database that mainland China can reach. Fruits and groups have no such
/// source and keep a hand-uploaded avatar.
///
/// A search hit is used only when Bangumi lists one of the draft's names (its
/// Simplified Chinese name or an alias such as the English one) and the
/// character appears in One Piece, so a loose match never becomes an avatar.
/// The browser looks portraits up and downloads them (Bangumi allows CORS);
/// after the import each kept portrait is cropped to a square from the top,
/// scaled to [size] and uploaded like a hand-picked avatar.
class ImportAvatars {
  ImportAvatars({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const size = 256;

  /// Bangumi's One Piece entries: the anime and the manga.
  static const onePiece = {975, 3510};

  static const _host = 'api.bgm.tv';
  static const _parallel = 3;
  static const _timeout = Duration(seconds: 15);

  /// Portrait URLs for the new characters among [items], by item key. Throws
  /// only when Bangumi could not be reached for any of them.
  Future<Map<String, String>> find(List<ImportItem> items) async {
    final characters = items
        .where((i) => !i.exists && i.type == ImportType.character)
        .toList();
    final found = <String, String>{};
    var failed = 0;
    for (var i = 0; i < characters.length; i += _parallel) {
      await Future.wait(characters.skip(i).take(_parallel).map((item) async {
        try {
          final url = await _portrait(item);
          if (url != null) found[item.key] = url;
        } catch (_) {
          failed++;
        }
      }));
    }
    if (characters.isNotEmpty && failed == characters.length) {
      throw StateError('Bangumi could not be reached');
    }
    return found;
  }

  Future<String?> _portrait(ImportItem item) async {
    final name = item.data['name'];
    final drafted = [
      for (final language in const ['zh_CN', 'en_US'])
        if (name is Map && '${name[language] ?? ''}'.trim().isNotEmpty)
          '${name[language]}'.trim(),
    ];
    final wanted = drafted.map(_normalize).toSet();
    for (final keyword in drafted) {
      for (final candidate in await _search(keyword)) {
        if (!_names(candidate).any(wanted.contains)) continue;
        final image = _image(candidate);
        if (image != null && await _inOnePiece(candidate['id'])) return image;
      }
    }
    return null;
  }

  Future<List<Map>> _search(String keyword) async {
    final response = await _client
        .post(Uri.https(_host, '/v0/search/characters', {'limit': '5'}),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'keyword': keyword}))
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw StateError('Bangumi search failed (${response.statusCode})');
    }
    final data = (jsonDecode(utf8.decode(response.bodyBytes)) as Map)['data'];
    return [...((data as List?) ?? const []).whereType<Map>()];
  }

  Future<bool> _inOnePiece(Object? id) async {
    final response = await _client
        .get(Uri.https(_host, '/v0/characters/$id/subjects'))
        .timeout(_timeout);
    if (response.statusCode != 200) return false;
    final subjects = jsonDecode(utf8.decode(response.bodyBytes));
    return subjects is List &&
        subjects.any((s) => s is Map && onePiece.contains(s['id']));
  }

  /// The original name, the Simplified Chinese name and every alias.
  static Set<String> _names(Map candidate) {
    final names = <String>{'${candidate['name'] ?? ''}'};
    for (final field in (candidate['infobox'] as List?) ?? const []) {
      if (field is! Map) continue;
      final value = field['value'];
      if (field['key'] == '简体中文名' && value is String) names.add(value);
      if (field['key'] == '别名' && value is List) {
        for (final alias in value) {
          if (alias is Map && alias['v'] is String) names.add(alias['v']);
        }
      }
    }
    return names.map(_normalize).where((n) => n.isNotEmpty).toSet();
  }

  static String _normalize(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[\s·・･.．\-_]'), '');

  static String? _image(Map candidate) {
    final images = candidate['images'];
    if (images is! Map) return null;
    for (final variant in const ['medium', 'large']) {
      final url = images[variant];
      if (url is String && url.startsWith('https://')) return url;
    }
    return null;
  }

  /// Downloads a portrait and returns a [size] × [size] PNG avatar.
  Future<Uint8List> prepare(String url) async {
    final response = await _client.get(Uri.parse(url)).timeout(_timeout);
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw StateError('Image download failed (${response.statusCode})');
    }
    final codec = await ui.instantiateImageCodec(response.bodyBytes);
    final image = (await codec.getNextFrame()).image;
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
        image,
        avatarSource(Size(image.width.toDouble(), image.height.toDouble())),
        const Rect.fromLTWH(0, 0, size + .0, size + .0),
        Paint()..filterQuality = FilterQuality.high);
    final avatar = await recorder.endRecording().toImage(size, size);
    final png = await avatar.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    avatar.dispose();
    if (png == null) throw StateError('Could not encode the avatar');
    return png.buffer.asUint8List();
  }

  /// The square of a portrait that becomes the avatar: as wide as possible,
  /// from the top so the head stays in (Bangumi portraits are full-body).
  static Rect avatarSource(Size image) {
    final side = image.shortestSide;
    return Alignment.topCenter.inscribe(Size(side, side), Offset.zero & image);
  }
}
