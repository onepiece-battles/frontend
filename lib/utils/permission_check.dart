import 'package:openapi/api.dart';

class PermissionCheck {
  static bool checkPermission(
      List<ResourcePermissionMap> loginRoleResourcePermissionMap,
      ResourceType expectedResource,
      Permission expectedPermission) {
    var resources =
        loginRoleResourcePermissionMap.map((e) => e.resourceType).toList();
    if (resources.contains(expectedResource)) {
      return loginRoleResourcePermissionMap
          .firstWhere((element) => element.resourceType == expectedResource)
          .permissions
          .contains(expectedPermission);
    }
    return false;
  }

  static bool isMyResource(String? creatorUserId, String? creatorRoleId,
      String myUserId, String? loginRoleId) {
    return myUserId.isNotEmpty &&
        loginRoleId != null &&
        creatorUserId == myUserId &&
        creatorRoleId == loginRoleId;
  }
}
