import 'package:flutter/material.dart';
import '../constants/onepiece_colors.dart';
import '../utils/image_helper.dart';
import 'image_cache_manager.dart';
import 'dart:typed_data';

class OriginalImageLoader extends StatefulWidget {
  final String Function()? uriProvider;
  final double maxWidth;

  const OriginalImageLoader({
    Key? key,
    required this.uriProvider,
    required this.maxWidth,
  }) : super(key: key);

  @override
  State<OriginalImageLoader> createState() => _OriginalImageLoaderState();
}

class _OriginalImageLoaderState extends State<OriginalImageLoader> {
  late Future<Uint8List> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = ImageCacheManager.getImage(widget.uriProvider!());
  }

  @override
  void didUpdateWidget(covariant OriginalImageLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.uriProvider!() != oldWidget.uriProvider!()) {
      _imageFuture = ImageCacheManager.getImage(widget.uriProvider!());
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
                OnepieceColors.liteFancyBlue,
                snapshot.data!,
            widget.maxWidth);
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      OnepieceColors.liteFancyBlue), // Change color to green
                  strokeWidth: 0, //
                ),
              ),
            );
          } else {
            return const Center(child: Icon(Icons.cancel));
          }
        });
  }
}
