import 'dart:convert';

enum BookFormat {
  cbz,
  cbr,
  pdf,
  zip,
  epub,
  unknown,
}

class BookItem {
  final String id;
  final String title;
  final String originalFilename;
  final String localPath;
  final String? coverPath;
  final BookFormat format;
  final int totalPages;
  final int currentPage;
  final double progress; // 0.0 to 1.0
  /// Position within the current EPUB chapter (0.0 to 1.0).
  ///
  /// Unlike a pixel offset, this value can be restored on screens with
  /// different sizes, fonts and margins. It is ignored for image and PDF
  /// readers.
  final double epubChapterProgress;
  final bool isCompleted;
  final DateTime addedDate;
  final DateTime? lastReadDate;
  final int fileSize; // bytes
  final String? serverId;
  final String? serverRelativePath;

  /// SHA-256 of the downloaded archive, used to match the same book after a
  /// rename or move on another device.
  final String? contentHash;
  final List<int> bookmarks;
  final bool isFavorite;

  BookItem({
    required this.id,
    required this.title,
    required this.originalFilename,
    required this.localPath,
    this.coverPath,
    required this.format,
    this.totalPages = 0,
    this.currentPage = 0,
    this.progress = 0.0,
    this.epubChapterProgress = 0.0,
    this.isCompleted = false,
    required this.addedDate,
    this.lastReadDate,
    this.fileSize = 0,
    this.serverId,
    this.serverRelativePath,
    this.contentHash,
    List<int>? bookmarks,
    this.isFavorite = false,
  }) : bookmarks = bookmarks ?? [];

  static BookFormat formatFromExtension(String pathOrName) {
    final lower = pathOrName.toLowerCase();
    if (lower.endsWith('.cbz')) return BookFormat.cbz;
    if (lower.endsWith('.cbr')) return BookFormat.cbr;
    if (lower.endsWith('.pdf')) return BookFormat.pdf;
    if (lower.endsWith('.zip')) return BookFormat.zip;
    if (lower.endsWith('.epub')) return BookFormat.epub;
    return BookFormat.unknown;
  }

  String get formatString {
    switch (format) {
      case BookFormat.cbz:
        return 'CBZ';
      case BookFormat.cbr:
        return 'CBR';
      case BookFormat.pdf:
        return 'PDF';
      case BookFormat.zip:
        return 'ZIP';
      case BookFormat.epub:
        return 'EPUB';
      default:
        return 'LIVRE';
    }
  }

  BookItem copyWith({
    String? id,
    String? title,
    String? originalFilename,
    String? localPath,
    String? coverPath,
    BookFormat? format,
    int? totalPages,
    int? currentPage,
    double? progress,
    double? epubChapterProgress,
    bool? isCompleted,
    DateTime? addedDate,
    DateTime? lastReadDate,
    int? fileSize,
    String? serverId,
    String? serverRelativePath,
    String? contentHash,
    List<int>? bookmarks,
    bool? isFavorite,
  }) {
    return BookItem(
      id: id ?? this.id,
      title: title ?? this.title,
      originalFilename: originalFilename ?? this.originalFilename,
      localPath: localPath ?? this.localPath,
      coverPath: coverPath ?? this.coverPath,
      format: format ?? this.format,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      progress: progress ?? this.progress,
      epubChapterProgress: epubChapterProgress ?? this.epubChapterProgress,
      isCompleted: isCompleted ?? this.isCompleted,
      addedDate: addedDate ?? this.addedDate,
      lastReadDate: lastReadDate ?? this.lastReadDate,
      fileSize: fileSize ?? this.fileSize,
      serverId: serverId ?? this.serverId,
      serverRelativePath: serverRelativePath ?? this.serverRelativePath,
      contentHash: contentHash ?? this.contentHash,
      bookmarks: bookmarks ?? List.from(this.bookmarks),
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'originalFilename': originalFilename,
      'localPath': localPath,
      'coverPath': coverPath,
      'format': format.name,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'progress': progress,
      'epubChapterProgress': epubChapterProgress,
      'isCompleted': isCompleted ? 1 : 0,
      'addedDate': addedDate.toIso8601String(),
      'lastReadDate': lastReadDate?.toIso8601String(),
      'fileSize': fileSize,
      'serverId': serverId,
      'serverRelativePath': serverRelativePath,
      'contentHash': contentHash,
      'bookmarks': jsonEncode(bookmarks),
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory BookItem.fromMap(Map<String, dynamic> map) {
    final totalPages = map['totalPages'] as int? ?? 0;
    final currentPage = map['currentPage'] as int? ?? 0;
    final format = BookFormat.values.firstWhere(
      (e) => e.name == map['format'],
      orElse: () => BookFormat.unknown,
    );
    final epubChapterProgress =
        ((map['epubChapterProgress'] as num?)?.toDouble() ?? 0.0)
            .clamp(0.0, 1.0)
            .toDouble();
    return BookItem(
      id: map['id'] as String,
      title: map['title'] as String,
      originalFilename:
          map['originalFilename'] as String? ?? map['title'] as String,
      localPath: map['localPath'] as String,
      coverPath: map['coverPath'] as String?,
      format: format,
      totalPages: totalPages,
      currentPage: currentPage,
      // Progress is a derived value. Recomputing it repairs historical
      // records where the page was synchronized but the stored percentage
      // had not yet been updated.
      progress: totalPages > 0
          ? ((currentPage +
              (format == BookFormat.epub ? epubChapterProgress : 0)) /
                  totalPages)
              .clamp(0.0, 1.0)
              .toDouble()
          : (map['progress'] as num?)?.toDouble() ?? 0.0,
      epubChapterProgress: epubChapterProgress,
      isCompleted: (map['isCompleted'] == 1 || map['isCompleted'] == true),
      addedDate: DateTime.tryParse(map['addedDate'] as String? ?? '') ??
          DateTime.now(),
      lastReadDate: map['lastReadDate'] != null
          ? DateTime.tryParse(map['lastReadDate'] as String)
          : null,
      fileSize: map['fileSize'] as int? ?? 0,
      serverId: map['serverId'] as String?,
      serverRelativePath: map['serverRelativePath'] as String?,
      contentHash: map['contentHash'] as String?,
      bookmarks: map['bookmarks'] != null
          ? List<int>.from(jsonDecode(map['bookmarks'] as String) as List)
          : [],
      isFavorite: (map['isFavorite'] == 1 || map['isFavorite'] == true),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory BookItem.fromJson(String source) =>
      BookItem.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
