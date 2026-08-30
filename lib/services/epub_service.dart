import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:epub_pro/epub_pro.dart';
import 'package:image/image.dart' as img;

class EpubChapterItem {
  final String title;
  final String htmlContent;
  final int index;

  EpubChapterItem({
    required this.title,
    required this.htmlContent,
    required this.index,
  });
}

class EpubService {
  /// Extracts the cover image from an EPUB file and saves it to [targetCoverPath]
  static Future<String?> extractCover({
    required String epubFilePath,
    required String targetCoverPath,
  }) async {
    try {
      final file = File(epubFilePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final epubBook = await EpubReader.readBook(bytes);
      final coverImage = epubBook.coverImage;
      if (coverImage == null) return null;

      final coverBytes = img.encodeJpg(coverImage, quality: 85);
      final coverFile = File(targetCoverPath);
      await coverFile.parent.create(recursive: true);
      await coverFile.writeAsBytes(coverBytes, flush: true);

      return targetCoverPath;
    } catch (e) {
      debugPrint('Error extracting cover from $epubFilePath: $e');
      return null;
    }
  }

  /// Loads an EPUB file and returns flattened chapters
  static Future<List<EpubChapterItem>> loadChapters(String epubFilePath) async {
    try {
      final file = File(epubFilePath);
      if (!await file.exists()) return [];

      final bytes = await file.readAsBytes();
      final epubBook = await EpubReader.readBook(bytes);

      final List<EpubChapterItem> chapters = [];
      if (epubBook.chapters.isNotEmpty) {
        _flattenChapters(epubBook.chapters, chapters);
      }

      // If no chapters found, fallback to content documents
      if (chapters.isEmpty && epubBook.content?.html != null) {
        int idx = 0;
        for (final entry in epubBook.content!.html.entries) {
          final content = entry.value.content ?? '';
          if (content.isNotEmpty) {
            chapters.add(EpubChapterItem(
              title: entry.key,
              htmlContent: content,
              index: idx++,
            ));
          }
        }
      }

      return chapters;
    } catch (e) {
      debugPrint('Error loading chapters from $epubFilePath: $e');
      return [];
    }
  }

  static void _flattenChapters(List<EpubChapter> source, List<EpubChapterItem> dest) {
    for (final chapter in source) {
      final title = (chapter.title?.trim().isNotEmpty == true)
          ? chapter.title!.trim()
          : 'Chapitre ${dest.length + 1}';

      final content = chapter.htmlContent ?? '';
      if (content.trim().isNotEmpty) {
        dest.add(EpubChapterItem(
          title: title,
          htmlContent: content,
          index: dest.length,
        ));
      }

      if (chapter.subChapters.isNotEmpty) {
        _flattenChapters(chapter.subChapters, dest);
      }
    }
  }
}
