import 'dart:io';
import 'package:flutter/material.dart';
import '../models/book_item.dart';
import '../utils/format_utils.dart';
import 'pdf_to_cbz_dialog.dart';

class BookCard extends StatelessWidget {
  final BookItem book;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;
  final VoidCallback? onToggleFavorite;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    required this.onDelete,
    required this.onToggleStatus,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCover = book.coverPath != null && File(book.coverPath!).existsSync();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: theme.colorScheme.surfaceContainer,
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withAlpha(40),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image with Badges
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasCover)
                    Image.file(
                      File(book.coverPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
                    )
                  else
                    _buildPlaceholder(theme),

                  // Gradient overlay at top and bottom
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withAlpha(120),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withAlpha(180),
                          ],
                          stops: const [0.0, 0.25, 0.65, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Format Badge (CBZ, PDF...)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getFormatColor(book.format),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        book.formatString,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Favorite Quick Action Button
                  if (onToggleFavorite != null)
                    Positioned(
                      top: 4,
                      right: 32,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onToggleFavorite,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: book.isFavorite
                                  ? Colors.redAccent.withAlpha(200)
                                  : Colors.black.withAlpha(90),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              book.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: book.isFavorite ? Colors.white : Colors.white70,
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Menu Button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.transparent,
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                        padding: EdgeInsets.zero,
                        color: theme.colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) {
                          if (value == 'delete') {
                            onDelete();
                          } else if (value == 'toggle') {
                            onToggleStatus();
                          } else if (value == 'convert') {
                            PdfToCbzDialog.show(context, book: book);
                          } else if (value == 'favorite') {
                            onToggleFavorite?.call();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'favorite',
                            child: Row(
                              children: [
                                Icon(
                                  book.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 8),
                                Text(book.isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris'),
                              ],
                            ),
                          ),
                          if (book.format == BookFormat.pdf)
                            const PopupMenuItem(
                              value: 'convert',
                              child: Row(
                                children: [
                                  Icon(Icons.transform_rounded, size: 18, color: Color(0xFF8B5CF6)),
                                  SizedBox(width: 8),
                                  Text('Convertir en BD (CBZ)'),
                                ],
                              ),
                            ),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Row(
                              children: [
                                Icon(
                                  book.isCompleted ? Icons.restart_alt : Icons.check_circle_outline,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(book.isCompleted ? 'Marquer comme non lu' : 'Marquer comme lu'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                SizedBox(width: 8),
                                Text('Supprimer de l\'appareil', style: TextStyle(color: Colors.redAccent)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Completed Checkmark or Reading Progress Pill
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: book.isCompleted
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'TERMINÉ',
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        : book.progress > 0
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: book.progress,
                                  backgroundColor: Colors.white24,
                                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                                  minHeight: 4,
                                ),
                              )
                            : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            // Book Details
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (book.totalPages > 0)
                        Text(
                          'Page ${book.currentPage + 1}/${book.totalPages}',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      else if (book.fileSize > 0)
                        Text(
                          FormatUtils.formatBytes(book.fileSize),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      const Spacer(),
                      if (book.progress > 0 && !book.isCompleted)
                        Text(
                          '${(book.progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          book.format == BookFormat.pdf ? Icons.picture_as_pdf : Icons.auto_stories,
          size: 40,
          color: theme.colorScheme.primary.withAlpha(120),
        ),
      ),
    );
  }

  Color _getFormatColor(BookFormat format) {
    switch (format) {
      case BookFormat.cbz:
        return const Color(0xFF8B5CF6); // Purple
      case BookFormat.cbr:
        return const Color(0xFF3B82F6); // Blue
      case BookFormat.pdf:
        return const Color(0xFFEF4444); // Red
      case BookFormat.zip:
        return const Color(0xFF10B981); // Emerald
      case BookFormat.epub:
        return const Color(0xFFF59E0B); // Amber / Orange
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }
}
