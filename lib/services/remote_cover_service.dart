import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
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
    } else {
      return await _fetchHttpPartialZipCover(server, file.path);
    }
  }

  Future<Uint8List?> _fetchHttpPartialZipCover(ServerProfile server, String remoteFilePath) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 8),
        validateStatus: (status) => status != null && (status >= 200 && status < 400),
      ),
    );

    var base = server.baseUrl;
    if (!base.endsWith('/')) base = '$base/';

    var cleanPath = remoteFilePath.trim();
    var serverBasePath = Uri.parse(base).path.replaceAll(RegExp(r'^/+'), '').replaceAll(RegExp(r'/+$'), '');
    var cleanRelative = cleanPath.replaceAll(RegExp(r'^/+'), '').replaceAll(RegExp(r'/+$'), '');
    if (cleanRelative == serverBasePath) {
      cleanRelative = '';
    } else if (serverBasePath.isNotEmpty && cleanRelative.startsWith('$serverBasePath/')) {
      cleanRelative = cleanRelative.substring(serverBasePath.length + 1);
    }

    final baseUri = Uri.parse(base);
    final allSegments = [
      ...baseUri.pathSegments.where((s) => s.isNotEmpty),
      ...cleanRelative.split('/').where((s) => s.isNotEmpty),
    ];
    final fileUri = baseUri.replace(pathSegments: allSegments);
    final fileUrl = fileUri.toString();

    final headers = <String, String>{
      'User-Agent': 'ComicStream-App/1.0',
      'Range': 'bytes=0-2097151', // Fetch first 2 MB
    };
    if (server.username != null && server.username!.isNotEmpty) {
      final authStr = '${server.username}:${server.password ?? ''}';
      final base64Auth = base64Encode(utf8.encode(authStr));
      headers['Authorization'] = 'Basic $base64Auth';
    }

    try {
      final response = await dio.get<List<int>>(
        fileUrl,
        options: Options(
          headers: headers,
          responseType: ResponseType.bytes,
          followRedirects: true,
          maxRedirects: 5,
        ),
      );

      final data = response.data;
      if (data == null || data.isEmpty) return null;

      final chunk = Uint8List.fromList(data);
      return _tryParseZipFirstImage(chunk);
    } catch (e) {
      debugPrint('RemoteCoverService: HTTP Range cover extraction error on $fileUrl: $e');
      return null;
    }
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

    int offset = 0;
    while (offset + 30 <= zipChunk.length) {
      final view = ByteData.sublistView(zipChunk, offset);

      // Check Local File Header Signature: 0x04034b50 (PK\x03\x04)
      final sig = view.getUint32(0, Endian.little);
      if (sig != 0x04034b50) {
        // Try searching for next PK\x03\x04 header in the chunk
        final nextSig = _findNextLocalHeader(zipChunk, offset + 4);
        if (nextSig > 0) {
          offset = nextSig;
          continue;
        }
        break;
      }

      final compressionMethod = view.getUint16(8, Endian.little);
      final compressedSize = view.getUint32(18, Endian.little);
      final fileNameLen = view.getUint16(26, Endian.little);
      final extraFieldLen = view.getUint16(28, Endian.little);

      if (offset + 30 + fileNameLen > zipChunk.length) break;

      final fileNameBytes = zipChunk.sublist(offset + 30, offset + 30 + fileNameLen);
      final fileName = utf8.decode(fileNameBytes, allowMalformed: true);

      final dataOffset = offset + 30 + fileNameLen + extraFieldLen;

      if (CbzService.isImageFile(fileName) && dataOffset < zipChunk.length) {
        if (compressionMethod == 0) {
          // Stored / uncompressed
          final end = (compressedSize > 0 && dataOffset + compressedSize <= zipChunk.length)
              ? dataOffset + compressedSize
              : zipChunk.length;
          final imgBytes = zipChunk.sublist(dataOffset, end);
          if (imgBytes.length > 100) return imgBytes;
        } else if (compressionMethod == 8) {
          // Deflate
          try {
            final compressed = (compressedSize > 0 && dataOffset + compressedSize <= zipChunk.length)
                ? zipChunk.sublist(dataOffset, dataOffset + compressedSize)
                : zipChunk.sublist(dataOffset);

            final decompressed = Inflate(compressed).getBytes();
            if (decompressed.isNotEmpty) {
              return Uint8List.fromList(decompressed);
            }
          } catch (_) {}
        }
      }

      // Advance offset to next entry
      if (compressedSize > 0 && dataOffset + compressedSize < zipChunk.length) {
        offset = dataOffset + compressedSize;
      } else {
        final nextSig = _findNextLocalHeader(zipChunk, offset + 4);
        if (nextSig > 0) {
          offset = nextSig;
        } else {
          break;
        }
      }
    }

    return null;
  }

  int _findNextLocalHeader(Uint8List bytes, int start) {
    for (int i = start; i <= bytes.length - 4; i++) {
      if (bytes[i] == 0x50 && bytes[i + 1] == 0x4B && bytes[i + 2] == 0x03 && bytes[i + 3] == 0x04) {
        return i;
      }
    }
    return -1;
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
