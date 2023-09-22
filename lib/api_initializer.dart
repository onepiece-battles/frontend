import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:openapi/api.dart';

class ApiInitializer {
  static const Map<ResourceType, int> resourceOrderMap = {
    ResourceType.CHARACTER:1,
    ResourceType.FRUIT:2,
    ResourceType.BATTLE:3,
    ResourceType.USER:4
  };
  static GetIt getIt = GetIt.instance;
  static initAuthInfo(User user, String token) {
    // construct new api client
    HttpBearerAuth bearAuth = HttpBearerAuth();
    bearAuth.accessToken = token;
    var apiClient = ApiClient(authentication: bearAuth);
    // sort resource type value, the display order is dependent on this order map
    user.loginRoleResources.sort((a,b) => resourceOrderMap[a]!.compareTo(resourceOrderMap[b]!));
    // init dao apis with new api client
    getIt.registerLazySingleton<UserDao>(() => UserDao(apiClient));
    getIt.registerLazySingleton<CharacterDao>(() => CharacterDao(apiClient));
    getIt.registerLazySingleton<User>(() => user);
  }
}
