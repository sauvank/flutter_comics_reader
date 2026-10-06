import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../models/book_item.dart';
import '../services/scan_cover_service.dart';

/// A book found on the device during a scan, not imported yet.
class ScannedBook {
  const ScannedBook({
    required this.path,
    required this.size,
    required this.alreadyInLibrary,
  });

  final String path;
  final int size;
  final bool alreadyInLibrary;

  BookFormat get format => BookItem.formatFromExtension(path);
  String get title =>
      p.basenameWithoutExtension(path).replaceAll('_', ' ').trim();
}

enum _ScanFilter { all, comics, epub, pdf }

class _ScanGroup {
  _ScanGroup(this.directory, this.location, this.books);

  final String directory;

  /// Parent folders relative to the scanned root, e.g. `Download › BD`.
  final String location;
  final List<ScannedBook> books;

  String get name => p.basename(directory);

  /// Drops the series name repeated in each file name ("Asterix - T01" → "T01").
  String titleOf(ScannedBook book) {
    final title = book.title;
    if (title.length <= name.length ||
        !title.toLowerCase().startsWith(name.toLowerCase())) {
      return title;
    }
    final rest = title
        .substring(name.length)
        .replaceFirst(RegExp(r'^[\s\-–—_:.,#]+'), '');
    return rest.isEmpty ? title : rest;
  }

  bool get isFullyImported => books.every((b) => b.alreadyInLibrary);

  bool get hasOnlyPdf => books.every((b) => b.format == BookFormat.pdf);
}

/// Full-screen picker shown after a device scan.
///
/// Books are grouped by folder (often one series per folder) and shown as a
/// cover grid. Pops with the selected paths, or `null` when cancelled.
class DeviceScanResultsScreen extends StatefulWidget {
  const DeviceScanResultsScreen({
    super.key,
    required this.books,
    required this.rootPath,
  });

  final List<ScannedBook> books;

  /// Storage root that was scanned, hidden from folder labels.
  final String rootPath;

  /// Reads sizes and matches already imported books by filename and size,
  /// which is cheap enough for a scan of the whole device.
  static Future<List<ScannedBook>> describe(
    List<String> paths,
    List<BookItem> library,
  ) async {
    final known = {
      for (final book in library)
        if (book.fileSize > 0) '${book.originalFilename}|${book.fileSize}',
    };
    return Future.wait(paths.map((path) async {
      var size = 0;
      try {
        size = await File(path).length();
      } catch (_) {}
      return ScannedBook(
        path: path,
        size: size,
        alreadyInLibrary: known.contains('${p.basename(path)}|$size'),
      );
    }));
  }

  @override
  State<DeviceScanResultsScreen> createState() =>
      _DeviceScanResultsScreenState();
}

class _DeviceScanResultsScreenState extends State<DeviceScanResultsScreen> {
  late final List<_ScanGroup> _groups;
  final _selected = <String>{};
  _ScanFilter _filter = _ScanFilter.all;

  @override
  void initState() {
    super.initState();
    final byDirectory = <String, List<ScannedBook>>{};
    for (final book in widget.books) {
      byDirectory.putIfAbsent(p.dirname(book.path), () => []).add(book);
    }
    _groups = [
      for (final entry in byDirectory.entries)
        _ScanGroup(entry.key, _labelFor(entry.key), entry.value),
    ]..sort((a, b) {
        // Folders already imported, then loose PDFs (invoices, manuals…)
        // are the least likely picks: list them last.
        if (a.isFullyImported != b.isFullyImported) {
          return a.isFullyImported ? 1 : -1;
        }
        if (a.hasOnlyPdf != b.hasOnlyPdf) return a.hasOnlyPdf ? 1 : -1;
        return a.directory.toLowerCase().compareTo(b.directory.toLowerCase());
      });
    for (final group in _groups) {
      if (group.hasOnlyPdf) continue;
      for (final book in group.books) {
        if (!book.alreadyInLibrary) _selected.add(book.path);
      }
    }
  }

  String _labelFor(String directory) {
    final parent = p.dirname(directory);
    final relative = p.relative(parent, from: widget.rootPath);
    if (relative == '.' || relative.startsWith('..')) return '';
    return p.split(relative).join(' › ');
  }

  bool _matches(ScannedBook book) => switch (_filter) {
        _ScanFilter.all => true,
        _ScanFilter.comics =>
          book.format != BookFormat.pdf && book.format != BookFormat.epub,
        _ScanFilter.epub => book.format == BookFormat.epub,
        _ScanFilter.pdf => book.format == BookFormat.pdf,
      };

  int _countFor(_ScanFilter filter) {
    final previous = _filter;
    _filter = filter;
    final count = widget.books.where(_matches).length;
    _filter = previous;
    return count;
  }

  void _toggle(ScannedBook book) {
    if (book.alreadyInLibrary) return;
    setState(() {
      if (!_selected.remove(book.path)) _selected.add(book.path);
    });
  }

  void _setAll(Iterable<ScannedBook> books, bool selected) {
    setState(() {
      for (final book in books) {
        if (book.alreadyInLibrary) continue;
        if (selected) {
          _selected.add(book.path);
        } else {
          _selected.remove(book.path);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedSize = widget.books
        .where((b) => _selected.contains(b.path))
        .fold<int>(0, (sum, b) => sum + b.size);
    final selectable = widget.books.where((b) => !b.alreadyInLibrary);
    final allSelected = selectable.every((b) => _selected.contains(b.path));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.books.length > 1
            ? '${widget.books.length} livres'
            : '${widget.books.length} livre'),
        actions: [
          TextButton(
            onPressed: selectable.isEmpty
                ? null
                : () => _setAll(selectable, !allSelected),
            child: Text(allSelected ? 'Aucun' : 'Tout'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        const padding = 16.0;
        const spacing = 10.0;
        final columns =
            math.max(3, (constraints.maxWidth - 2 * padding + spacing) ~/ 140);
        final tileWidth =
            (constraints.maxWidth - 2 * padding - (columns - 1) * spacing) /
                columns;
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildFilters()),
            for (final group in _groups)
              ..._buildGroup(group, columns, tileWidth, spacing, padding),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        );
      }),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selected.length} sélectionné(s)',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _formatSize(selectedSize),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _selected.isEmpty
                    ? null
                    : () => Navigator.of(context)
                        .pop(_selected.toList(growable: false)),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Importer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    const labels = {
      _ScanFilter.all: 'Tous',
      _ScanFilter.comics: 'BD',
      _ScanFilter.epub: 'EPUB',
      _ScanFilter.pdf: 'PDF',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          for (final filter in _ScanFilter.values)
            if (filter == _ScanFilter.all || _countFor(filter) > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('${labels[filter]} ${_countFor(filter)}'),
                  selected: _filter == filter,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _filter = filter),
                ),
              ),
        ],
      ),
    );
  }

  List<Widget> _buildGroup(
    _ScanGroup group,
    int columns,
    double tileWidth,
    double spacing,
    double padding,
  ) {
    final books = group.books.where(_matches).toList(growable: false);
    if (books.isEmpty) return const [];
    final theme = Theme.of(context);
    final selectable = books.where((b) => !b.alreadyInLibrary).toList();
    final allSelected = selectable.every((b) => _selected.contains(b.path));
    final size = books.fold<int>(0, (sum, b) => sum + b.size);

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(padding, 18, 8, 8),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      [
                        if (group.location.isNotEmpty) group.location,
                        '${books.length} · ${_formatSize(size)}',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (selectable.isNotEmpty)
                TextButton(
                  onPressed: () => _setAll(selectable, !allSelected),
                  child: Text(allSelected ? 'Tout retirer' : 'Tout ajouter'),
                ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: 14,
            // 2:3 cover plus one title line.
            mainAxisExtent: tileWidth * 1.5 + 26,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final book = books[index];
              return _ScanBookTile(
                key: ValueKey(book.path),
                book: book,
                title: group.titleOf(book),
                selected: _selected.contains(book.path),
                onTap: () => _toggle(book),
              );
            },
            childCount: books.length,
          ),
        ),
      ),
    ];
  }
}

class _ScanBookTile extends StatelessWidget {
  const _ScanBookTile({
    super.key,
    required this.book,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final ScannedBook book;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dimmed = book.alreadyInLibrary || !selected;

    return Semantics(
      checked: selected,
      enabled: !book.alreadyInLibrary,
      label: title,
      child: InkWell(
        onTap: book.alreadyInLibrary ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: book.alreadyInLibrary ? 0.45 : (dimmed ? 0.7 : 1),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? scheme.primary : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _ScanCover(book: book),
                        Positioned(
                          left: 6,
                          bottom: 6,
                          child: _FormatBadge(book: book),
                        ),
                        if (!book.alreadyInLibrary)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: _SelectionMark(selected: selected),
                          ),
                        if (book.alreadyInLibrary)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.75),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: const Text(
                                'Déjà importé',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? scheme.primary : Colors.black.withValues(alpha: 0.45),
        border: Border.all(
          color: selected ? scheme.surface : Colors.white,
          width: 2,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: 15, color: scheme.onPrimary)
          : null,
    );
  }
}

class _ScanCover extends StatelessWidget {
  const _ScanCover({required this.book});

  final ScannedBook book;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: ScanCoverService.coverFor(book.path),
      builder: (context, snapshot) {
        final path = snapshot.data;
        if (path != null) {
          return Image.file(
            File(path),
            fit: BoxFit.cover,
            cacheWidth: 300,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => _placeholder(context, false),
          );
        }
        return _placeholder(
            context, snapshot.connectionState != ConnectionState.done);
      },
    );
  }

  Widget _placeholder(BuildContext context, bool loading) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              book.title,
              maxLines: 4,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

class _FormatBadge extends StatelessWidget {
  const _FormatBadge({required this.book});

  final ScannedBook book;

  @override
  Widget build(BuildContext context) {
    final label = p.extension(book.path).replaceFirst('.', '').toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

String _formatSize(int bytes) {
  if (bytes <= 0) return '0 Mo';
  final mb = bytes / (1024 * 1024);
  if (mb >= 1024) {
    return '${(mb / 1024).toStringAsFixed(1).replaceAll('.', ',')} Go';
  }
  if (mb >= 10) return '${mb.round()} Mo';
  if (mb >= 0.1) return '${mb.toStringAsFixed(1).replaceAll('.', ',')} Mo';
  return '${(bytes / 1024).ceil()} Ko';
}
