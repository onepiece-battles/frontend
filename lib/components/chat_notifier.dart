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
  final Map<String, Future<void>> _historyLoadFutures = {};

  String? _activeChatId;
  Chat? _activeChat;

  ChatNotifier(this._webSocketService) {
    _webSocketService.incomingMessages.listen(_handleIncomingData);
    if (_chats.isNotEmpty) {
      _activeChat = _chats.first;
      _activeChatId = _activeChat!.id;
    }
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
    // Dedup: if we optimistically added this message already, skip the echo.
    if (_isDuplicate(message)) return;

    _insertMessage(message);
  }

  /// Optimistically inserts a just-sent message so it appears instantly
  /// instead of waiting for the server echo.  The echo is deduplicated.
  void addOptimisticMessage(Message message) {
    _insertMessage(message);
  }

  void _insertMessage(Message message) {
    final String conversationId = message.conversationId!;

    // Append — newest message at visual bottom.
    final List<Message> existing = _messagesByChatId[conversationId] ?? [];
    _messagesByChatId[conversationId] = [...existing, message];

    // Move chat to top of sidebar with new message preview
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

    // Single notify — both message panel and sidebar update in one frame.
    notifyListeners();
  }

  /// Returns true if [message] is already the last message in its
  /// conversation (i.e. it was optimistically added), to avoid showing a
  /// duplicate when the server echoes back.
  bool _isDuplicate(Message message) {
    final existing = _messagesByChatId[message.conversationId] ?? [];
    if (existing.isEmpty) return false;
    // Newest message is at the end of the list
    final newest = existing.last;
    return newest.userId == message.userId &&
        newest.conversationId == message.conversationId &&
        (newest.content != null && newest.content == message.content ||
            newest.imageContentUri != null &&
                newest.imageContentUri == message.imageContentUri);
  }

  void _handleChatUpdate(Chat update) {
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

      _chats = response.chats.toList();
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

  void sendChatMessage(String content) {
    _webSocketService.sendMessage(content);
  }

  /// Loads older messages for [chatId] and appends them to the existing list
  /// (they appear at the visual *top* of the reversed ListView).  Sorts by id
  /// so the oldest message is last in the Dart list = visual top.
  Future<void> loadMoreHistory(String chatId) async {
    if (_loadingHistoryChats.contains(chatId)) {
      final inFlight = _historyLoadFutures[chatId];
      if (inFlight != null) {
        await inFlight;
      }
      return;
    }
    if (!(_hasMoreHistory[chatId] ?? true)) return;

    final future = _loadMoreHistory(chatId);
    _historyLoadFutures[chatId] = future;
    await future;
  }

  Future<void> loadMoreHistoryAfterCurrent(String chatId) async {
    final inFlight = _historyLoadFutures[chatId];
    if (inFlight != null) {
      await inFlight;
    }
    if (!(_hasMoreHistory[chatId] ?? true)) return;
    await loadMoreHistory(chatId);
  }

  Future<void> _loadMoreHistory(String chatId) async {
    _loadingHistoryChats.add(chatId);
    notifyListeners();
    var shouldNotify = false;

    try {
      final loadCount = (_historyLoadCount[chatId] ?? 0) + 1;
      const batchSize = 10;
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
        return;
      }

      final allLoaded = response.chats;
      if (allLoaded.isEmpty) {
        _hasMoreHistory[chatId] = false;
        shouldNotify = true;
        return;
      }

      // Sort by id ascending: oldest first → newest last.
      allLoaded.sort((a, b) => (a.id ?? '').compareTo(b.id ?? ''));

      final existing = _messagesByChatId[chatId] ?? [];
      final existingIds = existing.map((e) => e.id).toSet();

      // Only keep messages that aren't already loaded.
      final onlyNew =
          allLoaded.where((m) => !existingIds.contains(m.id)).toList();

      if (onlyNew.isNotEmpty) {
        // Prepend older messages at the start (= visual top).
        _messagesByChatId[chatId] = [...onlyNew, ...existing];
      }

      // More history exists if server returned a full batch.
      _hasMoreHistory[chatId] = allLoaded.length >= limit;
      _historyLoadCount[chatId] = (limit + batchSize - 1) ~/ batchSize;
      shouldNotify = true;
    } catch (_) {
      _hasMoreHistory[chatId] = false;
      shouldNotify = true;
    } finally {
      _loadingHistoryChats.remove(chatId);
      _historyLoadFutures.remove(chatId);
      if (shouldNotify) {
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
    _webSocketService.dispose();
    super.dispose();
  }
}
