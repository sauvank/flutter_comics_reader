import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../models/book_item.dart';
import '../models/remote_file.dart';
import '../models/series_item.dart';
import '../models/server_profile.dart';
import '../providers/download_provider.dart';
import '../providers/library_provider.dart';
import '../providers/server_provider.dart';
import '../providers/sync_provider.dart';
import '../services/sync/sync_models.dart';
import '../utils/format_utils.dart';
import '../widgets/book_card.dart';
import '../widgets/instant_read_modal.dart';
import '../widgets/remote_book_card.dart';
import '../widgets/series_card.dart';
import 'synced_reader_screen.dart';
import '../l10n/l10n.dart';
import '../utils/desktop_layout.dart';

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
  final FocusNode _searchFocus = FocusNode();
  LibraryViewMode _viewMode = LibraryViewMode.series;
  SeriesItem? _selectedSeries;

  /// Selected book ids (long press, or Ctrl + click on PC).
  final Set<String> _selection = {};
  bool get _selecting => _selection.isNotEmpty;
  bool get _ctrlPressed => HardwareKeyboard.instance.isControlPressed;

  ServerProfile? _seriesServer;
  List<RemoteFile> _remoteSeriesFiles = [];
  bool _isLoadingRemoteSeries = false;

  bool get _isSearching => _searchController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
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
      final srv = serverProvider.servers
          .where((s) => s.id == serverBook!.serverId)
          .firstOrNull;
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => buildSyncedReaderScreen(book)),
    );
  }

  void _confirmDelete(BookItem book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteBookTitle),
        content: Text(l10n.deleteBookBody(book.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<LibraryProvider>().deleteBook(book.id);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _queueResumePrompt(LibraryProvider library) {
    final book = library.takeResumeSuggestion();
    if (book == null || book.currentPage <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            book.format == BookFormat.epub
                ? l10n.resumeAtChapter(book.title, book.currentPage + 1)
                : l10n.resumeAtPage(book.title, book.currentPage + 1),
          ),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: l10n.resume,
            onPressed: () => _openReader(book),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final library = context.watch<LibraryProvider>();

    // Forget selected books that no longer exist (deleted, synced away).
    _selection.removeWhere((id) => library.getBookById(id) == null);

    return PopScope(
      canPop: _selectedSeries == null && !_selecting,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() {
          if (_selecting) {
            _selection.clear();
          } else {
            _selectedSeries = null;
          }
        });
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyA, control: true): () =>
              setState(() =>
                  _selection.addAll(_visibleBooks(library).map((b) => b.id))),
          const SingleActivator(LogicalKeyboardKey.delete): () {
            if (_selecting) _confirmBulkDelete(library);
          },
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: _selectedSeries != null
                  ? _buildSeriesDetailView(context, library, theme)
                  : _buildMainLibraryView(context, library, theme),
            ),
            if (_selecting)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildSelectionBar(library, theme),
              ),
          ],
        ),
      ),
    );
  }

  List<BookItem> _visibleBooks(LibraryProvider library) =>
      _selectedSeries?.books ?? library.filteredBooks;

  void _toggleBook(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selection.remove(id)) _selection.add(id);
    });
  }

  bool _isSeriesSelected(SeriesItem series) =>
      series.books.isNotEmpty &&
      series.books.every((b) => _selection.contains(b.id));

  void _toggleSeries(SeriesItem series) {
    HapticFeedback.selectionClick();
    setState(() {
      final ids = series.books.map((b) => b.id);
      if (_isSeriesSelected(series)) {
        _selection.removeAll(ids);
      } else {
        _selection.addAll(ids);
      }
    });
  }

  Widget _bookCard(BookItem book, LibraryProvider library) {
    return BookCard(
      book: book,
      selected: _selecting ? _selection.contains(book.id) : null,
      onLongPress: () => _toggleBook(book.id),
      onTap: () {
        if (_selecting || _ctrlPressed) {
          _toggleBook(book.id);
        } else {
          _openReader(book);
        }
      },
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
  }

  Widget _buildSelectionBar(LibraryProvider library, ThemeData theme) {
    final selectedBooks =
        _selection.map(library.getBookById).whereType<BookItem>().toList();
    final allFavorite =
        selectedBooks.isNotEmpty && selectedBooks.every((b) => b.isFavorite);
    final allRead =
        selectedBooks.isNotEmpty && selectedBooks.every((b) => b.isCompleted);
    final compact = MediaQuery.sizeOf(context).width < 600;
    final ids = Set<String>.of(_selection);

    final secondary = <(IconData, String, VoidCallback)>[
      (
        allRead ? Icons.restart_alt_rounded : Icons.check_circle_outline,
        allRead ? l10n.markAsUnread : l10n.markAsRead,
        () => _runBulk(() => library.setBooksCompleted(ids, !allRead)),
      ),
      (
        allFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        allFavorite ? l10n.removeFromFavorites : l10n.addToFavorites,
        () => _runBulk(() => library.setBooksFavorite(ids, !allFavorite)),
      ),
    ];

    return Material(
      color: theme.colorScheme.primaryContainer,
      elevation: 3,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n.clearSelection,
                onPressed: () => setState(_selection.clear),
              ),
              Expanded(
                child: Text(
                  l10n.librarySelectionCount(_selection.length),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.select_all_rounded),
                tooltip: l10n.selectAll,
                onPressed: () => setState(() =>
                    _selection.addAll(_visibleBooks(library).map((b) => b.id))),
              ),
              if (!compact)
                for (final (icon, label, action) in secondary)
                  IconButton(
                      icon: Icon(icon), tooltip: label, onPressed: action),
              IconButton(
                icon: const Icon(Icons.drive_file_move_outline),
                tooltip: l10n.moveToSeries,
                onPressed: () => _moveSelection(library),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    color: theme.colorScheme.error),
                tooltip: l10n.delete,
                onPressed: () => _confirmBulkDelete(library),
              ),
              if (compact)
                PopupMenuButton<int>(
                  onSelected: (i) => secondary[i].$3(),
                  itemBuilder: (_) => [
                    for (var i = 0; i < secondary.length; i++)
                      PopupMenuItem(
                        value: i,
                        child: Row(children: [
                          Icon(secondary[i].$1, size: 20),
                          const SizedBox(width: 12),
                          Text(secondary[i].$2),
                        ]),
                      ),
                  ],
                ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runBulk(Future<void> Function() action) async {
    await action();
    if (mounted) setState(_selection.clear);
  }

  Future<void> _confirmBulkDelete(LibraryProvider library) async {
    final ids = Set<String>.of(_selection);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteSelectedTitle(ids.length)),
        content: Text(l10n.deleteSelectedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _runBulk(() => library.deleteBooks(ids));
    if (mounted && _selectedSeries != null) {
      final remaining = SeriesItem.groupFromBooks(library.books)
          .where((s) => s.name == _selectedSeries!.name)
          .firstOrNull;
      setState(() => _selectedSeries = remaining);
    }
  }

  Future<void> _moveSelection(LibraryProvider library) async {
    final ids = Set<String>.of(_selection);
    final names =
        SeriesItem.groupFromBooks(library.books).map((s) => s.name).toList();
    // '' = automatic series, null = cancelled.
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _MoveToSeriesDialog(
        initialName: _selectedSeries?.name,
        seriesNames: names,
      ),
    );
    if (result == null || !mounted) return;
    await _runBulk(() => library.moveBooksToSeries(ids, result));
    // The open series may have been emptied or renamed: go back to the list.
    if (mounted && _selectedSeries != null) {
      setState(() => _selectedSeries = null);
    }
  }

  Widget _buildMainLibraryView(
      BuildContext context, LibraryProvider library, ThemeData theme) {
    _queueResumePrompt(library);
    final books = library.filteredBooks;
    final allSeries = library.filteredSeries;
    final sync = context.watch<SyncProvider>();
    final wide = DesktopLayout.isWide(context);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            _searchFocus.requestFocus,
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _searchFocus.requestFocus,
        const SingleActivator(LogicalKeyboardKey.f5): library.loadLibrary,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: wide
              ? null
              : AppBar(
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
                      Flexible(
                        child: Text(
                          l10n.myLibrary,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (library.books.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.comicsCount(library.books.length),
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
                    if (sync.status == SyncStatus.syncing)
                      Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Tooltip(
                          message: l10n.syncInProgress,
                          child: Icon(Icons.cloud_sync_outlined, size: 18),
                        ),
                      ),
                    _buildSortMenu(library),
                  ],
                ),
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: wide
                        ? DesktopLayout.contentMaxWidth +
                            2 * (DesktopLayout.contentPadding - 16)
                        : 1350),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: wide ? DesktopLayout.contentPadding - 16 : 0),
                  child: Column(
                    children: [
                      if (wide)
                        _buildDesktopHeader(
                            library, allSeries, books, theme, sync),
                      if (library.books.isNotEmpty && !wide)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: _buildViewModeToggle(allSeries, books),
                        ),
                      if (!wide)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                          child: _buildSearchField(library, theme),
                        ),
                      Expanded(
                        child: _viewMode == LibraryViewMode.series
                            ? _buildSeriesListView(
                                context, library, allSeries, theme)
                            : _buildFlatBooksListView(
                                context, library, books, theme),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortMenu(LibraryProvider library) {
    return PopupMenuButton<LibrarySort>(
      icon: const Icon(Icons.sort_rounded),
      tooltip: l10n.sortBy,
      onSelected: (sort) => library.setSort(sort),
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: LibrarySort.lastRead,
          child: Text(l10n.lastRead),
        ),
        PopupMenuItem(
          value: LibrarySort.title,
          child: Text(l10n.titleAz),
        ),
        PopupMenuItem(
          value: LibrarySort.dateAdded,
          child: Text(l10n.dateAdded),
        ),
        PopupMenuItem(
          value: LibrarySort.progress,
          child: Text(l10n.progress),
        ),
      ],
    );
  }

  Widget _buildViewModeToggle(
      List<SeriesItem> allSeries, List<BookItem> books) {
    return SegmentedButton<LibraryViewMode>(
      segments: [
        ButtonSegment(
          value: LibraryViewMode.series,
          icon: const Icon(Icons.folder_special_rounded, size: 16),
          label: Text(l10n.seriesCount(allSeries.length)),
        ),
        ButtonSegment(
          value: LibraryViewMode.allBooks,
          icon: const Icon(Icons.auto_stories_rounded, size: 16),
          label: Text(l10n.volumesCount(books.length)),
        ),
      ],
      selected: {_viewMode},
      onSelectionChanged: (set) {
        setState(() {
          _viewMode = set.first;
        });
      },
    );
  }

  Widget _buildSearchField(LibraryProvider library, ThemeData theme) {
    return Container(
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
        focusNode: _searchFocus,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: l10n.searchLibraryHint,
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        onChanged: (val) {
          setState(() {
            library.setSearchQuery(val);
          });
        },
      ),
    );
  }

  /// One-line header used instead of the app bar on large windows.
  Widget _buildDesktopHeader(
      LibraryProvider library,
      List<SeriesItem> allSeries,
      List<BookItem> books,
      ThemeData theme,
      SyncProvider sync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
      child: Row(
        children: [
          Text(
            l10n.navLibrary,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 16),
          if (sync.status == SyncStatus.syncing)
            Tooltip(
              message: l10n.syncInProgress,
              child: const Icon(Icons.cloud_sync_outlined, size: 18),
            ),
          const Spacer(),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: _buildSearchField(library, theme),
            ),
          ),
          if (library.books.isNotEmpty) ...[
            const SizedBox(width: 12),
            _buildViewModeToggle(allSeries, books),
          ],
          const SizedBox(width: 4),
          _buildSortMenu(library),
        ],
      ),
    );
  }

  /// Up to three "continue reading" cards side by side on large windows.
  Widget _buildDesktopResumeRow(List<BookItem> books, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Text(
              l10n.continueReading,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: i < books.length
                      ? _buildResumeReadingHero(books[i], theme,
                          padding: const EdgeInsets.all(8), showLabel: false)
                      : const SizedBox.shrink(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesListView(BuildContext context, LibraryProvider library,
      List<SeriesItem> allSeries, ThemeData theme) {
    final recentBooks = library.recentBooks;
    final wide = DesktopLayout.isWide(context);

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
            child: _buildFilterChipsRow(context, library),
          ),
          if (wide &&
              recentBooks.isNotEmpty &&
              !_isSearching &&
              library.filter == LibraryFilter.all)
            SliverToBoxAdapter(
              child: _buildDesktopResumeRow(recentBooks, theme),
            ),
          if (!wide &&
              recentBooks.isNotEmpty &&
              !_isSearching &&
              library.filter == LibraryFilter.all)
            SliverToBoxAdapter(
              child: _buildResumeReadingHero(recentBooks.first, theme),
            ),
          if (!wide &&
              recentBooks.length > 1 &&
              !_isSearching &&
              library.filter == LibraryFilter.all) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Row(
                  children: [
                    Icon(Icons.history_rounded,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      l10n.recentlyOpened,
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
                  itemCount: recentBooks.length - 1,
                  itemBuilder: (context, index) {
                    final book = recentBooks[index + 1];
                    return Container(
                      width: 130,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      child: _bookCard(book, library),
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
                  Icon(Icons.collections_bookmark_rounded,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.myCollectionsCount(allSeries.length),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: wide ? 190 : 220,
                childAspectRatio: 0.68,
                crossAxisSpacing: wide ? 20 : 14,
                mainAxisSpacing: wide ? 20 : 14,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final series = allSeries[index];
                  return SeriesCard(
                    series: series,
                    selected: _selecting ? _isSeriesSelected(series) : null,
                    onLongPress: () => _toggleSeries(series),
                    onTap: () {
                      if (_selecting || _ctrlPressed) {
                        _toggleSeries(series);
                      } else {
                        _onSelectSeries(series);
                      }
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

  Widget _buildFlatBooksListView(BuildContext context, LibraryProvider library,
      List<BookItem> books, ThemeData theme) {
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
            child: _buildFilterChipsRow(context, library),
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
                  return _bookCard(book, library);
                },
                childCount: books.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesDetailView(
      BuildContext context, LibraryProvider library, ThemeData theme) {
    final series = _selectedSeries!;
    final nextLocalBook = series.nextToReadBook;
    final progressPercent = (series.overallProgress * 100).toInt();
    final downloadProvider = context.watch<DownloadProvider>();

    List<RemoteFile> undownloadedRemote = [];
    if (_seriesServer != null && _remoteSeriesFiles.isNotEmpty) {
      undownloadedRemote = _remoteSeriesFiles.where((rf) {
        if (rf.isDirectory || !rf.isSupportedBook) return false;
        if (library.getBookByServerPath(_seriesServer!.id, rf.path) != null) {
          return false;
        }
        final cleanRfName = p.basenameWithoutExtension(rf.name).toLowerCase();
        if (series.books.any((b) =>
            p.basenameWithoutExtension(b.originalFilename).toLowerCase() ==
                cleanRfName ||
            b.title.toLowerCase() == cleanRfName)) {
          return false;
        }
        return true;
      }).toList();
      undownloadedRemote.sort((a, b) => NaturalSort.compare(a.name, b.name));
    }

    final nextRemoteToDownload =
        undownloadedRemote.isNotEmpty ? undownloadedRemote.first : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: l10n.backToSeries,
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
              l10n.seriesProgress(
                  series.completedBooks, series.totalBooks, progressPercent),
              style: TextStyle(
                  fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          if (_seriesServer != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: l10n.checkNewVolumes,
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
                        theme.colorScheme.surfaceContainerHighest
                            .withAlpha(100),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: theme.colorScheme.primary.withAlpha(60)),
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
                                child: nextLocalBook.coverPath != null &&
                                        File(nextLocalBook.coverPath!)
                                            .existsSync()
                                    ? Image.file(File(nextLocalBook.coverPath!),
                                        fit: BoxFit.cover, cacheWidth: 200)
                                    : Container(
                                        color: theme.colorScheme.primary
                                            .withAlpha(30),
                                        child: Icon(Icons.menu_book,
                                            color: theme.colorScheme.primary),
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      nextLocalBook.progress > 0
                                          ? l10n.resumeUpper
                                          : l10n.nextVolumeToRead,
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
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    nextLocalBook.totalPages > 0
                                        ? (nextLocalBook.format ==
                                                    BookFormat.epub
                                                ? l10n.chapterProgressPercent
                                                : l10n.pageProgressPercent)(
                                            nextLocalBook.currentPage + 1,
                                            nextLocalBook.totalPages,
                                            (nextLocalBook.progress * 100)
                                                .toInt())
                                        : nextLocalBook.formatString,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            theme.colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () => _openReader(nextLocalBook),
                              icon: const Icon(Icons.play_arrow_rounded,
                                  size: 18),
                              label: Text(l10n.read),
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
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
                        theme.colorScheme.surfaceContainerHighest
                            .withAlpha(120),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFF59E0B).withAlpha(100)),
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
                            border: Border.all(
                                color: const Color(0xFFF59E0B).withAlpha(80)),
                          ),
                          child: const Center(
                            child: Icon(Icons.download_for_offline_rounded,
                                color: Color(0xFFF59E0B), size: 28),
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      l10n.nextVolumeOnServer,
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    FormatUtils.formatBytes(
                                        nextRemoteToDownload.size),
                                    style: TextStyle(
                                        fontSize: 10,
                                        color:
                                            theme.colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                nextRemoteToDownload.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                    ),
                                    icon: const Icon(Icons.download_rounded,
                                        size: 16),
                                    label: Text(l10n.download,
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      downloadProvider.enqueueDownload(
                                        server: _seriesServer!,
                                        remoteFile: nextRemoteToDownload,
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(l10n.downloadStarted(
                                              nextRemoteToDownload.name)),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                    ),
                                    icon: const Icon(Icons.visibility_rounded,
                                        size: 15),
                                    label: Text(l10n.readNow,
                                        style: TextStyle(fontSize: 11)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.searchingNextVolumes,
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant),
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
                  Icon(Icons.folder_open_rounded,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.downloadedVolumesCount(series.totalBooks),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
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
                  return _bookCard(book, library);
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
                    const Icon(Icons.cloud_download_rounded,
                        size: 18, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Text(
                      l10n.serverVolumesCount(undownloadedRemote.length),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (undownloadedRemote.length > 1)
                      FilledButton.icon(
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: Text(
                            l10n.downloadAllCount(undownloadedRemote.length),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        onPressed: () {
                          for (final f in undownloadedRemote) {
                            downloadProvider.enqueueDownload(
                              server: _seriesServer!,
                              remoteFile: f,
                            );
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n
                                  .volumesQueued(undownloadedRemote.length)),
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
                    final task =
                        downloadProvider.getTaskForRemotePath(remoteFile.path);

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
                            content:
                                Text(l10n.downloadingName(remoteFile.name)),
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

  Widget _buildFilterChipsRow(BuildContext context, LibraryProvider library) {
    // Keep the discovery controls in one predictable row on phones.  The
    // previous Wrap could take four rows, pushing the resume action below the
    // fold before the user reached any books.
    return Semantics(
      label: l10n.libraryFilters,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          spacing: 8,
          children: [
            _buildFilterChip(context, l10n.allCount(library.books.length),
                LibraryFilter.all, library),
            _buildFilterChip(
                context, l10n.favorites, LibraryFilter.favorites, library),
            _buildFilterChip(
                context, l10n.inProgress, LibraryFilter.inProgress, library),
            _buildFilterChip(
                context, l10n.unread, LibraryFilter.unread, library),
            _buildFilterChip(context, 'CBZ / CBR', LibraryFilter.cbz, library),
            _buildFilterChip(context, 'PDF', LibraryFilter.pdf, library),
            _buildFilterChip(
                context, l10n.epubNovels, LibraryFilter.epub, library),
            _buildFilterChip(
                context, l10n.finished, LibraryFilter.completed, library),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label,
      LibraryFilter filter, LibraryProvider library) {
    final isSelected = library.filter == filter;
    final theme = Theme.of(context);
    final iconColor = filter == LibraryFilter.favorites
        ? Colors.redAccent
        : isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant;
    return FilterChip(
      avatar: Icon(_filterIcon(filter), size: 16, color: iconColor),
      label: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (_) => library.setFilter(filter),
      showCheckmark: false,
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(90),
      selectedColor: theme.colorScheme.primary.withAlpha(45),
      side: BorderSide(
        color: isSelected
            ? theme.colorScheme.primary.withAlpha(150)
            : theme.colorScheme.outlineVariant.withAlpha(100),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  IconData _filterIcon(LibraryFilter filter) => switch (filter) {
        LibraryFilter.all => Icons.auto_stories_outlined,
        LibraryFilter.favorites => Icons.favorite_rounded,
        LibraryFilter.inProgress => Icons.menu_book_rounded,
        LibraryFilter.unread => Icons.markunread_outlined,
        LibraryFilter.cbz => Icons.collections_bookmark_outlined,
        LibraryFilter.pdf => Icons.picture_as_pdf_outlined,
        LibraryFilter.epub => Icons.menu_book_outlined,
        LibraryFilter.completed => Icons.check_circle_outline_rounded,
      };

  Widget _buildResumeReadingHero(BookItem book, ThemeData theme,
      {EdgeInsets padding = const EdgeInsets.fromLTRB(16, 8, 16, 8),
      bool showLabel = true}) {
    final progressPercent = (book.progress * 100).toInt();

    return Padding(
      padding: padding,
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
          border:
              Border.all(color: theme.colorScheme.outlineVariant.withAlpha(60)),
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
                          ? Image.file(File(book.coverPath!),
                              fit: BoxFit.cover, cacheWidth: 200)
                          : Container(
                              color: theme.colorScheme.primary.withAlpha(30),
                              child: Icon(Icons.auto_stories_rounded,
                                  color: theme.colorScheme.primary),
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
                            if (showLabel)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.primary.withAlpha(40),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l10n.continueReading,
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
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          book.totalPages > 0
                              ? (book.format == BookFormat.epub
                                      ? l10n.chapterOfTotal
                                      : l10n.pageOfTotal)(
                                  book.currentPage + 1, book.totalPages)
                              : book.formatString,
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: book.progress.clamp(0.0, 1.0),
                            minHeight: 4,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
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
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 22),
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
            Text(
              l10n.libraryEmpty,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.libraryEmptyBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            if (widget.onNavigateTab != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => widget.onNavigateTab?.call(1),
                icon: const Icon(Icons.dns_rounded, size: 18),
                label: Text(l10n.exploreServers),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => widget.onNavigateTab?.call(2),
                icon: const Icon(Icons.folder_open_rounded, size: 18),
                label: Text(l10n.importFromPhone),
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
            Text(
              l10n.noSearchResults,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noSearchResultsBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks for the destination series of the selected books.
/// Pops '' for the automatic series, the chosen name, or null when cancelled.
class _MoveToSeriesDialog extends StatefulWidget {
  const _MoveToSeriesDialog({this.initialName, required this.seriesNames});

  final String? initialName;
  final List<String> seriesNames;

  @override
  State<_MoveToSeriesDialog> createState() => _MoveToSeriesDialogState();
}

class _MoveToSeriesDialogState extends State<_MoveToSeriesDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(l10n.moveToSeries),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.seriesNameLabel),
              onSubmitted: (v) => Navigator.pop(context, v.trim()),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final name in widget.seriesNames)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.collections_bookmark_outlined),
                      title: Text(name),
                      onTap: () => Navigator.pop(context, name),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, ''),
          child: Text(l10n.automaticSeries),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(l10n.move),
        ),
      ],
    );
  }
}
