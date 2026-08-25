enum DownloadStatus {
  pending,
  downloading,
  converting,
  paused,
  completed,
  failed,
  cancelled,
}

class DownloadTask {
  final String id;
  final String bookId;
  final String fileName;
  final String remotePath;
  final String serverId;
  final String downloadUrl;
  final DownloadStatus status;
  final double progress; // 0.0 to 1.0
  final int receivedBytes;
  final int totalBytes;
  final double speedBytesPerSec;
  final String? statusDescription;
  final String? errorMessage;
  final DateTime createdAt;

  DownloadTask({
    required this.id,
    required this.bookId,
    required this.fileName,
    required this.remotePath,
    required this.serverId,
    required this.downloadUrl,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.speedBytesPerSec = 0.0,
    this.statusDescription,
    this.errorMessage,
    required this.createdAt,
  });

  DownloadTask copyWith({
    String? id,
    String? bookId,
    String? fileName,
    String? remotePath,
    String? serverId,
    String? downloadUrl,
    DownloadStatus? status,
    double? progress,
    int? receivedBytes,
    int? totalBytes,
    double? speedBytesPerSec,
    String? statusDescription,
    String? errorMessage,
    DateTime? createdAt,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      fileName: fileName ?? this.fileName,
      remotePath: remotePath ?? this.remotePath,
      serverId: serverId ?? this.serverId,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      speedBytesPerSec: speedBytesPerSec ?? this.speedBytesPerSec,
      statusDescription: statusDescription ?? this.statusDescription,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  int get downloadedBytes => receivedBytes;

  String get speedString {
    if (speedBytesPerSec <= 0) return '';
    final mbps = speedBytesPerSec / (1024 * 1024);
    if (mbps >= 1.0) {
      return '${mbps.toStringAsFixed(1)} Mo/s';
    }
    final kbps = speedBytesPerSec / 1024;
    return '${kbps.toStringAsFixed(0)} Ko/s';
  }

  String? get etaString {
    if (status == DownloadStatus.converting) {
      return statusDescription ?? 'Conversion HD en cours...';
    }
    if (speedBytesPerSec <= 0 || totalBytes <= 0 || receivedBytes >= totalBytes) {
      return null;
    }
    final remainingBytes = totalBytes - receivedBytes;
    final seconds = (remainingBytes / speedBytesPerSec).round();
    if (seconds <= 0) return 'Presque terminé...';
    if (seconds < 60) return '~ $seconds s restantes';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '~ ${mins}m ${secs.toString().padLeft(2, '0')}s';
  }
}
