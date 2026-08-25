import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/remote_file.dart';
import '../models/server_profile.dart';
import 'cbz_service.dart';

class RemoteCoverService {
  static final RemoteCoverService _instance = RemoteCoverService._internal();
  factory RemoteCoverService() => _instance;
  RemoteCoverService._internal();

  final Map<String, String> _memoryCoverCache = {};
  final Set<String> _pendingRequests = {};

  Directory? _cacheDir;

  Future<Directory> _getCacheDirectory() async {
    if (_cacheDir != null) return _cacheDir!;
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory(p.join(appDir.path, 'remote_covers_cache'));
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    return _cacheDir!;
  }

  String _generateKey(String serverId, String remotePath) {
    final raw = '$serverId:$remotePath';
    return raw.hashCode.toRadixString(16);
  }

  /// Returns the cached cover file path if available, or null
  String? getCachedCoverSync(ServerProfile server, RemoteFile file) {
    final key = _generateKey(server.id, file.path);
    return _memoryCoverCache[key];
  }

  void setCachedCover(String serverId, String remotePath, String localCoverPath) {
    final key = _generateKey(serverId, remotePath);
    _memoryCoverCache[key] = localCoverPath;
  }

  /// Gets or downloads in background the cover thumbnail for a remote book
  Future<String?> getCoverForRemoteBook({
    required ServerProfile server,
    required RemoteFile file,
    bool priority = false,
  }) async {
    final key = _generateKey(server.id, file.path);

    if (_memoryCoverCache.containsKey(key)) {
      final cachedPath = _memoryCoverCache[key]!;
      if (File(cachedPath).existsSync()) {
        return cachedPath;
      }
    }

    final cacheDir = await _getCacheDirectory();
    final targetFile = File(p.join(cacheDir.path, '$key.jpg'));

    if (await targetFile.exists()) {
      _memoryCoverCache[key] = targetFile.path;
      return targetFile.path;
    }

    if (_pendingRequests.contains(key)) {
      return null;
    }

    _pendingRequests.add(key);

    try {
      final coverBytes = await _extractFirstImageBytesFromRemote(server, file);
      if (coverBytes != null && coverBytes.isNotEmpty) {
        await targetFile.writeAsBytes(coverBytes);
        _memoryCoverCache[key] = targetFile.path;
        return targetFile.path;
      }
    } catch (e) {
      debugPrint('RemoteCoverService: Error extracting cover for ${file.name}: $e');
    } finally {
      _pendingRequests.remove(key);
    }

    return null;
  }

  Future<Uint8List?> _extractFirstImageBytesFromRemote(ServerProfile server, RemoteFile file) async {
    if (server.serverType == ServerType.ftp) {
      return await _fetchFtpPartialZipCover(server, file.path);
    }
    return null;
  }

  Future<Uint8List?> _fetchFtpPartialZipCover(ServerProfile server, String remoteFilePath) async {
    final port = server.port == 80 || server.port == 8080 ? 21 : server.port;
    Socket? controlSocket;
    Socket? dataSocket;

    try {
      controlSocket = await Socket.connect(server.host, port, timeout: const Duration(seconds: 5));
      final reader = _FtpStreamReader(controlSocket);
      await reader.readLine(); // Banner

      // Login
      controlSocket.write('USER ${server.username ?? 'anonymous'}\r\n');
      final userResp = await reader.readLine();
      if (userResp.startsWith('331')) {
        controlSocket.write('PASS ${server.password ?? ''}\r\n');
        await reader.readLine();
      }

      controlSocket.write('TYPE I\r\n');
      await reader.readLine();

      // Navigate to directory
      final cleanRelative = remoteFilePath.replaceAll('\\', '/').replaceAll(RegExp(r'^/+'), '');
      final lastSlash = cleanRelative.lastIndexOf('/');
      String dirPart = '';
      String filePart = cleanRelative;

      if (lastSlash >= 0) {
        dirPart = cleanRelative.substring(0, lastSlash);
        filePart = cleanRelative.substring(lastSlash + 1);
      }

      controlSocket.write('CWD /$dirPart\r\n');
      var cwdResp = await reader.readLine();
      if (!cwdResp.startsWith('250')) {
        controlSocket.write('CWD $dirPart\r\n');
        await reader.readLine();
      }

      // Enter Passive Mode
      controlSocket.write('PASV\r\n');
      final pasvResp = await reader.readLine();
      final dataEndpoint = _parsePasvResponse(pasvResp, server.host);

      dataSocket = await Socket.connect(dataEndpoint.host, dataEndpoint.port, timeout: const Duration(seconds: 6));

      controlSocket.write('RETR $filePart\r\n');
      final retrResp = await reader.readLine();
      if (!retrResp.startsWith('150') && !retrResp.startsWith('125')) {
        return null;
      }

      // Read only the first 500 KB to find the first image
      final buffer = BytesBuilder();
      final completer = Completer<Uint8List?>();
      const maxHeaderBytes = 600 * 1024; // 600 KB max for cover extraction

      StreamSubscription? sub;
      sub = dataSocket.listen(
        (chunk) {
          buffer.add(chunk);
          if (buffer.length >= maxHeaderBytes) {
            sub?.cancel();
            dataSocket?.destroy();
            final partial = buffer.takeBytes();
            final cover = _tryParseZipFirstImage(partial);
            if (!completer.isCompleted) completer.complete(cover);
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            final partial = buffer.takeBytes();
            final cover = _tryParseZipFirstImage(partial);
            completer.complete(cover);
          }
        },
        onError: (err) {
          if (!completer.isCompleted) completer.complete(null);
        },
        cancelOnError: true,
      );

      final result = await completer.future.timeout(const Duration(seconds: 6), onTimeout: () => null);
      return result;
    } catch (_) {
      return null;
    } finally {
      try {
        dataSocket?.destroy();
        controlSocket?.write('QUIT\r\n');
        controlSocket?.destroy();
      } catch (_) {}
    }
  }

  Uint8List? _tryParseZipFirstImage(Uint8List zipChunk) {
    if (zipChunk.length < 30) return null;

    final view = ByteData.sublistView(zipChunk);

    // Check Local File Header Signature: 0x04034b50 (PK\x03\x04)
    final sig = view.getUint32(0, Endian.little);
    if (sig != 0x04034b50) return null;

    final compressionMethod = view.getUint16(8, Endian.little);
    final compressedSize = view.getUint32(18, Endian.little);
    final fileNameLen = view.getUint16(26, Endian.little);
    final extraFieldLen = view.getUint16(28, Endian.little);

    if (30 + fileNameLen > zipChunk.length) return null;

    final fileNameBytes = zipChunk.sublist(30, 30 + fileNameLen);
    final fileName = utf8.decode(fileNameBytes, allowMalformed: true);

    if (!CbzService.isImageFile(fileName)) {
      // If first entry is a folder or metadata, try archive decoder on small chunk
      try {
        final archive = ZipDecoder().decodeBytes(zipChunk, verify: false);
        for (final f in archive.files) {
          if (f.isFile && CbzService.isImageFile(f.name)) {
            final bytes = f.readBytes();
            if (bytes != null && bytes.length > 100) {
              return Uint8List.fromList(bytes);
            }
          }
        }
      } catch (_) {}
      return null;
    }

    final dataOffset = 30 + fileNameLen + extraFieldLen;
    if (dataOffset >= zipChunk.length) return null;

    if (compressionMethod == 0) {
      // Stored / uncompressed
      final end = (compressedSize > 0 && dataOffset + compressedSize <= zipChunk.length)
          ? dataOffset + compressedSize
          : zipChunk.length;
      return zipChunk.sublist(dataOffset, end);
    } else if (compressionMethod == 8) {
      // Deflate
      try {
        final compressed = (compressedSize > 0 && dataOffset + compressedSize <= zipChunk.length)
            ? zipChunk.sublist(dataOffset, dataOffset + compressedSize)
            : zipChunk.sublist(dataOffset);

        final decompressed = Inflate(compressed).getBytes();
        return Uint8List.fromList(decompressed);
      } catch (_) {
        // Fallback to archive decoder
        try {
          final archive = ZipDecoder().decodeBytes(zipChunk, verify: false);
          for (final f in archive.files) {
            if (f.isFile && CbzService.isImageFile(f.name)) {
              final bytes = f.readBytes();
              if (bytes != null) return Uint8List.fromList(bytes);
            }
          }
        } catch (_) {}
      }
    }

    return null;
  }

  _FtpEndpoint _parsePasvResponse(String response, String fallbackHost) {
    final regex = RegExp(r'\((\d+),(\d+),(\d+),(\d+),(\d+),(\d+)\)');
    final match = regex.firstMatch(response);
    if (match != null) {
      final ip = '${match.group(1)}.${match.group(2)}.${match.group(3)}.${match.group(4)}';
      final p1 = int.parse(match.group(5)!);
      final p2 = int.parse(match.group(6)!);
      final port = (p1 * 256) + p2;
      return _FtpEndpoint(fallbackHost.isNotEmpty ? fallbackHost : ip, port);
    }
    throw Exception('Réponse PASV non reconnue: $response');
  }
}

class _FtpEndpoint {
  final String host;
  final int port;
  _FtpEndpoint(this.host, this.port);
}

class _FtpStreamReader {
  final Socket socket;
  final List<int> _buffer = [];
  final StreamIterator<List<int>> _iterator;

  _FtpStreamReader(this.socket) : _iterator = StreamIterator(socket);

  Future<String> readLine() async {
    while (true) {
      final newlineIdx = _buffer.indexOf(10);
      if (newlineIdx >= 0) {
        final lineBytes = _buffer.sublist(0, newlineIdx);
        _buffer.removeRange(0, newlineIdx + 1);
        return utf8.decode(lineBytes, allowMalformed: true).trim();
      }

      if (await _iterator.moveNext()) {
        _buffer.addAll(_iterator.current);
      } else {
        if (_buffer.isNotEmpty) {
          final line = utf8.decode(_buffer, allowMalformed: true).trim();
          _buffer.clear();
          return line;
        }
        return '';
      }
    }
  }
}
