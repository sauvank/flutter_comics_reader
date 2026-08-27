import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';
import 'package:uuid/uuid.dart';
import '../models/book_item.dart';
import '../models/download_task.dart';
import '../models/remote_file.dart';
import '../models/server_profile.dart';
import '../services/cbz_service.dart';
import '../services/database_service.dart';
import '../services/ftp_service.dart';
import '../services/pdf_converter_service.dart';
import '../services/reader_settings_service.dart';
import '../services/remote_cover_service.dart';
import '../services/webdav_service.dart';
import 'library_provider.dart';

class DownloadProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final WebDavService _webdav = WebDavService();
  final FtpService _ftp = FtpService();
  final Map<String, CancelToken> _cancelTokens = {};
  final List<DownloadTask> _tasks = [];
  final Map<String, ({ServerProfile server, RemoteFile file, DownloadTask task})> _pendingQueue = {};

  static const int maxConcurrentDownloads = 2; // Optimal for mobile IO & network bandwidth

  LibraryProvider? _libraryProvider;

  void updateLibraryProvider(LibraryProvider libraryProvider) {
    _libraryProvider = libraryProvider;
  }

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);

  List<DownloadTask> get activeTasks => _tasks
      .where((t) =>
          t.status == DownloadStatus.downloading ||
          t.status == DownloadStatus.converting ||
          t.status == DownloadStatus.pending)
      .toList();

  DownloadTask? getTask(String taskId) {
    try {
      return _tasks.firstWhere((t) => t.id == taskId);
    } catch (_) {
      return null;
    }
  }

  DownloadTask? getTaskForRemotePath(String remotePath) {
    try {
      return _tasks.firstWhere((t) => t.remotePath == remotePath);
    } catch (_) {
      return null;
    }
  }

  DownloadTask? getActiveTaskForRemotePath(String remotePath) {
    try {
      return _tasks.firstWhere(
        (t) =>
            t.remotePath == remotePath &&
            (t.status == DownloadStatus.downloading ||
                t.status == DownloadStatus.converting ||
                t.status == DownloadStatus.pending ||
                t.status == DownloadStatus.paused),
      );
    } catch (_) {
      return null;
    }
  }

  Future<String> enqueueDownload({
    required ServerProfile server,
    required RemoteFile remoteFile,
  }) async {
    // Check if already downloaded and present in local library
    if (_libraryProvider != null) {
      final existingBook = _libraryProvider!.getBookByServerPath(server.id, remoteFile.path);
      if (existingBook != null && File(existingBook.localPath).existsSync()) {
        return existingBook.id;
      }
    }

    // Check if already downloading, converting, or pending
    final active = getActiveTaskForRemotePath(remoteFile.path);
    if (active != null) return active.id;

    final taskId = const Uuid().v4();
    final bookId = 'book_${DateTime.now().millisecondsSinceEpoch}_${remoteFile.name.hashCode.abs()}';

    final task = DownloadTask(
      id: taskId,
      bookId: bookId,
      fileName: remoteFile.name,
      remotePath: remoteFile.path,
      serverId: server.id,
      downloadUrl: '${server.baseUrl}${remoteFile.path}',
      status: DownloadStatus.pending,
      totalBytes: remoteFile.size,
      statusDescription: 'En attente...',
      createdAt: DateTime.now(),
    );

    _tasks.insert(0, task);
    _pendingQueue[taskId] = (server: server, file: remoteFile, task: task);
    notifyListeners();

    _processQueue();
    return taskId;
  }

  Future<List<String>> enqueueMultipleDownloads({
    required ServerProfile server,
    required List<RemoteFile> files,
  }) async {
    final taskIds = <String>[];
    for (final f in files) {
      if (f.isSupportedBook) {
        final id = await enqueueDownload(server: server, remoteFile: f);
        taskIds.add(id);
      }
    }
    return taskIds;
  }

  void _processQueue() {
    final activeCount = _tasks.where((t) =>
        t.status == DownloadStatus.downloading ||
        t.status == DownloadStatus.converting).length;

    if (activeCount >= maxConcurrentDownloads || _pendingQueue.isEmpty) {
      return;
    }

    final availableSlots = maxConcurrentDownloads - activeCount;
    final toStart = _pendingQueue.keys.take(availableSlots).toList();

    for (final taskId in toStart) {
      final item = _pendingQueue.remove(taskId);
      if (item != null) {
        _executeDownload(item.task, item.server, item.file).whenComplete(() {
          _processQueue();
        });
      }
    }
  }

  Future<void> _executeDownload(DownloadTask task, ServerProfile server, RemoteFile remoteFile) async {
    final cancelToken = CancelToken();
    _cancelTokens[task.id] = cancelToken;

    _updateTaskStatus(task.id, DownloadStatus.downloading, statusDescription: 'Téléchargement...');

    final booksDir = await _db.getBooksDirectory();
    final extension = p.extension(task.fileName);
    final localBookPath = p.join(booksDir.path, '${task.bookId}$extension');

    int lastBytes = 0;
    DateTime lastTime = DateTime.now();

    void onProgress(int received, int total) {
      final now = DateTime.now();
      if (received == 0 || received < lastBytes) {
        lastBytes = 0;
        lastTime = now;
      }
      final timeDiff = now.difference(lastTime).inMilliseconds;
      double speed = 0.0;
      if (timeDiff >= 500) {
        final byteDiff = received - lastBytes;
        speed = (byteDiff / (timeDiff / 1000.0));
        lastBytes = received;
        lastTime = now;
      }

      final progress = total > 0 ? (received / total).clamp(0.0, 1.0) : 0.0;
      _updateTaskProgress(task.id, progress, received, total, speed);
    }

    try {
      if (server.serverType == ServerType.ftp) {
        await _ftp.downloadFile(
          server: server,
          remoteRelativePath: task.remotePath,
          destinationLocalPath: localBookPath,
          onProgress: onProgress,
        );
      } else {
        await _webdav.downloadFile(
          server: server,
          remoteRelativePath: task.remotePath,
          destinationLocalPath: localBookPath,
          cancelToken: cancelToken,
          onProgress: onProgress,
        );
      }

      // Post-processing: extract cover and metadata, and auto-convert PDF in background if enabled
      final format = BookItem.formatFromExtension(task.fileName);
      String? coverPath;
      int totalPages = 0;
      String finalLocalPath = localBookPath;
      BookFormat finalFormat = format;

      if (format == BookFormat.pdf && ReaderSettingsService().autoConvertPdfToCbz) {
        _updateTaskStatus(
          task.id,
          DownloadStatus.converting,
          progress: 0.85,
          statusDescription: 'Conversion HD en cours...',
        );

        final cbzPath = p.join(booksDir.path, '${task.bookId}.cbz');
        final converterStream = PdfConverterService().convertPdfToCbz(
          pdfFilePath: localBookPath,
          outputCbzPath: cbzPath,
          registerInDatabase: false,
        );

        await for (final prog in converterStream) {
          final mappedProgress = 0.85 + (prog.progress * 0.15);
          final remainingPages = prog.totalPages - prog.currentPage;
          final approxSec = (remainingPages * 0.4).round();
          final etaText = approxSec > 0 ? ' ~ ${approxSec}s restantes' : '';

          _updateTaskStatus(
            task.id,
            DownloadStatus.converting,
            progress: mappedProgress,
            statusDescription: 'Conversion HD (${prog.currentPage}/${prog.totalPages} pages)$etaText',
          );
        }

        // Delete raw PDF file after successful CBZ creation
        final rawPdfFile = File(localBookPath);
        if (await rawPdfFile.exists()) {
          await rawPdfFile.delete();
        }

        finalLocalPath = cbzPath;
        finalFormat = BookFormat.cbz;
      }

      if (finalFormat == BookFormat.cbz || finalFormat == BookFormat.zip) {
        final coversDir = await _db.getCoversDirectory();
        final targetCover = p.join(coversDir.path, '${task.bookId}.jpg');
        coverPath = await CbzService.extractCover(
          cbzFilePath: finalLocalPath,
          targetCoverPath: targetCover,
        );
        totalPages = await CbzService.getPageCount(finalLocalPath);
      } else if (finalFormat == BookFormat.pdf) {
        try {
          final coversDir = await _db.getCoversDirectory();
          final targetCover = p.join(coversDir.path, '${task.bookId}.jpg');

          // Check if remote cover was already cached first
          final cachedRemoteCover = await RemoteCoverService().getCachedCover(server.id, task.remotePath);
          if (cachedRemoteCover != null && await File(cachedRemoteCover).exists()) {
            await File(cachedRemoteCover).copy(targetCover);
            coverPath = targetCover;
          }

          final doc = await PdfDocument.openFile(finalLocalPath);
          totalPages = doc.pages.length;

          if (coverPath == null && doc.pages.isNotEmpty) {
            final page = doc.pages[0];
            final img = await page.render(fullWidth: 600, fullHeight: 900);
            if (img != null) {
              final uiImg = await img.createImage();
              final byteData = await uiImg.toByteData(format: ui.ImageByteFormat.png);
              img.dispose();
              uiImg.dispose();
              if (byteData != null) {
                final f = File(targetCover);
                await f.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
                coverPath = targetCover;
              }
            }
          }
          await doc.dispose();
        } catch (e) {
          debugPrint('PDF metadata extraction error on download: $e');
        }
      }

      final downloadedFile = File(finalLocalPath);
      final fileSize = await downloadedFile.exists() ? await downloadedFile.length() : task.totalBytes;

      // Clean display title (remove extension and replace underscores)
      var cleanTitle = p.basenameWithoutExtension(task.fileName).replaceAll('_', ' ');

      final newBook = BookItem(
        id: task.bookId,
        title: cleanTitle,
        originalFilename: p.basename(finalLocalPath),
        localPath: finalLocalPath,
        coverPath: coverPath,
        format: finalFormat,
        totalPages: totalPages,
        currentPage: 0,
        progress: 0.0,
        isCompleted: false,
        addedDate: DateTime.now(),
        fileSize: fileSize,
        serverId: server.id,
        serverRelativePath: task.remotePath,
      );

      await _db.addBook(newBook);
      await _libraryProvider?.loadLibrary();

      _updateTaskStatus(
        task.id,
        DownloadStatus.completed,
        progress: 1.0,
        statusDescription: 'Terminé',
      );
    } catch (e) {
      if (cancelToken.isCancelled) {
        _updateTaskStatus(task.id, DownloadStatus.cancelled, statusDescription: 'Annulé');
      } else {
        debugPrint('Download failed for ${task.fileName}: $e');
        final cleanMsg = _formatDownloadError(e);
        _updateTaskStatus(task.id, DownloadStatus.failed, errorMessage: cleanMsg, statusDescription: 'Échec');
      }
    } finally {
      _cancelTokens.remove(task.id);
      _pendingQueue.remove(task.id);
    }
  }

  String _formatDownloadError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Délai d\'attente dépassé (timeout réseau)';
        case DioExceptionType.badCertificate:
          return 'Certificat de sécurité invalide (serveur auto-signé ?)';
        case DioExceptionType.badResponse:
          final code = error.response?.statusCode;
          if (code == 404) return 'Fichier introuvable sur le serveur (404)';
          if (code == 401 || code == 403) return 'Accès refusé (identifiants incorrects)';
          return 'Erreur serveur${code != null ? ' ($code)' : ''}';
        case DioExceptionType.connectionError:
          return 'Impossible de joindre le serveur (connexion perdue)';
        case DioExceptionType.cancel:
          return 'Téléchargement annulé';
        case DioExceptionType.unknown:
        default:
          if (error.error != null) {
            final inner = error.error.toString().toLowerCase();
            if (inner.contains('socket') || inner.contains('network') || inner.contains('broken pipe') || inner.contains('connection reset')) {
              return 'Connexion réseau interrompue';
            }
            if (inner.contains('space') || inner.contains('enospc')) {
              return 'Espace de stockage insuffisant sur l\'appareil';
            }
          }
          return 'Erreur de connexion réseau';
      }
    }
    if (error is SocketException) {
      return 'Connexion réseau interrompue';
    }
    if (error is FileSystemException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('no space') || msg.contains('enospc')) {
        return 'Espace de stockage insuffisant sur l\'appareil';
      }
      return 'Erreur d\'accès au fichier local';
    }
    return error.toString();
  }

  void cancelDownload(String taskId) {
    _pendingQueue.remove(taskId);
    final token = _cancelTokens[taskId];
    token?.cancel();
    _updateTaskStatus(taskId, DownloadStatus.cancelled, statusDescription: 'Annulé');
    _processQueue();
  }

  void clearCompleted() {
    clearCompletedTasks();
  }

  void clearCompletedTasks() {
    _tasks.removeWhere(
      (t) =>
          t.status == DownloadStatus.completed ||
          t.status == DownloadStatus.failed ||
          t.status == DownloadStatus.cancelled,
    );
    notifyListeners();
  }

  void retryDownload(String taskId, ServerProfile server) {
    final task = getTask(taskId);
    if (task == null) return;

    final remoteFile = RemoteFile(
      name: task.fileName,
      path: task.remotePath,
      size: task.totalBytes,
      modified: DateTime.now(),
      isDirectory: false,
    );

    _updateTaskStatus(taskId, DownloadStatus.pending, progress: 0.0, statusDescription: 'En attente...');
    _pendingQueue[taskId] = (server: server, file: remoteFile, task: task);
    _processQueue();
  }

  void _updateTaskStatus(
    String taskId,
    DownloadStatus status, {
    double? progress,
    String? statusDescription,
    String? errorMessage,
  }) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index >= 0) {
      _tasks[index] = _tasks[index].copyWith(
        status: status,
        progress: progress ?? _tasks[index].progress,
        statusDescription: statusDescription ?? _tasks[index].statusDescription,
        errorMessage: errorMessage,
      );
      notifyListeners();
    }
  }

  void _updateTaskProgress(
    String taskId,
    double progress,
    int receivedBytes,
    int totalBytes,
    double speed,
  ) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index >= 0) {
      _tasks[index] = _tasks[index].copyWith(
        progress: progress,
        receivedBytes: receivedBytes,
        totalBytes: totalBytes,
        speedBytesPerSec: speed,
      );
      notifyListeners();
    }
  }
}
