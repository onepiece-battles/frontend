import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:one_piece_battles_flutter/components/desktop_card_layout.dart';
import 'package:one_piece_battles_flutter/config/my_input_theme.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_tag.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/repository/fruit_dao.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:one_piece_battles_flutter/repository/battle_dao.dart';
import 'package:one_piece_battles_flutter/views/character/character_view.dart';
import 'package:one_piece_battles_flutter/views/character/widgets/character_mobile_roster.dart';
import 'package:one_piece_battles_flutter/views/character/widgets/character_desktop_roster.dart';
import 'package:one_piece_battles_flutter/views/fruit/fruit_view.dart';
import 'package:one_piece_battles_flutter/views/fruit/widgets/fruit_roster.dart';
import 'package:one_piece_battles_flutter/views/group/group_view.dart';
import 'package:one_piece_battles_flutter/views/group/widgets/group_roster.dart';
import 'package:one_piece_battles_flutter/views/battle/battle_view.dart';
import 'package:one_piece_battles_flutter/views/battle/widgets/battle_roster.dart';
import 'support/resource_list_fakes.dart';

void main() {
  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    GetIt.instance.registerSingleton<User>(User(
        id: 'test',
        username: 'test',
        nickname: 'Test',
        loginRole: UserRole.NIKA));
    GetIt.instance.registerSingleton<CharacterDao>(ListCharacterFake());
    GetIt.instance.registerSingleton<FruitDao>(ListFruitFake());
    GetIt.instance.registerSingleton<GroupDao>(ListGroupFake());
    GetIt.instance.registerSingleton<BattleDao>(ListBattleFake());
  });
  tearDown(() async => GetIt.instance.reset());
  final views = <String, Widget Function()>{
    'character': () => const CharacterView(),
    'fruit': () => const FruitView(),
    'group': () => const GroupView(),
    'battle': () => const BattleView(),
  };
  for (final language in ['zh', 'en']) {
    for (final width in [375.0, 820.0, 1280.0]) {
      for (final view in views.entries) {
        testWidgets('${view.key} prioritizes records at $width in $language',
            (tester) async {
          tester.view.physicalSize = Size(width, 740);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final locale = Locale(language);
          GetIt.instance.registerSingleton<Locale>(locale);
          await tester.pumpWidget(MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(inputDecorationTheme: MyInputTheme().theme()),
            home: Scaffold(body: view.value()),
          ));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pump();
          final roster = find.byWidgetPredicate((widget) =>
              widget is CharacterMobileRoster ||
              widget is CharacterDesktopRoster ||
              widget is FruitRoster ||
              widget is GroupRoster ||
              widget is BattleRoster);
          expect(tester.getSize(roster).height, greaterThan(580));
          final loc = AppLocalizations.of(tester.element(roster))!;
          if (view.key == 'character' || view.key == 'fruit') {
            final label =
                view.key == 'character' ? loc.busoshoku : loc.parameciaFruit;
            final expectedColor = view.key == 'character'
                ? OnepieceTag.hakiToColor[Haki.busoshoku]
                : OnepieceTag.fruitTypeToColor[FruitType.paramecia];
            expect(
                find.ancestor(
                    of: find.text(label).first,
                    matching: find.byWidgetPredicate((widget) =>
                        widget is Container &&
                        widget.decoration is BoxDecoration &&
                        (widget.decoration as BoxDecoration).color ==
                            expectedColor)),
                findsOneWidget);
          }
          if (view.key == 'character') {
            final bounty = find.byWidgetPredicate((widget) =>
                widget is Text &&
                (widget.data ?? widget.textSpan?.toPlainText() ?? '')
                    .contains('3000000000'));
            final text = tester.widget<Text>(bounty.first);
            final style = text.data != null
                ? text.style
                : ((text.textSpan as TextSpan).children!.last as TextSpan)
                    .style;
            expect(style?.fontFamily, 'Lobster');
            expect(style?.color, OnepieceFonts.bountyStyle.color);
          }
          final viewport = tester.getRect(roster);
          final desktopCards = find.descendant(
              of: roster, matching: find.byType(DesktopSpotlightCard));
          final cards = desktopCards.evaluate().isNotEmpty
              ? desktopCards
              : find.descendant(of: roster, matching: find.byType(Card));
          final fullyVisible = cards.evaluate().where((element) {
            final rect = tester.getRect(find.byWidget(element.widget));
            return rect.top >= viewport.top && rect.bottom <= viewport.bottom;
          }).length;
          expect(fullyVisible, greaterThanOrEqualTo(width < 1000 ? 4 : 12),
              reason:
                  'Viewport: $viewport; first card: ${tester.getSize(cards.first)}');
          expect(tester.takeException(), isNull);
          expect(
              (GetIt.instance<CharacterDao>() as ListCharacterFake).pageSize ??
                  (GetIt.instance<FruitDao>() as ListFruitFake).pageSize ??
                  (GetIt.instance<GroupDao>() as ListGroupFake).pageSize ??
                  (GetIt.instance<BattleDao>() as ListBattleFake).pageSize,
              24);
          final filters = find.byType(ListFilterButton);
          final filterButton = filters.evaluate().isEmpty
              ? find.byIcon(Icons.filter_list)
              : filters;
          expect(find.text(loc.myResource), findsNothing);
          await tester.tap(filterButton);
          await tester.pump();
          expect(find.text(loc.myResource), findsOneWidget);
          await tester.tap(find.text(loc.myResource));
          await tester.pump();
          await tester.tap(filterButton);
          await tester.pump();
          expect(find.text(loc.myResource), findsNothing);
          if (view.key == 'group') {
            expect(
                (GetIt.instance<GroupDao>() as ListGroupFake).userId, 'test');
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
