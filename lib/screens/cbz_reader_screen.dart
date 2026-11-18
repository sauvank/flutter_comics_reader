import 'dart:async';
import 'dart:io';
import 'package:flutter/gestures.dart' show PointerScrollEvent;
import 'package:flutter/material.dart';
import '../utils/desktop_layout.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/book_item.dart';
import '../providers/library_provider.dart';
import '../services/cbz_service.dart';
import '../services/reader_settings_service.dart';
import '../widgets/reader_controls.dart';
import '../widgets/cbz_page_image.dart';
import '../widgets/cbz_zoom_viewport.dart';
import '../widgets/synced_reader_gate.dart';
import '../utils/cbz_page_layout.dart';
import 'epub_reader_screen.dart';
import 'pdf_reader_screen.dart';
import '../l10n/l10n.dart';

class CbzReaderScreen extends StatefulWidget {
  final BookItem book;

  const CbzReaderScreen({super.key, required this.book});

  @override
  State<CbzReaderScreen> createState() => _CbzReaderScreenState();
}

class _CbzReaderScreenState extends State<CbzReaderScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late PageController _pageController;
  ScrollController _verticalScrollController = ScrollController();
  final TransformationController _verticalTransform =
      TransformationController();
  CbzPageLayout? _verticalLayout;
  LibraryProvider? _library;
  ReaderSettingsService? _readerSettings;
  ReadingMode? _readingMode;
  Timer? _progressTimer;
  Timer? _prefetchTimer;
  int _prefetchGeneration = 0;
  int? _lastSavedPage;
  bool _adjustingVerticalLayout = false;
  final FocusNode _focusNode = FocusNode();

  List<CbzPageInfo> _pages = [];
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

  // Each visible page needs its own controller, but all pages share the same
  // zoom and pan so reading remains consistent when navigating.
  final Map<int, TransformationController> _transformControllers = {};

  Matrix4 _calculateInitialMatrixForPage() {
    final scale = _sharedTransformation.getMaxScaleOnAxis();
    if (scale <= 1.05 || !mounted) {
      return Matrix4.identity();
    }
    final settings = context.read<ReaderSettingsService>();
    final isRTL = settings.readingMode == ReadingMode.rightToLeft;
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Centrage sur la première case de lecture avec marges naturelles :
    // - BD / Comics (LTR) : Case 1 centrée à ~28% de la largeur
    // - Manga (RTL) : Case 1 centrée à ~72% de la largeur (28% depuis la droite)
    // - Hauteur : Case 1 en haut avec marge de tête à ~18%
    final targetFx = isRTL ? 0.72 : 0.28;
    final targetFy = 0.18;

    double tx = screenWidth * (0.5 - scale * targetFx);
    double ty = screenHeight * (0.5 - scale * targetFy);

    final minTx = -screenWidth * (scale - 1.0);
    final maxTx = 0.0;
    final minTy = -screenHeight * (scale - 1.0);
    final maxTy = 0.0;

    tx = tx.clamp(minTx, maxTx);
    ty = ty.clamp(minTy, maxTy);

    return Matrix4.identity()
      ..translate(tx, ty)
      ..scale(scale, scale, 1.0);
  }

  TransformationController _getTransformController(int index) {
    return _transformControllers.putIfAbsent(index, () {
      final ctrl = TransformationController(_calculateInitialMatrixForPage());
      ctrl.addListener(() {
        if (_isSynchronizingTransformation ||
            !mounted ||
            index != _currentPage) {
          return;
        }

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

    if (mounted && _isCurrentPageZoomed != isZoomed) {
      setState(() {
        _isCurrentPageZoomed = isZoomed;
      });
    }
  }

  void _resetZoomPositionForPage(int targetIndex) {
    if (!mounted) return;
    final scale = _sharedTransformation.getMaxScaleOnAxis();
    final newMatrix =
        scale <= 1.05 ? Matrix4.identity() : _calculateInitialMatrixForPage();
    _isSynchronizingTransformation = true;
    _sharedTransformation = Matrix4.copy(newMatrix);
    _getTransformController(targetIndex).value = Matrix4.copy(newMatrix);
    _isSynchronizingTransformation = false;
  }

  double get _verticalContentWidth {
    final width = MediaQuery.sizeOf(context).width;
    return width > 850 ? 800 : width;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _library = context.read<LibraryProvider>();
    final settings = context.read<ReaderSettingsService>();
    if (_readerSettings != settings) {
      _readerSettings?.removeListener(_onReaderSettingsChanged);
      _readerSettings = settings;
      _readingMode = settings.readingMode;
      settings.addListener(_onReaderSettingsChanged);
    }
  }

  void _onReaderSettingsChanged() {
    final mode = _readerSettings!.readingMode;
    if (!mounted || mode == _readingMode) return;
    _readingMode = mode;
    if (_pages.isEmpty) return;
    final targetPage = _currentPage.clamp(0, _pages.length - 1);
    _resetZoom();
    _pageController.dispose();
    _pageController = PageController(initialPage: targetPage);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _jumpToPage(targetPage);
    });
  }

  void _scheduleProgressSave() {
    _progressTimer?.cancel();
    _progressTimer =
        Timer(const Duration(milliseconds: 650), _persistCurrentProgress);
  }

  void _persistCurrentProgress() {
    _progressTimer?.cancel();
    if (_pages.isEmpty) return;
    final targetPage = _currentPage.clamp(0, _pages.length - 1);
    if (_lastSavedPage == targetPage) return;
    _lastSavedPage = targetPage;
    final library = _library;
    final bookId = widget.book.id;
    final totalPages = _pages.length;
    // Disposal can happen while Flutter has locked the widget tree. Notify
    // library listeners once that frame has finished tearing down the reader.
    scheduleMicrotask(() {
      library?.updateBookProgress(
        bookId: bookId,
        currentPage: targetPage,
        totalPages: totalPages,
      );
    });
  }

  void _schedulePrefetch() {
    _prefetchTimer?.cancel();
    final generation = ++_prefetchGeneration;
    CbzService.cancelPrefetch(widget.book.id);
    // Let the current page and the page-turn animation finish first.
    _prefetchTimer = Timer(const Duration(milliseconds: 300), () async {
      final page = _currentPage;
      if (!mounted || page >= _pages.length) return;
      for (final index in [page + 1, page - 1]) {
        if (index < 0 || index >= _pages.length) continue;
        final path = await CbzService.loadAndCachePage(
          cbzFilePath: widget.book.localPath,
          bookId: widget.book.id,
          pageIndex: index,
          priority: CbzPagePriority.prefetch,
        );
        if (!mounted || generation != _prefetchGeneration) return;
        if (path != null) {
          await precacheImage(
            cbzPageImageProvider(path, cbzDecodeExtent(MediaQuery.of(context))),
            context,
            onError: (error, stack) {},
          );
        }
        if (!mounted || generation != _prefetchGeneration) return;
      }
    });
  }

  void _resetZoom() {
    _zoomAnimationController?.stop();
    _sharedTransformation = Matrix4.identity();
    _isSynchronizingTransformation = true;
    _verticalTransform.value = Matrix4.identity();
    for (final controller in _transformControllers.values) {
      controller.value = Matrix4.identity();
    }
    _isSynchronizingTransformation = false;
    _isCurrentPageZoomed = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _persistCurrentProgress();
      _prefetchTimer?.cancel();
      _prefetchGeneration++;
      CbzService.cancelPrefetch(widget.book.id);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentPage = widget.book.currentPage < 0 ? 0 : widget.book.currentPage;
    _pageController = PageController(initialPage: _currentPage);
    _verticalScrollController.addListener(_onVerticalScroll);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadCbzPages();
  }

  @override
  void dispose() {
    _readerSettings?.removeListener(_onReaderSettingsChanged);
    _prefetchTimer?.cancel();
    _prefetchGeneration++;
    CbzService.cancelPendingLoads(widget.book.id);
    _verticalTransform.dispose();
    _persistCurrentProgress();
    WidgetsBinding.instance.removeObserver(this);
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
        if (!mounted) return;
        setState(() {
          _errorMessage = l10n.cbzNotFound;
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
            headerBytes[3] == 0x46; // F

        if (isPdf) {
          if (!mounted) return;
          _navigatedAway = true;
          context
              .read<LibraryProvider>()
              .updateBookFormat(widget.book.id, BookFormat.pdf);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => SyncedReaderGate(
                book: widget.book.copyWith(format: BookFormat.pdf),
                readerBuilder: (book) => PdfReaderScreen(book: book),
              ),
            ),
          );
          return;
        }
      } catch (_) {}

      final pages = await CbzService.getPageList(widget.book.localPath);
      if (!mounted) return;

      if (pages.isEmpty) {
        setState(() {
          _errorMessage = l10n.noValidImageInCbz;
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

      _pageController.dispose();
      _pageController = PageController(initialPage: _pageToItem(_currentPage));
      _verticalLayout = CbzPageLayout(pages.length);
      _verticalScrollController.dispose();
      _verticalScrollController = ScrollController(
        initialScrollOffset:
            _verticalLayout!.offsetFor(_currentPage, _verticalContentWidth),
      )..addListener(_onVerticalScroll);
      _scheduleProgressSave();
    } catch (e) {
      if (!mounted) return;
      final fileSize =
          await File(widget.book.localPath).length().catchError((_) => 0);
      if (!mounted) return;
      final sizeMb = (fileSize / (1024 * 1024)).toStringAsFixed(1);
      setState(() {
        _errorMessage = l10n.cbzReadError(sizeMb, e);
        _isLoading = false;
      });
    }
  }

  // Two-page spreads: the cover stays alone, then pages go by pairs
  // (1-2, 3-4…). PageView items are spreads; _currentPage stays a page index.
  bool _spreadMode = false;

  int get _itemCount {
    if (!_spreadMode || _pages.length <= 1) return _pages.length;
    return 1 + _pages.length ~/ 2;
  }

  int _itemToPage(int item) {
    if (item >= _itemCount) return _pages.length;
    return !_spreadMode || item == 0 ? item : 2 * item - 1;
  }

  int _pageToItem(int page) {
    if (page >= _pages.length) return _itemCount;
    return !_spreadMode || page == 0 ? page : (page + 1) ~/ 2;
  }

  /// Whether the window allows two pages side by side (wide, landscape,
  /// horizontal reading), whatever the user's choice.
  bool _canShowSpreads(ReaderSettingsService settings) {
    final size = MediaQuery.sizeOf(context);
    return settings.readingMode != ReadingMode.vertical &&
        size.width >= 900 &&
        size.width > size.height;
  }

  bool _wantsSpread(ReaderSettingsService settings) =>
      settings.doublePage && _canShowSpreads(settings);

  /// Switches between single pages and spreads, keeping the current page.
  void _syncSpreadMode(ReaderSettingsService settings) {
    final wanted = _wantsSpread(settings);
    if (wanted == _spreadMode) return;
    _spreadMode = wanted;
    final previous = _pageController;
    _pageController = PageController(initialPage: _pageToItem(_currentPage));
    WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
  }

  void _onPageChanged(int item) {
    final wasZoomed = _sharedTransformation.getMaxScaleOnAxis() > 1.05;
    final index = _itemToPage(item);

    setState(() {
      _currentPage = index;
      _isCurrentPageZoomed = wasZoomed;
    });

    if (index < _pages.length) {
      _resetZoomPositionForPage(index);
    }
    _schedulePrefetch();
    _scheduleProgressSave();
  }

  DateTime _lastWheelTurn = DateTime(0);

  /// Mouse wheel turns pages in horizontal modes (one page per notch burst).
  void _onWheel(PointerScrollEvent event) {
    final delta =
        event.scrollDelta.dy != 0 ? event.scrollDelta.dy : event.scrollDelta.dx;
    final now = DateTime.now();
    if (delta == 0 ||
        now.difference(_lastWheelTurn) < const Duration(milliseconds: 280)) {
      return;
    }
    _lastWheelTurn = now;
    delta > 0 ? _nextPage() : _prevPage();
  }

  void _nextPage() {
    final settings = context.read<ReaderSettingsService>();
    if (settings.readingMode == ReadingMode.vertical) {
      if (!_verticalScrollController.hasClients) return;
      _verticalScrollController.animateTo(
        (_verticalScrollController.offset + 500).clamp(
          0.0,
          _verticalScrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      if (_pageController.hasClients && _currentPage < _pages.length) {
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
      if (!_verticalScrollController.hasClients) return;
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
    if (!_verticalScrollController.hasClients ||
        _pages.isEmpty ||
        _adjustingVerticalLayout) {
      return;
    }
    final bestPage = _verticalLayout!.pageAtOffset(
      _verticalScrollController.offset +
          MediaQuery.sizeOf(context).height * 0.2,
      _verticalContentWidth,
    );
    if (bestPage != _currentPage) {
      setState(() => _currentPage = bestPage);
      _scheduleProgressSave();
      _schedulePrefetch();
    }
  }

  void _updatePageAspectRatio(int index, double ratio) {
    if (!mounted || !_verticalScrollController.hasClients) return;
    final oldOffset = _verticalScrollController.offset;
    final adjusted = _verticalLayout!.updateAspectRatio(
      index,
      ratio,
      oldOffset,
      _verticalContentWidth,
    );
    _adjustingVerticalLayout = true;
    setState(() {});
    // jumpTo accepts an offset beyond the old extent. The next layout uses the
    // new page heights, so pages above the viewport cannot push the reader away.
    if ((adjusted - oldOffset).abs() > 0.5) {
      _verticalScrollController.jumpTo(adjusted);
    }
    _adjustingVerticalLayout = false;
  }

  void _jumpToPage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _pages.length) return;
    final settings = context.read<ReaderSettingsService>();
    if (settings.readingMode == ReadingMode.vertical) {
      setState(() {
        _resetZoom();
        _currentPage = pageIndex;
      });
      if (_verticalScrollController.hasClients) {
        _adjustingVerticalLayout = true;
        _verticalScrollController.jumpTo(
          _verticalLayout!.offsetFor(pageIndex, _verticalContentWidth),
        );
        _adjustingVerticalLayout = false;
      }
      _scheduleProgressSave();
      _schedulePrefetch();
    } else if (_pageController.hasClients) {
      _pageController.jumpToPage(_pageToItem(pageIndex));
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
    showAdaptiveSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ReaderSettingsSheet(settings: settings),
    );
  }

  void _showThumbnailsGrid() {
    showAdaptiveSheet(
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
                        l10n.pagesCount(_pages.length),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _pages.length,
                    itemBuilder: (context, idx) {
                      final isCurrent = idx == _currentPage;
                      final isBookmarked = widget.book.bookmarks.contains(idx);

                      return _CbzThumbnailItem(
                        cbzFilePath: widget.book.localPath,
                        bookId: widget.book.id,
                        pageIndex: idx,
                        isCurrent: isCurrent,
                        isBookmarked: isBookmarked,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _jumpToPage(idx);
                        },
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
    final vertical = context.read<ReaderSettingsService>().readingMode ==
        ReadingMode.vertical;
    final controller =
        vertical ? _verticalTransform : _getTransformController(pageIndex);
    void completed() {
      if (vertical) {
        setState(() =>
            _isCurrentPageZoomed = controller.value.getMaxScaleOnAxis() > 1.05);
      } else {
        _synchronizeTransformation(pageIndex);
      }
    }

    final currentScale = controller.value.getMaxScaleOnAxis();

    if (currentScale > 1.1) {
      // Zoom out smoothly
      _animateTransformation(
        controller,
        Matrix4.identity(),
        onCompleted: completed,
      );
    } else {
      // Zoom in smoothly to 2.5x centered at the double-tapped point
      final tapPos = details?.localPosition ?? const Offset(200, 300);
      const targetScale = 2.5;

      final target = Matrix4.identity()
        ..translate(tapPos.dx, tapPos.dy)
        ..scale(targetScale)
        ..translate(-tapPos.dx, -tapPos.dy);

      _animateTransformation(
        controller,
        target,
        onCompleted: completed,
      );
    }
  }

  void _onTapZone(TapUpDetails details, BuildContext context,
      ReaderSettingsService settings) {
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
    final library = context.read<LibraryProvider>();
    final (isBookmarked, isFavorite) =
        context.select<LibraryProvider, (bool, bool)>((library) {
      final book = library.getBookById(widget.book.id) ?? widget.book;
      return (book.bookmarks.contains(_currentPage), book.isFavorite);
    });

    if (_isLoading) {
      return Scaffold(
        backgroundColor: settings.actualBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF8B5CF6)),
              const SizedBox(height: 16),
              Text(
                l10n.loadingVolume,
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
                const Icon(Icons.error_outline,
                    size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(_errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.back),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_showControls) {
          setState(() => _showControls = false);
          return;
        }
        if (_isCurrentPageZoomed) {
          _handleDoubleTap(_currentPage, null);
          return;
        }
        Navigator.of(context).pop();
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowRight): _nextPage,
          const SingleActivator(LogicalKeyboardKey.arrowLeft): _prevPage,
          const SingleActivator(LogicalKeyboardKey.space): _nextPage,
          const SingleActivator(LogicalKeyboardKey.pageDown): _nextPage,
          const SingleActivator(LogicalKeyboardKey.pageUp): _prevPage,
          const SingleActivator(LogicalKeyboardKey.backspace): _prevPage,
          const SingleActivator(LogicalKeyboardKey.keyD): () {
            final settings = context.read<ReaderSettingsService>();
            if (_canShowSpreads(settings)) {
              settings.setDoublePage(!settings.doublePage);
            }
          },
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context).pop(),
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
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ReaderTopBar(
                    visible: _showControls,
                    title: widget.book.title,
                    currentPage: _currentPage < _pages.length
                        ? _currentPage
                        : _pages.length - 1,
                    totalPages: _pages.length,
                    isBookmarked: isBookmarked,
                    isFavorite: isFavorite,
                    onBack: () => Navigator.of(context).pop(),
                    onToggleBookmark: _toggleBookmark,
                    onToggleFavorite: () =>
                        library.toggleFavorite(widget.book.id),
                    onOpenSettings: _showSettings,
                    doublePage:
                        _canShowSpreads(settings) ? settings.doublePage : null,
                    onToggleDoublePage: () =>
                        settings.setDoublePage(!settings.doublePage),
                  ),
                ),

                // Bottom Controls Bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ReaderBottomBar(
                    visible: _showControls,
                    currentPage: _currentPage < _pages.length
                        ? _currentPage
                        : _pages.length - 1,
                    totalPages: _pages.length,
                    readingMode: settings.readingMode,
                    onPageChanged: _jumpToPage,
                    onOpenThumbnails: _showThumbnailsGrid,
                    onReadingModeChanged: settings.setReadingMode,
                  ),
                ),

                // Floating Page Number Badge (when controls hidden)
                if (!_showControls &&
                    settings.showPageNumbers &&
                    _currentPage < _pages.length)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(160),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentPage + 1} / ${_pages.length}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalReader(ReaderSettingsService settings) {
    final isRTL = settings.readingMode == ReadingMode.rightToLeft;
    _syncSpreadMode(settings);

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: PageView.builder(
        key: ValueKey('pageview_${settings.readingMode}_$_spreadMode'),
        controller: _pageController,
        physics: _isCurrentPageZoomed
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        itemCount: _itemCount + 1,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, item) {
          if (item == _itemCount) {
            return _buildEndOfBookWidget(context);
          }
          final index = _itemToPage(item);
          final secondIndex =
              _spreadMode && item > 0 && index + 1 < _pages.length
                  ? index + 1
                  : null;
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
            child: CbzZoomViewport(
              controller: transformCtrl,
              zoomed: _isCurrentPageZoomed,
              onInteractionUpdate: (_) {
                final scale = transformCtrl.value.getMaxScaleOnAxis();
                final isZoomed = scale > 1.05;
                if (isZoomed != _isCurrentPageZoomed) {
                  setState(() => _isCurrentPageZoomed = isZoomed);
                }
              },
              onInteractionEnd: (_) => _synchronizeTransformation(index),
              onWheel: _isCurrentPageZoomed ? null : _onWheel,
              child: secondIndex == null
                  ? Center(
                      child: _buildHorizontalPage(
                          index, settings, effectiveFit, isWidescreen),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: _buildHorizontalPage(
                                index, settings, BoxFit.contain, true),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: _buildHorizontalPage(
                                secondIndex, settings, BoxFit.contain, true),
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalPage(int index, ReaderSettingsService settings,
      BoxFit fit, bool isWidescreen) {
    final screenSize = MediaQuery.of(context).size;
    return CbzPageImage(
      cbzFilePath: widget.book.localPath,
      bookId: widget.book.id,
      pageIndex: index,
      fit: fit,
      onReady: () {
        if (index == _currentPage) _schedulePrefetch();
      },
      width: (!isWidescreen && settings.fitMode == FitMode.fitWidth)
          ? screenSize.width
          : null,
      height: (fit == BoxFit.contain || fit == BoxFit.fitHeight)
          ? screenSize.height
          : null,
    );
  }

  Widget _buildVerticalReader(ReaderSettingsService settings) {
    final width = _verticalContentWidth;
    final screenHeight = MediaQuery.sizeOf(context).height;
    TapDownDetails? doubleTapDetails;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => setState(() => _showControls = !_showControls),
      onDoubleTapDown: (details) => doubleTapDetails = details,
      onDoubleTap: () => _handleDoubleTap(_currentPage, doubleTapDetails),
      child: CbzZoomViewport(
        controller: _verticalTransform,
        zoomed: _isCurrentPageZoomed,
        onInteractionUpdate: (_) {
          final zoomed = _verticalTransform.value.getMaxScaleOnAxis() > 1.05;
          if (zoomed != _isCurrentPageZoomed) {
            setState(() => _isCurrentPageZoomed = zoomed);
          }
        },
        onInteractionEnd: (_) {
          if (_verticalTransform.value.getMaxScaleOnAxis() <= 1.05) {
            setState(_resetZoom);
          }
        },
        child: ListView.builder(
          controller: _verticalScrollController,
          cacheExtent: screenHeight * 0.5,
          itemCount: _pages.length + 1,
          itemExtentBuilder: (index, _) => index == _pages.length
              ? screenHeight
              : _verticalLayout!.heightFor(index, width),
          padding: EdgeInsets.zero,
          physics: _isCurrentPageZoomed
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(),
          itemBuilder: (context, index) {
            if (index == _pages.length) return _buildEndOfBookWidget(context);
            return Center(
              child: CbzPageImage(
                key: ValueKey(index),
                cbzFilePath: widget.book.localPath,
                bookId: widget.book.id,
                pageIndex: index,
                fit: BoxFit.contain,
                width: width,
                height: _verticalLayout!.heightFor(index, width),
                onAspectRatio: (ratio) => _updatePageAspectRatio(index, ratio),
                onReady: () {
                  if (index == _currentPage) _schedulePrefetch();
                },
              ),
            );
          },
        ),
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
            child: const Icon(Icons.check_circle_rounded,
                color: Color(0xFF10B981), size: 40),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.volumeFinished,
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
              label: Text(l10n.nextVolumeWithTitle(nextBook.title),
                  textAlign: TextAlign.center),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => SyncedReaderGate(
                      book: nextBook,
                      readerBuilder: (book) {
                        if (book.format == BookFormat.pdf) {
                          return PdfReaderScreen(book: book);
                        }
                        if (book.format == BookFormat.epub) {
                          return EpubReaderScreen(book: book);
                        }
                        return CbzReaderScreen(book: book);
                      },
                    ),
                  ),
                );
              },
            )
          else
            OutlinedButton.icon(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              label: Text(l10n.backToLibrary,
                  style: TextStyle(color: Colors.white)),
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

class _CbzThumbnailItem extends StatefulWidget {
  final String cbzFilePath;
  final String bookId;
  final int pageIndex;
  final bool isCurrent;
  final bool isBookmarked;
  final VoidCallback onTap;

  const _CbzThumbnailItem({
    required this.cbzFilePath,
    required this.bookId,
    required this.pageIndex,
    required this.isCurrent,
    required this.isBookmarked,
    required this.onTap,
  });

  @override
  State<_CbzThumbnailItem> createState() => _CbzThumbnailItemState();
}

class _CbzThumbnailItemState extends State<_CbzThumbnailItem> {
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(covariant _CbzThumbnailItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageIndex != widget.pageIndex ||
        oldWidget.cbzFilePath != widget.cbzFilePath ||
        oldWidget.bookId != widget.bookId) {
      _loadThumbnail();
    }
  }

  void _loadThumbnail() {
    final targetIndex = widget.pageIndex;
    final targetBookId = widget.bookId;
    final targetCbzPath = widget.cbzFilePath;

    final cached = CbzService.getCachedPagePathSync(targetBookId, targetIndex);
    if (cached != null) {
      _filePath = cached;
      return;
    }

    _filePath = null;
    CbzService.loadAndCachePage(
      cbzFilePath: targetCbzPath,
      bookId: targetBookId,
      pageIndex: targetIndex,
      priority: CbzPagePriority.thumbnail,
    ).then((path) {
      if (mounted &&
          widget.pageIndex == targetIndex &&
          widget.bookId == targetBookId &&
          widget.cbzFilePath == targetCbzPath) {
        setState(() {
          _filePath = path;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isCurrent ? const Color(0xFF8B5CF6) : Colors.white12,
            width: widget.isCurrent ? 2.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_filePath != null)
              Image.file(
                File(_filePath!),
                fit: BoxFit.cover,
                cacheWidth: 250,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.white10,
                  child: const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.white30, size: 24)),
                ),
              )
            else
              Container(
                color: Colors.white10,
                child: const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white24),
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${widget.pageIndex + 1}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
            if (widget.isBookmarked)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(Icons.bookmark, color: Colors.amber, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}
