import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';
import 'package:one_piece_battles_flutter/ai/assistant_action_card.dart';
import 'package:one_piece_battles_flutter/ai/assistant_api.dart';
import 'package:one_piece_battles_flutter/ai/assistant_message.dart';
import 'package:one_piece_battles_flutter/ai/assistant_session.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/views/assistant/assistant_view.dart';

const _code = 'A26E0854B6';
const _summary =
    '待确认操作：创建战斗（尚不开始）\n- [波鲁萨利诺](onepiece://character/kizaru)\n- [马尔高](onepiece://character/marco)';
AiActionProposal _proposal({String status = 'pending', DateTime? expiresAt}) =>
    AiActionProposal(
      code: _code,
      operation: 'create_battle',
      title: '创建战斗（尚不开始）',
      summary: _summary,
      status: status,
      expiresAt: expiresAt ?? DateTime.now().add(const Duration(minutes: 15)),
      resources: status == 'completed'
          ? const [AiResourceLink('battle', 'battle-created', '波鲁萨利诺 vs 马尔高')]
          : const [],
    );

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    );
String _visible(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.textSpan?.toPlainText() ?? t.data ?? '')
    .join(' ');

class _Api extends AssistantApi {
  _Api(this.history) : super(ApiClient());
  final List<AiStoredMessage> history;
  final answers = StreamController<AssistantEvent>();
  final questions = <String>[];
  @override
  Future<List<AiStoredMessage>> listMessages() async => history;
  @override
  Stream<AssistantEvent> ask(String message, {String? language}) {
    questions.add(message);
    return answers.stream;
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump();
  }
}

void main() {
  test(
      'new done/history payloads keep typed proposals; older payloads still parse',
      () {
    final raw = {
      'messageId': 'reply',
      'content': '提案',
      'actionProposals': [
        {
          'code': _code,
          'operation': 'create_battle',
          'title': '创建战斗',
          'summary': _summary,
          'status': 'pending',
          'expiresAt': DateTime.now()
              .add(const Duration(minutes: 15))
              .millisecondsSinceEpoch,
          'resources': <Object>[],
        }
      ],
    };
    final event = AssistantEvent.fromJson('done', raw) as AssistantDone;
    expect(event.actionProposals.single.code, _code);
    expect(
        AiStoredMessage.fromJson({...raw, 'role': 'assistant'})
            .actionProposals
            .single
            .summary,
        _summary);
    expect(
        (AssistantEvent.fromJson('done', {'content': 'older'}) as AssistantDone)
            .actionProposals,
        isEmpty);
    expect(
        AiActionProposal.listFromJson([
          {'code': 'fake', 'expiresAt': 0}
        ]),
        isEmpty);
  });

  test(
      'only the exact proposal appendix is moved to its card; analysis remains',
      () {
    const original =
        '速度与攻击对比保留。\n\n$_summary\n\n尚未执行。15 分钟内发送 **确认 $_code** 执行。';
    final message =
        AiChatMessage('assistant', original, actionProposals: [_proposal()]);
    expect(message.displayText, '速度与攻击对比保留。');
    expect(message.text, original);
    expect(
        AiChatMessage('assistant', '其他分析。', actionProposals: [_proposal()])
            .displayText,
        '其他分析。');
  });

  test(
      'button commands have readable labels while their stored payload remains exact',
      () {
    final session = AssistantSession();
    session.messages
        .add(AiChatMessage('assistant', '提案', actionProposals: [_proposal()]));
    expect(session.displayCommand('确认 $_code', zh: true), '确认：创建战斗（尚不开始）');
    expect(session.displayCommand('取消 $_code', zh: true), '取消：创建战斗（尚不开始）');
    expect(
        session.displayCommand('解释确认 $_code 的含义', zh: true), '解释确认 $_code 的含义');
    expect(session.displayCommand('确认 0000000000', zh: true), '确认 0000000000');
    session.dispose();
  });

  testWidgets('mobile card keeps both participants and never auto-confirms',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var confirmed = 0, cancelled = 0;
    await tester.pumpWidget(_app(AssistantActionCard(
        proposal: _proposal(),
        busy: false,
        onConfirm: () => confirmed++,
        onCancel: () => cancelled++,
        onResource: (a, b, c) {})));
    expect(confirmed, 0);
    expect(cancelled, 0);
    expect(_visible(tester), contains('波鲁萨利诺'));
    expect(_visible(tester), contains('马尔高'));
    expect(_visible(tester), contains('不会自动开打'));
    await tester.tap(find.text('确认创建'));
    expect(confirmed, 1);
    await tester.tap(find.text('取消'));
    expect(cancelled, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'expired or busy cards cannot execute; completed card opens the actual battle',
      (tester) async {
    var confirmed = 0;
    final opened = <String>[];
    Widget card(AiActionProposal p, {bool busy = false}) =>
        _app(AssistantActionCard(
            proposal: p,
            busy: busy,
            onConfirm: () => confirmed++,
            onCancel: () {},
            onResource: (type, id, name) => opened.add('$type/$id')));
    await tester.pumpWidget(card(_proposal(), busy: true));
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    await tester.pumpWidget(card(
        _proposal(expiresAt: DateTime.now().add(const Duration(seconds: 1)))));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('已过期'), findsOneWidget);
    expect(find.text('确认创建'), findsNothing);
    expect(confirmed, 0);
    await tester.pumpWidget(card(_proposal(status: 'completed')));
    expect(_visible(tester), contains('波鲁萨利诺'));
    expect(_visible(tester), contains('马尔高'));
    await tester.tap(find.text('查看战斗'));
    expect(opened, ['battle/battle-created']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'restored proposal confirms through the server then retains a battle detail entry',
      (tester) async {
    final api = _Api([
      AiStoredMessage(
          id: 'old',
          role: 'assistant',
          content: '对比信息。\n\n$_summary\n\n确认 $_code',
          resources: const [],
          actionProposals: [_proposal()])
    ]);
    final session = AssistantSession();
    GetIt.instance
      ..registerSingleton<AssistantApi>(api)
      ..registerSingleton<AssistantSession>(session);
    addTearDown(() => GetIt.instance.reset());
    final router = GoRouter(routes: [
      GoRoute(
          path: '/', builder: (c, s) => const Scaffold(body: AssistantView())),
      GoRoute(
          path: '/battle/:id',
          name: 'battleDetails',
          builder: (c, s) =>
              Scaffold(body: Text('Battle ${s.pathParameters['id']}'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates));
    await _settle(tester);
    expect(find.text('确认创建'), findsOneWidget);
    await tester.ensureVisible(find.text('确认创建'));
    await tester.tap(find.text('确认创建'));
    await _settle(tester);
    expect(api.questions, ['确认 $_code']);
    expect(session.busy, isTrue);
    await tester.tap(find.text('确认创建'));
    expect(api.questions, ['确认 $_code']);
    api.answers.add(AssistantDone(
        messageId: 'created',
        content: '已完成：创建战斗',
        actionProposals: [
          _proposal(status: 'completed')
        ],
        resources: const [
          AiResourceLink('battle', 'battle-created', '波鲁萨利诺 vs 马尔高')
        ]));
    await api.answers.close();
    await _settle(tester);
    expect(session.messages.first.actionProposals.single.status, 'completed');
    expect(find.text('确认创建'), findsNothing);
    expect(find.text('查看战斗'), findsOneWidget);
    await tester.ensureVisible(find.text('查看战斗'));
    await tester.tap(find.text('查看战斗'));
    await tester.pumpAndSettle();
    expect(find.text('Battle battle-created'), findsOneWidget);
  });
  testWidgets('cancel submits the server command and leaves no creation action',
      (tester) async {
    final api = _Api(const []);
    final session = AssistantSession()..loaded = true;
    session.messages.add(
        AiChatMessage('assistant', '对比信息。', actionProposals: [_proposal()]));
    GetIt.instance
      ..registerSingleton<AssistantApi>(api)
      ..registerSingleton<AssistantSession>(session);
    addTearDown(() => GetIt.instance.reset());
    await tester.pumpWidget(_app(const AssistantView()));
    await _settle(tester);
    await tester.ensureVisible(find.text('取消'));
    await tester.tap(find.text('取消'));
    await _settle(tester);
    expect(api.questions, ['取消 $_code']);
    api.answers.add(AssistantDone(
        messageId: 'cancelled',
        content: '已取消，没有修改数据。',
        actionProposals: [_proposal(status: 'cancelled')]));
    await api.answers.close();
    await _settle(tester);
    expect(session.messages.first.actionProposals.single.status, 'cancelled');
    expect(find.text('确认创建'), findsNothing);
    expect(find.text('查看战斗'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
