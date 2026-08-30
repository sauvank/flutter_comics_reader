import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book_item.dart';
import '../models/download_task.dart';
import '../models/remote_file.dart';
import '../models/server_profile.dart';
import '../providers/download_provider.dart';
import '../providers/library_provider.dart';
import '../screens/cbz_reader_screen.dart';
import '../screens/epub_reader_screen.dart';
import '../screens/pdf_reader_screen.dart';

class InstantReadModal extends StatefulWidget {
  final ServerProfile server;
  final RemoteFile file;

  const InstantReadModal({
    super.key,
    required this.server,
    required this.file,
  });

  static Future<void> show(
    BuildContext context, {
    required ServerProfile server,
    required RemoteFile file,
  }) async {
    final libraryProvider = context.read<LibraryProvider>();
    final existingBook = libraryProvider.getBookByServerPath(server.id, file.path);

    if (existingBook != null) {
      _openReader(context, existingBook);
      return;
    }

    // Start instant download modal and await the result
    final downloadedBook = await showModalBottomSheet<BookItem>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InstantReadModal(server: server, file: file),
    );

    if (downloadedBook != null && context.mounted) {
      _openReader(context, downloadedBook);
    }
  }

  static void _openReader(BuildContext context, BookItem book) {
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

  @override
  State<InstantReadModal> createState() => _InstantReadModalState();
}

class _InstantReadModalState extends State<InstantReadModal> {
  bool _hasTriggeredDownload = false;
  bool _hasClosedModal = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final libraryProvider = context.read<LibraryProvider>();
      final existingBook = libraryProvider.getBookByServerPath(widget.server.id, widget.file.path);
      if (existingBook != null) {
        _hasClosedModal = true;
        Navigator.of(context).pop(existingBook);
        return;
      }
      _startDownload();
    });
  }

  void _startDownload() {
    if (_hasTriggeredDownload) return;
    _hasTriggeredDownload = true;

    final downloadProvider = context.read<DownloadProvider>();
    downloadProvider.enqueueDownload(
      server: widget.server,
      remoteFile: widget.file,
    );
  }

  void _checkCompletion(DownloadTask? task) {
    if (task != null && task.status == DownloadStatus.completed && !_hasClosedModal) {
      _hasClosedModal = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        final libraryProvider = context.read<LibraryProvider>();
        await libraryProvider.loadLibrary();

        BookItem? book = libraryProvider.getBookByServerPath(widget.server.id, widget.file.path);
        book ??= libraryProvider.getBookById(task.bookId);
        if (book == null && libraryProvider.books.isNotEmpty) {
          book = libraryProvider.books.first;
        }

        if (mounted) {
          Navigator.of(context).pop(book);
        }
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final downloadProvider = context.watch<DownloadProvider>();
    final task = downloadProvider.getTaskForRemotePath(widget.file.path);

    _checkCompletion(task);

    final progress = task?.progress ?? 0.0;
    final speed = task?.speedString ?? '';
    final received = task?.downloadedBytes ?? 0;
    final total = (task?.totalBytes ?? 0) > 0 ? task!.totalBytes : widget.file.size;
    final isFailed = task?.status == DownloadStatus.failed;
    final isConverting = widget.file.format == BookFormat.pdf && progress >= 0.85;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isFailed
                      ? Colors.redAccent.withAlpha(30)
                      : isConverting
                          ? const Color(0xFF8B5CF6).withAlpha(40)
                          : theme.colorScheme.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isFailed
                      ? Icons.error_outline_rounded
                      : isConverting
                          ? Icons.auto_fix_high_rounded
                          : Icons.menu_book_rounded,
                  color: isFailed
                      ? Colors.redAccent
                      : isConverting
                          ? const Color(0xFF8B5CF6)
                          : theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFailed
                          ? 'Échec du téléchargement'
                          : isConverting
                              ? 'Conversion HD en CBZ (Mode BD)...'
                              : 'Téléchargement de votre BD...',
                      style: TextStyle(
                        fontSize: 12,
                        color: isFailed ? Colors.redAccent : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Progress Bar or Error View
          if (isFailed) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withAlpha(50)),
              ),
              child: Text(
                task?.errorMessage ?? 'Une erreur réseau est survenue.',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          ] else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress > 0 ? progress : null,
                minHeight: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isConverting ? const Color(0xFF8B5CF6) : theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task?.statusDescription ??
                        (isConverting
                            ? 'Conversion HD en cours...'
                            : '${(progress * 100).toInt()}% • ${_formatBytes(received)} / ${_formatBytes(total)}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                if (task?.etaString != null && !isConverting)
                  Text(
                    task!.etaString!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  )
                else if (speed.isNotEmpty && !isConverting)
                  Text(
                    speed,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              if (!isFailed)
                TextButton(
                  onPressed: () {
                    if (task != null) {
                      downloadProvider.cancelDownload(task.id);
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text('Annuler', style: TextStyle(color: Colors.redAccent)),
                ),
              const Spacer(),
              if (isFailed && task != null) ...[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    downloadProvider.retryDownload(task.id, widget.server);
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Réessayer'),
                ),
              ] else ...[
                FilledButton.tonalIcon(
                  onPressed: () {
                    // Close modal and let download/conversion continue in background
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.download_done_rounded, size: 18),
                  label: const Text('Arrière-plan'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
