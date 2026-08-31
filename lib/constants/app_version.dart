class AppVersion {
  static const String version = '1.1.9';
  static const int buildNumber = 41;
  static const String fullVersion = 'v$version';
  static const String githubRepo = 'sauvank/flutter_comics_reader';
  static const String githubReleasesUrl = 'https://github.com/$githubRepo/releases';
  static const String githubLatestApiUrl = 'https://api.github.com/repos/$githubRepo/releases/latest';
  static const String playStorePackageId = 'com.sauvank.comicstream';
  static const String playStoreMarketUrl = 'market://details?id=$playStorePackageId';
  static const String playStoreWebUrl = 'https://play.google.com/store/apps/details?id=$playStorePackageId';
}
