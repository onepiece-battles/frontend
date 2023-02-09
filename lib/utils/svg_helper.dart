import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SvgHelper {
  static IconButton getIconButtonFromSvg(
      String svgPath, Color svgColor, Function() function) {
    return IconButton(
      onPressed: function,
      icon: SvgPicture.asset(
        svgPath,
        color: svgColor,
      ),
    );
  }

  static Transform getTransformFromSvg(IconButton iconButton, double scale) {
    return Transform.scale(
      scale: scale,
      child: iconButton,
    );
  }
}
