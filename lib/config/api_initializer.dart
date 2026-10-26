import 'dart:async';
import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/repository/battle_dao.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/repository/chatting_dao.dart';
import 'package:one_piece_battles_flutter/repository/email_dao.dart';
import 'package:one_piece_battles_flutter/repository/file_dao.dart';
import 'package:one_piece_battles_flutter/repository/fruit_dao.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:one_piece_battles_flutter/repository/image_dao.dart';
import 'package:one_piece_battles_flutter/repository/message_dao.dart';
import 'package:one_piece_battles_flutter/repository/notification_dao.dart';
import 'package:one_piece_battles_flutter/repository/support_dao.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:openapi/api.dart';
import '../repository/issue_dao.dart';
import 'session_aware_client.dart';

class ApiInitializer {
  static GetIt getIt = GetIt.instance;
  static void Function()? onSessionExpired;
  static String? _activeToken;
  static bool _expiryHandled = false;
  static Timer? _expiryTimer;

  static initAuthInfo(String token) {
    _expiryTimer?.cancel();
    _activeToken = token;
    _expiryHandled = false;
    _scheduleJwtExpiry(token);
    // construct new api client
    HttpBearerAuth bearAuth = HttpBearerAuth();
    bearAuth.accessToken = token;
    var apiClient = ApiClient(authentication: bearAuth);
    apiClient.client = SessionAwareClient(apiClient.client, () {
      _expire(token);
    });
    // init dao apis with new api client — unregister first to avoid
    // "already registered" errors on re-login
    _registerOrReplace<UserDao>(() => UserDao(apiClient));
    _registerOrReplace<CharacterDao>(() => CharacterDao(apiClient));
    _registerOrReplace<ChattingDao>(() => ChattingDao(apiClient));
    _registerOrReplace<ImageDao>(() => ImageDao(apiClient));
    _registerOrReplace<IssueDao>(() => IssueDao(apiClient));
    _registerOrReplace<BattleDao>(() => BattleDao(apiClient));
    _registerOrReplace<FruitDao>(() => FruitDao(apiClient));
    _registerOrReplace<FileDao>(() => FileDao(apiClient));
    _registerOrReplace<GroupDao>(() => GroupDao(apiClient));
    _registerOrReplace<SupportDao>(() => SupportDao(apiClient));
    _registerOrReplace<EmailDao>(() => EmailDao(apiClient));
    _registerOrReplace<NotificationDao>(() => NotificationDao(apiClient));
    _registerOrReplace<MessageDao>(() => MessageDao(apiClient));
  }

  static void clearAuth() {
    _expiryTimer?.cancel();
    _activeToken = null;
    _expiryHandled = false;
  }

  static void _expire(String token) {
    if (_activeToken != token || _expiryHandled) return;
    _expiryHandled = true;
    _expiryTimer?.cancel();
    onSessionExpired?.call();
  }

  static void _scheduleJwtExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return;
      final payload = jsonDecode(
              utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
          as Map<String, dynamic>;
      final seconds = payload['exp'];
      if (seconds is! num) return;
      final expiry =
          DateTime.fromMillisecondsSinceEpoch(seconds.toInt() * 1000);
      final remaining = expiry.difference(DateTime.now());
      _expiryTimer = Timer(remaining.isNegative ? Duration.zero : remaining,
          () => _expire(token));
    } catch (_) {
      // A malformed or opaque token still gets the HTTP 401 fallback.
    }
  }

  static void _registerOrReplace<T extends Object>(T Function() factory) {
    if (getIt.isRegistered<T>()) {
      getIt.unregister<T>();
    }
    getIt.registerLazySingleton<T>(factory);
  }
}
