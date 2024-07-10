import 'package:flutter/material.dart';
import '../constants/onepiece_colors.dart';
import '../utils/base64_helper.dart';
import '../utils/image_helper.dart';

class ImageLazyLoader extends StatelessWidget {
  final String uri;
  final double width;
  final double borderWidth;
  final double borderRadios;
  const ImageLazyLoader(
      {super.key,
      required this.uri,
      required this.width,
      required this.borderWidth,
      required this.borderRadios});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
        future: ImageHelper.loadImageByUri(uri),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return ImageHelper.getRoundImageFrame(
              width,
              width,
              borderWidth,
              OnepieceColors.liteFancyBlue,
              borderRadios,
              Base64Helper.decode(snapshot.data!),
            );
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: SizedBox(
                width: width,
                height: width,
                child: CircularProgressIndicator(
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      OnepieceColors.liteFancyBlue), // Change color to green
                  strokeWidth: borderWidth, //
                ),
              ),
            );
          } else {
            return const Center(child: Icon(Icons.cancel));
          }
        });
  }
}
