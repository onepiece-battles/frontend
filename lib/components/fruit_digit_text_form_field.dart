import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/utils/string_extensions.dart';

import '../constants/onepiece_fonts.dart';

class FruitDigitTextFormField extends StatefulWidget {
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
  State<FruitDigitTextFormField> createState() =>
      _FruitDigitTextFormFieldState();
}

class _FruitDigitTextFormFieldState extends State<FruitDigitTextFormField> {
  final ValueNotifier<bool> leftHasError = ValueNotifier<bool>(false);
  final ValueNotifier<bool> rightHasError = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: SizedBox(
            width: 300,
            height: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                widget.icon,
                Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Text(
                    widget.label,
                    style: OnepieceFonts.deepBlackHintFont,
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 100,
              child: TextFormField(
                enabled: widget.editable,
                controller: widget.slopeController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.isWhiteSpace()) {
                    leftHasError.value = true;
                    return AppLocalizations.of(widget.buildContext)!
                        .requiredField;
                  } else if (!value.isValidDouble()) {
                    leftHasError.value = true;
                    return AppLocalizations.of(widget.buildContext)!
                        .fieldMustBeDigit;
                  }
                  if (double.parse(value) < widget.slopeMin ||
                      double.parse(value) > widget.slopeMax) {
                    leftHasError.value = true;
                    return AppLocalizations.of(widget.buildContext)!
                        .valueExceedsLimit;
                  }
                  leftHasError.value = false;
                  return null;
                },
                decoration: InputDecoration(
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  isDense: true,
                  contentPadding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                  hintText: "${widget.slopeMin} - ${widget.slopeMax}",
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
                  fillColor: widget.editable
                      ? Colors.white
                      : OnepieceColors.liteFancyGreen,
                ),
              ),
            ),
            const Icon(
              Icons.close,
              color: OnepieceColors.fancyGreen,
            ),
            widget.icon,
            const Icon(Icons.add, color: OnepieceColors.fancyGreen),
            SizedBox(
              width: 100,
              child: TextFormField(
                enabled: widget.editable,
                controller: widget.interceptController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.isWhiteSpace()) {
                    rightHasError.value = true;
                    return AppLocalizations.of(widget.buildContext)!
                        .requiredField;
                  } else if (!value.isValidInt()) {
                    rightHasError.value = true;
                    return AppLocalizations.of(widget.buildContext)!
                        .fieldMustBeInt;
                  }
                  if (int.parse(value) < widget.interceptMin ||
                      int.parse(value) > widget.interceptMax) {
                    rightHasError.value = true;
                    return AppLocalizations.of(widget.buildContext)!
                        .valueExceedsLimit;
                  }
                  rightHasError.value = false;
                  return null;
                },
                decoration: InputDecoration(
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  contentPadding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                  hintText: "${widget.interceptMin} - ${widget.interceptMax}",
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: const BorderSide(
                      color: OnepieceColors.fancyBlue,
                      width: 1.0,
                    ),
                  ),
                  isDense: true,
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
                  fillColor: widget.editable
                      ? Colors.white
                      : OnepieceColors.liteFancyGreen,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
