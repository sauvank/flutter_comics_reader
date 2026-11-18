import 'package:flutter/widgets.dart';

/// Layout rules for large windows (Windows, Linux, macOS or a wide tablet).
///
/// The phone layout stays the reference; these helpers only switch to a side
/// menu and constrained content when the window is wide enough.
class DesktopLayout {
  /// Window width from which the side menu replaces the bottom bar.
  static const double breakpoint = 900;

  /// Maximum width of the main content next to the side menu.
  static const double contentMaxWidth = 1180;

  /// Horizontal padding of the content on large windows.
  static const double contentPadding = 40;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= breakpoint;
}

/// Centers [child] and caps its width on large windows; no-op on phones.
class DesktopContent extends StatelessWidget {
  const DesktopContent({
    super.key,
    required this.child,
    this.maxWidth = DesktopLayout.contentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (!DesktopLayout.isWide(context)) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
