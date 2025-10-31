import 'dart:convert';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:one_piece_battles_flutter/components/square_image_loader.dart';
import 'package:one_piece_battles_flutter/components/web_socket_manager.dart';
import 'package:one_piece_battles_flutter/popup/chatting_options.dart';
import 'package:one_piece_battles_flutter/utils/time_helper.dart';
import 'package:openapi/api.dart';
import 'package:popover/popover.dart';
import '../../components/message.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/repository/chatting_dao.dart';
import 'package:flutter/foundation.dart' hide Category;
import '../../l10n/app_localizations.dart';

GetIt getIt = GetIt.instance;
const accentColor = Color(0xFF4BA586);
const accentColorDark = Color(0xFF377E6A);
const backgroundColor = Color(0xFFEEE7DF);
const secondaryColor = Color(0xFF8B98A0);
const systemBackgroundColor = Color(0xFFF7F8FA);

class ChattingView extends StatefulWidget {
  const ChattingView({super.key});

  @override
  State<ChattingView> createState() => _ChattingViewState();
}

class _ChattingViewState extends State<ChattingView> {
  late final EmojiTextEditingController _controller;
  late final ScrollController _scrollController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
  bool showEmojiPicker = false;
  final ScrollController _ctrl = ScrollController();
  final ValueNotifier<List<Message>> messagesNotifier =
      ValueNotifier<List<Message>>([]);

  @override
  void initState() {
    super.initState();
    _controller = EmojiTextEditingController(
      emojiTextStyle: DefaultEmojiTextStyle.copyWith(
        fontFamily: GoogleFonts.notoColorEmoji().fontFamily,
        fontSize: 24 * 1.2,
      ),
    );
    _scrollController = ScrollController();
    listChat();
    _connect();
  }

  Future<void> _connect() async {
    webSocketManager.connect('ws://localhost:8081/chat?userId=$userId');
    webSocketManager.stream.listen((message) {
      final Message incomingMessage = Message.fromJson(jsonDecode(message))!;
      messagesNotifier.value = [...messagesNotifier.value, incomingMessage];
      _scrollToBottom();
    }, onError: (error) {
      if (kDebugMode) {
        print('WebSocket error: $error');
      }
    }, onDone: () {
      if (kDebugMode) {
        print('WebSocket connection closed');
      }
    });
  }

  @override
  void dispose() {
    webSocketManager.disconnect();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
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
                    Expanded(
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
                    ), // search
                    ChattingOptions(
                      context: context,
                    )
                  ], // create new group
                ),
                SizedBox(
                  width: 350,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 5.0),
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
                                      Text(
                                          style: const TextStyle(
                                            color: OnepieceFonts.contentFontColor,
                                            fontSize: OnepieceFonts.contentFontSize,
                                            fontFamilyFallback: [
                                              'NotoSansCJK',
                                              'NotoColorEmoji'
                                            ],
                                          ),
                                          chat.message!.content != null
                                              ? chat.message!.content!
                                                  .split('\n')
                                                  .first
                                              : AppLocalizations.of(context)!
                                                  .image)
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
                                },
                              );
                            });
                      },
                    ),
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
                        Padding(
                          padding: const EdgeInsets.only(left: 15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                  style:
                                      OnepieceFonts.smallContentFancyBlueStyle,
                                  selectedChatNotifier.value!.group!
                                      ? selectedChatNotifier.value!.name!
                                      : getTargetMember(
                                              selectedChatNotifier.value!)
                                          .nickname),
                              IconButton(
                                onPressed: () {
                                  final scaffold = _scaffoldKey.currentState;
                                  if (scaffold == null) return;
                                  if (scaffold.isEndDrawerOpen) {
                                    Navigator.of(context)
                                        .pop(); // closes the drawer
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
                        ValueListenableBuilder<List<Message>>(
                            valueListenable: messagesNotifier,
                            builder: (context, messages, child) {
                              return Expanded(
                                child: Scaffold(
                                    key: _scaffoldKey,
                                    drawerEnableOpenDragGesture: true,
                                    drawerScrimColor: Colors.transparent,
                                    endDrawer: Drawer(
                                      width: 200,
                                      elevation: 0.1,
                                      shadowColor: Colors.green,
                                      backgroundColor:
                                          OnepieceColors.menuBackgroundColor,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.horizontal(
                                            left: Radius.circular(8)),
                                      ),
                                      child: SafeArea(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            getUserWall(),
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
                                      controller: _ctrl,
                                      shrinkWrap: true,
                                      padding: const EdgeInsets.fromLTRB(
                                          0, 0, 25, 0),
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
                                          padding: const EdgeInsets.only(
                                              bottom: 15.0),
                                          child: MessageItem(
                                            message: msg,
                                            isMe: msg.userId == userId,
                                            preMessage: msg.preMessage,
                                            user: selectedChatNotifier
                                                .value!.members
                                                .firstWhere((user) =>
                                                    user.id == msg.userId),
                                          ),
                                        ); // your widget
                                      },
                                    )),
                              );
                            }),
                        const Divider(
                          height: 3,
                          thickness: 1,
                          color: OnepieceColors.liteFancyGreen,
                        ),
                        StatefulBuilder(
                          builder:
                              (BuildContext context, StateSetter buttonState) {
                            return Container(
                              padding: const EdgeInsets.fromLTRB(8, 16, 23, 16),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      IconButton(
                                          onPressed: () => showPopover(
                                                width: 500,
                                                arrowDxOffset: -273,
                                                arrowDyOffset: 23,
                                                arrowHeight: 10,
                                                arrowWidth: 8,
                                                direction: PopoverDirection.top,
                                                context: context,
                                                backgroundColor:
                                                    OnepieceColors.fancyBlue,
                                                bodyBuilder: (context) =>
                                                    EmojiPicker(
                                                  textEditingController:
                                                      _controller,
                                                  scrollController:
                                                      _scrollController,
                                                  config: Config(
                                                    height: 256,
                                                    checkPlatformCompatibility:
                                                        true,
                                                    viewOrderConfig:
                                                        const ViewOrderConfig(
                                                      top: EmojiPickerItem
                                                          .searchBar,
                                                      middle: EmojiPickerItem
                                                          .emojiView,
                                                      bottom: EmojiPickerItem
                                                          .categoryBar,
                                                    ),
                                                    emojiTextStyle:
                                                        DefaultEmojiTextStyle
                                                            .copyWith(
                                                      fontFamily: GoogleFonts
                                                              .notoColorEmoji()
                                                          .fontFamily,
                                                      fontSize: 24 * 1.2,
                                                    ),
                                                    emojiViewConfig:
                                                        const EmojiViewConfig(
                                                      backgroundColor:
                                                          Colors.white,
                                                    ),
                                                    skinToneConfig:
                                                        const SkinToneConfig(),
                                                    categoryViewConfig:
                                                        CategoryViewConfig(
                                                      backgroundColor:
                                                          Colors.white,
                                                      dividerColor:
                                                          Colors.white,
                                                      indicatorColor:
                                                          accentColor,
                                                      iconColorSelected:
                                                          Colors.black,
                                                      iconColor: secondaryColor,
                                                      customCategoryView: (
                                                        config,
                                                        state,
                                                        tabController,
                                                        pageController,
                                                      ) {
                                                        return WhatsAppCategoryView(
                                                          config,
                                                          state,
                                                          tabController,
                                                          pageController,
                                                        );
                                                      },
                                                      categoryIcons:
                                                          const CategoryIcons(
                                                        recentIcon: Icons
                                                            .access_time_outlined,
                                                        smileyIcon: Icons
                                                            .emoji_emotions_outlined,
                                                        animalIcon: Icons
                                                            .cruelty_free_outlined,
                                                        foodIcon: Icons
                                                            .coffee_outlined,
                                                        activityIcon: Icons
                                                            .sports_soccer_outlined,
                                                        travelIcon: Icons
                                                            .directions_car_filled_outlined,
                                                        objectIcon: Icons
                                                            .lightbulb_outline,
                                                        symbolIcon: Icons
                                                            .emoji_symbols_outlined,
                                                        flagIcon:
                                                            Icons.flag_outlined,
                                                      ),
                                                    ),
                                                    bottomActionBarConfig:
                                                        const BottomActionBarConfig(
                                                      backgroundColor:
                                                          Colors.white,
                                                      buttonColor: Colors.white,
                                                      buttonIconColor:
                                                          secondaryColor,
                                                    ),
                                                    searchViewConfig:
                                                        SearchViewConfig(
                                                      backgroundColor:
                                                          Colors.white,
                                                      customSearchView: (
                                                        config,
                                                        state,
                                                        showEmojiView,
                                                      ) {
                                                        return WhatsAppSearchView(
                                                          config,
                                                          state,
                                                          showEmojiView,
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  onEmojiSelected:
                                                      (category, emoji) {
                                                    buttonState(() {
                                                      final newText =
                                                          typingController
                                                                  .text +
                                                              emoji.emoji;
                                                      typingController.text =
                                                          newText;
                                                      typingController
                                                              .selection =
                                                          TextSelection
                                                              .collapsed(
                                                                  offset: newText
                                                                      .length);
                                                    });
                                                  },
                                                ),
                                              ),
                                          splashColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          focusColor: Colors.transparent,
                                          splashRadius: 0.1,
                                          visualDensity: VisualDensity.compact,
                                          enableFeedback: false,
                                          icon: const Icon(
                                            Icons.face,
                                            size: 20,
                                            color: OnepieceColors.fancyBlue,
                                          )),
                                      IconButton(
                                          onPressed: () {},
                                          icon: const Icon(
                                            Icons.image,
                                            size: 20,
                                          ))
                                    ],
                                  ),
                                  SizedBox(
                                    height: 60,
                                    width: 200,
                                    child: TextField(
                                      controller: typingController,
                                      focusNode: FocusNode(),
                                      enabled: true,
                                      minLines: 1,
                                      maxLines: 5,
                                      keyboardType: TextInputType
                                          .text, // not TextInputType.multiline
                                      textInputAction: TextInputAction.send,
                                      onSubmitted: (_) => {
                                        buttonState(() {
                                          final SendMessageRequest request =
                                              SendMessageRequest(
                                            content: typingController.text,
                                            userId: getIt<User>().id,
                                            conversationId:
                                                selectedChatNotifier.value?.id!,
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
                                        border: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                      ),
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

  Widget getUserWall() {
    var members = selectedChatNotifier.value?.members ?? [];
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

class WhatsAppCategoryView extends CategoryView {
  const WhatsAppCategoryView(
    super.config,
    super.state,
    super.tabController,
    super.pageController, {
    super.key,
  });

  @override
  WhatsAppCategoryViewState createState() => WhatsAppCategoryViewState();
}

class WhatsAppCategoryViewState extends State<WhatsAppCategoryView>
    with SkinToneOverlayStateMixin {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.config.categoryViewConfig.backgroundColor,
      child: Row(
        children: [
          Expanded(
            child: WhatsAppTabBar(
              widget.config,
              widget.tabController,
              widget.pageController,
              widget.state.categoryEmoji,
              closeSkinToneOverlay,
            ),
          ),
          _buildExtraTab(widget.config.categoryViewConfig.extraTab),
        ],
      ),
    );
  }

  Widget _buildExtraTab(extraTab) {
    if (extraTab == CategoryExtraTab.BACKSPACE) {
      return BackspaceButton(
        widget.config,
        widget.state.onBackspacePressed,
        widget.state.onBackspaceLongPressed,
        widget.config.categoryViewConfig.backspaceColor,
      );
    } else if (extraTab == CategoryExtraTab.SEARCH) {
      return SearchButton(
        widget.config,
        widget.state.onShowSearchView,
        widget.config.categoryViewConfig.iconColor,
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class WhatsAppTabBar extends StatelessWidget {
  const WhatsAppTabBar(
    this.config,
    this.tabController,
    this.pageController,
    this.categoryEmojis,
    this.closeSkinToneOverlay, {
    super.key,
  });

  final Config config;

  final TabController tabController;

  final PageController pageController;

  final List<CategoryEmoji> categoryEmojis;

  final VoidCallback closeSkinToneOverlay;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: config.categoryViewConfig.tabBarHeight,
      child: TabBar(
        labelColor: config.categoryViewConfig.iconColorSelected,
        indicatorColor: config.categoryViewConfig.indicatorColor,
        unselectedLabelColor: config.categoryViewConfig.iconColor,
        dividerColor: config.categoryViewConfig.dividerColor,
        controller: tabController,
        labelPadding: const EdgeInsets.only(top: 1.0),
        indicatorSize: TabBarIndicatorSize.label,
        indicator: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black12,
        ),
        onTap: (index) {
          closeSkinToneOverlay();
          pageController.jumpToPage(index);
        },
        tabs: categoryEmojis
            .asMap()
            .entries
            .map<Widget>(
                (item) => _buildCategory(item.key, item.value.category))
            .toList(),
      ),
    );
  }

  Widget _buildCategory(int index, Category category) {
    return Tab(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Icon(
          getIconForCategory(
            config.categoryViewConfig.categoryIcons,
            category,
          ),
          size: 20,
        ),
      ),
    );
  }
}

class WhatsAppSearchView extends SearchView {
  const WhatsAppSearchView(super.config, super.state, super.showEmojiView,
      {super.key});

  @override
  WhatsAppSearchViewState createState() => WhatsAppSearchViewState();
}

class WhatsAppSearchViewState extends SearchViewState {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final emojiSize =
          widget.config.emojiViewConfig.getEmojiSize(constraints.maxWidth);
      final emojiBoxSize =
          widget.config.emojiViewConfig.getEmojiBoxSize(constraints.maxWidth);
      return Container(
        color: widget.config.searchViewConfig.backgroundColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: emojiBoxSize + 8.0,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                scrollDirection: Axis.horizontal,
                itemCount: results.length,
                itemBuilder: (context, index) {
                  return buildEmoji(
                    results[index],
                    emojiSize,
                    emojiBoxSize,
                  );
                },
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: widget.showEmojiView,
                  color: widget.config.searchViewConfig.buttonIconColor,
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 20.0,
                  ),
                ),
                Expanded(
                  child: TextField(
                    onChanged: onTextInputChanged,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: widget.config.searchViewConfig.hintText,
                      hintStyle: const TextStyle(
                        color: secondaryColor,
                        fontWeight: FontWeight.normal,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
