import 'package:flutter/material.dart';
import '../services/reader_settings_service.dart';

class ReaderTopBar extends StatelessWidget {
  final String title;
  final int currentPage;
  final int totalPages;
  final bool isBookmarked;
  final VoidCallback onBack;
  final VoidCallback onToggleBookmark;
  final VoidCallback onOpenSettings;

  const ReaderTopBar({
    super.key,
    required this.title,
    required this.currentPage,
    required this.totalPages,
    required this.isBookmarked,
    required this.onBack,
    required this.onToggleBookmark,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withAlpha(220),
            Colors.black.withAlpha(150),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: onBack,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (totalPages > 0)
                      Text(
                        'Page ${currentPage + 1} sur $totalPages',
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? Colors.amber : Colors.white,
                ),
                onPressed: onToggleBookmark,
                tooltip: 'Marque-page',
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: Colors.white),
                onPressed: onOpenSettings,
                tooltip: 'Paramètres de lecture',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReaderBottomBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ReadingMode readingMode;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onOpenThumbnails;
  final ValueChanged<ReadingMode> onReadingModeChanged;

  const ReaderBottomBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.readingMode,
    required this.onPageChanged,
    required this.onOpenThumbnails,
    required this.onReadingModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isRTL = readingMode == ReadingMode.rightToLeft;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withAlpha(230),
            Colors.black.withAlpha(160),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Page Scrubber Slider
              if (totalPages > 1)
                Row(
                  children: [
                    Text(
                      '${currentPage + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Expanded(
                      child: Directionality(
                        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF8B5CF6),
                            inactiveTrackColor: Colors.white24,
                            thumbColor: const Color(0xFF8B5CF6),
                            overlayColor: const Color(0xFF8B5CF6).withAlpha(50),
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                          ),
                          child: Slider(
                            value: currentPage.toDouble().clamp(0.0, (totalPages - 1).toDouble()),
                            min: 0,
                            max: (totalPages - 1).toDouble(),
                            divisions: totalPages > 1 ? totalPages - 1 : 1,
                            onChanged: (val) {
                              onPageChanged(val.toInt());
                            },
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '$totalPages',
                      style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13),
                    ),
                  ],
                ),

              // Control buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mode Switcher (LTR / Manga RTL / Webtoon)
                  TextButton.icon(
                    onPressed: () {
                      final nextMode = readingMode == ReadingMode.leftToRight
                          ? ReadingMode.rightToLeft
                          : readingMode == ReadingMode.rightToLeft
                              ? ReadingMode.vertical
                              : ReadingMode.leftToRight;
                      onReadingModeChanged(nextMode);
                    },
                    icon: Icon(_getReadingModeIcon(readingMode), color: const Color(0xFF8B5CF6), size: 18),
                    label: Text(
                      _getReadingModeLabel(readingMode),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),

                  // Thumbnails Gallery button
                  IconButton(
                    icon: const Icon(Icons.grid_view_rounded, color: Colors.white),
                    onPressed: onOpenThumbnails,
                    tooltip: 'Grille des pages',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getReadingModeIcon(ReadingMode mode) {
    switch (mode) {
      case ReadingMode.leftToRight:
        return Icons.arrow_forward;
      case ReadingMode.rightToLeft:
        return Icons.arrow_back;
      case ReadingMode.vertical:
        return Icons.swap_vert;
    }
  }

  String _getReadingModeLabel(ReadingMode mode) {
    switch (mode) {
      case ReadingMode.leftToRight:
        return 'BD (G->D)';
      case ReadingMode.rightToLeft:
        return 'Manga (D->G)';
      case ReadingMode.vertical:
        return 'Webtoon';
    }
  }
}

class ReaderSettingsSheet extends StatelessWidget {
  final ReaderSettingsService settings;

  const ReaderSettingsSheet({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Paramètres de lecture',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),

            // Sens de lecture
            const Text('Sens de lecture', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            SegmentedButton<ReadingMode>(
              segments: const [
                ButtonSegment(
                  value: ReadingMode.leftToRight,
                  label: Text('BD (G à D)'),
                ),
                ButtonSegment(
                  value: ReadingMode.rightToLeft,
                  label: Text('Manga (D à G)'),
                ),
                ButtonSegment(
                  value: ReadingMode.vertical,
                  label: Text('Webtoon'),
                ),
              ],
              selected: {settings.readingMode},
              onSelectionChanged: (set) => settings.setReadingMode(set.first),
            ),
            const SizedBox(height: 18),

            // Mode d'ajustement
            const Text('Ajustement de l\'image', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            SegmentedButton<FitMode>(
              segments: const [
                ButtonSegment(
                  value: FitMode.fitWidth,
                  label: Text('Largeur'),
                ),
                ButtonSegment(
                  value: FitMode.fitHeight,
                  label: Text('Hauteur'),
                ),
                ButtonSegment(
                  value: FitMode.fitScreen,
                  label: Text('Écran'),
                ),
              ],
              selected: {settings.fitMode},
              onSelectionChanged: (set) => settings.setFitMode(set.first),
            ),
            const SizedBox(height: 18),

            // Couleur d'arrière-plan
            const Text('Arrière-plan', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildColorOption(context, ReaderBgColor.black, Colors.black, 'Noir'),
                const SizedBox(width: 8),
                _buildColorOption(context, ReaderBgColor.darkGray, const Color(0xFF222222), 'Gris'),
                const SizedBox(width: 8),
                _buildColorOption(context, ReaderBgColor.sepia, const Color(0xFFF4ECD8), 'Sépia'),
                const SizedBox(width: 8),
                _buildColorOption(context, ReaderBgColor.white, Colors.white, 'Blanc'),
              ],
            ),
            const SizedBox(height: 14),

            // Keep screen on switch
            SwitchListTile(
              title: const Text('Garder l\'écran allumé', style: TextStyle(fontSize: 14)),
              value: settings.keepScreenOn,
              onChanged: (val) => settings.setKeepScreenOn(val),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(BuildContext context, ReaderBgColor colorType, Color color, String label) {
    final isSelected = settings.bgColor == colorType;

    return Expanded(
      child: GestureDetector(
        onTap: () => settings.setBgColor(colorType),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade700,
              width: isSelected ? 2.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: color == Colors.white || color == const Color(0xFFF4ECD8) ? Colors.black : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
