import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_version.dart';
import '../models/update_info.dart';
import '../widgets/update_dialog.dart';

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      validateStatus: (status) => status != null && status < 500,
      headers: {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'ComicStreamApp',
      },
    ),
  );

  /// Compares whether [remoteTag] is strictly newer than [localVer]
  static bool isNewerVersion(String remoteTag, String localVer) {
    try {
      final cleanRemote = remoteTag.replaceAll(RegExp(r'^[vV]'), '').trim();
      final cleanLocal = localVer.replaceAll(RegExp(r'^[vV]'), '').trim();

      final remoteParts = cleanRemote.split('.').map((e) => int.tryParse(e.split('+').first) ?? 0).toList();
      final localParts = cleanLocal.split('.').map((e) => int.tryParse(e.split('+').first) ?? 0).toList();

      while (remoteParts.length < 3) {
        remoteParts.add(0);
      }
      while (localParts.length < 3) {
        localParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (remoteParts[i] > localParts[i]) return true;
        if (remoteParts[i] < localParts[i]) return false;
      }
      return false;
    } catch (e) {
      debugPrint('Error comparing versions ($remoteTag vs $localVer): $e');
      return false;
    }
  }

  /// Checks GitHub Releases for the latest version
  Future<UpdateInfo?> checkUpdate() async {
    try {
      final response = await _dio.get(AppVersion.githubLatestApiUrl);
      if (response.statusCode != 200 || response.data == null) {
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final htmlUrl = data['html_url'] as String? ?? AppVersion.githubReleasesUrl;
      final body = data['body'] as String? ?? 'Nouvelle mise à jour disponible.';
      final publishedAtStr = data['published_at'] as String?;
      final publishedAt = publishedAtStr != null ? DateTime.tryParse(publishedAtStr) : null;

      final hasUpdate = isNewerVersion(tagName, AppVersion.version);

      String? directDownloadUrl;
      final assets = data['assets'] as List<dynamic>? ?? [];

      if (!kIsWeb) {
        if (Platform.isWindows) {
          // Find Setup .exe or .msi or .zip
          for (final asset in assets) {
            final name = (asset['name'] as String? ?? '').toLowerCase();
            final downloadUrl = asset['browser_download_url'] as String?;
            if (name.endsWith('-setup-x64.exe') || name.endsWith('.exe')) {
              directDownloadUrl = downloadUrl;
              break;
            } else if (name.endsWith('.msi')) {
              directDownloadUrl ??= downloadUrl;
            } else if (name.endsWith('.zip')) {
              directDownloadUrl ??= downloadUrl;
            }
          }
        } else if (Platform.isAndroid) {
          // Find .apk
          for (final asset in assets) {
            final name = (asset['name'] as String? ?? '').toLowerCase();
            final downloadUrl = asset['browser_download_url'] as String?;
            if (name.endsWith('.apk')) {
              directDownloadUrl = downloadUrl;
              break;
            }
          }
        }
      }

      return UpdateInfo(
        currentVersion: AppVersion.fullVersion,
        latestVersion: tagName.startsWith('v') ? tagName : 'v$tagName',
        hasUpdate: hasUpdate,
        releaseUrl: htmlUrl,
        directDownloadUrl: directDownloadUrl ?? htmlUrl,
        releaseNotes: body,
        publishedAt: publishedAt,
      );
    } catch (e) {
      debugPrint('UpdateService checkUpdate error: $e');
      return null;
    }
  }

  /// Opens the update link in browser or triggers direct download
  Future<bool> launchUpdateUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      debugPrint('Launch update URL error: $e');
      return false;
    }
  }

  /// Opens the Google Play Store app directly on ComicStream's page
  Future<bool> launchPlayStore() async {
    try {
      final marketUri = Uri.parse(AppVersion.playStoreMarketUrl);
      if (await canLaunchUrl(marketUri)) {
        return await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      }
      final webUri = Uri.parse(AppVersion.playStoreWebUrl);
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Launch Play Store error: $e');
      return false;
    }
  }

  /// Displays the interactive update dialog to the user
  void promptUpdateDialog(BuildContext context, UpdateInfo info) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => UpdateDialog(info: info),
    );
  }
}
