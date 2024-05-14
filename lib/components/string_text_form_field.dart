import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../constants/onepiece_fonts.dart';

class StringTextFormField extends StatelessWidget {
  final BuildContext buildContext;
  final bool editable;
  final TextEditingController controller;
  final String label;
  final int length;
  final Widget icon;

  const StringTextFormField(this.buildContext, this.editable, this.controller,
      this.label, this.length, this.icon,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      // mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 300,
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
          height: 58,
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
            decoration: const InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.never,
              contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 15),
            ),
          ),
        ),
      ],
    );
  }
}
