import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';
import 'package:one_piece_battles_flutter/components/resource_detail_route.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/repository/fruit_dao.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';

import 'support/resource_list_fakes.dart';

class _KillerDao extends ListCharacterFake {
  @override
  Future<ListCharacterResponse?> listCharacter(
      ListCharacterRequest request) async {
    return ListCharacterResponse(characters: [
      sampleCharacter(0)
        ..id = 'killer-id'
        ..name = I18nText(zhCN: '基拉', enUS: 'Killer')
    ]);
  }
}

void main() {
  setUp(() {
    GetIt.I.registerSingleton<CharacterDao>(ListCharacterFake());
    GetIt.I.registerSingleton<FruitDao>(ListFruitFake());
    GetIt.I.registerSingleton<GroupDao>(ListGroupFake());
  });
  tearDown(() => GetIt.I.reset());

  testWidgets('the reported shared Killer URL resolves without transient extra',
      (tester) async {
    GetIt.I.unregister<CharacterDao>();
    GetIt.I.registerSingleton<CharacterDao>(_KillerDao());
    final shared = Uri.parse(
        'https://onepiece-battles.com/#/home/character/%E5%9F%BA%E6%8B%89');
    final name = Uri.parse(shared.fragment).pathSegments.last;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
          body: ResourceDetailRoute(
              id: null,
              type: 'character',
              name: name,
              page: (id) => Text('resolved:$id'))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('resolved:killer-id'), findsOneWidget);
  });

  for (final entry in {
    'character': ['蒙奇·D·路飞 0', 'Monkey D. Luffy 0'],
    'fruit': ['橡胶果实 0', 'Gum-Gum Fruit 0'],
    'group': ['草帽海贼团 0', 'Straw Hat Pirates 0'],
  }.entries) {
    for (final name in entry.value) {
      testWidgets('${entry.key} resolves legacy name $name', (tester) async {
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
              body: ResourceDetailRoute(
                  id: null,
                  type: entry.key,
                  name: name,
                  page: (id) => Text('resolved:$id'))),
        ));
        await tester.pumpAndSettle();
        expect(find.text('resolved:0'), findsOneWidget);
      });
    }
  }
}
