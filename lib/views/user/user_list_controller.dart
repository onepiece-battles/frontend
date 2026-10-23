import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

import '../../repository/user_dao.dart';

/// Data-access boundary for the user list screen.
///
/// Fronts [UserDao] so the view no longer reaches into the global service
/// locator for its queries, giving the feature a single, mockable data seam.
class UserListController extends ChangeNotifier {
  UserListController({UserDao? userDao})
      : _userDao = userDao ?? GetIt.instance<UserDao>();

  final UserDao _userDao;

  /// List users matching the given filter / paging request.
  Future<ListUsersResponse?> listUser(ListUsersRequest request) =>
      _userDao.listUser(request);
}
