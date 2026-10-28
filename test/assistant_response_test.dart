import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/ai/assistant_message.dart';
import 'package:one_piece_battles_flutter/ai/rich_message.dart';
import 'package:one_piece_battles_flutter/ai/assistant_session.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/views/assistant/assistant_view.dart';

// The tool-calling loop and the tools themselves now run on the server
// (backend AssistantAgentTests / AssistantToolsTests); the streaming client
// is covered by assistant_stream_test.dart.
void main() {
  test('unknown resource IDs are repaired by a known name or stay plain text',
      () {
    final result = normalizeResourceLinks(
      '[艾斯](onepiece://character/wrong-id) [不存在](onepiece://battle/invented)',
      const [ResourceRef('character', 'ace', '艾斯')],
    );
    expect(result, '[艾斯](onepiece://character/ace) 不存在');
  });

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
