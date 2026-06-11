import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:openapi/api.dart'; // Keep your existing import
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  // Broadcast controller so multiple UI widgets can listen to updates
  final StreamController<dynamic> _messageController = StreamController.broadcast();
  Stream<dynamic> get incomingMessages => _messageController.stream;
  Timer? _pingTimer;

  WebSocketChannel? _channel;
  String? currentId;
  final String hostName = 'wss://onepiece-battles.com/chat?userId=';

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
      debugPrint("Connecting to WebSocket...");

      _channel = WebSocketChannel.connect(Uri.parse('$hostName$currentId'));

      _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
      _startPing();
    } catch (e) {
      debugPrint("Connection failed: $e");
      _scheduleReconnect();
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    // Send a ping every 30 seconds (less than the 60s timeout)
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      // Send a JSON ping object as most servers expect structured messages
      sendMessage(jsonEncode({'type': 'ping'}));
    });
  }

  void _stopPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void sendMessage(String message) {
    if (_channel != null) {
      try {
        _channel!.sink.add(message);
      } catch (e) {
        debugPrint("Error sending message: $e");
      }
    }
  }

  void _onData(dynamic event) {
    try {
      final data = jsonDecode(event);
      // Determine message type and parse
      if (data.containsKey('retracted')) {
        _messageController.add(Message.fromJson(data));
      } else if (data.containsKey('private_group')) {
        _messageController.add(Chat.fromJson(data));
      }
      // Add other message types here...
    } catch (e) {
      debugPrint('Error parsing WebSocket message: $e');
    }
  }

  void _onError(Object error, StackTrace stackTrace) {
    debugPrint("WebSocket Error: $error");
    // Don't manually call _onDone here; the stream listener will usually call
    // onDone automatically after onError if cancelOnError is true.
  }

  void _onDone() {
    debugPrint("WebSocket connection closed.");
    _stopPing();
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
        debugPrint("Attempting to reconnect...");
        _initConnection();
      }
    });
  }

  /// Call this specifically when the User Logs Out
  void disconnect() {
    debugPrint("Disconnecting WebSocket (Intentional Logout)");
    _stopPing();

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
