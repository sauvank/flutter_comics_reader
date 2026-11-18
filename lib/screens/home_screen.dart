import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/download_provider.dart';
import '../providers/server_provider.dart';
import '../constants/app_version.dart';
import '../services/update_service.dart';
import '../utils/desktop_layout.dart';
import 'downloads_screen.dart';
import 'device_files_screen.dart';
import 'library_screen.dart';
import 'server_screen.dart';
import 'settings_screen.dart';
import '../l10n/l10n.dart';

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
    // IndexedStack keeps the Server tab alive, so refresh its cached profiles
    // when it becomes visible after a background or manual sync.
    if (index == 1) {
      context.read<ServerProvider>().loadServers();
    }
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
      const DeviceFilesScreen(),
      DownloadsScreen(onNavigateToServers: () => _onTabSelected(1)),
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
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
              content: Text(l10n.pressAgainToExit),
            ),
          );
          return;
        }

        // 4. Confirmed double back press: safely exit app
        SystemNavigator.pop();
      },
      child: DesktopLayout.isWide(context)
          ? Scaffold(
              body: Row(
                children: [
                  _DesktopSidebar(
                    currentIndex: _currentIndex,
                    activeDownloadsCount: activeDownloadsCount,
                    onSelected: _onTabSelected,
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: screens,
                    ),
                  ),
                ],
              ),
            )
          : Scaffold(
              body: IndexedStack(
                index: _currentIndex,
                children: screens,
              ),
              bottomNavigationBar: _buildBottomBar(activeDownloadsCount),
            ),
    );
  }

  Widget _buildBottomBar(int activeDownloadsCount) {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: _onTabSelected,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.auto_stories_outlined),
          selectedIcon: const Icon(Icons.auto_stories),
          // Five destinations share the same limited horizontal space on
          // phones.  A compact label prevents the selected destination
          // from wrapping at enlarged system text sizes.
          label: l10n.libraryTab,
        ),
        NavigationDestination(
          icon: const Icon(Icons.dns_outlined),
          selectedIcon: const Icon(Icons.dns),
          label: l10n.serverTab,
        ),
        NavigationDestination(
          icon: const Icon(Icons.folder_open_outlined),
          selectedIcon: const Icon(Icons.folder_open),
          label: l10n.filesTab,
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
          label: l10n.downloadsTabShort,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: l10n.settingsTab,
        ),
      ],
    );
  }
}

/// Side menu used instead of the bottom bar on large windows.
class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.currentIndex,
    required this.activeDownloadsCount,
    required this.onSelected,
  });

  final int currentIndex;
  final int activeDownloadsCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget item(int index, IconData icon, IconData selectedIcon, String label,
        {Widget? trailing}) {
      final selected = index == currentIndex;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: selected ? scheme.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onSelected(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(selected ? selectedIcon : icon,
                      size: 20,
                      color: selected
                          ? scheme.onSecondaryContainer
                          : scheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected
                            ? scheme.onSecondaryContainer
                            : scheme.onSurface,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 22),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(Icons.auto_stories,
                      size: 18, color: scheme.onPrimary),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text('ComicStream',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          item(0, Icons.auto_stories_outlined, Icons.auto_stories,
              l10n.navLibrary),
          item(1, Icons.dns_outlined, Icons.dns, l10n.navServers),
          item(2, Icons.folder_open_outlined, Icons.folder_open, l10n.filesTab),
          item(
            3,
            Icons.download_outlined,
            Icons.download,
            l10n.downloads,
            trailing: activeDownloadsCount > 0
                ? Badge(label: Text('$activeDownloadsCount'))
                : null,
          ),
          const Spacer(),
          item(4, Icons.settings_outlined, Icons.settings, l10n.settingsTab),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Text(
              AppVersion.fullVersion,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
