import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/views/character/character_view.dart';
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
      characters: List.generate(
          24, (index) => sampleCharacter((request.pageIndex - 1) * 24 + index)),
    );
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
      characters: List.generate(24, (index) => sampleCharacter(24 + index)),
    ));
    await tester.pump();
    expect(dao.pages, [1, 2]);
    expect(scrollable.position.pixels, beforeAppend);
    await tester.drag(list, const Offset(0, -4000));
    await tester.pump();
    expect(find.text('Monkey D. Luffy 47'), findsOneWidget);
  });
}
