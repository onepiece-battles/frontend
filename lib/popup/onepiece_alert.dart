import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';

class OnepieceAlert {
  static Future getBasicAlertDialogFunc(
      BuildContext context, String title, String displayMessage) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              title,
              style: OnepieceFonts.alertTitle,
            ),
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

  /// Returns a function that shows an alert dialog using a pre-captured
  /// [BuildContext]. The returned function is safe to call after async
  /// gaps without triggering `use_build_context_synchronously` lint.
  static void Function(String title, String message) createAlertShower(
      BuildContext context) {
    return (String title, String message) {
      showDialog(
          context: context,
          builder: (BuildContext ctx) {
            return AlertDialog(
              title: Text(title, style: OnepieceFonts.alertTitle),
              content: Text(message, style: OnepieceFonts.contentStyle),
              actions: [
                ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(AppLocalizations.of(ctx)!.confirm)),
              ],
            );
          });
    };
  }
}
