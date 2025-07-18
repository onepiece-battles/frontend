import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/views/chatting/add_friend_view.dart';
import 'package:one_piece_battles_flutter/views/chatting/create_chatting_view.dart';
import 'package:popover/popover.dart';
import '../constants/button_style.dart';

GetIt getIt = GetIt.instance;

class ChattingOptions extends StatefulWidget {
  // final BoxConstraints constraints;

  const ChattingOptions({super.key, required BuildContext context});

  @override
  State<ChattingOptions> createState() => _ChattingOptionsState();
}

class _ChattingOptionsState extends State<ChattingOptions> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 40,
      splashRadius: 0.1,
      color: OnepieceColors.liteFancyBlue,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      focusColor: Colors.transparent,
      onPressed: () => showPopover(
        width: 170,
        height: 70,
        direction: PopoverDirection.top,
        context: context,
        backgroundColor: OnepieceColors.fancyBlue,
        bodyBuilder: (context) => Column(
          children: [
            SizedBox(
              width: 170,
              height: 35,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: ((context) {
                      return Dialog(
                        surfaceTintColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        alignment: AlignmentDirectional.center,
                        child: const CreateChattingView(),
                      );
                    }),
                  );
                },
                style: OnepieceButtonStyle.getDefaultStyle(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        AppLocalizations.of(context)!.createChatting,
                        style: OnepieceFonts.smallContentStyleWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 170,
              height: 35,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: ((context) {
                      return Dialog(
                        surfaceTintColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        alignment: AlignmentDirectional.center,
                        child: const AddFriendView(),
                      );
                    }),
                  );
                },
                style: OnepieceButtonStyle.getDefaultStyle(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.group_add_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        AppLocalizations.of(context)!.addFriend,
                        style: OnepieceFonts.smallContentStyleWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      icon: const Icon(
        Icons.add_box,
        color: OnepieceColors.liteFancyBlue,
      ),
    );
  }
}
