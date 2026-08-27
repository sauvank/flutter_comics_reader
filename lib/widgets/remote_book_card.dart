import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book_item.dart';
import '../models/download_task.dart';
import '../models/remote_file.dart';
import '../models/server_profile.dart';
import '../providers/library_provider.dart';
import '../services/remote_cover_service.dart';

class RemoteBookCard extends StatefulWidget {
  final ServerProfile server;
  final RemoteFile file;
  final bool isDownloaded;
  final DownloadTask? downloadTask;
  final VoidCallback onTap;
  final VoidCallback onDownload;

  const RemoteBookCard({
    super.key,
    required this.server,
    required this.file,
    required this.isDownloaded,
    this.downloadTask,
    required this.onTap,
    required this.onDownload,
  });

  @override
  State<RemoteBookCard> createState() => _RemoteBookCardState();
}

class _RemoteBookCardState extends State<RemoteBookCard> {
  String? _cachedCoverPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCover();
    });
  }

  @override
  void didUpdateWidget(covariant RemoteBookCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path || oldWidget.isDownloaded != widget.isDownloaded) {
      _loadCover();
    }
  }

  void _loadCover() async {
    // 1. If book is downloaded locally, use local book cover
    try {
      final library = context.read<LibraryProvider>();
      final localBook = library.getBookByServerPath(widget.server.id, widget.file.path);
      if (localBook?.coverPath != null && File(localBook!.coverPath!).existsSync()) {
        if (mounted) {
          setState(() {
            _cachedCoverPath = localBook.coverPath;
          });
        }
        return;
      }
    } catch (_) {}

    // 2. Check remote cache
    final coverService = RemoteCoverService();
    final cached = coverService.getCachedCoverSync(widget.server, widget.file);
    if (cached != null && File(cached).existsSync()) {
      if (mounted) {
        setState(() {
          _cachedCoverPath = cached;
        });
      }
      return;
    }

    final coverPath = await coverService.getCoverForRemoteBook(
      server: widget.server,
      file: widget.file,
    );

    if (coverPath != null && mounted) {
      setState(() {
        _cachedCoverPath = coverPath;
      });
    }
  }

  void _confirmDeleteLocal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer de l\'appareil ?'),
        content: Text(
          'Voulez-vous supprimer le fichier téléchargé en local de "${widget.file.name}" pour libérer de l\'espace ?\n\nLe fichier reste toujours accessible et téléchargeable depuis votre serveur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final library = context.read<LibraryProvider>();
              final book = library.getBookByServerPath(widget.server.id, widget.file.path);
              if (book != null) {
                await library.deleteBook(book.id);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${widget.file.name}" a été supprimé de votre tablette.'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Supprimer du local'),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  Color _getFormatColor(BookFormat format) {
    switch (format) {
      case BookFormat.cbz:
      case BookFormat.cbr:
      case BookFormat.zip:
        return const Color(0xFF8B5CF6);
      case BookFormat.pdf:
        return const Color(0xFFEF4444);
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getFormatIcon(BookFormat format) {
    switch (format) {
      case BookFormat.cbz:
      case BookFormat.cbr:
      case BookFormat.zip:
        return Icons.auto_stories_rounded;
      case BookFormat.pdf:
        return Icons.picture_as_pdf_rounded;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final format = widget.file.format;
    final isDownloading = widget.downloadTask != null &&
        (widget.downloadTask!.status == DownloadStatus.downloading ||
            widget.downloadTask!.status == DownloadStatus.converting ||
            widget.downloadTask!.status == DownloadStatus.pending);

    final library = context.watch<LibraryProvider>();
    final localBook = library.getBookByServerPath(widget.server.id, widget.file.path);
    final isFavorite = widget.isDownloaded && localBook != null
        ? localBook.isFavorite
        : library.isRemoteFavorite(widget.server.id, widget.file.path);

    final cleanTitle = widget.file.name
        .replaceAll(RegExp(r'\.(cbz|cbr|zip|rar|pdf|epub)$', caseSensitive: false), '')
        .replaceAll('_', ' ');

    final hasCover = _cachedCoverPath != null && File(_cachedCoverPath!).existsSync();

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: widget.isDownloaded ? 1.0 : 0.75, // Slightly grayed out if not downloaded
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: widget.isDownloaded
                ? theme.colorScheme.surfaceContainer
                : theme.colorScheme.surfaceContainer.withAlpha(150),
            border: Border.all(
              color: widget.isDownloaded
                  ? theme.colorScheme.outlineVariant.withAlpha(60)
                  : theme.colorScheme.outlineVariant.withAlpha(30),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(widget.isDownloaded ? 40 : 20),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Area
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Real extracted Cover image or Stylized Placeholder
                    if (hasCover)
                      Image.file(
                        File(_cachedCoverPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(theme, format),
                      )
                    else
                      _buildPlaceholder(theme, format),

                    // Top and Bottom dark gradient overlay for text contrast
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withAlpha(140),
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withAlpha(180),
                              ],
                              stops: const [0.0, 0.25, 0.65, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Top Format Badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.isDownloaded
                              ? _getFormatColor(format)
                              : Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          format.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Top Right Status Badge and Actions (Cloud vs Downloaded)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Favorite Heart Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (widget.isDownloaded && localBook != null) {
                                  library.toggleFavorite(localBook.id);
                                } else {
                                  library.toggleRemoteFavorite(widget.server.id, widget.file.path);
                                }
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isFavorite
                                      ? Colors.redAccent.withAlpha(220)
                                      : Colors.black.withAlpha(120),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  color: isFavorite ? Colors.white : Colors.white70,
                                  size: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: widget.isDownloaded
                                  ? const Color(0xFF10B981) // Vibrant Green for LOCAL
                                  : const Color(0xFF3B82F6), // Vibrant Blue for SERVEUR
                              borderRadius: BorderRadius.circular(7),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(50),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.isDownloaded
                                      ? Icons.check_circle_rounded
                                      : Icons.cloud_outlined,
                                  size: 11,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  widget.isDownloaded ? 'LOCAL' : 'SERVEUR',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.isDownloaded) ...[
                            const SizedBox(width: 2),
                            Material(
                              color: Colors.transparent,
                              child: PopupMenuButton<String>(
                                icon: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(160),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.more_vert, size: 14, color: Colors.white),
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 160),
                                color: theme.colorScheme.surfaceContainerHighest,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _confirmDeleteLocal(context);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Supprimer du local',
                                          style: TextStyle(color: Colors.redAccent, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Bottom file size
                    if (widget.file.size > 0)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(160),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatBytes(widget.file.size),
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),

                    // Downloading progress overlay
                    if (isDownloading)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withAlpha(180),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    value: widget.downloadTask!.progress > 0
                                        ? widget.downloadTask!.progress
                                        : null,
                                    color: widget.downloadTask!.status == DownloadStatus.converting
                                        ? const Color(0xFF8B5CF6)
                                        : theme.colorScheme.primary,
                                    strokeWidth: 3,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${(widget.downloadTask!.progress * 100).toInt()}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (widget.downloadTask?.etaString != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.downloadTask!.etaString!,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Title and Actions footer
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cleanTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              height: 1.2,
                              color: widget.isDownloaded
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurface.withAlpha(200),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!widget.isDownloaded && !isDownloading)
                      IconButton(
                        icon: const Icon(Icons.download_rounded, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        tooltip: 'Télécharger pour lecture hors-ligne',
                        onPressed: widget.onDownload,
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

  Widget _buildPlaceholder(ThemeData theme, BookFormat format) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isDownloaded
              ? [
                  _getFormatColor(format).withAlpha(40),
                  theme.colorScheme.surfaceContainerHighest,
                ]
              : [
                  Colors.grey.shade900.withAlpha(120),
                  theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                ],
        ),
      ),
      child: Center(
        child: Icon(
          _getFormatIcon(format),
          size: 48,
          color: widget.isDownloaded
              ? _getFormatColor(format).withAlpha(140)
              : Colors.grey.shade600,
        ),
      ),
    );
  }
}
