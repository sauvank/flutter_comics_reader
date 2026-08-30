import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book_item.dart';
import '../providers/download_provider.dart';
import '../providers/library_provider.dart';
import '../providers/server_provider.dart';
import '../widgets/book_card.dart';
import '../widgets/folder_card.dart';
import '../widgets/instant_read_modal.dart';
import '../widgets/remote_book_card.dart';
import 'cbz_reader_screen.dart';
import 'epub_reader_screen.dart';
import 'pdf_reader_screen.dart';

class LibraryScreen extends StatefulWidget {
  final void Function(int index)? onNavigateTab;

  const LibraryScreen({super.key, this.onNavigateTab});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _activeViewIndex = 1; // Default to 1 (Collection / Folder Explorer with Local & Server badges)

  bool get _isSearching => _searchController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openReader(BookItem book) {
    if (book.format == BookFormat.pdf) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PdfReaderScreen(book: book),
        ),
      );
    } else if (book.format == BookFormat.epub) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EpubReaderScreen(book: book),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CbzReaderScreen(book: book),
        ),
      );
    }
  }

  void _confirmDelete(BookItem book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce livre ?'),
        content: Text('Voulez-vous supprimer "${book.title}" de votre stockage local ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<LibraryProvider>().deleteBook(book.id);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final library = context.watch<LibraryProvider>();
    final serverProvider = context.watch<ServerProvider>();

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
              child: Icon(
                _activeViewIndex == 0 ? Icons.menu_book_rounded : Icons.folder_copy_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Ma Bibliothèque',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (_activeViewIndex == 0)
            PopupMenuButton<LibrarySort>(
              icon: const Icon(Icons.sort_rounded),
              tooltip: 'Trier par',
              onSelected: (sort) => library.setSort(sort),
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: LibrarySort.lastRead,
                  child: Text('Dernière lecture'),
                ),
                const PopupMenuItem(
                  value: LibrarySort.title,
                  child: Text('Titre (A-Z)'),
                ),
                const PopupMenuItem(
                  value: LibrarySort.dateAdded,
                  child: Text('Date d\'ajout'),
                ),
                const PopupMenuItem(
                  value: LibrarySort.progress,
                  child: Text('Progression'),
                ),
              ],
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Actualiser le serveur',
              onPressed: () => serverProvider.fetchRemoteFiles(),
            ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1350),
            child: Column(
              children: [
                // View Switcher (Ma Collection / Dossiers vs Téléchargés)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                  child: SegmentedButton<int>(
                    segments: [
                      const ButtonSegment(
                        value: 1,
                        label: Text('Ma Collection (Dossiers)'),
                        icon: Icon(Icons.folder_copy_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: 0,
                        label: Text('Téléchargés (${library.books.length})'),
                        icon: const Icon(Icons.download_done_rounded, size: 16),
                      ),
                    ],
                    selected: {_activeViewIndex},
                    onSelectionChanged: (set) {
                      setState(() {
                        _activeViewIndex = set.first;
                      });
                    },
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withAlpha(90),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withAlpha(50),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: _activeViewIndex == 0
                            ? 'Rechercher parmi les BD téléchargées...'
                            : 'Rechercher un tome, une série ou un dossier...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    library.setSearchQuery('');
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (val) {
                        setState(() {
                          library.setSearchQuery(val);
                        });
                      },
                    ),
                  ),
                ),

                Expanded(
                  child: _activeViewIndex == 0
                      ? _buildLocalLibraryView(context, library, theme)
                      : _buildServerExplorerView(context, serverProvider, theme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocalLibraryView(BuildContext context, LibraryProvider library, ThemeData theme) {
    final books = library.filteredBooks;
    final recentBooks = library.recentBooks;

    return RefreshIndicator(
      onRefresh: () => library.loadLibrary(),
      child: CustomScrollView(
        slivers: [
          // Filter Chips Bar
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  _buildFilterChip('Tous (${library.books.length})', LibraryFilter.all, library),
                  const SizedBox(width: 8),
                  _buildFilterChip('❤️ Favoris', LibraryFilter.favorites, library),
                  const SizedBox(width: 8),
                  _buildFilterChip('En cours', LibraryFilter.inProgress, library),
                  const SizedBox(width: 8),
                  _buildFilterChip('CBZ / CBR', LibraryFilter.cbz, library),
                  const SizedBox(width: 8),
                  _buildFilterChip('PDF', LibraryFilter.pdf, library),
                  const SizedBox(width: 8),
                  _buildFilterChip('EPUB / Romans', LibraryFilter.epub, library),
                  const SizedBox(width: 8),
                  _buildFilterChip('Terminés', LibraryFilter.completed, library),
                ],
              ),
            ),
          ),

          // Hero Resume Reading Banner (Latest Read Book)
          if (recentBooks.isNotEmpty && !_isSearching && library.filter == LibraryFilter.all)
            SliverToBoxAdapter(
              child: _buildResumeReadingHero(recentBooks.first, theme),
            ),

          // Recent Books Section (Resume Reading Carousel)
          if (recentBooks.length > 1 && !_isSearching && library.filter == LibraryFilter.all) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    const Text(
                      'Récemment ouverts',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 190,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: recentBooks.skip(1).length,
                  itemBuilder: (context, index) {
                    final book = recentBooks.skip(1).toList()[index];
                    return Container(
                      width: 130,
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: BookCard(
                        book: book,
                        onTap: () => _openReader(book),
                        onDelete: () => _confirmDelete(book),
                        onToggleFavorite: () => library.toggleFavorite(book.id),
                        onToggleStatus: () {
                          library.updateBookProgress(
                            bookId: book.id,
                            currentPage: book.isCompleted ? 0 : book.totalPages,
                            totalPages: book.totalPages,
                            isCompleted: !book.isCompleted,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Divider(height: 24, indent: 16, endIndent: 16),
            ),
          ],

          // Grid / List of Books
          if (books.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isSearching ? Icons.search_off_rounded : Icons.auto_stories_outlined,
                        size: 64,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isSearching
                            ? 'Aucun résultat pour cette recherche'
                            : 'Aucun livre téléchargé pour le moment',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSearching
                            ? 'Essayez un autre mot-clé ou réinitialisez les filtres.'
                            : 'Basculez sur « Tout le Serveur » ci-dessus pour lire ou télécharger vos BDs !',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () {
                          setState(() {
                            _activeViewIndex = 1;
                          });
                        },
                        icon: const Icon(Icons.cloud_sync_rounded, size: 18),
                        label: const Text('Voir mes dossiers sur le serveur'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final book = books[index];
                    return BookCard(
                      book: book,
                      onTap: () => _openReader(book),
                      onDelete: () => _confirmDelete(book),
                      onToggleFavorite: () => library.toggleFavorite(book.id),
                      onToggleStatus: () {
                        library.updateBookProgress(
                          bookId: book.id,
                          currentPage: book.isCompleted ? 0 : book.totalPages,
                          totalPages: book.totalPages,
                          isCompleted: !book.isCompleted,
                        );
                      },
                    );
                  },
                  childCount: books.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServerExplorerView(BuildContext context, ServerProvider serverProvider, ThemeData theme) {
    final activeServer = serverProvider.activeServer;
    final remoteFiles = serverProvider.remoteFiles;
    final breadcrumbs = serverProvider.breadcrumbs;
    final currentPath = serverProvider.currentPath;
    final libraryProvider = context.watch<LibraryProvider>();
    final downloadProvider = context.watch<DownloadProvider>();

    if (activeServer == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Aucun serveur sélectionné', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => widget.onNavigateTab?.call(1),
                icon: const Icon(Icons.settings),
                label: const Text('Configurer le serveur'),
              ),
            ],
          ),
        ),
      );
    }

    final query = _searchController.text.trim().toLowerCase();
    final folders = remoteFiles.where((f) {
      if (!f.isDirectory) return false;
      if (query.isEmpty) return true;
      return f.name.toLowerCase().contains(query);
    }).toList();

    final books = remoteFiles.where((f) {
      if (f.isDirectory || !f.isSupportedBook) return false;
      if (query.isEmpty) return true;
      return f.name.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        // Navigation Breadcrumb bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(20)),
            ),
          ),
          child: Row(
            children: [
              if (currentPath.isNotEmpty && currentPath != '/')
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => serverProvider.navigateUp(),
                  tooltip: 'Dossier parent',
                ),
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
              Builder(
                builder: (context) {
                  final undownloadedBooks = books
                      .where((f) => libraryProvider.getBookByServerPath(activeServer.id, f.path) == null)
                      .toList();

                  if (books.isEmpty) return const SizedBox.shrink();

                  if (undownloadedBooks.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Tous téléchargés ✅',
                            style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }

                  return TextButton.icon(
                    onPressed: () {
                      for (final f in undownloadedBooks) {
                        downloadProvider.enqueueDownload(server: activeServer, remoteFile: f);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${undownloadedBooks.length} nouveau(x) livre(s) mis en file d\'attente')),
                      );
                    },
                    icon: const Icon(Icons.download_for_offline_outlined, size: 16),
                    label: Text('Tout (${undownloadedBooks.length})', style: const TextStyle(fontSize: 11)),
                  );
                },
              ),
            ],
          ),
        ),

        // Remote Directory Contents in Grid Layout
        Expanded(
          child: serverProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : serverProvider.errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                            const SizedBox(height: 12),
                            Text(serverProvider.errorMessage!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => serverProvider.fetchRemoteFiles(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : (folders.isEmpty && books.isEmpty)
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  query.isNotEmpty ? Icons.search_off_rounded : Icons.folder_open_outlined,
                                  size: 48,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  query.isNotEmpty
                                      ? 'Aucun résultat pour "$query"'
                                      : 'Dossier vide',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                                if (query.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        context.read<LibraryProvider>().setSearchQuery('');
                                      });
                                    },
                                    icon: const Icon(Icons.clear_rounded, size: 16),
                                    label: const Text('Effacer la recherche'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => serverProvider.fetchRemoteFiles(),
                          child: CustomScrollView(
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
                                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 380,
                                      mainAxisExtent: 68,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final folder = folders[index];
                                        final isFav = libraryProvider.isRemoteFavorite(activeServer.id, folder.path);
                                        return FolderCard(
                                          name: folder.name,
                                          isFavorite: isFav,
                                          onToggleFavorite: () => libraryProvider.toggleRemoteFavorite(activeServer.id, folder.path),
                                          onTap: () => serverProvider.navigateTo(folder.path),
                                        );
                                      },
                                      childCount: folders.length,
                                    ),
                                  ),
                                ),
                              ],

                              // Books / Files Section
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
                                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 200,
                                      childAspectRatio: 0.65,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 14,
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
                                            // 1-Tap Instant Stream & Read
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
                                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                behavior: SnackBarBehavior.floating,
                                                duration: const Duration(seconds: 4),
                                                content: Row(
                                                  children: [
                                                    const Icon(Icons.downloading_rounded, color: Colors.amber, size: 20),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        'Téléchargement démarré : ${file.name}',
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                action: widget.onNavigateTab != null
                                                    ? SnackBarAction(
                                                        label: 'Voir',
                                                        textColor: theme.colorScheme.primary,
                                                        onPressed: () => widget.onNavigateTab!(2),
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
    );
  }

  Widget _buildResumeReadingHero(BookItem book, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withAlpha(160),
            theme.colorScheme.surfaceContainerHighest.withAlpha(120),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(60),
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: () => _openReader(book),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 65,
                  height: 95,
                  child: book.coverPath != null && File(book.coverPath!).existsSync()
                      ? Image.file(File(book.coverPath!), fit: BoxFit.cover)
                      : Container(
                          color: theme.colorScheme.primary.withAlpha(40),
                          child: Icon(Icons.menu_book, color: theme.colorScheme.primary, size: 30),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            book.formatString,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Page ${book.currentPage + 1} / ${book.totalPages > 0 ? book.totalPages : "?"}',
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: book.progress,
                        minHeight: 5,
                        backgroundColor: theme.colorScheme.outlineVariant.withAlpha(50),
                        valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(book.progress * 100).toInt()}% lu',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                        ),
                        Row(
                          children: [
                            Text(
                              'Reprendre',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                            ),
                            Icon(Icons.play_arrow_rounded, size: 18, color: theme.colorScheme.primary),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, LibraryFilter filterValue, LibraryProvider library) {
    final isSelected = library.filter == filterValue;
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => library.setFilter(filterValue),
      selectedColor: theme.colorScheme.primary.withAlpha(40),
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
