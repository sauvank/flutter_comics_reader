import 'dart:async';

import 'package:comic_reader_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';

/// Tests assert on the French strings, the app's reference language.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  localeOverride = const Locale('fr');
  await testMain();
}
