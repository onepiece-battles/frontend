import 'package:flutter/material.dart';
import 'package:popover/popover.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

import '../constants/onepiece_colors.dart';

class EmojiSelection extends StatefulWidget {
  final TextEditingController editingController;
  const EmojiSelection({super.key, required this.editingController});

  @override
  State<EmojiSelection> createState() => _EmojiSelectionState();
}

class _EmojiSelectionState extends State<EmojiSelection> {
  TextEditingController emojiController = TextEditingController();

  static const config = Config(
    height: 250,
    checkPlatformCompatibility: false,
    emojiViewConfig: EmojiViewConfig(
      // Define number of columns based on screen width
      columns: 7,
      emojiSizeMax: 20,
      backgroundColor: Colors.transparent,
      buttonMode: ButtonMode.CUPERTINO,
    ),
    categoryViewConfig: CategoryViewConfig(
      // WeChat style: Categories at the bottom, minimal look
      initCategory: Category.SMILEYS,
      backgroundColor: OnepieceColors.fancyBlue,
      indicatorColor: Color(0xFF07C160),
      dividerColor: Colors.transparent,
      iconColorSelected: Color(0xFF07C160),

    ),
    bottomActionBarConfig: BottomActionBarConfig(
      enabled: false, // Hide the search/backspace bar for cleaner UI
      showBackspaceButton: false,
      showSearchViewButton: false,
    ),
    searchViewConfig: SearchViewConfig(
      backgroundColor: Colors.white,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (innerContext) {
      return IconButton(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        splashRadius: 0.1,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        enableFeedback: false,
        onPressed: () => showPopover(
            arrowWidth: 10,
            arrowHeight: 8,
            direction: PopoverDirection.top,
            arrowDyOffset: 5,
            context: innerContext,
            barrierColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            bodyBuilder: (ctx) => Container(
                width: 300, // Fixed width like a desktop popover
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: EmojiPicker(
                    textEditingController:
                        emojiController, // Optional if using onEmojiSelected
                    onEmojiSelected: _onEmojiSelected,
                    onBackspacePressed: () {
                      // Handle backspace logic manually if needed,
                      // or let the controller handle it via the library
                      emojiController.text = emojiController
                          .text.characters
                          .skipLast(1)
                          .toString();
                    },
                    config: config,
                  ),
                ))),
        icon: const Icon(
          Icons.face,
          color: OnepieceColors.fancyBlue,
          size: 20,
        ),
      );
    });
  }

  void _onEmojiSelected(Category? category, Emoji emoji) {
    final text = widget.editingController.text;
    final selection = emojiController.selection;
    final cursorPosition = selection.baseOffset;

    if (cursorPosition < 0) {
      // If no cursor position, add to end
      widget.editingController.text += emoji.emoji;
    } else {
      final newText =
          text.replaceRange(selection.start, selection.end, emoji.emoji);
      final newCursorPosition = cursorPosition + emoji.emoji.length;
      emojiController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursorPosition),
      );
    }
  }
}
