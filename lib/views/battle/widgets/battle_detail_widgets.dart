import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../../../components/image_lazy_loader.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../utils/i18n_helper.dart';
import '../../../utils/image_helper.dart';

/// Pure, stateless display helpers for the battle detail screen: a small
/// combatant avatar+score, and the vertical workflow step / connector marks.
Widget charMini(Character char, int? score) {
  return Column(children: [
    ImageLazyLoader(
        key: ValueKey(char.imageUri),
        uriProvider: () => char.imageUri!,
        width: 52,
        borderWidth: 1.5,
        borderRadios: 52),
    const SizedBox(height: 2),
    Text(I18nHelper.getDisplayNameFromI18n(char.name),
        style: const TextStyle(fontSize: 11),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center),
    Text(score?.toString() ?? '?',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
  ]);
}

Widget workflowConnector(bool active, double iconSize) {
  return Padding(
    padding: EdgeInsets.only(left: iconSize / 2 - 1, top: 3, bottom: 3),
    child: Container(
      width: 2,
      height: iconSize * 0.7,
      decoration: BoxDecoration(
        color: active
            ? OnepieceColors.fancyBlue
            : OnepieceColors.liteFancyBlue.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

Widget workflowStep({
  required String label,
  required bool done,
  required double iconSize,
  bool failed = false,
}) {
  final color = failed
      ? Colors.red
      : done
          ? OnepieceColors.fancyBlue
          : OnepieceColors.liteFancyBlue;
  final style = done && !failed
      ? OnepieceFonts.fancyBlueHintFont
      : OnepieceFonts.liteFancyBlueHintFont;

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: iconSize + 8,
        height: iconSize + 8,
        decoration: BoxDecoration(
          color: color.withValues(alpha: done || failed ? 0.12 : 0.08),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: failed
              ? ImageHelper.getSvgIconWithColor(
                  'images/svgs/failed.svg', iconSize, iconSize, Colors.red)
              : Icon(
                  done ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: iconSize,
                  color: color,
                ),
        ),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: Text(
          label,
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      )
    ],
  );
}
