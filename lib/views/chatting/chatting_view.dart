import 'dart:convert';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:one_piece_battles_flutter/components/square_image_loader.dart';
import 'package:one_piece_battles_flutter/components/web_socket_manager.dart';
import 'package:one_piece_battles_flutter/popup/chatting_options.dart';
import 'package:one_piece_battles_flutter/utils/time_helper.dart';
import 'package:openapi/api.dart';
import '../../components/message.dart';
import '../../constants/button_style.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/repository/chatting_dao.dart';

GetIt getIt = GetIt.instance;

class ChattingView extends StatefulWidget {
  const ChattingView({super.key});

  @override
  State<ChattingView> createState() => _ChattingViewState();
}

class _ChattingViewState extends State<ChattingView> {
  TextEditingController searchChattingController = TextEditingController();
  TextEditingController typingController = TextEditingController();
  Map<String, double> chatLocationMap = {};
  Map<String, String> chatMessageMap = {};
  String userId = getIt<User>().id;
  List<Chat> chats = [];
  WebSocketManager webSocketManager = WebSocketManager(getIt<User>().id);
  List<Message> messages = [];
  void preMessageId;
  ValueNotifier<Chat?> selectedChatNotifier = ValueNotifier(null);
  bool isComposing = false;
  FocusNode focusNode = FocusNode();
  bool canSend = false;
  final _ctrl = ScrollController();
  final ValueNotifier<List<Message>> messagesNotifier =
      ValueNotifier<List<Message>>([]);

  @override
  void initState() {
    super.initState();
    listChat();
    _connect();
  }

  Future<void> _connect() async {
    webSocketManager.connect('ws://localhost:8081/chat?userId=$userId');
    webSocketManager.stream.listen((message) {
      final Message incomingMessage = Message.fromJson(jsonDecode(message))!;
      messagesNotifier.value.add(incomingMessage);
      messagesNotifier.notifyListeners();
      _scrollToBottom();
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  @override
  void dispose() {
    webSocketManager.disconnect();
    super.dispose();
  }

  void _scrollToBottom() {
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.jumpTo(_ctrl.position.maxScrollExtent);
    });
  }

  listChat() {
    ListChatRequest listChatRequest = ListChatRequest(userId: userId);
    Future<ListChatResponse?> chatting =
        getIt<ChattingDao>().listChat(listChatRequest);
    chatting.then(
      (value) => setState(() {
        chats = value!.chats;
        if (chats.isNotEmpty) {
          selectedChatNotifier.value = chats.first;
          selectedChatNotifier.notifyListeners();
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        SizedBox(
          width: 300,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 240,
                      height: 35,
                      child: Expanded(
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
                      )),
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
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      return ValueListenableBuilder(
                          valueListenable: selectedChatNotifier,
                          builder: (context, value, _) {
                            return ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              title: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        chat.group!
                                            ? chat.name!
                                            : getTargetMember(chat).nickname,
                                        style: OnepieceFonts
                                            .contentStyleBoldFancyBlue,
                                      ),
                                      Text(
                                        TimeHelper.humanDateFromTimestamp(
                                            1759970648516, context),
                                        style: OnepieceFonts
                                            .boldLiteFancySmallFont,
                                      ),
                                      // replace with real time
                                    ],
                                  ),
                                  if (chat.message != null)
                                    Text(chat.message!.content != null
                                        ? chat.message!.content!
                                            .split('\n')
                                            .first
                                        : AppLocalizations.of(context)!.image)
                                  else
                                    const Text(""),
                                ],
                              ),
                              selected:
                                  selectedChatNotifier.value!.id == chat.id,
                              focusColor: OnepieceColors.liteFancyBlue,
                              selectedTileColor: OnepieceColors.liteFancyBlue,
                              leading: chat.group!
                                  ? getLeading(chat.members
                                      .map((e) => e.imageUri!)
                                      .toList())
                                  : getSingleLeading(
                                      chat), // Assuming Chat has 'lastMessage'
                              onTap: () {
                                selectedChatNotifier.value = chat;
                                selectedChatNotifier.notifyListeners();
                              },
                            );
                          });
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
        ),
        ValueListenableBuilder(
          valueListenable: selectedChatNotifier,
          builder: (context, value, _) {
            return selectedChatNotifier.value == null
                ? const Text("")
                : Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                            style: OnepieceFonts.smallHeaderStyleFancyBlue,
                            selectedChatNotifier.value!.group!
                                ? selectedChatNotifier.value!.name!
                                : getTargetMember(selectedChatNotifier.value!)
                                    .nickname),
                        const Center(
                          child: SizedBox(
                            width: 250,
                            child: Divider(
                              thickness: 1,
                              color: OnepieceColors.liteFancyGreen,
                            ),
                          ),
                        ),
                        ValueListenableBuilder<List<Message>>(
                            valueListenable: messagesNotifier,
                            builder: (context, messages, child) {
                              return Expanded(
                                  child: ListView.builder(
                                controller: _ctrl,
                                shrinkWrap: true,
                                padding:
                                    const EdgeInsets.fromLTRB(10, 0, 25, 0),
                                itemCount: messages
                                    .where((e) =>
                                        e.conversationId ==
                                        selectedChatNotifier.value!.id)
                                    .length,
                                itemBuilder: (context, index) {
                                  final msg = messages
                                      .where((e) =>
                                          e.conversationId ==
                                          selectedChatNotifier.value!.id)
                                      .toList()[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 15.0),
                                    child: MessageItem(
                                      message: msg,
                                      isMe: msg.userId == userId!,
                                      preMessage: msg.preMessage,
                                      user: selectedChatNotifier!.value!.members
                                          .firstWhere(
                                              (user) => user.id == msg.userId),
                                    ),
                                  ); // your widget
                                },
                              ));
                            }),
                        StatefulBuilder(
                          builder:
                              (BuildContext context, StateSetter buttonState) {
                            return Container(
                              padding: const EdgeInsets.fromLTRB(8, 16, 23, 16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 40,
                                          width: 200,
                                          child: TextField(
                                            controller: typingController,
                                            focusNode: FocusNode(),
                                            enabled: true,
                                            minLines: 1,
                                            maxLines: 5,
                                            keyboardType: TextInputType.text, // not TextInputType.multiline
                                            textInputAction: TextInputAction.send,
                                            onSubmitted: (_) => {
                                              buttonState(() {
                                                final SendMessageRequest request =
                                                    SendMessageRequest(
                                                  content: typingController.text,
                                                  userId: getIt<User>().id,
                                                  conversationId:
                                                      selectedChatNotifier
                                                          .value?.id!,
                                                  preMessageId: null,
                                                );
                                                final String jsonMessage =
                                                    jsonEncode(request.toJson());
                                                webSocketManager
                                                    .sendMessage(jsonMessage);
                                                typingController.clear();
                                                canSend = false;
                                                focusNode.requestFocus();
                                              })
                                            },
                                            onChanged: (value) {
                                              buttonState(() {
                                                canSend = typingController.text
                                                    .trim()
                                                    .isNotEmpty;
                                              });
                                            },
                                            decoration: const InputDecoration(
                                              contentPadding: EdgeInsets.symmetric(
                                                  horizontal: 10),
                                              labelStyle:
                                                  OnepieceFonts.dropDownItemStyle,
                                              floatingLabelBehavior:
                                                  FloatingLabelBehavior.never,
                                              disabledBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: OnepieceColors
                                                          .menuHoverColor)),
                                              enabledBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: OnepieceColors
                                                          .menuHoverColor)),
                                              focusedBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color:
                                                          OnepieceColors.iconGreen,
                                                      width: 1.5)),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        height: 38,
                                        child: ElevatedButton(
                                          onPressed: canSend
                                              ? () {
                                                  buttonState(() {
                                                    final SendMessageRequest
                                                        request =
                                                        SendMessageRequest(
                                                      content:
                                                          typingController.text,
                                                      userId: getIt<User>().id,
                                                      conversationId:
                                                          selectedChatNotifier
                                                              .value?.id!,
                                                      preMessageId: null,
                                                    );
                                                    final String jsonMessage =
                                                        jsonEncode(
                                                            request.toJson());
                                                    webSocketManager
                                                        .sendMessage(jsonMessage);
                                                    typingController.clear();
                                                    canSend = false;
                                                    focusNode.requestFocus();
                                                  });
                                                }
                                              : null,
                                          style:
                                              OnepieceButtonStyle.getDefaultStyle(),
                                          child: Text(
                                            AppLocalizations.of(context)!.send,
                                            style: TextStyle(
                                              color: canSend
                                                  ? Colors.white
                                                  : Colors.grey.shade600,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 250,
                                    child: EmojiPicker(
                                      onEmojiSelected: (category, emoji) {
                                        final newText = typingController.text + emoji.emoji;
                                        typingController.text = newText;
                                        typingController.selection = TextSelection.collapsed(offset: newText.length);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      ],
                    ),
                  );
          },
        ),
      ],
    );
  }

  User getTargetMember(Chat chat) {
    if (chat.members.first.id == userId) {
      return chat.members.last;
    } else {
      return chat.members.first;
    }
  }

  Widget getLeading(List<String> imageUrls) {
    final List<String> displayedImages =
        imageUrls.length > 9 ? imageUrls.sublist(0, 9) : imageUrls;
    return SizedBox(
      width: 45,
      height: 45,
      child: GridView.builder(
        shrinkWrap: true,
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
              borderWidth: 0);
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
