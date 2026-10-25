import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Local project imports
import 'package:one_piece_battles_flutter/components/emoji_selection.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:one_piece_battles_flutter/components/square_image_loader.dart';
import 'package:one_piece_battles_flutter/popup/chatting_options.dart';
import 'package:one_piece_battles_flutter/utils/onepiece_image_picker.dart';
import 'package:one_piece_battles_flutter/utils/time_helper.dart';
import 'package:one_piece_battles_flutter/utils/responsive_breakpoints.dart';
import 'package:openapi/api.dart';
import '../../components/chat_notifier.dart';
import '../../components/message.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/base64_helper.dart';
import '../../utils/image_helper.dart';
import 'widgets/add_group_character_dialog.dart';
import 'widgets/chat_detail_drawer.dart';

GetIt getIt = GetIt.instance;

// ─── Apple-style neutral palette, used across the chatting page ───
// Kept local to the chat view so the rest of the app's blue-forward palette
// (OnepieceColors) is untouched; these are the system-gray neutrals that make
// the chat read like Messages: hairline separators, soft fills, muted labels.
const Color _kSeparator = Color(0xFFE5E5EA); // systemGray5 hairline
const Color _kSurface =
    Color(0xFFF2F2F7); // systemGray6 fill (selected / input)
const Color _kSecondaryText = Color(0xFF8E8E93); // systemGray secondary label
const Color _kPrimaryText = Color(0xFF1C1C1E); // primary label

class ChattingView extends StatefulWidget {
  const ChattingView({super.key});

  @override
  State<ChattingView> createState() => _ChattingViewState();
}

class _ChatMessageScrollController extends ScrollController {
  bool _positionAtBottomDuringLayout = false;

  void beginInitialBottomPositioning() {
    _positionAtBottomDuringLayout = true;
  }

  void endInitialBottomPositioning() {
    _positionAtBottomDuringLayout = false;
  }

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _ChatMessageScrollPosition(
      controller: this,
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }
}

class _ChatMessageScrollPosition extends ScrollPositionWithSingleContext {
  _ChatMessageScrollPosition({
    required this.controller,
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  final _ChatMessageScrollController controller;

  /// How far above the previous bottom still counts as "at the bottom" when
  /// deciding whether late content growth should re-pin the view.
  static const double _bottomPinSlack = 8.0;

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    if (controller._positionAtBottomDuringLayout &&
        hasPixels &&
        maxScrollExtent > minScrollExtent) {
      // Only snap to the bottom when we were already sitting there: on the
      // very first layout (no dimensions yet), or when the current offset is
      // still at the previous bottom. This lets late content growth — a
      // message image finishing its load and expanding from the 60px spinner
      // to its real height — re-pin us to the newest message, while leaving a
      // user who has deliberately scrolled up where they are.
      final bool wasAtBottom = !hasContentDimensions ||
          pixels >= this.maxScrollExtent - _bottomPinSlack;
      if (wasAtBottom && (pixels - maxScrollExtent).abs() >= 0.5) {
        correctPixels(maxScrollExtent);
        super.applyContentDimensions(minScrollExtent, maxScrollExtent);
        return false;
      }
    }
    return super.applyContentDimensions(minScrollExtent, maxScrollExtent);
  }
}

class _ChattingViewState extends State<ChattingView> {
  final _ChatMessageScrollController scrollController =
      _ChatMessageScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Controllers
  TextEditingController searchChattingController = TextEditingController();
  TextEditingController typingController = TextEditingController();
  FocusNode focusNode = FocusNode();

  // Local State Caches (drafts — reset on navigation, that's acceptable).
  Map<String, Message?> chatIdToRepliedMessage = {};
  Map<String, String?> chatIdToCachedMessage = {};
  Map<String, Uint8List?> chatIdToCachedImage = {};

  // Scroll offset and the "load-earlier" pagination anchor are NOT kept here:
  // this State is destroyed whenever the user navigates to another page, so
  // they're persisted in ChatNotifier (which survives) and read back on
  // re-entry so we can restore the exact chat + position the user left on.

  final ValueNotifier<Message?> inputMessageNotifier = ValueNotifier(null);
  final ValueNotifier<Message?> inputPreMessageNotifier = ValueNotifier(null);

  /// Cached reference to the app-lifetime ChatNotifier, so scroll-position
  /// persistence works even from [dispose] (where reading a Provider is
  /// unsafe).
  late final ChatNotifier _chatNotifier;

  /// True while we're programmatically positioning the scroll view (restoring
  /// a saved offset or snapping to bottom). Suppresses the scroll listener so
  /// those transient positions aren't mistaken for the user's real position.
  bool _restoringScroll = false;

  // Tracking
  String activeConversationId = "";
  String _lastProcessedChatId = "";
  int _previousMsgCount = 0;

  /// Bumped on every call to [_loadInitialHistoryAndRestoreScroll] so a
  /// superseded call (user switched chats again before it finished) can
  /// tell it's stale and must not touch scroll state on behalf of a chat
  /// that's no longer active.
  int _scrollPositioningRequestId = 0;
  String? _previousNewestMessageId;
  final Set<String> _preservingHistoryScrollChats = {};
  bool _didSelectInitialChat = false;
  bool _activeChatWasAutoSelected = false;

  /// Dedicated notifier for search text — changes here rebuild only the
  /// chat-list filter, not the entire ChattingView.
  final ValueNotifier<String> _searchTextNotifier = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    _chatNotifier = Provider.of<ChatNotifier>(context, listen: false);
    scrollController.addListener(_persistActiveChatScrollOffset);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshChatsAndRestoreOrSelect();
    });
  }

  /// Keeps ChatNotifier's remembered scroll offset for the active chat live on
  /// every user scroll, so leaving the page (which disposes this State) always
  /// preserves the true last position, regardless of dispose ordering.
  void _persistActiveChatScrollOffset() {
    if (_restoringScroll) return;
    if (activeConversationId.isEmpty || !scrollController.hasClients) return;
    _chatNotifier.setViewScrollOffset(
        activeConversationId, scrollController.offset);
  }

  Future<void> _refreshChatsAndRestoreOrSelect() async {
    if (!mounted) return;
    await _chatNotifier.refreshChats();
    if (!mounted) return;
    _restoreOrSelectInitialChat(_chatNotifier);
  }

  /// On entering the chat page, restore the chat the user was last viewing
  /// (remembered in ChatNotifier across navigation). Only auto-select the
  /// first chat on a genuine first entry — nothing remembered yet, or the
  /// remembered chat no longer exists (e.g. after switching users).
  void _restoreOrSelectInitialChat(ChatNotifier notifier) {
    if (_didSelectInitialChat || notifier.chats.isEmpty) return;
    if (ResponsiveBreakpoints.isMobile(context)) return;
    _didSelectInitialChat = true;

    final rememberedId = notifier.activeChatId;
    final bool rememberedStillExists = rememberedId != null &&
        notifier.chats.any((chat) => chat.id == rememberedId);
    final String? targetId =
        rememberedStillExists ? rememberedId : notifier.chats.first.id;
    if (targetId == null) return;

    // Only counts as an auto-selection (which mobile undoes) when we fell
    // back to the first chat rather than restoring the user's own choice.
    _activeChatWasAutoSelected = !rememberedStillExists;
    activeConversationId = targetId;
    _lastProcessedChatId = "";
    typingController.text = chatIdToCachedMessage[targetId] ?? "";
    inputPreMessageNotifier.value = chatIdToRepliedMessage[targetId];

    notifier.setActiveChat(targetId);
    unawaited(_loadInitialHistoryAndRestoreScroll(targetId));
  }

  Future<void> _loadInitialHistoryAndRestoreScroll(String chatId) async {
    final int requestId = ++_scrollPositioningRequestId;
    // Suppress the scroll listener while we position programmatically.
    _restoringScroll = true;
    // Unconditionally cancel any bottom-forcing left on by a previous call
    // to this method that's still in flight (e.g. the user already switched
    // away from the chat that armed it) — otherwise that flag can get stuck
    // `true` forever, which makes every later layout pass (including one
    // triggered by an image finishing loading) snap the view back to the
    // bottom regardless of where it's supposed to be. That stuck-flag state
    // is what caused the "bounces back and forth" behavior.
    scrollController.endInitialBottomPositioning();

    // Capture the remembered offset up front, before any await, so a stray
    // scroll event can't clobber it before we read it.
    final double? savedOffset = _chatNotifier.viewScrollOffset(chatId);
    final bool shouldRestoreSavedOffset = savedOffset != null;
    if (!shouldRestoreSavedOffset) {
      scrollController.beginInitialBottomPositioning();
    }
    await _chatNotifier.ensureHistoryLoaded(chatId);
    if (!mounted || requestId != _scrollPositioningRequestId) {
      _restoringScroll = false;
      return;
    }
    if (shouldRestoreSavedOffset) {
      _restoreScrollForChat(chatId, savedOffset, requestId);
      return; // clears _restoringScroll after the jump completes
    }
    // Hold the bottom-pin until layout stops growing instead of releasing it
    // after a single frame — the first open otherwise lands above the bottom
    // because late layout passes grow the content after the pin was released.
    // Two regimes, because message images are the hard case:
    final messages = _chatNotifier.getMessagesForChat(chatId);
    final bool hasPendingImages =
        messages.any((m) => m.imageContentUri != null);

    if (hasPendingImages) {
      // A message image renders as a fixed 60px spinner and only grows to its
      // real height once the bytes arrive — possibly hundreds of ms later,
      // over the network — so a "layout is stable" check can't see that the
      // content is still going to grow. Instead keep the pin armed for a
      // bounded wall-clock window: firmly sit at the bottom for the first few
      // frames (the user can't have scrolled yet), then let
      // applyContentDimensions re-snap us whenever an image finishes and grows
      // the content (it only re-pins while we're still at the bottom, so it
      // won't fight a user who has started scrolling up to read history).
      final deadline = DateTime.now().add(const Duration(milliseconds: 2500));
      var frame = 0;
      while (DateTime.now().isBefore(deadline)) {
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted || requestId != _scrollPositioningRequestId) {
          _restoringScroll = false;
          return;
        }
        if (!scrollController.hasClients) continue;
        if (frame < 6) {
          final maxExtent = scrollController.position.maxScrollExtent;
          if ((scrollController.offset - maxExtent).abs() > 0.5) {
            scrollController.jumpTo(maxExtent);
          }
        }
        frame++;
      }
    } else {
      // No images: the content reaches its final height within a few frames,
      // so re-assert the bottom each frame until maxScrollExtent is stable.
      double lastMax = double.nan;
      var stableFrames = 0;
      for (var i = 0; i < 30; i++) {
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted || requestId != _scrollPositioningRequestId) {
          _restoringScroll = false;
          return;
        }
        if (!scrollController.hasClients) continue;
        final maxExtent = scrollController.position.maxScrollExtent;
        if ((scrollController.offset - maxExtent).abs() > 0.5) {
          scrollController.jumpTo(maxExtent);
        }
        if (maxExtent == lastMax) {
          if (++stableFrames >= 3) break;
        } else {
          stableFrames = 0;
          lastMax = maxExtent;
        }
      }
    }
    scrollController.endInitialBottomPositioning();
    if (scrollController.hasClients) {
      _chatNotifier.setViewScrollOffset(chatId, scrollController.offset);
    }
    _restoringScroll = false;
  }

  Future<void> _loadEarlierMessages(String chatId) async {
    if (!_chatNotifier.hasMoreHistory(chatId)) return;

    _preservingHistoryScrollChats.add(chatId);
    try {
      final insertedHistoryCount =
          await _chatNotifier.loadMoreHistoryAfterCurrent(
        chatId,
        beforeNotify: (count) {
          _chatNotifier.setViewVisibleStart(
              chatId, _chatNotifier.viewVisibleStart(chatId) + count);
        },
      );
      if (insertedHistoryCount <= 0) return;
      if (scrollController.hasClients) {
        _chatNotifier.setViewScrollOffset(chatId, scrollController.offset);
      }
    } finally {
      _preservingHistoryScrollChats.remove(chatId);
    }
  }

  @override
  void dispose() {
    // Belt-and-suspenders: capture the final scroll position before the
    // controller is torn down, in case the last user scroll didn't reach the
    // live listener (the listener already keeps it current on every scroll).
    if (!_restoringScroll &&
        activeConversationId.isNotEmpty &&
        scrollController.hasClients) {
      _chatNotifier.setViewScrollOffset(
          activeConversationId, scrollController.offset);
    }
    scrollController.removeListener(_persistActiveChatScrollOffset);
    _searchTextNotifier.dispose();
    scrollController.dispose();
    searchChattingController.dispose();
    typingController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  /// ROBUST BACK NAVIGATION & CACHING
  void _clearActiveChat() {
    FocusScope.of(context).unfocus();
    if (activeConversationId.isNotEmpty) {
      chatIdToCachedMessage[activeConversationId] = typingController.text;
      if (scrollController.hasClients) {
        _chatNotifier.setViewScrollOffset(
            activeConversationId, scrollController.offset);
      }
    }
    activeConversationId = "";
    _lastProcessedChatId = "";
    _previousNewestMessageId = null;
    _scrollPositioningRequestId++; // invalidate any in-flight history load
    scrollController.endInitialBottomPositioning();
    _chatNotifier.setActiveChat(null);
    typingController.clear();
    inputPreMessageNotifier.value = null;
  }

  /// Scrolls to bottom when a new message arrives and user is near the bottom.
  void _autoScrollOnNewMessages(List<Message> messages, String activeChatId) {
    final newestMessageId = messages.isEmpty ? null : messages.last.id;
    if (activeChatId != _lastProcessedChatId) {
      _lastProcessedChatId = activeChatId;
      _previousMsgCount = messages.length;
      _previousNewestMessageId = newestMessageId;
      return;
    }
    if (messages.length > _previousMsgCount) {
      _previousMsgCount = messages.length;
      if (_preservingHistoryScrollChats.contains(activeChatId)) {
        _previousNewestMessageId = newestMessageId;
        return;
      }
      if (newestMessageId == _previousNewestMessageId) {
        return;
      }
      _previousNewestMessageId = newestMessageId;
      if (!scrollController.hasClients) return;
      if (scrollController.position.maxScrollExtent -
              scrollController.position.pixels <
          500) {
        _scrollToBottom();
      }
    }
  }

  void _restoreScrollForChat(String chatId, double savedOffset, int requestId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || requestId != _scrollPositioningRequestId) {
        _restoringScroll = false;
        return;
      }
      if (scrollController.hasClients) {
        final minOffset = scrollController.position.minScrollExtent;
        final maxOffset = scrollController.position.maxScrollExtent;
        final target = savedOffset.clamp(minOffset, maxOffset).toDouble();
        scrollController.jumpTo(target);
        _chatNotifier.setViewScrollOffset(chatId, target);
      }
      _restoringScroll = false;
    });
  }

  User? _findChatMember(Chat chat, String? userId) {
    if (userId == null) return null;
    for (final member in chat.members) {
      if (member.id == userId) return member;
    }
    return null;
  }

  User _messageMemberOrFallback(Chat chat, Message message) {
    return _findChatMember(chat, message.userId) ??
        User(
          id: message.userId ?? '',
          username: message.userId ?? '',
          nickname: AppLocalizations.of(context)!.user,
          imageUri: '',
        );
  }

  String _memberNicknameOrFallback(Chat chat, String? userId) {
    return _findChatMember(chat, userId)?.nickname ??
        AppLocalizations.of(context)!.user;
  }

  bool _shouldShowTimeAfterMessage(List<Message> messages, int messageIndex) {
    if (messageIndex < 0 || messageIndex >= messages.length - 1) return false;
    final currentTimestamp =
        messages[messageIndex].creationRecord?.actionTimestamp;
    final nextTimestamp =
        messages[messageIndex + 1].creationRecord?.actionTimestamp;
    if (currentTimestamp == null || nextTimestamp == null) return false;
    return nextTimestamp - currentTimestamp >
        const Duration(minutes: 30).inMilliseconds;
  }

  Widget _buildMessageTimeMarker(BuildContext context, Message message) {
    final timestamp = message.creationRecord?.actionTimestamp;
    if (timestamp == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: OnepieceColors.menuHoverColor.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            _messageTimeLabel(context, timestamp),
            style: OnepieceFonts.superSmallContentStyle
                .copyWith(color: Colors.grey[700]),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageListItem(
    Chat activeChat,
    List<Message> messages,
    int messageIndex,
  ) {
    final msg = messages[messageIndex];
    final showTimeAfter = _shouldShowTimeAfterMessage(messages, messageIndex);

    return Padding(
      key: ValueKey('message_row_${msg.id}'),
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MessageItem(
            key: ValueKey(msg.id),
            message: msg,
            isMe: msg.userId == getIt<User>().id,
            preMessage: msg.preMessage,
            user: _messageMemberOrFallback(activeChat, msg),
            preMessageNickname: msg.preMessage != null
                ? _memberNicknameOrFallback(activeChat, msg.preMessage!.userId)
                : null,
            replyMessage: (msg) {
              // A still-optimistic message (client-generated 'opt_' id, not
              // yet echoed back by the server) has no real id the backend
              // can store as a reply target — referencing it would send an
              // unparseable preMessageId and fail server-side. Block it here
              // rather than let that request error out.
              if ((msg.id ?? '').startsWith('opt_')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(AppLocalizations.of(context)!.messageStillSending),
                  ),
                );
                return;
              }
              chatIdToRepliedMessage[msg.conversationId!] = msg;
              inputPreMessageNotifier.value = msg;
              Future.delayed(Duration.zero, () {
                if (focusNode.canRequestFocus) {
                  focusNode.requestFocus();
                }
              });
            },
          ),
          if (showTimeAfter) _buildMessageTimeMarker(context, msg),
        ],
      ),
    );
  }

  String _messageTimeLabel(BuildContext context, int timestampMillis) {
    final now = DateTime.now();
    final target = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(target.year, target.month, target.day);
    final dayDiff = today.difference(targetDay).inDays;
    final locale = Localizations.localeOf(context).toString();
    final time = DateFormat.jm(locale).format(target);

    if (dayDiff == 0) return time;
    if (dayDiff == 1) {
      return '${AppLocalizations.of(context)!.yesterday} $time';
    }
    if (dayDiff > 1 && dayDiff < 7) {
      return '${_localizedWeekday(context, target.weekday)} $time';
    }
    return '${DateFormat.yMMMd(locale).format(target)} $time';
  }

  String _localizedWeekday(BuildContext context, int weekday) {
    final l10n = AppLocalizations.of(context)!;
    return switch (weekday) {
      DateTime.monday => l10n.monday,
      DateTime.tuesday => l10n.tuesday,
      DateTime.wednesday => l10n.wednesday,
      DateTime.thursday => l10n.thursday,
      DateTime.friday => l10n.friday,
      DateTime.saturday => l10n.saturday,
      DateTime.sunday => l10n.sunday,
      _ => '',
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // The top-level build does NOT watch ChatNotifier.  Instead, Selector
  // widgets below subscribe to only the slices of state they need, so:
  //   • a new message rebuilds only the message list and the one affected
  //     sidebar row (not the whole page)
  //   • changing the search text rebuilds only the chat list filter
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile =
            ResponsiveBreakpoints.isMobileFromConstraints(constraints);

        if (isMobile) {
          return _buildMobileLayout(isMobile);
        }
        if (!_didSelectInitialChat) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _restoreOrSelectInitialChat(_chatNotifier);
          });
        }
        return _buildDesktopLayout(isMobile);
      },
    );
  }

  // ── Mobile: full-screen list OR full-screen message view ──────────────

  Widget _buildMobileLayout(bool isMobile) {
    return Selector<ChatNotifier, String?>(
      selector: (_, notifier) => notifier.activeChatId,
      builder: (context, activeChatId, _) {
        if (activeChatId != null && _activeChatWasAutoSelected) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _activeChatWasAutoSelected = false;
            _clearActiveChat();
          });
          return _buildChatListPanel(isMobile: isMobile);
        }
        if (activeChatId == null) {
          return _buildChatListPanel(isMobile: isMobile);
        }
        final activeChat = context.read<ChatNotifier>().activeChat;
        if (activeChat == null) {
          return _buildChatListPanel(isMobile: isMobile);
        }
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, dynamic result) {
            if (didPop) return;
            _clearActiveChat();
          },
          child:
              _buildChatView(context, activeChat, activeChatId, isMobile: true),
        );
      },
    );
  }

  // ── Desktop: sidebar + message area side by side ─────────────────────

  Widget _buildDesktopLayout(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        SizedBox(
          width: 300,
          child: _buildChatListPanel(isMobile: false),
        ),
        const VerticalDivider(
          thickness: 0.5,
          color: _kSeparator,
          width: 1,
        ),
        Expanded(child: _buildMessagePanel(isMobile)),
      ],
    );
  }

  // ── Sidebar panel (chat list) ────────────────────────────────────────

  Widget _buildChatListPanel({required bool isMobile}) {
    // Outer: rebuilds when chats are added / reordered / get new messages
    return Selector<ChatNotifier, int>(
      selector: (_, n) => n.chatListVersion,
      builder: (context, _, __) {
        // Inner: rebuilds when the selected chat changes (highlight)
        return Selector<ChatNotifier, String?>(
          selector: (_, n) => n.activeChatId,
          builder: (context, activeChatId, __) {
            final chats = context.read<ChatNotifier>().chats;
            return _buildChatList(context, chats, activeChatId,
                isMobile: isMobile);
          },
        );
      },
    );
  }

  // ── Message panel (right side / full screen) ─────────────────────────

  Widget _buildMessagePanel(bool isMobile) {
    return Selector<ChatNotifier, String?>(
      selector: (_, notifier) => notifier.activeChatId,
      builder: (context, activeChatId, _) {
        if (activeChatId == null) {
          return Center(
            child: ImageHelper.getSvgIconWithColor(
                'images/svgs/ship.svg', 200, 200, OnepieceColors.liteFancyBlue),
          );
        }
        final notifier = context.read<ChatNotifier>();
        final activeChat = notifier.activeChat;
        if (activeChat == null) {
          return const SizedBox.shrink();
        }
        return _buildChatView(context, activeChat, activeChatId,
            isMobile: isMobile);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // LEFT SIDE: Chat List
  // ---------------------------------------------------------------------------
  Widget _buildChatList(
      BuildContext context, List<Chat> chats, String? activeChatId,
      {required bool isMobile}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextFormField(
                    controller: searchChattingController,
                    onChanged: (value) {
                      // Update the notifier — rebuilds only the filtered list
                      _searchTextNotifier.value = value;
                    },
                    style: const TextStyle(fontSize: 15, color: _kPrimaryText),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: _kSurface,
                      contentPadding: EdgeInsets.zero,
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      hintText: AppLocalizations.of(context)!.name,
                      hintStyle:
                          const TextStyle(fontSize: 15, color: _kSecondaryText),
                      prefixIcon: const Icon(Icons.search,
                          size: 19, color: _kSecondaryText),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ChattingOptions(context: context)
            ],
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<String>(
            valueListenable: _searchTextNotifier,
            builder: (context, searchValue, _) {
              final searchText = searchValue.toLowerCase();
              final displayChats = searchText.isEmpty
                  ? chats
                  : chats.where((chat) {
                      final name = chatDisplayName(chat);
                      return name.toLowerCase().contains(searchText);
                    }).toList();

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 12),
                itemCount: displayChats.length,
                addAutomaticKeepAlives: true,
                itemBuilder: (context, index) {
                  final chat = displayChats[index];
                  final isSelected = activeChatId == chat.id;
                  return Padding(
                    // Key is crucial for reordering animations/updates
                    key: ValueKey(chat.id),
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          final newChatId = chat.id!;

                          // If the tapped chat is already active, do nothing.
                          if (activeConversationId == newChatId) return;

                          // Handle focus & draft/scroll caching for the OLD chat.
                          FocusScope.of(context).unfocus();
                          if (activeConversationId.isNotEmpty) {
                            chatIdToCachedMessage[activeConversationId] =
                                typingController.text;
                            if (scrollController.hasClients) {
                              _chatNotifier.setViewScrollOffset(
                                  activeConversationId,
                                  scrollController.offset);
                            }
                          }

                          // Update local state for the NEW chat.
                          activeConversationId = newChatId;
                          _activeChatWasAutoSelected = false;
                          _lastProcessedChatId = ""; // Reset scroll logic

                          // Restore drafts for the NEW chat.
                          typingController.text =
                              chatIdToCachedMessage[newChatId] ?? "";
                          inputPreMessageNotifier.value =
                              chatIdToRepliedMessage[newChatId];

                          // Switch the active chat, then load/restore history.
                          Provider.of<ChatNotifier>(context, listen: false)
                              .setActiveChat(newChatId);
                          unawaited(
                              _loadInitialHistoryAndRestoreScroll(newChatId));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected ? _kSurface : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              chat.group == true
                                  ? getLeading(chat.members
                                      .map((e) => e.imageUri ?? '')
                                      .toList())
                                  : getSingleLeading(chat),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            chatDisplayName(chat),
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: _kPrimaryText,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        if (chat.message?.creationRecord
                                                ?.actionTimestamp !=
                                            null)
                                          Text(
                                            TimeHelper.humanDateFromTimestamp(
                                                chat.message!.creationRecord!
                                                    .actionTimestamp!,
                                                context),
                                            style: const TextStyle(
                                                color: _kSecondaryText,
                                                fontSize: 12),
                                          )
                                        else
                                          Text(
                                            AppLocalizations.of(context)!
                                                .newConversation,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color:
                                                    OnepieceColors.fancyGreen),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: _buildChatPreview(
                                              context, chat, activeChatId),
                                        ),
                                        if (chat.unreadCount != null &&
                                            chat.unreadCount! > 0)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(left: 6),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            constraints: const BoxConstraints(
                                              minWidth: 20,
                                              minHeight: 20,
                                            ),
                                            decoration: BoxDecoration(
                                              color: OnepieceColors.fancyBlue,
                                              borderRadius:
                                                  BorderRadius.circular(11),
                                            ),
                                            child: Text(
                                              chat.unreadCount! > 99
                                                  ? '99+'
                                                  : chat.unreadCount.toString(),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ); // ListView.builder
            }, // ValueListenableBuilder builder
          ), // ValueListenableBuilder
        ), // Expanded
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // RIGHT SIDE: Active Chat View
  // ---------------------------------------------------------------------------
  Widget _buildChatView(
      BuildContext context, Chat activeChat, String activeChatId,
      {required bool isMobile}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(isMobile ? 4 : 18, 10, 6, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: _kSeparator, width: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isMobile)
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _clearActiveChat,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Icon(Icons.arrow_back_ios_new,
                        size: 20, color: OnepieceColors.fancyBlue),
                  ),
                ),
              Expanded(
                child: Text(
                  chatDisplayName(activeChat),
                  textAlign: isMobile ? TextAlign.center : TextAlign.start,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kPrimaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  final scaffold = _scaffoldKey.currentState;
                  if (scaffold == null) return;
                  if (scaffold.isEndDrawerOpen) {
                    Navigator.of(context).pop();
                  } else {
                    scaffold.openEndDrawer();
                  }
                },
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                splashRadius: 1,
                icon: const Icon(
                  Icons.more_horiz,
                  color: OnepieceColors.fancyBlue,
                  size: 22,
                ),
              )
            ],
          ),
        ),
        Expanded(
          child: Scaffold(
            key: _scaffoldKey,
            drawerEnableOpenDragGesture: true,
            drawerScrimColor: Colors.transparent,
            endDrawer: ChatDetailDrawer(
              chat: activeChat,
              currentUserId: getIt<User>().id,
              onRenameChat: (newName) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!
                        .groupRenameApiNotConnected),
                  ),
                );
              },
              onAddMember: () {
                final groupId = activeChat.id;
                if (groupId == null) return;
                showDialog(
                  context: context,
                  builder: (dialogContext) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    child: AddGroupCharacterDialog(groupId: groupId),
                  ),
                );
              },
            ),
            body: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  // Only the message list rebuilds when this chat's messages
                  // change — the header and input bar above/below stay put, so
                  // receiving a message no longer rebuilds the text field you
                  // are typing in.
                  child: Selector<ChatNotifier, List<Message>>(
                    selector: (_, n) => n.getMessagesForChat(activeChatId),
                    builder: (context, messages, _) {
                      _autoScrollOnNewMessages(messages, activeChatId);
                      return Builder(builder: (context) {
                        final visibleStart = _chatNotifier
                            .viewVisibleStart(activeChatId)
                            .clamp(0, messages.length)
                            .toInt();
                        final centerKey = ValueKey('chat_center_$activeChatId');

                        return CustomScrollView(
                          key: ValueKey('chat_scroll_$activeChatId'),
                          controller: scrollController,
                          center: centerKey,
                          cacheExtent: 5000,
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(15, 0, 20, 0),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    if (index == visibleStart) {
                                      return _buildHistoryControl(activeChatId);
                                    }

                                    final messageIndex =
                                        visibleStart - index - 1;
                                    return _buildMessageListItem(
                                      activeChat,
                                      messages,
                                      messageIndex,
                                    );
                                  },
                                  childCount: visibleStart + 1,
                                ),
                              ),
                            ),
                            SliverPadding(
                              key: centerKey,
                              padding: const EdgeInsets.fromLTRB(15, 0, 20, 0),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final messageIndex = visibleStart + index;
                                    return _buildMessageListItem(
                                      activeChat,
                                      messages,
                                      messageIndex,
                                    );
                                  },
                                  childCount: messages.length - visibleStart,
                                ),
                              ),
                            ),
                          ],
                        );
                      });
                    },
                  ),
                ),
                StatefulBuilder(
                  builder: (BuildContext context, StateSetter buttonState) {
                    return ValueListenableBuilder<TextEditingValue>(
                      valueListenable: typingController,
                      builder: (context, textValue, child) {
                        Future<void> pickImage() async {
                          final XFile? pickedImage =
                              await OnepieceImagePicker.pickWebImage();

                          if (!context.mounted || pickedImage == null) {
                            return;
                          }

                          chatIdToCachedImage[activeChatId] =
                              await pickedImage.readAsBytes();
                          buttonState(() {});
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (focusNode.canRequestFocus) {
                              focusNode.requestFocus();
                            }
                          });
                        }

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── Composer: pill field + circular send button ──
                            Builder(builder: (ctx) {
                              final hasImage =
                                  chatIdToCachedImage[activeChatId] != null;
                              final canSend =
                                  typingController.text.trim().isNotEmpty ||
                                      hasImage;

                              void clearAttachedImage() {
                                chatIdToCachedImage[activeChatId] = null;
                                buttonState(() {});
                              }

                              void sendCurrentMessage() {
                                buttonState(() {
                                  final hasText =
                                      typingController.text.trim().isNotEmpty;
                                  final hasImage =
                                      chatIdToCachedImage[activeChatId] != null;
                                  if (!hasText && !hasImage) return;
                                  final encodedImage = hasImage
                                      ? Base64Helper.encode(
                                          chatIdToCachedImage[activeChatId]!)
                                      : null;

                                  final SendMessageRequest request =
                                      SendMessageRequest(
                                    content: hasText
                                        ? typingController.text.trim()
                                        : null,
                                    userId: getIt<User>().id,
                                    profileImage: encodedImage,
                                    conversationId: activeChat.id!,
                                    type: MessageType.SEND_MESSAGE,
                                    preMessageId:
                                        inputPreMessageNotifier.value?.id,
                                  );

                                  if (hasText || hasImage) {
                                    Provider.of<ChatNotifier>(context,
                                            listen: false)
                                        .addOptimisticMessage(Message(
                                      id: 'opt_${DateTime.now().millisecondsSinceEpoch}',
                                      userId: getIt<User>().id,
                                      conversationId: activeChat.id!,
                                      content: hasText
                                          ? typingController.text.trim()
                                          : null,
                                      imageContentUri: encodedImage == null
                                          ? null
                                          : 'data:image;base64,$encodedImage',
                                      creationRecord: ActionRecord(
                                        actionTimestamp: DateTime.now()
                                            .millisecondsSinceEpoch,
                                        nickname: getIt<User>().nickname,
                                      ),
                                      preMessageId:
                                          inputPreMessageNotifier.value?.id,
                                      preMessage: inputPreMessageNotifier.value,
                                    ));
                                  }

                                  final String jsonMessage =
                                      jsonEncode(request.toJson());
                                  final bool sent = Provider.of<ChatNotifier>(
                                          context,
                                          listen: false)
                                      .sendChatMessage(jsonMessage);
                                  if (!sent) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            AppLocalizations.of(context)!
                                                .messageNotSent),
                                      ),
                                    );
                                  }

                                  chatIdToCachedImage[activeChatId] = null;
                                  chatIdToRepliedMessage[activeChatId] = null;
                                  chatIdToCachedMessage[activeChatId] = null;
                                  inputPreMessageNotifier.value = null;
                                  typingController.clear();

                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (focusNode.canRequestFocus) {
                                      focusNode.requestFocus();
                                    }
                                  });
                                });
                              }

                              // Shared TextField used in both layouts
                              final typingField = TextField(
                                controller: typingController,
                                enabled: true,
                                textAlign: TextAlign.start,
                                minLines: 1,
                                maxLines: isMobile ? 5 : 6,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.send,
                                autofocus: true,
                                cursorHeight: 16,
                                focusNode: focusNode,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: _kPrimaryText,
                                  height: 1.3,
                                ),
                                onChanged: (value) {},
                                onSubmitted: (_) => sendCurrentMessage(),
                                decoration: InputDecoration(
                                  isCollapsed: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 9),
                                  hintText:
                                      AppLocalizations.of(context)!.message,
                                  hintStyle: const TextStyle(
                                      color: _kSecondaryText, fontSize: 15),
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.never,
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                ),
                              );
                              final typingBox = ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: 24,
                                  maxHeight: isMobile ? 120 : 150,
                                ),
                                child: typingField,
                              );

                              // Unified composer for desktop and mobile:
                              // reply chip + attachment thumb stacked above a
                              // rounded pill (photo button, growing text field,
                              // inline emoji) and a circular send button.
                              return Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                    top: BorderSide(
                                        color: _kSeparator, width: 0.5),
                                  ),
                                ),
                                padding: EdgeInsets.fromLTRB(
                                  isMobile ? 8 : 16,
                                  8,
                                  isMobile ? 8 : 16,
                                  isMobile ? 10 : 14,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Reply context chip
                                    ValueListenableBuilder<Message?>(
                                      valueListenable: inputPreMessageNotifier,
                                      builder: (context, value, _) {
                                        final replied = chatIdToRepliedMessage[
                                            activeChatId];
                                        if (replied == null) {
                                          return const SizedBox.shrink();
                                        }
                                        return Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.fromLTRB(
                                              10, 8, 4, 8),
                                          decoration: const BoxDecoration(
                                            color: _kSurface,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(12)),
                                            border: Border(
                                              left: BorderSide(
                                                  color:
                                                      OnepieceColors.fancyBlue,
                                                  width: 3),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      _memberNicknameOrFallback(
                                                          activeChat,
                                                          replied.userId),
                                                      style: const TextStyle(
                                                        color: OnepieceColors
                                                            .fancyBlue,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    if (replied.content != null)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 2),
                                                        child: Text(
                                                          replied.content!,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                            color:
                                                                _kSecondaryText,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                      ),
                                                    if (replied
                                                            .imageContentUri !=
                                                        null)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 4),
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                          child:
                                                              SquareImageLoader(
                                                            uriProvider: () =>
                                                                replied
                                                                    .imageContentUri!,
                                                            width: 36,
                                                            borderWidth: 1,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  chatIdToRepliedMessage[
                                                      activeChatId] = null;
                                                  inputPreMessageNotifier
                                                      .value = null;
                                                  Future.delayed(Duration.zero,
                                                      () {
                                                    if (focusNode
                                                        .canRequestFocus) {
                                                      focusNode.requestFocus();
                                                    }
                                                  });
                                                },
                                                child: const Padding(
                                                  padding: EdgeInsets.all(4),
                                                  child: Icon(Icons.close,
                                                      size: 18,
                                                      color: _kSecondaryText),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    // Pending attachment thumbnail
                                    if (hasImage)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 8, left: 2),
                                        child: _buildAttachmentThumb(
                                          chatIdToCachedImage[activeChatId]!,
                                          clearAttachedImage,
                                        ),
                                      ),
                                    // Composer row
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        _buildComposerIcon(
                                          icon: Icons.photo_outlined,
                                          onTap: pickImage,
                                        ),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                  color: _kSeparator),
                                            ),
                                            padding: const EdgeInsets.fromLTRB(
                                                14, 2, 6, 2),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Expanded(child: typingBox),
                                                EmojiSelection(
                                                  editingController:
                                                      typingController,
                                                  focusNode: focusNode,
                                                  iconColor: _kSecondaryText,
                                                  iconSize: 22,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        _buildSendButton(
                                          enabled: canSend,
                                          onSend: sendCurrentMessage,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    );
                  },
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryControl(String activeChatId) {
    return Consumer<ChatNotifier>(builder: (context, notifier, _) {
      final isLoading = notifier.isLoadingHistory(activeChatId);
      final hasMore = notifier.hasMoreHistory(activeChatId);

      if (isLoading) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 14),
          child: Center(
            child: SizedBox(
              height: 36,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: OnepieceColors.liteFancyGreen.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.loading,
                        style: OnepieceFonts.superSmallContentStyle,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      if (!hasMore) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 14),
          child: Center(
            child: SizedBox(
              height: 36,
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.noEarlierMessages,
                  style: OnepieceFonts.superSmallContentStyle
                      .copyWith(color: Colors.grey[600]),
                ),
              ),
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 14),
        child: Center(
          child: SizedBox(
            height: 36,
            child: Center(
              child: TextButton.icon(
                onPressed: () => _loadEarlierMessages(activeChatId),
                icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                label: Text(AppLocalizations.of(context)!.loadEarlierMessages),
                style: TextButton.styleFrom(
                  foregroundColor: OnepieceColors.fancyBlue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side:
                        const BorderSide(color: OnepieceColors.liteFancyGreen),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  /// Last-message preview line for a chat-list row: a red "[draft]" marker
  /// when there's an unsent draft for a chat you aren't currently in,
  /// otherwise the sender + first line of the latest message.
  Widget _buildChatPreview(
      BuildContext context, Chat chat, String? activeChatId) {
    final bool hasDraft = (chatIdToRepliedMessage[chat.id] != null ||
            (chatIdToCachedMessage[chat.id] != null &&
                chatIdToCachedMessage[chat.id]!.isNotEmpty)) &&
        activeChatId != chat.id;
    if (hasDraft) {
      return Text(
        "[${AppLocalizations.of(context)!.draft}]",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.red, fontSize: 13),
      );
    }
    if (chat.message != null) {
      final nickname = _memberNicknameOrFallback(chat, chat.message!.userId);
      final preview = chat.message!.content != null
          ? chat.message!.content!.split('\n').first
          : AppLocalizations.of(context)!.image;
      return Text(
        "$nickname: $preview",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: _kSecondaryText, fontSize: 13),
      );
    }
    return const SizedBox.shrink();
  }

  /// Circular iMessage-style send button: filled brand blue when there's
  /// something to send, a muted disc otherwise, with a subtle scale-in.
  Widget _buildSendButton(
      {required bool enabled, required VoidCallback onSend}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: AnimatedScale(
        scale: enabled ? 1.0 : 0.85,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          color: enabled ? OnepieceColors.fancyBlue : const Color(0xFFCBD2DA),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled ? onSend : null,
            child: const SizedBox(
              width: 34,
              height: 34,
              child: Icon(Icons.arrow_upward_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  /// A flat, feedback-free composer affordance (e.g. the photo picker).
  Widget _buildComposerIcon(
      {required IconData icon, required VoidCallback onTap}) {
    return IconButton(
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      splashRadius: 0.1,
      visualDensity: VisualDensity.compact,
      enableFeedback: false,
      icon: Icon(icon, size: 24, color: OnepieceColors.fancyBlue),
    );
  }

  /// The pending-attachment thumbnail shown above the composer, with a
  /// close badge to drop it before sending.
  Widget _buildAttachmentThumb(Uint8List bytes, VoidCallback onRemove) {
    return Stack(
      alignment: AlignmentDirectional.topStart,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          right: -6,
          top: -6,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              margin: const EdgeInsets.all(4),
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 13, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  /// Scrolls to the bottom of the message list.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    });
  }

  User getTargetMember(Chat chat) {
    if (chat.members.first.id == getIt<User>().id) {
      return chat.members.last;
    } else {
      return chat.members.first;
    }
  }

  /// Both `group` and `name` are nullable on the generated [Chat] model —
  /// falls back to the other member's nickname (or an empty group name)
  /// instead of crashing when either is missing.
  String chatDisplayName(Chat chat) {
    if (chat.group == true) {
      return chat.name ?? '';
    }
    return getTargetMember(chat).nickname;
  }

  Widget getLeading(List<String> imageUrls) {
    final List<String> displayedImages =
        imageUrls.length > 9 ? imageUrls.sublist(0, 9) : imageUrls;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: OnepieceColors.liteFancyBlue,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: GridView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(2),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 1.0,
            mainAxisSpacing: 1.0,
          ),
          itemCount: displayedImages.length,
          itemBuilder: (context, index) {
            return SquareImageLoader(
                key: ValueKey(displayedImages[index]),
                uriProvider: () => displayedImages[index],
                width: 40,
                borderWidth: 0.5);
          },
        ),
      ),
    );
  }

  Widget getSingleLeading(Chat chat) {
    final uri = getTargetMember(chat).imageUri ?? '';
    return SizedBox(
      width: 48,
      height: 48,
      child: ImageLazyLoader(
        key: ValueKey(uri),
        uriProvider: () => uri,
        width: 46,
        borderWidth: 1,
        borderRadios: 23,
      ),
    );
  }
}
