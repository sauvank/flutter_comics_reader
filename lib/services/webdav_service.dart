import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';
import '../models/remote_file.dart';
import '../models/server_profile.dart';

class WebDavService {
  final Dio _dio;

  WebDavService()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(minutes: 10),
            sendTimeout: const Duration(seconds: 30),
            validateStatus: (status) => status != null && status >= 200 && status < 400,
          ),
        );

  Map<String, String> getHeaders(ServerProfile server) {
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

  /// Tests connection to the server
  Future<bool> testConnection(ServerProfile server) async {
    try {
      final url = server.baseUrl;
      final response = await _dio.request(
        url,
        options: Options(
          method: 'PROPFIND',
          headers: {
            ...getHeaders(server),
            'Depth': '0',
            'Content-Type': 'application/xml',
          },
        ),
      );
      return response.statusCode == 200 || response.statusCode == 207;
    } catch (e) {
      debugPrint('WebDAV test connection error: $e');
      // If PROPFIND fails, try a simple GET or HEAD request as fallback
      try {
        final response = await _dio.get(
          server.baseUrl,
          options: Options(
            headers: getHeaders(server),
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );
        return response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 400;
      } catch (e2) {
        debugPrint('WebDAV fallback GET test error: $e2');
        return false;
      }
    }
  }

  String buildTargetUrl(ServerProfile server, String remoteRelativePath, {bool isDirectory = true}) {
    var base = server.baseUrl;
    if (!base.endsWith('/')) base = '$base/';

    var cleanPath = remoteRelativePath.trim();
    if (cleanPath.isEmpty || cleanPath == '/') {
      return base;
    }

    // Clean server basePath to check for overlaps
    var serverBasePath = Uri.parse(base).path;
    serverBasePath = serverBasePath.replaceAll(RegExp(r'^/+'), '').replaceAll(RegExp(r'/+$'), '');

    var cleanRelative = cleanPath.replaceAll(RegExp(r'^/+'), '').replaceAll(RegExp(r'/+$'), '');

    // If cleanRelative is exactly serverBasePath (e.g. 'dav/Comics' when base is 'http://.../dav/Comics/'),
    // it refers to the root of baseUrl itself!
    if (cleanRelative == serverBasePath || cleanRelative.isEmpty) {
      return base;
    }

    // If cleanRelative starts with serverBasePath, strip that prefix
    if (serverBasePath.isNotEmpty && cleanRelative.startsWith('$serverBasePath/')) {
      cleanRelative = cleanRelative.substring(serverBasePath.length + 1);
    }

    var url = cleanRelative.isEmpty ? base : '$base$cleanRelative';
    if (isDirectory && !url.endsWith('/')) {
      url = '$url/';
    }
    return url;
  }

  /// Lists files and folders at [remoteRelativePath]
  Future<List<RemoteFile>> listDirectory({
    required ServerProfile server,
    String remoteRelativePath = '',
  }) async {
    final targetUrl = buildTargetUrl(server, remoteRelativePath, isDirectory: true);

    const propfindXml = '''<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
  <D:prop>
    <D:displayname/>
    <D:getcontentlength/>
    <D:getlastmodified/>
    <D:resourcetype/>
  </D:prop>
</D:propfind>''';

    try {
      final response = await _dio.request<String>(
        targetUrl,
        data: propfindXml,
        options: Options(
          method: 'PROPFIND',
          followRedirects: true,
          maxRedirects: 5,
          headers: {
            ...getHeaders(server),
            'Depth': '1',
            'Content-Type': 'application/xml; charset=utf-8',
          },
          responseType: ResponseType.plain,
        ),
      );

      final xmlString = response.data;
      if (xmlString == null || xmlString.isEmpty) return [];

      return _parseWebDavXml(xmlString, targetUrl, server);
    } catch (e) {
      debugPrint('WebDAV listDirectory error on $targetUrl: $e');
      // If failed with trailing slash, try without trailing slash as fallback
      if (targetUrl.endsWith('/')) {
        final fallbackUrl = targetUrl.substring(0, targetUrl.length - 1);
        try {
          final fallbackResponse = await _dio.request<String>(
            fallbackUrl,
            data: propfindXml,
            options: Options(
              method: 'PROPFIND',
              followRedirects: true,
              maxRedirects: 5,
              headers: {
                ...getHeaders(server),
                'Depth': '1',
                'Content-Type': 'application/xml; charset=utf-8',
              },
              responseType: ResponseType.plain,
            ),
          );
          final xmlString = fallbackResponse.data;
          if (xmlString != null && xmlString.isNotEmpty) {
            return _parseWebDavXml(xmlString, fallbackUrl, server);
          }
        } catch (e2) {
          debugPrint('WebDAV fallback error on $fallbackUrl: $e2');
        }
      }
      rethrow;
    }
  }

  String _safeDecode(String input) {
    var s = input;
    try {
      while (s.contains('%')) {
        final decoded = Uri.decodeComponent(s);
        if (decoded == s) break;
        s = decoded;
      }
    } catch (_) {}
    return s;
  }

  List<RemoteFile> _parseWebDavXml(String xmlContent, String requestedUrl, ServerProfile server) {
    final List<RemoteFile> results = [];
    final document = XmlDocument.parse(xmlContent);

    // Find all <response> or <D:response> or <d:response> elements
    final responses = document.findAllElements('response', namespace: '*').isNotEmpty
        ? document.findAllElements('response', namespace: '*')
        : document.findAllElements('response');

    final uriRequested = Uri.tryParse(requestedUrl);
    final requestedPath = uriRequested != null ? _safeDecode(uriRequested.path).replaceAll(RegExp(r'/+$'), '') : '';

    for (final res in responses) {
      // Get href
      final hrefElements = res.findAllElements('href', namespace: '*').isNotEmpty
          ? res.findAllElements('href', namespace: '*')
          : res.findAllElements('href');

      if (hrefElements.isEmpty) continue;
      final rawHref = hrefElements.first.innerText.trim();
      final decodedHref = _safeDecode(rawHref);

      // Check if it's the requested folder itself (Depth: 1 includes the target folder as 1st element)
      final cleanItemPath = decodedHref.replaceAll(RegExp(r'/+$'), '');
      if (cleanItemPath == requestedPath || cleanItemPath.isEmpty) {
        continue; // Skip the parent folder itself
      }

      // Check resource type (is collection/folder?)
      final isCollection = res.findAllElements('collection', namespace: '*').isNotEmpty ||
          res.findAllElements('collection').isNotEmpty ||
          rawHref.endsWith('/');

      // Display name or extract from href
      var displayName = '';
      final displayNameElems = res.findAllElements('displayname', namespace: '*');
      if (displayNameElems.isNotEmpty && displayNameElems.first.innerText.trim().isNotEmpty) {
        displayName = _safeDecode(displayNameElems.first.innerText.trim());
      } else {
        final segments = Uri.parse(rawHref).pathSegments.where((s) => s.isNotEmpty).toList();
        displayName = segments.isNotEmpty ? _safeDecode(segments.last) : 'Unknown';
      }

      // Content length (file size)
      int fileSize = 0;
      final lengthElems = res.findAllElements('getcontentlength', namespace: '*');
      if (lengthElems.isNotEmpty) {
        fileSize = int.tryParse(lengthElems.first.innerText.trim()) ?? 0;
      }

      // Last modified date
      DateTime? lastModified;
      final modifiedElems = res.findAllElements('getlastmodified', namespace: '*');
      if (modifiedElems.isNotEmpty) {
        try {
          lastModified = HttpDate.parse(modifiedElems.first.innerText.trim());
        } catch (_) {
          lastModified = DateTime.tryParse(modifiedElems.first.innerText.trim());
        }
      }

      // Compute relative path from server root
      var serverBasePath = Uri.parse(server.baseUrl).path;
      if (!serverBasePath.startsWith('/')) serverBasePath = '/$serverBasePath';
      if (!serverBasePath.endsWith('/')) serverBasePath = '$serverBasePath/';

      var relPath = decodedHref;
      if (relPath.contains('://')) {
        final parsed = Uri.tryParse(relPath);
        if (parsed != null) relPath = parsed.path;
      }
      if (relPath.startsWith(serverBasePath)) {
        relPath = relPath.substring(serverBasePath.length);
      } else if (relPath.startsWith('/')) {
        relPath = relPath.substring(1);
      }

      results.add(RemoteFile(
        name: displayName,
        path: relPath,
        isDirectory: isCollection,
        size: fileSize,
        modified: lastModified,
      ));
    }

    // Sort: directories first, then files alphabetically
    results.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return results;
  }

  /// Downloads a remote file to [destinationLocalPath] with progress callback and cancel token
  Future<void> downloadFile({
    required ServerProfile server,
    required String remoteRelativePath,
    required String destinationLocalPath,
    required void Function(int receivedBytes, int totalBytes) onProgress,
    CancelToken? cancelToken,
  }) async {
    final downloadUrl = buildTargetUrl(server, remoteRelativePath, isDirectory: false);

    final tempFile = File('$destinationLocalPath.tmp');
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    try {
      await _dio.download(
        downloadUrl,
        tempFile.path,
        onReceiveProgress: onProgress,
        cancelToken: cancelToken,
        options: Options(
          headers: getHeaders(server),
          responseType: ResponseType.stream,
        ),
      );

      // Rename temp file to final destination
      final finalFile = File(destinationLocalPath);
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await tempFile.rename(destinationLocalPath);
    } catch (e) {
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }
}
