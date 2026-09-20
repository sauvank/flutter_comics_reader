import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../models/book_item.dart';
import '../providers/library_provider.dart';
import 'cbz_reader_screen.dart';
import 'epub_reader_screen.dart';
import 'pdf_reader_screen.dart';

/// Dedicated entry point for books already stored on the current device.
class DeviceFilesScreen extends StatefulWidget {
  const DeviceFilesScreen({super.key});

  @override
  State<DeviceFilesScreen> createState() => _DeviceFilesScreenState();
}

class _DeviceFilesScreenState extends State<DeviceFilesScreen> {
  bool _importing = false;

  Future<void> _chooseDirectoryAndScan() async {
    final directoryPath = await FilePicker.getDirectoryPath();
    if (directoryPath == null || !mounted) return;

    setState(() => _importing = true);
    try {
      final paths = await context
          .read<LibraryProvider>()
          .scanLocalDirectory(directoryPath);
      if (!mounted) return;
      if (paths.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Aucun livre compatible dans ce dossier.')),
        );
        return;
      }
      final selectedPaths = await _chooseBooksToImport(paths);
      if (selectedPaths == null || selectedPaths.isEmpty || !mounted) return;

      final result =
          await context.read<LibraryProvider>().importLocalFiles(selectedPaths);
      if (!mounted) return;
      final skipped = result.skipped == 0
          ? ''
          : ' · ${result.skipped} déjà présent(s) ou ignoré(s)';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.imported} livre(s) ajouté(s)$skipped'),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import impossible : $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<List<String>?> _chooseBooksToImport(List<String> paths) async {
    final selectedPaths = paths.toSet();
    return showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${paths.length} livre(s) trouvé(s)'),
          content: SizedBox(
            width: 520,
            height: MediaQuery.sizeOf(context).height * 0.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Décochez les fichiers que vous ne voulez pas garder.'),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: paths.length,
                    itemBuilder: (_, index) {
                      final path = paths[index];
                      return CheckboxListTile(
                        value: selectedPaths.contains(path),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          p.basename(path),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          p.dirname(path),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onChanged: (selected) => setDialogState(() {
                          if (selected ?? false) {
                            selectedPaths.add(path);
                          } else {
                            selectedPaths.remove(path);
                          }
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: selectedPaths.isEmpty
                  ? null
                  : () => Navigator.of(dialogContext)
                      .pop(selectedPaths.toList(growable: false)),
              child: Text('Importer (${selectedPaths.length})'),
            ),
          ],
        ),
      ),
    );
  }

  void _openReader(BookItem book) {
    final Widget screen;
    if (book.format == BookFormat.pdf) {
      screen = PdfReaderScreen(book: book);
    } else if (book.format == BookFormat.epub) {
      screen = EpubReaderScreen(book: book);
    } else {
      screen = CbzReaderScreen(book: book);
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final localBooks = library.books
        .where((book) => book.serverId == null)
        .toList()
      ..sort((a, b) => b.addedDate.compareTo(a.addedDate));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Fichiers de l’appareil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.folder_copy_rounded,
                    size: 38, color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(height: 12),
                Text(
                  'Ajouter des BD depuis cet appareil',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choisissez un dossier : ses sous-dossiers sont analysés automatiquement. Vous choisissez ensuite les livres à garder.',
                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _importing ? null : _chooseDirectoryAndScan,
                  icon: _importing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.manage_search_rounded),
                  label: Text(_importing
                      ? 'Analyse des fichiers…'
                      : 'Choisir un dossier'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Fichiers ajoutés (${localBooks.length})',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (localBooks.isEmpty)
            const ListTile(
              leading: Icon(Icons.folder_open_outlined),
              title: Text('Aucun fichier ajouté'),
              subtitle: Text('Choisissez un dossier pour analyser ses livres.'),
            )
          else
            for (final book in localBooks)
              Card(
                child: ListTile(
                  leading: Icon(_iconFor(book.format)),
                  title: Text(book.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                      '${book.formatString} · Page ${book.currentPage + 1}/${book.totalPages}'),
                  trailing: const Icon(Icons.play_arrow_rounded),
                  onTap: () => _openReader(book),
                ),
              ),
        ],
      ),
    );
  }

  IconData _iconFor(BookFormat format) => switch (format) {
        BookFormat.pdf => Icons.picture_as_pdf_rounded,
        BookFormat.epub => Icons.menu_book_rounded,
        _ => Icons.auto_stories_rounded,
      };
}
