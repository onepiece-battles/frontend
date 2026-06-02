import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/components/web_socket_service.dart';
import 'package:openapi/api.dart';

GetIt getIt = GetIt.instance;

class ChatNotifier with ChangeNotifier {
  final WebSocketService _webSocketService;

  /// Sidebar chat list — always kept sorted (most recent first).
  /// A **new list reference** is created on every mutation so that
  /// [Selector] / [context.select] can detect changes via reference equality.
  List<Chat> _chats = [];

  /// Messages keyed by conversation id.  List references are also replaced
  /// on every append so message-area selectors fire only when needed.
  final Map<String, List<Message>> _messagesByChatId = {};

  String? _activeChatId;
  Chat? _activeChat;

  ChatNotifier(this._webSocketService) {
    _webSocketService.incomingMessages.listen(_handleIncomingData);
    if (_chats.isNotEmpty) {
      _activeChat = _chats.first;
      _activeChatId = _activeChat!.id;
    }
  }

  /// Returns the current chat list.  Reference changes whenever the list
  /// content or order changes — safe to use with [context.select].
  List<Chat> get chats => _chats;

  List<Message> getMessagesForChat(String? chatId) =>
      _messagesByChatId[chatId] ?? [];

  String? get activeChatId => _activeChatId;
  Chat? get activeChat => _activeChat;

  void setActiveChat(String? chatId) {
    if (_activeChatId == chatId) return;
    _activeChatId = chatId;
    _activeChat = chatId != null
        ? _chats.cast<Chat?>().firstWhere(
              (e) => e!.id == chatId,
              orElse: () => null,
            )
        : null;
    notifyListeners();
  }

  // ── Incoming data dispatch ─────────────────────────────────────────────

  void _handleIncomingData(dynamic data) {
    if (data is Message) {
      _handleIncomingMessage(data);
    } else if (data is Chat) {
      _handleChatUpdate(data);
    }
  }

  // ── Message handler ─────────────────────────────────────────────────────

  void _handleIncomingMessage(Message message) {
    final String conversationId = message.conversationId!;

    // 1. Append message — new list reference for change detection
    final List<Message> existing =
        _messagesByChatId[conversationId] ?? [];
    _messagesByChatId[conversationId] = [...existing, message];

    // 2. Move the corresponding chat to the top — new list reference
    final int index = _chats.indexWhere((e) => e.id == conversationId);
    if (index == -1) {
      notifyListeners();
      return;
    }

    final List<Chat> newChats = List<Chat>.from(_chats);
    final Chat chat = newChats.removeAt(index);
    chat.message = message;
    newChats.insert(0, chat);
    _chats = newChats;

    notifyListeners();
  }

  void _handleChatUpdate(Chat update) {
    // New list: old duplicate removed, update inserted at top
    final List<Chat> newChats = List<Chat>.from(_chats);
    newChats.removeWhere((e) => e.id == update.id);
    newChats.insert(0, update);
    _chats = newChats;
    notifyListeners();
  }

  void sendChatMessage(String content) {
    _webSocketService.sendMessage(content);
  }

  @override
  void dispose() {
    _webSocketService.dispose();
    super.dispose();
  }
}
