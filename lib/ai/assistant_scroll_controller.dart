import 'package:flutter/widgets.dart';

import 'assistant_session.dart';

/// Position the actual end during layout, rather than jumping once to a lazy
/// list's estimated extent. Keep a reader's top-relative offset across routes.
class AssistantScrollController extends ScrollController {
  AssistantScrollController(this.session)
      : super(
            initialScrollOffset: session.scrollOffset ?? 0,
            keepScrollOffset: false) {
    addListener(_remember);
  }

  final AssistantSession session;

  void _remember() {
    if (hasClients && session.messages.isNotEmpty) {
      session.scrollOffset = offset;
    }
  }

  @override
  void detach(ScrollPosition position) {
    if (position.hasPixels && session.messages.isNotEmpty) {
      session.scrollOffset = position.pixels;
    }
    super.detach(position);
  }

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics,
          ScrollContext context, ScrollPosition? oldPosition) =>
      _AssistantScrollPosition(
        session: session,
        physics: physics,
        context: context,
        initialPixels: session.scrollOffset ?? 0,
        keepScrollOffset: false,
        oldPosition: oldPosition,
      );
}

class _AssistantScrollPosition extends ScrollPositionWithSingleContext {
  _AssistantScrollPosition(
      {required this.session,
      required super.physics,
      required super.context,
      super.initialPixels,
      super.keepScrollOffset,
      super.oldPosition});

  final AssistantSession session;

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    if (session.followLatest &&
        hasPixels &&
        (pixels - maxScrollExtent).abs() > .5) {
      correctPixels(maxScrollExtent);
      session.scrollOffset = maxScrollExtent;
      super.applyContentDimensions(minScrollExtent, maxScrollExtent);
      return false;
    }
    return super.applyContentDimensions(minScrollExtent, maxScrollExtent);
  }
}
