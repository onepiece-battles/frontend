import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:one_piece_battles_flutter/constants/common_constants.dart';

class SecureStorage {
  static const FlutterSecureStorage storage = FlutterSecureStorage();
  static writeAccessToken(String accessToken) async {
    _writeSecureData(CommonConstants.accessToken, accessToken);
  }

  static writeRefreshToken(String refreshToken) async {
    _writeSecureData(CommonConstants.refreshToken, refreshToken);
  }

  static Future<String?> readAccessToken() async {
    return _readSecureData(CommonConstants.accessToken);
  }

  static Future<String?> readRefreshToken() async {
    return _readSecureData(CommonConstants.refreshToken);
  }

  static _writeSecureData(String key, String value) async {
    await storage.write(key: key, value: value);
  }

  static Future<String?> _readSecureData(String key)  async{
    return await storage.read(key: key);
  }

  static void _deleteSecureData(String key) async {
    return await storage.delete(key: key);
  }
}
