import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openapi/api.dart';
import 'package:one_piece_battles_flutter/combat/combat_api.dart';
import 'package:one_piece_battles_flutter/combat/combat_labels.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/views/character/widgets/character_skills_section.dart';
import 'package:one_piece_battles_flutter/views/battle/widgets/battle_detail_widgets.dart';

CombatProfile sample() => CombatProfile({
      'version': 2,
      'era': '和之国',
      'coatingLevel': 0,
      'skills': [
        {
          'id': 'marco.regeneration',
          'name': '再生之炎',
          'englishName': 'Phoenix regeneration',
          'origin': 'FRUIT',
          'target': 'SELF',
          'energy': 14,
          'cooldown': 4,
          'maxUses': 3,
          'healthBelow': .7,
          'effects': [
            {'type': 'HEAL', 'power': .24, 'duration': 0}
          ]
        }
      ]
    });

class FakeCombatApi extends CombatApi {
  FakeCombatApi() : super(ApiClient());
  Future<CombatProfile?> Function(String) fetch = (_) async => sample();
  @override
  Future<CombatProfile?> profile(String id) => fetch(id);
}

Future<void> pump(WidgetTester tester, Widget child,
    {String lang = 'zh', double width = 800}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
      locale: Locale(lang),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: SingleChildScrollView(child: child))));
  await tester.pump();
}

void main() {
  setUp(() => GetIt.instance.reset());
  tearDown(() => GetIt.instance.reset());
  testWidgets(
      'shows version, cost, eligibility and healing basis without treating it as an attack',
      (tester) async {
    GetIt.instance.registerSingleton<CombatApi>(FakeCombatApi());
    await pump(tester, const CharacterSkillsSection(characterId: 'marco'));
    await tester.pumpAndSettle();
    expect(find.text('战斗技能'), findsOneWidget);
    expect(find.textContaining('版本 2'), findsOneWidget);
    expect(find.textContaining('冷却 4 次自身行动'), findsOneWidget);
    await tester.tap(find.text('再生之炎'));
    await tester.pumpAndSettle();
    expect(find.text('回复血量 24% 基于最大血量'), findsOneWidget);
    expect(find.text('自身血量不高于 70% 时可用'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('small screens and English remain readable', (tester) async {
    GetIt.instance.registerSingleton<CombatApi>(FakeCombatApi());
    await pump(tester, const CharacterSkillsSection(characterId: 'marco'),
        lang: 'en', width: 320);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phoenix regeneration'));
    await tester.pumpAndSettle();
    expect(find.textContaining('of max HP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('loading has a progress line and failed requests can retry',
      (tester) async {
    final api = FakeCombatApi();
    final pending = Completer<CombatProfile?>();
    api.fetch = (_) => pending.future;
    GetIt.instance.registerSingleton<CombatApi>(api);
    await pump(tester, const CharacterSkillsSection(characterId: 'marco'));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    pending.completeError(StateError('network'));
    await tester.pumpAndSettle();
    expect(find.text('暂时无法加载技能'), findsOneWidget);
    api.fetch = (_) async => sample();
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(find.text('再生之炎'), findsOneWidget);
  });
  testWidgets(
      'healing rounds show actual healing rather than a hit with zero damage',
      (tester) async {
    final round = BattleProcessDetail(
        battleProcessRoundNumber: 1,
        attackSkill: '再生之炎',
        attackMissed: false,
        attackerEnergyLoss: 18,
        defenderBloodLoss: 0,
        defenderEnergyLoss: 0);
    final event = CombatEvent({
      'round': 1,
      'actor': 'marco',
      'label': '再生之炎',
      'missed': false,
      'effects': [
        {'type': 'HEAL', 'amount': 960, 'unit': 'HP'}
      ]
    });
    await pump(
        tester,
        BattleRounds(
            details: [round],
            battleStatus: BattleStatus.FINISHED,
            actorNames: const {'marco': '马尔高'},
            events: {1: event}));
    expect(find.text('马尔高'), findsOneWidget);
    expect(find.textContaining('回复血量 960'), findsOneWidget);
    final l = AppLocalizations.of(tester.element(find.byType(BattleRounds)))!;
    expect(find.textContaining(l.battleAttackHit), findsNothing);
    expect(find.textContaining('${l.battleDamage} 0'), findsNothing);
  });
  testWidgets(
      'status facts preserve fractional percentages and action duration',
      (tester) async {
    await pump(tester, const Text('status'));
    final l = AppLocalizations.of(tester.element(find.text('status')))!;
    final poison = combatOutcomeLabel(l, {
      'type': 'POISON',
      'amount': 250,
      'unit': 'BASIS_POINTS',
      'duration': 3
    });
    expect(poison, contains('2.5%'));
    expect(poison, contains(l.combatEffectDuration(3)));
    expect(
        combatOutcomeLabel(l, {'type': 'IMMUNE', 'amount': 0, 'unit': 'NONE'}),
        l.combatImmune);
  });
  test(
      'API retains bearer authentication and supports legacy servers without combat records',
      () async {
    final auth = HttpBearerAuth()..accessToken = 'test-token';
    final client = ApiClient(authentication: auth);
    client.client = MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer test-token');
      return http.Response(jsonEncode({'snapshot': null, 'events': []}), 200);
    });
    expect(await CombatApi(client).record('old-battle'), isNull);
    client.client = MockClient((request) async => http.Response('', 404));
    expect(await CombatApi(client).profile('old-character'), isNull);
  });
}
