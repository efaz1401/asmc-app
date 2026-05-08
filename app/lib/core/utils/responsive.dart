import 'package:flutter/widgets.dart';

/// Simple responsive helper that maps width buckets used by the app shell.
class Responsive {
  const Responsive._();

  /// Phones in portrait.
  static const double mobileBreakpoint = 600;

  /// Tablets / small laptops.
  static const double tabletBreakpoint = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobileBreakpoint && w < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;
}
