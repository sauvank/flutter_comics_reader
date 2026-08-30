import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:provider/provider.dart';
import '../models/book_item.dart';
import '../providers/library_provider.dart';
import '../services/epub_service.dart';
import '../services/reader_settings_service.dart';

class EpubReaderScreen extends StatefulWidget {
  final BookItem book;

  const EpubReaderScreen({super.key, required this.book});

  @override
  State<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends State<EpubReaderScreen> {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _tocSearchController = TextEditingController();

  List<EpubChapterItem> _chapters = [];
  bool _isLoading = true;
  int _currentChapterIndex = 0;
  bool _showControls = false;
  String _tocSearchQuery = '';
  final Map<int, double> _chapterScrollOffsets = {};

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.book.currentPage;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadEpub();
  }

  Future<void> _loadEpub() async {
    final chapters = await EpubService.loadChapters(widget.book.localPath);
    if (!mounted) return;

    setState(() {
      _chapters = chapters;
      _isLoading = false;
      if (_currentChapterIndex >= _chapters.length || _currentChapterIndex < 0) {
        _currentChapterIndex = 0;
      }
    });

    _saveProgress();
  }

  void _saveProgress() {
    if (_chapters.isEmpty) return;
    context.read<LibraryProvider>().updateBookProgress(
          bookId: widget.book.id,
          currentPage: _currentChapterIndex,
          totalPages: _chapters.length,
        );
  }

  void _goToChapter(int index) {
    if (index < 0 || index >= _chapters.length) return;
    if (_scrollController.hasClients) {
      _chapterScrollOffsets[_currentChapterIndex] = _scrollController.offset;
    }
    setState(() {
      _currentChapterIndex = index;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final savedOffset = _chapterScrollOffsets[_currentChapterIndex] ?? 0.0;
        _scrollController.jumpTo(savedOffset);
      }
    });
    _saveProgress();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    _tocSearchController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ReaderSettingsService>();
    final bgColor = settings.epubBackgroundColor;
    final textColor = settings.epubTextColor;

    return PopScope(
      canPop: true,
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
              event.logicalKey == LogicalKeyboardKey.pageDown) {
            _goToChapter(_currentChapterIndex + 1);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
              event.logicalKey == LogicalKeyboardKey.pageUp) {
            _goToChapter(_currentChapterIndex - 1);
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: bgColor,
        drawer: _buildTableOfContentsDrawer(settings),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                    const SizedBox(height: 16),
                    Text(
                      'Chargement du livre...',
                      style: TextStyle(color: textColor.withAlpha(180)),
                    ),
                  ],
                ),
              )
            : _chapters.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 64, color: textColor.withAlpha(120)),
                          const SizedBox(height: 16),
                          Text(
                            'Impossible de charger ce livre',
                            style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Le format du fichier est peut-être corrompu ou non supporté.',
                            style: TextStyle(color: textColor.withAlpha(150), fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _loadEpub,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Réessayer'),
                            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Retour à la bibliothèque'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      // Reader Content
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapUp: (details) {
                          final screenWidth = MediaQuery.of(context).size.width;
                          final tapX = details.globalPosition.dx;
                          final leftBoundary = screenWidth * 0.30;
                          final rightBoundary = screenWidth * 0.70;

                          if (tapX < leftBoundary) {
                            _goToChapter(_currentChapterIndex - 1);
                          } else if (tapX > rightBoundary) {
                            _goToChapter(_currentChapterIndex + 1);
                          } else {
                            setState(() => _showControls = !_showControls);
                          }
                        },
                        child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 860),
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                padding: EdgeInsets.symmetric(
                                  horizontal: settings.epubHorizontalPadding,
                                  vertical: 60,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 20),
                                    Text(
                                      _chapters[_currentChapterIndex].title,
                                      style: TextStyle(
                                        fontSize: settings.epubFontSize * 1.35,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                        fontFamily: settings.epubFontFamilyName,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    HtmlWidget(
                                      _chapters[_currentChapterIndex].htmlContent,
                                      textStyle: TextStyle(
                                        fontSize: settings.epubFontSize,
                                        height: settings.epubLineHeightValue,
                                        color: textColor,
                                        fontFamily: settings.epubFontFamilyName,
                                      ),
                                      customStylesBuilder: (element) {
                                        final styles = <String, String>{};
                                        if (element.localName == 'p') {
                                          styles['margin-bottom'] = '1.1em';
                                          styles['text-align'] = settings.epubTextAlign == EpubTextAlign.justify
                                              ? 'justify'
                                              : 'left';
                                        }
                                        return styles.isNotEmpty ? styles : null;
                                      },
                                    ),
                                    const SizedBox(height: 48),
                                    // Bottom chapter navigation
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (_currentChapterIndex > 0)
                                          FilledButton.tonalIcon(
                                            onPressed: () => _goToChapter(_currentChapterIndex - 1),
                                            icon: const Icon(Icons.arrow_back_rounded, size: 18),
                                            label: const Text('Chapitre précédent'),
                                          )
                                        else
                                          const SizedBox.shrink(),
                                        if (_currentChapterIndex < _chapters.length - 1)
                                          FilledButton.icon(
                                            onPressed: () => _goToChapter(_currentChapterIndex + 1),
                                            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                                            label: const Text('Chapitre suivant'),
                                          )
                                        else
                                          const SizedBox.shrink(),
                                      ],
                                    ),
                                    const SizedBox(height: 60),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Top Navigation Bar
                      if (_showControls)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black.withAlpha(220),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: SafeArea(
                              bottom: false,
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                  Expanded(
                                    child: Text(
                                      widget.book.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.menu_book_rounded, color: Colors.white),
                                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                                    tooltip: 'Table des matières',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.text_format_rounded, color: Colors.white),
                                    onPressed: () => _showSettingsModal(context, settings),
                                    tooltip: 'Personnaliser la lecture',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Bottom Progress & Chapter Slider
                      if (_showControls)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black.withAlpha(220),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: SafeArea(
                              top: false,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.skip_previous_rounded, color: Colors.white70),
                                        onPressed: _currentChapterIndex > 0
                                            ? () => _goToChapter(_currentChapterIndex - 1)
                                            : null,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Chapitre ${_currentChapterIndex + 1} / ${_chapters.length}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              _chapters[_currentChapterIndex].title,
                                              style: TextStyle(
                                                color: Colors.white.withAlpha(180),
                                                fontSize: 11,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${((_currentChapterIndex + 1) / _chapters.length * 100).toInt()}%',
                                        style: const TextStyle(
                                          color: Color(0xFF8B5CF6),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.skip_next_rounded, color: Colors.white70),
                                        onPressed: _currentChapterIndex < _chapters.length - 1
                                            ? () => _goToChapter(_currentChapterIndex + 1)
                                            : null,
                                      ),
                                    ],
                                  ),
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: const Color(0xFF8B5CF6),
                                      inactiveTrackColor: Colors.white24,
                                      thumbColor: Colors.white,
                                      trackHeight: 3,
                                    ),
                                    child: Slider(
                                      value: _currentChapterIndex.toDouble(),
                                      min: 0,
                                      max: math.max(0, _chapters.length - 1).toDouble(),
                                      divisions: _chapters.length > 1 ? _chapters.length - 1 : 1,
                                      onChanged: (val) {
                                        _goToChapter(val.toInt());
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    ),
  );
}

  Widget _buildTableOfContentsDrawer(ReaderSettingsService settings) {
    final filteredChapters = _tocSearchQuery.isEmpty
        ? _chapters
        : _chapters.where((c) => c.title.toLowerCase().contains(_tocSearchQuery.toLowerCase())).toList();

    return Drawer(
      backgroundColor: settings.epubBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.menu_book_rounded, color: settings.epubTextColor, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Table des Matières',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: settings.epubTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: TextField(
                controller: _tocSearchController,
                style: TextStyle(color: settings.epubTextColor, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Rechercher un chapitre...',
                  hintStyle: TextStyle(color: settings.epubTextColor.withAlpha(120), fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: settings.epubTextColor.withAlpha(150), size: 20),
                  suffixIcon: _tocSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            setState(() {
                              _tocSearchController.clear();
                              _tocSearchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: settings.epubTextColor.withAlpha(20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _tocSearchQuery = val;
                  });
                },
              ),
            ),
            const Divider(height: 20),
            if (filteredChapters.isEmpty && _tocSearchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Aucun chapitre trouvé pour "$_tocSearchQuery"',
                    style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                itemCount: filteredChapters.length,
                itemBuilder: (context, index) {
                  final chapter = filteredChapters[index];
                  final originalIndex = _chapters.indexOf(chapter);
                  final isCurrent = originalIndex == _currentChapterIndex;

                  return ListTile(
                    dense: true,
                    selected: isCurrent,
                    selectedTileColor: const Color(0xFF8B5CF6).withAlpha(40),
                    title: Text(
                      chapter.title,
                      style: TextStyle(
                        color: isCurrent ? const Color(0xFF8B5CF6) : settings.epubTextColor,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: Text(
                      '${originalIndex + 1}',
                      style: TextStyle(
                        color: isCurrent ? const Color(0xFF8B5CF6) : settings.epubTextColor.withAlpha(140),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _goToChapter(originalIndex);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsModal(BuildContext context, ReaderSettingsService settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E24),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Personnalisation du livre',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. Thème de lecture
                  const Text('THÈME & COULEURS', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildThemeCircle(
                        label: 'Sombre',
                        theme: EpubTheme.dark,
                        bg: const Color(0xFF1C1C1E),
                        text: const Color(0xFFE2E2E6),
                        currentTheme: settings.epubTheme,
                        onTap: () => settings.setEpubTheme(EpubTheme.dark),
                      ),
                      _buildThemeCircle(
                        label: 'OLED',
                        theme: EpubTheme.oled,
                        bg: Colors.black,
                        text: Colors.white,
                        currentTheme: settings.epubTheme,
                        onTap: () => settings.setEpubTheme(EpubTheme.oled),
                      ),
                      _buildThemeCircle(
                        label: 'Sépia',
                        theme: EpubTheme.sepia,
                        bg: const Color(0xFFFBF0D9),
                        text: const Color(0xFF3C2F1F),
                        currentTheme: settings.epubTheme,
                        onTap: () => settings.setEpubTheme(EpubTheme.sepia),
                      ),
                      _buildThemeCircle(
                        label: 'Menthe',
                        theme: EpubTheme.mint,
                        bg: const Color(0xFF182420),
                        text: const Color(0xFFD2E8DD),
                        currentTheme: settings.epubTheme,
                        onTap: () => settings.setEpubTheme(EpubTheme.mint),
                      ),
                      _buildThemeCircle(
                        label: 'Clair',
                        theme: EpubTheme.light,
                        bg: const Color(0xFFF8F9FA),
                        text: const Color(0xFF1C1B1F),
                        currentTheme: settings.epubTheme,
                        onTap: () => settings.setEpubTheme(EpubTheme.light),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // 2. Taille de police
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TAILLE DU TEXTE', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('${settings.epubFontSize.toInt()} px', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove_rounded, size: 18),
                        onPressed: settings.epubFontSize > 12
                            ? () => settings.setEpubFontSize(settings.epubFontSize - 1)
                            : null,
                      ),
                      Expanded(
                        child: Slider(
                          value: settings.epubFontSize,
                          min: 12.0,
                          max: 32.0,
                          divisions: 20,
                          onChanged: (val) => settings.setEpubFontSize(val),
                        ),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        onPressed: settings.epubFontSize < 32
                            ? () => settings.setEpubFontSize(settings.epubFontSize + 1)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3. Police de caractères
                  const Text('POLICE DE CARACTÈRES', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildChoiceChip(
                          label: 'Serif (Livre)',
                          isSelected: settings.epubFontFamily == EpubFontFamily.serif,
                          fontFamily: 'serif',
                          onTap: () => settings.setEpubFontFamily(EpubFontFamily.serif),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildChoiceChip(
                          label: 'Sans-Serif',
                          isSelected: settings.epubFontFamily == EpubFontFamily.sansSerif,
                          fontFamily: 'sans-serif',
                          onTap: () => settings.setEpubFontFamily(EpubFontFamily.sansSerif),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildChoiceChip(
                          label: 'Mono',
                          isSelected: settings.epubFontFamily == EpubFontFamily.monospace,
                          fontFamily: 'monospace',
                          onTap: () => settings.setEpubFontFamily(EpubFontFamily.monospace),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4. Interligne & Alignement
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('INTERLIGNE', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            SegmentedButton<EpubLineHeight>(
                              segments: const [
                                ButtonSegment(value: EpubLineHeight.compact, icon: Icon(Icons.density_small_rounded, size: 16)),
                                ButtonSegment(value: EpubLineHeight.normal, icon: Icon(Icons.density_medium_rounded, size: 16)),
                                ButtonSegment(value: EpubLineHeight.relaxed, icon: Icon(Icons.density_large_rounded, size: 16)),
                              ],
                              selected: {settings.epubLineHeight},
                              onSelectionChanged: (set) => settings.setEpubLineHeight(set.first),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ALIGNEMENT', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            SegmentedButton<EpubTextAlign>(
                              segments: const [
                                ButtonSegment(value: EpubTextAlign.justify, icon: Icon(Icons.format_align_justify_rounded, size: 16)),
                                ButtonSegment(value: EpubTextAlign.left, icon: Icon(Icons.format_align_left_rounded, size: 16)),
                              ],
                              selected: {settings.epubTextAlign},
                              onSelectionChanged: (set) => settings.setEpubTextAlign(set.first),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 5. Marges latérales
                  const Text('MARGES DU LIVRE', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SegmentedButton<EpubMargin>(
                    segments: const [
                      ButtonSegment(value: EpubMargin.narrow, label: Text('Étroite', style: TextStyle(fontSize: 12))),
                      ButtonSegment(value: EpubMargin.normal, label: Text('Standard', style: TextStyle(fontSize: 12))),
                      ButtonSegment(value: EpubMargin.wide, label: Text('Large', style: TextStyle(fontSize: 12))),
                    ],
                    selected: {settings.epubMargin},
                    onSelectionChanged: (set) => settings.setEpubMargin(set.first),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeCircle({
    required String label,
    required EpubTheme theme,
    required Color bg,
    required Color text,
    required EpubTheme currentTheme,
    required VoidCallback onTap,
  }) {
    final isSelected = currentTheme == theme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.withAlpha(90),
                width: isSelected ? 3 : 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withAlpha(100),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                'Aa',
                style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF8B5CF6) : Colors.white70,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required String fontFamily,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6).withAlpha(40) : Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B5CF6) : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontFamily: fontFamily,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
