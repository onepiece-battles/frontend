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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    searchChattingController.dispose();
    typingController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  /// ROBUST BACK NAVIGATION & CACHING
  /// ROBUST BACK NAVIGATION & CACHING
  void _clearActiveChat() {
    // 1. Cache the draft before leaving
    if (activeConversationId.isNotEmpty) {
      chatIdToCachedMessage[activeConversationId] = typingController.text;
    }

    // REMOVE THIS LINE:
    // FocusScope.of(context).unfocus();

    // 2. Update Provider
    // This triggers a rebuild. The ChatView will be unmounted,
    // which automatically disposes the TextField and closes the keyboard.
    Provider.of<ChatNotifier>(context, listen: false).setActiveChat(null);

    // 3. Reset local UI state
    if (mounted) {
      setState(() {
        activeConversationId = "";
        typingController.clear();
        inputPreMessageNotifier.value = null;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    // 1. WATCH the Notifier. Any update (including WS new chat) triggers this build.
    final chatNotifier = context.watch<ChatNotifier>();

    // 2. CREATE A SORTED COPY of the list.
    // We create a new list reference so Flutter knows to repaint.
    final List<Chat> sortedChats = List<Chat>.from(chatNotifier.chats);

    // 3. SORT LOGIC:
    // If message is null, it's a brand new chat -> give it current time (top priority).
    // Otherwise use the message timestamp.
    sortedChats.sort((a, b) {
      final int timeA = a.message?.creationRecord?.actionTimestamp ?? DateTime.now().millisecondsSinceEpoch;
      final int timeB = b.message?.creationRecord?.actionTimestamp ?? DateTime.now().millisecondsSinceEpoch;
      // Descending order (Newest first)
      return timeB.compareTo(timeA);
    });

    final String? activeChatId = chatNotifier.activeChatId;
    final Chat? activeChat = chatNotifier.activeChat;

    final messages = activeChatId != null
        ? chatNotifier.getMessagesForChat(activeChatId)
        : <Message>[];

    // --- SMART AUTO-SCROLL LOGIC ---
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (activeChatId == null) return;

      if (activeChatId != _lastProcessedChatId) {
        _lastProcessedChatId = activeConversationId;
        _previousMsgCount = messages.length;
        return;
      }

      if (messages.length > _previousMsgCount) {
        _previousMsgCount = messages.length;
        if (scrollController.hasClients) {
          final double maxScroll = scrollController.position.maxScrollExtent;
          final double currentScroll = scrollController.offset;
          final double distanceFromBottom = maxScroll - currentScroll;

          if (distanceFromBottom < 500) {
            _scrollToBottom(0);
          }
        }
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 500;

        // --- MOBILE LAYOUT ---
        if (isMobile) {
          if (activeChatId != null && activeChat != null) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (bool didPop, dynamic result) {
                if (didPop) return;
                _clearActiveChat();
              },
              child: _buildChatView(
                context,
                activeChat,
                activeChatId,
                messages,
                isMobile: true,
              ),
            );
          }
          // Pass sortedChats here
          return _buildChatList(context, sortedChats, activeChatId, isMobile: true);
        }

        // --- DESKTOP LAYOUT ---
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            SizedBox(
              width: 300,
              // Pass sortedChats here
              child: _buildChatList(
                  context, sortedChats, activeChatId, isMobile: false),
            ),
            const VerticalDivider(
              thickness: 1.2,
              color: OnepieceColors.liteFancyGreen,
              indent: 10,
              endIndent: 8,
              width: 2,
            ),
            Expanded(
              child: (activeChatId != null && activeChat != null)
                  ? _buildChatView(
                context,
                activeChat,
                activeChatId,
                messages,
                isMobile: false,
              )
                  : Center(
                child: ImageHelper.getSvgIconWithColor(
                    'images/svgs/ship.svg',
                    200,
                    200,
                    OnepieceColors.liteFancyBlue),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // LEFT SIDE: Chat List
  // ---------------------------------------------------------------------------
  Widget _buildChatList(BuildContext context, List<Chat> chats,
      String? activeChatId, {required bool isMobile}) {

    // Apply Search Filter locally on the sorted list
    final searchText = searchChattingController.text.toLowerCase();
    final displayChats = searchText.isEmpty
        ? chats
        : chats.where((chat) {
      final name = chat.group! ? chat.name! : getTargetMember(chat).nickname;
      return (name ?? "").toLowerCase().contains(searchText);
    }).toList();

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
                      // Trigger rebuild when searching
                      setState(() {});
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
          child: ListView.builder(
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
                                    chat.message!.creationRecord!.actionTimestamp!,
                                    context),
                                style: OnepieceFonts.boldLiteFancySmallFont,
                              )
                            else
                            // Fallback for new chats without messages
                              const Text(
                                "New",
                                style: TextStyle(fontSize: 10, color: Colors.green),
                              ),

                            // --- UNREAD COUNT BADGE ---
                            if (chat.unreadCount != null && chat.unreadCount! > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 5),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  chat.unreadCount! > 99 ? '99+' : chat.unreadCount.toString(),
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
                selected: activeChatId == chat.id,
                focusColor: OnepieceColors.liteFancyBlue,
                selectedTileColor: OnepieceColors.liteFancyBlue,
                leading: chat.group!
                    ? getLeading(chat.members.map((e) => e.imageUri!).toList())
                    : getSingleLeading(chat),
                onTap: () {
                  // 1. Save state for PREVIOUS chat
                  if (scrollController.hasClients &&
                      activeConversationId.isNotEmpty) {
                    chatIdToScrollOffset[activeConversationId] =
                        scrollController.offset;
                  }
                  if (activeConversationId.isNotEmpty) {
                    chatIdToCachedMessage[activeConversationId] =
                        typingController.text;
                  }

                  // 2. Switch to NEW chat
                  final newChatId = chat.id!;
                  Provider.of<ChatNotifier>(context, listen: false)
                      .setActiveChat(newChatId);

                  // 3. Update local tracker
                  setState(() {
                    activeConversationId = newChatId;
                  });

                  // 4. Restore state for NEW chat
                  typingController.text =
                      chatIdToCachedMessage[newChatId] ?? "";
                  inputPreMessageNotifier.value = chatIdToRepliedMessage[newChatId];

                  // 5. Restore scroll
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (chatIdToScrollOffset.containsKey(newChatId)) {
                      if (scrollController.hasClients) {
                        scrollController.jumpTo(
                            chatIdToScrollOffset[newChatId]!);
                      }
                    } else {
                      _scrollToBottom(0);
                    }
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // RIGHT SIDE: Active Chat View
  // ---------------------------------------------------------------------------
  Widget _buildChatView(BuildContext context, Chat activeChat,
      String activeChatId, List<Message> messages,
      {required bool isMobile}) {
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
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.arrow_back,
                              size: 24, color: OnepieceColors.fancyBlue),
                          onPressed: () {
                            _clearActiveChat();
                          },
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
                splashRadius: 20,
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
                                .firstWhere((e) =>
                            e.id == msg.preMessage!.userId!)
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

                        return Container(
                          height: 200,
                          padding: const EdgeInsets.fromLTRB(8, 6, 23, 6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  EmojiSelection(
                                      editingController: typingController, focusNode: focusNode,),
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
                                            chatIdToCachedImage[
                                            activeChatId]!),
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
                                minLines: 3,
                                maxLines: 5,
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
                                        .sendChatMessage( jsonMessage);

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
                                              overlayColor: WidgetStateProperty
                                                  .all(Colors.transparent),
                                            ),
                                          )
                                        ],
                                      );
                                    }
                                  }),
                            ],
                          ),
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
    var members = activeChat.members;
    if (members.length == 2) {
      members =
          members.toList().where((e) => e.id != getIt<User>().id).toList();
    }
    return SizedBox(
      width: 180,
      height: 120,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
        itemCount: members.length,
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final uri = members[index].imageUri ?? '';
          return InkWell(
            splashColor: Colors.transparent,
            hoverColor: Colors.transparent,
            onTap: () {},
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: ImageLazyLoader(
                uriProvider: () => uri,
                width: 30,
                borderWidth: 2,
                borderRadios: 2,
              ),
            ),
          );
        },
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
              key: UniqueKey(),
              uriProvider: () => displayedImages[index],
              width: 40,
              borderWidth: 0.5);
        },
      ),
    );
  }

  Widget getSingleLeading(Chat chat) {
    return SizedBox(
      width: 45,
      height: 45,
      child: ImageLazyLoader(
        key: UniqueKey(),
        uriProvider: () => getTargetMember(chat).imageUri!,
        width: 40,
        borderWidth: 1.5,
        borderRadios: 3,
      ),
    );
  }
}
