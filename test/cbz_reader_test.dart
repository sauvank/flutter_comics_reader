import 'dart:io';

import 'package:archive/archive.dart';
import 'package:comic_reader_app/models/book_item.dart';
import 'package:comic_reader_app/providers/library_provider.dart';
import 'package:comic_reader_app/screens/cbz_reader_screen.dart';
import 'package:comic_reader_app/services/cbz_service.dart';
import 'package:comic_reader_app/services/reader_settings_service.dart';
import 'package:comic_reader_app/widgets/cbz_page_image.dart';
import 'package:comic_reader_app/widgets/reader_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Library extends LibraryProvider {
  final savedPages = <int>[];

  @override
  Future<void> updateBookProgress({
    required String bookId,
    required int currentPage,
    required int totalPages,
    bool? isCompleted,
  }) async {
    savedPages.add(currentPage);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  late BookItem book;
  late _Library library;
  final settings = ReaderSettingsService();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    temp = await Directory.systemTemp.createTemp('cbz_reader_');
    final archive = Archive();
    for (var i = 0; i < 8; i++) {
      final page = img.Image(width: 60, height: i.isEven ? 90 : 45);
      img.fill(page, color: img.ColorRgb8(i * 30, 0, 255 - i * 30));
      final bytes = img.encodePng(page);
      archive.addFile(ArchiveFile('page${i + 1}.png', bytes.length, bytes));
    }
    final file = File('${temp.path}/comic.cbz');
    await file.writeAsBytes(ZipEncoder().encode(archive));
    book = BookItem(
      id: temp.uri.pathSegments.where((part) => part.isNotEmpty).last,
      title: 'Test CBZ',
      originalFilename: 'comic.cbz',
      localPath: file.path,
      format: BookFormat.cbz,
      totalPages: 8,
      addedDate: DateTime(2026),
    );
    library = _Library();
  });

  tearDown(() async {
    await CbzService.cleanCacheForBook(book.id);
    await temp.delete(recursive: true);
    library.dispose();
  });

  Future<void> tick(WidgetTester tester, [int count = 15]) async {
    for (var i = 0; i < count; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
  }

  Future<void> open(WidgetTester tester, ReadingMode mode,
      {int page = 0}) async {
    await tester.runAsync(() => settings.setReadingMode(mode));
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<LibraryProvider>.value(value: library),
        ChangeNotifierProvider<ReaderSettingsService>.value(value: settings),
      ],
      child: MaterialApp(
          home: CbzReaderScreen(book: book.copyWith(currentPage: page))),
    ));
    await tick(tester);
    expect(find.byType(CbzPageImage), findsWidgets);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    var cleaned = false;
    CbzService.cleanCacheForBook(book.id).then((_) => cleaned = true);
    for (var i = 0; i < 100 && !cleaned; i++) {
      await tick(tester, 1);
    }
    expect(cleaned, isTrue);
  }

  testWidgets(
      'horizontal jumps show the requested image after rapid direction changes',
      (tester) async {
    await open(tester, ReadingMode.leftToRight);
    final controls =
        tester.widget<ReaderBottomBar>(find.byType(ReaderBottomBar));
    controls.onPageChanged(6);
    await tester.pump();
    controls.onPageChanged(2);
    await tester.pump();
    controls.onPageChanged(0);
    await tick(tester);
    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.controller!.page, 0);
    final page = find.byWidgetPredicate(
        (widget) => widget is CbzPageImage && widget.pageIndex == 0);
    final image = tester
        .widget<Image>(find.descendant(of: page, matching: find.byType(Image)));
    final file = ((image.image as ResizeImage).imageProvider as FileImage).file;
    expect(file.path, CbzService.getCachedPagePathSync(book.id, 0));
    await close(tester);
    expect(library.savedPages.last, 0);
  });

  testWidgets('successive realistic horizontal drags each advance one page',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1920);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() => settings.setFitMode(FitMode.fitWidth));
    await open(tester, ReadingMode.leftToRight);
    for (var page = 1; page <= 5; page++) {
      final gesture = await tester.startGesture(const Offset(525, 475));
      await gesture.moveBy(const Offset(-100, 0),
          timeStamp: const Duration(milliseconds: 80));
      await gesture.moveBy(const Offset(-350, 0),
          timeStamp: const Duration(milliseconds: 350));
      await gesture.up(timeStamp: const Duration(milliseconds: 351));
      await tick(tester);
      expect(tester.widget<PageView>(find.byType(PageView)).controller!.page,
          page.toDouble());
    }
    await close(tester);
  });

  testWidgets(
      'a page whose temporary file was evicted is extracted and displayed again',
      (tester) async {
    final path = await tester.runAsync(() => CbzService.loadAndCachePage(
          cbzFilePath: book.localPath,
          bookId: book.id,
          pageIndex: 0,
        ));
    expect(path, isNotNull);
    await tester.runAsync(() => File(path!).delete());
    await tester.pumpWidget(MaterialApp(
      home: CbzPageImage(
        cbzFilePath: book.localPath,
        bookId: book.id,
        pageIndex: 0,
        fit: BoxFit.contain,
      ),
    ));
    await tick(tester);
    expect(find.byIcon(Icons.broken_image), findsNothing);
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    await close(tester);
  });

  for (final mode in [ReadingMode.leftToRight, ReadingMode.vertical]) {
    testWidgets('pinch, pan and unzoom keep navigation working in $mode',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1920);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await open(tester, mode);
      final left = await tester.startGesture(const Offset(200, 350));
      final right =
          await tester.startGesture(const Offset(400, 350), pointer: 2);
      await left.moveTo(const Offset(150, 350));
      await right.moveTo(const Offset(450, 350));
      await tester.pump();
      await left.moveTo(const Offset(100, 350));
      await right.moveTo(const Offset(500, 350));
      await tester.pump();
      await left.up();
      await right.up();
      await tick(tester);
      var viewer = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer).first);
      expect(viewer.transformationController!.value.getMaxScaleOnAxis(),
          greaterThan(1.05));
      final before = Matrix4.copy(viewer.transformationController!.value);
      await tester.dragFrom(const Offset(300, 400), const Offset(-40, -60));
      await tick(tester);
      expect(viewer.transformationController!.value, isNot(before));

      await tester.tapAt(const Offset(300, 400));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(const Offset(300, 400));
      await tick(tester);
      viewer = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer).first);
      expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 1);
      final drag = await tester.startGesture(const Offset(500, 600));
      final step = mode == ReadingMode.vertical
          ? const Offset(0, -150)
          : const Offset(-150, 0);
      await drag.moveBy(step);
      await drag.moveBy(step * 2);
      await drag.up();
      await tick(tester);
      if (mode == ReadingMode.vertical) {
        expect(
            tester.widget<ListView>(find.byType(ListView)).controller!.offset,
            greaterThan(0));
      } else {
        expect(
            tester.widget<PageView>(find.byType(PageView)).controller!.page, 1);
      }
      await close(tester);
    });
  }

  testWidgets(
      'vertical reading resumes and can return to earlier pages without collapsing them',
      (tester) async {
    await open(tester, ReadingMode.vertical, page: 4);
    final controls =
        tester.widget<ReaderBottomBar>(find.byType(ReaderBottomBar));
    expect(controls.currentPage, 4);
    controls.onPageChanged(0);
    await tick(tester);
    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.controller!.offset, 0);
    final page0 = find.byWidgetPredicate(
        (widget) => widget is CbzPageImage && widget.pageIndex == 0);
    final initialHeight = tester.getSize(page0).height;
    controls.onPageChanged(6);
    await tick(tester);
    controls.onPageChanged(0);
    await tester.pump();
    expect(tester.getSize(page0).height, initialHeight);
    await tick(tester);
    expect(list.controller!.offset, 0);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tick(tester);
    expect(list.controller!.offset, greaterThan(0));
    await tester.drag(find.byType(ListView), const Offset(0, 700));
    await tick(tester);
    expect(list.controller!.offset, closeTo(0, 1));
    await close(tester);
  });

  testWidgets(
      'leaving a zoomed page and changing reading mode does not lock scrolling',
      (tester) async {
    await open(tester, ReadingMode.leftToRight);
    var viewer =
        tester.widget<InteractiveViewer>(find.byType(InteractiveViewer).first);
    viewer.transformationController!.value = Matrix4.identity()..scale(2.0);
    viewer.onInteractionEnd!(ScaleEndDetails());
    await tester.pump();
    final controls =
        tester.widget<ReaderBottomBar>(find.byType(ReaderBottomBar));
    controls.onPageChanged(1);
    await tick(tester);
    viewer =
        tester.widget<InteractiveViewer>(find.byType(InteractiveViewer).first);
    viewer.transformationController!.value = Matrix4.identity();
    viewer.onInteractionEnd!(ScaleEndDetails());
    controls.onPageChanged(0);
    await tick(tester);
    viewer =
        tester.widget<InteractiveViewer>(find.byType(InteractiveViewer).first);
    expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 1);
    await tester.drag(find.byType(PageView), const Offset(-700, 0));
    await tick(tester);
    expect(tester.widget<PageView>(find.byType(PageView)).controller!.page, 1);
    controls.onReadingModeChanged(ReadingMode.vertical);
    await tick(tester);
    expect(tester.widget<ListView>(find.byType(ListView)).physics,
        isA<ClampingScrollPhysics>());
    // The settings sheet changes the service directly, bypassing the bottom bar.
    viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    viewer.transformationController!.value = Matrix4.identity()..scale(2.0);
    viewer.onInteractionUpdate!(ScaleUpdateDetails(scale: 2));
    await tester
        .runAsync(() => settings.setReadingMode(ReadingMode.leftToRight));
    await tick(tester);
    expect(tester.widget<PageView>(find.byType(PageView)).controller!.page, 1);
    viewer =
        tester.widget<InteractiveViewer>(find.byType(InteractiveViewer).first);
    expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 1);
    await close(tester);
  });

  testWidgets(
      'quick navigation coalesces saves and closing flushes the last page',
      (tester) async {
    await open(tester, ReadingMode.rightToLeft);
    library.savedPages.clear();
    final controls =
        tester.widget<ReaderBottomBar>(find.byType(ReaderBottomBar));
    for (final page in [1, 3, 2]) {
      controls.onPageChanged(page);
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(library.savedPages, isEmpty);
    await close(tester);
    expect(library.savedPages, [2]);
  });
}
