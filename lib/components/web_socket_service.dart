import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:openapi/api.dart'; // Keep your existing import
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  // Broadcast controller so multiple UI widgets can listen to updates
  final StreamController<dynamic> _messageController =
      StreamController.broadcast();
  Stream<dynamic> get incomingMessages => _messageController.stream;
  Timer? _pingTimer;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  String? currentId;
  String? _accessToken;

  // Timer for auto-reconnect
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  int _reconnectAttempt = 0;
  // Flag to distinguish between network error vs user clicking "Logout"
  bool _isIntentionalDisconnect = false;

  WebSocketService();

  /// Call this when the app starts or user logs in
  void connect(String userId, String accessToken) {
    // If we are already connected to this user, do nothing
    if ((_channel != null || _isConnecting) &&
        currentId == userId &&
        _accessToken == accessToken) {
      return;
    }

    // If connected to someone else, disconnect first
    disconnect();

    currentId = userId;
    _accessToken = accessToken;
    _isIntentionalDisconnect = false; // Reset flag
    _initConnection();
  }

  void _initConnection() {
    if (currentId == null ||
        currentId!.isEmpty ||
        _accessToken == null ||
        _accessToken!.isEmpty ||
        _isConnecting) {
      return;
    }

    try {
      debugPrint("Connecting to WebSocket...");

      _isConnecting = true;
      final channel = WebSocketChannel.connect(_webSocketUri());
      _channel = channel;

      _subscription = channel.stream.listen(
        _onData,
        onError: (error, stackTrace) => _onError(error, stackTrace, channel),
        onDone: () => _onDone(channel),
        cancelOnError: false,
      );
      channel.ready.then((_) {
        if (_channel != channel || _isIntentionalDisconnect) return;
        _isConnecting = false;
        _reconnectAttempt = 0;
        _startPing();
      }).catchError((error, stackTrace) {
        if (_channel != channel) return null;
        debugPrint("WebSocket connection failed: $error");
        _isConnecting = false;
        _stopPing();
        _subscription?.cancel();
        _subscription = null;
        _channel = null;
        try {
          channel.sink.close();
        } catch (_) {}
        if (!_isIntentionalDisconnect) {
          _scheduleReconnect();
        }
        return null;
      });
    } catch (e) {
      debugPrint("Connection failed: $e");
      _isConnecting = false;
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
      if (data is Map && data.containsKey('private_group')) {
        _messageController.add(Chat.fromJson(data));
      } else if (data is Map && data.containsKey('message')) {
        final response = SendMessageResponse.fromJson(data);
        if (response?.message != null) {
          _messageController.add(response!.message);
        }
      } else if (data is Map &&
          (data.containsKey('retracted') ||
              data.containsKey('image_content_uri') ||
              data.containsKey('voice_content_uri') ||
              data.containsKey('conversation_id'))) {
        _messageController.add(Message.fromJson(data));
      }
      // Add other message types here...
    } catch (e) {
      debugPrint('Error parsing WebSocket message: $e');
    }
  }

  void _onError(
    Object error,
    StackTrace stackTrace,
    WebSocketChannel channel,
  ) {
    if (_channel != channel) return;
    _isConnecting = false;
    debugPrint("WebSocket Error: $error");
    // Don't manually call _onDone here; the stream listener will usually call
    // onDone automatically after onError if cancelOnError is true.
  }

  void _onDone(WebSocketChannel channel) {
    if (_channel != channel) return;
    debugPrint("WebSocket connection closed.");
    _isConnecting = false;
    _stopPing();
    _channel = null;
    _subscription = null;

    // Only attempt to reconnect if the user didn't intentionally log out
    if (!_isIntentionalDisconnect) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    // Cancel existing timer if any
    _reconnectTimer?.cancel();

    _reconnectAttempt++;
    final delaySeconds = (3 * _reconnectAttempt).clamp(3, 30);

    // Attempt to reconnect with bounded backoff instead of a tight loop.
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isIntentionalDisconnect &&
          currentId != null &&
          _accessToken != null) {
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
    _isConnecting = false;

    // 2. Stop any pending reconnection timers
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempt = 0;

    // 3. Close the connection
    _subscription?.cancel();
    _subscription = null;
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }

    // 4. Clear User ID
    currentId = null;
    _accessToken = null;
  }

  Uri _webSocketUri() {
    final apiUri = Uri.parse(ApiClient().basePath);
    final scheme = apiUri.scheme == 'https' ? 'wss' : 'ws';
    return apiUri.replace(scheme: scheme, path: '/chat', queryParameters: {
      'token': _accessToken!,
    });
  }

  /// Call this only when the App is effectively shutting down
  /// (or if this service instance will never be used again)
  void dispose() {
    disconnect();
    _messageController.close();
  }
}
