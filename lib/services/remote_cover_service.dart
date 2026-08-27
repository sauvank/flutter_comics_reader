import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/remote_file.dart';
import '../models/server_profile.dart';
import 'cbz_service.dart';

import 'webdav_service.dart';

class RemoteCoverService {
  static final RemoteCoverService _instance = RemoteCoverService._internal();
  factory RemoteCoverService() => _instance;
  RemoteCoverService._internal();

  final WebDavService _webdav = WebDavService();
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

  /// Returns the cached cover file path if available on disk/memory, or null
  Future<String?> getCachedCover(String serverId, String remotePath) async {
    final key = _generateKey(serverId, remotePath);
    if (_memoryCoverCache.containsKey(key)) {
      final cachedPath = _memoryCoverCache[key]!;
      if (File(cachedPath).existsSync()) return cachedPath;
    }
    final cacheDir = await _getCacheDirectory();
    final targetFile = File(p.join(cacheDir.path, '$key.jpg'));
    if (await targetFile.exists()) {
      _memoryCoverCache[key] = targetFile.path;
      return targetFile.path;
    }
    return null;
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
        await targetFile.writeAsBytes(coverBytes, flush: true);
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
      return await _fetchHttpCoverBytes(server, file.path);
    }
  }

  Future<Uint8List?> _fetchHttpCoverBytes(ServerProfile server, String remoteFilePath) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 25),
        sendTimeout: const Duration(seconds: 12),
        validateStatus: (status) => status != null && status >= 200 && status < 400,
      ),
    );

    final rawUrl = _webdav.buildTargetUrl(server, remoteFilePath, isDirectory: false);
    final headers = _webdav.getHeaders(server);

    Future<Uint8List?> tryFetch(String url) async {
      try {
        final response = await dio.get<ResponseBody>(
          url,
          options: Options(
            headers: headers,
            responseType: ResponseType.stream,
            followRedirects: true,
            maxRedirects: 5,
          ),
        );

        final stream = response.data?.stream;
        if (stream == null) return null;

        final chunk = <int>[];
        const maxBytes = 3 * 1024 * 1024; // 3 MB max

        await for (final data in stream) {
          chunk.addAll(data);
          if (chunk.length >= maxBytes) {
            break;
          }
        }

        if (chunk.isEmpty) return null;
        final rawBytes = Uint8List.fromList(chunk);
        return _extractFirstImage(rawBytes, remoteFilePath);
      } catch (e) {
        return null;
      }
    }

    var result = await tryFetch(rawUrl);
    if (result == null || result.isEmpty) {
      final encodedUrl = Uri.encodeFull(rawUrl);
      if (encodedUrl != rawUrl) {
        result = await tryFetch(encodedUrl);
      }
    }
    return result;
  }

  Uint8List? _extractFirstImage(Uint8List bytes, String filename) {
    final lower = filename.toLowerCase();

    // 1. If CBZ/ZIP, try ZIP parser first
    if (lower.endsWith('.cbz') || lower.endsWith('.zip')) {
      final zipImg = _tryParseZipFirstImage(bytes);
      if (zipImg != null && zipImg.isNotEmpty) return zipImg;
    }

    // 2. Try extracting embedded JPEG (works for PDF, CBZ/ZIP raw, etc.)
    final jpeg = _tryExtractJpeg(bytes);
    if (jpeg != null && jpeg.isNotEmpty) return jpeg;

    // 3. Try extracting embedded PNG
    final png = _tryExtractPng(bytes);
    if (png != null && png.isNotEmpty) return png;

    // 4. Try WebP
    final webp = _tryExtractWebp(bytes);
    if (webp != null && webp.isNotEmpty) return webp;

    return null;
  }

  Uint8List? _tryExtractJpeg(Uint8List bytes) {
    for (int i = 0; i < bytes.length - 3; i++) {
      if (bytes[i] == 0xFF && bytes[i + 1] == 0xD8 && bytes[i + 2] == 0xFF) {
        // Found JPEG start marker
        for (int j = i + 5000; j < bytes.length - 1; j++) {
          if (bytes[j] == 0xFF && bytes[j + 1] == 0xD9) {
            // Found JPEG end marker
            final length = (j + 2) - i;
            if (length > 8000) { // At least 8KB
              return bytes.sublist(i, j + 2);
            }
          }
        }
      }
    }
    return null;
  }

  Uint8List? _tryExtractPng(Uint8List bytes) {
    for (int i = 0; i < bytes.length - 8; i++) {
      if (bytes[i] == 0x89 &&
          bytes[i + 1] == 0x50 &&
          bytes[i + 2] == 0x4E &&
          bytes[i + 3] == 0x47 &&
          bytes[i + 4] == 0x0D &&
          bytes[i + 5] == 0x0A &&
          bytes[i + 6] == 0x1A &&
          bytes[i + 7] == 0x0A) {
        for (int j = i + 5000; j < bytes.length - 8; j++) {
          if (bytes[j] == 0x49 &&
              bytes[j + 1] == 0x45 &&
              bytes[j + 2] == 0x4E &&
              bytes[j + 3] == 0x44 &&
              bytes[j + 4] == 0xAE &&
              bytes[j + 5] == 0x42 &&
              bytes[j + 6] == 0x60 &&
              bytes[j + 7] == 0x82) {
            final length = (j + 8) - i;
            if (length > 8000) {
              return bytes.sublist(i, j + 8);
            }
          }
        }
      }
    }
    return null;
  }

  Uint8List? _tryExtractWebp(Uint8List bytes) {
    for (int i = 0; i < bytes.length - 12; i++) {
      if (bytes[i] == 0x52 &&
          bytes[i + 1] == 0x49 &&
          bytes[i + 2] == 0x46 &&
          bytes[i + 3] == 0x46 &&
          bytes[i + 8] == 0x57 &&
          bytes[i + 9] == 0x45 &&
          bytes[i + 10] == 0x42 &&
          bytes[i + 11] == 0x50) {
        final view = ByteData.view(bytes.buffer, bytes.offsetInBytes + i, 8);
        final fileSize = view.getUint32(4, Endian.little) + 8;
        if (fileSize > 8000 && i + fileSize <= bytes.length) {
          return bytes.sublist(i, i + fileSize);
        }
      }
    }
    return null;
  }

  Uint8List? _tryParseZipFirstImage(Uint8List zipChunk) {
    int offset = 0;
    while (offset + 30 < zipChunk.length) {
      if (zipChunk[offset] != 0x50 ||
          zipChunk[offset + 1] != 0x4B ||
          zipChunk[offset + 2] != 0x03 ||
          zipChunk[offset + 3] != 0x04) {
        final nextSig = _findNextLocalHeader(zipChunk, offset + 4);
        if (nextSig > 0) {
          offset = nextSig;
          continue;
        }
        break;
      }

      final view = ByteData.view(zipChunk.buffer, zipChunk.offsetInBytes + offset, 30);
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
          final end = (compressedSize > 0 && dataOffset + compressedSize <= zipChunk.length)
              ? dataOffset + compressedSize
              : zipChunk.length;
          final imgBytes = zipChunk.sublist(dataOffset, end);
          if (imgBytes.length > 100) return imgBytes;
        } else if (compressionMethod == 8) {
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

  Future<Uint8List?> _fetchFtpPartialZipCover(ServerProfile server, String remoteFilePath) async {
    final port = server.port == 80 || server.port == 8080 ? 21 : server.port;
    Socket? controlSocket;
    Socket? dataSocket;

    try {
      controlSocket = await Socket.connect(server.host, port, timeout: const Duration(seconds: 5));
      final reader = _FtpStreamReader(controlSocket);
      await reader.readLine();

      controlSocket.write('USER ${server.username ?? 'anonymous'}\r\n');
      final userResp = await reader.readLine();
      if (userResp.startsWith('331')) {
        controlSocket.write('PASS ${server.password ?? ''}\r\n');
        await reader.readLine();
      }

      controlSocket.write('TYPE I\r\n');
      await reader.readLine();

      controlSocket.write('PASV\r\n');
      final pasvResp = await reader.readLine();
      final endpoint = _parsePasvResponse(pasvResp, server.host);

      dataSocket = await Socket.connect(endpoint.host, endpoint.port, timeout: const Duration(seconds: 5));

      controlSocket.write('RETR $remoteFilePath\r\n');
      await reader.readLine();

      final chunks = <int>[];
      const maxBytes = 2 * 1024 * 1024; // 2MB

      await for (final chunk in dataSocket) {
        chunks.addAll(chunk);
        if (chunks.length >= maxBytes) {
          break;
        }
      }

      if (chunks.isNotEmpty) {
        final raw = Uint8List.fromList(chunks);
        return _extractFirstImage(raw, remoteFilePath);
      }
    } catch (e) {
      debugPrint('FTP partial cover fetch error: $e');
    } finally {
      try {
        await dataSocket?.close();
        dataSocket?.destroy();
      } catch (_) {}
      try {
        controlSocket?.write('QUIT\r\n');
        await controlSocket?.close();
        controlSocket?.destroy();
      } catch (_) {}
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
