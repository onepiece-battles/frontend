import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

GetIt getIt = GetIt.instance;

class ResourcePermissionManager {
  static const Map<ResourceType, int> resourceOrderMap = {
    ResourceType.CHARACTER: 1,
    ResourceType.FRUIT: 2,
    ResourceType.BATTLE: 3,
    ResourceType.GROUP: 4,
    ResourceType.USER: 5,
    ResourceType.ISSUE: 6,
    ResourceType.ROLE: 7,
    ResourceType.CHATTING: 8
  };

  static void updateUserCache(User user) {
    // sort resource type value, the display order is dependent on this order map
    user.loginRoleResourcesPermissionMap.sort((a, b) =>
        resourceOrderMap[a.resourceType]!
            .compareTo(resourceOrderMap[b.resourceType]!));

    // Unregister before re-registering to avoid "already registered" errors
    // on subsequent logins / role switches.
    if (getIt.isRegistered<User>()) {
      getIt.unregister<User>();
    }
    getIt.registerLazySingleton(() => user);
  }
}
