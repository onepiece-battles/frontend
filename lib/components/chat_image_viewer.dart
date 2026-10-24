import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../utils/base64_helper.dart';
import '../utils/image_helper.dart';
import 'image_cache_manager.dart';

/// Opens a full-screen, zoomable viewer for a chat image — the WeChat-style
/// tap-to-enlarge interaction:
///
///  • fades up over a black backdrop (and fades back out on close);
///  • pinch or double-tap to zoom, drag to pan (InteractiveViewer);
///  • double-tap again (or when zoomed) snaps back to fit;
///  • tap anywhere at fit scale, or the × button, to dismiss;
///  • the system back gesture/button also dismisses.
///
/// [imageUri] is whatever the message carries: a `data:` URI for an image
/// that hasn't been uploaded yet (optimistic send), otherwise a server uri
/// resolved — at full resolution — through [ImageCacheManager].
Future<void> showChatImageViewer(BuildContext context, String imageUri) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) => _ChatImageViewer(imageUri: imageUri),
      transitionsBuilder: (_, animation, __, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

class _ChatImageViewer extends StatefulWidget {
  const _ChatImageViewer({required this.imageUri});

  final String imageUri;

  @override
  State<_ChatImageViewer> createState() => _ChatImageViewerState();
}

class _ChatImageViewerState extends State<_ChatImageViewer>
    with SingleTickerProviderStateMixin {
  late final Future<Uint8List> _bytesFuture = _loadBytes();

  final TransformationController _transform = TransformationController();

  /// Drives smooth (de)zoom on double-tap.
  late final AnimationController _zoomController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  Animation<Matrix4>? _zoomAnimation;

  // Captured on double-tap-down so the zoom can center on the tapped point.
  TapDownDetails? _doubleTapDetails;

  static const double _zoomScale = 2.5;

  Future<Uint8List> _loadBytes() {
    final uri = widget.imageUri;
    if (uri.startsWith('data:')) {
      // Optimistic, not-yet-uploaded image — the bytes are already local.
      return Future<Uint8List>.value(Base64Helper.decode(uri.split(',').last));
    }
    // Server image: pull the full-resolution variant (the inline thumbnail
    // only fetched the default size).
    return ImageCacheManager.getImage(uri, fullImage: true);
  }

  bool get _isZoomed => _transform.value.getMaxScaleOnAxis() > 1.05;

  void _animateTransformTo(Matrix4 target) {
    _zoomAnimation?.removeListener(_onZoomTick);
    _zoomAnimation = Matrix4Tween(begin: _transform.value, end: target).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.easeOut),
    )..addListener(_onZoomTick);
    _zoomController.forward(from: 0);
  }

  void _onZoomTick() {
    final value = _zoomAnimation?.value;
    if (value != null) _transform.value = value;
  }

  void _handleDoubleTap() {
    if (_isZoomed) {
      _animateTransformTo(Matrix4.identity());
      return;
    }
    final position = _doubleTapDetails?.localPosition;
    if (position == null) return;
    // Scale by _zoomScale about the tapped point: x' = s·x + tx, y' = s·y + ty,
    // with (tx, ty) chosen so the tapped point stays put. Built column-major
    // directly to avoid the deprecated Matrix4.translate/scale helpers.
    const double s = _zoomScale;
    final double tx = -position.dx * (s - 1);
    final double ty = -position.dy * (s - 1);
    _animateTransformTo(Matrix4(
      s, 0, 0, 0, //
      0, s, 0, 0, //
      0, 0, 1, 0, //
      tx, ty, 0, 1, //
    ));
  }

  void _handleTap() {
    // A tap while zoomed snaps back to fit (so a stray tap doesn't close on a
    // zoomed-in photo); a tap at fit scale dismisses the viewer.
    if (_isZoomed) {
      _animateTransformTo(Matrix4.identity());
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  void dispose() {
    _zoomAnimation?.removeListener(_onZoomTick);
    _zoomController.dispose();
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _handleTap,
              onDoubleTapDown: (details) => _doubleTapDetails = details,
              onDoubleTap: _handleDoubleTap,
              child: FutureBuilder<Uint8List>(
                future: _bytesFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: Colors.white54, size: 48),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    );
                  }
                  return InteractiveViewer(
                    transformationController: _transform,
                    minScale: 1,
                    maxScale: 4,
                    child: Center(
                      child: ImageHelper.rasterImage(
                        snapshot.data!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 48),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Close affordance — a frosted disc so it reads on any photo.
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Material(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const SizedBox(
                      width: 38,
                      height: 38,
                      child: Icon(Icons.close, color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
