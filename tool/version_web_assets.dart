import 'dart:convert';
import 'dart:io';

/// Give compiled code content-versioned URLs so browsers cannot combine
/// deferred libraries from two Docker deployments. Uses Flutter's generated
/// content hashes; no extra build dependencies are needed.
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
  final version = resources['main.dart.js'] as String;
  final mainName = 'main.$version.dart.js';
  final bootstrapName =
      'flutter_bootstrap.$version.${resources['flutter_bootstrap.js']}.js';
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
  file(mainName).writeAsStringSync(mainCode);
  file('main.dart.js').deleteSync();
  final bootstrap = file('flutter_bootstrap.js')
      .readAsStringSync()
      .replaceAll('main.dart.js', mainName);
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
  stdout.writeln('Versioned web code for release $version');
}
