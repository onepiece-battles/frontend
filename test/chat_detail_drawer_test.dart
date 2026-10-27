import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/repository/chatting_dao.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:one_piece_battles_flutter/views/chatting/widgets/add_chat_member_dialog.dart';
import 'package:one_piece_battles_flutter/views/chatting/widgets/chat_detail_drawer.dart';
import 'package:openapi/api.dart';

User _user(String id, String nickname) => User(
      id: id,
      username: '$id@example.com',
      nickname: nickname,
      imageUri: '',
    );

class _FriendsDao extends UserDao {
  _FriendsDao() : super.empty();

  @override
  Future<ListFriendResponse?> listFriend(ListFriendRequest request) async =>
      ListFriendResponse(users: [
        _user('me', '路飞'),
        _user('nami', '娜美'),
        _user('zoro', '索隆'),
      ]);
}

class _JoinDao extends ChattingDao {
  _JoinDao() : super.empty();
  JoinChatRequest? request;

  @override
  Future<Chat?> joinChat(JoinChatRequest request) async {
    this.request = request;
    return Chat(id: request.conversationId, group: true);
  }
}

Widget _app(Chat chat,
        {VoidCallback? onAddMember, ValueChanged<User>? onOpenProfile}) =>
    MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ChatDetailDrawer(
          chat: chat,
          currentUserId: 'me',
          onAddMember: onAddMember,
          onOpenProfile: onOpenProfile,
        ),
      ),
    );

void main() {
  testWidgets('group details show members and a working add action on mobile',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var addCount = 0;
    User? opened;
    final chat = Chat(
      id: 'group',
      group: true,
      name: '草帽一伙',
      members: [_user('me', '路飞'), _user('nami', '娜美')],
    );
    await tester.pumpWidget(_app(chat,
        onAddMember: () => addCount++, onOpenProfile: (user) => opened = user));
    expect(find.text('群聊信息'), findsOneWidget);
    expect(find.text('草帽一伙'), findsOneWidget);
    expect(find.text('群成员'), findsOneWidget);
    expect(find.text('对方资料'), findsNothing);
    await tester.tap(find.text('添加成员'));
    expect(addCount, 1);
    await tester.tap(find.text('娜美'));
    expect(opened?.id, 'nami');
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct details show the other user without group actions',
      (tester) async {
    final chat = Chat(
      id: 'direct',
      group: false,
      members: [_user('me', '路飞'), _user('zoro', '索隆')],
    );
    User? opened;
    await tester.pumpWidget(_app(chat, onOpenProfile: (user) => opened = user));
    expect(find.text('对方资料'), findsWidgets);
    expect(find.text('索隆'), findsWidgets);
    expect(find.text('zoro@example.com'), findsOneWidget);
    expect(find.text('群成员'), findsNothing);
    expect(find.text('添加成员'), findsNothing);
    await tester.tap(find.text('查看个人资料'));
    expect(opened?.id, 'zoro');
    expect(tester.takeException(), isNull);
  });

  testWidgets('adding a member excludes existing users and includes caller id',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final joinDao = _JoinDao();
    Chat? updated;
    final chat = Chat(
      id: 'group',
      group: true,
      members: [_user('me', '路飞'), _user('nami', '娜美')],
    );
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: AddChatMemberDialog(
          chat: chat,
          currentUserId: 'me',
          userDao: _FriendsDao(),
          chattingDao: joinDao,
          onMembersAdded: (value) => updated = value,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('娜美'), findsNothing);
    expect(find.text('索隆'), findsOneWidget);
    await tester.tap(find.text('索隆'));
    await tester.pump();
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    expect(joinDao.request?.conversationId, 'group');
    expect(joinDao.request?.ids, ['me', 'zoro']);
    expect(updated?.id, 'group');
    expect(tester.takeException(), isNull);
  });
}
