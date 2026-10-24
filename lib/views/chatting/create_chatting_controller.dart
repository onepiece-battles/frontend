import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';

import '../../repository/chatting_dao.dart';
import '../../repository/user_dao.dart';

/// Data-access boundary for the create-chat screen.
///
/// Fronts the user / chatting DAOs so the view no longer reaches into the
/// global service locator for server interaction.
class CreateChattingController extends ChangeNotifier {
  CreateChattingController({UserDao? userDao, ChattingDao? chattingDao})
      : _userDao = userDao ?? GetIt.instance<UserDao>(),
        _chattingDao = chattingDao ?? GetIt.instance<ChattingDao>();

  final UserDao _userDao;
  final ChattingDao _chattingDao;

  /// List the current user's friends (the candidate chat members).
  Future<ListFriendResponse?> listFriend(ListFriendRequest request) =>
      _userDao.listFriend(request);

  /// Create a new chat with the chosen members.
  Future<Chat?> createChat(CreateChatRequest request) =>
      _chattingDao.createChat(request);
}
