import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:one_piece_battles_flutter/components/resource_loading.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'support/resource_list_fakes.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/views/character/character_view.dart';
import 'package:one_piece_battles_flutter/repository/fruit_dao.dart';
import 'package:one_piece_battles_flutter/views/fruit/fruit_view.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:one_piece_battles_flutter/views/group/group_view.dart';
import 'package:one_piece_battles_flutter/repository/battle_dao.dart';
import 'package:one_piece_battles_flutter/views/battle/battle_view.dart';

mixin PendingRequests<T> {
  final requests = <Completer<T?>>[];
  Future<T?> next() {
    final request = Completer<T?>();
    requests.add(request);
    return request.future;
  }
}

class PendingCharacter extends ListCharacterFake
    with PendingRequests<ListCharacterResponse> {
  @override
  Future<ListCharacterResponse?> listCharacter(ListCharacterRequest request) =>
      next();
  Future<ListCharacterResponse?> sample() =>
      super.listCharacter(ListCharacterRequest(pageIndex: 1, pageSize: 24));
}

class PendingFruit extends ListFruitFake
    with PendingRequests<ListFruitResponse> {
  @override
  Future<ListFruitResponse?> list(ListFruitRequest request) => next();
  Future<ListFruitResponse?> sample() =>
      super.list(ListFruitRequest(pageIndex: 1, pageSize: 24));
}

class PendingGroup extends ListGroupFake
    with PendingRequests<ListGroupResponse> {
  @override
  Future<ListGroupResponse?> listGroups(ListGroupRequest request) => next();
  Future<ListGroupResponse?> sample() =>
      super.listGroups(ListGroupRequest(pageIndex: 1, pageSize: 24));
}

class PendingBattle extends ListBattleFake
    with PendingRequests<ListBattleResponse> {
  @override
  Future<ListBattleResponse?> listBattles(ListBattleRequest request) => next();
  Future<ListBattleResponse?> sample() =>
      super.listBattles(ListBattleRequest(pageIndex: 1, pageSize: 24));
}

void main() {
  final sources = <String, dynamic>{};
  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    sources.addAll({
      'character': PendingCharacter(),
      'fruit': PendingFruit(),
      'group': PendingGroup(),
      'battle': PendingBattle()
    });
    GetIt.I.registerSingleton<User>(User(
        id: 'test',
        username: 'test',
        nickname: 'Test',
        loginRole: UserRole.NIKA));
    GetIt.I.registerSingleton<Locale>(const Locale('en'));
    GetIt.I.registerSingleton<CharacterDao>(sources['character']);
    GetIt.I.registerSingleton<FruitDao>(sources['fruit']);
    GetIt.I.registerSingleton<GroupDao>(sources['group']);
    GetIt.I.registerSingleton<BattleDao>(sources['battle']);
  });
  tearDown(() async => GetIt.I.reset());
  final views = <String, Widget Function()>{
    'character': () => const CharacterView(),
    'fruit': () => const FruitView(),
    'group': () => const GroupView(),
    'battle': () => const BattleView(),
  };
  for (final entry in views.entries) {
    testWidgets(
        '${entry.key}: loading, refresh, latest search, failure, retry and disposal',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final source = sources[entry.key];
      final data = await source.sample();
      final empty = await source.sample();
      switch (entry.key) {
        case 'character':
          empty.characters.clear();
          break;
        case 'fruit':
          empty.fruits.clear();
          break;
        case 'group':
          empty.groups.clear();
          break;
        case 'battle':
          empty.battles.clear();
          break;
      }
      empty.totalSize = 0;
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: entry.value()),
      ));
      expect(find.byType(ResourceLoading), findsOneWidget);
      expect(find.byType(ResourceEmptyState), findsNothing);
      source.requests[0].complete(data);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ResourceLoading), findsNothing);
      expect(find.byType(ResourceEmptyState), findsNothing);
      final search = find.byType(TextFormField).first;
      await tester.enterText(search, 'old');
      await tester.pump();
      expect(find.byType(ResourceLoading), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.enterText(search, 'new');
      await tester.pump();
      source.requests[2].complete(empty);
      await tester.pump();
      expect(find.byType(ResourceEmptyState), findsOneWidget);
      source.requests[1].complete(data);
      await tester.pump();
      expect(find.byType(ResourceEmptyState), findsOneWidget);
      await tester.enterText(search, 'broken');
      await tester.pump();
      source.requests[3].completeError(StateError('offline'));
      await tester.pump();
      final loc =
          AppLocalizations.of(tester.element(find.byType(ResourceEmptyState)))!;
      expect(find.text(loc.resourceLoadFailed), findsOneWidget);
      await tester.tap(find.text(loc.retryLoading));
      await tester.pump();
      expect(find.byType(ResourceLoading), findsOneWidget);
      source.requests[4].complete(null);
      await tester.pump();
      expect(find.text(loc.resourceLoadFailed), findsOneWidget);
      await tester.tap(find.text(loc.retryLoading));
      await tester.pump();
      source.requests[5].complete(data);
      await tester.pump();
      expect(find.byType(ResourceEmptyState), findsNothing);
      await tester.enterText(search, 'leave');
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      source.requests[6].complete(data);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
