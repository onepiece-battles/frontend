import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';
import 'package:one_piece_battles_flutter/ai/assistant_api.dart';
import 'package:one_piece_battles_flutter/ai/assistant_session.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/views/assistant/assistant_view.dart';

/// Stands in for the server: each question returns [answer]'s stream, which
/// the test feeds event by event.
class _FakeAssistantApi extends AssistantApi {
  _FakeAssistantApi() : super(ApiClient());

  final answer = StreamController<AssistantEvent>();
  final questions = <String>[];
  String? language;

  @override
  Stream<AssistantEvent> ask(String message, {String? language}) {
    questions.add(message);
    this.language = language;
    return answer.stream;
  }

  @override
  Future<List<AiStoredMessage>> listMessages() async => const [];
}

Widget _assistantApp() => const MaterialApp(
      locale: Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: AssistantView()),
    );

Future<_FakeAssistantApi> _pumpAssistant(WidgetTester tester) async {
  final api = _FakeAssistantApi();
  GetIt.instance
    ..registerSingleton<AssistantApi>(api)
    ..registerSingleton<AssistantSession>(AssistantSession()..loaded = true);
  addTearDown(() => GetIt.instance.reset());
  await tester.pumpWidget(_assistantApp());
  await tester.pump();
  return api;
}

/// Lets stream events and the rebuilds they trigger run. (The typing dots
/// animate forever, so pumpAndSettle would never return.)
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump();
  }
}

String _visibleText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.textSpan?.toPlainText() ?? text.data ?? '')
    .join(' ');

AssistantSession get _session => GetIt.instance<AssistantSession>();

void main() {
  group('parseAssistantEvents', () {
    test('parses every event even when bytes split mid-line and mid-character',
        () async {
      const body = ': keep-alive\n\n'
          'event:status\n'
          'data:{"tool":"get_character_detail","label":"正在查询角色「路飞」的资料"}\n\n'
          'event:delta\n'
          'data: {"text":"路飞"}\n\n'
          'event:done\n'
          'data:{"messageId":"m1","content":"[路飞](onepiece://character/c1)更强",'
          '"resources":[{"type":"character","id":"c1","name":"路飞"}],'
          '"battleProposal":{"starterId":"c1","receiverId":"c2","label":"路飞 vs 赤犬"}}\n\n'
          'event:error\n'
          'data:{"code":"busy","message":"上一个问题还在回答中"}\n\n';
      final bytes = utf8.encode(body);
      // 7-byte chunks split both lines and 3-byte Chinese characters.
      final chunks = [
        for (var i = 0; i < bytes.length; i += 7)
          bytes.sublist(i, min(i + 7, bytes.length))
      ];

      final events =
          await parseAssistantEvents(Stream.fromIterable(chunks)).toList();

      expect(events, hasLength(4));
      expect((events[0] as AssistantStatus).label, '正在查询角色「路飞」的资料');
      expect((events[1] as AssistantDelta).text, '路飞');
      final done = events[2] as AssistantDone;
      expect(done.content, '[路飞](onepiece://character/c1)更强');
      expect(done.resources.single.name, '路飞');
      expect(done.battleProposal!.receiverId, 'c2');
      expect((events[3] as AssistantFailure).code, 'busy');
    });

    test('skips unknown events and malformed data', () async {
      const body = 'event:future\ndata:{"x":1}\n\n'
          'event:delta\ndata:not json\n\n'
          'event:delta\ndata:{"text":"ok"}'; // last event without a blank line

      final events =
          await parseAssistantEvents(Stream.value(utf8.encode(body))).toList();

      expect(events, hasLength(1));
      expect((events.single as AssistantDelta).text, 'ok');
    });
  });

  testWidgets('streams the tool status, then the text, then the final answer',
      (tester) async {
    final api = await _pumpAssistant(tester);
    await tester.tap(find.text('路飞和赤犬谁更强？'));
    await tester.pump();
    expect(api.questions, ['路飞和赤犬谁更强？']);
    expect(api.language, 'zh_CN');

    api.answer.add(
        const AssistantStatus('get_character_detail', '正在查询角色「路飞」的资料'));
    await _settle(tester);
    expect(find.text('正在查询角色「路飞」的资料'), findsOneWidget);

    api.answer
      ..add(const AssistantDelta('路飞'))
      ..add(const AssistantDelta('更强一些'));
    await _settle(tester);
    expect(_visibleText(tester), contains('路飞更强一些'));
    expect(find.text('正在查询角色「路飞」的资料'), findsNothing);
    expect(_session.busy, isTrue);

    api.answer.add(const AssistantDone(
      messageId: 'm1',
      content: '**路飞**更强。',
      battleProposal: BattleProposal('luffy', 'akainu', '路飞 vs 赤犬'),
    ));
    await api.answer.close();
    await _settle(tester);
    expect(_visibleText(tester), contains('路飞更强。'));
    expect(_visibleText(tester), isNot(contains('更强一些')));
    expect(find.text('路飞 vs 赤犬'), findsOneWidget);
    expect(_session.busy, isFalse);
  });

  testWidgets('a failed answer shows the server message', (tester) async {
    final api = await _pumpAssistant(tester);
    await tester.tap(find.text('谁吃了闪闪果实？'));
    await tester.pump();

    api.answer
        .add(const AssistantFailure('rate_limited', '提问太频繁了，请一分钟后再试。'));
    await api.answer.close();
    await _settle(tester);

    expect(_visibleText(tester), contains('⚠️ 提问太频繁了，请一分钟后再试。'));
    expect(_session.busy, isFalse);
  });

  testWidgets('a stream that ends without an answer says the connection dropped',
      (tester) async {
    final api = await _pumpAssistant(tester);
    await tester.tap(find.text('谁吃了闪闪果实？'));
    await tester.pump();

    api.answer.add(const AssistantDelta('半句'));
    await api.answer.close();
    await _settle(tester);

    expect(_visibleText(tester), contains('连接中断了'));
  });

  testWidgets('without a configured key the pending reply is withdrawn',
      (tester) async {
    final api = await _pumpAssistant(tester);
    await tester.tap(find.text('谁吃了闪闪果实？'));
    await tester.pump();

    api.answer.add(
        const AssistantFailure(AssistantFailure.notConfigured, 'not configured'));
    await api.answer.close();
    await _settle(tester);

    expect(find.text('AI 助手尚未配置，请联系管理员'), findsOneWidget);
    expect(_session.messages.map((m) => m.role), ['user']);
  });

  testWidgets('the answer keeps arriving while the assistant view is closed',
      (tester) async {
    final api = await _pumpAssistant(tester);
    await tester.tap(find.text('谁吃了闪闪果实？'));
    await tester.pump();

    // The user opens a resource page while the answer is still streaming.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    api.answer.add(const AssistantDone(messageId: 'm1', content: '黄猿吃了闪闪果实。'));
    await api.answer.close();
    await _settle(tester);

    await tester.pumpWidget(_assistantApp());
    await tester.pump();
    expect(_visibleText(tester), contains('黄猿吃了闪闪果实。'));
    expect(_session.busy, isFalse);
  });
}
