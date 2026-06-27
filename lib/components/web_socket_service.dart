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
  int _connectionGeneration = 0;
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

    // Invalidate callbacks from the previous transport before closing it.
    _connectionGeneration++;
    _closeTransport();

    currentId = userId;
    _accessToken = accessToken;
    _isIntentionalDisconnect = false;
    _initConnection(_connectionGeneration);
  }

  void _initConnection(int generation) {
    if (currentId == null ||
        currentId!.isEmpty ||
        _accessToken == null ||
        _accessToken!.isEmpty ||
        _isConnecting ||
        generation != _connectionGeneration) {
      return;
    }

    try {
      debugPrint("Connecting to WebSocket...");

      _isConnecting = true;
      final channel = WebSocketChannel.connect(_webSocketUri());
      _channel = channel;

      _subscription = channel.stream.listen(
        _onData,
        onError: (error, stackTrace) =>
            _onError(error, stackTrace, channel, generation),
        onDone: () => _onDone(channel, generation),
        cancelOnError: false,
      );
      channel.ready.timeout(const Duration(seconds: 12)).then((_) {
        if (_channel != channel ||
            _isIntentionalDisconnect ||
            generation != _connectionGeneration) {
          return;
        }
        _isConnecting = false;
        _reconnectAttempt = 0;
        _startPing();
      }).catchError((error, stackTrace) {
        if (_channel != channel || generation != _connectionGeneration) {
          return null;
        }
        debugPrint("WebSocket connection failed: $error");
        _handleConnectionFailure(channel, generation);
        return null;
      });
    } catch (e) {
      debugPrint("Connection failed: $e");
      _isConnecting = false;
      _scheduleReconnect(generation);
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
      final data = _normalizeWebSocketJson(jsonDecode(event));
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

  dynamic _normalizeWebSocketJson(dynamic value) {
    if (value is List) {
      return value.map(_normalizeWebSocketJson).toList();
    }
    if (value is Map) {
      return value.map((key, nestedValue) {
        final normalizedKey = key is String ? _camelToSnake(key) : key;
        return MapEntry(normalizedKey, _normalizeWebSocketJson(nestedValue));
      });
    }
    return value;
  }

  String _camelToSnake(String value) {
    return value.replaceAllMapped(
      RegExp(r'(?<=[a-z0-9])[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }

  void _onError(
    Object error,
    StackTrace stackTrace,
    WebSocketChannel channel,
    int generation,
  ) {
    if (_channel != channel || generation != _connectionGeneration) return;
    debugPrint("WebSocket Error: $error");
    _handleConnectionFailure(channel, generation);
  }

  void _onDone(WebSocketChannel channel, int generation) {
    if (_channel != channel || generation != _connectionGeneration) return;
    debugPrint("WebSocket connection closed.");
    _handleConnectionFailure(channel, generation);
  }

  void _handleConnectionFailure(
    WebSocketChannel channel,
    int generation,
  ) {
    if (_channel != channel || generation != _connectionGeneration) return;
    _isConnecting = false;
    _stopPing();
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    try {
      channel.sink.close();
    } catch (_) {}

    if (!_isIntentionalDisconnect) {
      _scheduleReconnect(generation);
    }
  }

  void _scheduleReconnect(int generation) {
    if (_isIntentionalDisconnect || generation != _connectionGeneration) {
      return;
    }
    _reconnectTimer?.cancel();

    _reconnectAttempt++;
    final delaySeconds = (3 * _reconnectAttempt).clamp(3, 30);

    // Attempt to reconnect with bounded backoff instead of a tight loop.
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isIntentionalDisconnect &&
          generation == _connectionGeneration &&
          currentId != null &&
          _accessToken != null) {
        debugPrint("Attempting to reconnect...");
        _initConnection(generation);
      }
    });
  }

  /// Call this specifically when the User Logs Out
  void disconnect() {
    debugPrint("Disconnecting WebSocket (Intentional Logout)");
    _stopPing();

    _isIntentionalDisconnect = true;
    _connectionGeneration++;
    _isConnecting = false;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempt = 0;

    _closeTransport();

    currentId = null;
    _accessToken = null;
  }

  void _closeTransport() {
    _isConnecting = false;
    _subscription?.cancel();
    _subscription = null;
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
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
