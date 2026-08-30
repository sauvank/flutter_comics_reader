import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../models/book_item.dart';
import '../models/download_task.dart';
import '../models/remote_file.dart';
import '../utils/format_utils.dart';

class RemoteFileTile extends StatelessWidget {
  final RemoteFile file;
  final bool isDownloaded;
  final DownloadTask? downloadTask;
  final VoidCallback onTap;
  final VoidCallback onDownload;
  final VoidCallback? onCancelDownload;

  const RemoteFileTile({
    super.key,
    required this.file,
    required this.isDownloaded,
    this.downloadTask,
    required this.onTap,
    required this.onDownload,
    this.onCancelDownload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(25),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: onTap,
        leading: _buildLeading(theme),
        title: Text(
          file.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: file.isDirectory ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
            color: file.isDirectory ? theme.colorScheme.onSurface : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: file.isDirectory
            ? const Text('Dossier', style: TextStyle(fontSize: 12, color: Colors.grey))
            : Row(
                children: [
                  if (file.size > 0) ...[
                    Text(FormatUtils.formatBytes(file.size), style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                  ],
                  if (file.modified != null)
                    Text(
                      FormatUtils.formatRelativeDate(file.modified!),
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
        trailing: _buildTrailing(theme),
      ),
    );
  }

  Widget _buildLeading(ThemeData theme) {
    if (file.isDirectory) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withAlpha(30),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.folder_rounded,
          color: theme.colorScheme.primary,
          size: 22,
        ),
      );
    }

    final format = file.format;
    Color color = Colors.grey;
    IconData icon = Icons.insert_drive_file;

    switch (format) {
      case BookFormat.cbz:
      case BookFormat.cbr:
      case BookFormat.zip:
        color = const Color(0xFF8B5CF6);
        icon = Icons.auto_stories;
        break;
      case BookFormat.pdf:
        color = const Color(0xFFEF4444);
        icon = Icons.picture_as_pdf;
        break;
      case BookFormat.epub:
        color = const Color(0xFFF59E0B);
        icon = Icons.menu_book;
        break;
      default:
        color = Colors.blueGrey;
        icon = Icons.insert_drive_file_outlined;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildTrailing(ThemeData theme) {
    if (file.isDirectory) {
      return const Icon(Icons.chevron_right, color: Colors.grey, size: 20);
    }

    if (!file.isSupportedBook) {
      return const SizedBox.shrink();
    }

    if (isDownloaded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withAlpha(80)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 14),
            SizedBox(width: 4),
            Text(
              'Téléchargé',
              style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    if (downloadTask != null) {
      if (downloadTask!.status == DownloadStatus.downloading) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularPercentIndicator(
              radius: 16.0,
              lineWidth: 3.0,
              percent: downloadTask!.progress.clamp(0.0, 1.0),
              center: Text(
                '${(downloadTask!.progress * 100).toInt()}%',
                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
              ),
              progressColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.outlineVariant.withAlpha(60),
            ),
            if (onCancelDownload != null) ...[
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
                onPressed: onCancelDownload,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ],
        );
      } else if (downloadTask!.status == DownloadStatus.pending) {
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }
    }

    return IconButton.filledTonal(
      icon: const Icon(Icons.download_rounded, size: 18),
      onPressed: onDownload,
      tooltip: 'Télécharger',
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.primary.withAlpha(40),
        foregroundColor: theme.colorScheme.primary,
      ),
    );
  }
}
