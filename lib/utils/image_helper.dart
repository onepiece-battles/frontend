import 'dart:async';
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
    // Sized to the image's own aspect ratio (capped within maxWidth/
    // maxHeight) rather than a fixed box — a fixed box either letterboxes
    // (showing the message bubble's background color in the gaps) or
    // stretches the photo. See _AspectFitImage for how the aspect ratio is
    // learned without introducing a second visible resize.
    return _AspectFitImage(
      imageData: imageData,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
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

  /// Public, web-safe raster image for already-decoded bytes, used by the
  /// full-screen chat image viewer so it shares the exact same decode path as
  /// inline images (Image.memory off web, data-URI Image.network on web —
  /// Image.memory is unreliable on web for some encodings).
  static Widget rasterImage(
    Uint8List imageData, {
    BoxFit? fit,
    ImageErrorWidgetBuilder? errorBuilder,
  }) =>
      _buildRasterImage(imageData, fit: fit, errorBuilder: errorBuilder);

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
      // HTML platform-view images sit outside Flutter's scene, so the global
      // search BackdropFilter cannot blur them. Data URIs can be decoded into
      // the canvas without an HTML element.
      webHtmlElementStrategy: WebHtmlElementStrategy.never,
    );
  }

  static ImageProvider _resolveImageProvider(Uint8List imageData) {
    if (!kIsWeb) {
      return MemoryImage(imageData);
    }
    final mimeType = _detectImageMimeType(imageData);
    final dataUri = 'data:$mimeType;base64,${base64Encode(imageData)}';
    return NetworkImage(dataUri);
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

/// Renders [imageData] sized to its own aspect ratio, capped within
/// [maxWidth]/[maxHeight], instead of a fixed box. A fixed box either
/// letterboxes (revealing the surrounding widget's background color in the
/// gaps) or stretches the photo — sizing to the real aspect ratio avoids
/// both. The aspect ratio is learned by resolving the same [ImageProvider]
/// used for display (so there's no second, inconsistent decode path for
/// web vs. non-web); until that resolves, a small neutral spinner is shown
/// instead of a placeholder box, since we don't know the right size yet.
class _AspectFitImage extends StatefulWidget {
  const _AspectFitImage({
    required this.imageData,
    required this.maxWidth,
    required this.maxHeight,
  });

  final Uint8List imageData;
  final double maxWidth;
  final double maxHeight;

  @override
  State<_AspectFitImage> createState() => _AspectFitImageState();
}

class _AspectFitImageState extends State<_AspectFitImage> {
  late Future<Size> _sizeFuture;

  @override
  void initState() {
    super.initState();
    _sizeFuture = _decodeSize(widget.imageData);
  }

  @override
  void didUpdateWidget(covariant _AspectFitImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.imageData, oldWidget.imageData)) {
      _sizeFuture = _decodeSize(widget.imageData);
    }
  }

  static Future<Size> _decodeSize(Uint8List imageData) {
    final completer = Completer<Size>();
    final provider = ImageHelper._resolveImageProvider(imageData);
    final stream = provider.resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener((ImageInfo info, bool _) {
      if (!completer.isCompleted) {
        completer.complete(
            Size(info.image.width.toDouble(), info.image.height.toDouble()));
      }
      stream.removeListener(listener);
    }, onError: (Object error, StackTrace? stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace ?? StackTrace.current);
      }
      stream.removeListener(listener);
    });
    stream.addListener(listener);
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: widget.maxWidth,
        maxHeight: widget.maxHeight,
      ),
      child: FutureBuilder<Size>(
        future: _sizeFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Icon(Icons.broken_image));
          }
          if (!snapshot.hasData) {
            return const SizedBox(
              width: 60,
              height: 60,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: snapshot.data!.width / snapshot.data!.height,
              child: ImageHelper._buildRasterImage(
                widget.imageData,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
              ),
            ),
          );
        },
      ),
    );
  }
}
