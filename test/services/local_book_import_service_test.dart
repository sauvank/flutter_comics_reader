import 'package:comic_reader_app/services/local_book_import_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recognizes the formats available for device import', () {
    expect(LocalBookImportService.isSupportedPath('album.cbz'), isTrue);
    expect(LocalBookImportService.isSupportedPath('album.cbr'), isTrue);
    expect(LocalBookImportService.isSupportedPath('album.zip'), isTrue);
    expect(LocalBookImportService.isSupportedPath('album.pdf'), isTrue);
    expect(LocalBookImportService.isSupportedPath('album.epub'), isTrue);
    expect(LocalBookImportService.isSupportedPath('album.jpg'), isFalse);
  });
}
