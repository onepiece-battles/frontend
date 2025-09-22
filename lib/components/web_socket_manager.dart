import 'dart:convert';

import 'package:openapi/api.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../app_router.dart';

class WebSocketManager {
  WebSocketChannel? _channel;
  final String userId;

  WebSocketManager(this.userId);

  void connect(String url) {
    _channel = WebSocketChannel.connect(Uri.parse(url));
  }

  void sendMessage(String message, String groupId) {
    if (_channel != null) {
      final payload = {
        'userId': userId,
        'groupId': groupId,
        'message': message,
      };
      _channel!.sink.add(jsonEncode(payload));
    }
  }

  Stream get stream => _channel!.stream;

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
  }
}
