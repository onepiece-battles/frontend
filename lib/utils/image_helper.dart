import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ImageHelper {
  static IconButton getIconButtonFromSvg(
    String svgPath,
    Color svgColor,
    double width,
    double height,
    Function() onPressed,
  ) {
    return IconButton(
      onPressed: onPressed,
      splashRadius: 1,
      icon: SvgPicture.asset(
        svgPath,
        color: svgColor,
        width: width,
        height: height,
      ),
    );
  }

  static Transform getTransformFromSvg(
    String svgPath,
    Color svgColor,
    double width,
    double height,
    Function() onPressed,
    double scale,
  ) {
    return Transform.scale(
      scale: scale,
      child: getIconButtonFromSvg(
        svgPath,
        svgColor,
        width,
        height,
        onPressed,
      ),
    );
  }

  static Image getImageFromPath(String path) {
    return Image(
      image: AssetImage(path),
      fit: BoxFit.fill,
    );
  }

  static IconButton getIconButtonFromImage(
    String path,
    double iconSize,
    EdgeInsets padding,
    Function() onPressed,
  ) {
    return IconButton(
      onPressed: onPressed,
      icon: getImageFromPath(path),
      iconSize: iconSize,
      padding: padding,
    );
  }

  static Widget getSvgIcon(
      String svgPath, double width, double height) {
    return SvgPicture.asset(
      svgPath,
      // color: svgColor,
      width: width,
      height: height,
    );
  }

  static Widget getSvgIconWithColor(
      String svgPath, double width, double height, Color color) {
    return SvgPicture.asset(
      svgPath,
      color: color,
      width: width,
      height: height,
    );
  }
}
