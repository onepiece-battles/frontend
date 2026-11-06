import 'package:flutter/material.dart';
import 'package:popover/popover.dart';
// Only the emoji DATA is reused from the package (defaultEmojiSet / Category);
// the picker UI is our own lightweight grid — emoji_picker_flutter's own view
// wraps every emoji in a CupertinoButton and is janky on Flutter web.
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart'
    show defaultEmojiSet, CategoryEmoji, Category;

import '../constants/onepiece_colors.dart';

/// Recently-used emoji, most-recent-first, kept for the app session so the
/// picker can offer a quick "recent" tab. Module-level so it survives the
/// picker widget being rebuilt or reopened.
final List<String> _recentEmojis = <String>[];
const int _maxRecent = 24;

void _recordRecent(String emoji) {
  _recentEmojis.remove(emoji);
  _recentEmojis.insert(0, emoji);
  if (_recentEmojis.length > _maxRecent) {
    _recentEmojis.removeRange(_maxRecent, _recentEmojis.length);
  }
}

class EmojiSelection extends StatefulWidget {
  final TextEditingController editingController;
  final FocusNode focusNode;
  final Color iconColor;
  final double iconSize;

  const EmojiSelection({
    super.key,
    required this.editingController,
    required this.focusNode,
    this.iconColor = OnepieceColors.fancyBlue,
    this.iconSize = 20,
  });

  @override
  State<EmojiSelection> createState() => _EmojiSelectionState();
}

class _EmojiSelectionState extends State<EmojiSelection> {
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
          showPopover(
            arrowWidth: 10,
            arrowHeight: 8,
            direction: PopoverDirection.top,
            arrowDyOffset: 5,
            context: innerContext,
            barrierColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            bodyBuilder: (ctx) => _EmojiPanel(onSelected: _onEmojiSelected),
          );
        },
        icon: Icon(
          Icons.face,
          color: widget.iconColor,
          size: widget.iconSize,
        ),
      );
    });
  }

  void _onEmojiSelected(String emoji) {
    final controller = widget.editingController;
    final text = controller.text;
    final selection = controller.selection;
    final cursorPos = selection.baseOffset;

    if (cursorPos < 0) {
      controller.text = '$text$emoji';
    } else {
      final newText = text.replaceRange(selection.start, selection.end, emoji);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursorPos + emoji.length),
      );
    }
    widget.focusNode.requestFocus();
    _recordRecent(emoji);
  }
}

class _EmojiTab {
  const _EmojiTab(this.icon, this.emojis);
  final IconData icon;
  final List<String> emojis;
}

/// A lightweight emoji grid: category tabs + a lazy [GridView.builder] whose
/// cells are a bare tap region over a [Text] glyph. Only visible cells are
/// built (and each is its own repaint boundary), so opening and scrolling stay
/// smooth even with the full emoji set.
class _EmojiPanel extends StatefulWidget {
  const _EmojiPanel({required this.onSelected});
  final void Function(String emoji) onSelected;

  @override
  State<_EmojiPanel> createState() => _EmojiPanelState();
}

class _EmojiPanelState extends State<_EmojiPanel> {
  late final List<_EmojiTab> _tabs;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _tabs = [
      if (_recentEmojis.isNotEmpty)
        _EmojiTab(Icons.schedule, List<String>.from(_recentEmojis)),
      for (final CategoryEmoji c in defaultEmojiSet)
        _EmojiTab(
          _iconFor(c.category),
          c.emoji.map((e) => e.emoji).toList(growable: false),
        ),
    ];
  }

  IconData _iconFor(Category category) {
    switch (category) {
      case Category.RECENT:
        return Icons.schedule;
      case Category.SMILEYS:
        return Icons.emoji_emotions_outlined;
      case Category.ANIMALS:
        return Icons.pets_outlined;
      case Category.FOODS:
        return Icons.restaurant_outlined;
      case Category.TRAVEL:
        return Icons.directions_car_outlined;
      case Category.ACTIVITIES:
        return Icons.sports_basketball_outlined;
      case Category.OBJECTS:
        return Icons.lightbulb_outline;
      case Category.SYMBOLS:
        return Icons.emoji_symbols_outlined;
      case Category.FLAGS:
        return Icons.flag_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final emojis = _tabs[_selected].emojis;
    return Container(
      width: 300,
      height: 262,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          children: [
            _buildTabBar(),
            Divider(height: 1, color: Colors.grey.shade200),
            Expanded(
              child: GridView.builder(
                key: ValueKey(_selected),
                // Rasterizing color-emoji glyphs is the costly part on web, so
                // paint a few rows ahead of the viewport (cacheExtent) and drop
                // the per-item keep-alive / semantics bookkeeping to keep
                // scrolling smooth.
                cacheExtent: 420,
                addAutomaticKeepAlives: false,
                addSemanticIndexes: false,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                ),
                itemCount: emojis.length,
                itemBuilder: (context, i) {
                  final e = emojis[i];
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.onSelected(e),
                    child: Center(
                      child: Text(e, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          for (var i = 0; i < _tabs.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_selected != i) setState(() => _selected = i);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: i == _selected
                            ? OnepieceColors.fancyBlue
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Icon(
                    _tabs[i].icon,
                    size: 19,
                    color: i == _selected
                        ? OnepieceColors.fancyBlue
                        : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
