import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import '../models/book_item.dart';
import '../providers/library_provider.dart';
import '../services/reader_settings_service.dart';
import '../widgets/pdf_to_cbz_dialog.dart';
import '../widgets/reader_controls.dart';

class PdfReaderScreen extends StatefulWidget {
  final BookItem book;

  const PdfReaderScreen({super.key, required this.book});

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  final FocusNode _focusNode = FocusNode();
  int _currentPage = 0;
  int _totalPages = 0;
  bool _showControls = false;
  bool _fileExists = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.book.currentPage;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _checkFileExists();

    _pdfController.addListener(() {
      final page = _pdfController.pageNumber;
      final total = _pdfController.pageCount;
      if (page != null && page > 0 && total > 0) {
        final zeroBased = page - 1;
        if (_currentPage != zeroBased || _totalPages != total) {
          setState(() {
            _currentPage = zeroBased;
            _totalPages = total;
          });

          context.read<LibraryProvider>().updateBookProgress(
                bookId: widget.book.id,
                currentPage: zeroBased,
                totalPages: total,
              );
        }
      }
    });
  }

  Future<void> _checkFileExists() async {
    final file = File(widget.book.localPath);
    final exists = await file.exists();
    if (mounted) {
      setState(() {
        _fileExists = exists;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _nextPage() {
    if (_totalPages > 0 && _currentPage < _totalPages - 1) {
      final settings = context.read<ReaderSettingsService>();
      final isRTL = settings.readingMode == ReadingMode.rightToLeft;
      _pdfController.goToPage(
        pageNumber: _currentPage + 2,
        anchor: isRTL ? PdfPageAnchor.topRight : PdfPageAnchor.topLeft,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      final settings = context.read<ReaderSettingsService>();
      final isRTL = settings.readingMode == ReadingMode.rightToLeft;
      _pdfController.goToPage(
        pageNumber: _currentPage,
        anchor: isRTL ? PdfPageAnchor.topRight : PdfPageAnchor.topLeft,
      );
    }
  }

  void _jumpToPage(int pageIndex) {
    if (pageIndex < 0 || (_totalPages > 0 && pageIndex >= _totalPages)) return;
    final settings = context.read<ReaderSettingsService>();
    final isRTL = settings.readingMode == ReadingMode.rightToLeft;
    _pdfController.goToPage(
      pageNumber: pageIndex + 1,
      anchor: isRTL ? PdfPageAnchor.topRight : PdfPageAnchor.topLeft,
    );
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

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ReaderSettingsService>();
    final library = context.watch<LibraryProvider>();
    final currentBook = library.getBookById(widget.book.id) ?? widget.book;
    final isBookmarked = currentBook.bookmarks.contains(_currentPage);
    final isFavorite = currentBook.isFavorite;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: settings.actualBackgroundColor,
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6))),
      );
    }

    if (!_fileExists) {
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
                const Text(
                  'Fichier PDF introuvable sur l\'appareil.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
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

    return PopScope(
      canPop: true,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowRight): _nextPage,
          const SingleActivator(LogicalKeyboardKey.arrowLeft): _prevPage,
          const SingleActivator(LogicalKeyboardKey.space): _nextPage,
          const SingleActivator(LogicalKeyboardKey.pageDown): _nextPage,
          const SingleActivator(LogicalKeyboardKey.pageUp): _prevPage,
          const SingleActivator(LogicalKeyboardKey.backspace): _prevPage,
          const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).pop(),
        },
        child: Focus(
          autofocus: true,
          focusNode: _focusNode,
          child: Builder(
          builder: (context) {
            final screenSize = MediaQuery.of(context).size;
            final isWidescreen = screenSize.width > 850;
            final pcPdfMaxWidth = isWidescreen
                ? ((screenSize.height - 24) * 0.707).clamp(400.0, 780.0)
                : double.infinity;

            return Scaffold(
              backgroundColor: settings.actualBackgroundColor,
              body: Stack(
                children: [
                  // PDF Viewer with smooth pinch-to-zoom & Webtoon scroll
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: pcPdfMaxWidth,
                      ),
                      child: PdfViewer.file(
                        widget.book.localPath,
                        controller: _pdfController,
                        initialPageNumber: _currentPage > 0 ? _currentPage + 1 : 1,
                        params: PdfViewerParams(
                          backgroundColor: settings.actualBackgroundColor,
                          margin: 4,
                      maxScale: 8.0,
                      minScale: 1.0,
                      panAxis: PanAxis.free,
                      boundaryMargin: EdgeInsets.zero,
                      enableTextSelection: false,
                      viewerOverlayBuilder: (ctx, size, handleLinkTap) => [
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapUp: (details) {
                            if (_showControls) {
                              setState(() {
                                _showControls = false;
                              });
                              return;
                            }
                            final tapX = details.globalPosition.dx;
                            final screenWidth = MediaQuery.of(context).size.width;
                            
                            if (tapX < screenWidth * 0.30) {
                              _prevPage();
                            } else if (tapX > screenWidth * 0.70) {
                              _nextPage();
                            } else {
                              setState(() {
                                _showControls = !_showControls;
                              });
                            }
                          },
                          child: IgnorePointer(
                            child: SizedBox(width: size.width, height: size.height),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Top Controls Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ReaderTopBar(
                  visible: _showControls,
                  title: widget.book.title,
                  currentPage: _currentPage,
                  totalPages: _totalPages > 0 ? _totalPages : widget.book.totalPages,
                  isBookmarked: isBookmarked,
                  isFavorite: isFavorite,
                  onBack: () => Navigator.of(context).pop(),
                  onToggleBookmark: _toggleBookmark,
                  onToggleFavorite: () => library.toggleFavorite(widget.book.id),
                  onOpenSettings: _showSettings,
                ),
              ),

              // Convert to CBZ Floating Action Button
              if (_showControls)
                Positioned(
                  top: kToolbarHeight + MediaQuery.of(context).padding.top + 8,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withAlpha(220),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(50),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.auto_fix_high_rounded, color: Colors.white),
                        tooltip: 'Convertir en CBZ (Mode BD)',
                        onPressed: () => PdfToCbzDialog.show(context, book: widget.book),
                      ),
                    ),
                  ),
                ),

              // Bottom Controls Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ReaderBottomBar(
                  visible: _showControls,
                  currentPage: _currentPage,
                  totalPages: _totalPages > 0 ? _totalPages : widget.book.totalPages,
                  readingMode: settings.readingMode,
                  onPageChanged: _jumpToPage,
                  onOpenThumbnails: () {},
                  onReadingModeChanged: (mode) => settings.setReadingMode(mode),
                ),
              ),

              // Floating Page Number Badge
              if (!_showControls && settings.showPageNumbers && _totalPages > 0)
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
                      '${_currentPage + 1} / $_totalPages',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  ),
),
);
  }
}
