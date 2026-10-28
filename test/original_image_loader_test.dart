import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/components/image_cache_manager.dart';
import 'package:one_piece_battles_flutter/components/original_image_loader.dart';
import 'package:one_piece_battles_flutter/repository/image_dao.dart';

class _FakeImageDao extends ImageDao {
  _FakeImageDao(this.completer) : super.empty();
  final Completer<Uint8List> completer;

  @override
  Future<Uint8List> loadImageBytes(String uri, {bool? fullImage}) {
    return completer.future;
  }
}

/// Builds a real, precisely-sized solid-color PNG so the test can assert on
/// an exact, non-square aspect ratio rather than coincidentally-square test
/// data that couldn't distinguish "sized to aspect ratio" from "sized to a
/// fixed box".
Future<Uint8List> _solidColorPng(int width, int height) async {
  final pixels = Uint8List(width * height * 4);
  for (var i = 0; i < pixels.length; i += 4) {
    pixels[i] = 200; // R
    pixels[i + 1] = 60; // G
    pixels[i + 2] = 60; // B
    pixels[i + 3] = 255; // A
  }
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
      pixels, width, height, ui.PixelFormat.rgba8888, completer.complete);
  final image = await completer.future;
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return byteData!.buffer.asUint8List();
}

void main() {
  setUp(ImageCacheManager.clear);

  testWidgets(
      'OriginalImageLoader sizes the loaded image to its own aspect ratio, '
      'not a fixed box', (tester) async {
    // 2:1 landscape image inside a 200x200 max box should end up 200x100 —
    // width-constrained, not stretched/cropped to fill the square bounds.
    final pngBytes = (await tester.runAsync(() => _solidColorPng(200, 100)))!;
    final completer = Completer<Uint8List>();
    GetIt.instance.registerSingleton<ImageDao>(_FakeImageDao(completer));
    addTearDown(() => GetIt.instance.unregister<ImageDao>());

    const key = Key('original_image_loader_under_test');
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OriginalImageLoader(
            key: key,
            uriProvider: _uniqueTestUri,
            maxWidth: 200,
            maxHeight: 200,
          ),
        ),
      ),
    );

    // Still loading (network fetch not resolved) — the small neutral
    // spinner footprint, deliberately not a colored box guessing a size.
    final loadingSize = tester.getSize(find.byKey(key));
    expect(loadingSize, equals(const Size(60, 60)));

    // Browser image codecs complete outside the fake test clock. Resolve the
    // same provider the view uses before measuring its final aspect ratio.
    await tester.runAsync(() => precacheImage(
          NetworkImage('data:image/png;base64,${base64Encode(pngBytes)}'),
          tester.element(find.byKey(key)),
        ));

    completer.complete(pngBytes);
    await tester.pump(); // outer FutureBuilder rebuilds with the bytes
    await tester.pump(); // inner aspect-ratio decode resolves
    await tester.pump(); // image frame settles

    final loadedSize = tester.getSize(find.byKey(key));
    expect(
      loadedSize.width / loadedSize.height,
      closeTo(2.0, 0.01),
      reason: 'the rendered box must match the source image\'s 2:1 aspect '
          'ratio — a fixed box would distort or letterbox it instead',
    );
    expect(loadedSize.width, closeTo(200, 0.5));
    expect(loadedSize.height, closeTo(100, 0.5));
  });
}

String _uniqueTestUri() => 'https://example.com/original-image-loader-test.png';
