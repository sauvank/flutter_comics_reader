import 'dart:convert';

enum ServerType {
  webdav,
  ftp,
  httpDirectory, // HTTP File directory / JSON listing / Apache index
}

class ServerProfile {
  final String id;
  final String name;
  final String host;
  final int port;
  final String path;
  final bool isHttps;
  final ServerType serverType;
  final String? username;
  final String? password;
  final bool isActive;

  ServerProfile({
    required this.id,
    required this.name,
    required this.host,
    this.port = 80,
    String path = '/',
    this.isHttps = false,
    this.serverType = ServerType.webdav,
    this.username,
    this.password,
    this.isActive = false,
  }) : path = path.replaceAll('\\', '/');

  String get baseUrl {
    final scheme = isHttps ? 'https' : 'http';
    final cleanHost = host.replaceAll(RegExp(r'^https?:\/\/'), '').replaceAll(RegExp(r'\/$'), '');
    final portPart = (isHttps && port == 443) || (!isHttps && port == 80) ? '' : ':$port';
    var cleanPath = path.startsWith('/') ? path : '/$path';
    if (!cleanPath.endsWith('/')) {
      cleanPath = '$cleanPath/';
    }
    return '$scheme://$cleanHost$portPart$cleanPath';
  }

  ServerProfile copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? path,
    bool? isHttps,
    ServerType? serverType,
    String? username,
    String? password,
    bool? isActive,
  }) {
    return ServerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      path: path ?? this.path,
      isHttps: isHttps ?? this.isHttps,
      serverType: serverType ?? this.serverType,
      username: username ?? this.username,
      password: password ?? this.password,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'path': path,
      'isHttps': isHttps,
      'serverType': serverType.name,
      'username': username,
      'password': password,
      'isActive': isActive,
    };
  }

  factory ServerProfile.fromMap(Map<String, dynamic> map) {
    return ServerProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      host: map['host'] as String,
      port: map['port'] as int? ?? 80,
      path: (map['path'] as String? ?? '/').replaceAll('\\', '/'),
      isHttps: map['isHttps'] as bool? ?? false,
      serverType: ServerType.values.firstWhere(
        (e) => e.name == map['serverType'],
        orElse: () => ServerType.webdav,
      ),
      username: map['username'] as String?,
      password: map['password'] as String?,
      isActive: map['isActive'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory ServerProfile.fromJson(String source) => ServerProfile.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerProfile && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
