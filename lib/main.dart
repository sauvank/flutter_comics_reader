import 'package:flutter/gestures.dart' show kBackMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/download_provider.dart';
import 'providers/library_provider.dart';
import 'providers/server_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/sync_provider.dart';
import 'screens/home_screen.dart';
import 'models/book_item.dart';
import 'screens/synced_reader_screen.dart';
import 'services/database_service.dart';
import 'services/launch_file_service.dart';
import 'services/reader_settings_service.dart';
import 'services/sync/firebase_bootstrap.dart';
import 'utils/text_scale.dart';
import 'l10n/l10n.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Limit Flutter image cache to prevent OOM crashes on memory-constrained devices (tablets <= 3GB RAM)
  PaintingBinding.instance.imageCache.maximumSize = 25; // max 25 decoded images
  PaintingBinding.instance.imageCache.maximumSizeBytes = 40 << 20; // 40 MB max

  // Initialize persistent services
  await DatabaseService().init();
  await ReaderSettingsService().init();
  await FirebaseBootstrap.initialize();

  // Set system UI overlay style
  // SystemChrome.setSystemUIOverlayStyle(
  //   const SystemUiOverlayStyle(
  //     statusBarColor: Colors.transparent,
  //     statusBarIconBrightness: Brightness.light,
  //     systemNavigationBarColor: Color(0xFF13151F),
  //     systemNavigationBarIconBrightness: Brightness.light,
  //   ),
  // );

  runApp(
      ComicStreamApp(launchFilePath: LaunchFileService.bookPathFromArgs(args)));
}

class ComicStreamApp extends StatefulWidget {
  const ComicStreamApp({super.key, this.launchFilePath});

  /// Book handed over by the OS at launch (Windows default reader).
  final String? launchFilePath;

  @override
  State<ComicStreamApp> createState() => _ComicStreamAppState();
}

class _ComicStreamAppState extends State<ComicStreamApp> {
  String? _shownLanguage = userLocale?.languageCode;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    final path = widget.launchFilePath;
    if (path != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _openLaunchFile(path));
    }
  }

  Future<void> _openLaunchFile(String path) async {
    BookItem? book;
    Object? error;
    try {
      book = await LaunchFileService().resolveBook(path);
    } catch (e) {
      error = e;
    }
    final navigatorContext = _navigatorKey.currentContext;
    if (navigatorContext == null || !navigatorContext.mounted) return;
    if (book == null) {
      ScaffoldMessenger.of(navigatorContext).showSnackBar(
        SnackBar(content: Text(l10n.importFailed(error ?? path))),
      );
      return;
    }
    navigatorContext.read<LibraryProvider>().loadLibrary();
    final openedBook = book;
    _navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => buildSyncedReaderScreen(openedBook)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
        ChangeNotifierProvider(create: (_) => SyncProvider()..start()),
        ChangeNotifierProvider(create: (_) => ReaderSettingsService()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()..loadLibrary()),
        ChangeNotifierProxyProvider<LibraryProvider, DownloadProvider>(
          create: (_) => DownloadProvider(),
          update: (_, libraryProvider, downloadProvider) {
            downloadProvider?.updateLibraryProvider(libraryProvider);
            return downloadProvider ?? DownloadProvider();
          },
        ),
        ChangeNotifierProvider(create: (_) => ServerProvider()..loadServers()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          // Most widgets read the global `l10n`, not Localizations: after a
          // language change, rebuild the whole tree once.
          if (_shownLanguage != themeProvider.languageCode) {
            _shownLanguage = themeProvider.languageCode;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              void rebuild(Element e) {
                e.markNeedsBuild();
                e.visitChildren(rebuild);
              }

              WidgetsBinding.instance.rootElement?.visitChildren(rebuild);
            });
          }
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'ComicStream',
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: userLocale,
            localeListResolutionCallback: (locales, _) =>
                userLocale ?? resolveAppLocale(locales),
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentTheme,
            home: const HomeScreen(),
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: AppTextScale.forInterface(
                    mediaQuery.textScaler,
                  ),
                ),
                child: _DesktopNavigationShortcuts(
                  navigatorKey: _navigatorKey,
                  child: child!,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// PC habits: Esc / Alt+Left / mouse "back" button go to the previous screen.
/// Deeper handlers (dialogs, the reader, text fields) still take precedence.
class _DesktopNavigationShortcuts extends StatelessWidget {
  const _DesktopNavigationShortcuts({
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  void _back() => navigatorKey.currentState?.maybePop();

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        if (event.buttons & kBackMouseButton != 0) _back();
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): _back,
          const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): _back,
        },
        child: child,
      ),
    );
  }
}
