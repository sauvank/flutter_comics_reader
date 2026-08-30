import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/server_profile.dart';
import '../providers/server_provider.dart';
import '../providers/library_provider.dart';
import '../providers/download_provider.dart';
import '../widgets/server_form_dialog.dart';
import '../widgets/remote_book_card.dart';
import '../widgets/instant_read_modal.dart';

class ServerScreen extends StatefulWidget {
  const ServerScreen({super.key});

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

  void _exportServersDialog() {
    final serverProvider = context.read<ServerProvider>();
    final jsonStr = serverProvider.exportServersJson();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.file_upload_outlined),
            SizedBox(width: 8),
            Text('Exporter la configuration'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Voici le fichier de configuration JSON contenant vos profils serveurs :',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest.withAlpha(80),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(ctx).colorScheme.outlineVariant.withAlpha(50)),
                ),
                constraints: const BoxConstraints(maxHeight: 180),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonStr,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copier JSON'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Configuration copiée dans le presse-papiers !'),
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
        title: const Row(
          children: [
            Icon(Icons.file_download_outlined),
            SizedBox(width: 8),
            Text('Importer une configuration'),
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
                label: const Text('Choisir un fichier .json'),
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
                          SnackBar(content: Text('Erreur lors de la lecture du fichier : $e')),
                        );
                      }
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              const Text('Ou collez le JSON ici :', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: textController,
                maxLines: 5,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                decoration: const InputDecoration(
                  hintText: '[{"name": "Mon Serveur", ...}]',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.download_done_rounded, size: 16),
            label: const Text('Importer'),
            onPressed: () async {
              final text = textController.text.trim();
              if (text.isEmpty) return;

              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(ctx);
              final provider = context.read<ServerProvider>();

              try {
                final count = await provider.importServersFromJson(text);
                if (ctx.mounted) {
                  nav.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('✅ $count serveur(s) importé(s) avec succès !'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('❌ Erreur de format JSON : $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
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

  void _showServerSwitchSheet(BuildContext context) {
    final serverProvider = context.read<ServerProvider>();
    final activeServer = serverProvider.activeServer;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.dns_rounded, color: theme.colorScheme.primary, size: 22),
                      const SizedBox(width: 10),
                      const Text(
                        'Mes Serveurs Cloud & Locaux',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (serverProvider.servers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Aucun profil serveur enregistré',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: serverProvider.servers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final srv = serverProvider.servers[index];
                      final isSelected = srv.id == activeServer?.id;

                      IconData typeIcon = Icons.cloud_outlined;
                      Color typeColor = const Color(0xFF8B5CF6);
                      if (srv.serverType == ServerType.webdav) {
                        typeIcon = Icons.cloud_done_outlined;
                        typeColor = const Color(0xFF06B6D4);
                      } else if (srv.serverType == ServerType.ftp) {
                        typeIcon = Icons.swap_horizontal_circle_outlined;
                        typeColor = const Color(0xFFF59E0B);
                      } else if (srv.serverType == ServerType.httpDirectory) {
                        typeIcon = Icons.http_rounded;
                        typeColor = const Color(0xFF10B981);
                      }

                      return Material(
                        color: isSelected
                            ? theme.colorScheme.primaryContainer.withAlpha(100)
                            : theme.colorScheme.surfaceContainerHighest.withAlpha(50),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () {
                            serverProvider.setActiveServer(srv);
                            Navigator.pop(ctx);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant.withAlpha(30),
                                width: isSelected ? 1.8 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: typeColor.withAlpha(35),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(typeIcon, color: typeColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              srv.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: isSelected
                                                    ? theme.colorScheme.primary
                                                    : theme.colorScheme.onSurface,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: typeColor.withAlpha(30),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              srv.serverType.name.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: typeColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${srv.host}:${srv.port}${srv.path}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  tooltip: 'Modifier',
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _openEditServerDialog(srv);
                                  },
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 22),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),

              // Add Server Button
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openAddServerDialog();
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Ajouter un autre serveur'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServerHeroHeader(ServerProfile? activeServer, ServerProvider serverProvider, ThemeData theme) {
    if (activeServer == null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(40)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.cloud_off_rounded, color: theme.colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aucun serveur actif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 2),
                  Text('Touchez pour connecter un serveur', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: _openAddServerDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ajouter'),
              style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
      );
    }

    Color typeColor = const Color(0xFF8B5CF6);
    IconData typeIcon = Icons.cloud_queue_rounded;
    if (activeServer.serverType == ServerType.webdav) {
      typeColor = const Color(0xFF06B6D4);
      typeIcon = Icons.cloud_done_rounded;
    } else if (activeServer.serverType == ServerType.ftp) {
      typeColor = const Color(0xFFF59E0B);
      typeIcon = Icons.swap_horizontal_circle_rounded;
    } else if (activeServer.serverType == ServerType.httpDirectory) {
      typeColor = const Color(0xFF10B981);
      typeIcon = Icons.http_rounded;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showServerSwitchSheet(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Type Icon with glowing container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: typeColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: typeColor.withAlpha(80), width: 1.2),
                ),
                child: Icon(typeIcon, color: typeColor, size: 22),
              ),
              const SizedBox(width: 12),

              // Server Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            activeServer.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: typeColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            activeServer.serverType.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: typeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${activeServer.host}:${activeServer.port}',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Switch Icon Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Changer',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serverProvider = context.watch<ServerProvider>();

    final activeServer = serverProvider.activeServer;
    final remoteFiles = serverProvider.remoteFiles;
    final breadcrumbs = serverProvider.breadcrumbs;
    final currentPath = serverProvider.currentPath;

    final q = _searchQuery.trim().toLowerCase();
    final folders = q.isEmpty
        ? remoteFiles.where((f) => f.isDirectory).toList()
        : remoteFiles.where((f) => f.isDirectory && f.name.toLowerCase().contains(q)).toList();
    final books = q.isEmpty
        ? remoteFiles.where((f) => !f.isDirectory && f.isSupportedBook).toList()
        : remoteFiles.where((f) => !f.isDirectory && f.isSupportedBook && f.name.toLowerCase().contains(q)).toList();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Filtrer ce dossier...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              )
            : Row(
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
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'Fermer la recherche' : 'Rechercher',
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
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Ajouter un serveur',
            onPressed: _openAddServerDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: activeServer != null ? () => serverProvider.fetchRemoteFiles() : null,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Options de configuration',
            onSelected: (value) {
              if (value == 'export') {
                _exportServersDialog();
              } else if (value == 'import') {
                _importServersDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_upload_outlined, size: 20),
                    SizedBox(width: 10),
                    Text('Exporter la configuration'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.file_download_outlined, size: 20),
                    SizedBox(width: 10),
                    Text('Importer une configuration'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Server Hero Header
          _buildServerHeroHeader(activeServer, serverProvider, theme),

          // Breadcrumbs Navigation Bar
          if (activeServer != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(20)),
                  bottom: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(20)),
                ),
              ),
              child: Row(
                children: [
                  // Back button
                  if (currentPath.isNotEmpty && currentPath != '/')
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      onPressed: () => serverProvider.navigateUp(),
                      tooltip: 'Dossier parent',
                    ),
                  // Root icon
                  InkWell(
                    onTap: () => serverProvider.navigateToRoot(),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: Row(
                        children: [
                          Icon(Icons.home_rounded, size: 16, color: theme.colorScheme.primary),
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
                            Icon(Icons.chevron_right_rounded, size: 16, color: theme.colorScheme.outline),
                            InkWell(
                              onTap: () => serverProvider.navigateToBreadcrumbIndex(i),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
                ],
              ),
            ),

          // Main Directory Content Area (Folder List)
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
                                child: ListView(
                                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                                  children: [
                                    // Info pill if current folder contains books
                                    if (books.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withAlpha(25),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFF10B981).withAlpha(60)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.auto_stories_rounded, color: Color(0xFF10B981), size: 18),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Ce dossier contient ${books.length} tome(s) de BD',
                                                style: const TextStyle(
                                                  color: Color(0xFF10B981),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // List of Folders
                                    if (folders.isNotEmpty) ...[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                        child: Text(
                                          'Sous-dossiers disponibles (${folders.length})',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      ...folders.map((folder) => Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.surfaceContainer,
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(30)),
                                            ),
                                            child: ListTile(
                                              onTap: () => serverProvider.navigateTo(folder.path),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                              leading: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.primary.withAlpha(30),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Icon(Icons.folder_rounded, color: theme.colorScheme.primary, size: 22),
                                              ),
                                              title: Text(
                                                folder.name.replaceAll('_', ' '),
                                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                              ),
                                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                                            ),
                                          )),
                                    ],
                                    if (books.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                        child: Text(
                                          'Bandes dessinées (${books.length})',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 0.65,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                        ),
                                        itemCount: books.length,
                                        itemBuilder: (context, index) {
                                          final file = books[index];
                                          final isDownloaded = context.watch<LibraryProvider>().getBookByServerPath(activeServer.id, file.path) != null;
                                          final downloadTask = context.watch<DownloadProvider>().getTaskForRemotePath(file.path);
                                          return RemoteBookCard(
                                            server: activeServer,
                                            file: file,
                                            isDownloaded: isDownloaded,
                                            downloadTask: downloadTask,
                                            onTap: () {
                                              InstantReadModal.show(context, server: activeServer, file: file);
                                            },
                                            onDownload: () {
                                              context.read<DownloadProvider>().enqueueDownload(server: activeServer, remoteFile: file);
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Téléchargement de ${file.name} ajouté à la file d\'attente.')));
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
          ),

          // Bottom Action Bar to Select Folder as Library Root
          if (activeServer != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
                border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(30))),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dossier actuel :',
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                          ),
                          Text(
                            currentPath.isEmpty ? '/' : currentPath,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _saveCurrentPathAsRoot,
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text('Choisir ce dossier'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
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
