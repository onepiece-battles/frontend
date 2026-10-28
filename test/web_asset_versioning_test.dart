import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import '../tool/version_web_assets.dart' as versioning;

void main() {
  test('two deployments never reuse compiled code URLs', () {
    final outputs = <String>[];
    for (final release in ['first', 'second']) {
      final directory = Directory.systemTemp.createTempSync('web-release-');
      addTearDown(() => directory.deleteSync(recursive: true));
      File file(String name) => File('${directory.path}/$name');
      file('main.dart.js')
          .writeAsStringSync('parts:["main.dart.js_1.part.js"]');
      file('main.dart.js_1.part.js').writeAsStringSync('code:$release');
      file('flutter_bootstrap.js')
          .writeAsStringSync('{"mainJsPath":"main.dart.js"}');
      file('index.html')
          .writeAsStringSync('<script src="flutter_bootstrap.js"></script>');
      file('flutter_service_worker.js')
          .writeAsStringSync('const RESOURCES = ${jsonEncode({
            'main.dart.js': release,
            'flutter_bootstrap.js': '$release-bootstrap',
            'main.dart.js_1.part.js': '$release-part',
          })};');
      versioning.main([directory.path]);
      final main = file('main.$release.dart.js');
      expect(main.readAsStringSync(),
          contains('main.dart.js_1.$release-part.part.js'));
      expect(file('main.dart.js_1.$release-part.part.js').existsSync(), isTrue);
      expect(
          file('flutter_bootstrap.$release.$release-bootstrap.js')
              .readAsStringSync(),
          contains('main.$release.dart.js'));
      expect(file('main.dart.js').existsSync(), isFalse);
      outputs.add(file('index.html').readAsStringSync());
    }
    expect(outputs.first, isNot(outputs.last));
  });
}
