import 'dart:io';

import 'package:comic_reader_app/services/launch_file_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('launch_file_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('picks the first existing book among command line arguments', () {
    final book = File('${dir.path}/XIII - T01.cbz')..writeAsBytesSync([0]);
    File('${dir.path}/notes.txt').writeAsStringSync('x');

    expect(
      LaunchFileService.bookPathFromArgs(
          ['--flag', '${dir.path}/notes.txt', '${dir.path}/missing.cbz', book.path]),
      book.path,
    );
  });

  test('returns null when no book is passed', () {
    expect(LaunchFileService.bookPathFromArgs(const []), isNull);
    expect(LaunchFileService.bookPathFromArgs(['${dir.path}/missing.cbr']), isNull);
  });
}
