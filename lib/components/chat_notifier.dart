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
    }
    notifyListeners();
  }

  void _handleIncomingData(dynamic data) {
    if (data is Message) {
      _handleIncomingMessage(data);
    } else if (data is Chat) {
      _handleChatUpdate(data);
    }
  }

  void _handleIncomingMessage(Message message) {
    // 1. Add message to the specific chat's message list
    _messagesByChatId.update(
      message.conversationId!,
      (list) => [...list, message], // Append new message
      ifAbsent: () => [message], // Create list if chat not seen before
    );
    Chat chat = _chats.firstWhere((e)=>e.id==message.conversationId);
    chat.message = message;
    int index = _chats.indexWhere((e)=>e.id==message.conversationId);
    Chat removedChat = _chats.removeAt(index);
    _chats.insert(0, removedChat);

    notifyListeners(); // Notify all listening widgets
  }

  void _handleChatUpdate(Chat update) {
    _chats.insert(0, update); // Add to top
    // Handle other update types (e.g., chat name change)
    notifyListeners();
  }

  // Method for sending messages (can be called from ChatPage)
  void sendChatMessage(String content) {
    _webSocketService.sendMessage(content);
  }

  @override
  void dispose() {
    _webSocketService.dispose(); // Dispose the service too
    super.dispose();
  }
}
