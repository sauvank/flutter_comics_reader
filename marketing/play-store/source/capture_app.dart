// Capture-only entry point. The production app and its widgets are unchanged.
// Install with applicationId com.sauvank.comicstream.storepreview.
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:comic_reader_app/main.dart' as production;
import 'package:comic_reader_app/models/book_item.dart';
import 'package:comic_reader_app/models/server_profile.dart';
import 'package:comic_reader_app/services/database_service.dart';
import 'package:comic_reader_app/services/reader_settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSize = 25;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 40 << 20;
  await DatabaseService().init();
  await ReaderSettingsService().init();
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getInt('store_demo_version') != 1) {
    await seedDemoLibrary();
    await prefs.setString('app_theme_mode', 'dark');
    await ReaderSettingsService().setReadingMode(ReadingMode.leftToRight);
    await ReaderSettingsService().setFitMode(FitMode.fitScreen);
    await prefs.setInt('store_demo_version', 1);
  }
  runApp(const production.ComicStreamApp());
}

Future<void> seedDemoLibrary() async {
  final db = DatabaseService();
  final booksDirectory = await db.getBooksDirectory();
  final coversDirectory = await db.getCoversDirectory();
  final page = (await rootBundle.load('assets/store/orbit_page.png'))
      .buffer
      .asUint8List();
  final books = <BookItem>[];
  final series = [
    ('Orbite', 'orbit_cover.png', ['L’horizon bleu', 'Le signal']),
    ('Sylve', 'sylve_cover.png', ['Le jardin suspendu', 'Les racines du ciel']),
    ('Minuit', 'minuit_cover.png', ['La ville des échos', 'Dernière lumière']),
  ];
  for (var s = 0; s < series.length; s++) {
    final (name, asset, subtitles) = series[s];
    final cover =
        (await rootBundle.load('assets/store/$asset')).buffer.asUint8List();
    final coverFile = File('${coversDirectory.path}/$asset');
    await coverFile.writeAsBytes(cover);
    for (var volume = 0; volume < 2; volume++) {
      final archive = Archive();
      archive.addFile(ArchiveFile('page_01.png', cover.length, cover));
      for (var i = 2; i <= 8; i++) {
        archive.addFile(ArchiveFile('page_0$i.png', page.length, page));
      }
      final id = 'store-$s-$volume';
      final local = File('${booksDirectory.path}/$id.cbz');
      await local.writeAsBytes(ZipEncoder().encode(archive));
      final title = '$name - T0${volume + 1} - ${subtitles[volume]}';
      final current = s == 0 && volume == 0 ? 2 : 0;
      books.add(BookItem(
        id: id,
        title: title,
        originalFilename: '$title.cbz',
        localPath: local.path,
        coverPath: coverFile.path,
        format: BookFormat.cbz,
        totalPages: 8,
        currentPage: current,
        progress: current / 8,
        addedDate: DateTime(2026, 1, 10 - s, 12 - volume),
        lastReadDate: current > 0 ? DateTime(2026, 1, 11) : null,
        fileSize: await local.length(),
        serverId: 'store-nas',
        serverRelativePath: '/BD/$name/$title.cbz',
        isFavorite: volume == 0,
        bookmarks: current > 0 ? [1, 2, 5] : [],
      ));
    }
  }
  await db.saveBooks(books);
  await db.saveServers([
    ServerProfile(
      id: 'store-nas',
      name: 'Ma bibliothèque',
      host: 'bibliotheque.example',
      port: 443,
      path: '/BD/',
      isHttps: true,
      serverType: ServerType.webdav,
    ),
    ServerProfile(
      id: 'store-http',
      name: 'Mon serveur web',
      host: 'comics.example',
      port: 443,
      path: '/',
      isHttps: true,
      serverType: ServerType.httpDirectory,
    ),
    ServerProfile(
      id: 'store-ftp',
      name: 'Mes archives',
      host: 'archives.example',
      port: 21,
      path: '/Comics/',
      serverType: ServerType.ftp,
    ),
  ]);
}
