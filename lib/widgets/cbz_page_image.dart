import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/cbz_service.dart';

int cbzDecodeExtent(MediaQueryData media) =>
    (media.size.longestSide * media.devicePixelRatio).clamp(1080, 1800).round();

// Use the same cache key for display and prefetch. Bounding both dimensions
// also limits memory for double-page spreads without stretching the image.
ResizeImage cbzPageImageProvider(String path, int extent) => ResizeImage(
      FileImage(File(path)),
      width: extent,
      height: extent,
      policy: ResizeImagePolicy.fit,
    );

class CbzPageImage extends StatefulWidget {
  const CbzPageImage({
    super.key,
    required this.cbzFilePath,
    required this.bookId,
    required this.pageIndex,
    required this.fit,
    this.width,
    this.height,
    this.onReady,
    this.onAspectRatio,
  });

  final String cbzFilePath;
  final String bookId;
  final int pageIndex;
  final BoxFit fit;
  final double? width;
  final double? height;
  final VoidCallback? onReady;
  final ValueChanged<double>? onAspectRatio;

  @override
  State<CbzPageImage> createState() => _CbzPageImageState();
}

class _CbzPageImageState extends State<CbzPageImage> {
  String? _path;
  bool _loading = true;
  bool _resolved = false;
  int _generation = 0;
  ImageProvider? _provider;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(CbzPageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageIndex != widget.pageIndex ||
        oldWidget.bookId != widget.bookId ||
        oldWidget.cbzFilePath != widget.cbzFilePath) {
      _load();
      _resolveImage();
    }
  }

  void _load() {
    final generation = ++_generation;
    _detachImage();
    _provider = null;
    _resolved = false;
    _path = CbzService.getCachedPagePathSync(widget.bookId, widget.pageIndex);
    _loading = _path == null;
    CbzService.loadAndCachePage(
      cbzFilePath: widget.cbzFilePath,
      bookId: widget.bookId,
      pageIndex: widget.pageIndex,
    ).then((path) {
      if (!mounted || generation != _generation) return;
      if (!_loading && path == _path && _resolved) return;
      setState(() {
        _path = path;
        _loading = false;
        _resolveImage();
      });
    });
  }

  void _resolveImage() {
    if (_path == null) return;
    final provider =
        cbzPageImageProvider(_path!, cbzDecodeExtent(MediaQuery.of(context)));
    if (provider == _provider) return;
    _detachImage();
    _provider = provider;
    final generation = _generation;
    _stream = provider.resolve(createLocalImageConfiguration(context));
    var reported = false;
    _listener = ImageStreamListener((info, _) {
      _resolved = true;
      final ratio = info.image.width / math.max(1, info.image.height);
      info.dispose();
      if (reported) return;
      reported = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || generation != _generation) return;
        widget.onAspectRatio?.call(ratio);
        widget.onReady?.call();
      });
    }, onError: (Object error, StackTrace? stack) {
      // The Image widget displays its error placeholder.
    });
    _stream!.addListener(_listener!);
  }

  void _detachImage() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _detachImage();
    super.dispose();
  }

  Widget _placeholder({bool decoding = false}) => SizedBox(
        width: widget.width,
        height: widget.height ?? (widget.width ?? 200) * 1.5,
        child: Center(
          child: _loading || decoding
              ? const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Color(0xFF8B5CF6)),
                )
              : const Icon(Icons.broken_image, color: Colors.white38, size: 40),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_provider == null) return _placeholder();
    return RepaintBoundary(
      child: Image(
        image: _provider!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        gaplessPlayback: false,
        filterQuality: FilterQuality.low,
        frameBuilder: (_, child, frame, wasSynchronouslyLoaded) =>
            frame != null || wasSynchronouslyLoaded
                ? child
                : _placeholder(decoding: true),
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }
}
