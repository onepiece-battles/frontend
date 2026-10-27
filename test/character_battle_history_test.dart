import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/views/character/widgets/character_battles_section.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'support/resource_list_fakes.dart';

void main() {
  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    GetIt.instance.registerSingleton<Locale>(const Locale('en'));
  });
  tearDown(() async => GetIt.instance.reset());

  for (final width in [375.0, 1100.0]) {
    testWidgets('battle history stays readable and expands at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final character = CharacterFullView.fromJson(
          jsonDecode(jsonEncode(sampleCharacter(0))))!;
      final response = await ListBattleFake()
          .listBattles(ListBattleRequest(pageSize: 24, pageIndex: 1));
      character.battles = response!.battles.take(12).toList();
      for (var i = 0; i < character.battles.length; i++) {
        character.battles[i].id = '$i';
      }
      character.battles[0].battleExecution = BattleExecution(
          battleStatus: BattleStatus.FINISHED,
          winnerId: character.id,
          starterScoreBefore: 9000,
          starterScoreAfter: 9025,
          winnerScoreChange: 25);
      character.battles[1].battleExecution = BattleExecution(
          battleStatus: BattleStatus.FINISHED,
          winnerId: '1',
          starterScoreBefore: 9025,
          starterScoreAfter: 9010,
          loserScoreChange: -15);
      character.battles[2].battleExecution = null;

      await tester.pumpWidget(MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
              body: SingleChildScrollView(
                  child: CharacterBattlesSection(
                      character: character, isNarrow: width < 600)))));
      await tester.pump();
      expect(find.text('Won'), findsOneWidget);
      expect(find.text('Lost'), findsOneWidget);
      expect(find.text('+25'), findsOneWidget);
      expect(find.text('−15'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(10));
      expect(tester.takeException(), isNull);

      final more = find.text('Show more battles');
      await tester.ensureVisible(more);
      await tester.tap(more);
      await tester.pump();
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(12));
      expect(find.text('Show fewer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
