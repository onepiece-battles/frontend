import 'package:flutter/material.dart';

import '../../../constants/onepiece_colors.dart';
import '../../../utils/responsive_breakpoints.dart';

/// The message box of the AI pages (the assistant and the batch import), so
/// both look and behave the same: a light bordered input that grows to a few
/// lines, and a round send button that greys out while the text is empty or
/// the AI is busy, and spins while it is busy. [leading] goes before the
/// input (the assistant's voice button). Keys are `<keyPrefix>_composer`,
/// `_input_surface`, `_input` and `_send`.
class AssistantComposer extends StatelessWidget {
  const AssistantComposer({
    super.key,
    required this.controller,
    required this.hint,
    required this.busy,
    required this.onSend,
    required this.zh,
    this.leading,
    this.keyPrefix = 'assistant',
  });

  final TextEditingController controller;
  final String hint;
  final bool busy;
  final ValueChanged<String> onSend;
  final bool zh;
  final Widget? leading;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final mobile = ResponsiveBreakpoints.isMobile(context);
    return Container(
      key: ValueKey('${keyPrefix}_composer'),
      padding: EdgeInsets.fromLTRB(
          mobile ? 8 : 16, 8, mobile ? 8 : 16, mobile ? 10 : 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border:
            Border(top: BorderSide(color: OnepieceColors.separator, width: .5)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (leading != null) ...[leading!, const SizedBox(width: 4)],
        Expanded(
          child: Container(
            key: ValueKey('${keyPrefix}_input_surface'),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: OnepieceColors.separator, width: .7),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: 24, maxHeight: mobile ? 120 : 150),
              child: TextField(
                key: ValueKey('${keyPrefix}_input'),
                controller: controller,
                minLines: 1,
                maxLines: mobile ? 5 : 6,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.send,
                cursorHeight: 16,
                style: const TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    color: OnepieceColors.primaryLabel),
                onSubmitted: onSend,
                decoration: InputDecoration(
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 9),
                  hintText: hint,
                  hintStyle: const TextStyle(
                      fontSize: 15, color: OnepieceColors.secondaryLabel),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final canSend = !busy && value.text.trim().isNotEmpty;
            return Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: IconButton.filled(
                key: ValueKey('${keyPrefix}_send'),
                tooltip:
                    busy ? (zh ? '正在回复' : 'Replying') : (zh ? '发送' : 'Send'),
                onPressed: canSend ? () => onSend(value.text) : null,
                style: IconButton.styleFrom(
                  minimumSize: const Size(40, 40),
                  maximumSize: const Size(40, 40),
                  backgroundColor: OnepieceColors.fancyBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: OnepieceColors.surface,
                  disabledForegroundColor: OnepieceColors.secondaryLabel,
                  shape: const CircleBorder(),
                ),
                icon: busy
                    ? const SizedBox.square(
                        dimension: 17,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: OnepieceColors.secondaryLabel))
                    : const Icon(Icons.arrow_upward_rounded, size: 21),
              ),
            );
          },
        ),
      ]),
    );
  }
}
