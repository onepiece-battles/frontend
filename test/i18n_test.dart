import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/api.dart';
import 'package:one_piece_battles_flutter/components/page_foot.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/utils/date_helper.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:one_piece_battles_flutter/utils/time_helper.dart';

Widget localizedApp(Locale locale, Widget child) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  test('Chinese and English catalogs have matching nonempty entries', () {
    Map<String, dynamic> catalog(String language) =>
        jsonDecode(File('lib/l10n/app_$language.arb').readAsStringSync());
    final en = catalog('en');
    final zh = catalog('zh');
    final keys = en.keys.where((key) => !key.startsWith('@')).toSet();
    expect(zh.keys.where((key) => !key.startsWith('@')).toSet(), keys);
    for (final key in keys) {
      expect((en[key] as String).trim(), isNotEmpty, reason: 'en: $key');
      expect((zh[key] as String).trim(), isNotEmpty, reason: 'zh: $key');
    }
  });

  test('English language variants map to the English API locale', () {
    for (final locale in [const Locale('en'), const Locale('en', 'GB')]) {
      expect(I18nHelper.convertToOnepieceLocale(locale), OnepieceLocale.enUS);
    }
    expect(I18nHelper.convertToOnepieceLocale(const Locale('zh', 'CN')),
        OnepieceLocale.zhCN);
  });

  test('Display falls back to available content; editing never copies it', () {
    final text = I18nText(zhCN: '路飞', enUS: '  ');
    expect(I18nHelper.getDisplayNameFromI18nByLocale(text, const Locale('en')),
        '路飞');
    expect(I18nHelper.getEditableNameFromI18n(text, const Locale('en')), '  ');
    expect(
        I18nHelper.getDisplayNameFromI18nByLocale(
            I18nText(enUS: 'Luffy'), const Locale('zh')),
        'Luffy');
    expect(I18nHelper.getDisplayNameFromI18nByLocale(null, const Locale('en')),
        isEmpty);
  });

  test('Counts use English plurals and Chinese classifiers', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final zh = await AppLocalizations.delegate.load(const Locale('zh'));
    expect(en.characterCount(1), '1 character');
    expect(en.characterCount(2), '2 characters');
    expect(en.fruitCount(0), '0 Devil Fruits');
    expect(en.userCount(1), '1 user');
    expect(en.issueCount(2), '2 feedback items');
    expect(en.relatedBattleCount(1), '1 related battle');
    expect(zh.characterCount(2), '2 个角色');
    expect(zh.issueCount(2), '2 条反馈');
  });

  testWidgets('Pagination labels update when switching languages',
      (tester) async {
    final footer =
        PageFoot(currentPage: 2, totalPages: 5, onPageChanged: (_) {});
    await tester.pumpWidget(localizedApp(const Locale('en'), footer));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Previous Page'), findsOneWidget);
    expect(find.byTooltip('Next Page'), findsOneWidget);
    expect(find.text('Jump'), findsOneWidget);
    await tester.pumpWidget(localizedApp(const Locale('zh'), footer));
    await tester.pumpAndSettle();
    expect(find.byTooltip('上一页'), findsOneWidget);
    expect(find.byTooltip('下一页'), findsOneWidget);
    expect(find.text('前往'), findsOneWidget);
    expect(find.byTooltip('Previous Page'), findsNothing);
  });

  testWidgets('Dates follow the active UI language', (tester) async {
    String date = '';
    String chatDate = '';
    final timestamp = DateTime(2020, 3, 15, 15, 30).millisecondsSinceEpoch;
    Widget content() => Builder(builder: (context) {
          date =
              DateHelper.getFormattedDatetimeFromTimestamp(timestamp, context);
          chatDate = TimeHelper.humanDateFromTimestamp(timestamp, context);
          return const SizedBox();
        });
    await tester.pumpWidget(localizedApp(const Locale('en'), content()));
    await tester.pumpAndSettle();
    expect(chatDate, contains('Mar'));
    final englishDate = date;
    await tester.pumpWidget(localizedApp(const Locale('zh'), content()));
    await tester.pumpAndSettle();
    expect(chatDate, contains('月'));
    expect(date, startsWith('2020'));
    expect(date, isNot(englishDate));
  });
}
