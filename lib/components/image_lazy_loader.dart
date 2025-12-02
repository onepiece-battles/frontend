import 'package:flutter/material.dart';
import '../constants/onepiece_colors.dart';
import '../utils/image_helper.dart';
import 'image_cache_manager.dart';
import 'dart:typed_data';
class ImageLazyLoader extends StatefulWidget {
  final String Function()? uriProvider;
  final double width;
  final double borderWidth;
  final double borderRadios;

  const ImageLazyLoader({
    Key? key,
    required this.uriProvider,
    required this.width,
    required this.borderWidth,
    required this.borderRadios,
  }) : super(key: key);

  @override
  State<ImageLazyLoader> createState() => _ImageLazyLoaderState();
}

class _ImageLazyLoaderState extends State<ImageLazyLoader> {
  late Future<String> imageFuture;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
        future: ImageCacheManager.getImage(widget.uriProvider!()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return ImageHelper.getRoundImageFrame(
                widget.width,
                widget.width,
                widget.borderWidth,
                OnepieceColors.liteFancyBlue,
                widget.borderRadios,
                snapshot.data!);
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: SizedBox(
                width: widget.width,
                height: widget.width,
                child: CircularProgressIndicator(
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      OnepieceColors.liteFancyBlue), // Change color to green
                  strokeWidth: widget.borderWidth, //
                ),
              ),
            );
          } else {
            return const Center(child: Icon(Icons.cancel));
          }
        });
  }
}
