import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';

class OnepieceButtonStyle {
  static ButtonStyle getDefaultStyle() {
    return ElevatedButton.styleFrom(
        backgroundColor: OnepieceColors.fancyBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
        ),
        foregroundColor: Colors.white);
  }

  static ButtonStyle getFatherGroupButtonStyle() {
    return ElevatedButton.styleFrom(
        backgroundColor: OnepieceColors.fancyBlue,
        padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 10, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
        ),
        foregroundColor: Colors.white);
  }
}
