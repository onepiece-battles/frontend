import 'package:flutter/material.dart';
import '../constants/onepiece_colors.dart';
import '../utils/image_helper.dart';
import 'image_cache_manager.dart';
import 'dart:typed_data';

class SquareImageLoader extends StatefulWidget {
  final String Function()? uriProvider;
  final double width;
  final double borderWidth;
  final double borderRadius;
  final Color borderColor;
  final IconData fallbackIcon;
  final bool? fullImage;

  const SquareImageLoader({
    Key? key,
    required this.uriProvider,
    required this.width,
    required this.borderWidth,
    this.borderRadius = 2,
    this.borderColor = OnepieceColors.liteFancyBlue,
    this.fallbackIcon = Icons.broken_image_outlined,
    this.fullImage,
  }) : super(key: key);

  @override
  State<SquareImageLoader> createState() => _SquareImageLoaderState();
}

class _SquareImageLoaderState extends State<SquareImageLoader> {
  Future<Uint8List>? _imageFuture;

  Future<Uint8List>? _loadImage() {
    final uri = widget.uriProvider?.call();
    if (uri == null || uri.isEmpty) return null;
    return ImageCacheManager.getImage(uri, fullImage: widget.fullImage);
  }

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImage();
  }

  @override
  void didUpdateWidget(covariant SquareImageLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.uriProvider?.call() != oldWidget.uriProvider?.call() ||
        widget.fullImage != oldWidget.fullImage) {
      _imageFuture = _loadImage();
    }
  }

  Widget _placeholder() => Container(
        width: widget.width,
        height: widget.width,
        decoration: BoxDecoration(
          color: OnepieceColors.surface,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border:
              Border.all(color: widget.borderColor, width: widget.borderWidth),
        ),
        child: Icon(widget.fallbackIcon,
            size: widget.width * .5, color: OnepieceColors.secondaryLabel),
      );

  @override
  Widget build(BuildContext context) {
    if (_imageFuture == null) return _placeholder();
    return FutureBuilder<Uint8List>(
        future: _imageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return ImageHelper.getSquareImageFrame(widget.width, widget.width,
                widget.borderWidth, widget.borderColor, snapshot.data!,
                borderRadius: widget.borderRadius);
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: SizedBox(
                    width: widget.width,
                    height: widget.width,
                    child: CircularProgressIndicator(
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          OnepieceColors
                              .liteFancyBlue), // Change color to green
                      strokeWidth: widget.borderWidth, //
                    )),
              ),
            );
          } else {
            return _placeholder();
          }
        });
  }
}
