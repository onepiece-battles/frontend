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

class ApiInitializer {
  static GetIt getIt = GetIt.instance;

  static initAuthInfo(String token) {
    // construct new api client
    HttpBearerAuth bearAuth = HttpBearerAuth();
    bearAuth.accessToken = token;
    var apiClient = ApiClient(authentication: bearAuth);
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

  static void _registerOrReplace<T extends Object>(T Function() factory) {
    if (getIt.isRegistered<T>()) {
      getIt.unregister<T>();
    }
    getIt.registerLazySingleton<T>(factory);
  }
}
