import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/repository/battle_dao.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/repository/fruit_dao.dart';
import 'package:one_piece_battles_flutter/repository/image_dao.dart';
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
    // init dao apis with new api client
    getIt.registerLazySingleton<UserDao>(() => UserDao(apiClient));
    getIt.registerLazySingleton<CharacterDao>(() => CharacterDao(apiClient));
    getIt.registerLazySingleton<ImageDao>(() => ImageDao(apiClient));
    getIt.registerLazySingleton<IssueDao>(() => IssueDao(apiClient));
    getIt.registerLazySingleton<BattleDao>(() => BattleDao(apiClient));
    getIt.registerLazySingleton<FruitDao>(() => FruitDao(apiClient));
  }
}
