import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/app_router.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/personal_home.dart';
import 'package:one_piece_battles_flutter/repository/battle_dao.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:openapi/api.dart';
import 'package:visibility_detector/visibility_detector.dart';

class _Characters extends CharacterDao {
  _Characters() : super.empty();
  @override
  Future<ListCharacterResponse?> listCharacter(
          ListCharacterRequest request) async =>
      ListCharacterResponse();
}

class _Groups extends GroupDao {
  _Groups({this.populated = false}) : super.empty();
  final bool populated;
  @override
  Future<ListGroupResponse?> listGroups(ListGroupRequest request) async =>
      ListGroupResponse(
          groups: populated
              ? [
                  GroupListView(
                      id: 'straw-hats',
                      name: I18nText(zhCN: '草帽团', enUS: 'Straw Hats'),
                      imageUri: '')
                ]
              : []);
}

class _Battles extends BattleDao {
  _Battles() : super.empty();
  @override
  Future<ListBattleResponse?> listBattles(ListBattleRequest request) async =>
      ListBattleResponse();
}

void main() {
  setUp(() async {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    await GetIt.I.reset();
    GetIt.I.registerSingleton<Locale>(const Locale('zh'));
    GetIt.I.registerSingleton<User>(User(
      id: 'me',
      username: 'me@example.com',
      nickname: '路飞',
      loginRole: UserRole.NIKA,
    ));
    GetIt.I.registerSingleton<CharacterDao>(_Characters());
    GetIt.I.registerSingleton<GroupDao>(_Groups());
    GetIt.I.registerSingleton<BattleDao>(_Battles());
  });
  tearDown(() async => GetIt.I.reset());

  for (final width in [390.0, 1280.0]) {
    testWidgets('personal home shows overview and creation paths at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: UserHome(userId: 'me')),
      ));
      await tester.pumpAndSettle();
      expect(find.text('个人主页'), findsOneWidget);
      expect(find.text('我的资源'), findsOneWidget);
      expect(find.text('创建角色'), findsOneWidget);
      expect(find.text('创建团体'), findsOneWidget);
      expect(find.text('创建战斗'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('empty-resource actions target existing routes', () {
    expect(AppRouter.router.namedLocation('create_character'),
        contains('/create'));
    expect(AppRouter.router.namedLocation('create_group'), contains('/create'));
    expect(
        AppRouter.router.namedLocation('create_battle'), contains('/create'));
  });

  testWidgets('personal home presents a populated resource without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    GetIt.I.unregister<GroupDao>();
    GetIt.I.registerSingleton<GroupDao>(_Groups(populated: true));
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: UserHome(userId: 'me')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('草帽团'), findsOneWidget);
    expect(find.text('创建团体'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
