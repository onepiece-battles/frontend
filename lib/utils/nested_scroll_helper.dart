import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class NestedScrollPassthrough extends StatelessWidget {
  final Axis childScrollDirection;
  final ScrollController? parentController;
  final Widget child;

  const NestedScrollPassthrough({
    super.key,
    required this.childScrollDirection,
    required this.parentController,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (parentController == null) return child;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: childScrollDirection == Axis.horizontal
          ? (details) => _moveParent(-details.delta.dy)
          : null,
      onHorizontalDragUpdate: childScrollDirection == Axis.vertical
          ? (details) => _moveParent(-details.delta.dx)
          : null,
      child: child,
    );
  }

  void _moveParent(double delta) {
    final controller = parentController;
    if (controller == null || !controller.hasClients) return;

    final position = controller.position;
    final nextOffset = math.max(
      position.minScrollExtent,
      math.min(position.maxScrollExtent, position.pixels + delta),
    );
    if (nextOffset == position.pixels) return;
    controller.jumpTo(nextOffset);
  }
}

class NestedHorizontalScrollView extends StatelessWidget {
  final ScrollController? controller;
  final ScrollController? verticalParentController;
  final Widget child;
  final ScrollPhysics? physics;

  const NestedHorizontalScrollView({
    super.key,
    this.controller,
    this.verticalParentController,
    this.physics,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return NestedScrollPassthrough(
      childScrollDirection: Axis.horizontal,
      parentController: verticalParentController,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        dragStartBehavior: DragStartBehavior.down,
        physics: physics ?? const ClampingScrollPhysics(),
        child: child,
      ),
    );
  }
}
