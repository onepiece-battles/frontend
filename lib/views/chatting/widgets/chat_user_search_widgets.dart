import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../../../components/image_lazy_loader.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';

InputDecoration chatUserSearchDecoration(String label) {
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: OnepieceColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    floatingLabelBehavior: FloatingLabelBehavior.never,
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: OnepieceColors.fancyBlue, width: 1.5),
    ),
    prefixIcon: const Icon(Icons.search, size: 19, color: OnepieceColors.secondaryLabel),
    labelText: label,
    labelStyle:
        const TextStyle(color: OnepieceColors.secondaryLabel, fontSize: 14),
  );
}

class ChatUserSearchCard extends StatelessWidget {
  const ChatUserSearchCard({
    super.key,
    required this.user,
    required this.selected,
    this.disabled = false,
    this.circularAvatar = false,
    required this.onTap,
  });

  final User user;
  final bool selected;
  final bool disabled;
  final bool circularAvatar;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatarSize = circularAvatar ? 42.0 : 40.0;
    return Card(
      elevation: selected ? 2 : 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: disabled
          ? OnepieceColors.surface
          : selected
              ? OnepieceColors.fancyBlue.withValues(alpha: 0.10)
              : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected
              ? OnepieceColors.fancyBlue
              : OnepieceColors.separator,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        hoverColor:
            disabled ? Colors.transparent : OnepieceColors.surface,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              ImageLazyLoader(
                key: ValueKey(user.imageUri),
                uriProvider: () => user.imageUri ?? '',
                width: avatarSize,
                borderWidth: 1.5,
                borderRadios: circularAvatar ? avatarSize : 8,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  user.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OnepieceFonts.contentStyle
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: selected
                    ? OnepieceColors.fancyBlue
                    : OnepieceColors.menuIconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
