import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Local project imports
import 'package:one_piece_battles_flutter/components/emoji_selection.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:one_piece_battles_flutter/components/square_image_loader.dart';
import 'package:one_piece_battles_flutter/popup/chatting_options.dart';
import 'package:one_piece_battles_flutter/utils/onepiece_image_picker.dart';
import 'package:one_piece_battles_flutter/utils/time_helper.dart';
import 'package:openapi/api.dart';
import '../../components/chat_notifier.dart';
import '../../components/message.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/base64_helper.dart';
import '../../utils/image_helper.dart';

GetIt getIt = GetIt.instance;

class ChattingView extends StatefulWidget {
  const ChattingView({super.key});

  @override
  State<ChattingView> createState() => _ChattingViewState();
}

class _ChattingViewState extends State<ChattingView> {
  final ScrollController scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Controllers
  TextEditingController searchChattingController = TextEditingController();
  TextEditingController typingController = TextEditingController();
  FocusNode focusNode = FocusNode();
  // 1. ADD THIS CONTROLLER
  TextEditingController chatNameController = TextEditingController();

  // 2. ADD THIS TRACKER (to prevent overwriting text while typing)
  String? _currentNameChatId;

  // Local State Caches
  Map<String, Message?> chatIdToRepliedMessage = {};
  Map<String, String?> chatIdToCachedMessage = {};
  Map<String, Uint8List?> chatIdToCachedImage = {};
  Map<String, double> chatIdToScrollOffset = {};

  final ValueNotifier<Message?> inputMessageNotifier = ValueNotifier(null);
  final ValueNotifier<Message?> inputPreMessageNotifier = ValueNotifier(null);

  // Tracking
  String activeConversationId = "";
  String _lastProcessedChatId = "";
  int _previousMsgCount = 0;

  /// Dedicated notifier for search text — changes here rebuild only the
  /// chat-list filter, not the entire ChattingView.
  final ValueNotifier<String> _searchTextNotifier = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchTextNotifier.dispose();
    scrollController.dispose();
    searchChattingController.dispose();
    typingController.dispose();
    focusNode.dispose();
    chatNameController.dispose();
    super.dispose();
  }

  /// ROBUST BACK NAVIGATION & CACHING
  void _clearActiveChat() {
    // 1. Unfocus keyboard
    FocusScope.of(context).unfocus();

    // 2. Cache current text
    if (activeConversationId.isNotEmpty) {
      chatIdToCachedMessage[activeConversationId] = typingController.text;
    }

    // 3. Reset Local Variables
    activeConversationId = "";
    _lastProcessedChatId = "";
    _currentNameChatId = null;

    // 4. Update Provider
    Provider.of<ChatNotifier>(context, listen: false).setActiveChat(null);

    // 5. Clear controllers manually
    typingController.clear();
    chatNameController.clear();
    inputPreMessageNotifier.value = null;
  }

  /// Scrolls to bottom when a new message arrives and the user is near the
  /// bottom.  Called from Selector builders (only fires when messages change).
  void _autoScrollOnNewMessages(List<Message> messages, String activeChatId) {
    if (activeChatId != _lastProcessedChatId) {
      _lastProcessedChatId = activeChatId;
      _previousMsgCount = messages.length;
      return;
    }
    if (messages.length > _previousMsgCount) {
      _previousMsgCount = messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          final double maxScroll =
              scrollController.position.maxScrollExtent;
          final double currentScroll = scrollController.offset;
          if (maxScroll - currentScroll < 500) {
            _scrollToBottom(0);
          }
        }
      });
    }
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
        final bool isMobile = constraints.maxWidth < 500;

        if (isMobile) {
          return _buildMobileLayout(isMobile);
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
        if (activeChatId == null) {
          return _buildChatListPanel(isMobile: isMobile);
        }
        final activeChat = context.read<ChatNotifier>().activeChat;
        if (activeChat == null) {
          return _buildChatListPanel(isMobile: isMobile);
        }
        // Nested Selector for messages — avoids context.select in builder
        return Selector<ChatNotifier, List<Message>>(
          selector: (_, n) => n.getMessagesForChat(activeChatId),
          builder: (_, messages, __) {
            _autoScrollOnNewMessages(messages, activeChatId);
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (bool didPop, dynamic result) {
                if (didPop) return;
                _clearActiveChat();
              },
              child: _buildChatView(context, activeChat, activeChatId,
                  messages, isMobile: true),
            );
          },
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
          thickness: 1.2,
          color: OnepieceColors.liteFancyGreen,
          indent: 10,
          endIndent: 8,
          width: 2,
        ),
        Expanded(child: _buildMessagePanel(isMobile)),
      ],
    );
  }

  // ── Sidebar panel (chat list) ────────────────────────────────────────

  Widget _buildChatListPanel({required bool isMobile}) {
    return Selector<ChatNotifier, List<Chat>>(
      selector: (_, n) => n.chats,
      builder: (context, chats, _) {
        // Non-reactive read for the selected-highlight — updates on next
        // chat-list change, which is frequent enough in practice.
        final activeChatId = context.read<ChatNotifier>().activeChatId;
        return _buildChatList(context, chats, activeChatId,
            isMobile: isMobile);
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
        // Nested Selector for messages — avoids context.select in builder
        return Selector<ChatNotifier, List<Message>>(
          selector: (_, n) => n.getMessagesForChat(activeChatId),
          builder: (_, messages, __) {
            _autoScrollOnNewMessages(messages, activeChatId);
            return _buildChatView(context, activeChat, activeChatId, messages,
                isMobile: isMobile);
          },
        );
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: SizedBox(
                  height: 35,
                  child: TextFormField(
                    controller: searchChattingController,
                    onChanged: (value) {
                      // Update the notifier — rebuilds only the filtered list
                      _searchTextNotifier.value = value;
                    },
                    decoration: InputDecoration(
                      labelStyle: OnepieceFonts.dropDownItemStyle,
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      disabledBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: OnepieceColors.menuHoverColor)),
                      enabledBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: OnepieceColors.menuHoverColor)),
                      focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                              color: OnepieceColors.fancyGreen, width: 1.5)),
                      prefixIcon: const Icon(Icons.search),
                      labelText: AppLocalizations.of(context)!.name,
                    ),
                  ),
                ),
              ),
            ),
            ChattingOptions(context: context)
          ],
        ),
        Expanded(
          child: ValueListenableBuilder<String>(
            valueListenable: _searchTextNotifier,
            builder: (context, searchValue, _) {
              final searchText = searchValue.toLowerCase();
              final displayChats = searchText.isEmpty
                  ? chats
                  : chats.where((chat) {
                      final name = chat.group!
                          ? chat.name!
                          : getTargetMember(chat).nickname;
                      return name.toLowerCase().contains(searchText);
                    }).toList();

              return ListView.builder(
                itemCount: displayChats.length,
                addAutomaticKeepAlives: true,
                itemBuilder: (context, index) {
                  final chat = displayChats[index];
                  return ListTile(
                // Key is crucial for reordering animations/updates
                key: ValueKey(chat.id),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chat Name
                        Expanded(
                          child: Text(
                            chat.group!
                                ? chat.name!
                                : getTargetMember(chat).nickname,
                            overflow: TextOverflow.ellipsis,
                            style: OnepieceFonts.smallContentFancyBlueStyle,
                          ),
                        ),
                        const SizedBox(width: 5),

                        // RIGHT COLUMN: Date & Unread Badge
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (chat.message != null)
                              Text(
                                TimeHelper.humanDateFromTimestamp(
                                    chat.message!.creationRecord!
                                        .actionTimestamp!,
                                    context),
                                style: OnepieceFonts.boldLiteFancySmallFont,
                              )
                            else
                              // Fallback for new chats without messages
                              const Text(
                                "New",
                                style: TextStyle(
                                    fontSize: 10, color: Colors.green),
                              ),

                            // --- UNREAD COUNT BADGE ---
                            if (chat.unreadCount != null &&
                                chat.unreadCount! > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 5),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  chat.unreadCount! > 99
                                      ? '99+'
                                      : chat.unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Draft Indicator OR Last Message Preview
                    if ((chatIdToRepliedMessage[chat.id] != null ||
                            (chatIdToCachedMessage[chat.id] != null &&
                                chatIdToCachedMessage[chat.id]!.isNotEmpty)) &&
                        activeChatId != chat.id)
                      Text(
                        "[${AppLocalizations.of(context)!.draft}]",
                        style: OnepieceFonts.smallContentStyle
                            .copyWith(color: Colors.red),
                      )
                    else if (chat.message != null)
                      Text(
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: OnepieceFonts.superSmallContentStyle,
                          "${chat.members.firstWhere((e) => e.id == chat.message!.userId!).nickname}: ${chat.message!.content != null ? chat.message!.content!.split('\n').first : AppLocalizations.of(context)!.image}")
                  ],
                ),
                selected:
                    activeChatId == chat.id,
                focusColor: OnepieceColors.liteFancyBlue,
                selectedTileColor: OnepieceColors.liteFancyBlue,
                leading: chat.group!
                    ? getLeading(chat.members.map((e) => e.imageUri!).toList())
                    : getSingleLeading(chat),
                // inside ListView.builder -> ListTile
                // Inside _buildChatList -> ListView.builder -> ListTile
                onTap: () {
                  final newChatId = chat.id!;

                  // 1. If clicking the SAME chat that is already active (rare but possible), do nothing
                  if (activeConversationId == newChatId) return;

                  // 2. Handle Focus & Cache for the OLD chat (if any)
                  FocusScope.of(context).unfocus();
                  if (activeConversationId.isNotEmpty) {
                    chatIdToCachedMessage[activeConversationId] =
                        typingController.text;
                    if (scrollController.hasClients) {
                      chatIdToScrollOffset[activeConversationId] =
                          scrollController.offset;
                    }
                  }

                  // 3. Update Local State for the NEW chat
                  activeConversationId = newChatId;
                  _lastProcessedChatId = ""; // Reset scroll logic

                  // 4. Restore Drafts for NEW chat
                  typingController.text =
                      chatIdToCachedMessage[newChatId] ?? "";
                  inputPreMessageNotifier.value =
                      chatIdToRepliedMessage[newChatId];

                  // 5. Update Provider (This triggers the view switch)
                  Provider.of<ChatNotifier>(context, listen: false)
                      .setActiveChat(newChatId);

                  // 6. Handle Scroll (Post Frame)
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (chatIdToScrollOffset.containsKey(newChatId)) {
                      if (scrollController.hasClients) {
                        scrollController
                            .jumpTo(chatIdToScrollOffset[newChatId]!);
                      }
                    } else {
                      _scrollToBottom(0);
                    }
                  });
                },
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
  Widget _buildChatView(BuildContext context, Chat activeChat,
      String activeChatId, List<Message> messages,
      {required bool isMobile}) {
    if (_currentNameChatId != activeChatId) {
      _currentNameChatId = activeChatId;
      // If it's a group, use group name, else use the other person's nickname
      chatNameController.text = activeChat.group!
          ? (activeChat.name ?? "")
          : getTargetMember(activeChat).nickname;
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 15.0, top: 5.0, bottom: 5.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (isMobile)
                      Container(
                        margin: const EdgeInsets.only(right: 5),
                        child: GestureDetector(
                          behavior: HitTestBehavior
                              .translucent, // Ensures tap is caught
                          onTap: () {
                            _clearActiveChat();
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.arrow_back,
                                size: 24, color: OnepieceColors.fancyBlue),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        style: OnepieceFonts.smallContentFancyBlueStyle,
                        activeChat.group!
                            ? activeChat.name!
                            : getTargetMember(activeChat).nickname,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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
                  size: 20,
                ),
              )
            ],
          ),
        ),
        const Divider(
          thickness: 1,
          color: OnepieceColors.liteFancyGreen,
          height: 1,
          indent: 0,
          endIndent: 0,
        ),
        Expanded(
          child: Scaffold(
            key: _scaffoldKey,
            drawerEnableOpenDragGesture: true,
            drawerScrimColor: Colors.transparent,
            endDrawer: Drawer(
              width: 200,
              elevation: 0.1,
              shadowColor: Colors.green,
              backgroundColor: OnepieceColors.menuBackgroundColor,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    getUserWall(activeChat),
                    const Divider(
                        thickness: 1,
                        indent: 10,
                        endIndent: 10,
                        color: Colors.black12),
                    // 2. ADD THIS NEW WIDGET
                    if (activeChat.group!)
                      _buildEditableChatName(activeChat, context),
                  ],
                ),
              ),
            ),
            body: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: ListView.builder(
                    key: PageStorageKey('chat_list_$activeChatId'),
                    controller: scrollController,
                    addAutomaticKeepAlives: true,
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(15, 0, 20, 0),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: MessageItem(
                            key: ValueKey(msg.id),
                            message: msg,
                            isMe: msg.userId == getIt<User>().id,
                            preMessage: msg.preMessage,
                            user: activeChat.members
                                .firstWhere((user) => user.id == msg.userId),
                            preMessageNickname: msg.preMessage != null
                                ? activeChat.members
                                    .firstWhere(
                                        (e) => e.id == msg.preMessage!.userId!)
                                    .nickname
                                : null,
                            replyMessage: (msg) {
                              chatIdToRepliedMessage[msg.conversationId!] = msg;
                              inputPreMessageNotifier.value = msg;
                              Future.delayed(Duration.zero, () {
                                if (focusNode.canRequestFocus) {
                                  focusNode.requestFocus();
                                }
                              });
                            }),
                      );
                    },
                  ),
                ),
                const Divider(
                  height: 3,
                  thickness: 1,
                  color: OnepieceColors.liteFancyGreen,
                ),
                StatefulBuilder(
                  builder: (BuildContext context, StateSetter buttonState) {
                    return ValueListenableBuilder<TextEditingValue>(
                      valueListenable: typingController,
                      builder: (context, textValue, child) {
                        final bool canSend = textValue.text.trim().isNotEmpty ||
                            chatIdToCachedImage[activeChatId] != null;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                EmojiSelection(
                                  editingController: typingController,
                                  focusNode: focusNode,
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final XFile? pickedImage =
                                        await OnepieceImagePicker
                                            .pickWebImage();

                                    if (!context.mounted ||
                                        pickedImage == null) {
                                      return;
                                    }

                                    chatIdToCachedImage[activeChatId] =
                                        await pickedImage.readAsBytes();
                                    buttonState(() {});
                                    Future.delayed(Duration.zero, () {
                                      if (focusNode.canRequestFocus) {
                                        focusNode.requestFocus();
                                      }
                                    });
                                  },
                                  padding: EdgeInsets.zero,
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  splashRadius: 0.1,
                                  visualDensity: VisualDensity.compact,
                                  enableFeedback: false,
                                  icon: const Icon(
                                    Icons.image,
                                    size: 20,
                                    color: OnepieceColors.fancyBlue,
                                  ),
                                )
                              ],
                            ),
                            if (chatIdToCachedImage[activeChatId] != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Stack(
                                  alignment: AlignmentDirectional.topStart,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: ImageHelper.getSquareImageFrame(
                                          50,
                                          50,
                                          2,
                                          Colors.white,
                                          chatIdToCachedImage[activeChatId]!),
                                    ),
                                    Positioned(
                                      right: -2,
                                      top: -2,
                                      child: InkWell(
                                        onTap: () {
                                          chatIdToCachedImage[activeChatId] =
                                              null;
                                          buttonState(() {});
                                        },
                                        child: const CircleAvatar(
                                          backgroundColor: Colors.black54,
                                          radius: 8,
                                          child: Icon(Icons.close,
                                              size: 8, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            TextField(
                              controller: typingController,
                              enabled: true,
                              textAlign: TextAlign.start,
                              minLines: 1,
                              maxLines: 3,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.send,
                              autofocus: true,
                              cursorHeight: 15,
                              focusNode: focusNode,
                              style: OnepieceFonts.smallContentStyle,
                              onChanged: (value) {},
                              onSubmitted: !canSend
                                  ? null
                                  : (_) {
                                      buttonState(() {
                                        final SendMessageRequest request =
                                            SendMessageRequest(
                                          content: typingController.text
                                                  .trim()
                                                  .isNotEmpty
                                              ? typingController.text.trim()
                                              : null,
                                          userId: getIt<User>().id,
                                          profileImage: chatIdToCachedImage[
                                                      activeChatId] ==
                                                  null
                                              ? null
                                              : Base64Helper.encode(
                                                  chatIdToCachedImage[
                                                      activeChatId]!),
                                          conversationId: activeChat.id!,
                                          type: MessageType.SEND_MESSAGE,
                                          preMessageId:
                                              inputPreMessageNotifier
                                                  .value?.id,
                                        );

                                        final String jsonMessage =
                                            jsonEncode(request.toJson());

                                        Provider.of<ChatNotifier>(context,
                                                listen: false)
                                            .sendChatMessage(jsonMessage);

                                        chatIdToCachedImage[activeChatId] =
                                            null;
                                        chatIdToRepliedMessage[activeChatId] =
                                            null;
                                        chatIdToCachedMessage[activeChatId] =
                                            null;
                                        inputPreMessageNotifier.value = null;
                                        typingController.clear();

                                        Future.delayed(Duration.zero, () {
                                          if (focusNode.canRequestFocus) {
                                            focusNode.requestFocus();
                                          }
                                          _scrollToBottom(0);
                                        });
                                      });
                                    },
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 0),
                                isDense: true,
                                labelStyle: OnepieceFonts.dropDownItemStyle,
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                              ),
                            ),
                            ValueListenableBuilder<Message?>(
                                valueListenable: inputPreMessageNotifier,
                                builder: (context, value, _) {
                                  if (chatIdToRepliedMessage[activeChatId] ==
                                      null) {
                                    return const Text("");
                                  } else {
                                    return Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              10, 0, 0, 0),
                                          child: Container(
                                            decoration: const BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.all(
                                                        Radius.circular(5)),
                                                color: OnepieceColors
                                                    .liteFancyGreen),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(4.0),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  if (chatIdToRepliedMessage[
                                                              activeChatId]!
                                                          .content !=
                                                      null)
                                                    Text(
                                                      "${activeChat.members.firstWhere((e) => e.id == chatIdToRepliedMessage[activeChatId]!.userId!).nickname}: ${chatIdToRepliedMessage[activeChatId]!.content!}",
                                                      style: OnepieceFonts
                                                          .tagStyle,
                                                    ),
                                                  if (chatIdToRepliedMessage[
                                                              activeChatId]!
                                                          .imageContentUri !=
                                                      null)
                                                    SquareImageLoader(
                                                      key: UniqueKey(),
                                                      uriProvider: () =>
                                                          chatIdToRepliedMessage[
                                                                  activeChatId]!
                                                              .imageContentUri!,
                                                      width: 40,
                                                      borderWidth: 1,
                                                    )
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            chatIdToRepliedMessage[
                                                activeChatId] = null;
                                            inputPreMessageNotifier.value =
                                                null;
                                            Future.delayed(Duration.zero, () {
                                              if (focusNode.canRequestFocus) {
                                                focusNode.requestFocus();
                                              }
                                            });
                                          },
                                          icon: const Icon(
                                              size: 20,
                                              color: OnepieceColors
                                                  .liteFancyGreen,
                                              Icons.cancel_rounded),
                                          style: ButtonStyle(
                                            overlayColor:
                                                WidgetStateProperty.all(
                                                    Colors.transparent),
                                          ),
                                        )
                                      ],
                                    );
                                  }
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

  void _scrollToBottom(int extendValue) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!scrollController.hasClients) return;

      final double target =
          scrollController.position.maxScrollExtent + extendValue;
      final double current = scrollController.offset;
      final double distance = target - current;

      if (distance > 500) {
        scrollController.jumpTo(target);
      } else {
        scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget getUserWall(Chat activeChat) {
    // 1. Filter logic
    var members = activeChat.members;
    if (members.length == 2) {
      members =
          members.toList().where((e) => e.id != getIt<User>().id).toList();
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 500,
      ),
      child: SizedBox(
        width: 180,
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
          itemCount: members.length + 1,
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8, // Increased spacing between rows
            crossAxisSpacing: 4,
            // 2. IMPORTANT: Ratio < 1 makes the cell taller to fit the text
            childAspectRatio: 0.70,
          ),
          itemBuilder: (context, index) {
            // --- OPTION A: Add Button ---
            if (index == members.length) {
              return Column(
                children: [
                  Container(
                    height: 40,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                          color: OnepieceColors.fancyBlue, width: 1.5),
                      color: Colors.white,
                    ),
                    child: IconButton(
                      splashRadius: 1,
                      iconSize: 20,
                      disabledColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      color: OnepieceColors.fancyBlue,
                      onPressed: () {},
                      icon: const Icon(
                        Icons.add,
                      ),
                    ),
                  ),
                ],
              );
            }

            // --- OPTION B: User Profile ---
            final member = members[index];
            final uri = member.imageUri ?? '';

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image takes up available vertical space
                SquareImageLoader(
                  uriProvider: () => uri,
                  width: 40, // Acts as max width/quality
                  borderWidth: 2,
                ),
                const SizedBox(height: 2),
                // Username Text
                Text(
                  member.nickname,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis, // cuts off long names: "Luff..."
                  style: const TextStyle(
                    fontSize: 9, // Small font to fit
                    color: OnepieceColors.fancyBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEditableChatName(Chat activeChat, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!
                .name, // Ensure you have this key or use string
            style:
                const TextStyle(fontSize: 10, color: OnepieceColors.fancyBlue),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: chatNameController,
                  style: OnepieceFonts.smallContentFancyBlueStyle,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black12),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: OnepieceColors.fancyGreen),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  final newName = chatNameController.text.trim();
                  if (newName.isNotEmpty && newName != activeChat.name) {
                    // CALL YOUR API HERE
                    // Example:
                    // Provider.of<ChatNotifier>(context, listen: false)
                    //    .updateGroupName(activeChat.id!, newName);

                    // Close the drawer (Optional)
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Group name updated")),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle,
                    color: OnepieceColors.fancyGreen, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 20,
              )
            ],
          ),
        ],
      ),
    );
  }

  User getTargetMember(Chat chat) {
    if (chat.members.first.id == getIt<User>().id) {
      return chat.members.last;
    } else {
      return chat.members.first;
    }
  }

  Widget getLeading(List<String> imageUrls) {
    final List<String> displayedImages =
        imageUrls.length > 9 ? imageUrls.sublist(0, 9) : imageUrls;
    return Container(
      width: 45,
      height: 45,
      decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(3)),
          color: OnepieceColors.liteFancyBlue),
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
    );
  }

  Widget getSingleLeading(Chat chat) {
    final uri = getTargetMember(chat).imageUri ?? '';
    return SizedBox(
      width: 45,
      height: 45,
      child: ImageLazyLoader(
        key: ValueKey(uri),
        uriProvider: () => uri,
        width: 40,
        borderWidth: 1.5,
        borderRadios: 3,
      ),
    );
  }
}
