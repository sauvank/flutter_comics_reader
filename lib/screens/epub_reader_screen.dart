import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import '../models/book_item.dart';
import '../providers/library_provider.dart';
import '../services/epub_service.dart';

enum EpubTheme {
  dark,
  oled,
  sepia,
  light,
}

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

  List<EpubChapterItem> _chapters = [];
  bool _isLoading = true;
  int _currentChapterIndex = 0;
  double _fontSize = 16.0;
  EpubTheme _theme = EpubTheme.dark;
  bool _showControls = false;

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
      if (_currentChapterIndex >= _chapters.length) {
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
    setState(() {
      _currentChapterIndex = index;
    });
    _scrollController.jumpTo(0.0);
    _saveProgress();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Color get _backgroundColor {
    switch (_theme) {
      case EpubTheme.oled:
        return Colors.black;
      case EpubTheme.dark:
        return const Color(0xFF1E1E1E);
      case EpubTheme.sepia:
        return const Color(0xFFFBF0D9);
      case EpubTheme.light:
        return const Color(0xFFF7F7F7);
    }
  }

  Color get _textColor {
    switch (_theme) {
      case EpubTheme.oled:
      case EpubTheme.dark:
        return const Color(0xFFE0E0E0);
      case EpubTheme.sepia:
        return const Color(0xFF5F4B32);
      case EpubTheme.light:
        return const Color(0xFF1E1E1E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
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
        backgroundColor: _backgroundColor,
        drawer: _buildTableOfContentsDrawer(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _chapters.isEmpty
                ? Center(
                    child: Text(
                      'Impossible de charger les chapitres de ce livre.',
                      style: TextStyle(color: _textColor),
                    ),
                  )
                : Stack(
                    children: [
                      // Reader Content
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showControls = !_showControls;
                          });
                        },
                        child: SelectionArea(
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width > 800 ? 120 : 20,
                              vertical: 60,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                Text(
                                  _chapters[_currentChapterIndex].title,
                                  style: TextStyle(
                                    fontSize: _fontSize * 1.4,
                                    fontWeight: FontWeight.bold,
                                    color: _textColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                HtmlWidget(
                                  _chapters[_currentChapterIndex].htmlContent,
                                  textStyle: TextStyle(
                                    fontSize: _fontSize,
                                    height: 1.6,
                                    color: _textColor,
                                    fontFamily: 'serif',
                                  ),
                                  customStylesBuilder: (element) {
                                    if (element.localName == 'p') {
                                      return {'margin-bottom': '1em'};
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 40),
                                // Bottom chapter navigation
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (_currentChapterIndex > 0)
                                      ElevatedButton.icon(
                                        onPressed: () => _goToChapter(_currentChapterIndex - 1),
                                        icon: const Icon(Icons.arrow_back),
                                        label: const Text('Précédent'),
                                      )
                                    else
                                      const SizedBox.shrink(),
                                    if (_currentChapterIndex < _chapters.length - 1)
                                      ElevatedButton.icon(
                                        onPressed: () => _goToChapter(_currentChapterIndex + 1),
                                        icon: const Icon(Icons.arrow_forward),
                                        label: const Text('Suivant'),
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

                      // Top Navigation Bar
                      if (_showControls)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black.withAlpha(200),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: SafeArea(
                              bottom: false,
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                  Expanded(
                                    child: Text(
                                      widget.book.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.menu_book, color: Colors.white),
                                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                                    tooltip: 'Table des matières',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.format_size, color: Colors.white),
                                    onPressed: _showSettingsDialog,
                                    tooltip: 'Police et Thème',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Bottom Progress Bar
                      if (_showControls)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black.withAlpha(200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: SafeArea(
                              top: false,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Chapitre ${_currentChapterIndex + 1} / ${_chapters.length}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${((_currentChapterIndex + 1) / _chapters.length * 100).toInt()}%',
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  Slider(
                                    value: _currentChapterIndex.toDouble(),
                                    min: 0,
                                    max: (_chapters.length - 1).toDouble().clamp(0, double.infinity),
                                    divisions: _chapters.length > 1 ? _chapters.length - 1 : 1,
                                    onChanged: (val) {
                                      _goToChapter(val.toInt());
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildTableOfContentsDrawer() {
    return Drawer(
      backgroundColor: _backgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Table des Matières',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _chapters.length,
                itemBuilder: (context, index) {
                  final isCurrent = index == _currentChapterIndex;
                  return ListTile(
                    selected: isCurrent,
                    selectedTileColor: Colors.deepPurple.withAlpha(50),
                    title: Text(
                      _chapters[index].title,
                      style: TextStyle(
                        color: isCurrent ? Colors.deepPurpleAccent : _textColor,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isCurrent ? Colors.deepPurpleAccent : _textColor.withAlpha(150),
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _goToChapter(index);
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

  void _showSettingsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF222222),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Paramètres de lecture',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Taille de la police', style: TextStyle(color: Colors.white70)),
                  Row(
                    children: [
                      const Text('A', style: TextStyle(color: Colors.white, fontSize: 14)),
                      Expanded(
                        child: Slider(
                          value: _fontSize,
                          min: 12.0,
                          max: 28.0,
                          divisions: 8,
                          onChanged: (val) {
                            setSheetState(() => _fontSize = val);
                            setState(() => _fontSize = val);
                          },
                        ),
                      ),
                      const Text('A', style: TextStyle(color: Colors.white, fontSize: 22)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Thème de lecture', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildThemeButton('Sombre', EpubTheme.dark, const Color(0xFF1E1E1E), Colors.white),
                      _buildThemeButton('OLED', EpubTheme.oled, Colors.black, Colors.white),
                      _buildThemeButton('Sépia', EpubTheme.sepia, const Color(0xFFFBF0D9), const Color(0xFF5F4B32)),
                      _buildThemeButton('Clair', EpubTheme.light, const Color(0xFFF7F7F7), Colors.black),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeButton(String label, EpubTheme theme, Color bg, Color text) {
    final isSelected = _theme == theme;
    return GestureDetector(
      onTap: () {
        setState(() => _theme = theme);
        Navigator.of(context).pop();
      },
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? Colors.deepPurpleAccent : Colors.grey.withAlpha(100),
                width: isSelected ? 3 : 1,
              ),
            ),
            child: Center(
              child: Text(
                'Aa',
                style: TextStyle(color: text, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.deepPurpleAccent : Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
