import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/api.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/repository/fruit_dao.dart';
import 'package:one_piece_battles_flutter/views/fruit/fruit_detail_controller.dart';
import 'package:one_piece_battles_flutter/views/fruit/widgets/fruit_basic_info_section.dart';

Widget localizedApp(Locale locale, Widget child) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('Name drafts stay in their own language when switching an editor',
      (tester) async {
    final fruit = FruitFullView(
      id: 'fruit',
      name: I18nText(zhCN: '橡胶果实', enUS: 'Gum-Gum Fruit'),
      fruitType: FruitType.paramecia,
    );
    final controller = FruitDetailController(fruitDao: FruitDao.empty());
    addTearDown(controller.dispose);
    GetIt.instance.registerSingleton<Locale>(const Locale('en'));
    addTearDown(() => GetIt.instance.reset());
    Widget editor() => FruitBasicInfoSection(
          fruit: fruit,
          controller: controller,
          editButtonVisible: true,
          isNarrow: false,
        );
    await tester.pumpWidget(localizedApp(const Locale('en'), editor()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    final input = find.byType(TextFormField).first;
    expect(
        tester.widget<TextFormField>(input).controller!.text, 'Gum-Gum Fruit');
    await tester.enterText(input, 'EN draft');
    GetIt.instance.unregister<Locale>();
    GetIt.instance.registerSingleton<Locale>(const Locale('zh'));
    await tester.pumpWidget(localizedApp(const Locale('zh'), editor()));
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(input).controller!.text, '橡胶果实');
    await tester.enterText(input, '中文草稿');
    GetIt.instance.unregister<Locale>();
    GetIt.instance.registerSingleton<Locale>(const Locale('en'));
    await tester.pumpWidget(localizedApp(const Locale('en'), editor()));
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(input).controller!.text, 'EN draft');
    expect(fruit.name!.zhCN, '橡胶果实');
    expect(fruit.name!.enUS, 'Gum-Gum Fruit');
  });
}
