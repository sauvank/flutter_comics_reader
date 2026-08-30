import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/download_provider.dart';
import 'providers/library_provider.dart';
import 'providers/server_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'services/reader_settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent services
  await DatabaseService().init();
  await ReaderSettingsService().init();

  // Set system UI overlay style
  // SystemChrome.setSystemUIOverlayStyle(
  //   const SystemUiOverlayStyle(
  //     statusBarColor: Colors.transparent,
  //     statusBarIconBrightness: Brightness.light,
  //     systemNavigationBarColor: Color(0xFF13151F),
  //     systemNavigationBarIconBrightness: Brightness.light,
  //   ),
  // );

  runApp(const ComicStreamApp());
}

class ComicStreamApp extends StatelessWidget {
  const ComicStreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
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
          return MaterialApp(
            title: 'ComicStream',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentTheme,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
