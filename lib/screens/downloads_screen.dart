import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/download_task.dart';
import '../providers/download_provider.dart';
import '../providers/library_provider.dart';
import '../providers/server_provider.dart';
import '../utils/format_utils.dart';
import 'cbz_reader_screen.dart';
import 'pdf_reader_screen.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final downloadProvider = context.watch<DownloadProvider>();
    final tasks = downloadProvider.tasks;

    final activeTasks = downloadProvider.activeTasks;
    final otherTasks = tasks.where((t) => !activeTasks.contains(t)).toList();

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
              child: Icon(Icons.download_rounded, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Téléchargements'),
          ],
        ),
        actions: [
          if (otherTasks.isNotEmpty)
            TextButton.icon(
              onPressed: () => downloadProvider.clearCompleted(),
              icon: const Icon(Icons.cleaning_services_rounded, size: 16),
              label: const Text('Nettoyer', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
      body: tasks.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_done_outlined, size: 56, color: Colors.grey.shade600),
                    const SizedBox(height: 16),
                    const Text('Aucun téléchargement en cours',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Les fichiers que vous téléchargez depuis votre serveur local apparaîtront ici avec leur progression.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // Active Section
                if (activeTasks.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'En cours (${activeTasks.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  for (final task in activeTasks)
                    _buildActiveTaskCard(context, task, downloadProvider, theme),
                  const SizedBox(height: 16),
                ],

                // Finished & Other Section
                if (otherTasks.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Historique (${otherTasks.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
                    ),
                  ),
                  for (final task in otherTasks)
                    _buildCompletedTaskCard(context, task, downloadProvider, theme),
                ],
              ],
            ),
    );
  }

  Widget _buildActiveTaskCard(
    BuildContext context,
    DownloadTask task,
    DownloadProvider provider,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.redAccent),
                onPressed: () => provider.cancelDownload(task.id),
                tooltip: 'Annuler',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: task.progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task.statusDescription ??
                      '${(task.progress * 100).toInt()}% • ${FormatUtils.formatBytes(task.receivedBytes)} / ${FormatUtils.formatBytes(task.totalBytes)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              if (task.etaString != null)
                Text(
                  task.etaString!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                )
              else if (task.speedBytesPerSec > 0)
                Text(
                  FormatUtils.formatSpeed(task.speedBytesPerSec),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTaskCard(
    BuildContext context,
    DownloadTask task,
    DownloadProvider provider,
    ThemeData theme,
  ) {
    final isSuccess = task.status == DownloadStatus.completed;
    final isFailed = task.status == DownloadStatus.failed;
    final isCancelled = task.status == DownloadStatus.cancelled;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSuccess
                  ? Colors.green.withAlpha(30)
                  : Colors.red.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isSuccess
                  ? Icons.check_circle_outline
                  : isCancelled
                      ? Icons.cancel_outlined
                      : Icons.error_outline,
              size: 20,
              color: isSuccess ? Colors.green : Colors.redAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  isSuccess
                      ? 'Terminé • ${FormatUtils.formatBytes(task.totalBytes)}'
                      : isCancelled
                          ? 'Annulé'
                          : 'Échec: ${task.errorMessage ?? "Erreur réseau"}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSuccess
                        ? theme.colorScheme.onSurfaceVariant
                        : Colors.red.shade300,
                  ),
                ),
              ],
            ),
          ),
          if (isSuccess) ...[
            FilledButton.tonal(
              onPressed: () {
                final library = context.read<LibraryProvider>();
                final book = library.getBookById(task.bookId);
                if (book != null) {
                  if (book.format.name == 'pdf') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PdfReaderScreen(book: book)),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => CbzReaderScreen(book: book)),
                    );
                  }
                }
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Lire', style: TextStyle(fontSize: 12)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
              tooltip: 'Supprimer du stockage',
              onPressed: () async {
                final library = context.read<LibraryProvider>();
                await library.deleteBook(task.bookId);
              },
            ),
          ]
          else if (isFailed || isCancelled)
            IconButton(
              icon: const Icon(Icons.replay_rounded, size: 20),
              onPressed: () {
                final serverProvider = context.read<ServerProvider>();
                final server = serverProvider.servers.firstWhere(
                  (s) => s.id == task.serverId,
                  orElse: () => serverProvider.activeServer!,
                );
                provider.retryDownload(task.id, server);
              },
              tooltip: 'Réessayer',
            ),
        ],
      ),
    );
  }
}
