import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/utils/string_extensions.dart';

import '../constants/onepiece_fonts.dart';

class FruitDigitTextFormField extends StatelessWidget {
  final TextEditingController slopeController;
  final TextEditingController interceptController;
  final bool editable;
  final BuildContext buildContext;
  final double slopeMax;
  final double slopeMin;
  final int interceptMax;
  final int interceptMin;
  final String label;
  final Widget icon;
  const FruitDigitTextFormField(
      this.buildContext,
      this.editable,
      this.slopeController,
      this.interceptController,
      this.label,
      this.slopeMin,
      this.slopeMax,
      this.interceptMin,
      this.interceptMax,
      this.icon,
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
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 70,
                child: TextFormField(
                  enabled: editable,
                  controller: slopeController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value!.isWhiteSpace()) {
                      return AppLocalizations.of(buildContext)!.requiredField;
                    } else if (!value.isValidDouble()) {
                      return AppLocalizations.of(buildContext)!.fieldMustBeDigit;
                    }
                    if (double.parse(value) < slopeMin ||
                        double.parse(value) > slopeMax) {
                      return AppLocalizations.of(buildContext)!.valueExceedsLimit;
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    contentPadding: const EdgeInsets.fromLTRB(10, 10, 0, 0),
                    hintText: "$slopeMin-$slopeMax",
                  ),
                ),
              ),
              const Icon(Icons.close, color: OnepieceColors.fancyGreen,),
              icon,
              const Icon(Icons.add, color: OnepieceColors.fancyGreen),
              SizedBox(
                width: 100,
                height: 70,
                child: TextFormField(
                  enabled: editable,
                  controller: interceptController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value!.isWhiteSpace()) {
                      return AppLocalizations.of(buildContext)!.requiredField;
                    } else if (!value.isValidInt()) {
                      return AppLocalizations.of(buildContext)!.fieldMustBeInt;
                    }
                    if (int.parse(value) < interceptMin ||
                        int.parse(value) > interceptMax) {
                      return AppLocalizations.of(buildContext)!.valueExceedsLimit;
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    contentPadding: const EdgeInsets.fromLTRB(10, 10, 0, 0),
                    hintText: "$interceptMin-$interceptMax",
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
