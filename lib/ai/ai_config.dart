import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Holds the DeepSeek endpoint and the user-supplied API key. The key is kept
/// in secure storage so it can be configured at runtime (no rebuild) and never
/// ships in the repository. A build-time `--dart-define=DEEPSEEK_API_KEY=…`
/// value is used as a fallback.
class AiConfig {
  AiConfig._();

  static const baseUrl = 'https://api.deepseek.com/chat/completions';
  static const model = 'deepseek-chat';

  static const _storage = FlutterSecureStorage();
  static const _keyName = 'deepseek_api_key';
  static const _envKey =
      String.fromEnvironment('DEEPSEEK_API_KEY', defaultValue: '');

  static String? _cached;

  static Future<String?> getKey() async {
    _cached ??= await _safeRead();
    final key = (_cached?.isNotEmpty ?? false) ? _cached : null;
    if (key != null) return key;
    return _envKey.isNotEmpty ? _envKey : null;
  }

  static Future<String?> _safeRead() async {
    try {
      return await _storage.read(key: _keyName);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setKey(String key) async {
    _cached = key.trim();
    try {
      await _storage.write(key: _keyName, value: _cached);
    } catch (_) {}
  }

  static Future<void> clear() async {
    _cached = null;
    try {
      await _storage.delete(key: _keyName);
    } catch (_) {}
  }
}
