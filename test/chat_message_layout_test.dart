import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/api.dart';
import 'package:one_piece_battles_flutter/components/message.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';

void main() {
  for (final isMe in [false, true]) {
    testWidgets('long chat message fits phone width from either side ($isMe)',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
              body: MessageItem(
                  message: Message(
                      content: '这是一段较长的聊天内容，用于确认头像旁的消息气泡在手机宽度内能正常换行显示。'),
                  preMessage: null,
                  isMe: isMe,
                  user: User(
                      id: '1', username: 'user@example.com', nickname: '路飞'),
                  replyMessage: (_) {}))));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('picture-only message has no surrounding text bubble',
      (tester) async {
    const image =
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/0x8AAAAASUVORK5CYII=';
    await tester.pumpWidget(MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
            body: MessageItem(
                message: Message(imageContentUri: image),
                preMessage: null,
                isMe: true,
                user:
                    User(id: '1', username: 'user@example.com', nickname: '路飞'),
                replyMessage: (_) {}))));
    await tester.pump();
    expect(find.byKey(const Key('chat-message-image')), findsOneWidget);
    expect(find.byKey(const Key('chat-text-bubble')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
