import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/components/emoji_selection.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:one_piece_battles_flutter/components/square_image_loader.dart';
import 'package:one_piece_battles_flutter/popup/chatting_options.dart';
import 'package:one_piece_battles_flutter/utils/onepiece_image_picker.dart';
import 'package:one_piece_battles_flutter/utils/time_helper.dart';
import 'package:openapi/api.dart';
import 'package:provider/provider.dart';
import '../../components/chat_notifier.dart';
import '../../components/message.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/base64_helper.dart';
import '../../utils/image_helper.dart';
import 'package:image_picker/image_picker.dart';

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
  bool showEmojiPicker = false;
  Map<String, Message?> chatIdToRepliedMessage = {};
  Map<String, String?> chatIdToCachedMessage = {};
  Map<String, Uint8List?> chatIdToCachedImage = {};
  final ValueNotifier<Message?> inputMessageNotifier = ValueNotifier(null);
  final ValueNotifier<Message?> inputPreMessageNotifier = ValueNotifier(null);
  String activeConversationId = "";
  bool emojiVisible = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        SizedBox(
          width: 300,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0.0, 0, 0, 0),
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
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.never,
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
                    ), // search
                    ChattingOptions(
                      context: context,
                    )
                  ], // create new group
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
                                    style: OnepieceFonts
                                        .smallContentFancyBlueStyle,
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
                                // replace with real time
                              ],
                            ),
                            const SizedBox(
                              height: 8,
                            ),
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
                                    fontSize:
                                        OnepieceFonts.superSmallContentFontSize,
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
                            : getSingleLeading(
                                chat), // Assuming Chat has 'lastMessage'
                        onTap: () {
                          // save last active chat caches
                          if (activeChat != null) {
                            chatIdToCachedMessage[activeChat.id!] =
                                typingController.text.trim();
                          }
                          Provider.of<ChatNotifier>(context, listen: false)
                              .setActiveChat(chat.id);
                          _scrollToBottom(0);
                          activeConversationId = chat.id!;
                          typingController.text =
                              chatIdToCachedMessage[activeConversationId] ?? "";
                          inputPreMessageNotifier.value = Message(
                              content:
                                  chatIdToCachedMessage[activeChatId] ?? "");
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const VerticalDivider(
          thickness: 1.2,
          color: OnepieceColors.liteFancyGreen,
          indent: 10,
          endIndent: 8,
          width: 2,
        ),
        if (activeChat == null)
          Expanded(
            child: Center(
              child: ImageHelper.getSvgIconWithColor('images/svgs/ship.svg',
                  200, 200, OnepieceColors.liteFancyBlue),
            ),
          ),
        if (activeChat != null)
          Expanded(
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
                            Navigator.of(context).pop(); // closes the drawer
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
                    body: ListView.builder(
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
                                focusNode.requestFocus();
                              }),
                        ); // your widget
                      },
                    ),
                  ),
                ),
                const Divider(
                  height: 3,
                  thickness: 1,
                  color: OnepieceColors.liteFancyGreen,
                ),
                StatefulBuilder(
                  builder: (BuildContext context, StateSetter buttonState) {
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
                                  editingController: typingController),
                              IconButton(
                                onPressed: () async {
                                  final XFile? pickedImage =
                                      await OnepieceImagePicker.pickWebImage();
                                  if (pickedImage == null) return;
                                  chatIdToCachedImage[activeChatId!] =
                                      await pickedImage.readAsBytes();
                                  focusNode.requestFocus();
                                  buttonState(() {});
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
                                  // Display the Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: ImageHelper.getSquareImageFrame(
                                        50,
                                        50,
                                        2,
                                        Colors.white,
                                        chatIdToCachedImage[activeChatId]!),
                                  ),
                                  // Close 'X' Button
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
                            onSubmitted: typingController.text.isEmpty &&
                                    chatIdToCachedImage[activeChatId] == null
                                ? null
                                : (_) => {
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
                                              inputPreMessageNotifier.value?.id,
                                        );

                                        final String jsonMessage =
                                            jsonEncode(request.toJson());

                                        Provider.of<ChatNotifier>(context,
                                                listen: false)
                                            .sendChatMessage(
                                                activeChatId, jsonMessage);

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
                                      })
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
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(5)),
                                              color: OnepieceColors
                                                  .liteFancyGreen),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (chatIdToRepliedMessage[
                                                            activeChatId]!
                                                        .content !=
                                                    null)
                                                  Text(
                                                    "${activeChat.members.firstWhere((e) => e.id == chatIdToRepliedMessage[activeChatId]!.userId!).nickname}: ${chatIdToRepliedMessage[activeChatId]!.content!}",
                                                    style:
                                                        OnepieceFonts.tagStyle,
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
                                          chatIdToRepliedMessage[activeChatId] =
                                              null;
                                          inputPreMessageNotifier.value = null;
                                          focusNode.requestFocus();
                                        },
                                        icon: const Icon(
                                            size: 20,
                                            color:
                                                OnepieceColors.liteFancyGreen,
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
                )
              ],
            ),
          )
      ],
    );
  }

  void _scrollToBottom(int extendValue) {
    // Ensure scrolling occurs after the build cycle completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent + extendValue,
          duration: const Duration(milliseconds: 100),
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
