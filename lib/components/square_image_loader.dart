import 'package:flutter/material.dart';
import '../constants/onepiece_colors.dart';
import '../utils/image_helper.dart';
import 'image_cache_manager.dart';
import 'dart:typed_data';

class SquareImageLoader extends StatefulWidget {
  final String Function()? uriProvider;
  final double width;
  final double borderWidth;

  const SquareImageLoader({
    Key? key,
    required this.uriProvider,
    required this.width,
    required this.borderWidth,
  }) : super(key: key);

  @override
  State<SquareImageLoader> createState() => _SquareImageLoaderState();
}

class _SquareImageLoaderState extends State<SquareImageLoader> {
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
            return ImageHelper.getSquareImageFrame(
                widget.width,
                widget.width,
                widget.borderWidth,
                OnepieceColors.liteFancyBlue,
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
