import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  Timer? _saveDebounceTimer;
  double _lastSavedOffset = 0.0;
  double _currentChapterProgress = 0.0;
  bool _isRestoringPosition = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _scrollController.addListener(_onScroll);
    _loadEpub();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isRestoringPosition) return;

    final offset = _scrollController.offset;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final ratio = maxExtent > 0 ? (offset / maxExtent).clamp(0.0, 1.0) : 0.0;

    if ((ratio - _currentChapterProgress).abs() > 0.02 || (offset - _lastSavedOffset).abs() > 50) {
      setState(() {
        _currentChapterProgress = ratio;
      });
      _debounceSavePosition(offset, ratio);
    }
  }

  void _debounceSavePosition(double offset, double ratio) {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 350), () {
      _saveExactPosition(offset: offset, ratio: ratio);
    });
  }

  Future<void> _saveExactPosition({double? offset, double? ratio}) async {
    if (_chapters.isEmpty) return;

    final effectiveOffset = offset ?? (_scrollController.hasClients ? _scrollController.offset : _lastSavedOffset);
    final maxExtent = _scrollController.hasClients ? _scrollController.position.maxScrollExtent : 1.0;
    final effectiveRatio = ratio ?? (maxExtent > 0 ? (effectiveOffset / maxExtent).clamp(0.0, 1.0) : 0.0);

    _lastSavedOffset = effectiveOffset;
    _currentChapterProgress = effectiveRatio;

    final totalChapters = _chapters.length;
    final totalBookProgress = totalChapters > 0
        ? ((_currentChapterIndex + effectiveRatio) / totalChapters).clamp(0.0, 1.0)
        : 0.0;

    try {
      final prefs = await SharedPreferences.getInstance();
      final progressData = {
        'chapterIndex': _currentChapterIndex,
        'scrollOffset': effectiveOffset,
        'scrollRatio': effectiveRatio,
        'totalProgress': totalBookProgress,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString('epub_pos_${widget.book.id}', jsonEncode(progressData));
    } catch (e) {
      debugPrint('Error saving exact epub position: $e');
    }

    if (mounted) {
      context.read<LibraryProvider>().updateBookProgress(
            bookId: widget.book.id,
            currentPage: _currentChapterIndex,
            totalPages: totalChapters,
            isCompleted: totalBookProgress >= 0.98,
          );
    }
  }

  Future<void> _loadEpub() async {
    final chapters = await EpubService.loadChapters(widget.book.localPath);
    if (!mounted) return;

    if (chapters.isEmpty) {
      setState(() {
        _chapters = [];
        _isLoading = false;
      });
      return;
    }

    int initialChapter = widget.book.currentPage;
    double initialOffset = 0.0;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('epub_pos_${widget.book.id}');
      if (savedJson != null) {
        final data = jsonDecode(savedJson) as Map<String, dynamic>;
        initialChapter = data['chapterIndex'] as int? ?? initialChapter;
        initialOffset = (data['scrollOffset'] as num?)?.toDouble() ?? 0.0;
      }
    } catch (_) {}

    if (initialChapter >= chapters.length || initialChapter < 0) {
      initialChapter = 0;
      initialOffset = 0.0;
    }

    setState(() {
      _chapters = chapters;
      _currentChapterIndex = initialChapter;
      _isLoading = false;
    });

    _restorePosition(initialOffset);
  }

  void _restorePosition(double targetOffset) {
    if (targetOffset <= 0) return;
    _isRestoringPosition = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _scrollController.hasClients) {
          final maxExtent = _scrollController.position.maxScrollExtent;
          final clampedOffset = targetOffset.clamp(0.0, maxExtent);
          _scrollController.jumpTo(clampedOffset);
          _lastSavedOffset = clampedOffset;
          _isRestoringPosition = false;
        }
      });
    });
  }

  void _goToChapter(int index, {bool fromTop = true, double? initialOffset}) {
    if (index < 0 || index >= _chapters.length) return;

    _saveDebounceTimer?.cancel();
    _saveExactPosition();

    setState(() {
      _currentChapterIndex = index;
      _currentChapterProgress = fromTop ? 0.0 : 1.0;
    });

    _isRestoringPosition = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (initialOffset != null) {
          _scrollController.jumpTo(initialOffset.clamp(0.0, _scrollController.position.maxScrollExtent));
        } else if (fromTop) {
          _scrollController.jumpTo(0.0);
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
        _lastSavedOffset = _scrollController.offset;
        _isRestoringPosition = false;
        _saveExactPosition();
      }
    });
  }

  void _pageForward() {
    if (!_scrollController.hasClients) return;

    final viewportHeight = _scrollController.position.viewportDimension;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final currentOffset = _scrollController.offset;

    // 15% overlap for comfortable reading continuity
    final stepSize = viewportHeight * 0.85;

    if (currentOffset + 25 >= maxExtent) {
      // Reached the end of the chapter -> advance to next chapter
      if (_currentChapterIndex < _chapters.length - 1) {
        HapticFeedback.selectionClick();
        _goToChapter(_currentChapterIndex + 1, fromTop: true);
      } else {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous êtes arrivé à la fin du livre !'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      final target = (currentOffset + stepSize).clamp(0.0, maxExtent);
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _pageBackward() {
    if (!_scrollController.hasClients) return;

    final viewportHeight = _scrollController.position.viewportDimension;
    final currentOffset = _scrollController.offset;
    final stepSize = viewportHeight * 0.85;

    if (currentOffset <= 25) {
      // Reached the top of the chapter -> go back to previous chapter
      if (_currentChapterIndex > 0) {
        HapticFeedback.selectionClick();
        _goToChapter(_currentChapterIndex - 1, fromTop: false);
      }
    } else {
      final target = (currentOffset - stepSize).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _toggleBookmark() {
    context.read<LibraryProvider>().toggleBookmark(
          bookId: widget.book.id,
          pageNumber: _currentChapterIndex,
        );
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    _saveExactPosition();
    _focusNode.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tocSearchController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  double get _totalProgress {
    if (_chapters.isEmpty) return 0.0;
    return ((_currentChapterIndex + _currentChapterProgress) / _chapters.length).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ReaderSettingsService>();
    final library = context.watch<LibraryProvider>();
    final currentBook = library.getBookById(widget.book.id) ?? widget.book;
    final isBookmarked = currentBook.bookmarks.contains(_currentChapterIndex);
    final bgColor = settings.epubBackgroundColor;
    final textColor = settings.epubTextColor;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          Navigator.of(context).pop();
          return;
        }
        if (_showControls) {
          setState(() => _showControls = false);
          return;
        }
        final navigator = Navigator.of(context);
        _saveExactPosition().then((_) {
          if (mounted) navigator.pop();
        });
      },
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.space ||
                event.logicalKey == LogicalKeyboardKey.pageDown) {
              _pageForward();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.backspace ||
                event.logicalKey == LogicalKeyboardKey.pageUp) {
              _pageBackward();
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
                        // Reader Content with 3-zone Tap Navigation
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapUp: (details) {
                            final screenWidth = MediaQuery.of(context).size.width;
                            final tapX = details.globalPosition.dx;
                            final leftBoundary = screenWidth * 0.25;
                            final rightBoundary = screenWidth * 0.75;

                            if (tapX < leftBoundary) {
                              _pageBackward();
                            } else if (tapX > rightBoundary) {
                              _pageForward();
                            } else {
                              setState(() => _showControls = !_showControls);
                            }
                          },
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 820),
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                physics: const ClampingScrollPhysics(),
                                padding: EdgeInsets.symmetric(
                                  horizontal: settings.epubHorizontalPadding,
                                  vertical: 40,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 28),

                                    // Chapter Header
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
                                    const SizedBox(height: 24),

                                    // HTML Rendered Content
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
                                          styles['margin-bottom'] = '1.15em';
                                          styles['text-align'] = settings.epubTextAlign == EpubTextAlign.justify
                                              ? 'justify'
                                              : 'left';
                                        }
                                        return styles.isNotEmpty ? styles : null;
                                      },
                                    ),

                                    const SizedBox(height: 48),

                                    // Refined Literary Chapter Ending
                                    _buildChapterEndingSection(textColor),

                                    const SizedBox(height: 48),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Discreet Minimal Reading Status Bar (when controls hidden)
                        if (!_showControls && settings.showPageNumbers)
                          Positioned(
                            bottom: 12,
                            left: 20,
                            right: 20,
                            child: SafeArea(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _chapters[_currentChapterIndex].title,
                                      style: TextStyle(
                                        color: textColor.withAlpha(90),
                                        fontSize: 11,
                                        fontFamily: settings.epubFontFamilyName,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${(_totalProgress * 100).toInt()}% • Chap. ${_currentChapterIndex + 1}/${_chapters.length}',
                                    style: TextStyle(
                                      color: textColor.withAlpha(110),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Frosted Glass Top Navigation Bar
                        if (_showControls)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: ClipRect(
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                child: Container(
                                  color: Colors.black.withAlpha(190),
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
                                          icon: Icon(
                                            isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                            color: isBookmarked ? const Color(0xFF8B5CF6) : Colors.white,
                                          ),
                                          onPressed: _toggleBookmark,
                                          tooltip: 'Marque-page',
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
                            ),
                          ),

                        // Frosted Glass Bottom Progress Bar & Slider
                        if (_showControls)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: ClipRect(
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                child: Container(
                                  color: Colors.black.withAlpha(190),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                                                  ? () => _goToChapter(_currentChapterIndex - 1, fromTop: true)
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
                                                      color: Colors.white.withAlpha(170),
                                                      fontSize: 11,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '${(_totalProgress * 100).toInt()}%',
                                              style: const TextStyle(
                                                color: Color(0xFF8B5CF6),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.skip_next_rounded, color: Colors.white70),
                                              onPressed: _currentChapterIndex < _chapters.length - 1
                                                  ? () => _goToChapter(_currentChapterIndex + 1, fromTop: true)
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
                                              _goToChapter(val.toInt(), fromTop: true);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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

  /// Elegant literary chapter ending without clunky buttons
  Widget _buildChapterEndingSection(Color textColor) {
    final hasNext = _currentChapterIndex < _chapters.length - 1;

    return Center(
      child: Column(
        children: [
          // Literary divider
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 40, height: 1, color: textColor.withAlpha(40)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '✦  ✦  ✦',
                  style: TextStyle(
                    color: textColor.withAlpha(90),
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),
              ),
              Container(width: 40, height: 1, color: textColor.withAlpha(40)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Fin du Chapitre ${_currentChapterIndex + 1}',
            style: TextStyle(
              color: textColor.withAlpha(120),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 24),

          // Next chapter card preview
          if (hasNext)
            InkWell(
              onTap: () => _goToChapter(_currentChapterIndex + 1, fromTop: true),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: textColor.withAlpha(12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: textColor.withAlpha(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CHAPITRE SUIVANT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _chapters[_currentChapterIndex + 1].title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: textColor.withAlpha(140)),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withAlpha(20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF8B5CF6).withAlpha(50)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Color(0xFF8B5CF6), size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Vous avez terminé ce livre !',
                    style: TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
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
