import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/remote_file.dart';
import '../models/server_profile.dart';

class FtpService {
  /// Tests FTP connection with credentials
  Future<bool> testConnection(ServerProfile server) async {
    Socket? controlSocket;
    try {
      controlSocket = await Socket.connect(
        server.host,
        server.port == 80 || server.port == 8080 ? 21 : server.port,
        timeout: const Duration(seconds: 5),
      );

      final reader = _FtpStreamReader(controlSocket);
      final banner = await reader.readLine();
      if (!banner.startsWith('220')) return false;

      // Send USER
      controlSocket.write('USER ${server.username ?? 'anonymous'}\r\n');
      final userResp = await reader.readLine();

      if (userResp.startsWith('331')) {
        // Needs password
        controlSocket.write('PASS ${server.password ?? ''}\r\n');
        final passResp = await reader.readLine();
        if (!passResp.startsWith('230')) return false;
      } else if (!userResp.startsWith('230')) {
        return false;
      }

      controlSocket.write('QUIT\r\n');
      return true;
    } catch (e) {
      debugPrint('FTP testConnection error: $e');
      return false;
    } finally {
      controlSocket?.destroy();
    }
  }

  /// Verifies that the specific folder path actually exists on the FTP server
  Future<bool> testPathExists(ServerProfile server, [String? customPath]) async {
    final port = server.port == 80 || server.port == 8080 ? 21 : server.port;
    Socket? controlSocket;
    try {
      controlSocket = await Socket.connect(
        server.host,
        port,
        timeout: const Duration(seconds: 5),
      );

      final reader = _FtpStreamReader(controlSocket);
      final banner = await reader.readLine();
      if (!banner.startsWith('220')) return false;

      // Send USER
      controlSocket.write('USER ${server.username ?? 'anonymous'}\r\n');
      final userResp = await reader.readLine();

      if (userResp.startsWith('331')) {
        controlSocket.write('PASS ${server.password ?? ''}\r\n');
        final passResp = await reader.readLine();
        if (!passResp.startsWith('230')) return false;
      } else if (!userResp.startsWith('230')) {
        return false;
      }

      final pathToTest = (customPath ?? server.path).replaceAll('\\', '/').trim();
      if (pathToTest.isEmpty || pathToTest == '/') {
        return true;
      }

      final targetPath = await _smartNavigateToTarget(
        controlSocket,
        reader,
        server,
        pathToTest,
      );

      return targetPath.isNotEmpty && targetPath != '/';
    } catch (e) {
      debugPrint('FTP testPathExists error: $e');
      return false;
    } finally {
      try {
        controlSocket?.write('QUIT\r\n');
      } catch (_) {}
      controlSocket?.destroy();
    }
  }

  /// Lists files and directories at [remoteRelativePath]
  Future<List<RemoteFile>> listDirectory({
    required ServerProfile server,
    String remoteRelativePath = '',
  }) async {
    final port = server.port == 80 || server.port == 8080 ? 21 : server.port;
    final controlSocket = await Socket.connect(
      server.host,
      port,
      timeout: const Duration(seconds: 10),
    );

    final reader = _FtpStreamReader(controlSocket);

    try {
      final banner = await reader.readLine();
      if (!banner.startsWith('220')) {
        throw Exception('Serveur FTP invalide: $banner');
      }

      // Login
      controlSocket.write('USER ${server.username ?? 'anonymous'}\r\n');
      final userResp = await reader.readLine();

      if (userResp.startsWith('331')) {
        controlSocket.write('PASS ${server.password ?? ''}\r\n');
        final passResp = await reader.readLine();
        if (!passResp.startsWith('230')) {
          throw Exception('Identifiants FTP refusés: $passResp');
        }
      } else if (!userResp.startsWith('230')) {
        throw Exception('Identifiant FTP refusé: $userResp');
      }

      // Set UTF8 & Binary
      controlSocket.write('OPTS UTF8 ON\r\n');
      await reader.readLine();

      controlSocket.write('TYPE I\r\n');
      await reader.readLine();

      // Smart Navigate to target directory
      final currentEffectivePath = await _smartNavigateToTarget(
        controlSocket,
        reader,
        server,
        remoteRelativePath,
      );

      // Enter Passive Mode
      controlSocket.write('PASV\r\n');
      final pasvResp = await reader.readLine();
      if (!pasvResp.startsWith('227')) {
        throw Exception('Mode passif FTP échoué: $pasvResp');
      }

      final dataEndpoint = _parsePasvResponse(pasvResp, server.host);
      final dataSocket = await Socket.connect(
        dataEndpoint.host,
        dataEndpoint.port,
        timeout: const Duration(seconds: 10),
      );

      // Try MLSD first, fallback to LIST -la, then LIST
      controlSocket.write('MLSD\r\n');
      var listResp = await reader.readLine();
      bool isMlsd = listResp.startsWith('150') || listResp.startsWith('125');

      if (!isMlsd) {
        controlSocket.write('LIST -la\r\n');
        listResp = await reader.readLine();
        if (!listResp.startsWith('150') && !listResp.startsWith('125')) {
          controlSocket.write('LIST\r\n');
          await reader.readLine();
        }
      }

      // Read all data from dataSocket
      final dataBuffer = StringBuffer();
      final completer = Completer<String>();

      dataSocket.listen(
        (chunk) => dataBuffer.write(utf8.decode(chunk, allowMalformed: true)),
        onDone: () => completer.complete(dataBuffer.toString()),
        onError: (err) => completer.completeError(err),
        cancelOnError: true,
      );

      final rawListing = await completer.future;
      await dataSocket.close();

      // Read transfer complete on control socket
      await reader.readLine();

      debugPrint('FTP: Target "$currentEffectivePath", received listing:\n$rawListing');

      if (isMlsd) {
        return _parseMlsdListing(rawListing, currentEffectivePath);
      } else {
        return _parseGeneralListing(rawListing, currentEffectivePath);
      }
    } finally {
      try {
        controlSocket.write('QUIT\r\n');
      } catch (_) {}
      controlSocket.destroy();
    }
  }

  Future<String> _smartNavigateToTarget(
    Socket socket,
    _FtpStreamReader reader,
    ServerProfile server,
    String remoteRelativePath,
  ) async {
    String target;
    if (remoteRelativePath.isNotEmpty) {
      target = remoteRelativePath;
    } else {
      target = server.path;
    }

    target = target.replaceAll('\\', '/').trim();
    if (target.isEmpty || target == '/') {
      socket.write('CWD /\r\n');
      await reader.readLine();
      return '/';
    }

    final cleanTarget = target.replaceAll(RegExp(r'/+'), '/');
    final absoluteTarget = cleanTarget.startsWith('/') ? cleanTarget : '/$cleanTarget';
    final relativeTarget = cleanTarget.replaceAll(RegExp(r'^/+'), '');

    // 1. Direct absolute CWD (e.g. /home/shares/public/BOOKS)
    socket.write('CWD $absoluteTarget\r\n');
    var resp = await reader.readLine();
    if (resp.startsWith('250')) {
      debugPrint('FTP: CWD absolute success to: $absoluteTarget');
      return absoluteTarget;
    }

    // 2. Direct relative CWD (e.g. home/shares/public/BOOKS)
    socket.write('CWD $relativeTarget\r\n');
    resp = await reader.readLine();
    if (resp.startsWith('250')) {
      debugPrint('FTP: CWD relative success to: $relativeTarget');
      return absoluteTarget;
    }

    // 3. Try with common prefixes
    final username = server.username ?? 'pi';
    final prefixes = [
      '/home/$username',
      '/mnt',
      '/media',
      '/srv',
    ];

    for (final pref in prefixes) {
      final testCand = '$pref/$relativeTarget'.replaceAll(RegExp(r'/+'), '/');
      socket.write('CWD $testCand\r\n');
      resp = await reader.readLine();
      if (resp.startsWith('250')) {
        debugPrint('FTP: CWD prefixed success to: $testCand');
        return testCand;
      }
    }

    // 4. Segment by segment from root /
    socket.write('CWD /\r\n');
    await reader.readLine();

    final segments = relativeTarget.split('/').where((s) => s.isNotEmpty).toList();
    final traversed = <String>[];
    for (final seg in segments) {
      socket.write('CWD $seg\r\n');
      resp = await reader.readLine();
      if (resp.startsWith('250')) {
        traversed.add(seg);
        continue;
      }
      break;
    }

    if (traversed.isNotEmpty) {
      return '/${traversed.join('/')}';
    }

    // Fallback stay at /
    socket.write('CWD /\r\n');
    await reader.readLine();
    return '/';
  }

  /// Downloads file from FTP with progress callback
  Future<void> downloadFile({
    required ServerProfile server,
    required String remoteRelativePath,
    required String destinationLocalPath,
    required void Function(int receivedBytes, int totalBytes) onProgress,
  }) async {
    final port = server.port == 80 || server.port == 8080 ? 21 : server.port;
    final controlSocket = await Socket.connect(
      server.host,
      port,
      timeout: const Duration(seconds: 10),
    );

    final reader = _FtpStreamReader(controlSocket);

    try {
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

      // Extract directory part and filename part
      final cleanRelative = remoteRelativePath.replaceAll('\\', '/');
      final lastSlash = cleanRelative.lastIndexOf('/');
      String dirPart = '';
      String filePart = cleanRelative;

      if (lastSlash >= 0) {
        dirPart = cleanRelative.substring(0, lastSlash);
        filePart = cleanRelative.substring(lastSlash + 1);
      }

      await _smartNavigateToTarget(controlSocket, reader, server, dirPart);

      // Get file size
      int totalBytes = 0;
      controlSocket.write('SIZE $filePart\r\n');
      final sizeResp = await reader.readLine();
      if (sizeResp.startsWith('213')) {
        totalBytes = int.tryParse(sizeResp.substring(4).trim()) ?? 0;
      }

      // Enter Passive Mode
      controlSocket.write('PASV\r\n');
      final pasvResp = await reader.readLine();
      final dataEndpoint = _parsePasvResponse(pasvResp, server.host);

      final dataSocket = await Socket.connect(
        dataEndpoint.host,
        dataEndpoint.port,
        timeout: const Duration(seconds: 15),
      );

      controlSocket.write('RETR $filePart\r\n');
      final retrResp = await reader.readLine();
      if (!retrResp.startsWith('150') && !retrResp.startsWith('125')) {
        throw Exception('Impossible de télécharger le fichier FTP: $retrResp');
      }

      final tempFile = File('$destinationLocalPath.tmp');
      if (await tempFile.exists()) await tempFile.delete();
      final sink = tempFile.openWrite();

      int receivedBytes = 0;
      final completer = Completer<void>();

      dataSocket.listen(
        (data) {
          sink.add(data);
          receivedBytes += data.length;
          onProgress(receivedBytes, totalBytes);
        },
        onDone: () async {
          await sink.flush();
          await sink.close();
          completer.complete();
        },
        onError: (err) async {
          await sink.close();
          completer.completeError(err);
        },
        cancelOnError: true,
      );

      await completer.future;
      await dataSocket.close();

      // Read transfer complete
      await reader.readLine();

      // Move temp to destination
      final finalFile = File(destinationLocalPath);
      if (await finalFile.exists()) await finalFile.delete();
      await tempFile.rename(destinationLocalPath);
    } finally {
      try {
        controlSocket.write('QUIT\r\n');
      } catch (_) {}
      controlSocket.destroy();
    }
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

  List<RemoteFile> _parseMlsdListing(String rawListing, String currentPath) {
    final List<RemoteFile> results = [];
    final lines = rawListing.split(RegExp(r'\r?\n'));

    var cleanBase = currentPath.replaceAll(RegExp(r'/+$'), '');
    if (!cleanBase.startsWith('/') && cleanBase.isNotEmpty) {
      cleanBase = '/$cleanBase';
    }

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      final spaceIdx = line.indexOf(' ');
      if (spaceIdx < 0) continue;

      final facts = line.substring(0, spaceIdx);
      final fileName = line.substring(spaceIdx + 1).trim();

      if (fileName == '.' || fileName == '..' || fileName.isEmpty) continue;

      bool isDir = false;
      int size = 0;

      final factParts = facts.split(';');
      for (final fact in factParts) {
        final kv = fact.split('=');
        if (kv.length == 2) {
          final k = kv[0].toLowerCase().trim();
          final v = kv[1].toLowerCase().trim();
          if (k == 'type') {
            isDir = (v == 'dir' || v == 'cdir' || v == 'pdir');
          } else if (k == 'size') {
            size = int.tryParse(v) ?? 0;
          }
        }
      }

      var fullRelPath = cleanBase.isEmpty || cleanBase == '/' ? '/$fileName' : '$cleanBase/$fileName';

      results.add(RemoteFile(
        name: fileName,
        path: fullRelPath,
        isDirectory: isDir,
        size: size,
      ));
    }

    results.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return results;
  }

  List<RemoteFile> _parseGeneralListing(String rawListing, String currentPath) {
    final List<RemoteFile> results = [];
    final lines = rawListing.split(RegExp(r'\r?\n'));

    var cleanBase = currentPath.replaceAll(RegExp(r'/+$'), '');
    if (!cleanBase.startsWith('/') && cleanBase.isNotEmpty) {
      cleanBase = '/$cleanBase';
    }

    for (final line in lines) {
      if (line.trim().isEmpty || line.startsWith('total')) continue;

      final dosRegex = RegExp(r'^\d{2}-\d{2}-\d{2,4}\s+\d{2}:\d{2}(?:AM|PM)?\s+(<DIR>|\d+)\s+(.+)$', caseSensitive: false);
      final dosMatch = dosRegex.firstMatch(line.trim());
      if (dosMatch != null) {
        final dirOrSize = dosMatch.group(1)!;
        final name = dosMatch.group(2)!.trim();
        if (name == '.' || name == '..') continue;

        final isDir = dirOrSize.toUpperCase() == '<DIR>';
        final size = isDir ? 0 : int.tryParse(dirOrSize) ?? 0;

        var fullRelPath = cleanBase.isEmpty || cleanBase == '/' ? '/$name' : '$cleanBase/$name';

        results.add(RemoteFile(
          name: name,
          path: fullRelPath,
          isDirectory: isDir,
          size: size,
        ));
        continue;
      }

      // Unix style
      final isDir = line.startsWith('d');
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 9) continue;

      final size = int.tryParse(parts[4]) ?? 0;
      final fileName = parts.sublist(8).join(' ').trim();

      if (fileName == '.' || fileName == '..' || fileName.isEmpty) continue;

      var fullRelPath = cleanBase.isEmpty || cleanBase == '/' ? '/$fileName' : '$cleanBase/$fileName';

      results.add(RemoteFile(
        name: fileName,
        path: fullRelPath,
        isDirectory: isDir,
        size: size,
      ));
    }

    results.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return results;
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
      final newlineIdx = _buffer.indexOf(10); // \n
      if (newlineIdx >= 0) {
        final lineBytes = _buffer.sublist(0, newlineIdx);
        _buffer.removeRange(0, newlineIdx + 1);
        var line = utf8.decode(lineBytes, allowMalformed: true).trim();
        return line;
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
