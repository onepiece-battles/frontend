import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Assuming these are your local project imports.
// Keep your existing imports exactly as they were.
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
  TextEditingController searchChattingController = TextEditingController();
  TextEditingController typingController = TextEditingController();
  FocusNode focusNode = FocusNode();

  Map<String, Message?> chatIdToRepliedMessage = {};
  Map<String, String?> chatIdToCachedMessage = {};
  Map<String, Uint8List?> chatIdToCachedImage = {};
  // Add this under your other maps
  Map<String, double> chatIdToScrollOffset = {};


  final ValueNotifier<Message?> inputMessageNotifier = ValueNotifier(null);
  final ValueNotifier<Message?> inputPreMessageNotifier = ValueNotifier(null);
  String activeConversationId = "";
  // ADD THESE TWO:
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

  @override
  Widget build(BuildContext context) {
    final chats = context.watch<ChatNotifier>().chats;
    final activeChatId = context.watch<ChatNotifier>().activeChatId;
    final activeChat = context.watch<ChatNotifier>().activeChat;
    final messages = context.select<ChatNotifier, List<Message>>(
          (notifier) => notifier.getMessagesForChat(activeChatId),
    );
    // --- SMART AUTO-SCROLL LOGIC START ---
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Detect if we just switched to a different chat
      if (activeChatId != _lastProcessedChatId) {
        _lastProcessedChatId = activeConversationId;
        _previousMsgCount = messages.length;
        // We do nothing here, because onTap handles the scroll restoration
        return;
      }

      // 2. Detect if a new message arrived in the SAME chat
      if (messages.length > _previousMsgCount) {
        _previousMsgCount = messages.length;

        // 3. Check where the user is currently looking
        if (scrollController.hasClients) {
          final double maxScroll = scrollController.position.maxScrollExtent;
          final double currentScroll = scrollController.offset;

          // Calculate distance from bottom
          // We use the NEW maxScroll, so we add a threshold (e.g. 500px)
          // to account for the height of the new message(s) that just rendered.
          final double distanceFromBottom = maxScroll - currentScroll;

          // If user is within 500px of the bottom, pull them down to the newest message.
          // If they are 2000px up (history), this condition fails, and they stay put.
          if (distanceFromBottom < 500) {
            _scrollToBottom(0);
          }
        }
      }
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        // -------------------------
        // LEFT SIDE: Chat List
        // -------------------------
        SizedBox(
          width: 300,
          child: Column(
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
                        width: 240,
                        height: 35,
                        child: TextFormField(
                          controller: searchChattingController,
                          onChanged: (value) {},
                          decoration: InputDecoration(
                            labelStyle: OnepieceFonts.dropDownItemStyle,
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            disabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: OnepieceColors.menuHoverColor)),
                            enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: OnepieceColors.menuHoverColor)),
                            focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: OnepieceColors.fancyGreen,
                                    width: 1.5)),
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
              SizedBox(
                width: 350,
                child: ListView.builder(
                  itemCount: chats.length,
                  addAutomaticKeepAlives: true,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return ListTile(
                      title: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text(
                                  chat.group!
                                      ? chat.name!
                                      : getTargetMember(chat).nickname,
                                  overflow: TextOverflow.ellipsis,
                                  style: OnepieceFonts.smallContentFancyBlueStyle,
                                ),
                              ),
                              if (chat.message != null)
                                Text(
                                  TimeHelper.humanDateFromTimestamp(
                                      chat.message!.creationRecord!
                                          .actionTimestamp!,
                                      context),
                                  style: OnepieceFonts.boldLiteFancySmallFont,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if ((chatIdToRepliedMessage[chat.id] != null ||
                              (chatIdToCachedMessage[chat.id] != null &&
                                  chatIdToCachedMessage[chat.id]!
                                      .isNotEmpty)) &&
                              activeChatId != chat.id)
                            Text(
                              "[${AppLocalizations.of(context)!.draft}]",
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: OnepieceFonts.smallContentFontSize,
                              ),
                            )
                          else if (chat.message != null)
                            Text(
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: OnepieceFonts.contentFontColor,
                                  fontSize: OnepieceFonts.superSmallContentFontSize,
                                ),
                                "${chat.members.firstWhere((e) => e.id == chat.message!.userId!).nickname}: ${chat.message!.content != null ? chat.message!.content!.split('\n').first : AppLocalizations.of(context)!.image}")
                          else
                            const Text(""),
                        ],
                      ),
                      selected: activeChatId == chat.id,
                      focusColor: OnepieceColors.liteFancyBlue,
                      selectedTileColor: OnepieceColors.liteFancyBlue,
                      leading: chat.group!
                          ? getLeading(
                          chat.members.map((e) => e.imageUri!).toList())
                          : getSingleLeading(chat),
                      onTap: () {
                        // 1. Save the CURRENT chat's scroll position before switching
                        if (scrollController.hasClients && activeConversationId.isNotEmpty) {
                          chatIdToScrollOffset[activeConversationId] = scrollController.offset;
                        }

                        // 2. Save text draft (your existing code)
                        if (activeChat != null) {
                          chatIdToCachedMessage[activeChat.id!] = typingController.text.trim();
                        }

                        // 3. Switch the active chat
                        Provider.of<ChatNotifier>(context, listen: false).setActiveChat(chat.id);

                        // 4. Update local tracker
                        activeConversationId = chat.id!;

                        // 5. Restore text draft (your existing code)
                        typingController.text = chatIdToCachedMessage[activeConversationId] ?? "";
                        inputPreMessageNotifier.value = Message(
                            content: chatIdToCachedMessage[activeChatId] ?? "");

                        // 6. RESTORE SCROLL POSITION
                        // We use postFrameCallback to wait for the ListView to render the new messages
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (chatIdToScrollOffset.containsKey(activeConversationId)) {
                            // If we have a saved position, jump there
                            if (scrollController.hasClients) {
                              scrollController.jumpTo(chatIdToScrollOffset[activeConversationId]!);
                            }
                          } else {
                            // If it's the first time opening this chat, go to bottom
                            _scrollToBottom(0);
                          }
                        });
                      },

                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(
          thickness: 1.2,
          color: OnepieceColors.liteFancyGreen,
          indent: 10,
          endIndent: 8,
          width: 2,
        ),

        // -------------------------
        // RIGHT SIDE: Active Chat
        // -------------------------
        if (activeChat == null)
          Expanded(
            child: Center(
              child: ImageHelper.getSvgIconWithColor('images/svgs/ship.svg',
                  200, 200, OnepieceColors.liteFancyBlue),
            ),
          )
        else
          Expanded( // Added Expanded here to ensure column takes remaining space
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                          style: OnepieceFonts.smallContentFancyBlueStyle,
                          activeChat.group!
                              ? activeChat.name!
                              : getTargetMember(activeChat).nickname),
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
                        splashRadius: 0.1,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        focusColor: Colors.transparent,
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
                  height: 3,
                  indent: 0,
                  endIndent: 0,
                ),
                Expanded( // Use Expanded to let the Nested Scaffold fill vertical space
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
                        borderRadius:
                        BorderRadius.horizontal(left: Radius.circular(8)),
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
                        // Messages List
                        Expanded( // Changed from specific height to Expanded to flex with window
                          child: ListView.builder(
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
                                      chatIdToRepliedMessage[msg.conversationId!] =
                                          msg;
                                      inputPreMessageNotifier.value = msg;

                                      // CRITICAL FIX: Safe Focus Request
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
                        // Input Area
                        StatefulBuilder(
                          builder: (BuildContext context, StateSetter buttonState) {
                            // FIX: Wrap in ValueListenableBuilder to listen to controller changes (Emoji & Typing)
                            return ValueListenableBuilder<TextEditingValue>(
                              valueListenable: typingController,
                              builder: (context, textValue, child) {

                                // Calculate if send is allowed based on LIVE text value or Image presence
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
                                          EmojiSelection(editingController: typingController),
                                          IconButton(
                                            onPressed: () async {
                                              final XFile? pickedImage =
                                              await OnepieceImagePicker.pickWebImage();

                                              if (!context.mounted || pickedImage == null) return;

                                              chatIdToCachedImage[activeChatId!] =
                                              await pickedImage.readAsBytes();

                                              // Update state for Image
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
                                      if (chatIdToCachedImage[activeChatId!] != null)
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
                                                    chatIdToCachedImage[activeChatId] = null;
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
                                        // Note: onChanged is no longer strictly needed for buttonState
                                        // because ValueListenableBuilder handles it, but keeping it empty is fine.
                                        onChanged: (value) {},

                                        // Logic is now reactive to emojis
                                        onSubmitted: !canSend
                                            ? null
                                            : (_) {
                                          // Use buttonState to wrap the send logic purely for safety,
                                          // though logic execution doesn't strictly need UI rebuild here.
                                          buttonState(() {
                                            final SendMessageRequest request =
                                            SendMessageRequest(
                                              content: typingController.text.trim().isNotEmpty
                                                  ? typingController.text.trim()
                                                  : null,
                                              userId: getIt<User>().id,
                                              profileImage:
                                              chatIdToCachedImage[activeChatId] == null
                                                  ? null
                                                  : Base64Helper.encode(
                                                  chatIdToCachedImage[activeChatId]!),
                                              conversationId: activeChat.id!,
                                              type: MessageType.SEND_MESSAGE,
                                              preMessageId: inputPreMessageNotifier.value?.id,
                                            );

                                            final String jsonMessage =
                                            jsonEncode(request.toJson());

                                            Provider.of<ChatNotifier>(context, listen: false)
                                                .sendChatMessage(activeChatId, jsonMessage);

                                            // Reset UI
                                            chatIdToCachedImage[activeChatId] = null;
                                            chatIdToRepliedMessage[activeChatId] = null;
                                            chatIdToCachedMessage[activeChatId] = null;
                                            inputPreMessageNotifier.value = null;
                                            typingController.clear();

                                            // Engine Crash Fix & Scroll
                                            Future.delayed(Duration.zero, () {
                                              if (focusNode.canRequestFocus) {
                                                focusNode.requestFocus();
                                              }
                                              _scrollToBottom(0);
                                            });
                                          });
                                        },
                                        decoration: const InputDecoration(
                                          contentPadding:
                                          EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                          isDense: true,
                                          labelStyle: OnepieceFonts.dropDownItemStyle,
                                          floatingLabelBehavior: FloatingLabelBehavior.never,
                                          border: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          disabledBorder: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                        ),
                                      ),
                                      ValueListenableBuilder<Message?>(
                                          valueListenable: inputPreMessageNotifier,
                                          builder: (context, value, _) {
                                            if (chatIdToRepliedMessage[activeChatId] == null) {
                                              return const Text("");
                                            } else {
                                              return Row(
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                                    child: Container(
                                                      decoration: const BoxDecoration(
                                                          borderRadius:
                                                          BorderRadius.all(Radius.circular(5)),
                                                          color: OnepieceColors.liteFancyGreen),
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(4.0),
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.start,
                                                          crossAxisAlignment:
                                                          CrossAxisAlignment.end,
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            if (chatIdToRepliedMessage[activeChatId]!
                                                                .content !=
                                                                null)
                                                              Text(
                                                                "${activeChat.members.firstWhere((e) => e.id == chatIdToRepliedMessage[activeChatId]!.userId!).nickname}: ${chatIdToRepliedMessage[activeChatId]!.content!}",
                                                                style: OnepieceFonts.tagStyle,
                                                              ),
                                                            if (chatIdToRepliedMessage[activeChatId]!
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
                                                      chatIdToRepliedMessage[activeChatId] = null;
                                                      inputPreMessageNotifier.value = null;
                                                      Future.delayed(Duration.zero, () {
                                                        if (focusNode.canRequestFocus) {
                                                          focusNode.requestFocus();
                                                        }
                                                      });
                                                    },
                                                    icon: const Icon(
                                                        size: 20,
                                                        color: OnepieceColors.liteFancyGreen,
                                                        Icons.cancel_rounded),
                                                    style: ButtonStyle(
                                                      overlayColor: WidgetStateProperty.all(
                                                          Colors.transparent),
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
            ),
          )
      ],
    );
  }

  void _scrollToBottom(int extendValue) {
    // 1. Wait for layout to update with the new message
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!scrollController.hasClients) return;

      final double target = scrollController.position.maxScrollExtent + extendValue;
      final double current = scrollController.offset;
      final double distance = target - current;

      // 2. "Smart Scroll" Logic
      // If the distance is huge (more than 500 pixels), jump directly to the bottom
      // to avoid the long, dizzying animation ("scroll less").
      if (distance > 500) {
        scrollController.jumpTo(target);
      } else {
        // If close, animate smoothly but faster (200ms instead of 300ms)
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
