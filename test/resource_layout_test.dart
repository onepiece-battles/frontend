import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';
import 'package:one_piece_battles_flutter/components/desktop_card_layout.dart';
import 'package:one_piece_battles_flutter/config/my_input_theme.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/repository/battle_dao.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/repository/fruit_dao.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:one_piece_battles_flutter/repository/image_dao.dart';
import 'package:one_piece_battles_flutter/views/battle/create_battle_view.dart';
import 'package:one_piece_battles_flutter/views/character/create_character_view.dart';
import 'package:one_piece_battles_flutter/views/fruit/create_fruit_view.dart';
import 'package:one_piece_battles_flutter/views/fruit/widgets/fruit_roster.dart';
import 'package:one_piece_battles_flutter/views/group/create_group_view.dart';

class _CharacterDao extends CharacterDao {
  _CharacterDao() : super.empty();

  @override
  Future<ListCharacterResponse?> listCharacter(
      ListCharacterRequest request) async {
    return ListCharacterResponse(characters: []);
  }
}

Widget _app(Widget child, Locale locale) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(inputDecorationTheme: MyInputTheme().theme()),
      home: Scaffold(body: child),
    );

void main() {
  setUp(() {
    GetIt.instance.registerSingleton<User>(User(
        id: 'test',
        username: 'test',
        nickname: 'Test',
        loginRole: UserRole.NIKA));
    GetIt.instance.registerSingleton<CharacterDao>(_CharacterDao());
    GetIt.instance.registerSingleton<BattleDao>(BattleDao.empty());
    GetIt.instance.registerSingleton<FruitDao>(FruitDao.empty());
    GetIt.instance.registerSingleton<GroupDao>(GroupDao.empty());
    GetIt.instance.registerSingleton<ImageDao>(ImageDao.empty());
  });
  tearDown(() async => GetIt.instance.reset());

  final forms = <String, Widget Function()>{
    'character': () => const CreateCharacterView(),
    'fruit': () => const CreateFruitView(),
    'group': () => const CreateGroupView(),
    'battle': () => const CreateBattleView(),
  };
  for (final language in ['en', 'zh']) {
    for (final width in [375.0, 820.0, 1280.0]) {
      for (final form in forms.entries) {
        testWidgets('${form.key} fits $width in $language', (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final locale = Locale(language);
          GetIt.instance.registerSingleton<Locale>(locale);
          await tester.pumpWidget(_app(form.value(), locale));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final scrollable = find.byType(SingleChildScrollView).first;
          await tester.drag(scrollable, const Offset(0, -2000));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('resource grid uses one column in a narrow content pane',
      (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(
        SizedBox(
            width: 500,
            child: DesktopSpotlightGrid<int>(
              items: const [1, 2],
              idOf: (item) => '$item',
              controller: controller,
              cardBuilder: (context, item) => SizedBox(
                key: ValueKey('card-$item'),
                height: 140,
                child: Text('Resource $item'),
              ),
            )),
        const Locale('en')));
    final first = tester.getRect(find.byKey(const ValueKey('card-1')));
    final second = tester.getRect(find.byKey(const ValueKey('card-2')));
    expect(first.left, second.left);
    expect(second.top, greaterThanOrEqualTo(first.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid fruit form scrolls back to the first missing field',
      (tester) async {
    GetIt.instance.registerSingleton<Locale>(const Locale('en'));
    await tester.pumpWidget(_app(const CreateFruitView(), const Locale('en')));
    await tester.pumpAndSettle();
    final scrollable = find.byType(SingleChildScrollView).first;
    await tester.drag(scrollable, const Offset(0, -2500));
    await tester.pumpAndSettle();
    final formContext = tester.element(find.byType(Form));
    final loc = AppLocalizations.of(formContext)!;
    await tester.tap(find.text(loc.submitForm));
    await tester.pumpAndSettle();
    final firstField = find.byType(TextFormField).first;
    expect(tester.getRect(firstField).top, greaterThanOrEqualTo(0));
    expect(tester.getRect(firstField).bottom, lessThan(600));
    expect(find.text(loc.requiredField), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fruit card flip shows all six attribute formulas',
      (tester) async {
    GetIt.instance.registerSingleton<Locale>(const Locale('en'));
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final expandedIds = <String>{};
    final fruit = FruitListView(
      id: 'fruit',
      name: I18nText(enUS: 'A fruit with a long descriptive name'),
      fruitType: FruitType.paramecia,
      attackSlope: 1,
      attackIntercept: 10,
      defenseSlope: 1,
      defenseIntercept: 20,
      bloodSlope: 1,
      bloodIntercept: 30,
      intelligenceSlope: 1,
      intelligenceIntercept: 40,
      speedSlope: 1,
      speedIntercept: 50,
      groupGainSlope: 1,
      groupGainIntercept: 60,
    );
    await tester.pumpWidget(_app(
        SizedBox(
            width: 420,
            child: StatefulBuilder(builder: (context, setState) {
              return FruitRoster(
                fruits: [fruit],
                controller: controller,
                isNarrow: false,
                expandedRowIds: expandedIds,
                onToggleExpand: (id) => setState(() {
                  expandedIds.contains(id)
                      ? expandedIds.remove(id)
                      : expandedIds.add(id);
                }),
              );
            })),
        const Locale('en')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.flip_to_back_outlined));
    await tester.pumpAndSettle();
    expect(expandedIds, contains('fruit'));
    for (final intercept in [10, 20, 30, 40, 50, 60]) {
      expect(find.textContaining('× + $intercept'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
