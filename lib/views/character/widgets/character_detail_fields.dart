import 'package:flutter/material.dart';

import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../utils/image_helper.dart';

/// A labelled field row shared by the character detail basic-info and
/// combat-info sections. Shows a bordered [TextFormField] when [editable],
/// otherwise a read-only "label … value" row.
Widget mobileField(BuildContext context, bool editable,
    TextEditingController ctrl, String label, String? icon,
    {bool isNum = false}) {
  final value = ctrl.text.isNotEmpty ? ctrl.text : '-';
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: editable
        ? SizedBox(
            height: 35,
            child: TextFormField(
              controller: ctrl,
              keyboardType: isNum ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                floatingLabelBehavior: FloatingLabelBehavior.never,
                disabledBorder: const OutlineInputBorder(
                    borderSide:
                        BorderSide(color: OnepieceColors.separator)),
                enabledBorder: const OutlineInputBorder(
                    borderSide:
                        BorderSide(color: OnepieceColors.separator)),
                focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: OnepieceColors.fancyGreen)),
                prefixIcon: icon != null
                    ? ImageHelper.getTextFormFieldIcon(icon, true, 18)
                    : null,
                labelText: label,
              ),
            ))
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              if (icon != null) ...[
                ImageHelper.getTextFormFieldIcon(icon, true, 20),
                const SizedBox(width: 10)
              ],
              Text(label, style: OnepieceFonts.deepBlackHintFont),
              const Spacer(),
              Text(value,
                  style: OnepieceFonts.contentStyle
                      .copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
            ]),
          ),
  );
}
