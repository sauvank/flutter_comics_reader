import 'book_item.dart';

enum RemoteDownloadStatus {
  notDownloaded,
  inQueue,
  downloading,
  downloaded,
}

class RemoteFile {
  final String name;
  final String path; // e.g. /Comics/Batman/issue1.cbz
  final bool isDirectory;
  final int size; // bytes
  final DateTime? modified;
  final RemoteDownloadStatus downloadStatus;
  final double downloadProgress;
  final String? localBookId;

  RemoteFile({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size = 0,
    this.modified,
    this.downloadStatus = RemoteDownloadStatus.notDownloaded,
    this.downloadProgress = 0.0,
    this.localBookId,
  });

  bool get isSupportedBook {
    if (isDirectory) return false;
    final fmt = BookItem.formatFromExtension(name);
    return fmt != BookFormat.unknown;
  }

  BookFormat get format => BookItem.formatFromExtension(name);

  RemoteFile copyWith({
    String? name,
    String? path,
    bool? isDirectory,
    int? size,
    DateTime? modified,
    RemoteDownloadStatus? downloadStatus,
    double? downloadProgress,
    String? localBookId,
  }) {
    return RemoteFile(
      name: name ?? this.name,
      path: path ?? this.path,
      isDirectory: isDirectory ?? this.isDirectory,
      size: size ?? this.size,
      modified: modified ?? this.modified,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      localBookId: localBookId ?? this.localBookId,
    );
  }
}
