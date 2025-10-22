import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/components/square_image_loader.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:openapi/api.dart';

class MessageItem extends StatelessWidget {
  final Message message;
  final Message? preMessage;
  final User user;
  final bool isMe;
  const MessageItem(
      {super.key,
      required this.message,
      required this.preMessage,
      required this.isMe,
      required this.user});

  @override
  Widget build(BuildContext context) {
    return isMe
        ? Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                children: [
                  getChatting(),
                  if (preMessage != null) getPreMessage()
                ],
              ),
              SquareImageLoader(
                  key: UniqueKey(),
                  uriProvider: () => user.imageUri!,
                  width: 40,
                  borderWidth: 0),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SquareImageLoader(
                  key: UniqueKey(),
                  uriProvider: () => user.imageUri!,
                  width: 40,
                  borderWidth: 0),
              Column(
                children: [
                  getChatting(),
                  if (preMessage != null) getPreMessage()
                ],
              ),
            ],
          );
  }

  Widget getChatting() {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: isMe ? OnepieceColors.fancyBlue : Colors.grey[900],
          ),
          padding: const EdgeInsets.all(6.5),
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
      ),
    );
  }

  Widget getPreMessage() {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isMe ? Colors.blue[200] : Colors.grey[300],
        ),
        padding: const EdgeInsets.all(16),
        child: preMessage!.content != null
            ? Text(
                preMessage!.content!,
                style: const TextStyle(fontSize: 15),
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
