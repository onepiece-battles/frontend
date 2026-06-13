import 'package:flutter/widgets.dart';

/// Central responsive breakpoint utility.
///
/// Usage with BuildContext:
///   if (ResponsiveBreakpoints.isMobile(context)) { ... }
///
/// Usage inside LayoutBuilder:
///   final isNarrow = ResponsiveBreakpoints.isMobileFromConstraints(constraints);
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  /// Phones in portrait orientation (most are 320–428 px wide).
  static const double mobileMax = 600;

  /// Phones in landscape + small tablets.
  static const double tabletMax = 900;

  // ── BuildContext helpers ──────────────────────────────────────────────

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileMax;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= mobileMax && w < tabletMax;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletMax;

  // ── BoxConstraints helpers (for use inside LayoutBuilder) ─────────────

  static bool isMobileFromConstraints(BoxConstraints constraints) =>
      constraints.maxWidth < mobileMax;

  static bool isTabletFromConstraints(BoxConstraints constraints) {
    final w = constraints.maxWidth;
    return w >= mobileMax && w < tabletMax;
  }

  static bool isDesktopFromConstraints(BoxConstraints constraints) =>
      constraints.maxWidth >= tabletMax;
}
