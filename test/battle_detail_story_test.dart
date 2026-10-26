import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/repository/battle_dao.dart';
import 'package:one_piece_battles_flutter/repository/file_dao.dart';
import 'package:one_piece_battles_flutter/repository/image_dao.dart';
import 'package:one_piece_battles_flutter/views/battle/battle_detail_view.dart';

import 'support/resource_detail_fakes.dart';

class _StoryBattleFake extends DetailBattleFake {
  _StoryBattleFake(this.reportStage,
      {this.withFile = false, this.battleStatus = BattleStatus.FINISHED});

  final BattleReportStage reportStage;
  final bool withFile;
  final BattleStatus battleStatus;

  @override
  Future<BattleFullView?> getBattleFullView(
      GetBattleFullViewRequest request) async {
    final original = (await super.getBattleFullView(request))!;
    final battle = BattleFullView.fromJson(jsonDecode(jsonEncode(original)))!;
    battle.starter!.name = I18nText(zhCN: '蒙奇·D·路飞', enUS: 'Monkey D. Luffy');
    battle.receiver!.name = I18nText(zhCN: '罗罗诺亚·索隆', enUS: 'Roronoa Zoro');
    battle.battleExecution!
      ..battleStatus = battleStatus
      ..battleReportStage = reportStage
      ..winnerId = battle.starter!.id
      ..starterScoreBefore = 1840
      ..starterScoreAfter = 1866
      ..receiverScoreBefore = 1770
      ..receiverScoreAfter = 1744
      ..reportFileId = withFile ? 'report-1' : null;
    battle.battleProcessDetails = [
      BattleProcessDetail(
          battleProcessRoundNumber: 1,
          attackSkill: 'Rubber Pistol',
          attackMissed: false,
          attackerEnergyLoss: 6,
          defenderBloodLoss: 34),
      BattleProcessDetail(
          battleProcessRoundNumber: 2,
          attackSkill: 'Three Sword Style',
          attackMissed: true,
          attackerEnergyLoss: 8),
    ];
    return battle;
  }

  @override
  Future<BattleExecution?> getBattleExecution(
          GetBattleExecutionRequest request) async =>
      BattleExecution(
        battleStatus: battleStatus,
        battleReportStage: reportStage,
        reportFileId: withFile ? 'report-1' : null,
      );
}

class _TransitionBattleFake extends _StoryBattleFake {
  _TransitionBattleFake() : super(BattleReportStage.IN_PROGRESS);

  bool firstLoad = true;

  @override
  Future<BattleFullView?> getBattleFullView(
      GetBattleFullViewRequest request) async {
    final battle = (await super.getBattleFullView(request))!;
    if (firstLoad) {
      firstLoad = false;
      battle.battleExecution!
        ..battleStatus = BattleStatus.CREATED
        ..battleReportStage = BattleReportStage.WAITING
        ..winnerId = null;
      battle.battleProcessDetails = [];
    }
    return battle;
  }

  @override
  Future<BattleExecution?> getBattleExecution(
          GetBattleExecutionRequest request) async =>
      BattleExecution(
        battleStatus: BattleStatus.FINISHED,
        battleReportStage: BattleReportStage.IN_PROGRESS,
        winnerId: '0',
        starterScoreBefore: 1840,
        starterScoreAfter: 1866,
        receiverScoreBefore: 1770,
        receiverScoreAfter: 1744,
      );
}

void main() {
  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    GetIt.instance.registerSingleton<User>(User(
      id: 'test',
      username: 'test',
      nickname: 'Test',
      loginRole: UserRole.NIKA,
    ));
    GetIt.instance.registerSingleton<ImageDao>(ImageDao.empty());
    GetIt.instance.registerSingleton<FileDao>(FileDao.empty());
  });
  tearDown(() async => GetIt.instance.reset());

  for (final language in ['zh', 'en']) {
    for (final width in [320.0, 600.0, 820.0, 1280.0]) {
      testWidgets('battle story is readable at $width in $language',
          (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final locale = Locale(language);
        GetIt.instance.registerSingleton<Locale>(locale);
        GetIt.instance.registerSingleton<BattleDao>(
            _StoryBattleFake(BattleReportStage.IN_PROGRESS));
        await tester.pumpWidget(MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: BattleDetailView(battleId: '0')),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byKey(const Key('battle-story')), findsOneWidget);
        expect(find.byKey(const Key('battle-duel')), findsOneWidget);
        expect(find.byKey(const Key('battle-journey')), findsOneWidget);
        expect(find.textContaining('Rubber Pistol'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final story = tester.getRect(find.byKey(const Key('battle-story')));
        expect(story.width, lessThanOrEqualTo(width));
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('ready report exposes download and rematch', (tester) async {
    GetIt.instance.registerSingleton<Locale>(const Locale('en'));
    GetIt.instance.registerSingleton<BattleDao>(
        _StoryBattleFake(BattleReportStage.FINISHED, withFile: true));
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: BattleDetailView(battleId: '0')),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Download Battle Report'), findsOneWidget);
    expect(find.text('Fight Again'), findsOneWidget);
    expect(find.text('Start Battle'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('created battle keeps start as the primary action',
      (tester) async {
    GetIt.instance.registerSingleton<Locale>(const Locale('en'));
    GetIt.instance.registerSingleton<BattleDao>(_StoryBattleFake(
        BattleReportStage.WAITING,
        battleStatus: BattleStatus.CREATED));
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: BattleDetailView(battleId: '0')),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Start Battle'), findsOneWidget);
    expect(find.text('Download Battle Report'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('report without file never exposes a broken download',
      (tester) async {
    GetIt.instance.registerSingleton<Locale>(const Locale('en'));
    GetIt.instance.registerSingleton<BattleDao>(
        _StoryBattleFake(BattleReportStage.FINISHED));
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: BattleDetailView(battleId: '0')),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Download Battle Report'), findsNothing);
    expect(find.text('Preparing the download…'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('polling reveals result and round history when battle finishes',
      (tester) async {
    GetIt.instance.registerSingleton<Locale>(const Locale('en'));
    GetIt.instance.registerSingleton<BattleDao>(_TransitionBattleFake());
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: BattleDetailView(battleId: '0')),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Start Battle'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Start Battle'), findsNothing);
    expect(find.textContaining('Rubber Pistol'), findsOneWidget);
    expect(find.text('Download Battle Report'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
