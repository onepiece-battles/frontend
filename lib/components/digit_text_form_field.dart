import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/utils/string_extensions.dart';

import '../constants/onepiece_colors.dart';
import '../constants/onepiece_fonts.dart';

/*
  DigitTextFormField is used to create a TextFormField that hold a editable
  integer value.
 */
class DigitTextFormField extends StatelessWidget {
  final TextEditingController textEditingController;
  final bool editable;
  final BuildContext buildContext;
  final int max;
  final int min;
  final Widget icon;
  final String label;
  final bool required;

  const DigitTextFormField(
    this.buildContext,
    this.editable,
    this.textEditingController,
    this.label,
    this.min,
    this.max,
    this.icon,
    this.required, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 300,
          height: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              icon,
              Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Text(
                  label,
                  style: OnepieceFonts.deepBlackHintFont,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 300,
          child: TextFormField(
            enabled: editable,
            controller: textEditingController,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              if (!required && (value == null || value.isEmpty)) {
                return null;
              }
              if (required && (value == null || value.isEmpty)) {
                return AppLocalizations.of(buildContext)!.requiredField;
              }
              if (value != null && value.isNotEmpty && !value.isValidInt()) {
                return AppLocalizations.of(buildContext)!.fieldMustBeInt;
              }
              int valueInt = int.parse(value!);
              if (valueInt < min || valueInt > max) {
                return AppLocalizations.of(buildContext)!.valueExceedsLimit;
              }
              return null;
            },
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.never,
              isDense: true,
              contentPadding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
              hintText: editable ? "$min - $max" : "",
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5.0),
                borderSide: const BorderSide(
                  color: OnepieceColors.fancyBlue,
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5.0),
                borderSide: const BorderSide(
                  color: OnepieceColors.fancyBlue,
                  width: 1.5,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5.0),
                borderSide: const BorderSide(
                  color: Colors.white,
                  width: 1.0,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5.0),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5.0),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor:
                  editable ? Colors.white : OnepieceColors.liteFancyGreen,
            ),
          ),
        ),
        const SizedBox(
          height: 18,
        )
      ],
    );
  }
}
