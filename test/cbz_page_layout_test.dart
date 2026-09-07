import 'package:comic_reader_app/utils/cbz_page_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loading an earlier page preserves the visible page and position', () {
    final layout = CbzPageLayout(10);
    const width = 800.0;
    final before = layout.offsetFor(5, width) + 300;
    final after = layout.updateAspectRatio(1, 2, before, width);
    expect(layout.pageAtOffset(after, width), 5);
    expect(after - layout.offsetFor(5, width), 300);
    expect(after, before - 800);
  });

  test('loading the visible page preserves the fraction already read', () {
    final layout = CbzPageLayout(4);
    final offset = layout.updateAspectRatio(0, 1 / 3, 600, 800);
    expect(offset, 1200);
    expect(layout.heightFor(0, 800), 2400);
    // Revisiting a page uses its retained height, not the initial placeholder.
    expect(layout.offsetFor(1, 800), 2400);
    expect(layout.updateAspectRatio(0, 1 / 3, offset, 800), offset);
  });

  test('jumps use page heights in order, including mixed spreads and portraits',
      () {
    final layout = CbzPageLayout(3);
    layout.updateAspectRatio(0, 0.5, 0, 800);
    layout.updateAspectRatio(1, 2, 0, 800);
    layout.updateAspectRatio(2, 1, 0, 800);
    expect(layout.offsetFor(2, 800), 2000);
    expect(layout.pageAtOffset(1999, 800), 1);
    expect(layout.pageAtOffset(2000, 800), 2);
    expect(layout.offsetFor(2, 400), 1000);
  });
}
