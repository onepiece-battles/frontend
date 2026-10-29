import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show PointerScrollEvent;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';
import 'package:one_piece_battles_flutter/ai/assistant_api.dart';
import 'package:one_piece_battles_flutter/ai/assistant_message.dart';
import 'package:one_piece_battles_flutter/ai/assistant_session.dart';
import 'package:one_piece_battles_flutter/components/emoji_selection.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/views/assistant/assistant_view.dart';

class _Api extends AssistantApi {
  _Api() : super(ApiClient());
  final streams = <StreamController<AssistantEvent>>[];
  final questions = <String>[];
  List<AiStoredMessage> history = const [];
  @override
  Future<List<AiStoredMessage>> listMessages() async => history;
  @override
  Stream<AssistantEvent> ask(String text, {String? language}) {
    questions.add(text);
    final stream = StreamController<AssistantEvent>();
    streams.add(stream);
    return stream.stream;
  }

  @override
  Future<void> clearMessages() async {}
}

Widget _app() => const MaterialApp(
      locale: Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: AssistantView()),
    );

Future<({AssistantSession session, _Api api})> _start(WidgetTester tester,
    {bool history = false, int count = 80, bool tallTail = false}) async {
  final session = AssistantSession()..loaded = !history;
  final api = _Api();
  final messages = List.generate(
      count,
      (i) => AiChatMessage('assistant',
          '消息 $i\n${List.filled(i % 5 + 1, '角色与战斗的信息。').join('\n')}'));
  if (tallTail) {
    messages.add(AiChatMessage('assistant',
        '${List.filled(100, '很长的最终回复。').join('\n')}\nTAIL_MARKER'));
  }
  if (history) {
    api.history = messages
        .map((m) => AiStoredMessage(
            id: '${messages.indexOf(m)}',
            role: m.role,
            content: m.text,
            resources: const []))
        .toList();
  } else {
    session.messages.addAll(messages);
  }
  GetIt.instance
    ..registerSingleton<AssistantApi>(api)
    ..registerSingleton<AssistantSession>(session);
  addTearDown(() => GetIt.instance.reset());
  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();
  return (session: session, api: api);
}

Finder get _list => find.byKey(const ValueKey('assistant_messages'));
ScrollPosition _position(WidgetTester tester) =>
    tester.widget<ListView>(_list).controller!.position;
Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump();
  }
}

Future<void> _finish(WidgetTester tester, _Api api, String text) async {
  api.streams.last.add(AssistantDone(messageId: 'reply', content: text));
  await api.streams.last.close();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'first history load reaches the true end of variable and very tall messages',
      (tester) async {
    final state =
        await _start(tester, history: true, count: 130, tallTail: true);
    expect(state.session.followLatest, isTrue);
    expect(_position(tester).extentAfter, lessThan(.5));
    expect(find.textContaining('TAIL_MARKER'), findsOneWidget);
    final copy = find
        .descendant(of: _list, matching: find.byIcon(Icons.copy_rounded))
        .last;
    expect(tester.getRect(copy).bottom,
        lessThanOrEqualTo(tester.getRect(_list).bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'leaving and returning restores the reading offset instead of resetting to bottom',
      (tester) async {
    final state = await _start(tester);
    await tester.drag(_list, const Offset(0, 430));
    await tester.pumpAndSettle();
    final offset = _position(tester).pixels;
    expect(state.session.followLatest, isFalse);
    expect(_position(tester).extentAfter, greaterThan(100));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    // New content below the reader must not alter their top-relative bookmark.
    state.session.messages.add(
        AiChatMessage('assistant', List.filled(50, '后台收到的更新。').join('\n')));
    state.session.changed();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(_position(tester).pixels, closeTo(offset, .5));
    expect(state.session.followLatest, isFalse);
  });

  testWidgets(
      'sending resumes bottom-following; streaming respects a reader scrolling up',
      (tester) async {
    final state = await _start(tester);
    await tester.drag(_list, const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(state.session.followLatest, isFalse);
    await tester.enterText(
        find.byKey(const ValueKey('assistant_input')), '新的问题');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('assistant_send')));
    await _frames(tester);
    expect(state.api.questions, ['新的问题']);
    expect(state.session.followLatest, isTrue);
    state.api.streams.last
        .add(AssistantDelta(List.filled(50, '逐步输出的回答。').join('\n')));
    await _frames(tester);
    expect(_position(tester).extentAfter, lessThan(.5));
    await tester.drag(_list, const Offset(0, 350));
    await _frames(tester);
    // Finish the scroll's ballistic activity without settling the typing animation.
    await tester.pump(const Duration(seconds: 2));
    final offset = _position(tester).pixels;
    expect(state.session.followLatest, isFalse);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    state.api.streams.last
        .add(AssistantDelta(List.filled(40, '继续输出。').join('\n')));
    await _frames(tester);
    await tester.pumpWidget(_app());
    await _frames(tester);
    expect(_position(tester).pixels, closeTo(offset, .5));
    await _finish(tester, state.api, List.filled(90, '完整回复。').join('\n'));
    expect(_position(tester).pixels, closeTo(offset, .5));
  });

  testWidgets('desktop wheel pauses following and reaching the end resumes it',
      (tester) async {
    final state = await _start(tester);
    await tester.sendEventToBinding(PointerScrollEvent(
        position: tester.getCenter(_list), scrollDelta: const Offset(0, -320)));
    await _frames(tester);
    final offset = _position(tester).pixels;
    expect(state.session.followLatest, isFalse);
    state.session.messages
        .add(AiChatMessage('assistant', List.filled(30, '新内容。').join('\n')));
    state.session.changed();
    await _frames(tester);
    expect(_position(tester).pixels, closeTo(offset, .5));
    await tester.sendEventToBinding(PointerScrollEvent(
        position: tester.getCenter(_list),
        scrollDelta: const Offset(0, 100000)));
    await _frames(tester);
    expect(state.session.followLatest, isTrue);
    expect(_position(tester).extentAfter, lessThan(.5));
  });

  testWidgets(
      'a reply continues following after closing and reopening the view',
      (tester) async {
    final state = await _start(tester, count: 12);
    await tester.enterText(
        find.byKey(const ValueKey('assistant_input')), '继续回答');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('assistant_send')));
    await _frames(tester);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    state.api.streams.last
        .add(AssistantDelta(List.filled(60, '离开页面时的回复。').join('\n')));
    await _frames(tester);
    await tester.pumpWidget(_app());
    await _frames(tester);
    expect(_position(tester).extentAfter, lessThan(.5));
    state.api.streams.last
        .add(AssistantDelta(List.filled(25, '返回后继续回复。').join('\n')));
    await _frames(tester);
    expect(_position(tester).extentAfter, lessThan(.5));
    await _finish(tester, state.api, '最终回复。');
    expect(_position(tester).extentAfter, lessThan(.5));
  });

  testWidgets(
      'composer matches chat field styling and disables empty and busy sends on mobile',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = await _start(tester, count: 0);
    final send = find.byKey(const ValueKey('assistant_send'));
    expect(tester.widget<IconButton>(send).onPressed, isNull);
    expect(find.byType(EmojiSelection), findsNothing);
    final surface = tester
        .widget<Container>(
            find.byKey(const ValueKey('assistant_input_surface')))
        .decoration! as BoxDecoration;
    expect(surface.color, Colors.white);
    expect(surface.borderRadius, BorderRadius.circular(6));
    expect((surface.border! as Border).top.width, .7);
    expect((surface.border! as Border).top.color, OnepieceColors.separator);
    await tester.enterText(
        find.byKey(const ValueKey('assistant_input')), '   ');
    await tester.pump();
    expect(tester.widget<IconButton>(send).onPressed, isNull);
    await tester.enterText(
        find.byKey(const ValueKey('assistant_input')), '第一行\n第二行');
    await tester.pump();
    expect(tester.widget<IconButton>(send).onPressed, isNotNull);
    await tester.tap(send);
    await _frames(tester);
    expect(state.api.questions, ['第一行\n第二行']);
    expect(tester.widget<IconButton>(send).onPressed, isNull);
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('assistant_input')))
            .controller!
            .text,
        isEmpty);
    expect(tester.takeException(), isNull);
    await _finish(tester, state.api, '收到。');
  });

  test('clearing the conversation also clears its scroll bookmark', () {
    final session = AssistantSession()
      ..scrollOffset = 340
      ..followLatest = false;
    session.reset();
    expect(session.scrollOffset, isNull);
    expect(session.followLatest, isTrue);
    session.dispose();
  });
}
