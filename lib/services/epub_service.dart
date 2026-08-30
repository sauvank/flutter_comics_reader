import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:epub_pro/epub_pro.dart';
import 'package:image/image.dart' as img;
import 'package:xml/xml.dart' as xml;

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

      // Primary attempt: using epub_pro
      try {
        final epubBook = await EpubReader.readBook(bytes);
        final coverImage = epubBook.coverImage;
        if (coverImage != null) {
          final coverBytes = img.encodeJpg(coverImage, quality: 85);
          final coverFile = File(targetCoverPath);
          await coverFile.parent.create(recursive: true);
          await coverFile.writeAsBytes(coverBytes, flush: true);
          return targetCoverPath;
        }
      } catch (e1) {
        debugPrint('Primary epub_pro cover extraction failed, trying archive fallback: $e1');
      }

      // Fallback attempt: scan ZIP archive for cover image directly
      return await _extractCoverFromArchive(bytes, targetCoverPath);
    } catch (e) {
      debugPrint('Error extracting cover from $epubFilePath: $e');
      return null;
    }
  }

  /// Loads an EPUB file and returns flattened chapters (with bulletproof ZIP fallback)
  static Future<List<EpubChapterItem>> loadChapters(String epubFilePath) async {
    try {
      final file = File(epubFilePath);
      if (!await file.exists()) return [];

      final bytes = await file.readAsBytes();

      // Primary attempt: using epub_pro
      try {
        final epubBook = await EpubReader.readBook(bytes);
        final List<EpubChapterItem> chapters = [];

        if (epubBook.chapters.isNotEmpty) {
          _flattenChapters(epubBook.chapters, chapters);
        }

        // If no chapters found via TOC, check content documents
        if (chapters.isEmpty && epubBook.content?.html != null) {
          int idx = 0;
          for (final entry in epubBook.content!.html.entries) {
            final content = entry.value.content ?? '';
            if (content.trim().isNotEmpty) {
              chapters.add(EpubChapterItem(
                title: entry.key,
                htmlContent: content,
                index: idx++,
              ));
            }
          }
        }

        if (chapters.isNotEmpty) {
          return chapters;
        }
      } catch (e1) {
        debugPrint('Primary epub_pro readBook failed, falling back to ZIP parser: $e1');
      }

      // Secondary bulletproof fallback: read directly from ZIP structure
      return await _loadChaptersFromArchive(bytes);
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

  /// Bulletproof fallback: manually parse EPUB container, OPF manifest/spine or raw HTML entries
  static Future<List<EpubChapterItem>> _loadChaptersFromArchive(List<int> bytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final List<EpubChapterItem> chapters = [];

      // 1. Try to locate OPF file from META-INF/container.xml
      String? opfPath;
      final containerFile = archive.findFile('META-INF/container.xml');
      if (containerFile != null) {
        try {
          final xmlStr = utf8.decode(containerFile.content as List<int>, allowMalformed: true);
          final doc = xml.XmlDocument.parse(xmlStr);
          final rootfile = doc.findAllElements('rootfile').firstOrNull;
          opfPath = rootfile?.getAttribute('full-path');
        } catch (_) {}
      }

      // 2. If OPF found, follow spine order
      if (opfPath != null) {
        final opfFile = archive.findFile(opfPath);
        if (opfFile != null) {
          try {
            final opfDir = opfPath.contains('/') ? opfPath.substring(0, opfPath.lastIndexOf('/') + 1) : '';
            final xmlStr = utf8.decode(opfFile.content as List<int>, allowMalformed: true);
            final doc = xml.XmlDocument.parse(xmlStr);

            final manifestMap = <String, String>{};
            for (final item in doc.findAllElements('item')) {
              final id = item.getAttribute('id');
              final href = item.getAttribute('href');
              if (id != null && href != null) {
                manifestMap[id] = href;
              }
            }

            final spineElements = doc.findAllElements('itemref');
            int idx = 0;
            for (final itemref in spineElements) {
              final idref = itemref.getAttribute('idref');
              if (idref != null && manifestMap.containsKey(idref)) {
                var href = manifestMap[idref]!;
                href = Uri.decodeFull(href);
                final fullItemPath = opfDir.isNotEmpty ? '$opfDir$href' : href;

                final chapterFile = archive.findFile(fullItemPath) ??
                    archive.files.firstOrNullWhere((f) => f.name.endsWith(href) || f.name == href);

                if (chapterFile != null && chapterFile.isFile) {
                  final htmlStr = utf8.decode(chapterFile.content as List<int>, allowMalformed: true);
                  if (htmlStr.trim().isNotEmpty) {
                    final title = _extractHtmlTitle(htmlStr) ?? 'Chapitre ${idx + 1}';
                    chapters.add(EpubChapterItem(
                      title: title,
                      htmlContent: htmlStr,
                      index: idx++,
                    ));
                  }
                }
              }
            }

            if (chapters.isNotEmpty) {
              return chapters;
            }
          } catch (eOpf) {
            debugPrint('Error parsing OPF spine: $eOpf');
          }
        }
      }

      // 3. Last-resort fallback: find all .xhtml/.html/.htm files and sort them naturally
      final htmlFiles = archive.files.where((f) {
        final lower = f.name.toLowerCase();
        return f.isFile &&
            (lower.endsWith('.xhtml') || lower.endsWith('.html') || lower.endsWith('.htm')) &&
            !lower.contains('toc.xhtml') &&
            !lower.contains('nav.xhtml');
      }).toList();

      htmlFiles.sort((a, b) => a.name.compareTo(b.name));

      int idx = 0;
      for (final f in htmlFiles) {
        try {
          final htmlStr = utf8.decode(f.content as List<int>, allowMalformed: true);
          if (htmlStr.trim().isNotEmpty) {
            final title = _extractHtmlTitle(htmlStr) ?? 'Chapitre ${idx + 1}';
            chapters.add(EpubChapterItem(
              title: title,
              htmlContent: htmlStr,
              index: idx++,
            ));
          }
        } catch (_) {}
      }

      return chapters;
    } catch (e) {
      debugPrint('Archive fallback failed for EPUB: $e');
      return [];
    }
  }

  static String? _extractHtmlTitle(String html) {
    try {
      final titleMatch = RegExp(r'<title[^>]*>(.*?)</title>', caseSensitive: false, dotAll: true).firstMatch(html);
      if (titleMatch != null && titleMatch.group(1)?.trim().isNotEmpty == true) {
        final clean = titleMatch.group(1)!.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        if (clean.isNotEmpty) return clean;
      }

      final h1Match = RegExp(r'<h[1-2][^>]*>(.*?)</h[1-2]>', caseSensitive: false, dotAll: true).firstMatch(html);
      if (h1Match != null && h1Match.group(1)?.trim().isNotEmpty == true) {
        final clean = h1Match.group(1)!.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        if (clean.isNotEmpty) return clean;
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> _extractCoverFromArchive(List<int> bytes, String targetCoverPath) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      ArchiveFile? coverFile;

      // Priority 1: files with 'cover' in name and image extension
      coverFile = archive.files.firstOrNullWhere((f) {
        final lower = f.name.toLowerCase();
        return f.isFile &&
            lower.contains('cover') &&
            (lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.webp'));
      });

      // Priority 2: first image in the archive
      coverFile ??= archive.files.firstOrNullWhere((f) {
        final lower = f.name.toLowerCase();
        return f.isFile &&
            (lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.webp'));
      });

      if (coverFile != null) {
        final coverBytes = coverFile.content as List<int>;
        final targetFile = File(targetCoverPath);
        await targetFile.parent.create(recursive: true);
        await targetFile.writeAsBytes(coverBytes, flush: true);
        return targetCoverPath;
      }
    } catch (e) {
      debugPrint('Archive cover extraction failed: $e');
    }
    return null;
  }
}

extension _FirstOrNullWhere<E> on Iterable<E> {
  E? firstOrNullWhere(bool Function(E element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
