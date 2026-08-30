import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book_item.dart';
import '../providers/library_provider.dart';
import '../screens/cbz_reader_screen.dart';
import '../services/pdf_converter_service.dart';

class PdfToCbzDialog extends StatefulWidget {
  final BookItem book;

  const PdfToCbzDialog({super.key, required this.book});

  static Future<void> show(BuildContext context, {required BookItem book}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PdfToCbzDialog(book: book),
    );
  }

  @override
  State<PdfToCbzDialog> createState() => _PdfToCbzDialogState();
}

class _PdfToCbzDialogState extends State<PdfToCbzDialog> {
  StreamSubscription<PdfConverterProgress>? _sub;
  PdfConverterProgress? _progress;
  bool _isConverting = false;
  BookItem? _convertedBook;
  bool _isCompleted = false;
  String? _errorMessage;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _startConversion() {
    setState(() {
      _isConverting = true;
      _errorMessage = null;
      _isCompleted = false;
      _convertedBook = null;
    });

    final stream = PdfConverterService().convertPdfToCbz(
      pdfFilePath: widget.book.localPath,
    );

    _sub = stream.listen(
      (prog) {
        setState(() {
          _progress = prog;
          if (prog.convertedBook != null) {
            _convertedBook = prog.convertedBook;
          }
          if (prog.progress >= 1.0) {
            _isConverting = false;
            _isCompleted = true;
          }
        });

        if (prog.progress >= 1.0 && mounted) {
          context.read<LibraryProvider>().loadLibrary();
        }
      },
      onError: (err) {
        setState(() {
          _isConverting = false;
          _errorMessage = '$err';
        });
      },
    );
  }

  void _openConvertedBook() async {
    final library = context.read<LibraryProvider>();
    BookItem? targetBook = _convertedBook;

    if (targetBook == null) {
      await library.loadLibrary();
      targetBook = library.books.firstWhere(
        (b) => b.title == widget.book.title && b.format == BookFormat.cbz,
        orElse: () => widget.book,
      );
    }

    // Remove the old PDF entry from library since we now have the CBZ version
    if (widget.book.format == BookFormat.pdf && targetBook.id != widget.book.id) {
      await library.deleteBook(widget.book.id);
    }

    await library.loadLibrary();

    if (mounted) {
      Navigator.of(context).pop(); // Close dialog
      // Use pushReplacement to replace the current PDF reader with CBZ reader
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CbzReaderScreen(book: targetBook!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (_progress?.progress ?? 0.0).clamp(0.0, 1.0);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withAlpha(40),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.transform_rounded, color: Color(0xFF8B5CF6), size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Convertir en BD (CBZ)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 12),

            // Benefits explanation banner
            if (!_isConverting && !_isCompleted)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.bolt_rounded, size: 16, color: Colors.amber),
                        SizedBox(width: 6),
                        Text('Avantages du format CBZ :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text('• Rendu beaucoup plus rapide et fluide', style: TextStyle(fontSize: 11)),
                    Text('• Mode Manga (sens droit-à-gauche) disponible', style: TextStyle(fontSize: 11)),
                    Text('• Mode Webtoon (défilement continu) fluide', style: TextStyle(fontSize: 11)),
                    Text('• Moins de consommation mémoire et batterie', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),

            // Progress status
            if (_isConverting) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: percent > 0 ? percent : null,
                color: const Color(0xFF8B5CF6),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _progress?.statusText ?? 'Conversion en cours...',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                  Text(
                    '${(percent * 100).toInt()}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF8B5CF6)),
                  ),
                ],
              ),
            ],

            // Completed banner
            if (_isCompleted) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Conversion réussie !', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Votre BD est disponible au format CBZ haute définition.', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Error banner
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_isConverting && !_isCompleted) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
            onPressed: _startConversion,
            icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
            label: const Text('Convertir'),
          ),
        ] else if (_isCompleted) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
            onPressed: _openConvertedBook,
            icon: const Icon(Icons.auto_stories_rounded, size: 16),
            label: const Text('Lire en mode BD (CBZ)'),
          ),
        ] else ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Veuillez patienter...', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ],
    );
  }
}
