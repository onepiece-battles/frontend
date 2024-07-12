import 'package:flutter/material.dart';
import '../constants/onepiece_colors.dart';
import '../utils/base64_helper.dart';
import '../utils/image_helper.dart';

class ImageLazyLoader extends StatefulWidget {
  final String uri;
  final double width;
  final double borderWidth;
  final double borderRadios;
  const ImageLazyLoader({
    Key? key,
    required this.uri,
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
    imageFuture = ImageHelper.loadImageByUri(widget.uri);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
        future: imageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return ImageHelper.getRoundImageFrame(
              widget.width,
              widget.width,
              widget.borderWidth,
              OnepieceColors.liteFancyBlue,
              widget.borderRadios,
              Base64Helper.decode(snapshot.data!),
            );
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
