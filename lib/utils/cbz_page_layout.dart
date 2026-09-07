/// Retains page geometry even after an offscreen image has been evicted.
class CbzPageLayout {
  CbzPageLayout(int pageCount) : _aspectRatios = List.filled(pageCount, 2 / 3);

  final List<double> _aspectRatios;

  double heightFor(int index, double width) => width / _aspectRatios[index];

  double offsetFor(int index, double width) {
    var offset = 0.0;
    for (var i = 0; i < index; i++) {
      offset += heightFor(i, width);
    }
    return offset;
  }

  int pageAtOffset(double offset, double width) {
    for (var i = 0; i < _aspectRatios.length; i++) {
      final height = heightFor(i, width);
      if (offset < height) return i;
      offset -= height;
    }
    return _aspectRatios.length - 1;
  }

  /// Returns an adjusted scroll offset that keeps the same part of the visible
  /// page in view when an image's actual dimensions replace an estimate.
  double updateAspectRatio(
      int index, double ratio, double offset, double width) {
    if (!ratio.isFinite || ratio <= 0 || _aspectRatios[index] == ratio) {
      return offset;
    }
    final anchor = pageAtOffset(offset, width);
    final fraction =
        (offset - offsetFor(anchor, width)) / heightFor(anchor, width);
    _aspectRatios[index] = ratio;
    return offsetFor(anchor, width) + fraction * heightFor(anchor, width);
  }
}
