import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../constants/onepiece_colors.dart';

class ImageHelper {
  static Widget getSquareImageFrame(double width, double height,
      double? borderWidth, Color? borderColor, Uint8List imageData) {
    return Container(
      width: width,
      height: height,
      decoration: borderWidth == null || borderColor == null
          ? null
          : BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(2.0)),
              border: Border.all(
                  color: borderColor,
                  width: borderWidth,
                  style: BorderStyle.solid),
            ),
      child: ClipRect(
        child: AspectRatio(
          aspectRatio: 1,
          child: FittedBox(
            fit: BoxFit.cover,
            child: Image.memory(imageData),
          ),
        ),
      ),
    );
  }

  static Widget getCircleImageFrame(double width, double height,
      double? borderWidth, Color? borderColor, Uint8List imageData) {
    return Container(
      width: width,
      height: height,
      decoration: borderWidth == null || borderColor == null
          ? null
          : BoxDecoration(
              borderRadius: BorderRadius.all(
                  Radius.circular(width < height ? width : height)),
              border: Border.all(
                  color: borderColor,
                  width: borderWidth,
                  style: BorderStyle.solid),
            ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width < height ? width : height),
        child: AspectRatio(
          aspectRatio: 1,
          child: FittedBox(
            fit: BoxFit.cover,
            child: Image.memory(imageData),
          ),
        ),
      ),
    );
  }

  static Widget getRoundImageFrame(
      double width,
      double height,
      double? borderWidth,
      Color? borderColor,
      double borderRadios,
      Uint8List imageData) {
    return Container(
      width: width,
      height: height,
      decoration: borderWidth == null || borderColor == null
          ? null
          : BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(borderRadios)),
              border: Border.all(
                  color: borderColor,
                  width: borderWidth,
                  style: BorderStyle.solid),
            ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadios - (borderWidth ?? 0)),
        child: AspectRatio(
          aspectRatio: 1,
          child: FittedBox(
            fit: BoxFit.cover,
            child: Image.memory(imageData),
          ),
        ),
      ),
    );
  }

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
        "asset/$svgPath",
        color: svgColor,
        width: width,
        height: height,
      ),
    );
  }

  static Image getImageFromPath(String path) {
    return Image(
      image: AssetImage(path),
      fit: BoxFit.fill,
    );
  }

  static Widget getSvgIcon(String svgPath, double width, double height) {
    return SvgPicture.asset(
      "asset/$svgPath",
      // color: svgColor,
      width: width,
      height: height,
    );
  }

  static Widget getSvgIconWithColor(
      String svgPath, double width, double height, Color? color) {
    return SvgPicture.asset(
      "asset/$svgPath",
      color: color,
      width: width,
      height: height,
    );
  }

  static bool isValidImageSize(double maxSize, Uint8List image) {
    if (image.lengthInBytes > maxSize) {
      return false;
    }
    return true;
  }

  static Widget getTextFormFieldIcon(
      String iconPath, bool originalColor, double? size) {
    return SizedBox(
      width: size ?? 35,
      height: size ?? 35,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.0),
        child: getSvgIconWithColor(
            iconPath, 3, 3, originalColor ? null : OnepieceColors.iconGreen),
      ),
    );
  }
}
