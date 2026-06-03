import 'package:flutter/material.dart';
import 'package:popover/popover.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

import '../constants/onepiece_colors.dart';

class EmojiSelection extends StatefulWidget {
  final TextEditingController editingController;
  final FocusNode focusNode;
  const EmojiSelection(
      {super.key,
      required this.editingController,
      required this.focusNode});

  @override
  State<EmojiSelection> createState() => _EmojiSelectionState();
}

class _EmojiSelectionState extends State<EmojiSelection> {
  // Cache the heavy EmojiPicker widget — it's built once and reused across
  // every popover open, eliminating the 200-500ms lag on each open.
  Widget? _cachedPicker;

  static const config = Config(
    height: 250,
    checkPlatformCompatibility: false,
    emojiViewConfig: EmojiViewConfig(
      columns: 7,
      emojiSizeMax: 20,
      backgroundColor: Colors.transparent,
      buttonMode: ButtonMode.CUPERTINO,
    ),
    categoryViewConfig: CategoryViewConfig(
      initCategory: Category.SMILEYS,
      backgroundColor: OnepieceColors.fancyBlue,
      indicatorColor: Color(0xFF07C160),
      dividerColor: Colors.transparent,
      iconColorSelected: Color(0xFF07C160),
    ),
    bottomActionBarConfig: BottomActionBarConfig(
      enabled: false,
      showBackspaceButton: false,
      showSearchViewButton: false,
    ),
    searchViewConfig: SearchViewConfig(
      backgroundColor: Colors.white,
    ),
  );

  Widget _buildPicker() {
    return Container(
      width: 300,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: EmojiPicker(
          config: config,
          onEmojiSelected: _onEmojiSelected,
        ),
      ),
    );
  }

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
        onPressed: () {
          // Lazily build the picker on first open, then reuse forever
          _cachedPicker ??= _buildPicker();
          showPopover(
            arrowWidth: 10,
            arrowHeight: 8,
            direction: PopoverDirection.top,
            arrowDyOffset: 5,
            context: innerContext,
            barrierColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            bodyBuilder: (ctx) => _cachedPicker!,
          );
        },
        icon: const Icon(
          Icons.face,
          color: OnepieceColors.fancyBlue,
          size: 20,
        ),
      );
    });
  }

  void _onEmojiSelected(Category? category, Emoji emoji) {
    final controller = widget.editingController;
    final text = controller.text;
    final selection = controller.selection;
    final cursorPos = selection.baseOffset;

    if (cursorPos < 0) {
      controller.text = '$text${emoji.emoji}';
    } else {
      final newText =
          text.replaceRange(selection.start, selection.end, emoji.emoji);
      controller.value = TextEditingValue(
        text: newText,
        selection:
            TextSelection.collapsed(offset: cursorPos + emoji.emoji.length),
      );
    }
    widget.focusNode.requestFocus();
  }
}
