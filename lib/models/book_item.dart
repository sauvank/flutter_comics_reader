import 'dart:convert';

enum BookFormat {
  cbz,
  cbr,
  pdf,
  zip,
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
  final bool isCompleted;
  final DateTime addedDate;
  final DateTime? lastReadDate;
  final int fileSize; // bytes
  final String? serverId;
  final String? serverRelativePath;
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
    this.isCompleted = false,
    required this.addedDate,
    this.lastReadDate,
    this.fileSize = 0,
    this.serverId,
    this.serverRelativePath,
    List<int>? bookmarks,
    this.isFavorite = false,
  }) : bookmarks = bookmarks ?? [];

  static BookFormat formatFromExtension(String pathOrName) {
    final lower = pathOrName.toLowerCase();
    if (lower.endsWith('.cbz')) return BookFormat.cbz;
    if (lower.endsWith('.cbr')) return BookFormat.cbr;
    if (lower.endsWith('.pdf')) return BookFormat.pdf;
    if (lower.endsWith('.zip')) return BookFormat.zip;
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
    bool? isCompleted,
    DateTime? addedDate,
    DateTime? lastReadDate,
    int? fileSize,
    String? serverId,
    String? serverRelativePath,
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
      isCompleted: isCompleted ?? this.isCompleted,
      addedDate: addedDate ?? this.addedDate,
      lastReadDate: lastReadDate ?? this.lastReadDate,
      fileSize: fileSize ?? this.fileSize,
      serverId: serverId ?? this.serverId,
      serverRelativePath: serverRelativePath ?? this.serverRelativePath,
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
      'isCompleted': isCompleted ? 1 : 0,
      'addedDate': addedDate.toIso8601String(),
      'lastReadDate': lastReadDate?.toIso8601String(),
      'fileSize': fileSize,
      'serverId': serverId,
      'serverRelativePath': serverRelativePath,
      'bookmarks': jsonEncode(bookmarks),
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory BookItem.fromMap(Map<String, dynamic> map) {
    return BookItem(
      id: map['id'] as String,
      title: map['title'] as String,
      originalFilename: map['originalFilename'] as String? ?? map['title'] as String,
      localPath: map['localPath'] as String,
      coverPath: map['coverPath'] as String?,
      format: BookFormat.values.firstWhere(
        (e) => e.name == map['format'],
        orElse: () => BookFormat.unknown,
      ),
      totalPages: map['totalPages'] as int? ?? 0,
      currentPage: map['currentPage'] as int? ?? 0,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      isCompleted: (map['isCompleted'] == 1 || map['isCompleted'] == true),
      addedDate: DateTime.tryParse(map['addedDate'] as String? ?? '') ?? DateTime.now(),
      lastReadDate: map['lastReadDate'] != null ? DateTime.tryParse(map['lastReadDate'] as String) : null,
      fileSize: map['fileSize'] as int? ?? 0,
      serverId: map['serverId'] as String?,
      serverRelativePath: map['serverRelativePath'] as String?,
      bookmarks: map['bookmarks'] != null
          ? List<int>.from(jsonDecode(map['bookmarks'] as String) as List)
          : [],
      isFavorite: (map['isFavorite'] == 1 || map['isFavorite'] == true),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory BookItem.fromJson(String source) => BookItem.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
