import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:one_piece_battles_flutter/repository/image_dao.dart';
import 'package:openapi/api.dart';

import '../app_router.dart';
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
            child: _buildRasterImage(imageData),
          ),
        ),
      ),
    );
  }

  static Widget getOriginalImageFrame(
      Color borderColor, Uint8List imageData, double maxWidth,
      {double maxHeight = 200}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: _buildRasterImage(
          imageData,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
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
            child: _buildRasterImage(imageData),
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
        colorFilter: ColorFilter.mode(svgColor, BlendMode.srcIn),
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
      colorFilter:
          color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
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

  static Future<String> loadImageByUri(String uri, {bool? fullImage}) async {
    return await getIt<ImageDao>()
        .getImage(GetImageRequest(uri: uri, fullImage: fullImage))
        .then((value) {
      return value!.image;
    });
  }

  static Widget _buildRasterImage(
    Uint8List imageData, {
    BoxFit? fit,
    ImageErrorWidgetBuilder? errorBuilder,
  }) {
    if (!kIsWeb) {
      return Image.memory(
        imageData,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }

    final mimeType = _detectImageMimeType(imageData);
    final dataUri = 'data:$mimeType;base64,${base64Encode(imageData)}';
    return Image.network(
      dataUri,
      fit: fit,
      errorBuilder: errorBuilder,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
    );
  }

  static String _detectImageMimeType(Uint8List data) {
    if (data.length >= 8 &&
        data[0] == 0x89 &&
        data[1] == 0x50 &&
        data[2] == 0x4e &&
        data[3] == 0x47) {
      return 'image/png';
    }
    if (data.length >= 3 &&
        data[0] == 0xff &&
        data[1] == 0xd8 &&
        data[2] == 0xff) {
      return 'image/jpeg';
    }
    if (data.length >= 4 &&
        data[0] == 0x47 &&
        data[1] == 0x49 &&
        data[2] == 0x46 &&
        data[3] == 0x38) {
      return 'image/gif';
    }
    if (data.length >= 12 &&
        data[0] == 0x52 &&
        data[1] == 0x49 &&
        data[2] == 0x46 &&
        data[3] == 0x46 &&
        data[8] == 0x57 &&
        data[9] == 0x45 &&
        data[10] == 0x42 &&
        data[11] == 0x50) {
      return 'image/webp';
    }
    return 'image/png';
  }
}
