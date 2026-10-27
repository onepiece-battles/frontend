import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/components/resource_list_load_more.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/repository/battle_dao.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/repository/fruit_dao.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:one_piece_battles_flutter/views/battle/battle_view.dart';
import 'package:one_piece_battles_flutter/views/character/character_view.dart';
import 'package:one_piece_battles_flutter/views/fruit/fruit_view.dart';
import 'package:one_piece_battles_flutter/views/group/group_view.dart';
import 'package:openapi/api.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'support/resource_list_fakes.dart';

class _PagedCharacters extends CharacterDao {
  _PagedCharacters() : super.empty();

  final pages = <int>[];
  final secondPage = Completer<ListCharacterResponse?>();

  @override
  Future<ListCharacterResponse?> listCharacter(
      ListCharacterRequest request) async {
    pages.add(request.pageIndex);
    if (request.pageIndex == 2) return secondPage.future;
    return ListCharacterResponse(
      totalSize: 48,
      characters: List.unmodifiable(List.generate(24,
          (index) => sampleCharacter((request.pageIndex - 1) * 24 + index))),
    );
  }
}

class _PagedFruits extends ListFruitFake {
  final pages = <int>[];

  @override
  Future<ListFruitResponse?> list(ListFruitRequest request) async {
    pages.add(request.pageIndex);
    final response = (await super.list(request))!;
    response.totalSize = 48;
    for (final item in response.fruits) {
      item.id = '${request.pageIndex}-${item.id}';
    }
    response.fruits = List.unmodifiable(response.fruits);
    return response;
  }
}

class _PagedGroups extends ListGroupFake {
  final pages = <int>[];

  @override
  Future<ListGroupResponse?> listGroups(ListGroupRequest request) async {
    pages.add(request.pageIndex);
    final response = (await super.listGroups(request))!;
    response.totalSize = 48;
    for (final item in response.groups) {
      item.id = '${request.pageIndex}-${item.id}';
    }
    response.groups = List.unmodifiable(response.groups);
    return response;
  }
}

class _PagedBattles extends ListBattleFake {
  final pages = <int>[];

  @override
  Future<ListBattleResponse?> listBattles(ListBattleRequest request) async {
    pages.add(request.pageIndex);
    final response = (await super.listBattles(request))!;
    response.totalSize = 48;
    for (final item in response.battles) {
      item.id = '${request.pageIndex}-${item.id}';
    }
    response.battles = List.unmodifiable(response.battles);
    return response;
  }
}

void main() {
  testWidgets('next page appends below the current scroll position',
      (tester) async {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    tester.view.physicalSize = const Size(375, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dao = _PagedCharacters();
    GetIt.I.registerSingleton<User>(User(
        id: 'test',
        username: 'test',
        nickname: 'Test',
        loginRole: UserRole.NIKA));
    GetIt.I.registerSingleton<Locale>(const Locale('en'));
    GetIt.I.registerSingleton<CharacterDao>(dao);
    addTearDown(() => GetIt.I.reset());

    await tester.pumpWidget(const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: CharacterView()),
    ));
    await tester.pump();
    expect(dao.pages, [1]);

    final list = find.byType(ListView).first;
    await tester.drag(list, const Offset(0, -4000));
    await tester.pump();
    expect(dao.pages, [1, 2]);
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: list, matching: find.byType(Scrollable)).first,
    );
    final beforeAppend = scrollable.position.pixels;

    dao.secondPage.complete(ListCharacterResponse(
      totalSize: 48,
      characters: List.unmodifiable(
          List.generate(24, (index) => sampleCharacter(24 + index))),
    ));
    await tester.pump();
    expect(dao.pages, [1, 2]);
    expect(scrollable.position.pixels, beforeAppend);
    await tester.drag(list, const Offset(0, -4000));
    await tester.pump();
    expect(find.text('Monkey D. Luffy 47'), findsOneWidget);
  });

  for (final kind in ['fruit', 'group', 'battle']) {
    testWidgets('$kind appends a fixed-length API page without failing',
        (tester) async {
      VisibilityDetectorController.instance.updateInterval = Duration.zero;
      tester.view.physicalSize = const Size(375, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      GetIt.I.registerSingleton<User>(User(
          id: 'test',
          username: 'test',
          nickname: 'Test',
          loginRole: UserRole.NIKA));
      GetIt.I.registerSingleton<Locale>(const Locale('en'));
      addTearDown(() => GetIt.I.reset());

      final Widget view;
      final List<int> pages;
      switch (kind) {
        case 'fruit':
          final dao = _PagedFruits();
          GetIt.I.registerSingleton<FruitDao>(dao);
          view = const FruitView();
          pages = dao.pages;
        case 'group':
          final dao = _PagedGroups();
          GetIt.I.registerSingleton<GroupDao>(dao);
          view = const GroupView();
          pages = dao.pages;
        default:
          final dao = _PagedBattles();
          GetIt.I.registerSingleton<BattleDao>(dao);
          view = const BattleView();
          pages = dao.pages;
      }

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: view),
      ));
      await tester.pump();
      expect(pages, [1]);
      await tester.drag(find.byType(ListView).first, const Offset(0, -4000));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(pages, [1, 2]);
      expect(find.byType(ResourceListLoadMore), findsNothing);
    });
  }
}
