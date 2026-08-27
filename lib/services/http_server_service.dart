import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/remote_file.dart';
import '../models/server_profile.dart';

class HttpServerService {
  final Dio _dio;

  HttpServerService()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(minutes: 10),
            sendTimeout: const Duration(seconds: 30),
          ),
        );

  Map<String, String> _getHeaders(ServerProfile server) {
    final headers = <String, String>{
      'User-Agent': 'ComicStream-App/1.0',
    };
    if (server.username != null && server.username!.isNotEmpty) {
      final authStr = '${server.username}:${server.password ?? ''}';
      final base64Auth = base64Encode(utf8.encode(authStr));
      headers['Authorization'] = 'Basic $base64Auth';
    }
    return headers;
  }

  String _buildTargetUrl(ServerProfile server, String remoteRelativePath) {
    var base = server.baseUrl;
    if (!base.endsWith('/')) base = '$base/';

    var cleanPath = remoteRelativePath.trim();
    if (cleanPath.isEmpty || cleanPath == '/') {
      return base;
    }

    var serverBasePath = Uri.parse(base).path;
    serverBasePath = serverBasePath.replaceAll(RegExp(r'^/+'), '').replaceAll(RegExp(r'/+$'), '');

    var cleanRelative = cleanPath.replaceAll(RegExp(r'^/+'), '').replaceAll(RegExp(r'/+$'), '');

    if (cleanRelative == serverBasePath || cleanRelative.isEmpty) {
      return base;
    }

    if (serverBasePath.isNotEmpty && cleanRelative.startsWith('$serverBasePath/')) {
      cleanRelative = cleanRelative.substring(serverBasePath.length + 1);
    }

    return cleanRelative.isEmpty ? base : '$base$cleanRelative';
  }

  /// Lists files from an HTTP server (Supports JSON API or standard HTML Directory Listing)
  Future<List<RemoteFile>> listDirectory({
    required ServerProfile server,
    String remoteRelativePath = '',
  }) async {
    final targetUrl = _buildTargetUrl(server, remoteRelativePath);
    final cleanRelative = remoteRelativePath.replaceAll(RegExp(r'^/+'), '');

    try {
      final response = await _dio.get(
        targetUrl,
        options: Options(
          headers: _getHeaders(server),
          responseType: ResponseType.plain,
        ),
      );

      final content = response.data?.toString() ?? '';

      // Check if response is JSON (e.g. comic JSON API or directory manifest)
      if (content.trim().startsWith('[') || content.trim().startsWith('{')) {
        try {
          final decoded = jsonDecode(content);
          if (decoded is List) {
            return _parseJsonList(decoded, cleanRelative);
          } else if (decoded is Map && decoded.containsKey('files')) {
            return _parseJsonList(decoded['files'] as List, cleanRelative);
          }
        } catch (_) {}
      }

      // Fallback: parse HTML auto-index (Apache / Nginx / Python http.server)
      return _parseHtmlDirectory(content, cleanRelative);
    } catch (e) {
      debugPrint('HTTP Server listDirectory error: $e');
      rethrow;
    }
  }

  List<RemoteFile> _parseJsonList(List<dynamic> list, String currentPath) {
    final List<RemoteFile> results = [];
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        final name = item['name'] as String? ?? 'file';
        final isDir = item['isDirectory'] as bool? ?? (item['type'] == 'directory');
        final size = (item['size'] as num?)?.toInt() ?? 0;
        final itemPath = currentPath.isEmpty ? name : '$currentPath/$name';

        results.add(RemoteFile(
          name: name,
          path: itemPath,
          isDirectory: isDir,
          size: size,
        ));
      }
    }
    return results;
  }

  List<RemoteFile> _parseHtmlDirectory(String html, String currentPath) {
    final List<RemoteFile> results = [];
    // Extract <a href="...">...</a>
    final regex = RegExp(r'<a\s+(?:[^>]*?\s+)?href="([^"]*)"[^>]*>(.*?)<\/a>', caseSensitive: false);
    final matches = regex.allMatches(html);

    for (final match in matches) {
      var href = match.group(1)?.trim() ?? '';

      if (href.isEmpty || href == '../' || href == '/' || href.startsWith('?') || href.startsWith('#')) {
        continue; // Skip parent directory / query / anchor links
      }

      final isDir = href.endsWith('/');
      var cleanName = Uri.decodeComponent(href.replaceAll(RegExp(r'/+$'), ''));
      if (cleanName.isEmpty) continue;

      var fullRelPath = currentPath.isEmpty ? cleanName : '$currentPath/$cleanName';

      results.add(RemoteFile(
        name: cleanName,
        path: fullRelPath,
        isDirectory: isDir,
        size: 0,
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
