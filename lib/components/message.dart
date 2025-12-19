import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:one_piece_battles_flutter/components/original_image_loader.dart';
import 'package:one_piece_battles_flutter/components/square_image_loader.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:openapi/api.dart';
import 'package:popover/popover.dart';
import '../l10n/app_localizations.dart';

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
              // 1. WRAP THE SENDER COLUMN IN FLEXIBLE
              Flexible(
                child: Column(
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
              // 2. WRAP THE RECEIVER COLUMN IN FLEXIBLE
              Flexible(
                child: Column(
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
              ),
            ],
          );
  }

  Widget getContent(BuildContext context) {
    // 1. Define the popup logic in a reusable function
    void showMessageMenu(BuildContext innerContext) {
      showPopover(
        arrowWidth: 6,
        arrowHeight: 5,
        direction: PopoverDirection.top,
        arrowDyOffset: -8,
        context: innerContext,
        barrierColor: Colors.transparent,
        backgroundColor: Colors.grey[600]!,
        bodyBuilder: (ctx) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                replyMessage(message);
                Navigator.of(ctx).pop();
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  AppLocalizations.of(context)!.reference,
                  style: OnepieceFonts.superSmallContentStyleWhite,
                ),
              ),
            ),
            const SizedBox(
              height: 15,
              width: 2,
              child: VerticalDivider(
                thickness: 1,
                color: Colors.grey,
              ),
            ),
            InkWell(
              onTap: () {
                if (message.content != null) {
                  Clipboard.setData(ClipboardData(text: message.content!));
                }
                Navigator.of(ctx).pop();
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(AppLocalizations.of(context)!.copy,
                    style: OnepieceFonts.superSmallContentStyleWhite),
              ),
            )
          ],
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => BrowserContextMenu.disableContextMenu(),
      onExit: (_) => BrowserContextMenu.enableContextMenu(),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isMe ? OnepieceColors.fancyBlue : Colors.grey[900],
        ),
        padding: EdgeInsets.all(message.content == null ? 0 : 6),
        child: Builder(builder: (innerContext) {
          return GestureDetector(
            // 2. Triggers on Right Click (Desktop/Web)
            onSecondaryTap: () => showMessageMenu(innerContext),
            // 3. Triggers on Long Press (Mobile/Touch)
            onLongPress: () => showMessageMenu(innerContext),
            child: SelectionContainer.disabled(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.content != null)
                    Text(
                      message.content!,
                      style: OnepieceFonts.tagStyle,
                      softWrap: true,
                      textAlign: TextAlign.start,
                    ),
                  if (message.imageContentUri != null)
                    OriginalImageLoader(
                        key: UniqueKey(),
                        uriProvider: () => message.imageContentUri!,
                        maxWidth: 150)
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget getPreMessage(BuildContext context) {
    return Container(
        margin: const EdgeInsets.symmetric(
          vertical: 5,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[300],
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (preMessage!.content != null)
              Text(
                textAlign: TextAlign.start,
                softWrap: true,
                "$preMessageNickname: ${preMessage!.content!}",
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            if (preMessage!.imageContentUri != null)
              OriginalImageLoader(
                key: UniqueKey(),
                uriProvider: () => preMessage!.imageContentUri!,
                maxWidth: 100,
              )
          ],
        ));
  }
}
