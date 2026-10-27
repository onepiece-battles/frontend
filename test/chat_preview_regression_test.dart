import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/api.dart';
import 'package:one_piece_battles_flutter/components/chat_notifier.dart';
import 'package:one_piece_battles_flutter/components/web_socket_service.dart';

void main() {
  test('older picture update does not replace a newly sent emoji preview', () {
    final notifier = ChatNotifier(WebSocketService());
    addTearDown(notifier.dispose);
    notifier.upsertChat(Chat(id: 'room', members: []));
    notifier.addOptimisticMessage(Message(
      id: 'opt_emoji',
      conversationId: 'room',
      userId: 'me',
      content: '😊',
      creationRecord: ActionRecord(actionTimestamp: 200),
    ));

    notifier.upsertChat(Chat(
      id: 'room',
      members: [],
      message: Message(
        id: 'older-picture',
        conversationId: 'room',
        userId: 'me',
        imageContentUri: '/picture',
        creationRecord: ActionRecord(actionTimestamp: 100),
      ),
    ));

    expect(notifier.chats.single.message?.content, '😊');
    expect(notifier.getMessagesForChat('room').last.content, '😊');
  });
}
