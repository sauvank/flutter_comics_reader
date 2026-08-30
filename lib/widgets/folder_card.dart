import 'package:flutter/material.dart';

class FolderCard extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  final EdgeInsetsGeometry? margin;

  const FolderCard({
    super.key,
    required this.name,
    required this.onTap,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = name.replaceAll('_', ' ');

    return Container(
      margin: margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(70),
        border: Border.all(
          color: isFavorite
              ? Colors.redAccent.withAlpha(120)
              : theme.colorScheme.outlineVariant.withAlpha(35),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Folder icon with stylized badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isFavorite
                      ? Colors.redAccent.withAlpha(30)
                      : theme.colorScheme.primary.withAlpha(30),
                ),
                child: Center(
                  child: Icon(
                    Icons.folder_rounded,
                    color: isFavorite ? Colors.redAccent : theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.collections_bookmark_outlined,
                          size: 13,
                          color: theme.colorScheme.onSurfaceVariant.withAlpha(160),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Dossier / Série',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant.withAlpha(180),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Favorite button
              if (onToggleFavorite != null)
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFavorite ? Colors.redAccent : theme.colorScheme.onSurfaceVariant.withAlpha(140),
                    size: 20,
                  ),
                  onPressed: onToggleFavorite,
                  tooltip: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                  visualDensity: VisualDensity.compact,
                ),

              // Forward arrow chevron
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
