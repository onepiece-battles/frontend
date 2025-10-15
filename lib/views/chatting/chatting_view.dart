import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/components/chat_input_field.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:one_piece_battles_flutter/components/square_image_loader.dart';
import 'package:one_piece_battles_flutter/components/web_socket_manager.dart';
import 'package:one_piece_battles_flutter/popup/chatting_options.dart';
import 'package:one_piece_battles_flutter/utils/time_helper.dart';
import 'package:openapi/api.dart';
import '../../components/message.dart';
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
  final ValueNotifier<List<Message>> messagesNotifier =
      ValueNotifier<List<Message>>([]);
  void preMessageId;
  ValueNotifier<Chat?> selectedChatNotifier = ValueNotifier(null);
  bool isComposing = false;

  @override
  void initState() {
    super.initState();
    listChat();
    webSocketManager.connect('ws://localhost:8081/chat?userId=$userId');
    webSocketManager.stream.listen((message) {
      final Message incomingMessage = Message.fromJson(jsonDecode(message))!;
      messagesNotifier.value = [...messagesNotifier.value, incomingMessage];
      messagesNotifier.notifyListeners();
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
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 230,
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
                                    Text(chat.message!.content ??
                                        AppLocalizations.of(context)!.image)
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
                          style: OnepieceFonts.fancyBlueSmallTitle,
                          selectedChatNotifier.value!.group!
                              ? selectedChatNotifier.value!.name!
                              : getTargetMember(selectedChatNotifier.value!)
                                  .nickname),
                      ValueListenableBuilder<List<Message>>(
                        valueListenable: messagesNotifier,
                        builder: (context, value, _) {
                          var selectedMessages = messagesNotifier.value.where(
                              (e) =>
                                  e.conversationId ==
                                  selectedChatNotifier.value!.id);
                          return Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(10,0,25,0),
                            reverse: true,
                            itemCount: selectedMessages.length,
                            itemBuilder: (context, index) {
                              final msg = selectedMessages.toList()[index];
                              return MessageItem(
                                message: msg,
                                isMe: msg.userId == userId!,
                                preMessage: msg.preMessage,
                                user: selectedChatNotifier!.value!.members
                                    .firstWhere(
                                        (user) => user.id == msg.userId),
                              ); // your widget
                            },
                          ));
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0,10,15,10),
                        child: ChatInputField(
                          webSocketManager: webSocketManager,
                          selectedChatNotifier: selectedChatNotifier,
                          textEditingController: typingController,
                          padding: EdgeInsets.only(
                            left: 8,
                            right: 8,
                            bottom: MediaQuery.of(context)
                                .viewInsets
                                .bottom, // move above keyboard
                            top: 6,
                          ),
                        ),
                      )
                    ],
                  ));
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
