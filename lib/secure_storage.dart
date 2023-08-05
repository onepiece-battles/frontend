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

  static readAccessToken() async {
    _readSecureData(CommonConstants.accessToken);
  }

  static readRefreshToken() async {
    _readSecureData(CommonConstants.refreshToken);
  }

  static _writeSecureData(String key, String value) async {
    await storage.write(key: key, value: value);
  }

  static _readSecureData(String key) async {
    return await storage.read(key: key);
  }

  static _deleteSecureData(String key) async {
    return await storage.delete(key: key);
  }
}
