import 'package:flutter/widgets.dart';

/// Keeps interface controls usable on narrow phones when Android's font size is
/// set very large.
class AppTextScale {
  static const double maxInterfaceScale = 1.15;

  static TextScaler forInterface(TextScaler systemTextScaler) {
    return systemTextScaler.clamp(maxScaleFactor: maxInterfaceScale);
  }
}
