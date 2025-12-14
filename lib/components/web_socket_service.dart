import 'dart:async';
import 'dart:convert';
import 'package:openapi/api.dart'; // Keep your existing import
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  // Broadcast controller so multiple UI widgets can listen to updates
  final StreamController<dynamic> _messageController = StreamController.broadcast();
  Stream<dynamic> get incomingMessages => _messageController.stream;

  WebSocketChannel? _channel;
  String? currentId;
  final String hostName = 'ws://localhost:8081/chat?userId=';

  // Timer for auto-reconnect
  Timer? _reconnectTimer;
  // Flag to distinguish between network error vs user clicking "Logout"
  bool _isIntentionalDisconnect = false;

  WebSocketService();

  /// Call this when the app starts or user logs in
  void connect(String userId) {
    // If we are already connected to this user, do nothing
    if (_channel != null && currentId == userId) return;

    // If connected to someone else, disconnect first
    disconnect();

    currentId = userId;
    _isIntentionalDisconnect = false; // Reset flag
    _initConnection();
  }

  void _initConnection() {
    if (currentId == null) return;

    try {
      print("Connecting to WebSocket...");
      _channel = WebSocketChannel.connect(Uri.parse('$hostName$currentId'));

      _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: true,
      );
    } catch (e) {
      print("Connection failed: $e");
      _scheduleReconnect();
    }
  }

  void sendMessage(String message) {
    if (_channel != null && _channel!.sink != null) {
      try {
        _channel!.sink.add(message);
      } catch (e) {
        print("Error sending message: $e");
      }
    }
  }

  void _onData(dynamic event) {
    try {
      final data = jsonDecode(event);
      // Determine message type and parse
      if (data.containsKey('retracted')) {
        // print('message');
        _messageController.add(Message.fromJson(data));
      } else if (data.containsKey('private_group')) {
        // print('chat');
        _messageController.add(Chat.fromJson(data));
      }
      // Add other message types here...
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }

  void _onError(Object error, StackTrace stackTrace) {
    print("WebSocket Error: $error");
    // Don't manually call _onDone here; the stream listener will usually call
    // onDone automatically after onError if cancelOnError is true.
  }

  void _onDone() {
    print("WebSocket connection closed.");
    _channel = null;

    // Only attempt to reconnect if the user didn't intentionally log out
    if (!_isIntentionalDisconnect) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    // Cancel existing timer if any
    _reconnectTimer?.cancel();

    // Attempt to reconnect in 3 seconds
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_isIntentionalDisconnect && currentId != null) {
        print("Attempting to reconnect...");
        _initConnection();
      }
    });
  }

  /// Call this specifically when the User Logs Out
  void disconnect() {
    print("Disconnecting WebSocket (Intentional Logout)");

    // 1. Mark as intentional so we don't reconnect
    _isIntentionalDisconnect = true;

    // 2. Stop any pending reconnection timers
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    // 3. Close the connection
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }

    // 4. Clear User ID
    currentId = null;
  }

  /// Call this only when the App is effectively shutting down
  /// (or if this service instance will never be used again)
  void dispose() {
    disconnect();
    _messageController.close();
  }
}
