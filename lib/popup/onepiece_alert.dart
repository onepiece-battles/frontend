import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';

class OnepieceAlert {
  static Future getBasicAlertDialogFunc(
      BuildContext context, String title, String displayMessage) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title, style: OnepieceFonts.alertTitle,),
            content: Text(
              displayMessage,
              style: OnepieceFonts.contentStyle,
            ),
            actions: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    AppLocalizations.of(context)!.confirm,
                  )),
            ],
          );
        });
  }
}
