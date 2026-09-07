import 'package:flutter/gestures.dart' show DeviceGestureSettings;
import 'package:flutter/material.dart';

/// Lets the reader scroll at normal size while retaining pinch-to-zoom.
class CbzZoomViewport extends StatelessWidget {
  const CbzZoomViewport({
    super.key,
    required this.controller,
    required this.zoomed,
    required this.onInteractionUpdate,
    required this.onInteractionEnd,
    required this.child,
  });

  final TransformationController controller;
  final bool zoomed;
  final GestureScaleUpdateCallback onInteractionUpdate;
  final GestureScaleEndCallback onInteractionEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      // InteractiveViewer still recognizes one-finger pans when panEnabled is
      // false. A large first move can therefore beat the enclosing PageView's
      // drag recognizer. Disable only that pan threshold at normal size;
      // Flutter's scale-span threshold for pinching is independent of it.
      data: zoomed
          ? media
          : media.copyWith(
              gestureSettings:
                  const DeviceGestureSettings(touchSlop: double.infinity),
            ),
      child: InteractiveViewer(
        transformationController: controller,
        minScale: 1,
        maxScale: 6,
        panEnabled: zoomed,
        onInteractionUpdate: onInteractionUpdate,
        onInteractionEnd: onInteractionEnd,
        // Restore normal drag thresholds for the vertical ListView and any
        // other controls inside the zoomed content.
        child: MediaQuery(data: media, child: child),
      ),
    );
  }
}
