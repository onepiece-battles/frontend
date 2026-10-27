import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';
import 'package:one_piece_battles_flutter/ai/assistant_api.dart';
import 'package:one_piece_battles_flutter/ai/deepseek_service.dart';
import 'package:one_piece_battles_flutter/ai/resource_tools.dart';
import 'package:one_piece_battles_flutter/ai/rich_message.dart';
import 'package:one_piece_battles_flutter/ai/assistant_session.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/views/assistant/assistant_view.dart';

class _AssistantApiFake extends AssistantApi {
  _AssistantApiFake() : super(ApiClient());

  final requests = <Map<String, dynamic>>[];

  @override
  Future<AiChatResult> chat(String requestBody) async {
    final request = jsonDecode(requestBody) as Map<String, dynamic>;
    requests.add(request);
    final round = requests.length;
    final message = round <= 8
        ? {
            'role': 'assistant',
            'content': null,
            'tool_calls': [
              {
                'id': 'call_$round',
                'type': 'function',
                'function': {'name': 'unknown_tool', 'arguments': '{}'},
              }
            ],
          }
        : {'role': 'assistant', 'content': '没有找到相关资料，请换个关键词。'};
    return AiChatResult(
        200,
        jsonEncode({
          'choices': [
            {'message': message}
          ]
        }),
        null);
  }
}

void main() {
  test('normalizes bare and malformed resource links using tool names', () {
    final result = normalizeResourceLinks(
      '看看 onepiece://character/ace，或 [onepiece://fruit/mera](onepiece://fruit/mera)。',
      const [
        ResourceRef('character', 'ace', '艾斯'),
        ResourceRef('fruit', 'mera', '烧烧果实'),
      ],
    );
    expect(result,
        '看看 [艾斯](onepiece://character/ace)，或 [烧烧果实](onepiece://fruit/mera)。');
  });

  test('after repeated tool calls, requests a final answer without tools',
      () async {
    final fake = _AssistantApiFake();
    GetIt.instance.registerSingleton<AssistantApi>(fake);
    addTearDown(() => GetIt.instance.reset());

    final reply = await DeepSeekAssistant().ask('介绍一下艾斯');
    expect(reply.text, '没有找到相关资料，请换个关键词。');
    expect(fake.requests, hasLength(9));
    expect(fake.requests.last.containsKey('tools'), isFalse);
    expect(fake.requests.last.containsKey('tool_choice'), isFalse);
    expect((fake.requests.last['messages'] as List).last['role'], 'tool');
  });

  testWidgets('links inside bold text stay tappable and hide raw URLs',
      (tester) async {
    final taps = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RichMessage(
          data: '**[艾斯](onepiece://character/ace)** 和 onepiece://fruit/mera',
          onResource: (type, id, name) => taps.add('$type/$id/$name'),
        ),
      ),
    ));

    final visible = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.textSpan?.toPlainText() ?? text.data ?? '')
        .join(' ');
    expect(visible, isNot(contains('onepiece://')));
    expect(visible, contains('艾斯'));
    await tester.tapAt(
        tester.getTopLeft(find.textContaining('艾斯')) + const Offset(12, 10));
    expect(taps, ['character/ace/艾斯']);
  });

  testWidgets('copy confirmation is centered and disappears after one second',
      (tester) async {
    final session = AssistantSession()
      ..loaded = true
      ..messages.add(AiChatMessage('user', '测试消息'));
    GetIt.instance.registerSingleton<AssistantSession>(session);
    addTearDown(() => GetIt.instance.reset());

    await tester.pumpWidget(const MaterialApp(
      locale: Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: AssistantView()),
    ));
    await tester.pump();
    await tester.tap(find.text('复制'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('已复制'), findsOneWidget);
    final toastCenter = tester.getCenter(find.text('已复制'));
    expect(
        (toastCenter.dy -
                tester.view.physicalSize.height /
                    tester.view.devicePixelRatio /
                    2)
            .abs(),
        lessThan(80));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('已复制'), findsNothing);
  });
}
