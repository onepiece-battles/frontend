import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/utils/string_extensions.dart';
import '../constants/onepiece_colors.dart';
import '../constants/onepiece_fonts.dart';
import '../utils/data_validator.dart';

class StringTextFormField extends StatelessWidget {
  final BuildContext buildContext;
  final bool editable;
  final TextEditingController controller;
  final String label;
  final int length;
  final Widget icon;
  final bool required;

  const StringTextFormField(this.buildContext, this.editable, this.controller,
      this.label, this.length, this.icon, this.required,
      {super.key});

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
            controller: controller,
            enabled: editable,
            maxLength: length,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            buildCounter: (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) {
              if (!isFocused) {
                return const Text("");
              } else {
                return Text(
                    "$currentLength/$maxLength ${AppLocalizations.of(context)!.characters}");
              }
            },
            validator: (value) {
              if ((required && value!.isWhiteSpace()) ||
                  (required && value == null)) {
                return AppLocalizations.of(buildContext)!.requiredField;
              }
              if (!DataValidator.validName(value!)) {
                return AppLocalizations.of(context)!.invalidName;
              }
              return null;
            },
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.never,
              isDense: true,
              contentPadding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5.0),
                borderSide: const BorderSide(
                  color: OnepieceColors.fancyBlue,
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
              filled: true,
              fillColor:
                  editable ? Colors.white : OnepieceColors.liteFancyGreen,
            ),
          ),
        ),
      ],
    );
  }
}
