import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/components/web_socket_service.dart';
import 'package:openapi/api.dart';
GetIt getIt = GetIt.instance;

class ChatNotifier with ChangeNotifier {
  final WebSocketService _webSocketService;
  // Potentially inject a ChatRepository here for initial data loading
  final List<Chat> _chats = []; // List of all chats for the sidebar
  final Map<String, List<Message>> _messagesByChatId = {}; // Messages for each chat
  String? _activeChatId; // ID of the chat currently open on the screen
  Chat? _activeChat;

  // Constructor and Listener setup
  ChatNotifier(this._webSocketService) {
    _webSocketService.incomingMessages.listen(_handleIncomingData);
    if (_chats.isNotEmpty) {
      _activeChat = _chats.first;
      _activeChatId =_activeChat!.id;
    }
  }

  List<Chat> get chats => _chats;
  List<Message> getMessagesForChat(String? chatId) =>
      _messagesByChatId[chatId] ?? [];
  String? get activeChatId => _activeChatId;
  Chat? get activeChat => _activeChat;

  // Method to inform the notifier which chat page is currently active
  void setActiveChat(String? chatId) {
    if (_activeChatId != chatId) {
      _activeChatId = chatId;
      _activeChat = chats.where((e)=>_activeChatId==e.id).first;
      if (chatId != null) {
        _markChatAsRead(chatId); // Mark the newly active chat as read
      }
      notifyListeners(); // Notify if UI needs to react to active chat change (e.g., clear banner)
    }
  }

  void _handleIncomingData(dynamic data) {
    if (data is Message) {
      _handleIncomingMessage(data);
    } else if (data is Chat) {
      _handleChatUpdate(data);
    }
    // Any other global state changes might also trigger notifyListeners()
  }

  void _handleIncomingMessage(Message message) {
    // 1. Add message to the specific chat's message list
    _messagesByChatId.update(
      message.conversationId!,
      (list) => [...list, message], // Append new message
      ifAbsent: () => [message], // Create list if chat not seen before
    );

    // 2. Update the main chats list (e.g., last message, unread count)
    int chatIndex =
        _chats.indexWhere((chat) => chat.id == message.conversationId);
    // if (chatIndex != -1) {
    // int newUnreadCount = _chats[chatIndex].unreadCount;
    // Increment unread count only if chat is NOT currently active
    //   if (_activeChatId != message.conversationId) {
    //     newUnreadCount++;
    //   } else {
    //     // If active, message is considered read immediately
    //     // In a real app, you'd probably send a "read receipt" to the server here.
    //   }
    //   _chats[chatIndex] = _chats[chatIndex].copyWith(
    //     lastMessage: message,
    //     unreadCount: newUnreadCount,
    //   );
    //   // Move chat to top of the list if you want a "recently active" sort
    //   final updatedChat = _chats.removeAt(chatIndex);
    //   _chats.insert(0, updatedChat);
    // } else {
    //   // Handle case where a message arrives for a chat not yet in _chats (e.g., new chat)
    //   // This implies the chat creation was missed or is handled by a separate update.
    //   // For now, let's assume `_chats` always has the relevant chat entry.
    //   print('Warning: Message for unknown chat ID: ${message.conversationId}');
    // }

    notifyListeners(); // Notify all listening widgets
  }

  void _handleChatUpdate(Chat update) {
    _chats.insert(0, update); // Add to top
    // Handle other update types (e.g., chat name change)
    notifyListeners();
  }

  void _markChatAsRead(String chatId) {
    // int chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
    // if (chatIndex != -1 && _chats[chatIndex].unreadCount > 0) {
    //   _chats[chatIndex] = _chats[chatIndex].copyWith(unreadCount: 0);
    //   notifyListeners(); // Only notify if a change actually occurred
    // }
  }

  // Method for sending messages (can be called from ChatPage)
  void sendChatMessage(String chatId, String content, Message message) {
    // final tempMessageId = DateTime.now()
    //     .millisecondsSinceEpoch
    //     .toString(); // For optimistic update
    // _webSocketService.sendMessage({
    //   'type': 'send_message',
    //   'payload': {
    //     'chatId': chatId,
    //     'content': content,
    //     // Include senderId, timestamp etc. if backend expects it
    //   },
    // });
    _webSocketService.sendMessage(content);

    // Optimistically add to UI
    _messagesByChatId.update(
      chatId,
      (list) => [...list, message],
      ifAbsent: () => [message],
    );
    activeChat?.message = message;
    notifyListeners();

    // Send via WebSocket (backend will persist and echo back)
    // _webSocketService.sendMessage({
    //   'type': 'send_message',
    //   'payload': {
    //     'chatId': chatId,
    //     'content': content,
    //     // Include senderId, timestamp etc. if backend expects it
    //   },
    // });
    // When the echoed message comes back from WebSocketService,
    // `_handleIncomingMessage` will process it. You might need
    // to match tempMessageId to the server's actual ID and update status.
    // This often involves replacing the optimistic message with the server-confirmed one.
  }

  @override
  void dispose() {
    _webSocketService.dispose(); // Dispose the service too
    super.dispose();
  }
}
