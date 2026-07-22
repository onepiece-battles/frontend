import 'package:flutter/material.dart';
import '../constants/onepiece_colors.dart';
import '../utils/image_helper.dart';
import 'image_cache_manager.dart';
import 'dart:typed_data';

class OriginalImageLoader extends StatefulWidget {
  final String Function()? uriProvider;
  final double maxWidth;
  final double maxHeight;
  final bool? fullImage;

  const OriginalImageLoader({
    Key? key,
    required this.uriProvider,
    required this.maxWidth,
    this.maxHeight = 200,
    this.fullImage,
  }) : super(key: key);

  @override
  State<OriginalImageLoader> createState() => _OriginalImageLoaderState();
}

class _OriginalImageLoaderState extends State<OriginalImageLoader> {
  late Future<Uint8List> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = ImageCacheManager.getImage(
      widget.uriProvider!(),
      fullImage: widget.fullImage,
    );
  }

  @override
  void didUpdateWidget(covariant OriginalImageLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.uriProvider!() != oldWidget.uriProvider!() ||
        widget.fullImage != oldWidget.fullImage) {
      _imageFuture = ImageCacheManager.getImage(
        widget.uriProvider!(),
        fullImage: widget.fullImage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
        future: _imageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            // Sizes itself to the image's own aspect ratio — see
            // ImageHelper.getOriginalImageFrame / _AspectFitImage.
            return ImageHelper.getOriginalImageFrame(
                OnepieceColors.liteFancyBlue, snapshot.data!, widget.maxWidth,
                maxHeight: widget.maxHeight);
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            // Small neutral spinner — deliberately not a colored box, since
            // we don't yet know the image's aspect ratio and don't want to
            // guess a size that the loaded image would then have to jump
            // away from.
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
          } else {
            return const Center(child: Icon(Icons.cancel));
          }
        });
  }
}
