import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Translations for the phone's current language.
///
/// Resolved from the platform locales rather than a [BuildContext] so that
/// services, providers and dialogs share the same strings. English is used
/// when the phone language is not supported.
AppLocalizations get l10n => lookupAppLocalizations(appLocale);

Locale get appLocale =>
    localeOverride ?? resolveAppLocale(PlatformDispatcher.instance.locales);

/// Forces a language, e.g. French in tests that assert on French text.
@visibleForTesting
Locale? localeOverride;

Locale resolveAppLocale(List<Locale>? preferred) {
  for (final locale in preferred ?? const <Locale>[]) {
    for (final supported in AppLocalizations.supportedLocales) {
      if (supported.languageCode == locale.languageCode) return supported;
    }
  }
  return const Locale('en');
}
