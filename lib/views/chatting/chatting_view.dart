import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/popup/chatting_options.dart';
import 'package:one_piece_battles_flutter/views/chatting/create_chatting_view.dart';
import 'package:openapi/api.dart';
import 'package:popover/popover.dart';
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

  List<Chat> chats = [];
  late String selectedChatId;

  @override
  void initState() {
    super.initState();
    _search();
  }

  _search() {
    ListChatRequest listChatRequest = ListChatRequest(userId: getIt<User>().id);
    Future<ListChatResponse?> chatting =
        getIt<ChattingDao>().listChat(listChatRequest);
    chatting.then((value) => setState(() {
          chats = value!.chats;
        }));
  }

  void _showDialog(BuildContext context) {
    showCupertinoModalPopup(
      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
      context: context,
      builder: ((context) {
        return Dialog(
          backgroundColor: Colors.white,
          alignment: Alignment.topCenter,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: const CreateChattingView(),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return
      Row(
        children: [
          Container(
            width: 300,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8.0,0,0,0),
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
                                    color: OnepieceColors.fancyGreen, width: 1.5)),
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
                          title: Text(chat.name!), // Assuming Chat has 'lastMessage'
                          onTap: () {
                            // Handle chat tap if needed
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
            child: Container(
              color: OnepieceColors.liteFancyGreen,
              child: Column(
                children: [
                  Row(), // chatting title/ group name
                  Row(), // chatting content
                  Row(), // typping area
                ],
              ),
            ),
          ),
        ],
      );
  }
}
