import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../models/book_item.dart';
import '../models/remote_file.dart';
import '../models/series_item.dart';
import '../models/server_profile.dart';
import '../providers/download_provider.dart';
import '../providers/library_provider.dart';
import '../providers/server_provider.dart';
import '../utils/format_utils.dart';
import '../widgets/book_card.dart';
import '../widgets/instant_read_modal.dart';
import '../widgets/remote_book_card.dart';
import '../widgets/series_card.dart';
import 'cbz_reader_screen.dart';
import 'epub_reader_screen.dart';
import 'pdf_reader_screen.dart';

enum LibraryViewMode {
  series,
  allBooks,
}

class LibraryScreen extends StatefulWidget {
  final void Function(int index)? onNavigateTab;

  const LibraryScreen({super.key, this.onNavigateTab});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  LibraryViewMode _viewMode = LibraryViewMode.series;
  SeriesItem? _selectedSeries;

  ServerProfile? _seriesServer;
  List<RemoteFile> _remoteSeriesFiles = [];
  bool _isLoadingRemoteSeries = false;

  bool get _isSearching => _searchController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSelectSeries(SeriesItem series) {
    setState(() {
      _selectedSeries = series;
      _remoteSeriesFiles = [];
      _seriesServer = null;
    });
    _checkAndLoadRemoteSeries(series);
  }

  void _checkAndLoadRemoteSeries(SeriesItem series) async {
    final serverProvider = context.read<ServerProvider>();
    BookItem? serverBook;
    for (final b in series.books) {
      if (b.serverId != null && b.serverRelativePath != null) {
        serverBook = b;
        break;
      }
    }

    if (serverBook != null) {
      final srv = serverProvider.servers.where((s) => s.id == serverBook!.serverId).firstOrNull;
      if (srv != null) {
        final parentDir = p.posix.dirname(serverBook.serverRelativePath!);
        setState(() {
          _seriesServer = srv;
          _isLoadingRemoteSeries = true;
        });

        try {
          final files = await serverProvider.listFilesInDirectory(
            server: srv,
            remoteRelativePath: parentDir,
          );
          if (mounted && _selectedSeries?.name == series.name) {
            setState(() {
              _remoteSeriesFiles = files;
              _isLoadingRemoteSeries = false;
            });
          }
        } catch (_) {
          if (mounted) {
            setState(() {
              _isLoadingRemoteSeries = false;
            });
          }
        }
      }
    }
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

    return PopScope(
      canPop: _selectedSeries == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedSeries != null) {
          setState(() {
            _selectedSeries = null;
          });
        }
      },
      child: _selectedSeries != null
          ? _buildSeriesDetailView(context, library, theme)
          : _buildMainLibraryView(context, library, theme),
    );
  }

  Widget _buildMainLibraryView(BuildContext context, LibraryProvider library, ThemeData theme) {
    final books = library.filteredBooks;
    final allSeries = SeriesItem.groupFromBooks(books);

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
                Icons.auto_stories_rounded,
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
            if (library.books.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${library.books.length} BD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
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
                if (library.books.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: SegmentedButton<LibraryViewMode>(
                      segments: [
                        ButtonSegment(
                          value: LibraryViewMode.series,
                          icon: const Icon(Icons.folder_special_rounded, size: 16),
                          label: Text('Par Séries (${allSeries.length})'),
                        ),
                        ButtonSegment(
                          value: LibraryViewMode.allBooks,
                          icon: const Icon(Icons.auto_stories_rounded, size: 16),
                          label: Text('Tous les tomes (${books.length})'),
                        ),
                      ],
                      selected: {_viewMode},
                      onSelectionChanged: (set) {
                        setState(() {
                          _viewMode = set.first;
                        });
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
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
                        hintText: 'Rechercher une série, un tome, un auteur...',
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
                  child: _viewMode == LibraryViewMode.series
                      ? _buildSeriesListView(context, library, allSeries, theme)
                      : _buildFlatBooksListView(context, library, books, theme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeriesListView(BuildContext context, LibraryProvider library, List<SeriesItem> allSeries, ThemeData theme) {
    final recentBooks = library.recentBooks;

    if (library.books.isEmpty) {
      return _buildEmptyLibraryState(theme);
    }

    if (allSeries.isEmpty && _isSearching) {
      return _buildEmptySearchState(theme);
    }

    return RefreshIndicator(
      onRefresh: () => library.loadLibrary(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildFilterChipsRow(library),
          ),
          if (recentBooks.isNotEmpty && !_isSearching && library.filter == LibraryFilter.all)
            SliverToBoxAdapter(
              child: _buildResumeReadingHero(recentBooks.first, theme),
            ),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.collections_bookmark_rounded, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Mes Collections & Séries (${allSeries.length})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                childAspectRatio: 0.68,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final series = allSeries[index];
                  return SeriesCard(
                    series: series,
                    onTap: () {
                      _onSelectSeries(series);
                    },
                  );
                },
                childCount: allSeries.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlatBooksListView(BuildContext context, LibraryProvider library, List<BookItem> books, ThemeData theme) {
    if (library.books.isEmpty) {
      return _buildEmptyLibraryState(theme);
    }

    if (books.isEmpty && _isSearching) {
      return _buildEmptySearchState(theme);
    }

    return RefreshIndicator(
      onRefresh: () => library.loadLibrary(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildFilterChipsRow(library),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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

  Widget _buildSeriesDetailView(BuildContext context, LibraryProvider library, ThemeData theme) {
    final series = _selectedSeries!;
    final nextLocalBook = series.nextToReadBook;
    final progressPercent = (series.overallProgress * 100).toInt();
    final downloadProvider = context.watch<DownloadProvider>();

    List<RemoteFile> undownloadedRemote = [];
    if (_seriesServer != null && _remoteSeriesFiles.isNotEmpty) {
      undownloadedRemote = _remoteSeriesFiles.where((rf) {
        if (rf.isDirectory || !rf.isSupportedBook) return false;
        if (library.getBookByServerPath(_seriesServer!.id, rf.path) != null) return false;
        final cleanRfName = p.basenameWithoutExtension(rf.name).toLowerCase();
        if (series.books.any((b) =>
            p.basenameWithoutExtension(b.originalFilename).toLowerCase() == cleanRfName ||
            b.title.toLowerCase() == cleanRfName)) {
          return false;
        }
        return true;
      }).toList();
      undownloadedRemote.sort((a, b) => NaturalSort.compare(a.name, b.name));
    }

    final nextRemoteToDownload = undownloadedRemote.isNotEmpty ? undownloadedRemote.first : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Retour aux séries',
          onPressed: () {
            setState(() {
              _selectedSeries = null;
            });
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              series.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${series.completedBooks}/${series.totalBooks} tomes lus • $progressPercent%',
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          if (_seriesServer != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Vérifier les nouveaux tomes sur le serveur',
              onPressed: () => _checkAndLoadRemoteSeries(series),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          if (nextLocalBook != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primaryContainer.withAlpha(140),
                        theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.primary.withAlpha(60)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openReader(nextLocalBook),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 50,
                                height: 75,
                                child: nextLocalBook.coverPath != null && File(nextLocalBook.coverPath!).existsSync()
                                    ? Image.file(File(nextLocalBook.coverPath!), fit: BoxFit.cover)
                                    : Container(
                                        color: theme.colorScheme.primary.withAlpha(30),
                                        child: Icon(Icons.menu_book, color: theme.colorScheme.primary),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      nextLocalBook.progress > 0 ? 'REPRENDRE' : 'TOME SUIVANT À LIRE',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    nextLocalBook.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    nextLocalBook.totalPages > 0
                                        ? 'Page ${nextLocalBook.currentPage + 1}/${nextLocalBook.totalPages} (${(nextLocalBook.progress * 100).toInt()}%)'
                                        : nextLocalBook.formatString,
                                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () => _openReader(nextLocalBook),
                              icon: const Icon(Icons.play_arrow_rounded, size: 18),
                              label: const Text('Lire'),
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (nextRemoteToDownload != null && _seriesServer != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF59E0B).withAlpha(40),
                        theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF59E0B).withAlpha(100)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 68,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFF59E0B).withAlpha(80)),
                          ),
                          child: const Center(
                            child: Icon(Icons.download_for_offline_rounded, color: Color(0xFFF59E0B), size: 28),
                          ),
                        ),
                        const SizedBox(width: 14),
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
                                      color: const Color(0xFFF59E0B),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'TOME SUIVANT SUR LE SERVEUR',
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    FormatUtils.formatBytes(nextRemoteToDownload.size),
                                    style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                nextRemoteToDownload.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFF59E0B),
                                      foregroundColor: Colors.black,
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    ),
                                    icon: const Icon(Icons.download_rounded, size: 16),
                                    label: const Text('Télécharger', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      downloadProvider.enqueueDownload(
                                        server: _seriesServer!,
                                        remoteFile: nextRemoteToDownload,
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('📥 Téléchargement lancé : ${nextRemoteToDownload.name}'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    ),
                                    icon: const Icon(Icons.visibility_rounded, size: 15),
                                    label: const Text('Lire direct', style: TextStyle(fontSize: 11)),
                                    onPressed: () {
                                      InstantReadModal.show(
                                        context,
                                        server: _seriesServer!,
                                        file: nextRemoteToDownload,
                                      );
                                    },
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
              ),
            ),
          if (_isLoadingRemoteSeries)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Recherche des tomes suivants sur le serveur distant...',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.folder_open_rounded, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Tomes téléchargés (${series.totalBooks})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                childAspectRatio: 0.65,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final book = series.books[index];
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
                childCount: series.books.length,
              ),
            ),
          ),
          if (undownloadedRemote.isNotEmpty && _seriesServer != null) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_download_rounded, size: 18, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Text(
                      'Tomes disponibles sur le serveur (${undownloadedRemote.length})',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (undownloadedRemote.length > 1)
                      TextButton.icon(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        icon: const Icon(Icons.download_for_offline_outlined, size: 16),
                        label: Text('Tout télécharger (${undownloadedRemote.length})', style: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          for (final f in undownloadedRemote) {
                            downloadProvider.enqueueDownload(
                              server: _seriesServer!,
                              remoteFile: f,
                            );
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('📥 ${undownloadedRemote.length} tomes ajoutés à la file de téléchargement'),
                            ),
                          );
                        },
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
                    final remoteFile = undownloadedRemote[index];
                    final task = downloadProvider.getTaskForRemotePath(remoteFile.path);

                    return RemoteBookCard(
                      server: _seriesServer!,
                      file: remoteFile,
                      isDownloaded: false,
                      downloadTask: task,
                      onTap: () {
                        InstantReadModal.show(
                          context,
                          server: _seriesServer!,
                          file: remoteFile,
                        );
                      },
                      onDownload: () {
                        downloadProvider.enqueueDownload(
                          server: _seriesServer!,
                          remoteFile: remoteFile,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('📥 Téléchargement : ${remoteFile.name}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                  childCount: undownloadedRemote.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChipsRow(LibraryProvider library) {
    return SingleChildScrollView(
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
          _buildFilterChip('Non lus', LibraryFilter.unread, library),
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
    );
  }

  Widget _buildFilterChip(String label, LibraryFilter filter, LibraryProvider library) {
    final isSelected = library.filter == filter;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (_) => library.setFilter(filter),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildResumeReadingHero(BookItem book, ThemeData theme) {
    final progressPercent = (book.progress * 100).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer.withAlpha(120),
              theme.colorScheme.surfaceContainerHighest.withAlpha(90),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(60)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openReader(book),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 56,
                      height: 80,
                      child: File(book.coverPath ?? '').existsSync()
                          ? Image.file(File(book.coverPath!), fit: BoxFit.cover)
                          : Container(
                              color: theme.colorScheme.primary.withAlpha(30),
                              child: Icon(Icons.auto_stories_rounded, color: theme.colorScheme.primary),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
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
                                color: theme.colorScheme.primary.withAlpha(40),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'CONTINUER LA LECTURE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$progressPercent%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          book.totalPages > 0
                              ? 'Page ${book.currentPage + 1} sur ${book.totalPages}'
                              : book.formatString,
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: book.progress.clamp(0.0, 1.0),
                            minHeight: 4,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyLibraryState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 64,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 16),
            const Text(
              'Votre bibliothèque est vide',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Explorez vos serveurs distants pour lire en streaming ou télécharger vos séries !',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            if (widget.onNavigateTab != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => widget.onNavigateTab?.call(1),
                icon: const Icon(Icons.dns_rounded, size: 18),
                label: const Text('Explorer mes serveurs'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun résultat pour cette recherche',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez un autre mot-clé ou réinitialisez les filtres.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
