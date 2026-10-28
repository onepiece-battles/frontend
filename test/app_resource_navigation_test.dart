@TestOn('browser')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:one_piece_battles_flutter/app_router.dart';
import 'package:one_piece_battles_flutter/components/chat_notifier.dart';
import 'package:one_piece_battles_flutter/components/web_socket_service.dart';
import 'package:one_piece_battles_flutter/components/resource_detail_layout.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/repository/battle_dao.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/repository/fruit_dao.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:one_piece_battles_flutter/repository/image_dao.dart';
import 'package:one_piece_battles_flutter/repository/file_dao.dart';
import 'package:one_piece_battles_flutter/repository/notification_dao.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';

import 'support/resource_detail_fakes.dart';

class _Notifications extends NotificationDao {
  _Notifications() : super.empty();
  @override
  Future<ListNotificationResponse?> list(
          ListNotificationRequest request) async =>
      ListNotificationResponse();
}

void main() {
  testWidgets('real router opens all four details and restores copied links',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    GetIt.I.registerSingleton<User>(User(
        id: 'me',
        username: 'test',
        nickname: 'test',
        loginRole: UserRole.NIKA,
        userRoles: [UserRole.NIKA]));
    GetIt.I.registerSingleton<Locale>(const Locale('en'));
    GetIt.I.registerSingleton<CharacterDao>(DetailCharacterFake());
    GetIt.I.registerSingleton<FruitDao>(DetailFruitFake());
    GetIt.I.registerSingleton<GroupDao>(DetailGroupFake());
    GetIt.I.registerSingleton<BattleDao>(DetailBattleFake());
    GetIt.I.registerSingleton<ImageDao>(ImageDao.empty());
    GetIt.I.registerSingleton<FileDao>(FileDao.empty());
    GetIt.I.registerSingleton<NotificationDao>(_Notifications());
    GetIt.I.registerSingleton<UserDao>(UserDao.empty());
    addTearDown(() => GetIt.I.reset());

    final router = AppRouter.router;
    router.go('${AppRouter.characterPath}/Luffy?id=0');
    final notifier = ChatNotifier(WebSocketService());
    addTearDown(notifier.dispose);
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: notifier,
        child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales)));

    for (final name in [
      'characterDetails',
      'fruitDetails',
      'groupDetails',
      'battleDetails'
    ]) {
      router.goNamed(name,
          extra: '0',
          pathParameters: {name == 'battleDetails' ? 'id' : 'name': '0'});
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull, reason: name);
      expect(
          router.routeInformationProvider.value.uri.queryParameters['id'], '0');
      expect(
          name == 'battleDetails'
              ? find.byKey(const Key('battle-story'))
              : find.byType(DetailHero),
          findsOneWidget,
          reason: name);
      // Re-enter using only the URL, with no transient extra.
      router.go(router.routeInformationProvider.value.uri.toString());
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull, reason: '$name copied URL');
    }
    final sharedBattle = router.routeInformationProvider.value.uri;
    GetIt.I.unregister<User>();
    GetIt.I.registerSingleton<User>(User(id: '', username: '', nickname: ''));
    router.go(sharedBattle.toString());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final login = router.routeInformationProvider.value.uri;
    expect(login.path, '/login');
    expect(login.queryParameters['from'], sharedBattle.toString());
    GetIt.I.unregister<User>();
    GetIt.I.registerSingleton<User>(User(
        id: 'me',
        username: 'test',
        nickname: 'test',
        loginRole: UserRole.NIKA,
        userRoles: [UserRole.NIKA]));
    router.go(login.toString());
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('battle-story')), findsOneWidget);
    expect(router.routeInformationProvider.value.uri, sharedBattle);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
