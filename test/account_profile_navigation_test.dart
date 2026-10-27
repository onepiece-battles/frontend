import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/app_router.dart';
import 'package:one_piece_battles_flutter/home_page.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/popup/user_navigation.dart';
import 'package:one_piece_battles_flutter/repository/email_dao.dart';
import 'package:one_piece_battles_flutter/repository/image_dao.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:one_piece_battles_flutter/utils/image_helper.dart';
import 'package:one_piece_battles_flutter/views/user/user_profile.dart';
import 'package:openapi/api.dart';

User _profileUser([String nickname = '路飞']) => User(
      id: 'me',
      username: 'me@example.com',
      nickname: nickname,
      profileImage: '',
      emailVerified: true,
    );

class _ProfileDao extends UserDao {
  _ProfileDao({this.fail = false}) : super.empty();
  bool fail;
  int requests = 0;
  String nickname = '路飞';

  @override
  Future<User?> get(GetUserRequest request) async {
    requests++;
    return fail ? null : _profileUser(nickname);
  }

  @override
  Future<UpdateUserResponse?> updateUser(UpdateUserRequest request) async {
    nickname = request.nickname!;
    return UpdateUserResponse(user: _profileUser(nickname));
  }
}

class _OtherProfileDao extends UserDao {
  _OtherProfileDao() : super.empty();

  @override
  Future<User?> get(GetUserRequest request) async => User(
        id: 'other',
        username: 'other@example.com',
        nickname: '娜美',
        profileImage: '',
        emailVerified: false,
      );
}

Widget _profileApp() => const MaterialApp(
      locale: Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: UserProfile(userId: 'me')),
    );

void main() {
  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<User>(_profileUser());
    GetIt.I.registerSingleton<ImageDao>(ImageDao.empty());
    GetIt.I.registerSingleton<EmailDao>(EmailDao.empty());
  });
  tearDown(() async => GetIt.I.reset());

  test('account route uses the registered name', () {
    final location = AppRouter.router
        .namedLocation('user_profile', pathParameters: {'name': '路飞'});
    expect(location, endsWith('/profile'));
  });

  testWidgets('decoded raster images stay in Flutter scene for background blur',
      (tester) async {
    final bytes = Uint8List.fromList(base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/0x8AAAAASUVORK5CYII='));
    final image = ImageHelper.rasterImage(bytes);
    expect(image, isA<Image>());
    expect(((image as Image).image as NetworkImage).webHtmlElementStrategy,
        WebHtmlElementStrategy.never);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: image)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('account page shows compact identity and information on mobile',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    GetIt.I.registerSingleton<UserDao>(_ProfileDao());
    await tester.pumpWidget(_profileApp());
    await tester.pumpAndSettle();
    expect(find.text('我的账号'), findsOneWidget);
    expect(find.text('路飞'), findsWidgets);
    expect(find.text('me@example.com'), findsWidgets);
    expect(find.text('基本信息'), findsOneWidget);
    expect(find.byTooltip('编辑昵称'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('another member profile is visible without account actions',
      (tester) async {
    GetIt.I.registerSingleton<UserDao>(_OtherProfileDao());
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: UserProfile(userId: 'other')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('个人资料'), findsOneWidget);
    expect(find.text('娜美'), findsWidgets);
    expect(find.byTooltip('编辑昵称'), findsNothing);
    expect(find.text('上传头像'), findsNothing);
    expect(find.text('发送验证邮件'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed account load offers retry instead of crashing',
      (tester) async {
    final dao = _ProfileDao(fail: true);
    GetIt.I.registerSingleton<UserDao>(dao);
    await tester.pumpWidget(_profileApp());
    await tester.pumpAndSettle();
    expect(find.text('账号资料加载失败，请重试'), findsOneWidget);
    dao.fail = false;
    await tester.tap(find.text('重新加载'));
    await tester.pumpAndSettle();
    expect(find.text('路飞'), findsWidgets);
    expect(dao.requests, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('account edits nickname and keeps the profile route working',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dao = _ProfileDao();
    GetIt.I.registerSingleton<UserDao>(dao);
    final router = GoRouter(
      initialLocation: '/home/old/profile',
      routes: [
        GoRoute(
          path: '/home/:name/profile',
          name: 'user_profile',
          builder: (context, state) =>
              const Scaffold(body: UserProfile(userId: 'me')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('编辑昵称'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '新昵称');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(dao.nickname, '新昵称');
    expect(router.routeInformationProvider.value.uri.path,
        '/home/%E6%96%B0%E6%98%B5%E7%A7%B0/profile');
    expect(tester.takeException(), isNull);
  });

  testWidgets('sidebar account entry reaches the profile route',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(
            body: SideMenu(constraints: BoxConstraints(maxWidth: 1280)),
          ),
        ),
        GoRoute(
          path: '/home/:name/profile',
          name: 'user_profile',
          builder: (context, state) =>
              const Scaffold(body: Text('Account destination')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的账号'));
    await tester.pumpAndSettle();
    expect(find.text('Account destination'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('avatar menu account entry reaches the profile route',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (context) => Align(
                alignment: Alignment.topLeft,
                child: UserNavigation(
                    context: context,
                    constraints: const BoxConstraints(maxWidth: 1280)),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/home/:name/profile',
          name: 'user_profile',
          builder: (context, state) =>
              const Scaffold(body: Text('Account destination')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(UserNavigation));
    await tester.pumpAndSettle();
    await tester.tap(find.text('个人账号'));
    await tester.pumpAndSettle();
    expect(find.text('Account destination'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
