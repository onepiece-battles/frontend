import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/components/square_image_loader.dart';
import 'package:one_piece_battles_flutter/constants/button_style.dart';
import 'package:one_piece_battles_flutter/popup/chatting_options.dart';
import 'package:one_piece_battles_flutter/repository/message_dao.dart';
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
  List<Chat> chats = [];
  List<Message> messages = [];
  late Chat selectedChat;
  ValueNotifier<Chat?> selectedChatNotifier = ValueNotifier(null);
  bool isComposing = false;

  @override
  void initState() {
    super.initState();
    listChat();
  }

  listChat() {
    ListChatRequest listChatRequest = ListChatRequest(userId: getIt<User>().id);
    Future<ListChatResponse?> chatting =
        getIt<ChattingDao>().listChat(listChatRequest);
    chatting.then((value) => setState(() {
          chats = value!.chats;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
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
                  height: 500,
                  child: ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      return ListTile(
                        title: Text(chat.name!),
                        leading: getLeading(chat.members
                            .map((e) => e.imageUri!)
                            .toList()), // Assuming Chat has 'lastMessage'
                        onTap: () {
                          getIt<MessageDao>()
                              .listMessage(ListMessageRequest(
                              userId: getIt<User>().id,
                              chatId: chat.id,
                              limit: 10))
                              .then((value) => messages = value!.chats!);
                          selectedChatNotifier.value = chat;
                          selectedChat = chat;
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: selectedChatNotifier,
            builder: (context, value, _) {
              return selectedChatNotifier.value == null
                  ? Container(
                      color: OnepieceColors.liteFancyGreen,
                    )
                  : Container(
                      color: OnepieceColors.liteFancyGreen,
                      height: 800,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(selectedChatNotifier.value!.name!),
                              IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.add_box))
                            ],
                          ),
                          Text(messages.length.toString()),
                          // chatting title/ group name
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: messages
                                .map((e) => MessageItem(
                                      message: e,
                                      isMe: e.userId == getIt<User>().id!,
                                      preMessage: e.preMessage,
                                      user: selectedChat!.members.firstWhere(
                                          (user) => user.id == e.userId),
                                    ))
                                .toList(),
                          ), // chatting content
                          getTypingArea(context) // typing area
                        ],
                      ),
                    );
            },
          ),
        ),
      ],
    );
  }

  Widget getTypingArea(BuildContext context) {
    return Column(
      children: [
        const Row(
          children: [Icon(Icons.access_alarms_rounded), Icon(Icons.face)],
        ),
        TextField(
          controller: typingController,
          textAlign: TextAlign.left,
          maxLines: 10,
          autofocus: true,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () {
                getIt<MessageDao>()
                    .sendMessage(SendMessageRequest(
                        userId: getIt<User>().id,
                        chatId: selectedChat.id,
                        content: typingController.text))
                    .then((value) => value!.result!
                        ? typingController.clear()
                        : typingController.value);
              },
              style: OnepieceButtonStyle.getDefaultStyle(),
              child: Text(
                AppLocalizations.of(context)!.sendEmail,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: OnepieceColors.fancyBlue),
              ),
            )
          ],
        ),
      ],
    );
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
}
