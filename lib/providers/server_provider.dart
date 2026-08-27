import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/remote_file.dart';
import '../models/server_profile.dart';
import '../services/database_service.dart';
import '../services/ftp_service.dart';
import '../services/http_server_service.dart';
import '../services/webdav_service.dart';

class ServerProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final WebDavService _webdav = WebDavService();
  final HttpServerService _http = HttpServerService();
  final FtpService _ftp = FtpService();

  List<ServerProfile> _servers = [];
  ServerProfile? _activeServer;
  String _currentPath = ''; // Current path in folder browser
  List<RemoteFile> _remoteFiles = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ServerProfile> get servers => _servers;
  ServerProfile? get activeServer => _activeServer;
  String get currentPath => _currentPath;
  List<RemoteFile> get remoteFiles => _remoteFiles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get rootPath {
    if (_activeServer != null && _activeServer!.path.isNotEmpty) {
      return _activeServer!.path;
    }
    return '/';
  }

  List<String> get breadcrumbs {
    if (_currentPath.isEmpty || _currentPath == rootPath) return [];

    if (_currentPath.startsWith(rootPath) && rootPath != '/') {
      final relative = _currentPath.substring(rootPath.length).replaceAll(RegExp(r'^/+'), '');
      if (relative.isEmpty) return [];
      return relative.split('/').where((s) => s.isNotEmpty).toList();
    }

    return _currentPath.split('/').where((s) => s.isNotEmpty).toList();
  }

  Future<void> loadServers() async {
    _servers = await _db.getServers();
    final activeId = await _db.getActiveServerId();
    if (activeId != null && _servers.any((s) => s.id == activeId)) {
      _activeServer = _servers.firstWhere((s) => s.id == activeId);
    } else if (_servers.isNotEmpty) {
      _activeServer = _servers.first;
      await _db.setActiveServerId(_activeServer!.id);
    }
    if (_activeServer != null) {
      _currentPath = rootPath;
    }
    notifyListeners();

    if (_activeServer != null) {
      await fetchRemoteFiles();
    }
  }

  Future<void> setActiveServer(ServerProfile server) async {
    _activeServer = server;
    _currentPath = rootPath;
    _remoteFiles = [];
    _errorMessage = null;
    await _db.setActiveServerId(server.id);
    notifyListeners();
    await fetchRemoteFiles();
  }

  Future<void> saveServer(ServerProfile server) async {
    await _db.saveServer(server);
    await loadServers();
  }

  Future<void> setAndSaveCurrentPathAsRoot() async {
    if (_activeServer == null) return;
    final newPath = _currentPath.isEmpty ? '/' : _currentPath;
    final updated = _activeServer!.copyWith(path: newPath);
    await _db.saveServer(updated);
    _activeServer = updated;
    notifyListeners();
  }

  Future<void> deleteServer(String serverId) async {
    await _db.deleteServer(serverId);
    if (_activeServer?.id == serverId) {
      _activeServer = null;
      _remoteFiles = [];
    }
    await loadServers();
  }

  /// Exports all configured servers into a formatted JSON string
  String exportServersJson() {
    final list = _servers.map((s) => s.toMap()).toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }

  /// Imports server profiles from a JSON string, returns the number of imported servers
  Future<int> importServersFromJson(String jsonContent) async {
    try {
      final decoded = jsonDecode(jsonContent);
      List<dynamic> list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('servers') && decoded['servers'] is List) {
          list = decoded['servers'] as List;
        } else {
          list = [decoded];
        }
      } else {
        throw const FormatException('Format JSON invalide');
      }

      int count = 0;
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final profile = ServerProfile.fromMap(item);
          await _db.saveServer(profile);
          count++;
        }
      }
      await loadServers();
      return count;
    } catch (e) {
      debugPrint('Error importing servers: $e');
      rethrow;
    }
  }

  Future<bool> testConnection(ServerProfile server) async {
    if (server.serverType == ServerType.ftp) {
      return await _ftp.testConnection(server);
    } else if (server.serverType == ServerType.webdav) {
      return await _webdav.testConnection(server);
    } else {
      try {
        final list = await _http.listDirectory(server: server, remoteRelativePath: '');
        return list.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  Future<bool> verifyPathExists(ServerProfile server, [String? targetPath]) async {
    if (server.serverType == ServerType.ftp) {
      return await _ftp.testPathExists(server, targetPath ?? server.path);
    }
    return true;
  }

  Future<void> navigateTo(String path) async {
    _currentPath = path;
    notifyListeners();
    await fetchRemoteFiles();
  }

  Future<void> navigateToRoot() async {
    await navigateTo(rootPath);
  }

  Future<void> navigateToBreadcrumbIndex(int index) async {
    if (_currentPath.startsWith(rootPath) && rootPath != '/') {
      final sub = breadcrumbs.sublist(0, index + 1).join('/');
      final base = rootPath.endsWith('/') ? rootPath : '$rootPath/';
      await navigateTo('$base$sub');
    } else {
      final segments = _currentPath.split('/').where((s) => s.isNotEmpty).toList();
      final target = '/${segments.sublist(0, index + 1).join('/')}';
      await navigateTo(target);
    }
  }

  Future<void> navigateUp() async {
    if (_currentPath == rootPath) return;

    if (_currentPath.isEmpty || _currentPath == '/') {
      return;
    }

    final clean = _currentPath.replaceAll(RegExp(r'/+$'), '');
    final lastSlash = clean.lastIndexOf('/');
    if (lastSlash <= 0) {
      await navigateTo(rootPath);
    } else {
      final parent = clean.substring(0, lastSlash);
      await navigateTo(parent.isEmpty ? '/' : parent);
    }
  }

  Future<void> fetchRemoteFiles() async {
    if (_activeServer == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_activeServer!.serverType == ServerType.ftp) {
        _remoteFiles = await _ftp.listDirectory(
          server: _activeServer!,
          remoteRelativePath: _currentPath,
        );
      } else if (_activeServer!.serverType == ServerType.webdav) {
        _remoteFiles = await _webdav.listDirectory(
          server: _activeServer!,
          remoteRelativePath: _currentPath,
        );
      } else {
        _remoteFiles = await _http.listDirectory(
          server: _activeServer!,
          remoteRelativePath: _currentPath,
        );
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Impossible de charger le dossier: $e';
      notifyListeners();
    }
  }
}
