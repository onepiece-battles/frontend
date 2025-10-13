import 'dart:convert';

import 'package:openapi/api.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../app_router.dart';

class WebSocketManager {
  WebSocketChannel? _channel;
  final String userId;
  final String hostName = 'ws://localhost:8081/chat?userId=';

  WebSocketManager(this.userId);

  void connect(String url) {
    _channel = WebSocketChannel.connect(Uri.parse('$hostName$userId'));
  }

  void sendMessage(String message) {
    if (_channel != null) {
      _channel!.sink.add(message);
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
