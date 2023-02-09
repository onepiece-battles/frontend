import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

class MouseRegionBuilder {
  static MouseRegion buildMouseRegion(
    Widget child,
    Function(PointerEnterEvent) onEnter,
    Function(PointerExitEvent) onExit,
    Function(PointerHoverEvent) onHover,
  ) {
    return MouseRegion(
      onEnter: onEnter,
      onExit: onExit,
      onHover: onHover,
      child: child,
    );
  }
}
