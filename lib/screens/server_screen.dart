import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/remote_file.dart';
import '../models/server_profile.dart';
import '../providers/download_provider.dart';
import '../providers/library_provider.dart';
import '../providers/server_provider.dart';
import '../widgets/folder_card.dart';
import '../widgets/instant_read_modal.dart';
import '../widgets/remote_book_card.dart';
import '../widgets/remote_file_tile.dart';
import '../widgets/server_form_dialog.dart';

class ServerScreen extends StatefulWidget {
  const ServerScreen({super.key});

  @override
  State<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends State<ServerScreen> {
  bool _isGridView = true;

  void _openAddServerDialog() async {
    final newServer = await showDialog<ServerProfile>(
      context: context,
      builder: (_) => const ServerFormDialog(),
    );
    if (newServer != null && mounted) {
      final provider = context.read<ServerProvider>();
      await provider.saveServer(newServer);
      await provider.setActiveServer(newServer);
    }
  }

  void _openEditServerDialog(ServerProfile server) async {
    final updated = await showDialog<ServerProfile>(
      context: context,
      builder: (_) => ServerFormDialog(server: server),
    );
    if (updated != null && mounted) {
      final provider = context.read<ServerProvider>();
      await provider.saveServer(updated);
      if (provider.activeServer?.id == updated.id) {
        await provider.setActiveServer(updated);
      }
    }
  }

  void _saveCurrentPathAsRoot() async {
    final provider = context.read<ServerProvider>();
    if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ Impossible d\'enregistrer : ce dossier est inaccessible.'),
          backgroundColor: Colors.red.shade800,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    await provider.setAndSaveCurrentPathAsRoot();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Dossier racine validé et enregistré : ${provider.currentPath}'),
          backgroundColor: Colors.green.shade800,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _downloadAllInFolder(List<RemoteFile> files, ServerProfile server) {
    final downloadProvider = context.read<DownloadProvider>();
    final libraryProvider = context.read<LibraryProvider>();

    int count = 0;
    for (final file in files) {
      if (file.isSupportedBook) {
        final isDownloaded = libraryProvider.getBookByServerPath(server.id, file.path) != null;
        if (!isDownloaded) {
          downloadProvider.enqueueDownload(server: server, remoteFile: file);
          count++;
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$count fichier(s) ajouté(s) à la file de téléchargement'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serverProvider = context.watch<ServerProvider>();
    final downloadProvider = context.watch<DownloadProvider>();
    final libraryProvider = context.watch<LibraryProvider>();

    final activeServer = serverProvider.activeServer;
    final remoteFiles = serverProvider.remoteFiles;
    final breadcrumbs = serverProvider.breadcrumbs;
    final currentPath = serverProvider.currentPath;

    final folders = remoteFiles.where((f) => f.isDirectory).toList();
    final books = remoteFiles.where((f) => !f.isDirectory && f.isSupportedBook).toList();
    final supportedFilesCount = books.length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.cloud_sync_rounded, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Explorateur Serveur'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            tooltip: _isGridView ? 'Vue Liste' : 'Vue Grille',
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Ajouter un serveur',
            onPressed: _openAddServerDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: activeServer != null ? () => serverProvider.fetchRemoteFiles() : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Server Selector Card
          Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(30)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: serverProvider.servers.isEmpty
                      ? const Text('Aucun serveur configuré', style: TextStyle(color: Colors.grey))
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: serverProvider.servers.any((s) => s.id == activeServer?.id)
                                ? activeServer?.id
                                : null,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            items: serverProvider.servers.map((server) {
                              IconData icon = Icons.folder_shared_outlined;
                              if (server.serverType == ServerType.ftp) {
                                icon = Icons.swap_horizontal_circle_outlined;
                              } else if (server.serverType == ServerType.httpDirectory) {
                                icon = Icons.http;
                              }

                              return DropdownMenuItem<String>(
                                value: server.id,
                                child: Row(
                                  children: [
                                    Icon(
                                      icon,
                                      size: 18,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        server.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                    Text(
                                      '${server.host}:${server.port}',
                                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (serverId) {
                              if (serverId != null) {
                                final s = serverProvider.servers.firstWhere((srv) => srv.id == serverId);
                                serverProvider.setActiveServer(s);
                              }
                            },
                          ),
                        ),
                ),
                if (activeServer != null) ...[
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 20),
                    tooltip: 'Modifier ce serveur',
                    onPressed: () => _openEditServerDialog(activeServer),
                  ),
                ],
              ],
            ),
          ),

          // Breadcrumbs Navigation Bar
          if (activeServer != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(20)),
                  bottom: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(20)),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Back button
                      if (currentPath.isNotEmpty && currentPath != '/')
                        IconButton(
                          icon: const Icon(Icons.arrow_back, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () => serverProvider.navigateUp(),
                          tooltip: 'Dossier parent',
                        ),
                      // Root icon
                      InkWell(
                        onTap: () => serverProvider.navigateToRoot(),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            children: [
                              Icon(Icons.home_outlined, size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 4),
                              const Text('Racine', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      // Breadcrumb segments
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (int i = 0; i < breadcrumbs.length; i++) ...[
                                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                                InkWell(
                                  onTap: () => serverProvider.navigateToBreadcrumbIndex(i),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                    child: Text(
                                      breadcrumbs[i],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: i == breadcrumbs.length - 1
                                            ? theme.colorScheme.onSurface
                                            : theme.colorScheme.primary,
                                        fontWeight: i == breadcrumbs.length - 1
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      // Batch Download All button
                      if (supportedFilesCount > 0)
                        TextButton.icon(
                          onPressed: () => _downloadAllInFolder(books, activeServer),
                          icon: const Icon(Icons.download_for_offline_outlined, size: 16),
                          label: Text('Tout ($supportedFilesCount)', style: const TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),

                  // Folder Validation Banner
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 2),
                    child: Row(
                      children: [
                        Icon(Icons.folder_open, size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            currentPath.isEmpty ? '/' : currentPath,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _saveCurrentPathAsRoot,
                          icon: const Icon(Icons.check_circle_outline, size: 14),
                          label: const Text('Valider ce dossier', style: TextStyle(fontSize: 11)),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Main Directory Content Area
          Expanded(
            child: activeServer == null
                ? _buildNoServerState(theme)
                : serverProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : serverProvider.errorMessage != null
                        ? _buildErrorState(serverProvider.errorMessage!, activeServer, theme)
                        : (folders.isEmpty && books.isEmpty)
                            ? _buildEmptyDirectoryState(theme)
                            : RefreshIndicator(
                                onRefresh: () => serverProvider.fetchRemoteFiles(),
                                child: _isGridView
                                    ? _buildGridView(context, folders, books, activeServer, libraryProvider, downloadProvider, theme)
                                    : _buildListView(context, remoteFiles, activeServer, libraryProvider, downloadProvider),
                              ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(
    BuildContext context,
    List<RemoteFile> folders,
    List<RemoteFile> books,
    ServerProfile activeServer,
    LibraryProvider libraryProvider,
    DownloadProvider downloadProvider,
    ThemeData theme,
  ) {
    final serverProvider = context.read<ServerProvider>();

    return CustomScrollView(
      slivers: [
        // Folders Section
        if (folders.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.folder_copy_outlined, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Dossiers & Séries (${folders.length})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final folder = folders[index];
                  return FolderCard(
                    name: folder.name,
                    onTap: () => serverProvider.navigateTo(folder.path),
                  );
                },
                childCount: folders.length,
              ),
            ),
          ),
        ],

        // Books Section
        if (books.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.menu_book_rounded, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Livres & Tomes (${books.length})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final file = books[index];
                  final isDownloaded =
                      libraryProvider.getBookByServerPath(activeServer.id, file.path) != null;
                  final task = downloadProvider.getTaskForRemotePath(file.path);

                  return RemoteBookCard(
                    server: activeServer,
                    file: file,
                    isDownloaded: isDownloaded,
                    downloadTask: task,
                    onTap: () {
                      InstantReadModal.show(
                        context,
                        server: activeServer,
                        file: file,
                      );
                    },
                    onDownload: () {
                      downloadProvider.enqueueDownload(
                        server: activeServer,
                        remoteFile: file,
                      );
                    },
                  );
                },
                childCount: books.length,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildListView(
    BuildContext context,
    List<RemoteFile> remoteFiles,
    ServerProfile activeServer,
    LibraryProvider libraryProvider,
    DownloadProvider downloadProvider,
  ) {
    final serverProvider = context.read<ServerProvider>();

    return ListView.builder(
      padding: const EdgeInsets.only(top: 6, bottom: 20),
      itemCount: remoteFiles.length,
      itemBuilder: (context, index) {
        final file = remoteFiles[index];
        final isDownloaded =
            libraryProvider.getBookByServerPath(activeServer.id, file.path) != null;
        final task = downloadProvider.getTaskForRemotePath(file.path);

        return RemoteFileTile(
          file: file,
          isDownloaded: isDownloaded,
          downloadTask: task,
          onTap: () {
            if (file.isDirectory) {
              serverProvider.navigateTo(file.path);
            } else if (file.isSupportedBook) {
              InstantReadModal.show(
                context,
                server: activeServer,
                file: file,
              );
            }
          },
          onDownload: () {
            downloadProvider.enqueueDownload(
              server: activeServer,
              remoteFile: file,
            );
          },
          onCancelDownload: task != null
              ? () => downloadProvider.cancelDownload(task.id)
              : null,
        );
      },
    );
  }

  Widget _buildNoServerState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dns_outlined, size: 64, color: theme.colorScheme.primary.withAlpha(150)),
            const SizedBox(height: 16),
            const Text('Aucun serveur local configuré', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Ajoutez l\'adresse de votre serveur WebDAV ou HTTP local pour explorer et télécharger vos BDs.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _openAddServerDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter mon premier serveur'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDirectoryState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined, size: 56, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            const Text('Ce dossier est vide', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Aucun fichier ou sous-dossier trouvé dans cet emplacement.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, ServerProfile server, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text('Connexion impossible au serveur',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Vérifiez que votre appareil est connecté au même réseau WiFi et que le serveur est allumé sur ${server.baseUrl}.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openEditServerDialog(server),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Modifier les paramètres'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => context.read<ServerProvider>().fetchRemoteFiles(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
