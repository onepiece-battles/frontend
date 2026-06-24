import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../constants/onepiece_colors.dart';
import '../utils/image_helper.dart';
import 'image_cache_manager.dart';
import 'dart:typed_data';

class ImageLazyLoader extends StatefulWidget {
  final String Function()? uriProvider;
  final double width;
  final double borderWidth;
  final double borderRadios;
  final bool? fullImage;

  /// When true, defers image loading until the widget scrolls into the
  /// viewport — drastically reduces initial load burst in data tables.
  final bool lazy;

  const ImageLazyLoader({
    Key? key,
    required this.uriProvider,
    required this.width,
    required this.borderWidth,
    required this.borderRadios,
    this.fullImage,
    this.lazy = false,
  }) : super(key: key);

  @override
  State<ImageLazyLoader> createState() => _ImageLazyLoaderState();
}

class _ImageLazyLoaderState extends State<ImageLazyLoader> {
  Future<Uint8List>? _imageFuture;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    if (!widget.lazy) {
      _triggerLoad();
    }
  }

  @override
  void didUpdateWidget(covariant ImageLazyLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newUri = widget.uriProvider?.call();
    final oldUri = oldWidget.uriProvider?.call();
    if ((newUri != oldUri || widget.fullImage != oldWidget.fullImage) &&
        _triggered) {
      _imageFuture = (newUri != null && newUri.isNotEmpty)
          ? ImageCacheManager.getImage(newUri, fullImage: widget.fullImage)
          : null;
    }
  }

  void _triggerLoad() {
    if (_triggered) return;
    _triggered = true;
    final uri = widget.uriProvider?.call();
    if (uri != null && uri.isNotEmpty) {
      _imageFuture = ImageCacheManager.getImage(
        uri,
        fullImage: widget.fullImage,
      );
    }
    if (mounted) setState(() {});
  }

  // ── Loading indicator ────────────────────────────────────────────

  Widget _buildLoading() {
    return Center(
      child: SizedBox(
        width: widget.width,
        height: widget.width,
        child: CircularProgressIndicator(
          valueColor:
              const AlwaysStoppedAnimation<Color>(OnepieceColors.liteFancyBlue),
          strokeWidth: widget.borderWidth,
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Lazy mode: gate behind VisibilityDetector
    if (widget.lazy && !_triggered) {
      // Unique key per instance — avoids collisions when URIs repeat
      final visKey = ValueKey('lazy_${identityHashCode(this)}');
      return VisibilityDetector(
        key: visKey,
        onVisibilityChanged: (info) {
          if (info.visibleFraction > 0) {
            _triggerLoad();
          }
        },
        child: _buildLoading(),
      );
    }

    if (_imageFuture == null) {
      // URI was null / empty — show a subtle empty placeholder, not
      // a spinning loader, so it doesn't look stuck.
      return Container(
        width: widget.width,
        height: widget.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(widget.borderRadios)),
          border: Border.all(
            color: OnepieceColors.liteFancyBlue.withValues(alpha: 0.3),
            width: widget.borderWidth,
          ),
        ),
      );
    }

    return FutureBuilder<Uint8List>(
        future: _imageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return ImageHelper.getRoundImageFrame(
                  widget.width,
                  widget.width,
                  widget.borderWidth,
                  OnepieceColors.liteFancyBlue,
                  widget.borderRadios,
                  snapshot.data!);
            }
            // Load completed with error — faint frame
            return Container(
              width: widget.width,
              height: widget.width,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.all(Radius.circular(widget.borderRadios)),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.3),
                  width: widget.borderWidth,
                ),
              ),
            );
          }
          // Still waiting — spinner (original animation style)
          return _buildLoading();
        });
  }
}
