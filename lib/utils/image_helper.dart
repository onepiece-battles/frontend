import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:one_piece_battles_flutter/repository/image_dao.dart';
import 'package:openapi/api.dart';

import '../app_router.dart';
import '../components/image_lazy_loader.dart';
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

  static Widget getOriginalImageFrame(Color borderColor,
      Uint8List imageData, double maxWidth) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: FittedBox(
          fit: BoxFit.fill,
          child: Image.memory(imageData),
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
      hoverColor: Colors.transparent,
      icon: SvgPicture.asset(
        "asset/$svgPath",
        color: svgColor,
        width: width,
        height: height,
      ),
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
      width: size ?? 22,
      height: size ?? 22,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: getSvgIconWithColor(
            iconPath, 3, 3, originalColor ? null : OnepieceColors.iconGreen),
      ),
    );
  }

  static Future<String> loadImageByUri(String uri) async {
    return await getIt<ImageDao>()
        .getImage(GetImageRequest(uri: uri))
        .then((value) {
      return value!.image;
    });
  }
}
