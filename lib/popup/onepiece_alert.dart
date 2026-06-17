import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';

class OnepieceAlert {
  static Future getBasicAlertDialogFunc(
      BuildContext context, String title, String displayMessage) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return _buildAlertDialog(context, title, displayMessage);
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
            return _buildAlertDialog(ctx, title, message);
          });
    };
  }

  static Widget _buildAlertDialog(
      BuildContext context, String title, String message) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          elevation: 12,
          shadowColor: Colors.black.withValues(alpha: 0.16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: OnepieceColors.fancyBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        size: 20,
                        color: OnepieceColors.fancyBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: OnepieceFonts.alertTitle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  message,
                  style: OnepieceFonts.contentStyle,
                ),
                const SizedBox(height: 22),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OnepieceColors.fancyBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.confirm),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
