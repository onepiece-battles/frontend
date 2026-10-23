import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

import '../../repository/user_dao.dart';

/// Data-access boundary for the user detail screen.
///
/// Fronts [UserDao] so the view no longer reaches into the global service
/// locator for server interaction, giving the feature a single, mockable seam.
class UserDetailController extends ChangeNotifier {
  UserDetailController({UserDao? userDao})
      : _userDao = userDao ?? GetIt.instance<UserDao>();

  final UserDao _userDao;

  /// Load a single user.
  Future<User?> get(GetUserRequest request) => _userDao.get(request);
}
