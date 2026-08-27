import 'package:flutter/material.dart';

class FolderCard extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  const FolderCard({
    super.key,
    required this.name,
    required this.onTap,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Clean folder display name
    final displayName = name.replaceAll('_', ' ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(90),
          border: Border.all(
            color: isFavorite
                ? Colors.redAccent.withAlpha(100)
                : theme.colorScheme.primary.withAlpha(50),
            width: 1.5,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (isFavorite ? Colors.redAccent : theme.colorScheme.primary).withAlpha(25),
              theme.colorScheme.surfaceContainerHighest.withAlpha(90),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row with Folder Icon and favorite/arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.folder_rounded,
                    color: theme.colorScheme.primary,
                    size: 26,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onToggleFavorite != null)
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFavorite ? Colors.redAccent : theme.colorScheme.onSurfaceVariant.withAlpha(150),
                          size: 20,
                        ),
                        onPressed: onToggleFavorite,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),

            // Folder Title
            Text(
              displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),

            // Subtitle
            Row(
              children: [
                Icon(Icons.collections_bookmark_outlined, size: 12, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Dossier / Série',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
