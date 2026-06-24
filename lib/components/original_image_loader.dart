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
            return ImageHelper.getOriginalImageFrame(
                OnepieceColors.liteFancyBlue, snapshot.data!, widget.maxWidth,
                maxHeight: widget.maxHeight);
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            // Stable-height placeholder — prevents layout jumps
            return Container(
              width: widget.maxWidth,
              height: widget.maxHeight.clamp(80.0, 200.0),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.image, color: Colors.grey, size: 32),
              ),
            );
          } else {
            return const Center(child: Icon(Icons.cancel));
          }
        });
  }
}
