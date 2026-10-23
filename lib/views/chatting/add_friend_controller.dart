import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

import '../../repository/user_dao.dart';

/// Data-access boundary for the add-friend screen.
///
/// Fronts [UserDao] so the view no longer reaches into the global service
/// locator for server interaction, giving the feature a single, mockable seam.
class AddFriendController extends ChangeNotifier {
  AddFriendController({UserDao? userDao})
      : _userDao = userDao ?? GetIt.instance<UserDao>();

  final UserDao _userDao;

  /// Search users to befriend.
  Future<ListUsersResponse?> listUser(ListUsersRequest request) =>
      _userDao.listUser(request);

  /// Send a friend request.
  Future<AddFriendResponse?> addFriend(AddFriendRequest request) =>
      _userDao.addFriend(request);
}
