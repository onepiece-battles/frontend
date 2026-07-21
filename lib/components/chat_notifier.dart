import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/components/web_socket_service.dart';
import 'package:one_piece_battles_flutter/repository/chatting_dao.dart';
import 'package:one_piece_battles_flutter/repository/message_dao.dart';
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

  /// How many batches of history have been loaded per chat.
  final Map<String, int> _historyLoadCount = {};

  /// Whether more history is available for a given chat.
  final Map<String, bool> _hasMoreHistory = {};
  final Map<String, Future<int>> _historyLoadFutures = {};

  String? _activeChatId;
  Chat? _activeChat;

  StreamSubscription<dynamic>? _incomingSubscription;

  ChatNotifier(this._webSocketService) {
    _incomingSubscription =
        _webSocketService.incomingMessages.listen(_handleIncomingData);
  }

  /// Monotonically increasing counter bumped on every chat-list mutation.
  /// Use this in [Selector] selectors — unlike [chats] (whose [List.==]
  /// returns true for equal elements), the version is guaranteed different.
  int _chatListVersion = 0;

  /// Returns the current chat list.  Reference changes whenever the list
  /// content or order changes — safe to use with [context.select].
  List<Chat> get chats => _chats;

  /// Version that increments on every chat-list change.  Safe for
  /// [Selector] comparison (uses [identical] on an [int]).
  int get chatListVersion => _chatListVersion;

  List<Message> getMessagesForChat(String? chatId) =>
      _messagesByChatId[chatId] ?? [];

  String? get activeChatId => _activeChatId;
  Chat? get activeChat => _activeChat;

  /// Whether more history can be loaded for [chatId].
  bool hasMoreHistory(String chatId) => _hasMoreHistory[chatId] ?? true;

  /// Whether a history load is in progress for [chatId].
  bool isLoadingHistory(String chatId) => _loadingHistoryChats.contains(chatId);
  final Set<String> _loadingHistoryChats = {};

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
    if (_replaceNewestOptimistic(message)) return;

    // If we already have a message with this exact server-assigned id,
    // update it in place (e.g. a retraction event re-delivers the same id
    // with `retracted: true`) instead of appending a duplicate or silently
    // dropping the update.
    if (_updateMessageInPlace(message)) return;

    _insertMessage(message);
  }

  /// Optimistically inserts a just-sent message so it appears instantly
  /// instead of waiting for the server echo.  The echo is deduplicated.
  void addOptimisticMessage(Message message) {
    _insertMessage(message);
  }

  /// Marks a message as retracted locally, right after the retract API call
  /// succeeds. The API only returns a success flag (no updated message, and
  /// no live websocket broadcast reaches other participants today), so the
  /// retracting user's own copy is scrubbed optimistically here.
  void markMessageRetracted(String conversationId, String messageId) {
    final existing = _messagesByChatId[conversationId] ?? [];
    final index = existing.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    final message = existing[index];
    message.retracted = true;
    message.content = null;
    message.imageContentUri = null;
    message.voiceContentUri = null;
    _messagesByChatId[conversationId] = List<Message>.from(existing);
    notifyListeners();
  }

  void _insertMessage(Message message) {
    final String conversationId = message.conversationId!;
    _insertMessageWithoutNotify(message);

    // Move chat to top of sidebar with new message preview
    _promoteChatWithMessage(conversationId, message);

    // Single notify — both message panel and sidebar update in one frame.
    notifyListeners();
  }

  void _insertMessageWithoutNotify(Message message) {
    final String conversationId = message.conversationId!;
    // Append — newest message at visual bottom.
    final List<Message> existing = _messagesByChatId[conversationId] ?? [];
    _messagesByChatId[conversationId] = [...existing, message];
  }

  void _promoteChatWithMessage(String conversationId, Message message) {
    final int index = _chats.indexWhere((e) => e.id == conversationId);
    if (index > 0) {
      final List<Chat> newChats = List<Chat>.from(_chats);
      final Chat chat = newChats.removeAt(index);
      chat.message = message;
      newChats.insert(0, chat);
      _chats = newChats;
    } else if (index == 0) {
      _chats[0].message = message;
    }
    _chatListVersion++;
  }

  /// If a message with this exact server-assigned id already exists locally,
  /// replaces it in place (covers redelivery after reconnect, and updates
  /// like a retraction event carrying the same id with new content) instead
  /// of appending a duplicate or relying on a content-based heuristic that
  /// would also misfire on two legitimate identical messages sent back to
  /// back. Returns whether an existing entry was found.
  bool _updateMessageInPlace(Message message, {bool notify = true}) {
    final conversationId = message.conversationId;
    final id = message.id;
    if (conversationId == null || id == null) return false;

    final existing = _messagesByChatId[conversationId] ?? [];
    final index = existing.indexWhere((m) => m.id == id);
    if (index == -1) return false;

    final updated = List<Message>.from(existing);
    updated[index] = message;
    _messagesByChatId[conversationId] = updated;
    if (notify) notifyListeners();
    return true;
  }

  /// Finds the most recent still-optimistic (client-generated, `opt_`-id)
  /// placeholder matching [message]'s sender/content/attachment and replaces
  /// it in place with the server's authoritative echo — covers both text
  /// and image sends, so optimistic entries always get reconciled with a
  /// real id instead of staying fake forever (which broke reply-to-message
  /// and produced duplicates on the next history fetch).
  bool _replaceNewestOptimistic(
    Message message, {
    bool notify = true,
    bool promoteChat = true,
  }) {
    final conversationId = message.conversationId;
    if (conversationId == null) return false;

    final incomingImageUri = message.imageContentUri;
    final sameContent = message.content;

    final existing = _messagesByChatId[conversationId] ?? [];
    for (var i = existing.length - 1; i >= 0; i--) {
      final current = existing[i];
      final isOptimistic = (current.id ?? '').startsWith('opt_');
      if (!isOptimistic || current.userId != message.userId) continue;

      final currentImageUri = current.imageContentUri;
      final contentMatches = (current.content ?? '') == (sameContent ?? '');
      final isImageReplacement = incomingImageUri != null &&
          currentImageUri != null &&
          currentImageUri.startsWith('data:image') &&
          contentMatches;
      final isTextReplacement = incomingImageUri == null &&
          currentImageUri == null &&
          contentMatches;

      if (isImageReplacement || isTextReplacement) {
        final updated = List<Message>.from(existing);
        updated[i] = message;
        _messagesByChatId[conversationId] = updated;
        if (promoteChat) {
          _promoteChatWithMessage(conversationId, message);
        }
        if (notify) {
          notifyListeners();
        }
        return true;
      }
    }

    return false;
  }

  void _handleChatUpdate(Chat update) {
    final latestMessage = update.message;
    if (latestMessage != null) {
      latestMessage.conversationId ??= update.id;
    }
    if (latestMessage != null &&
        latestMessage.conversationId != null &&
        !_replaceNewestOptimistic(
          latestMessage,
          notify: false,
          promoteChat: false,
        ) &&
        !_updateMessageInPlace(latestMessage, notify: false)) {
      _insertMessageWithoutNotify(latestMessage);
    }

    // New list: old duplicate removed, update inserted at top
    final List<Chat> newChats = List<Chat>.from(_chats);
    newChats.removeWhere((e) => e.id == update.id);
    newChats.insert(0, update);
    _chats = newChats;
    _chatListVersion++;
    notifyListeners();
  }

  void upsertChat(Chat chat) {
    _handleChatUpdate(chat);
  }

  Future<void> refreshChats() async {
    try {
      final response = await getIt<ChattingDao>().listChat(
        ListChatRequest(
          type: MessageType.CREATE_CHAT,
          userId: getIt<User>().id,
        ),
      );
      if (response == null) return;

      _chats = response.chats.toList()..sort(_compareChatsByLatestMessage);
      if (_activeChatId != null) {
        _activeChat = _chats.cast<Chat?>().firstWhere(
              (chat) => chat?.id == _activeChatId,
              orElse: () => null,
            );
        if (_activeChat == null) {
          _activeChatId = null;
        }
      }
      _chatListVersion++;
      notifyListeners();
    } catch (error) {
      debugPrint('Error refreshing chats: $error');
    }
  }

  int _compareChatsByLatestMessage(Chat left, Chat right) {
    final leftTimestamp = left.message?.creationRecord?.actionTimestamp;
    final rightTimestamp = right.message?.creationRecord?.actionTimestamp;

    if (leftTimestamp == null && rightTimestamp == null) {
      return (left.id ?? '').compareTo(right.id ?? '');
    }
    if (leftTimestamp == null) return 1;
    if (rightTimestamp == null) return -1;

    final timestampOrder = rightTimestamp.compareTo(leftTimestamp);
    if (timestampOrder != 0) return timestampOrder;
    return (left.id ?? '').compareTo(right.id ?? '');
  }

  /// Returns whether the message was actually handed to an open socket —
  /// false means the caller should tell the user delivery is uncertain
  /// instead of assuming the optimistic bubble reflects reality.
  bool sendChatMessage(String content) {
    return _webSocketService.sendMessage(content);
  }

  /// Loads older messages for [chatId] and appends them to the existing list
  /// (they appear at the visual *top* of the reversed ListView). Relies on
  /// the server's chronological ordering (oldest first per batch).
  Future<int> loadMoreHistory(
    String chatId, {
    ValueChanged<int>? beforeNotify,
  }) async {
    if (_loadingHistoryChats.contains(chatId)) {
      final inFlight = _historyLoadFutures[chatId];
      if (inFlight != null) {
        return await inFlight;
      }
      return 0;
    }
    if (!(_hasMoreHistory[chatId] ?? true)) return 0;

    final future = _loadMoreHistory(chatId, beforeNotify: beforeNotify);
    _historyLoadFutures[chatId] = future;
    return await future;
  }

  Future<int> loadMoreHistoryAfterCurrent(
    String chatId, {
    ValueChanged<int>? beforeNotify,
  }) async {
    final inFlight = _historyLoadFutures[chatId];
    if (inFlight != null) {
      await inFlight;
    }
    if (!(_hasMoreHistory[chatId] ?? true)) return 0;
    return await loadMoreHistory(chatId, beforeNotify: beforeNotify);
  }

  Future<int> _loadMoreHistory(
    String chatId, {
    ValueChanged<int>? beforeNotify,
  }) async {
    _loadingHistoryChats.add(chatId);
    notifyListeners();
    var shouldNotify = false;
    var insertedHistoryCount = 0;

    try {
      final loadCount = (_historyLoadCount[chatId] ?? 0) + 1;
      const batchSize = 20;
      final alreadyLoadedCount = _messagesByChatId[chatId]?.length ?? 0;
      final countedLimit = loadCount * batchSize;
      final visibleLimit = alreadyLoadedCount + batchSize;
      final limit = countedLimit > visibleLimit ? countedLimit : visibleLimit;

      final request = ListMessageRequest(
        userId: getIt<User>().id,
        chatId: chatId,
        limit: limit,
      );
      final response = await getIt<MessageDao>().listMessage(request);
      if (response == null) {
        _hasMoreHistory[chatId] = false;
        shouldNotify = true;
        return 0;
      }

      final allLoaded = response.chats;
      if (allLoaded.isEmpty) {
        _hasMoreHistory[chatId] = false;
        shouldNotify = true;
        return 0;
      }

      // Trust server order: MessageDao's query already returns this batch
      // oldest-first (message.id is a random UUID, not time-ordered, so
      // sorting by id here would scramble chronological order).
      final existing = _messagesByChatId[chatId] ?? [];
      final existingIds = existing.map((e) => e.id).toSet();

      // Only keep messages that aren't already loaded.
      final onlyNew =
          allLoaded.where((m) => !existingIds.contains(m.id)).toList();

      if (onlyNew.isNotEmpty) {
        // Prepend older messages at the start (= visual top).
        _messagesByChatId[chatId] = [...onlyNew, ...existing];
        insertedHistoryCount = onlyNew.length;
      }

      // More history exists if server returned a full batch.
      _hasMoreHistory[chatId] = allLoaded.length >= limit;
      _historyLoadCount[chatId] = (limit + batchSize - 1) ~/ batchSize;
      shouldNotify = true;
      return insertedHistoryCount;
    } catch (_) {
      _hasMoreHistory[chatId] = false;
      shouldNotify = true;
      return 0;
    } finally {
      _loadingHistoryChats.remove(chatId);
      _historyLoadFutures.remove(chatId);
      if (shouldNotify) {
        if (insertedHistoryCount > 0) {
          beforeNotify?.call(insertedHistoryCount);
        }
        notifyListeners();
      }
    }
  }

  /// Called when entering a chat.  Loads the initial batch of history.
  /// Skips only if history was already fetched via [loadMoreHistory].
  Future<void> ensureHistoryLoaded(String chatId) async {
    // Only skip if a paginated fetch already happened for this chat
    if (_historyLoadCount.containsKey(chatId)) return;
    await loadMoreHistory(chatId);
  }

  @override
  void dispose() {
    // Note: WebSocketService is a shared, app-lifetime singleton — it is not
    // owned by this notifier, so only the subscription is torn down here.
    _incomingSubscription?.cancel();
    super.dispose();
  }
}
