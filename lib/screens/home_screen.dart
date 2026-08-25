import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/download_provider.dart';
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
      const ServerScreen(),
      const DownloadsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
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
    );
  }
}
