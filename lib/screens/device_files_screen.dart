import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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

  Future<void> _scanFiles() async {
    final selection = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['cbz', 'cbr', 'zip', 'pdf', 'epub'],
      allowMultiple: true,
      withData: false,
    );
    final paths = selection?.paths.whereType<String>().toList() ?? const [];
    if (paths.isEmpty || !mounted) return;

    setState(() => _importing = true);
    try {
      final result =
          await context.read<LibraryProvider>().importLocalFiles(paths);
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
                  'Seuls les fichiers lisibles sont affichés : CBZ, CBR, ZIP, PDF et EPUB.',
                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _importing ? null : _scanFiles,
                  icon: _importing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.manage_search_rounded),
                  label: Text(_importing
                      ? 'Analyse des fichiers…'
                      : 'Scanner les fichiers'),
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
              subtitle:
                  Text('Utilisez « Scanner les fichiers » pour en choisir.'),
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
