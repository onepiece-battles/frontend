import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:one_piece_battles_flutter/components/square_image_loader.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:openapi/api.dart';
import 'package:popover/popover.dart';
import '../../l10n/app_localizations.dart';

class MessageItem extends StatelessWidget {
  final Message message;
  final Message? preMessage;
  final String? preMessageNickname;
  final User user;
  final bool isMe;
  final Function replyMessage;
  const MessageItem({
    super.key,
    required this.message,
    required this.preMessage,
    required this.isMe,
    required this.user,
    this.preMessageNickname,
    required this.replyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return isMe
        ? Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 5,
                  ),
                  getContent(context),
                  if (preMessage != null) getPreMessage(context)
                ],
              ),
              const SizedBox(
                width: 10,
              ),
              SquareImageLoader(
                  key: UniqueKey(),
                  uriProvider: () => user.imageUri!,
                  width: 40,
                  borderWidth: 2),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                children: [
                  const SizedBox(
                    height: 7,
                  ),
                  SquareImageLoader(
                      key: UniqueKey(),
                      uriProvider: () => user.imageUri!,
                      width: 40,
                      borderWidth: 2),
                ],
              ),
              const SizedBox(
                width: 10,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.nickname,
                    style: OnepieceFonts.superSmallContentStyle,
                  ),
                  const SizedBox(
                    height: 7,
                  ),
                  getContent(context),
                  if (preMessage != null) getPreMessage(context)
                ],
              ),
            ],
          );
  }

  Widget getContent(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => BrowserContextMenu.disableContextMenu(),
      onExit: (_) => BrowserContextMenu.enableContextMenu(),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: isMe ? OnepieceColors.fancyBlue : Colors.grey[900],
        ),
        padding: const EdgeInsets.all(6),
        child: SelectionArea(
          child: Builder(builder: (innerContext) {
          return GestureDetector(
            onSecondaryTap: () => showPopover(
              // height: 25,
              // width: 80,
              direction: PopoverDirection.top,
              arrowDyOffset: -8,
              context: innerContext,
              barrierColor: Colors.transparent,
              backgroundColor: Colors.grey[500]!,
              bodyBuilder: (ctx) => InkWell(
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                focusColor: Colors.transparent,
                onTap: () {
                  replyMessage(message);
                  Navigator.of(ctx).pop();
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                    child: Text(
                  AppLocalizations.of(context)!.reference,
                  style: OnepieceFonts.superSmallContentStyleWhite,
                )),
              ),
            ),
            child: message.content != null
                ? Text(
                    message.content!,
                    style: OnepieceFonts.tagStyle,
                    softWrap: true,
                    textAlign: TextAlign.justify,
                  )
                : SquareImageLoader(
                    key: UniqueKey(),
                    uriProvider: () => message.imageContentUri!,
                    width: 40,
                    borderWidth: 0),
          );
        }),
        ),
      ),
    );
  }

  Widget getPreMessage(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Colors.grey[300],
      ),
      padding: const EdgeInsets.all(6),
      child: preMessage!.content != null
          ? Text(
              softWrap: true,
              "$preMessageNickname: ${preMessage!.content!}",
              style: const TextStyle(fontSize: 10, color: Colors.white),
            )
          : SquareImageLoader(
              key: UniqueKey(),
              uriProvider: () => preMessage!.imageContentUri!,
              width: 40,
              borderWidth: 0),
    );
  }
}
