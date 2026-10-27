import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/components/resource_flip_card.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/views/character/widgets/character_desktop_roster.dart';
import 'package:one_piece_battles_flutter/views/character/widgets/character_mobile_roster.dart';
import 'package:one_piece_battles_flutter/views/fruit/widgets/fruit_roster.dart';
import 'package:openapi/api.dart';

CharacterListView _character() => CharacterListView(
      id: 'luffy',
      name: I18nText(zhCN: '路飞', enUS: 'Luffy'),
      maximumFruitCount: 2,
      score: 9000,
      baseGroupGain: 100,
      baseAttack: 200,
      baseDefense: 180,
      baseIntelligence: 90,
      baseBlood: 3000,
      baseSpeed: 120,
      attack: 400,
      defense: 350,
      intelligence: 110,
      blood: 8000,
      speed: 210,
      groupGain: 130,
      energy: 240,
      battleStyle: BattleStyle.BODY,
      race: Race.HUMAN,
      bounty: 3000000000,
      imageUri: '',
      hakis: [Haki.busoshoku, Haki.kenbunshoku, Haki.haoshoku],
    );

FruitListView _fruit() => FruitListView(
      id: 'fruit-1',
      name: I18nText(zhCN: '橡胶果实', enUS: 'Gum-Gum Fruit'),
      fruitType: FruitType.paramecia,
      attackSlope: 1.2,
      attackIntercept: 30,
      defenseSlope: 1.4,
      defenseIntercept: -10,
      bloodSlope: 1.0,
      bloodIntercept: 0,
      intelligenceSlope: 1.05,
      intelligenceIntercept: 5,
      speedSlope: 1.1,
      speedIntercept: 12,
      groupGainSlope: 1.5,
      groupGainIntercept: 20,
      energyConsume: 25,
    );

final _styleMap = {BattleStyle.BODY: '体术'};
final _raceMap = {Race.HUMAN: '人类'};
final _hakiMap = {
  Haki.busoshoku: '武装色',
  Haki.kenbunshoku: '见闻色',
  Haki.haoshoku: '霸王色',
};

Widget _host(Widget Function(BuildContext) content) {
  final router = GoRouter(routes: [
    GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(body: content(context))),
    GoRoute(
      path: '/character/:name',
      name: 'characterDetails',
      builder: (context, state) => const Scaffold(body: Text('character page')),
    ),
    GoRoute(
      path: '/fruit/:name',
      name: 'fruitDetails',
      builder: (context, state) => const Scaffold(body: Text('fruit page')),
    ),
  ]);
  return MaterialApp.router(
    routerConfig: router,
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

void main() {
  setUp(() {
    if (GetIt.instance.isRegistered<Locale>()) {
      GetIt.instance.unregister<Locale>();
    }
    GetIt.instance.registerSingleton<Locale>(const Locale('zh'));
  });
  tearDown(() {
    if (GetIt.instance.isRegistered<Locale>()) {
      GetIt.instance.unregister<Locale>();
    }
  });

  testWidgets('character card flips in place on mobile and returns to front',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final flipped = <String>{};
    await tester.pumpWidget(_host((context) => StatefulBuilder(
          builder: (context, setState) => CharacterMobileRoster(
            characters: [_character()],
            scrollController: ScrollController(),
            battleStyleMap: _styleMap,
            raceMap: _raceMap,
            hakiMap: _hakiMap,
            expandedRowIds: flipped,
            onToggleExpand: (id) => setState(() {
              if (!flipped.remove(id)) flipped.add(id);
            }),
          ),
        )));
    await tester.pump();
    final card = find.byType(ResourceFlipCard);
    final before = tester.getSize(card);
    // ignore: avoid_print
    print('first face: ${tester.widgetList<Text>(find.byType(Text)).map((text) => text.data).toList()}');
    expect(find.text('武装色'), findsOneWidget);
    await tester.tap(find.text('详细信息'));
    await tester.pump(const Duration(milliseconds: 210));
    expect(tester.getSize(card), before);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('攻击力'), findsOneWidget);
    expect(find.text('400'), findsOneWidget);
    expect(find.text('精力值'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(tester.getSize(card), before);
    await tester.tap(find.byTooltip('翻回正面'));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('武装色'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop character card keeps tags and back metrics readable',
      (tester) async {
    tester.view.physicalSize = const Size(320, 650);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final flipped = <String>{};
    await tester.pumpWidget(_host((context) => StatefulBuilder(
          builder: (context, setState) => CharacterDesktopRoster(
            characters: [_character()],
            totalItemCount: 1,
            scrollController: ScrollController(),
            battleStyleMap: _styleMap,
            raceMap: _raceMap,
            hakiMap: _hakiMap,
            expandedRowIds: flipped,
            onToggleExpand: (id) => setState(() {
              if (!flipped.remove(id)) flipped.add(id);
            }),
            scoreOrder: null,
            onScoreSortTap: () {},
          ),
        )));
    await tester.pump();
    expect(find.text('霸王色'), findsOneWidget);
    await tester.tap(find.text('详细信息'));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('果实数上限'), findsOneWidget);
    expect(find.text('团体增益 (%)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fruit card shows compact signed formulas and opens full page',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final flipped = <String>{};
    await tester.pumpWidget(_host((context) => StatefulBuilder(
          builder: (context, setState) => FruitRoster(
            fruits: [_fruit()],
            controller: ScrollController(),
            expandedRowIds: flipped,
            onToggleExpand: (id) => setState(() {
              if (!flipped.remove(id)) flipped.add(id);
            }),
            isNarrow: true,
          ),
        )));
    await tester.pump();
    expect(find.text('暂无持有者'), findsOneWidget);
    final before = tester.getSize(find.byType(ResourceFlipCard));
    await tester.tap(find.text('详细信息'));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('1.2× + 30'), findsOneWidget);
    expect(find.text('1.4× − 10'), findsOneWidget);
    expect(find.text('1×'), findsOneWidget);
    expect(tester.getSize(find.byType(ResourceFlipCard)), before);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('查看完整详情'));
    await tester.pump();
    expect(find.text('fruit page'), findsOneWidget);
  });

  testWidgets('fruit back fits a narrow desktop grid card', (tester) async {
    tester.view.physicalSize = const Size(320, 650);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final flipped = <String>{};
    await tester.pumpWidget(_host((context) => StatefulBuilder(
          builder: (context, setState) => FruitRoster(
            fruits: [_fruit()],
            controller: ScrollController(),
            expandedRowIds: flipped,
            onToggleExpand: (id) => setState(() {
              if (!flipped.remove(id)) flipped.add(id);
            }),
            isNarrow: false,
          ),
        )));
    await tester.pump();
    await tester.tap(find.text('详细信息'));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('精力消耗'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
