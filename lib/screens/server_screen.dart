import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/server_profile.dart';
import '../providers/download_provider.dart';
import '../providers/library_provider.dart';
import '../providers/server_provider.dart';
import '../widgets/folder_card.dart';
import '../widgets/instant_read_modal.dart';
import '../widgets/remote_book_card.dart';
import '../widgets/server_form_dialog.dart';
import '../widgets/server_setup_guide.dart';
import '../l10n/l10n.dart';

class ServerScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  const ServerScreen({super.key, this.onNavigateTab});

  @override
  State<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends State<ServerScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSetupGuide() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (guideContext) => Scaffold(
        appBar: AppBar(title: Text(l10n.setupServer)),
        body: ServerSetupGuide(
          onAddServer: () {
            Navigator.of(guideContext).pop();
            _openAddServerDialog();
          },
          onImportConfiguration: () {
            Navigator.of(guideContext).pop();
            _importServersDialog();
          },
        ),
      ),
    ));
  }

  void _openAddServerDialog() async {
    final newServer = await showDialog<ServerProfile>(
      context: context,
      builder: (_) => const ServerFormDialog(),
    );
    if (newServer != null && mounted) {
      final provider = context.read<ServerProvider>();
      await provider.saveServer(newServer);
      await provider.openServer(newServer);
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
        await provider.openServer(updated);
      }
    }
  }

  void _testServerConnection(ServerProfile server) async {
    final serverProvider = context.read<ServerProvider>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final success = await serverProvider.testConnection(server);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(
                success
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  success
                      ? l10n.connectionSucceeded(server.name)
                      : l10n.connectionFailed(server.name),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: success ? Colors.green : Colors.redAccent,
        ),
      );
    }
  }

  void _confirmDeleteServer(ServerProfile server) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteServerTitle),
        content: Text(
            l10n.deleteServerBody(server.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ServerProvider>().deleteServer(server.id);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _exportServersDialog() {
    final serverProvider = context.read<ServerProvider>();
    final jsonStr = serverProvider.exportServersJson();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.file_upload_outlined),
            SizedBox(width: 8),
            Text(l10n.exportConfiguration),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.exportConfigurationBody,
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(ctx)
                      .colorScheme
                      .surfaceContainerHighest
                      .withAlpha(80),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Theme.of(ctx)
                          .colorScheme
                          .outlineVariant
                          .withAlpha(50)),
                ),
                constraints: const BoxConstraints(maxHeight: 180),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonStr,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: Text(l10n.copyJson),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text(l10n.configurationCopied),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _importServersDialog() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.file_download_outlined),
            SizedBox(width: 8),
            Text(l10n.importConfiguration),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.folder_open_rounded),
                label: Text(l10n.chooseJsonFile),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                ),
                onPressed: () async {
                  final result = await FilePicker.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['json'],
                  );
                  if (result != null && result.files.single.path != null) {
                    try {
                      final file = File(result.files.single.path!);
                      final content = await file.readAsString();
                      textController.text = content;
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  l10n.fileReadError(e))),
                        );
                      }
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              Text(l10n.orPasteJson,
                  style: TextStyle(fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: textController,
                maxLines: 5,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                decoration: InputDecoration(
                  hintText: '{\n  "servers": [...]\n}',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final json = textController.text.trim();
              if (json.isEmpty) return;

              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(ctx);
              final serverProvider = context.read<ServerProvider>();
              final count = await serverProvider.importServersFromJson(json);
              nav.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(l10n.serversImported(count)),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(l10n.importAction),
          ),
        ],
      ),
    );
  }

  void _saveCurrentPathAsRoot() async {
    final serverProvider = context.read<ServerProvider>();
    await serverProvider.setAndSaveCurrentPathAsRoot();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              l10n.baseLocationSet(serverProvider.currentPath)),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serverProvider = context.watch<ServerProvider>();

    if (!serverProvider.isBrowsing || serverProvider.activeServer == null) {
      return _buildServersList(context, serverProvider, theme);
    }

    return _buildServerBrowser(
        context, serverProvider, serverProvider.activeServer!, theme);
  }

  Widget _buildServersList(
      BuildContext context, ServerProvider serverProvider, ThemeData theme) {
    final servers = serverProvider.servers;

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
              child: Icon(Icons.dns_rounded,
                  color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(l10n.myServers),
            if (servers.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${servers.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: l10n.addServer,
            onPressed: _openAddServerDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: l10n.options,
            onSelected: (value) {
              if (value == 'guide') {
                _openSetupGuide();
              } else if (value == 'export') {
                _exportServersDialog();
              } else if (value == 'import') {
                _importServersDialog();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'guide',
                child: Row(
                  children: [
                    Icon(Icons.help_outline_rounded, size: 20),
                    SizedBox(width: 10),
                    Text(l10n.howToSetupServer),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_upload_outlined, size: 20),
                    SizedBox(width: 10),
                    Text(l10n.exportConfigurations),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.file_download_outlined, size: 20),
                    SizedBox(width: 10),
                    Text(l10n.importConfiguration),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: servers.isEmpty
          ? ServerSetupGuide(
              onAddServer: _openAddServerDialog,
              onImportConfiguration: _importServersDialog,
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: servers.length,
              itemBuilder: (context, index) {
                final server = servers[index];
                return _buildServerCard(context, server, serverProvider, theme);
              },
            ),
    );
  }

  Widget _buildServerCard(BuildContext context, ServerProfile server,
      ServerProvider serverProvider, ThemeData theme) {
    Color typeColor = const Color(0xFF8B5CF6);
    IconData typeIcon = Icons.cloud_queue_rounded;
    if (server.serverType == ServerType.webdav) {
      typeColor = const Color(0xFF06B6D4);
      typeIcon = Icons.cloud_done_rounded;
    } else if (server.serverType == ServerType.ftp) {
      typeColor = const Color(0xFFF59E0B);
      typeIcon = Icons.swap_horizontal_circle_rounded;
    } else if (server.serverType == ServerType.httpDirectory) {
      typeColor = const Color(0xFF10B981);
      typeIcon = Icons.http_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: theme.colorScheme.outlineVariant.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => serverProvider.openServer(server),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Glowing protocol badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: typeColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: typeColor.withAlpha(80), width: 1.2),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 24),
                ),
                const SizedBox(width: 14),

                // Server details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              server.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              server.serverType.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: typeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${server.host}:${server.port}${server.path}',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Action Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  tooltip: l10n.options,
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openEditServerDialog(server);
                    } else if (value == 'test') {
                      _testServerConnection(server);
                    } else if (value == 'delete') {
                      _confirmDeleteServer(server);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text(l10n.edit),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'test',
                      child: Row(
                        children: [
                          Icon(Icons.network_check_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(l10n.testConnection),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 18, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text(l10n.delete,
                              style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),

                const Icon(Icons.chevron_right_rounded,
                    size: 24, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServerBrowser(
      BuildContext context,
      ServerProvider serverProvider,
      ServerProfile activeServer,
      ThemeData theme) {
    final remoteFiles = serverProvider.remoteFiles;
    final breadcrumbs = serverProvider.breadcrumbs;
    final libraryProvider = context.watch<LibraryProvider>();
    final downloadProvider = context.watch<DownloadProvider>();

    final q = _searchQuery.trim().toLowerCase();
    final folders = q.isEmpty
        ? remoteFiles.where((f) => f.isDirectory).toList()
        : remoteFiles
            .where((f) => f.isDirectory && f.name.toLowerCase().contains(q))
            .toList();
    final books = q.isEmpty
        ? remoteFiles.where((f) => !f.isDirectory && f.isSupportedBook).toList()
        : remoteFiles
            .where((f) =>
                !f.isDirectory &&
                f.isSupportedBook &&
                f.name.toLowerCase().contains(q))
            .toList();

    final undownloadedBooks = books
        .where((f) =>
            libraryProvider.getBookByServerPath(activeServer.id, f.path) ==
            null)
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: l10n.back,
          onPressed: () {
            if (serverProvider.canNavigateUp) {
              serverProvider.navigateUp();
            } else {
              serverProvider.closeServerBrowser();
            }
          },
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: l10n.filterFolderHint,
                  border: InputBorder.none,
                  hintStyle:
                      TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeServer.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${activeServer.serverType.name.toUpperCase()} • ${activeServer.host}',
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? l10n.closeSearch : l10n.search,
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.refresh,
            onPressed: () => serverProvider.fetchRemoteFiles(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: l10n.folderOptions,
            onSelected: (value) {
              if (value == 'set_root') {
                _saveCurrentPathAsRoot();
              } else if (value == 'switch_server') {
                serverProvider.closeServerBrowser();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'set_root',
                child: Row(
                  children: [
                    Icon(Icons.bookmark_add_outlined, size: 18),
                    SizedBox(width: 8),
                    Text(l10n.setFolderAsRoot),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'switch_server',
                child: Row(
                  children: [
                    Icon(Icons.dns_outlined, size: 18),
                    SizedBox(width: 8),
                    Text(l10n.switchServer),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Breadcrumbs Navigation Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
              border: Border(
                bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withAlpha(20)),
              ),
            ),
            child: Row(
              children: [
                if (serverProvider.canNavigateUp)
                  IconButton(
                    icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => serverProvider.navigateUp(),
                    tooltip: l10n.parentFolder,
                  ),
                InkWell(
                  onTap: () => serverProvider.navigateToRoot(),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.home_rounded,
                            size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(l10n.root,
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (int i = 0; i < breadcrumbs.length; i++) ...[
                          Icon(Icons.chevron_right_rounded,
                              size: 16, color: theme.colorScheme.outline),
                          InkWell(
                            onTap: () =>
                                serverProvider.navigateToBreadcrumbIndex(i),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              child: Text(
                                breadcrumbs[i],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: i == breadcrumbs.length - 1
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
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
                if (undownloadedBooks.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.download_for_offline_outlined,
                        size: 16),
                    label: Text(l10n.everythingCount(undownloadedBooks.length),
                        style: const TextStyle(fontSize: 11)),
                    onPressed: () async {
                      if (undownloadedBooks.length > 3) {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(l10n.downloadAllTitle),
                            content: Text(
                                l10n.downloadAllBody(undownloadedBooks.length)),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(l10n.cancel)),
                              FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(l10n.download)),
                            ],
                          ),
                        );
                        if (confirm != true) return;
                      }
                      for (final f in undownloadedBooks) {
                        downloadProvider.enqueueDownload(
                            server: activeServer, remoteFile: f);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                l10n.volumesQueuedCount(undownloadedBooks.length)),
                          ),
                        );
                      }
                    },
                  ),
              ],
            ),
          ),

          // Main Directory Content
          Expanded(
            child: serverProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : serverProvider.errorMessage != null
                    ? _buildErrorState(
                        serverProvider.errorMessage!, activeServer, theme)
                    : (folders.isEmpty && books.isEmpty)
                        ? _buildEmptyDirectoryState(theme)
                        : RefreshIndicator(
                            onRefresh: () => serverProvider.fetchRemoteFiles(),
                            child: CustomScrollView(
                              slivers: [
                                // Subfolders section
                                if (folders.isNotEmpty) ...[
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 14, 16, 8),
                                      child: Row(
                                        children: [
                                          Icon(Icons.folder_copy_outlined,
                                              size: 18,
                                              color: theme.colorScheme.primary),
                                          const SizedBox(width: 6),
                                          Text(
                                            l10n.foldersSeriesCount(folders.length),
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    sliver: SliverGrid(
                                      gridDelegate:
                                          const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 380,
                                        mainAxisExtent: 68,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final folder = folders[index];
                                          final isFav =
                                              libraryProvider.isRemoteFavorite(
                                                  activeServer.id, folder.path);
                                          return FolderCard(
                                            name: folder.name,
                                            isFavorite: isFav,
                                            onToggleFavorite: () =>
                                                libraryProvider
                                                    .toggleRemoteFavorite(
                                                        activeServer.id,
                                                        folder.path),
                                            onTap: () => serverProvider
                                                .navigateTo(folder.path),
                                          );
                                        },
                                        childCount: folders.length,
                                      ),
                                    ),
                                  ),
                                ],

                                // Books section
                                if (books.isNotEmpty) ...[
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 18, 16, 8),
                                      child: Row(
                                        children: [
                                          Icon(Icons.menu_book_rounded,
                                              size: 18,
                                              color: theme.colorScheme.primary),
                                          const SizedBox(width: 6),
                                          Text(
                                            l10n.booksComicsCount(books.length),
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SliverPadding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 24),
                                    sliver: SliverGrid(
                                      gridDelegate:
                                          const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 200,
                                        childAspectRatio: 0.65,
                                        crossAxisSpacing: 14,
                                        mainAxisSpacing: 14,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final file = books[index];
                                          final isDownloaded = libraryProvider
                                                  .getBookByServerPath(
                                                      activeServer.id,
                                                      file.path) !=
                                              null;
                                          final task = downloadProvider
                                              .getTaskForRemotePath(file.path);

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
                                              ScaffoldMessenger.of(context)
                                                  .hideCurrentSnackBar();
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  duration: const Duration(
                                                      seconds: 4),
                                                  content: Row(
                                                    children: [
                                                      const Icon(
                                                          Icons
                                                              .downloading_rounded,
                                                          color: Colors.amber,
                                                          size: 20),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Text(
                                                          l10n.downloadingNamePlain(file.name),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  action: widget
                                                              .onNavigateTab !=
                                                          null
                                                      ? SnackBarAction(
                                                          label: l10n.view,
                                                          textColor: theme
                                                              .colorScheme
                                                              .primary,
                                                          onPressed: () => widget
                                                              .onNavigateTab!(3),
                                                        )
                                                      : null,
                                                ),
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
                            ),
                          ),
          ),
        ],
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
            Icon(Icons.folder_open_outlined,
                size: 56, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(l10n.folderEmpty,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              l10n.folderEmptyBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
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
            const Icon(Icons.wifi_off_rounded,
                size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(l10n.cannotConnectServer,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              l10n.checkServerReachable(server.baseUrl),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openEditServerDialog(server),
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(l10n.editSettings),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () =>
                      context.read<ServerProvider>().fetchRemoteFiles(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
