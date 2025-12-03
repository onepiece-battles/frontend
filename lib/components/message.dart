import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/components/square_image_loader.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:openapi/api.dart';

class MessageItem extends StatelessWidget {
  final Message message;
  final Message? preMessage;
  final String? preMessageNickname;
  final User user;
  final bool isMe;
  const MessageItem({
    super.key,
    required this.message,
    required this.preMessage,
    required this.isMe,
    required this.user,
    this.preMessageNickname,
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
                  getContent(),
                  if (preMessage != null) getPreMessage()
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
                  getContent(),
                  if (preMessage != null) getPreMessage()
                ],
              ),
            ],
          );
  }

  Widget getContent() {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: isMe ? OnepieceColors.fancyBlue : Colors.grey[900],
        ),
        padding: const EdgeInsets.all(6),
        child: message.content != null
            ? Text(
                message.content!,
                style: OnepieceFonts.tagStyle,
              )
            : SquareImageLoader(
                key: UniqueKey(),
                uriProvider: () => message.imageContentUri!,
                width: 40,
                borderWidth: 0),
      ),
    );
  }

  Widget getPreMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.grey[300],
        ),
        padding: const EdgeInsets.all(6),
        child: preMessage!.content != null
            ? Text(
                "$preMessageNickname: ${preMessage!.content!}",
                style: const TextStyle(fontSize: 10, color: Colors.white),
              )
            : SquareImageLoader(
                key: UniqueKey(),
                uriProvider: () => preMessage!.imageContentUri!,
                width: 40,
                borderWidth: 0),
      ),
    );
  }
}
