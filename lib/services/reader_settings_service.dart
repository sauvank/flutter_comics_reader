import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum ReadingMode {
  leftToRight, // BD / Comics / Standard
  rightToLeft, // Manga (Japonais)
  vertical, // Webtoon (Défilement continu)
}

enum FitMode {
  fitWidth,
  fitHeight,
  fitScreen,
}

enum ReaderBgColor {
  black,
  darkGray,
  white,
  sepia,
}

enum PdfRenderQuality {
  autoAdaptive, // Automatique (Détecte l'écran physique + 35% de zoom net, Recommandé)
  highSuperSampled, // Élevée fixe (2600px)
  ultraHd, // Ultra HD (3500px)
  screenMatch, // Standard 1:1 (Rapide)
}

enum EpubTheme {
  dark,
  oled,
  sepia,
  mint,
  light,
}

enum EpubFontFamily {
  serif,
  sansSerif,
  monospace,
}

enum EpubLineHeight {
  compact,
  normal,
  relaxed,
}

enum EpubMargin {
  narrow,
  normal,
  wide,
}

enum EpubTextAlign {
  justify,
  left,
}

class ReaderSettingsService extends ChangeNotifier {
  static final ReaderSettingsService _instance = ReaderSettingsService._internal();
  factory ReaderSettingsService() => _instance;
  ReaderSettingsService._internal();

  ReadingMode _readingMode = (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS))
      ? ReadingMode.leftToRight
      : ReadingMode.vertical;
  FitMode _fitMode = (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS))
      ? FitMode.fitScreen
      : FitMode.fitWidth;
  ReaderBgColor _bgColor = ReaderBgColor.black;
  bool _keepScreenOn = true;
  bool _showPageNumbers = true;
  bool _volumeButtonsNavigation = false;
  bool _autoConvertPdfToCbz = false; // Native PDF reading by default (instant and smooth)
  PdfRenderQuality _pdfRenderQuality = PdfRenderQuality.autoAdaptive;

  // EPUB custom settings
  EpubTheme _epubTheme = EpubTheme.dark;
  double _epubFontSize = 17.0;
  EpubFontFamily _epubFontFamily = EpubFontFamily.serif;
  EpubLineHeight _epubLineHeight = EpubLineHeight.normal;
  EpubMargin _epubMargin = EpubMargin.normal;
  EpubTextAlign _epubTextAlign = EpubTextAlign.justify;

  ReadingMode get readingMode => _readingMode;
  FitMode get fitMode => _fitMode;
  ReaderBgColor get bgColor => _bgColor;
  bool get keepScreenOn => _keepScreenOn;
  bool get showPageNumbers => _showPageNumbers;
  bool get volumeButtonsNavigation => _volumeButtonsNavigation;
  bool get autoConvertPdfToCbz => _autoConvertPdfToCbz;
  PdfRenderQuality get pdfRenderQuality => _pdfRenderQuality;

  EpubTheme get epubTheme => _epubTheme;
  double get epubFontSize => _epubFontSize;
  EpubFontFamily get epubFontFamily => _epubFontFamily;
  EpubLineHeight get epubLineHeight => _epubLineHeight;
  EpubMargin get epubMargin => _epubMargin;
  EpubTextAlign get epubTextAlign => _epubTextAlign;

  Color get epubBackgroundColor {
    switch (_epubTheme) {
      case EpubTheme.oled:
        return Colors.black;
      case EpubTheme.dark:
        return const Color(0xFF1C1C1E);
      case EpubTheme.sepia:
        return const Color(0xFFFBF0D9);
      case EpubTheme.mint:
        return const Color(0xFF182420);
      case EpubTheme.light:
        return const Color(0xFFF8F9FA);
    }
  }

  Color get epubTextColor {
    switch (_epubTheme) {
      case EpubTheme.oled:
      case EpubTheme.dark:
        return const Color(0xFFE2E2E6);
      case EpubTheme.sepia:
        return const Color(0xFF3C2F1F);
      case EpubTheme.mint:
        return const Color(0xFFD2E8DD);
      case EpubTheme.light:
        return const Color(0xFF1C1B1F);
    }
  }

  double get epubLineHeightValue {
    switch (_epubLineHeight) {
      case EpubLineHeight.compact:
        return 1.35;
      case EpubLineHeight.normal:
        return 1.65;
      case EpubLineHeight.relaxed:
        return 1.95;
    }
  }

  String get epubFontFamilyName {
    switch (_epubFontFamily) {
      case EpubFontFamily.serif:
        return 'serif';
      case EpubFontFamily.sansSerif:
        return 'sans-serif';
      case EpubFontFamily.monospace:
        return 'monospace';
    }
  }

  double get epubHorizontalPadding {
    switch (_epubMargin) {
      case EpubMargin.narrow:
        return 16.0;
      case EpubMargin.normal:
        return 28.0;
      case EpubMargin.wide:
        return 48.0;
    }
  }

  double get pdfDpiScale {
    switch (_pdfRenderQuality) {
      case PdfRenderQuality.autoAdaptive:
        try {
          final views = ui.PlatformDispatcher.instance.views;
          if (views.isNotEmpty) {
            final pixelRatio = views.first.devicePixelRatio;
            return math.max(1.5, pixelRatio * 1.35);
          }
        } catch (_) {}
        return 2.5;
      case PdfRenderQuality.highSuperSampled:
        return 2.6;
      case PdfRenderQuality.ultraHd:
        return 3.5;
      case PdfRenderQuality.screenMatch:
        return 1.0;
    }
  }

  Color get actualBackgroundColor {
    switch (_bgColor) {
      case ReaderBgColor.black:
        return Colors.black;
      case ReaderBgColor.darkGray:
        return const Color(0xFF1E1E1E);
      case ReaderBgColor.white:
        return Colors.white;
      case ReaderBgColor.sepia:
        return const Color(0xFFF4ECD8);
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    final defaultReadingMode = isDesktop ? ReadingMode.leftToRight : ReadingMode.vertical;
    final defaultFitMode = isDesktop ? FitMode.fitScreen : FitMode.fitWidth;

    final modeStr = prefs.getString('reader_reading_mode');
    if (modeStr != null) {
      _readingMode = ReadingMode.values.firstWhere(
        (e) => e.name == modeStr,
        orElse: () => defaultReadingMode,
      );
    } else {
      _readingMode = defaultReadingMode;
    }

    final fitStr = prefs.getString('reader_fit_mode');
    if (fitStr != null) {
      _fitMode = FitMode.values.firstWhere(
        (e) => e.name == fitStr,
        orElse: () => defaultFitMode,
      );
    } else {
      _fitMode = defaultFitMode;
    }
    final bgStr = prefs.getString('reader_bg_color');
    if (bgStr != null) {
      _bgColor = ReaderBgColor.values.firstWhere(
        (e) => e.name == bgStr,
        orElse: () => ReaderBgColor.black,
      );
    }
    final qualityStr = prefs.getString('pdf_render_quality');
    if (qualityStr != null) {
      _pdfRenderQuality = PdfRenderQuality.values.firstWhere(
        (e) => e.name == qualityStr,
        orElse: () => PdfRenderQuality.autoAdaptive,
      );
    }
    _keepScreenOn = prefs.getBool('reader_keep_screen_on') ?? true;
    _showPageNumbers = prefs.getBool('reader_show_page_numbers') ?? true;
    _volumeButtonsNavigation = prefs.getBool('reader_volume_nav') ?? false;
    _autoConvertPdfToCbz = prefs.getBool('auto_convert_pdf_to_cbz') ?? false;

    // Load EPUB settings
    final epubThemeStr = prefs.getString('epub_theme');
    if (epubThemeStr != null) {
      _epubTheme = EpubTheme.values.firstWhere((e) => e.name == epubThemeStr, orElse: () => EpubTheme.dark);
    }
    _epubFontSize = prefs.getDouble('epub_font_size') ?? 17.0;
    final epubFontStr = prefs.getString('epub_font_family');
    if (epubFontStr != null) {
      _epubFontFamily = EpubFontFamily.values.firstWhere((e) => e.name == epubFontStr, orElse: () => EpubFontFamily.serif);
    }
    final epubLineHeightStr = prefs.getString('epub_line_height');
    if (epubLineHeightStr != null) {
      _epubLineHeight = EpubLineHeight.values.firstWhere((e) => e.name == epubLineHeightStr, orElse: () => EpubLineHeight.normal);
    }
    final epubMarginStr = prefs.getString('epub_margin');
    if (epubMarginStr != null) {
      _epubMargin = EpubMargin.values.firstWhere((e) => e.name == epubMarginStr, orElse: () => EpubMargin.normal);
    }
    final epubAlignStr = prefs.getString('epub_text_align');
    if (epubAlignStr != null) {
      _epubTextAlign = EpubTextAlign.values.firstWhere((e) => e.name == epubAlignStr, orElse: () => EpubTextAlign.justify);
    }

    WakelockPlus.toggle(enable: _keepScreenOn);
    notifyListeners();
  }

  Future<void> setReadingMode(ReadingMode mode) async {
    _readingMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reader_reading_mode', mode.name);
  }

  Future<void> setFitMode(FitMode mode) async {
    _fitMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reader_fit_mode', mode.name);
  }

  Future<void> setBgColor(ReaderBgColor color) async {
    _bgColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reader_bg_color', color.name);
  }

  Future<void> setKeepScreenOn(bool value) async {
    _keepScreenOn = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reader_keep_screen_on', value);
    WakelockPlus.toggle(enable: value);
  }

  Future<void> setVolumeButtonsNavigation(bool value) async {
    _volumeButtonsNavigation = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('volumeButtonsNavigation', value);
  }

  Future<void> setShowPageNumbers(bool value) async {
    _showPageNumbers = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reader_show_page_numbers', value);
  }

  Future<void> setAutoConvertPdfToCbz(bool value) async {
    _autoConvertPdfToCbz = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_convert_pdf_to_cbz', value);
  }

  Future<void> setPdfRenderQuality(PdfRenderQuality quality) async {
    _pdfRenderQuality = quality;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pdf_render_quality', quality.name);
  }

  Future<void> setEpubTheme(EpubTheme theme) async {
    _epubTheme = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('epub_theme', theme.name);
  }

  Future<void> setEpubFontSize(double size) async {
    _epubFontSize = size;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('epub_font_size', size);
  }

  Future<void> setEpubFontFamily(EpubFontFamily family) async {
    _epubFontFamily = family;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('epub_font_family', family.name);
  }

  Future<void> setEpubLineHeight(EpubLineHeight lineHeight) async {
    _epubLineHeight = lineHeight;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('epub_line_height', lineHeight.name);
  }

  Future<void> setEpubMargin(EpubMargin margin) async {
    _epubMargin = margin;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('epub_margin', margin.name);
  }

  Future<void> setEpubTextAlign(EpubTextAlign align) async {
    _epubTextAlign = align;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('epub_text_align', align.name);
  }
}
