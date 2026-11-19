import 'package:flutter/material.dart';

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

/// Bottom sheet on phones, centered dialog on large windows.
///
/// Accepts the same arguments as [showModalBottomSheet] used in the app, so
/// call sites switch by name only.
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  ShapeBorder? shape,
  bool isScrollControlled = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool? showDragHandle,
}) {
  if (!DesktopLayout.isWide(context)) {
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      backgroundColor: backgroundColor,
      shape: shape,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
    );
  }
  final size = MediaQuery.sizeOf(context);
  return showDialog<T>(
    context: context,
    barrierDismissible: isDismissible,
    builder: (dialogContext) => Dialog(
      // Same default as a bottom sheet: an opaque surface, otherwise sheets
      // that rely on it show the page through (e.g. backup chooser).
      backgroundColor: backgroundColor ??
          Theme.of(context).bottomSheetTheme.modalBackgroundColor ??
          Theme.of(context).bottomSheetTheme.backgroundColor ??
          Theme.of(context).colorScheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: size.height * 0.85,
        ),
        child: MediaQuery.removePadding(
          context: dialogContext,
          removeBottom: true,
          child: builder(dialogContext),
        ),
      ),
    ),
  );
}
