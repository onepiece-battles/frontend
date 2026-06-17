import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import '../../l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/views/chatting/add_friend_view.dart';
import 'package:one_piece_battles_flutter/views/chatting/create_chatting_view.dart';

GetIt getIt = GetIt.instance;

class ChattingOptions extends StatefulWidget {
  const ChattingOptions({super.key, required BuildContext context});

  @override
  State<ChattingOptions> createState() => _ChattingOptionsState();
}

class _ChattingOptionsState extends State<ChattingOptions> {
  Future<void> _showOptions(BuildContext buttonContext) async {
    final buttonBox = buttonContext.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(buttonContext).context.findRenderObject() as RenderBox;
    final buttonTopLeft =
        buttonBox.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonRect = buttonTopLeft & buttonBox.size;
    final localizations = AppLocalizations.of(context)!;

    final selected = await showMenu<_ChattingAction>(
      context: context,
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      position: RelativeRect.fromRect(
        buttonRect,
        Offset.zero & overlay.size,
      ),
      items: [
        _buildMenuItem(
          value: _ChattingAction.createChat,
          icon: Icons.chat_bubble_outline,
          label: localizations.createChatting,
        ),
        _buildMenuItem(
          value: _ChattingAction.addFriend,
          icon: Icons.group_add_outlined,
          label: localizations.addFriend,
        ),
      ],
    );

    if (!mounted || selected == null) return;
    if (selected == _ChattingAction.createChat) {
      _showCardDialog(const CreateChattingView());
    } else {
      _showCardDialog(const AddFriendView());
    }
  }

  PopupMenuItem<_ChattingAction> _buildMenuItem({
    required _ChattingAction value,
    required IconData icon,
    required String label,
  }) {
    return PopupMenuItem<_ChattingAction>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Container(
        width: 190,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: OnepieceColors.liteFancyBlue.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: OnepieceColors.menuHoverColor.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: OnepieceColors.fancyBlue),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OnepieceFonts.smallContentStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCardDialog(Widget child) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (buttonContext) => InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showOptions(buttonContext),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: OnepieceColors.fancyBlue,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: OnepieceColors.fancyBlue.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

enum _ChattingAction { createChat, addFriend }
