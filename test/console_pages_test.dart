import 'package:comic_reader_app/models/download_task.dart';
import 'package:comic_reader_app/models/remote_file.dart';
import 'package:comic_reader_app/models/server_profile.dart';
import 'package:comic_reader_app/providers/download_provider.dart';
import 'package:comic_reader_app/providers/library_provider.dart';
import 'package:comic_reader_app/providers/server_provider.dart';
import 'package:comic_reader_app/widgets/console_downloads_view.dart';
import 'package:comic_reader_app/widgets/console_servers_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

DownloadTask _task(String name, DownloadStatus status, int minute,
        {double progress = 0}) =>
    DownloadTask(
      id: name,
      bookId: 'book-$name',
      fileName: '$name.cbz',
      remotePath: '/BD/$name.cbz',
      serverId: 'nas',
      downloadUrl: 'http://192.168.1.100/BD/$name.cbz',
      status: status,
      progress: progress,
      totalBytes: 180000000,
      receivedBytes: (180000000 * progress).round(),
      speedBytesPerSec: status == DownloadStatus.downloading ? 4200000 : 0,
      createdAt: DateTime(2026, 1, 1, 10, minute),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final nas = ServerProfile(
      id: 'nas', name: 'NAS maison', host: '192.168.1.100', path: '/BD');
  final friend = ServerProfile(
      id: 'ami',
      name: 'Serveur ami',
      host: 'example.org',
      serverType: ServerType.httpDirectory);

  Future<(ServerProvider, DownloadProvider)> pump(
      WidgetTester tester, Size size, Widget child) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final servers = ServerProvider();
    final downloads = DownloadProvider();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider.value(value: downloads),
        ChangeNotifierProvider.value(value: servers),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    ));
    return (servers, downloads);
  }

  for (final size in const [Size(1440, 900), Size(1000, 640)]) {
    testWidgets('servers page renders at $size and queues a volume',
        (tester) async {
      final (servers, downloads) = await pump(
          tester,
          size,
          ConsoleServersView(
            onAddServer: () {},
            onEditServer: (_) {},
            onTestServer: (_) {},
            onDeleteServer: (_) {},
            onOpenBook: (_) {},
          ));
      servers.debugShow(
          servers: [nas, friend],
          active: nas,
          files: [
            RemoteFile(
                name: 'Blacksad', path: '/BD/Blacksad', isDirectory: true),
            RemoteFile(
                name: 'Lovecraft - 01.cbz',
                path: '/BD/Lovecraft - 01.cbz',
                isDirectory: false),
            RemoteFile(
                name: 'Lovecraft - 02.cbz',
                path: '/BD/Lovecraft - 02.cbz',
                isDirectory: false),
          ]);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(find.text('NAS maison'), findsWidgets);
      expect(find.text('Télécharger les 2 manquants'), findsOneWidget);

      // Down to the files row, right to the first volume, Enter queues it.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 500));
      expect(downloads.tasks.single.remotePath, '/BD/Lovecraft - 01.cbz');
      downloads.debugSetTasks([]);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('downloads page renders at $size with running first',
        (tester) async {
      final (_, downloads) =
          await pump(tester, size, ConsoleDownloadsView(onOpenBook: (_) {}));
      downloads.debugSetTasks([
        _task('Dunwich 02', DownloadStatus.pending, 4),
        _task('Dunwich 01', DownloadStatus.pending, 3),
        _task('Abime', DownloadStatus.downloading, 2, progress: .2),
        _task('Hantait', DownloadStatus.downloading, 1, progress: .5),
        _task('Saga', DownloadStatus.failed, 0),
      ]);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(find.text('Hantait'), findsOneWidget);
      expect(find.textContaining("FILE D'ATTENTE · 2", findRichText: true), findsOneWidget);
      // Queue numbered in start order: oldest pending is #1.
      final first = tester.getTopLeft(find.text('Dunwich 01'));
      final second = tester.getTopLeft(find.text('Dunwich 02'));
      expect(first.dx, lessThan(second.dx));
    });
  }
}
