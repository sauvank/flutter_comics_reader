class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final bool hasUpdate;
  final String releaseUrl;
  final String? directDownloadUrl;
  final String releaseNotes;
  final DateTime? publishedAt;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.hasUpdate,
    required this.releaseUrl,
    this.directDownloadUrl,
    required this.releaseNotes,
    this.publishedAt,
  });
}
