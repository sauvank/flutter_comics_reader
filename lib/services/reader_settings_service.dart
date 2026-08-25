import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class ReaderSettingsService extends ChangeNotifier {
  static final ReaderSettingsService _instance = ReaderSettingsService._internal();
  factory ReaderSettingsService() => _instance;
  ReaderSettingsService._internal();

  ReadingMode _readingMode = ReadingMode.leftToRight;
  FitMode _fitMode = FitMode.fitWidth;
  ReaderBgColor _bgColor = ReaderBgColor.black;
  bool _keepScreenOn = true;
  bool _showPageNumbers = true;
  bool _volumeButtonsNavigation = false;
  bool _autoConvertPdfToCbz = true;
  PdfRenderQuality _pdfRenderQuality = PdfRenderQuality.autoAdaptive;

  ReadingMode get readingMode => _readingMode;
  FitMode get fitMode => _fitMode;
  ReaderBgColor get bgColor => _bgColor;
  bool get keepScreenOn => _keepScreenOn;
  bool get showPageNumbers => _showPageNumbers;
  bool get volumeButtonsNavigation => _volumeButtonsNavigation;
  bool get autoConvertPdfToCbz => _autoConvertPdfToCbz;
  PdfRenderQuality get pdfRenderQuality => _pdfRenderQuality;

  double get pdfDpiScale {
    switch (_pdfRenderQuality) {
      case PdfRenderQuality.autoAdaptive:
        try {
          final views = ui.PlatformDispatcher.instance.views;
          if (views.isNotEmpty) {
            final physicalSize = views.first.physicalSize;
            final maxDim = math.max(physicalSize.width, physicalSize.height);
            if (maxDim > 0) {
              // Target height = screen physical dimension * 1.35 (35% supersampled zoom headroom)
              final scale = (maxDim * 1.35) / 842.0;
              return scale.clamp(2.0, 3.5);
            }
          }
        } catch (_) {}
        return 2.6; // Fallback
      case PdfRenderQuality.highSuperSampled:
        return 2.6; // ~30% higher than 1920x1200 screen
      case PdfRenderQuality.ultraHd:
        return 3.2;
      case PdfRenderQuality.screenMatch:
        return 1.8;
    }
  }

  Color get actualBackgroundColor {
    switch (_bgColor) {
      case ReaderBgColor.black:
        return Colors.black;
      case ReaderBgColor.darkGray:
        return const Color(0xFF181818);
      case ReaderBgColor.white:
        return Colors.white;
      case ReaderBgColor.sepia:
        return const Color(0xFFF4ECD8);
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString('reader_reading_mode');
    if (modeStr != null) {
      _readingMode = ReadingMode.values.firstWhere(
        (e) => e.name == modeStr,
        orElse: () => ReadingMode.leftToRight,
      );
    }
    final fitStr = prefs.getString('reader_fit_mode');
    if (fitStr != null) {
      _fitMode = FitMode.values.firstWhere(
        (e) => e.name == fitStr,
        orElse: () => FitMode.fitWidth,
      );
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
    _autoConvertPdfToCbz = prefs.getBool('auto_convert_pdf_to_cbz') ?? true;
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
}
