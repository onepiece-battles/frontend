import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../utils/image_helper.dart';

/// Shared field rows for the fruit detail sections (mobile card layout).
/// Each shows an editable input when [editable], otherwise a read-only
/// "label … value" row. Extracted so the basic-info and combat-info sections
/// render identical fields.

/// A labelled single-value field (name / energy).
Widget mobileField(BuildContext context, bool editable,
    TextEditingController ctrl, String label, String? icon,
    {bool isNum = false}) {
  final val = ctrl.text.isNotEmpty ? ctrl.text : '-';
  return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: editable
          ? SizedBox(
              height: 35,
              child: TextFormField(
                  controller: ctrl,
                  keyboardType:
                      isNum ? TextInputType.number : TextInputType.text,
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
                        borderSide:
                            BorderSide(color: OnepieceColors.fancyGreen)),
                    prefixIcon: icon != null
                        ? ImageHelper.getTextFormFieldIcon(icon, true, 18)
                        : null,
                    labelText: label,
                  )))
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                if (icon != null) ...[
                  ImageHelper.getTextFormFieldIcon(icon, true, 20),
                  const SizedBox(width: 10)
                ],
                Text(label, style: OnepieceFonts.deepBlackHintFont),
                const Spacer(),
                Text(val,
                    style: OnepieceFonts.contentStyle
                        .copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
              ])));
}

/// A labelled "slope × x + intercept" coefficient pair (combat strengthen).
Widget mobileStatPair(
    BuildContext context,
    bool editable,
    TextEditingController slope,
    TextEditingController intercept,
    String label,
    String icon) {
  final sv = slope.text.isNotEmpty ? slope.text : '0';
  final iv = intercept.text.isNotEmpty ? intercept.text : '0';
  return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: editable
          ? Row(children: [
              Expanded(
                  child: SizedBox(
                      height: 35,
                      child: TextFormField(
                          controller: slope,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            disabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: OnepieceColors.separator)),
                            enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: OnepieceColors.separator)),
                            focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: OnepieceColors.fancyGreen)),
                            prefixIcon: ImageHelper.getTextFormFieldIcon(
                                icon, true, 18),
                            labelText: label,
                          )))),
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('×', style: TextStyle(fontSize: 16))),
              Expanded(
                  child: SizedBox(
                      height: 35,
                      child: TextFormField(
                          controller: intercept,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            disabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: OnepieceColors.separator)),
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: OnepieceColors.separator)),
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: OnepieceColors.fancyGreen)),
                            labelText: '+',
                          )))),
            ])
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                ImageHelper.getTextFormFieldIcon(icon, true, 20),
                const SizedBox(width: 10),
                Text(label, style: OnepieceFonts.deepBlackHintFont),
                const Spacer(),
                Text('$sv × x + $iv',
                    style: OnepieceFonts.contentStyle
                        .copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
              ])));
}

/// A labelled dropdown (fruit type).
Widget mobileDropdown<T>(
    bool enabled,
    T value,
    List<T> items,
    Map<T, String> displayMap,
    String hint,
    String? icon,
    Function(T) onChanged) {
  return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonHideUnderline(
          child: DropdownButton2<T>(
        isExpanded: true,
        value: value,
        hint: Row(children: [
          if (icon != null) ...[
            ImageHelper.getTextFormFieldIcon(icon, true, 18),
            const SizedBox(width: 8)
          ],
          Text(hint, style: OnepieceFonts.dropDownItemStyle)
        ]),
        onChanged: enabled
            ? (T? v) {
                if (v != null) onChanged(v);
              }
            : null,
        buttonStyleData: ButtonStyleData(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 35,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: OnepieceColors.surface)),
        menuItemStyleData: const MenuItemStyleData(height: 30),
        items: items
            .map((i) => DropdownMenuItem<T>(
                value: i,
                child:
                    Text(displayMap[i]!, style: const TextStyle(fontSize: 16))))
            .toList(),
      )));
}
