import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../constants/onepiece_colors.dart';
import '../../../l10n/app_localizations.dart';

/// A bounded, pannable viewport for a potentially deep group hierarchy.
/// Scaling only affects the hierarchy; the page header and navigation stay put.
class GroupHierarchyCanvas extends StatefulWidget {
  const GroupHierarchyCanvas(
      {super.key, required this.child, required this.mobile});

  final Widget child;
  final bool mobile;

  @override
  State<GroupHierarchyCanvas> createState() => _GroupHierarchyCanvasState();
}

class _GroupHierarchyCanvasState extends State<GroupHierarchyCanvas>
    with SingleTickerProviderStateMixin {
  final TransformationController _transform = TransformationController();
  late final AnimationController _animation;
  Animation<Matrix4>? _matrixAnimation;
  bool _initialized = false;
  double _fitScale = 1;
  double _viewportWidth = 0;
  double _scale = 1;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(() {
        final value = _matrixAnimation?.value;
        if (value != null) _transform.value = value;
      });
  }

  @override
  void dispose() {
    _animation.dispose();
    _transform.dispose();
    super.dispose();
  }

  Matrix4 _matrix(double scale, double x, double y) => Matrix4.identity()
    ..setEntry(0, 0, scale)
    ..setEntry(1, 1, scale)
    ..setTranslationRaw(x, y, 0);

  void _animateTo(Matrix4 target) {
    _animation.stop();
    _matrixAnimation = Matrix4Tween(
      begin: _transform.value.clone(),
      end: target,
    ).animate(CurvedAnimation(parent: _animation, curve: Curves.easeOutCubic));
    _animation.forward(from: 0);
    setState(() => _scale = target.getMaxScaleOnAxis());
  }

  void _zoom(double factor) {
    final current = _transform.value;
    final currentScale = current.getMaxScaleOnAxis();
    final targetScale = (currentScale * factor).clamp(0.45, 2.2);
    final center = _viewportWidth / 2;
    final x = current.entry(0, 3);
    final y = current.entry(1, 3);
    final contentX = (center - x) / currentScale;
    final contentY = (210 - y) / currentScale;
    _animateTo(_matrix(targetScale, center - contentX * targetScale,
        210 - contentY * targetScale));
  }

  void _reset() => _animateTo(_matrix(_fitScale, 16, 16));

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final contentWidth = math.max(widget.mobile ? 480.0 : 720.0, width - 32);
      final fit = math.min(1.0, (width - 32) / contentWidth).clamp(0.45, 1.0);
      _viewportWidth = width;
      _fitScale = fit;
      if (!_initialized) {
        _initialized = true;
        _scale = fit;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _transform.value = _matrix(fit, 16, 16);
        });
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: widget.mobile ? 440 : 560,
          decoration: BoxDecoration(
            color: OnepieceColors.surface,
            border: Border.all(color: OnepieceColors.separator),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(children: [
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: _transform,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(240),
                minScale: 0.45,
                maxScale: 2.2,
                trackpadScrollCausesScale: true,
                scaleFactor: 160,
                onInteractionEnd: (_) => setState(() {
                  _scale = _transform.value.getMaxScaleOnAxis();
                }),
                child: SizedBox(
                  width: contentWidth,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 20, 80),
                    child: widget.child,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: OnepieceColors.separator),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                    )
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    tooltip: loc.groupZoomOut,
                    onPressed: () => _zoom(0.8),
                    icon: const Icon(Icons.remove, size: 18),
                  ),
                  Text('${(_scale * 100).round()}%',
                      style: const TextStyle(
                          fontSize: 12, color: OnepieceColors.secondaryLabel)),
                  IconButton(
                    tooltip: loc.groupZoomIn,
                    onPressed: () => _zoom(1.25),
                    icon: const Icon(Icons.add, size: 18),
                  ),
                  const SizedBox(height: 22, child: VerticalDivider(width: 1)),
                  IconButton(
                    tooltip: loc.groupFitView,
                    onPressed: _reset,
                    icon: const Icon(Icons.center_focus_strong, size: 18),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      );
    });
  }
}
