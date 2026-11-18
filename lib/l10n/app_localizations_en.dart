import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get resetVaultTitle => 'Reset the vault?';

  @override
  String get resetVaultBody => 'If you lost your recovery phrase, resetting will create a new empty vault. Protected data from your other devices will need to be synced again.';

  @override
  String get reset => 'Reset';

  @override
  String get confirmSecretPhrase => 'Confirm the secret phrase';

  @override
  String get secretPhraseWrittenDownBody => 'Have you written down your secret phrase somewhere safe?\n\nIt is required to restore your data or sync a new device. ComicStream does not keep it and will never be able to recover it for you.';

  @override
  String get yourSecretPhrase => 'Your secret phrase:';

  @override
  String get phraseNotedContinue => 'I wrote it down, continue';

  @override
  String get changeSecretPhrase => 'Change the secret phrase';

  @override
  String get changeSecretPhraseBody => 'Set a new secret phrase (at least 16 characters) to secure your sync.';

  @override
  String get newSecretPhrase => 'New secret phrase';

  @override
  String get min16Characters => 'At least 16 characters';

  @override
  String get showPhrase => 'Show phrase';

  @override
  String get hidePhrase => 'Hide phrase';

  @override
  String get confirmNewPhrase => 'Confirm the new phrase';

  @override
  String get phraseTooShort => 'The phrase must be at least 16 characters long.';

  @override
  String get phrasesDoNotMatch => 'The two phrases do not match.';

  @override
  String get confirmChangeTitle => 'Confirm the change?';

  @override
  String get confirmChangeBody => 'Your vault will be updated with this new secret phrase.\nMake sure you wrote it down:';

  @override
  String get confirmAndSave => 'Confirm and save';

  @override
  String get secretPhraseUpdated => 'Secret phrase updated successfully.';

  @override
  String get operationDone => 'Operation complete.';

  @override
  String cannotContinue(Object error) {
    return 'Unable to continue: $error';
  }

  @override
  String dateAtTime(Object date, Object time) {
    return '$date at $time';
  }

  @override
  String get syncConflict => 'Sync conflict';

  @override
  String syncConflictBody(Object label) {
    return 'Two versions of “$label” were modified.';
  }

  @override
  String thisDeviceValue(Object formatConflictDate) {
    return 'This device: $formatConflictDate';
  }

  @override
  String syncServerValue(Object formatConflictDate) {
    return 'Sync server: $formatConflictDate';
  }

  @override
  String thisDeviceSummary(Object localSummary) {
    return 'This device: $localSummary';
  }

  @override
  String serverSummary(Object remoteSummary) {
    return 'Server: $remoteSummary';
  }

  @override
  String get chooseReferenceVersion => 'Choose the reference version. It will then be synced to your other devices.';

  @override
  String get fetchFromServer => 'Fetch from server';

  @override
  String get sendToServer => 'Send to server';

  @override
  String get later => 'Later';

  @override
  String get thisDeviceName => 'Name of this device';

  @override
  String get deviceNameHint => 'E.g. Tablet or Phone';

  @override
  String get deviceNameSavedOnServer => 'Device name saved on the server.';

  @override
  String get deviceNameSavedLocally => 'Name saved on this device. It will be sent on the next sync.';

  @override
  String cannotPrepareSync(Object error) {
    return 'Unable to prepare the sync: $error';
  }

  @override
  String get whichBackupToUse => 'Which backup should be used?';

  @override
  String get whichBackupBody => 'Your choice becomes the shared reference. Other devices will receive it on their next sync.';

  @override
  String get notBackedUpYet => 'Not backed up yet';

  @override
  String backedUpAt(Object formatConflictDate) {
    return 'Backed up $formatConflictDate';
  }

  @override
  String get accountAndSync => 'Account and sync';

  @override
  String get syncUnavailableNoFirebase => 'Sync will be available once the Firebase project is configured. The reader and your local data keep working normally.';

  @override
  String get accountConnected => 'Signed in';

  @override
  String get vaultUnlockedE2e => 'Vault unlocked. Your data is end-to-end encrypted.';

  @override
  String get vaultLockedOrNew => 'Vault locked or not initialized.';

  @override
  String get unlockVault => 'Unlock the vault';

  @override
  String get initEncryptedVault => 'Set up your encrypted vault';

  @override
  String get unlockVaultBody => 'An encrypted vault is linked to this account. Enter your recovery phrase to unlock sync on this device.';

  @override
  String get initVaultBody => 'To protect your server passwords and data, choose a secret phrase (at least 16 characters). It is required to restore your data on a new device.';

  @override
  String get recoveryPhrase => 'Recovery phrase';

  @override
  String get secretPhraseMin16 => 'Secret phrase (at least 16 characters)';

  @override
  String get enterRecoveryPhrase => 'Please enter your recovery phrase.';

  @override
  String get secretPhraseTooShort => 'The secret phrase must be at least 16 characters long.';

  @override
  String get secretPhrasesDoNotMatch => 'The secret phrases do not match.';

  @override
  String get unlockSync => 'Unlock sync';

  @override
  String get createAndEnableVault => 'Create and enable the vault';

  @override
  String get forgotPhraseReset => 'Forgot the phrase? Reset the vault';

  @override
  String get vaultUnlocked => 'Vault unlocked';

  @override
  String get syncActiveE2e => 'Sync is active and protected by end-to-end encryption.';

  @override
  String get syncing => 'Syncing…';

  @override
  String get changePhrase => 'Change phrase';

  @override
  String get shownWhenChoosingBackup => 'Shown when choosing a backup';

  @override
  String get signOut => 'Sign out';

  @override
  String get createAccount => 'Create an account';

  @override
  String get signIn => 'Sign in';

  @override
  String get passwordMin12 => 'Password (at least 12 characters)';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get createTheAccount => 'Create the account';

  @override
  String get alreadyHaveAccount => 'I already have an account';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get recoveryPhraseRequiredNote => 'The recovery phrase is required to restore server passwords on a new device. It is never saved by ComicStream.';

  @override
  String androidCertNotAllowed(Object hashes) {
    return 'Android certificate not allowed: $hashes';
  }

  @override
  String pendingConflicts(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes are waiting for your choice.',
      one: '1 change is waiting for your choice.',
    );
    return '$_temp0';
  }

  @override
  String upToDate(Object fullVersion) {
    return 'ComicStream is up to date ($fullVersion)!';
  }

  @override
  String get updateCheckError => 'Error while checking for updates';

  @override
  String get clearCacheTitle => 'Clear the cache?';

  @override
  String get clearCacheBody => 'Covers will be reloaded automatically.';

  @override
  String get coverCacheCleared => 'Cover cache cleared successfully!';

  @override
  String get deleteAllTitle => 'Delete everything?';

  @override
  String get deleteAllBody => 'This will delete all comics and manga downloaded locally to free up space. Your server settings will be kept.';

  @override
  String get allLocalFilesDeleted => 'All local files have been deleted.';

  @override
  String get eraseAll => 'Erase all';

  @override
  String get commandCopied => 'Command copied!';

  @override
  String get localServerGuide => 'Local server guide';

  @override
  String get guideOption1 => 'Option 1: WebDAV server with Docker (recommended)';

  @override
  String get guideOption1Body => 'Run a lightweight WebDAV server with Docker in one line, pointing to your comics folder:';

  @override
  String get guideOption2 => 'Option 2: Ready-to-use Python script';

  @override
  String get guideOption2Body => 'A dedicated Python server is provided in `server_example/comic_server.py`. To run it:';

  @override
  String get guideOption3 => 'Option 3: Synology NAS / TrueNAS / Nextcloud';

  @override
  String get guideOption3Body => 'Simply enable the WebDAV service in your NAS admin panel (port 5005 by default on Synology) and enter your credentials in the app.';

  @override
  String get settings => 'Settings';

  @override
  String get accountAndSyncShort => 'Account & sync';

  @override
  String get accountAndSyncSubtitle => 'Encrypted servers, progress and settings';

  @override
  String get appearanceTheme => 'Appearance & theme';

  @override
  String get appTheme => 'App theme';

  @override
  String get readerPreferences => 'Reader preferences';

  @override
  String get defaultReadingMode => 'Default reading mode';

  @override
  String get readingModeComic => 'Comic (left to right)';

  @override
  String get readingModeManga => 'Manga (right to left)';

  @override
  String get readingModeWebtoon => 'Webtoon (vertical scrolling)';

  @override
  String get keepScreenOn => 'Keep the screen on while reading';

  @override
  String get showPageNumber => 'Show the page number';

  @override
  String get autoConvertPdf => 'Automatically convert PDFs to CBZ';

  @override
  String get autoConvertPdfBody => 'Turns each downloaded PDF into a super-smooth comic archive for tablets.';

  @override
  String get comicRenderQuality => 'Comic rendering quality';

  @override
  String get qualityAutoLong => 'Automatic (detects the screen + 35% sharpness)';

  @override
  String get qualitySuperLong => 'Supersampled (2600px - sharp zoom)';

  @override
  String get qualityUltraLong => 'Ultra HD (3500px - max definition)';

  @override
  String get qualityStandardLong => 'Standard 1:1 (1900px - fast)';

  @override
  String get qualityAuto => 'Auto (screen + 35%)';

  @override
  String get qualityHigh => 'High (2600px)';

  @override
  String get qualityStandard => 'Standard 1:1';

  @override
  String get ebooksEpub => 'E-books & EPUB';

  @override
  String get fontSize => 'Font size';

  @override
  String get justifiedText => 'Justified text';

  @override
  String get storageCache => 'Storage & cache';

  @override
  String get spaceUsedByBooks => 'Space used by books:';

  @override
  String booksDownloadedCount(Object length) {
    return '$length book(s) downloaded';
  }

  @override
  String get clearCache => 'Clear cache';

  @override
  String get updates => 'Updates';

  @override
  String get checkForUpdate => 'Check for updates';

  @override
  String installedVersion(Object fullVersion) {
    return 'Installed version: $fullVersion';
  }

  @override
  String get check => 'Check';

  @override
  String get seeStoreListing => 'See the official ComicStream listing';

  @override
  String get helpSetup => 'Help & setup';

  @override
  String get howToSetupLocalServer => 'How do I set up my local server?';

  @override
  String get helpSetupSubtitle => 'Docker, Python, Synology NAS, TrueNAS...';

  @override
  String get appTagline => 'Comics, BD & Manga cloud reader';

  @override
  String get deleteBookTitle => 'Delete this book?';

  @override
  String deleteBookBody(Object title) {
    return 'Do you want to delete \"$title\" from your local storage?';
  }

  @override
  String resumeAtChapter(Object title, Object currentPage1) {
    return '“$title” was already started. Resume at chapter $currentPage1?';
  }

  @override
  String resumeAtPage(Object title, Object currentPage1) {
    return '“$title” was already started. Resume at page $currentPage1?';
  }

  @override
  String get myLibrary => 'My library';

  @override
  String comicsCount(Object length) {
    return '$length comics';
  }

  @override
  String get syncInProgress => 'Sync in progress';

  @override
  String get sortBy => 'Sort by';

  @override
  String get lastRead => 'Last read';

  @override
  String get titleAz => 'Title (A-Z)';

  @override
  String get dateAdded => 'Date added';

  @override
  String seriesCount(Object length) {
    return 'Series ($length)';
  }

  @override
  String volumesCount(Object length) {
    return 'Volumes ($length)';
  }

  @override
  String get searchLibraryHint => 'Search a series, a volume, an author...';

  @override
  String get recentlyOpened => 'Recently opened';

  @override
  String myCollectionsCount(Object length) {
    return 'My collections & series ($length)';
  }

  @override
  String get backToSeries => 'Back to series';

  @override
  String seriesProgress(Object completedBooks, Object totalBooks, Object progressPercent) {
    return '$completedBooks/$totalBooks volumes read • $progressPercent%';
  }

  @override
  String get checkNewVolumes => 'Check for new volumes on the server';

  @override
  String get nextVolumeToRead => 'NEXT VOLUME TO READ';

  @override
  String get nextVolumeOnServer => 'NEXT VOLUME ON THE SERVER';

  @override
  String get download => 'Download';

  @override
  String downloadStarted(Object name) {
    return '📥 Download started: $name';
  }

  @override
  String get readNow => 'Read now';

  @override
  String get searchingNextVolumes => 'Looking for the next volumes on the remote server...';

  @override
  String downloadedVolumesCount(Object totalBooks) {
    return 'Downloaded volumes ($totalBooks)';
  }

  @override
  String serverVolumesCount(Object length) {
    return 'Volumes available on the server ($length)';
  }

  @override
  String downloadAllCount(Object length) {
    return 'Download all ($length)';
  }

  @override
  String volumesQueued(Object length) {
    return '📥 $length volumes added to the download queue';
  }

  @override
  String downloadingName(Object name) {
    return '📥 Downloading: $name';
  }

  @override
  String get libraryFilters => 'Library filters';

  @override
  String allCount(Object length) {
    return 'All ($length)';
  }

  @override
  String get inProgress => 'In progress';

  @override
  String get unread => 'Unread';

  @override
  String get epubNovels => 'EPUB / Novels';

  @override
  String get finished => 'Finished';

  @override
  String get continueReading => 'CONTINUE READING';

  @override
  String get libraryEmpty => 'Your library is empty';

  @override
  String get libraryEmptyBody => 'Add comics from a server or from files already on your phone.';

  @override
  String get exploreServers => 'Explore my servers';

  @override
  String get importFromPhone => 'Import from this phone';

  @override
  String get noSearchResults => 'No results for this search';

  @override
  String get noSearchResultsBody => 'Try another keyword or reset the filters.';

  @override
  String chapterProgressPercent(Object current, Object total, Object percent) {
    return 'Chapter $current/$total ($percent%)';
  }

  @override
  String pageProgressPercent(Object current, Object total, Object percent) {
    return 'Page $current/$total ($percent%)';
  }

  @override
  String chapterOfTotal(Object current, Object total) {
    return 'Chapter $current of $total';
  }

  @override
  String pageOfTotal(Object current, Object total) {
    return 'Page $current of $total';
  }

  @override
  String get setupServer => 'Set up a server';

  @override
  String connectionSucceeded(Object name) {
    return 'Connected to $name!';
  }

  @override
  String connectionFailed(Object name) {
    return 'Connection to $name failed';
  }

  @override
  String get deleteServerTitle => 'Delete this server?';

  @override
  String deleteServerBody(Object name) {
    return 'Do you really want to delete \"$name\" from your remote sources?';
  }

  @override
  String get exportConfiguration => 'Export the configuration';

  @override
  String get exportConfigurationBody => 'Here is the JSON configuration file containing your server profiles:';

  @override
  String get copyJson => 'Copy JSON';

  @override
  String get configurationCopied => '✅ Configuration copied to the clipboard!';

  @override
  String get importConfiguration => 'Import a configuration';

  @override
  String get chooseJsonFile => 'Choose a .json file';

  @override
  String fileReadError(Object e) {
    return 'Error while reading the file: $e';
  }

  @override
  String get orPasteJson => 'Or paste the JSON here:';

  @override
  String serversImported(Object count) {
    return '✅ $count server(s) imported successfully!';
  }

  @override
  String baseLocationSet(Object currentPath) {
    return '✅ Base location set to: $currentPath';
  }

  @override
  String get myServers => 'My servers';

  @override
  String get addServer => 'Add a server';

  @override
  String get howToSetupServer => 'How to set up a server';

  @override
  String get exportConfigurations => 'Export configurations';

  @override
  String get testConnection => 'Test the connection';

  @override
  String get filterFolderHint => 'Filter this folder...';

  @override
  String get closeSearch => 'Close search';

  @override
  String get folderOptions => 'Folder options';

  @override
  String get setFolderAsRoot => 'Set this folder as root';

  @override
  String get switchServer => 'Switch server';

  @override
  String get parentFolder => 'Parent folder';

  @override
  String everythingCount(Object length) {
    return 'Everything ($length)';
  }

  @override
  String get downloadAllTitle => 'Download everything?';

  @override
  String downloadAllBody(Object length) {
    return '$length volumes will be downloaded in the background.';
  }

  @override
  String volumesQueuedCount(Object length) {
    return '📥 $length volume(s) added to the download queue';
  }

  @override
  String foldersSeriesCount(Object length) {
    return 'Folders & series ($length)';
  }

  @override
  String booksComicsCount(Object length) {
    return 'Books & comics ($length)';
  }

  @override
  String downloadingNamePlain(Object name) {
    return 'Downloading: $name';
  }

  @override
  String get folderEmpty => 'This folder is empty';

  @override
  String get folderEmptyBody => 'No book or subfolder found in this location.';

  @override
  String get cannotConnectServer => 'Unable to connect to the server';

  @override
  String checkServerReachable(Object baseUrl) {
    return 'Check that the server is reachable at $baseUrl.';
  }

  @override
  String get editSettings => 'Edit settings';

  @override
  String get retry => 'Retry';

  @override
  String get googleTokenMissing => 'Google authentication token not found.';

  @override
  String get googleSignInUnavailable => 'Google sign-in is not available on this device.';

  @override
  String get recoveryPhraseTooShort => 'The recovery phrase must be at least 16 characters long.';

  @override
  String get signInRequired => 'Sign-in required';

  @override
  String get noSyncVaultFound => 'No sync vault found.';

  @override
  String get vaultMustBeUnlocked => 'The vault must be unlocked to change the secret phrase.';

  @override
  String get recoveryPhraseRequiredHere => 'Recovery phrase required on this device.';

  @override
  String get serverConfigurations => 'Server configurations';

  @override
  String get readingSettings => 'Reading settings';

  @override
  String get deviceNameLength => 'The name must be between 1 and 40 characters.';

  @override
  String deviceDefaultName(Object substring) {
    return 'Device $substring';
  }

  @override
  String get otherDevice => 'Other device';

  @override
  String get remoteProgressGone => 'This remote progress no longer exists.';

  @override
  String thisDeviceNamed(Object currentName) {
    return 'This device — $currentName';
  }

  @override
  String get deviceBackupNotFound => 'The backup of this device cannot be found.';

  @override
  String get googleDataNotFound => 'The Google data to resolve cannot be found.';

  @override
  String get localProgressGone => 'The matching local progress no longer exists.';

  @override
  String get unknownSyncDocument => 'Unknown sync document';

  @override
  String get readingSettingsShort => 'Reading settings';

  @override
  String get yes => 'yes';

  @override
  String get no => 'no';

  @override
  String chapterSlash(Object current, Object total) {
    return 'Chapter $current/$total';
  }

  @override
  String pageSlash(Object current, Object total) {
    return 'Page $current/$total';
  }

  @override
  String progressSummary(Object location, Object favorite, Object bookmarks) {
    return '$location · Favorite: $favorite · $bookmarks';
  }

  @override
  String bookmarksCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bookmarks',
      one: '1 bookmark',
      zero: '0 bookmarks',
    );
    return '$_temp0';
  }

  @override
  String serverProfilesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count server profiles',
      one: '1 server profile',
      zero: '0 server profiles',
    );
    return '$_temp0';
  }

  @override
  String ftpInvalidServer(Object banner) {
    return 'Invalid FTP server: $banner';
  }

  @override
  String ftpCredentialsRefused(Object passResp) {
    return 'FTP credentials refused: $passResp';
  }

  @override
  String ftpUsernameRefused(Object userResp) {
    return 'FTP username refused: $userResp';
  }

  @override
  String ftpPassiveFailed(Object pasvResp) {
    return 'FTP passive mode failed: $pasvResp';
  }

  @override
  String ftpDownloadFailed(Object retrResp) {
    return 'Unable to download the FTP file: $retrResp';
  }

  @override
  String get ftpIdleTimeout => 'FTP idle timeout exceeded';

  @override
  String ftpPasvUnrecognized(Object response) {
    return 'Unrecognized PASV response: $response';
  }

  @override
  String get guideHeroTitle => 'Read the comics stored on your computer or NAS';

  @override
  String get guideHeroBody => 'A server makes your collection available from your phone without copying everything. It takes about 2 minutes.';

  @override
  String get howItWorks => 'How it works';

  @override
  String get guideStep1Title => 'Share your comics folder';

  @override
  String get guideStep1Body => 'On your NAS or computer, enable a WebDAV, FTP or HTTP share pointing to the folder that holds your CBZ, CBR, PDF or EPUB files. The examples below cover each case.';

  @override
  String get guideStep2Title => 'Note its address';

  @override
  String get guideStep2Body => 'Find the local IP address of the machine (e.g. 192.168.1.100) and the port of the share. The phone must be on the same Wi-Fi network.';

  @override
  String get guideStep3Title => 'Fill in the form';

  @override
  String get guideStep3Body => 'Tap “Add a server”, choose the type, then enter the host, port, folder path and, if needed, the username and password.';

  @override
  String get guideStep4Title => 'Test, then save';

  @override
  String get guideStep4Body => '“Test” checks the connection. Once it works, “Save” opens the server directly so you can browse and download your books.';

  @override
  String get configurationExamples => 'Configuration examples';

  @override
  String get webdavSubtitle => 'Recommended · Synology NAS, QNAP, Nextcloud';

  @override
  String get host => 'Host';

  @override
  String get webdavPorts => '5005 (Synology), 80 or 443';

  @override
  String get webdavCredentials => 'those of your NAS account';

  @override
  String get webdavTip => 'On Synology: install “WebDAV Server” from the Package Center and enable HTTP or HTTPS.';

  @override
  String get httpSubtitle => 'The easiest option from a computer';

  @override
  String get computerIp => 'IP of the computer';

  @override
  String get httpTip => 'In your comics folder, run “python3 -m http.server 8080”, or the server_example/comic_server.py script provided with ComicStream.';

  @override
  String get ftpSubtitle => 'Internet boxes, older NAS';

  @override
  String get ftpCredentials => 'FTP account of the box or NAS';

  @override
  String get ftpTip => 'FTP is not encrypted: keep it to your home network.';

  @override
  String get cannotConnectTitle => 'Can’t connect?';

  @override
  String get tipSameWifi => 'Check that the phone and the server are on the same Wi-Fi.';

  @override
  String get tipUseIp => 'Try the IP address rather than a name (nas.local).';

  @override
  String get tipFirewall => 'Check that the computer firewall allows the chosen port.';

  @override
  String get tipVpn => 'Away from home, use a VPN (WireGuard, Tailscale…) rather than exposing the server to the Internet.';

  @override
  String get importExistingConfiguration => 'Import an existing configuration';

  @override
  String get waiting => 'Waiting...';

  @override
  String get downloadingEllipsis => 'Downloading...';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get extractingFinalizing => 'Extracting and finalizing...';

  @override
  String get convertingHd => 'Converting to HD comic...';

  @override
  String secondsRemaining(Object approxSec) {
    return ' ~ ${approxSec}s left';
  }

  @override
  String convertingHdProgress(Object currentPage, Object totalPages, Object etaText) {
    return 'HD conversion ($currentPage/$totalPages pages)$etaText';
  }

  @override
  String get finishedStatus => 'Done';

  @override
  String get failed => 'Failed';

  @override
  String get networkTimeout => 'Timed out (network timeout)';

  @override
  String get invalidCertificate => 'Invalid security certificate (self-signed server?)';

  @override
  String get fileNotFound404 => 'File not found on the server (404)';

  @override
  String get accessDenied => 'Access denied (wrong credentials)';

  @override
  String get cannotReachServerLost => 'Unable to reach the server (connection lost)';

  @override
  String get downloadCancelled => 'Download cancelled';

  @override
  String get networkInterrupted => 'Network connection interrupted';

  @override
  String get notEnoughStorage => 'Not enough storage space on the device';

  @override
  String get networkError => 'Network connection error';

  @override
  String get localFileAccessError => 'Local file access error';

  @override
  String get serverError => 'Server error';

  @override
  String serverErrorCode(Object code) {
    return 'Server error ($code)';
  }

  @override
  String get endOfBookReached => 'You reached the end of the book!';

  @override
  String get loadingBook => 'Loading the book...';

  @override
  String get cannotLoadBook => 'Unable to load this book';

  @override
  String get fileMaybeCorrupted => 'The file may be corrupted or in an unsupported format.';

  @override
  String get backToLibrary => 'Back to the library';

  @override
  String epubProgressShort(Object value, Object currentChapterIndex1, Object length) {
    return '$value% • Ch. $currentChapterIndex1/$length';
  }

  @override
  String get tableOfContents => 'Table of contents';

  @override
  String get customizeReading => 'Customize reading';

  @override
  String chapterXOfY(Object currentChapterIndex1, Object length) {
    return 'Chapter $currentChapterIndex1 / $length';
  }

  @override
  String endOfChapter(Object currentChapterIndex1) {
    return 'End of chapter $currentChapterIndex1';
  }

  @override
  String get nextChapterUpper => 'NEXT CHAPTER';

  @override
  String get bookFinished => 'You finished this book!';

  @override
  String get tableOfContentsTitle => 'Table of Contents';

  @override
  String get searchChapterHint => 'Search a chapter...';

  @override
  String noChapterFound(Object tocSearchQuery) {
    return 'No chapter found for \"$tocSearchQuery\"';
  }

  @override
  String get bookCustomization => 'Book customization';

  @override
  String get themeColorsUpper => 'THEME & COLORS';

  @override
  String get sepia => 'Sepia';

  @override
  String get textSizeUpper => 'TEXT SIZE';

  @override
  String get fontUpper => 'FONT';

  @override
  String get serifBook => 'Serif (book)';

  @override
  String get bookMarginsUpper => 'BOOK MARGINS';

  @override
  String get narrow => 'Narrow';

  @override
  String get connectionFailedCheck => '❌ Connection failed. Check the IP address, port and credentials.';

  @override
  String get connectionOkFolderValid => '✅ Connected and folder validated!';

  @override
  String folderMissingOnServer(Object path) {
    return '❌ The server responds, but the folder \"$path\" does not exist on the server.';
  }

  @override
  String get checkingFolder => 'Checking the folder on the server...';

  @override
  String get cannotReachServerCheck => '❌ Unable to reach the server. Check the settings.';

  @override
  String cannotSaveFolderMissing(Object path) {
    return '❌ Unable to save: the folder \"$path\" does not exist on the server.';
  }

  @override
  String deleteProfileBody(Object name) {
    return 'Are you sure you want to delete the profile \"$name\"?';
  }

  @override
  String serverDeleted(Object serverName) {
    return '🗑️ Server \"$serverName\" deleted.';
  }

  @override
  String get addLocalServer => 'Add a local server';

  @override
  String get editServer => 'Edit the server';

  @override
  String get deleteThisServer => 'Delete this server';

  @override
  String get serverName => 'Server name';

  @override
  String get serverNameHint => 'E.g. Living room NAS, Office PC...';

  @override
  String get enterName => 'Please enter a name';

  @override
  String get ftpPort21 => 'FTP (port 21)';

  @override
  String get hostIp => 'Host / IP';

  @override
  String get hostHint => 'e.g. 192.168.1.100 or nas.local';

  @override
  String get hostRequired => 'IP or domain required';

  @override
  String get rootPath => 'Root path';

  @override
  String get secureConnectionHttps => 'Secure connection (HTTPS)';

  @override
  String get authenticationOptional => 'Authentication (optional)';

  @override
  String get usernameLabel => 'Username';

  @override
  String get password => 'Password';

  @override
  String get allFilesAccessRequired => 'Access to all files is required to scan the phone.';

  @override
  String get noCompatibleBookFound => 'No compatible book found on the phone.';

  @override
  String alreadyPresentOrSkipped(Object skipped) {
    return ' · $skipped already present or skipped';
  }

  @override
  String booksAddedCount(Object imported, Object skipped) {
    return '$imported book(s) added$skipped';
  }

  @override
  String importFailed(Object error) {
    return 'Import failed: $error';
  }

  @override
  String get permissionNotGranted => 'Permission not granted: no file was scanned.';

  @override
  String get scanPhoneTitle => 'Scan the books on this phone?';

  @override
  String get scanPhoneBody => 'ComicStream will request file access only to find comics, PDFs and EPUBs. You will then choose the files to import; nothing is copied without confirmation.';

  @override
  String get notNow => 'Not now';

  @override
  String get deviceFiles => 'Device files';

  @override
  String get addComicsFromDevice => 'Add comics from this device';

  @override
  String get addComicsFromDeviceBody => 'Scan every compatible file on the phone, then choose the books to keep.';

  @override
  String get scanningFiles => 'Scanning files…';

  @override
  String get scanPhone => 'Scan the phone';

  @override
  String addedFilesCount(Object length) {
    return 'Added files ($length)';
  }

  @override
  String get noFileAdded => 'No file added';

  @override
  String get scanPhoneToFindBooks => 'Scan the phone to find your books.';

  @override
  String formatPageProgress(Object formatString, Object currentPage1, Object totalPages) {
    return '$formatString · Page $currentPage1/$totalPages';
  }

  @override
  String pageXOfY(Object currentPage1, Object totalPages) {
    return 'Page $currentPage1 of $totalPages';
  }

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get pageGrid => 'Page grid';

  @override
  String get comicLtrShort => 'Comic (L->R)';

  @override
  String get mangaRtlShort => 'Manga (R->L)';

  @override
  String get readingDirection => 'Reading direction';

  @override
  String get comicLtr => 'Comic (L to R)';

  @override
  String get mangaRtl => 'Manga (R to L)';

  @override
  String get imageFit => 'Image fit';

  @override
  String get screen => 'Screen';

  @override
  String get background => 'Background';

  @override
  String get keepScreenAwake => 'Keep the screen on';

  @override
  String selectedCount(Object length) {
    return '$length selected';
  }

  @override
  String get removeAll => 'Remove all';

  @override
  String get addAll => 'Add all';

  @override
  String get alreadyImported => 'Already imported';

  @override
  String booksFoundCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0';
  }

  @override
  String sizeGb(Object value) {
    return '$value GB';
  }

  @override
  String sizeMb(Object value) {
    return '$value MB';
  }

  @override
  String sizeKb(Object value) {
    return '$value KB';
  }

  @override
  String get decimalSeparator => '.';

  @override
  String get convertToCbz => 'Convert to comic (CBZ)';

  @override
  String get markAsUnread => 'Mark as unread';

  @override
  String get markAsRead => 'Mark as read';

  @override
  String get deleteFromDevice => 'Delete from the device';

  @override
  String get finishedUpper => 'FINISHED';

  @override
  String get cbzBenefits => 'Benefits of the CBZ format:';

  @override
  String get cbzBenefit1 => '• Much faster and smoother rendering';

  @override
  String get cbzBenefit2 => '• Manga mode (right-to-left) available';

  @override
  String get cbzBenefit3 => '• Smooth Webtoon mode (continuous scrolling)';

  @override
  String get cbzBenefit4 => '• Lower memory and battery usage';

  @override
  String get converting => 'Converting...';

  @override
  String get conversionSucceeded => 'Conversion successful!';

  @override
  String get conversionSucceededBody => 'Your comic is available in high-definition CBZ format.';

  @override
  String get readAsCbz => 'Read in comic mode (CBZ)';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get downloads => 'Downloads';

  @override
  String get noDownloadInProgress => 'No download in progress';

  @override
  String get noDownloadInProgressBody => 'Files you download from your local server will appear here with their progress.';

  @override
  String inProgressCount(Object length) {
    return 'In progress ($length)';
  }

  @override
  String historyCount(Object length) {
    return 'History ($length)';
  }

  @override
  String doneWithSize(Object formatBytes) {
    return 'Done • $formatBytes';
  }

  @override
  String get deleteFromStorage => 'Delete from storage';

  @override
  String failedWithReason(Object reason) {
    return 'Failed: $reason';
  }

  @override
  String weeksAgo(Object weeks) {
    return '$weeks wk ago';
  }

  @override
  String daysAgo(Object inDays) {
    return '$inDays days ago';
  }

  @override
  String hoursAgo(Object inHours) {
    return '$inHours h ago';
  }

  @override
  String minutesAgo(Object inMinutes) {
    return '$inMinutes min ago';
  }

  @override
  String get justNow => 'Just now';

  @override
  String pdfNotFound(Object pdfFilePath) {
    return 'PDF file not found: $pdfFilePath';
  }

  @override
  String get pdfHasNoPage => 'The PDF file has no page.';

  @override
  String conversionInit(Object totalPages) {
    return 'Starting the conversion ($totalPages pages)...';
  }

  @override
  String renderingPagesRange(Object i1, Object currentBatchEnd, Object totalPages) {
    return 'HD rendering pages $i1 to $currentBatchEnd / $totalPages...';
  }

  @override
  String renderingPage(Object i1, Object totalPages) {
    return 'HD rendering page $i1 / $totalPages...';
  }

  @override
  String get assemblingCbz => 'Assembling the CBZ archive...';

  @override
  String get noPageGenerated => 'No page could be generated from the PDF.';

  @override
  String get cbzEncodingFailed => 'Failed to encode the CBZ archive.';

  @override
  String get finalizingCover => 'Finalizing and extracting the cover...';

  @override
  String get conversionDone => 'Conversion completed successfully!';

  @override
  String get cbzNotFound => 'CBZ file not found on the device.';

  @override
  String get noValidImageInCbz => 'No valid image found in this CBZ archive.';

  @override
  String cbzReadError(Object sizeMb, Object e) {
    return 'Read error ($sizeMb MB): $e\n\nThe file may be corrupted or the download incomplete.';
  }

  @override
  String pagesCount(Object length) {
    return 'Pages ($length)';
  }

  @override
  String get loadingVolume => 'Loading the volume...';

  @override
  String get volumeFinished => 'Volume finished! 🎉';

  @override
  String nextVolumeWithTitle(Object title) {
    return 'Go to the next volume ➔\n$title';
  }

  @override
  String bookSyncUnavailable(Object error) {
    return 'Sync unavailable for this book. Local reading kept: $error';
  }

  @override
  String get progressFoundElsewhere => 'Progress found on another device';

  @override
  String otherPositionOnDevice(Object remoteDeviceName) {
    return '“$remoteDeviceName” has another position for this book.';
  }

  @override
  String get thisDevice => 'This device';

  @override
  String get keepHere => 'Keep here';

  @override
  String continueFromDevice(Object remoteDeviceName) {
    return 'Continue from $remoteDeviceName';
  }

  @override
  String get downloadFailed => 'Download failed';

  @override
  String get convertingHdCbz => 'HD conversion to CBZ (comic mode)...';

  @override
  String get downloadingYourComic => 'Downloading your comic...';

  @override
  String get networkErrorOccurred => 'A network error occurred.';

  @override
  String get convertingHdInProgress => 'HD conversion in progress...';

  @override
  String get deleteFromDeviceTitle => 'Delete from the device?';

  @override
  String deleteDownloadedFileBody(Object name) {
    return 'Do you want to delete the locally downloaded file of \"$name\" to free up space?\n\nThe file remains available and downloadable from your server.';
  }

  @override
  String deletedFromDevice(Object name) {
    return '\"$name\" was deleted from your device.';
  }

  @override
  String get deleteLocalCopy => 'Delete local copy';

  @override
  String get downloadForOffline => 'Download for offline reading';

  @override
  String get updateAvailable => 'Update available!';

  @override
  String get whatsNew => 'What\'s new:';

  @override
  String get defaultReleaseNotes => 'Performance improvements and bug fixes.';

  @override
  String get downloadApk => 'Download APK';

  @override
  String get almostDone => 'Almost done...';

  @override
  String secondsLeft(Object seconds) {
    return '~ $seconds s left';
  }

  @override
  String itemsCount(Object itemCount) {
    return '$itemCount items';
  }

  @override
  String readOfTotal(Object completedBooks, Object totalBooks) {
    return '$completedBooks/$totalBooks read';
  }

  @override
  String get emptyServerResponse => 'Empty response from the server';

  @override
  String chapterN(Object length1) {
    return 'Chapter $length1';
  }

  @override
  String chapterNIdx(Object idx1) {
    return 'Chapter $idx1';
  }

  @override
  String get pdfNotFoundOnDevice => 'PDF file not found on the device.';

  @override
  String get convertToCbzComicMode => 'Convert to CBZ (comic mode)';

  @override
  String get pressAgainToExit => 'Press again to exit ComicStream';

  @override
  String get downloadsTabShort => 'Offline';

  @override
  String get settingsTab => 'Settings';

  @override
  String get invalidJsonFormat => 'Invalid JSON format';

  @override
  String cannotLoadFolder(Object e) {
    return 'Unable to load the folder: $e';
  }

  @override
  String get newUpdateAvailable => 'A new update is available.';

  @override
  String get unknownEncryptionVersion => 'Unknown encryption version';

  @override
  String speedMb(Object value) {
    return '$value MB/s';
  }

  @override
  String speedKb(Object value) {
    return '$value KB/s';
  }

  @override
  String minutesSecondsLeft(Object minutes, Object seconds) {
    return '~ $minutes min $seconds s';
  }

  @override
  String volumeCountPlural(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count volumes',
      one: '1 volume',
    );
    return '$_temp0';
  }

  @override
  String chapterSlashPercent(Object current, Object total, Object percent) {
    return 'Chapter $current/$total · $percent%';
  }

  @override
  String labelLocationDate(Object label, Object location, Object date, Object time) {
    return '$label: $location\n$date at $time';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get edit => 'Edit';

  @override
  String get continueLabel => 'Continue';

  @override
  String get save => 'Save';

  @override
  String get view => 'View';

  @override
  String get synchronize => 'Sync';

  @override
  String get back => 'Back';

  @override
  String get none => 'None';

  @override
  String get all => 'All';

  @override
  String get importAction => 'Import';

  @override
  String get everyone => 'All';

  @override
  String get clean => 'Clear';

  @override
  String get read => 'Read';

  @override
  String get dark => 'Dark';

  @override
  String get mint => 'Mint';

  @override
  String get light => 'Light';

  @override
  String get standard => 'Standard';

  @override
  String get large => 'Wide';

  @override
  String get libraryTab => 'Library';

  @override
  String get serverTab => 'Server';

  @override
  String get filesTab => 'Files';

  @override
  String get delete => 'Delete';

  @override
  String get resume => 'Resume';

  @override
  String get progress => 'Progress';

  @override
  String get favorites => 'Favorites';

  @override
  String get close => 'Close';

  @override
  String get options => 'Options';

  @override
  String get search => 'Search';

  @override
  String get refresh => 'Refresh';

  @override
  String get root => 'Root';

  @override
  String get empty => 'Empty';

  @override
  String get font => 'Font';

  @override
  String get lineSpacing => 'Line spacing';

  @override
  String get compact => 'Compact';

  @override
  String get normal => 'Normal';

  @override
  String get relaxed => 'Relaxed';

  @override
  String get margin => 'Margin';

  @override
  String get narrowShort => 'Narrow';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get today => 'Today';

  @override
  String get folder => 'Folder';

  @override
  String get convert => 'Convert';

  @override
  String get width => 'Width';

  @override
  String get height => 'Height';

  @override
  String get black => 'Black';

  @override
  String get grey => 'Grey';

  @override
  String get white => 'White';

  @override
  String get downloaded => 'Downloaded';

  @override
  String get serverDefaultName => 'Server';

  @override
  String get test => 'Test';

  @override
  String get type => 'Type';

  @override
  String get port => 'Port';

  @override
  String get path => 'Path';

  @override
  String get credentials => 'Credentials';

  @override
  String get ignore => 'Ignore';

  @override
  String get noneLower => 'none';

  @override
  String get serverUpper => 'SERVER';

  @override
  String get bookUpper => 'BOOK';

  @override
  String get resumeUpper => 'RESUME';

  @override
  String get currentUpper => 'CURRENT';

  @override
  String get lineSpacingUpper => 'LINE SPACING';

  @override
  String get alignmentUpper => 'ALIGNMENT';

  @override
  String get comicsFilter => 'Comics';

  @override
  String get navLibrary => 'Library';

  @override
  String get navServers => 'Servers';

  @override
  String get computerFiles => 'Computer files';

  @override
  String get addComicsFromComputerBody => 'Pick comics (CBZ, CBR, PDF, EPUB) or a whole folder to scan. Double-clicking a file in Explorer also opens it directly.';

  @override
  String get openFiles => 'Open files…';

  @override
  String get scanFolder => 'Scan a folder…';

  @override
  String get columnTitle => 'Title';

  @override
  String get columnFormat => 'Format';

  @override
  String get columnSize => 'Size';

  @override
  String get columnAdded => 'Added';

  @override
  String get doublePageTitle => 'Two-page spread on large screens';

  @override
  String get doublePageBody => 'Two pages side by side when the window is wide and in landscape';

  @override
  String get onePage => '1 page';

  @override
  String get twoPages => '2 pages';

  @override
  String get togglePagesPerView => 'Show 1 or 2 pages (D)';
}
