import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

GetIt getIt = GetIt.instance;
class ResourcePermissionManager {
  static const Map<ResourceType, int> resourceOrderMap = {
    ResourceType.CHARACTER: 1,
    ResourceType.FRUIT: 2,
    ResourceType.BATTLE: 3,
    ResourceType.USER: 4,
    ResourceType.ISSUE: 5,
    ResourceType.ROLE: 6
  };

  static void updateUserCache(User user) {
    // sort resource type value, the display order is dependent on this order map
    user.loginRoleResources
        .sort((a, b) => resourceOrderMap[a]!.compareTo(resourceOrderMap[b]!));
    getIt.registerLazySingleton(()=>user);
  }
}