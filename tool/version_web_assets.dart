import 'dart:convert';
import 'dart:io';

/// Give compiled code content-versioned URLs so browsers cannot combine
/// deferred libraries from two Docker deployments. Uses Flutter's generated
/// content hashes; no extra build dependencies are needed.
///
/// `flutter build web --wasm` emits both a dart2wasm entrypoint
/// (main.dart.wasm + its JS support runtime main.dart.mjs) and a dart2js
/// fallback (main.dart.js + deferred main.dart.js_*.part.js parts). All of
/// them are renamed to content-hashed names and the bootstrap's build config
/// is pointed at the new names.
void main(List<String> arguments) {
  final directory =
      Directory(arguments.isEmpty ? 'build/web' : arguments.single);
  File file(String name) => File('${directory.path}/$name');
  final worker = file('flutter_service_worker.js');
  final manifest = RegExp(r'const RESOURCES = (\{.*?\});', dotAll: true)
      .firstMatch(worker.readAsStringSync());
  if (manifest == null) {
    throw StateError('Expected the content hashes from flutter build web.');
  }
  final resources = jsonDecode(manifest.group(1)!) as Map<String, dynamic>;

  final jsVersion = resources['main.dart.js'] as String;
  final jsName = 'main.$jsVersion.dart.js';
  final bootstrapName =
      'flutter_bootstrap.$jsVersion.${resources['flutter_bootstrap.js']}.js';

  // dart2wasm entrypoint + support runtime (only present with --wasm).
  final wasmVersion = resources['main.dart.wasm'] as String?;
  final mjsVersion = resources['main.dart.mjs'] as String?;
  final wasmName = wasmVersion == null ? null : 'main.$wasmVersion.dart.wasm';
  final mjsName = mjsVersion == null ? null : 'main.$mjsVersion.dart.mjs';

  // Version the dart2js deferred parts and rewrite the references inside the
  // fallback bundle so the browser can't mix parts from two deployments.
  var mainCode = file('main.dart.js').readAsStringSync();
  for (final entry in resources.entries) {
    if (!RegExp(r'^main\.dart\.js_\d+\.part\.js$').hasMatch(entry.key)) {
      continue;
    }
    final versionedName =
        entry.key.replaceFirst('.part.js', '.${entry.value}.part.js');
    mainCode = mainCode.replaceAll('"${entry.key}"', '"$versionedName"');
    file(entry.key).renameSync(file(versionedName).path);
  }
  file(jsName).writeAsStringSync(mainCode);
  file('main.dart.js').deleteSync();

  // Version the wasm entrypoint and its JS support runtime.
  if (wasmName != null && file('main.dart.wasm').existsSync()) {
    file('main.dart.wasm').renameSync(file(wasmName).path);
  }
  if (mjsName != null && file('main.dart.mjs').existsSync()) {
    file('main.dart.mjs').renameSync(file(mjsName).path);
  }

  // Point the bootstrap's build config at the versioned entrypoints.
  final bootstrap = file('flutter_bootstrap.js')
      .readAsStringSync()
      .replaceAll('main.dart.js', jsName)
      .replaceAll('main.dart.wasm', wasmName ?? 'main.dart.wasm')
      .replaceAll('main.dart.mjs', mjsName ?? 'main.dart.mjs');
  file(bootstrapName).writeAsStringSync(bootstrap);
  file('flutter_bootstrap.js').deleteSync();

  final index = file('index.html');
  index.writeAsStringSync(index
      .readAsStringSync()
      .replaceAll('flutter_bootstrap.js', bootstrapName));
  // Existing installations still check this URL for an updated worker.
  worker.writeAsStringSync('''
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    await Promise.all(['flutter-app-cache', 'flutter-temp-cache', 'flutter-app-manifest']
      .map((name) => caches.delete(name)));
    await self.clients.claim();
    await self.registration.unregister();
  })());
});
''');
  stdout.writeln('Versioned web code for release $jsVersion');
}
