import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:one_piece_battles_flutter/components/chat_image_viewer.dart';
import 'package:one_piece_battles_flutter/components/chat_notifier.dart';
import 'package:one_piece_battles_flutter/components/original_image_loader.dart';
import 'package:one_piece_battles_flutter/components/square_image_loader.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/repository/message_dao.dart';
import 'package:one_piece_battles_flutter/utils/base64_helper.dart';
import 'package:one_piece_battles_flutter/utils/image_helper.dart';
import 'package:openapi/api.dart';
import 'package:popover/popover.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';

// `getIt` comes from the chat_notifier.dart import above.

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
                  key: ValueKey(user.imageUri),
                  uriProvider: () => user.imageUri ?? '',
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
                      key: ValueKey(user.imageUri),
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

  bool get _isConfirmed => !(message.id ?? '').startsWith('opt_');

  Future<void> _retractMessage(BuildContext context) async {
    final conversationId = message.conversationId;
    final messageId = message.id;
    if (conversationId == null || messageId == null) return;
    final response = await getIt<MessageDao>().retractMessage(
      RetractMessageRequest(
        type: MessageType.RETRACT_MESSAGE,
        chatId: conversationId,
        userId: getIt<User>().id,
        messageId: messageId,
      ),
    );
    if (response?.result == true && context.mounted) {
      Provider.of<ChatNotifier>(context, listen: false)
          .markMessageRetracted(conversationId, messageId);
    }
  }

  Widget getContent(BuildContext context) {
    if (message.retracted == true) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[300],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          AppLocalizations.of(context)!.messageRetracted,
          style: OnepieceFonts.superSmallContentStyle.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

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
            ),
            if (isMe && _isConfirmed) ...[
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
                  Navigator.of(ctx).pop();
                  _retractMessage(context);
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(AppLocalizations.of(context)!.delete,
                      style: OnepieceFonts.superSmallContentStyleWhite),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final bool hasText = message.content != null;
    final bool hasImage = message.imageContentUri != null;

    return MouseRegion(
      onEnter: (_) => BrowserContextMenu.disableContextMenu(),
      onExit: (_) => BrowserContextMenu.enableContextMenu(),
      child: Container(
        decoration: BoxDecoration(
          // iMessage-style rounded bubble: brand blue for me, light neutral
          // grey (not near-black) for received, with legible text on each.
          borderRadius: BorderRadius.circular(18),
          color: isMe ? OnepieceColors.fancyBlue : const Color(0xFFE9E9EB),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        child: Builder(builder: (innerContext) {
          return GestureDetector(
            onSecondaryTap: () => showMessageMenu(innerContext),
            onLongPress: () => showMessageMenu(innerContext),
            child: SelectionContainer.disabled(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasText)
                    Text(
                      message.content!,
                      style: TextStyle(
                        color:
                            isMe ? Colors.white : const Color(0xFF1C1C1E),
                        fontSize: 16,
                        height: 1.3,
                      ),
                      softWrap: true,
                      textAlign: TextAlign.start,
                    ),
                  // Gap between text and image
                  if (hasText && hasImage) const SizedBox(height: 6),
                  if (hasImage)
                    GestureDetector(
                      // Tap to open the full-screen zoomable viewer; the
                      // long-press menu still comes from the bubble's outer
                      // GestureDetector.
                      onTap: () => showChatImageViewer(
                          context, message.imageContentUri!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            _buildMessageImage(message.imageContentUri!, 200),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMessageImage(String imageUri, double maxWidth,
      {bool fullImage = true}) {
    if (imageUri.startsWith('data:image')) {
      final base64Data = imageUri.split(',').last;
      // Same aspect-ratio-sized rendering as OriginalImageLoader below, so
      // when the server echo arrives (this message's id changes and Flutter
      // swaps this branch out for OriginalImageLoader) the bubble doesn't
      // visibly resize.
      return ImageHelper.getOriginalImageFrame(
        OnepieceColors.fancyBlue,
        Base64Helper.decode(base64Data),
        maxWidth,
      );
    }

    // The inline bubble image is still shown small (capped at [maxWidth]),
    // but it loads the full-resolution original rather than the downscaled
    // thumbnail so it stays crisp on high-DPI screens — and shares the
    // ImageCacheManager 'full' entry with the tap-to-zoom viewer, so opening
    // the viewer is instant. The tiny reply-quote preview opts out
    // (fullImage: false) to avoid fetching a big original for a 100px quote.
    return OriginalImageLoader(
      key: ValueKey('${fullImage ? 'full' : 'thumb'}:$imageUri'),
      uriProvider: () => imageUri,
      maxWidth: maxWidth,
      fullImage: fullImage,
    );
  }

  Widget getPreMessage(BuildContext context) {
    return Container(
        margin: const EdgeInsets.symmetric(
          vertical: 5,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[600],
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
              GestureDetector(
                onTap: () => showChatImageViewer(
                    context, preMessage!.imageContentUri!),
                child: _buildMessageImage(preMessage!.imageContentUri!, 100,
                    fullImage: false),
              )
          ],
        ));
  }
}
