import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/book_item.dart';
import '../providers/library_provider.dart';
import '../services/cbz_service.dart';
import '../services/reader_settings_service.dart';
import '../widgets/reader_controls.dart';
import 'pdf_reader_screen.dart';

class CbzReaderScreen extends StatefulWidget {
  final BookItem book;

  const CbzReaderScreen({super.key, required this.book});

  @override
  State<CbzReaderScreen> createState() => _CbzReaderScreenState();
}

class _CbzReaderScreenState extends State<CbzReaderScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  final ScrollController _verticalScrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<ComicPage> _pages = [];
  int _currentPage = 0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _showControls = false;
  bool _isCurrentPageZoomed = false;
  bool _navigatedAway = false;
  Matrix4 _sharedTransformation = Matrix4.identity();
  bool _isSynchronizingTransformation = false;

  AnimationController? _zoomAnimationController;
  Animation<Matrix4>? _zoomAnimation;

  // Keys and controllers for vertical Webtoon mode
  final Map<int, GlobalKey> _pageKeys = {};

  GlobalKey _getPageKey(int index) {
    return _pageKeys.putIfAbsent(index, () => GlobalKey());
  }

  // Each visible page needs its own controller, but all pages share the same
  // zoom and pan so reading remains consistent when navigating.
  final Map<int, TransformationController> _transformControllers = {};

  TransformationController _getTransformController(int index) {
    return _transformControllers.putIfAbsent(index, () {
      final ctrl = TransformationController(Matrix4.copy(_sharedTransformation));
      ctrl.addListener(() {
        if (_isSynchronizingTransformation || !mounted) return;

        final isZoomed = ctrl.value.getMaxScaleOnAxis() > 1.05;
        if (isZoomed != _isCurrentPageZoomed) {
          setState(() {
            _isCurrentPageZoomed = isZoomed;
          });
        }
      });
      return ctrl;
    });
  }

  void _synchronizeTransformation(int sourcePageIndex) {
    final source = _getTransformController(sourcePageIndex);
    var transformation = Matrix4.copy(source.value);
    final isZoomed = transformation.getMaxScaleOnAxis() > 1.05;

    // Avoid leaving a barely transformed page that can no longer be panned.
    if (!isZoomed) {
      transformation = Matrix4.identity();
      source.value = Matrix4.identity();
    }

    _sharedTransformation = Matrix4.copy(transformation);
    _isSynchronizingTransformation = true;
    for (final entry in _transformControllers.entries) {
      if (entry.key != sourcePageIndex) {
        entry.value.value = Matrix4.copy(_sharedTransformation);
      }
    }
    _isSynchronizingTransformation = false;

    if (mounted && _isCurrentPageZoomed != isZoomed) {
      setState(() {
        _isCurrentPageZoomed = isZoomed;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _currentPage = widget.book.currentPage;
    _pageController = PageController(initialPage: _currentPage);
    _verticalScrollController.addListener(_onVerticalScroll);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadCbzPages();
  }

  @override
  void dispose() {
    _zoomAnimationController?.dispose();
    _focusNode.dispose();
    _pageController.dispose();
    _verticalScrollController.removeListener(_onVerticalScroll);
    _verticalScrollController.dispose();
    for (final ctrl in _transformControllers.values) {
      ctrl.dispose();
    }
    if (!_navigatedAway) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  Future<void> _loadCbzPages() async {
    try {
      final file = File(widget.book.localPath);
      if (!await file.exists()) {
        setState(() {
          _errorMessage = 'Fichier CBZ introuvable sur l\'appareil.';
          _isLoading = false;
        });
        return;
      }

      // Check if file is actually a PDF
      try {
        final raf = await file.open(mode: FileMode.read);
        final headerBytes = await raf.read(4);
        await raf.close();

        final isPdf = headerBytes.length >= 4 &&
            headerBytes[0] == 0x25 && // %
            headerBytes[1] == 0x50 && // P
            headerBytes[2] == 0x44 && // D
            headerBytes[3] == 0x46;   // F

        if (isPdf) {
          if (!mounted) return;
          _navigatedAway = true;
          context.read<LibraryProvider>().updateBookFormat(widget.book.id, BookFormat.pdf);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => PdfReaderScreen(book: widget.book.copyWith(format: BookFormat.pdf)),
            ),
          );
          return;
        }
      } catch (_) {}

      final pages = await CbzService.loadAllPages(widget.book.localPath);

      if (pages.isEmpty) {
        setState(() {
          _errorMessage = 'Aucune image valide trouvée dans cette archive CBZ.';
          _isLoading = false;
        });
        return;
      }

      if (_currentPage >= pages.length) {
        _currentPage = 0;
      }

      if (!mounted) return;
      setState(() {
        _pages = pages;
        _isLoading = false;
      });

      _pageController = PageController(initialPage: _currentPage);

      // Save page count if not already recorded
      if (widget.book.totalPages != pages.length && mounted) {
        context.read<LibraryProvider>().updateBookProgress(
              bookId: widget.book.id,
              currentPage: _currentPage,
              totalPages: pages.length,
            );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erreur de lecture: $e';
        _isLoading = false;
      });
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
      _isCurrentPageZoomed = _sharedTransformation.getMaxScaleOnAxis() > 1.05;
    });

    // Persist progress
    context.read<LibraryProvider>().updateBookProgress(
          bookId: widget.book.id,
          currentPage: _currentPage,
          totalPages: _pages.length,
        );
  }

  void _nextPage() {
    final settings = context.read<ReaderSettingsService>();
    if (settings.readingMode == ReadingMode.vertical) {
      _verticalScrollController.animateTo(
        _verticalScrollController.offset + 500,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      if (_pageController.hasClients && _currentPage < _pages.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _prevPage() {
    final settings = context.read<ReaderSettingsService>();
    if (settings.readingMode == ReadingMode.vertical) {
      _verticalScrollController.animateTo(
        (_verticalScrollController.offset - 500).clamp(0.0, double.infinity),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      if (_pageController.hasClients && _currentPage > 0) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _onVerticalScroll() {
    if (!_verticalScrollController.hasClients || _pages.isEmpty) return;

    final screenHeight = MediaQuery.of(context).size.height;
    int? bestPage;
    double minDistance = double.infinity;

    for (final entry in _pageKeys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx != null) {
        final renderBox = ctx.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final position = renderBox.localToGlobal(Offset.zero);
          final top = position.dy;
          final bottom = top + renderBox.size.height;

          // If this page covers the upper/middle viewport
          if (top <= screenHeight * 0.45 && bottom >= screenHeight * 0.15) {
            bestPage = entry.key;
            break;
          }

          final dist = (top - 120).abs();
          if (dist < minDistance) {
            minDistance = dist;
            bestPage = entry.key;
          }
        }
      }
    }

    if (bestPage != null && bestPage != _currentPage) {
      _currentPage = bestPage;
      setState(() {});
      context.read<LibraryProvider>().updateBookProgress(
            bookId: widget.book.id,
            currentPage: _currentPage,
            totalPages: _pages.length,
          );
    }
  }

  void _jumpToPage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _pages.length) return;
    _onPageChanged(pageIndex);
    final settings = context.read<ReaderSettingsService>();
    if (settings.readingMode == ReadingMode.vertical) {
      final key = _pageKeys[pageIndex];
      final currentContext = key?.currentContext;
      if (currentContext != null) {
        Scrollable.ensureVisible(
          currentContext,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.0,
        );
      } else if (_verticalScrollController.hasClients) {
        final maxScroll = _verticalScrollController.position.maxScrollExtent;
        final estimatedOffset = (pageIndex / _pages.length) * (maxScroll > 0 ? maxScroll : pageIndex * 800.0);
        _verticalScrollController.jumpTo(
          estimatedOffset.clamp(0.0, _verticalScrollController.position.maxScrollExtent),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final key2 = _pageKeys[pageIndex];
          final ctx2 = key2?.currentContext;
          if (ctx2 != null) {
            Scrollable.ensureVisible(
              ctx2,
              duration: const Duration(milliseconds: 200),
              alignment: 0.0,
            );
          }
        });
      }
    } else {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(pageIndex);
      }
    }
  }

  void _toggleBookmark() {
    context.read<LibraryProvider>().toggleBookmark(
          bookId: widget.book.id,
          pageNumber: _currentPage,
        );
  }

  void _showSettings() {
    final settings = context.read<ReaderSettingsService>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ReaderSettingsSheet(settings: settings),
    );
  }

  void _showThumbnailsGrid() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF13151F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pages (${_pages.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _pages.length,
                    itemBuilder: (context, idx) {
                      final isCurrent = idx == _currentPage;
                      final isBookmarked = widget.book.bookmarks.contains(idx);

                      return GestureDetector(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _jumpToPage(idx);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCurrent ? const Color(0xFF8B5CF6) : Colors.white12,
                              width: isCurrent ? 2.5 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(_pages[idx].bytes, fit: BoxFit.cover),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  color: Colors.black87,
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    '${idx + 1}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                  ),
                                ),
                              ),
                              if (isBookmarked)
                                const Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Icon(Icons.bookmark, color: Colors.amber, size: 18),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _animateTransformation(
    TransformationController controller,
    Matrix4 targetMatrix, {
    VoidCallback? onCompleted,
  }) {
    _zoomAnimationController?.dispose();
    _zoomAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _zoomAnimation = Matrix4Tween(
      begin: controller.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _zoomAnimationController!,
      curve: Curves.easeOutCubic,
    ));

    _zoomAnimation!.addListener(() {
      controller.value = _zoomAnimation!.value;
    });

    _zoomAnimationController!.forward().whenComplete(() {
      if (mounted) onCompleted?.call();
    });
  }

  void _handleDoubleTap(int pageIndex, TapDownDetails? details) {
    final controller = _getTransformController(pageIndex);
    final currentScale = controller.value.getMaxScaleOnAxis();

    if (currentScale > 1.1) {
      // Zoom out smoothly
      _animateTransformation(
        controller,
        Matrix4.identity(),
        onCompleted: () => _synchronizeTransformation(pageIndex),
      );
    } else {
      // Zoom in smoothly to 2.5x centered at the double-tapped point
      final tapPos = details?.localPosition ?? const Offset(200, 300);
      const targetScale = 2.5;

      final dx = -tapPos.dx * (targetScale - 1);
      final dy = -tapPos.dy * (targetScale - 1);

      final target = Matrix4.identity()
        ..translate(dx, dy)
        ..scale(targetScale);

      _animateTransformation(
        controller,
        target,
        onCompleted: () => _synchronizeTransformation(pageIndex),
      );
    }
  }

  void _onTapZone(TapUpDetails details, BuildContext context, ReaderSettingsService settings) {
    // If controls are visible, tapping anywhere hides controls
    if (_showControls) {
      setState(() {
        _showControls = false;
      });
      return;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = details.globalPosition.dx;

    final leftBoundary = screenWidth * 0.30;
    final rightBoundary = screenWidth * 0.70;

    final isRTL = settings.readingMode == ReadingMode.rightToLeft;

    if (tapX < leftBoundary) {
      // Tapped Left Zone
      if (isRTL) {
        _nextPage();
      } else {
        _prevPage();
      }
    } else if (tapX > rightBoundary) {
      // Tapped Right Zone
      if (isRTL) {
        _prevPage();
      } else {
        _nextPage();
      }
    } else {
      // Tapped Center Zone: Toggle Bars/Controls
      setState(() {
        _showControls = !_showControls;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ReaderSettingsService>();
    final library = context.watch<LibraryProvider>();
    final currentBook = library.getBookById(widget.book.id) ?? widget.book;
    final isBookmarked = currentBook.bookmarks.contains(_currentPage);
    final isFavorite = currentBook.isFavorite;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF8B5CF6)),
              const SizedBox(height: 16),
              Text(
                'Chargement du tome...',
                style: TextStyle(color: Colors.white.withAlpha(200)),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Retour'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowRight): _nextPage,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _prevPage,
        const SingleActivator(LogicalKeyboardKey.space): _nextPage,
        const SingleActivator(LogicalKeyboardKey.pageDown): _nextPage,
        const SingleActivator(LogicalKeyboardKey.pageUp): _prevPage,
      },
      child: Focus(
        autofocus: true,
        focusNode: _focusNode,
        child: Scaffold(
          backgroundColor: settings.actualBackgroundColor,
          body: Stack(
            children: [
              // Main Reader Pages
              settings.readingMode == ReadingMode.vertical
                  ? _buildVerticalReader(settings)
                  : _buildHorizontalReader(settings),

              // Top Controls Bar
              if (_showControls)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ReaderTopBar(
                    title: widget.book.title,
                    currentPage: _currentPage,
                    totalPages: _pages.length,
                    isBookmarked: isBookmarked,
                    isFavorite: isFavorite,
                    onBack: () => Navigator.of(context).pop(),
                    onToggleBookmark: _toggleBookmark,
                    onToggleFavorite: () => library.toggleFavorite(widget.book.id),
                    onOpenSettings: _showSettings,
                  ),
                ),

              // Bottom Controls Bar
              if (_showControls)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ReaderBottomBar(
                    currentPage: _currentPage,
                    totalPages: _pages.length,
                    readingMode: settings.readingMode,
                    onPageChanged: _jumpToPage,
                    onOpenThumbnails: _showThumbnailsGrid,
                    onReadingModeChanged: (mode) {
                      settings.setReadingMode(mode);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _jumpToPage(_currentPage);
                      });
                    },
                  ),
                ),

              // Floating Page Number Badge (when controls hidden)
              if (!_showControls && settings.showPageNumbers)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(160),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentPage + 1} / ${_pages.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalReader(ReaderSettingsService settings) {
    final isRTL = settings.readingMode == ReadingMode.rightToLeft;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: PageView.builder(
        controller: _pageController,
        physics: _isCurrentPageZoomed
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        itemCount: _pages.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final page = _pages[index];
          final transformCtrl = _getTransformController(index);
          TapDownDetails? doubleTapDetails;

          final screenSize = MediaQuery.of(context).size;
          final isWidescreen = screenSize.width > 900;

          BoxFit effectiveFit = _getBoxFit(settings.fitMode);
          if (isWidescreen && settings.fitMode == FitMode.fitWidth) {
            effectiveFit = BoxFit.contain;
          }

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTapDown: (details) => doubleTapDetails = details,
            onTapUp: (details) => _onTapZone(details, context, settings),
            onDoubleTap: () => _handleDoubleTap(index, doubleTapDetails),
            child: InteractiveViewer(
              transformationController: transformCtrl,
              minScale: 1.0,
              maxScale: 6.0,
              panAxis: PanAxis.free,
              panEnabled: _isCurrentPageZoomed,
              boundaryMargin: const EdgeInsets.all(48),
              clipBehavior: Clip.hardEdge,
              onInteractionEnd: (_) => _synchronizeTransformation(index),
              child: Center(
                child: Image.memory(
                  page.bytes,
                  fit: effectiveFit,
                  width: (!isWidescreen && settings.fitMode == FitMode.fitWidth) ? screenSize.width : null,
                  height: (effectiveFit == BoxFit.contain || effectiveFit == BoxFit.fitHeight) ? screenSize.height : null,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerticalReader(ReaderSettingsService settings) {
    final screenSize = MediaQuery.of(context).size;
    final isWidescreen = screenSize.width > 850;
    final verticalContentWidth = isWidescreen ? 800.0 : screenSize.width;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: ListView.builder(
        controller: _verticalScrollController,
        itemCount: _pages.length + 1, // +1 for end of book footer
        padding: EdgeInsets.zero,
        physics: _isCurrentPageZoomed
            ? const NeverScrollableScrollPhysics()
            : const ClampingScrollPhysics(),
        itemBuilder: (context, index) {
          if (index == _pages.length) {
            return _buildEndOfBookWidget(context);
          }

          final page = _pages[index];
          final transformCtrl = _getTransformController(index);
          TapDownDetails? doubleTapDetails;

          return Container(
            key: _getPageKey(index),
            width: double.infinity,
            color: settings.actualBackgroundColor,
            child: Center(
              child: SizedBox(
                width: verticalContentWidth,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onDoubleTapDown: (details) => doubleTapDetails = details,
                  onTap: () {
                    setState(() {
                      _showControls = !_showControls;
                    });
                  },
                  onDoubleTap: () => _handleDoubleTap(index, doubleTapDetails),
                  child: InteractiveViewer(
                    transformationController: transformCtrl,
                    minScale: 1.0,
                    maxScale: 6.0,
                    panAxis: PanAxis.free,
                    panEnabled: _isCurrentPageZoomed,
                    boundaryMargin: const EdgeInsets.all(48),
                    clipBehavior: Clip.hardEdge,
                    onInteractionEnd: (_) => _synchronizeTransformation(index),
                    child: Image.memory(
                      page.bytes,
                      fit: BoxFit.fitWidth,
                      width: verticalContentWidth,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.high,
                      isAntiAlias: true,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEndOfBookWidget(BuildContext context) {
    final library = context.read<LibraryProvider>();
    final nextBook = library.getNextBook(widget.book);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      color: Colors.black.withAlpha(220),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 40),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tome terminé ! 🎉',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            widget.book.title,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13),
          ),
          const SizedBox(height: 24),
          if (nextBook != null)
            FilledButton.icon(
              icon: const Icon(Icons.skip_next_rounded),
              label: Text('Passer au Tome suivant ➔\n${nextBook.title}', textAlign: TextAlign.center),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (nextBook.format == BookFormat.pdf) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => PdfReaderScreen(book: nextBook)),
                  );
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => CbzReaderScreen(book: nextBook)),
                  );
                }
              },
            )
          else
            OutlinedButton.icon(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              label: const Text('Retour à la bibliothèque', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }

  BoxFit _getBoxFit(FitMode fitMode) {
    switch (fitMode) {
      case FitMode.fitWidth:
        return BoxFit.fitWidth;
      case FitMode.fitHeight:
        return BoxFit.fitHeight;
      case FitMode.fitScreen:
        return BoxFit.contain;
    }
  }
}
