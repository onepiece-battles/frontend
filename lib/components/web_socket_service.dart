import 'dart:async';
import 'dart:convert';
import 'package:openapi/api.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final StreamController<dynamic> _messageController = StreamController.broadcast();
  Stream<dynamic> get incomingMessages => _messageController.stream;
  WebSocketChannel? _channel;
  String? currentId = '';
  final String hostName = 'ws://localhost:8081/chat?userId=';
  List<String> messageTypes = [MessageType.SEND_MESSAGE.toString(), MessageType.LIST_MESSAGE.toString()];
  List<String> chatTypes = [MessageType.JOIN_CHAT.toString(), MessageType.CREATE_CHAT.toString(), MessageType.LIST_CHAT.toString()];

  Timer? _reconnectTimer;

  WebSocketService();


  void connect(String userId) {
    currentId = userId;
    try {
      _channel = WebSocketChannel.connect(Uri.parse('$hostName$userId'));
      _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
      );
      print('WebSocket connected to $hostName$userId');
    } catch (e) {
      print('WebSocket connection error: $e');
      _scheduleReconnect();
    }
  }

  void sendMessage(String message) {
    if (_channel != null) {
      _channel!.sink.add(message);
    }
  }

  void _onData(dynamic event) {
    try {
      final data = jsonDecode(event);
      // Determine message type and parse
      if (data.containsKey('retracted')) {
        print('message');
        _messageController.add(Message.fromJson(data));
      } else if (data.containsKey('private_group')) {
        print('chat');
        _messageController.add(Chat.fromJson(data));
      }
      // ... handle other types
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }


  void _onError(Object error, StackTrace stackTrace) {
    print('WebSocket error: $error');
    _onDone(); // Treat error as connection done to attempt reconnect
  }

  void _onDone() {
    print('WebSocket connection closed.');
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      print('Attempting to reconnect WebSocket...');
      if (currentId!=null) {
        connect(currentId!);
      }
    });
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
      currentId = null;
    }
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _messageController.close();
    print('WebSocketService disposed.');
  }
}
