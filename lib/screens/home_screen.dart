import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/download_provider.dart';
import '../providers/server_provider.dart';
import '../services/update_service.dart';
import 'downloads_screen.dart';
import 'library_screen.dart';
import 'server_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final info = await UpdateService().checkUpdate();
      if (info != null && info.hasUpdate && mounted) {
        UpdateService().promptUpdateDialog(context, info);
      }
    });
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final downloadProvider = context.watch<DownloadProvider>();
    final activeDownloadsCount = downloadProvider.activeTasks.length;

    final List<Widget> screens = [
      LibraryScreen(onNavigateTab: _onTabSelected),
      ServerScreen(onNavigateTab: _onTabSelected),
      const DownloadsScreen(),
      const SettingsScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final serverProvider = context.read<ServerProvider>();

        // 1. If we are in the Server tab and browsing a server
        if (_currentIndex == 1 && serverProvider.isBrowsing) {
          if (serverProvider.canNavigateUp) {
            serverProvider.navigateUp();
          } else {
            serverProvider.closeServerBrowser();
          }
          return;
        }

        // 2. If we are on any tab other than Library, return to Library tab first
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }

        // 3. If we are on Library tab, require a second back press within 2s to exit
        final now = DateTime.now();
        if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
              content: Text('Appuyez à nouveau pour quitter ComicStream'),
            ),
          );
          return;
        }

        // 4. Confirmed double back press: safely exit app
        SystemNavigator.pop();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabSelected,
          destinations: [
          const NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Bibliothèque',
          ),
          const NavigationDestination(
            icon: Icon(Icons.dns_outlined),
            selectedIcon: Icon(Icons.dns),
            label: 'Serveur',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: activeDownloadsCount > 0,
              label: Text('$activeDownloadsCount'),
              child: const Icon(Icons.download_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: activeDownloadsCount > 0,
              label: Text('$activeDownloadsCount'),
              child: const Icon(Icons.download),
            ),
            label: 'Téléchargements',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
      ),
    ),
    );
  }
}
