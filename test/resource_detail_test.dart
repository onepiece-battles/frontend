import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:one_piece_battles_flutter/components/resource_detail_layout.dart';
import 'package:one_piece_battles_flutter/config/my_input_theme.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/repository/battle_dao.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/repository/fruit_dao.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:one_piece_battles_flutter/repository/image_dao.dart';
import 'package:one_piece_battles_flutter/repository/file_dao.dart';
import 'package:one_piece_battles_flutter/views/character/character_detail_view.dart';
import 'package:one_piece_battles_flutter/views/fruit/fruit_detail_view.dart';
import 'package:one_piece_battles_flutter/views/group/group_detail_view.dart';
import 'package:one_piece_battles_flutter/views/battle/battle_detail_view.dart';
import 'package:one_piece_battles_flutter/views/fruit/widgets/fruit_roster.dart';
import 'package:one_piece_battles_flutter/views/character/character_view.dart';
import 'package:one_piece_battles_flutter/components/desktop_card_layout.dart';
import 'support/resource_detail_fakes.dart';
import 'support/resource_list_fakes.dart';

Widget _app(Widget child, Locale locale) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(inputDecorationTheme: MyInputTheme().theme()),
      home: Scaffold(body: child),
    );

void main() {
  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    GetIt.instance.registerSingleton<User>(User(
        id: 'test',
        username: 'test',
        nickname: 'Test',
        loginRole: UserRole.NIKA));
    GetIt.instance.registerSingleton<CharacterDao>(DetailCharacterFake());
    GetIt.instance.registerSingleton<FruitDao>(DetailFruitFake());
    GetIt.instance.registerSingleton<GroupDao>(DetailGroupFake());
    GetIt.instance.registerSingleton<BattleDao>(DetailBattleFake());
    GetIt.instance.registerSingleton<ImageDao>(ImageDao.empty());
    GetIt.instance.registerSingleton<FileDao>(FileDao.empty());
  });
  tearDown(() async => GetIt.instance.reset());

  final pages = <String, Widget Function()>{
    'character': () => const CharacterDetail(characterId: '0'),
    'fruit': () => const FruitDetailView(fruitId: '0'),
    'group': () => const GroupDetailView(groupId: '0'),
    'battle': () => const BattleDetailView(battleId: '0'),
  };
  for (final language in ['en', 'zh']) {
    for (final width in [600.0, 820.0, 1280.0]) {
      for (final page in pages.entries) {
        testWidgets('${page.key} detail fits $width in $language',
            (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final locale = Locale(language);
          GetIt.instance.registerSingleton<Locale>(locale);
          await tester.pumpWidget(_app(page.value(), locale));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pump();
          expect(find.byType(DetailHero), findsOneWidget);
          expect(tester.takeException(), isNull);
          final scrollable = find
              .descendant(
                  of: find.byType(ResourceDetailPage),
                  matching: find.byType(SingleChildScrollView))
              .first;
          await tester.drag(scrollable, const Offset(0, -2400));
          await tester.pump(const Duration(milliseconds: 400));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }

  for (final narrow in [false, true]) {
    testWidgets(
        'fruit card heights stay equal with and without holders ($narrow)',
        (tester) async {
      tester.view.physicalSize = Size(narrow ? 375 : 800, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      GetIt.instance.registerSingleton<Locale>(const Locale('en'));
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final response = await GetIt.instance<FruitDao>()
          .list(ListFruitRequest(pageSize: 24, pageIndex: 1));
      final fruits = response!.fruits.take(2).toList();
      fruits.last.characters = [
        CharacterInFruitView.fromJson(
            jsonDecode(jsonEncode(sampleCharacter(1))))!
      ];
      final selected = <String>{};
      await tester.pumpWidget(_app(
          SizedBox(
              width: narrow ? 375 : 800,
              child: StatefulBuilder(
                  builder: (context, setState) => FruitRoster(
                        fruits: fruits,
                        controller: controller,
                        expandedRowIds: selected,
                        isNarrow: narrow,
                        onToggleExpand: (id) => setState(() {
                          selected.contains(id)
                              ? selected.remove(id)
                              : selected.add(id);
                        }),
                      ))),
          const Locale('en')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final buttons = find.byWidgetPredicate((widget) => widget is TextButton);
      final first = find.byKey(ValueKey('fruit-card-${fruits.first.id}'),
          skipOffstage: false);
      final second = find.byKey(ValueKey('fruit-card-${fruits.last.id}'));
      final firstCard = tester.getRect(first);
      expect(tester.getSize(second).height, firstCard.height);
      await tester.tap(buttons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(narrow ? BottomSheet : Dialog), findsOneWidget);
      expect(tester.getRect(first), firstCard);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(selected, isEmpty);
    });
  }

  for (final entry in [
    'character-basic',
    'character-combat',
    'fruit-basic',
    'fruit-combat',
    'group-basic'
  ]) {
    testWidgets('$entry editor stays available in the new detail layout',
        (tester) async {
      tester.view.physicalSize = const Size(1100, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      GetIt.instance.registerSingleton<Locale>(const Locale('en'));
      await tester.pumpWidget(
          _app(pages[entry.split('-').first]!(), const Locale('en')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final button =
          find.byType(DetailEditButton).at(entry.endsWith('combat') ? 1 : 0);
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(DetailEditor), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [375.0, 1280.0]) {
    testWidgets('character details do not resize the list card at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      GetIt.instance.registerSingleton<Locale>(const Locale('en'));
      await tester.pumpWidget(_app(const CharacterView(), const Locale('en')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final card = width < 600
          ? find.byType(Card).first
          : find.byType(DesktopSpotlightCard).first;
      final rect = tester.getRect(card);
      final loc = AppLocalizations.of(tester.element(card))!;
      await tester.tap(find.byTooltip(loc.detailInformation).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(width < 600 ? BottomSheet : Dialog), findsOneWidget);
      expect(tester.getRect(card), rect);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    });
  }
}
