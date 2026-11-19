import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get resetVaultTitle => 'Tresor zurücksetzen?';

  @override
  String get resetVaultBody => 'Wenn du deine Wiederherstellungsphrase verloren hast, erstellt das Zurücksetzen einen neuen, leeren Tresor. Geschützte Daten deiner anderen Geräte müssen erneut synchronisiert werden.';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get confirmSecretPhrase => 'Geheimphrase bestätigen';

  @override
  String get secretPhraseWrittenDownBody => 'Hast du deine Geheimphrase an einem sicheren Ort notiert?\n\nSie ist unerlässlich, um deine Daten wiederherzustellen oder ein neues Gerät zu synchronisieren. ComicStream speichert sie nicht und kann sie niemals für dich wiederherstellen.';

  @override
  String get yourSecretPhrase => 'Deine Geheimphrase:';

  @override
  String get phraseNotedContinue => 'Notiert, weiter';

  @override
  String get changeSecretPhrase => 'Geheimphrase ändern';

  @override
  String get changeSecretPhraseBody => 'Lege eine neue Geheimphrase fest (mindestens 16 Zeichen), um deine Synchronisierung zu schützen.';

  @override
  String get newSecretPhrase => 'Neue Geheimphrase';

  @override
  String get min16Characters => 'Mindestens 16 Zeichen';

  @override
  String get showPhrase => 'Phrase anzeigen';

  @override
  String get hidePhrase => 'Phrase verbergen';

  @override
  String get confirmNewPhrase => 'Neue Phrase bestätigen';

  @override
  String get phraseTooShort => 'Die Phrase muss mindestens 16 Zeichen lang sein.';

  @override
  String get phrasesDoNotMatch => 'Die beiden Phrasen stimmen nicht überein.';

  @override
  String get confirmChangeTitle => 'Änderung bestätigen?';

  @override
  String get confirmChangeBody => 'Dein Tresor wird mit dieser neuen Geheimphrase aktualisiert.\nStelle sicher, dass du sie notiert hast:';

  @override
  String get confirmAndSave => 'Bestätigen und speichern';

  @override
  String get secretPhraseUpdated => 'Geheimphrase erfolgreich aktualisiert.';

  @override
  String get operationDone => 'Vorgang abgeschlossen.';

  @override
  String cannotContinue(Object error) {
    return 'Fortfahren nicht möglich: $error';
  }

  @override
  String dateAtTime(Object date, Object time) {
    return '$date um $time';
  }

  @override
  String get syncConflict => 'Synchronisierungskonflikt';

  @override
  String syncConflictBody(Object label) {
    return 'Zwei Versionen von „$label“ wurden geändert.';
  }

  @override
  String thisDeviceValue(Object formatConflictDate) {
    return 'Dieses Gerät: $formatConflictDate';
  }

  @override
  String syncServerValue(Object formatConflictDate) {
    return 'Synchronisierungsserver: $formatConflictDate';
  }

  @override
  String thisDeviceSummary(Object localSummary) {
    return 'Dieses Gerät: $localSummary';
  }

  @override
  String serverSummary(Object remoteSummary) {
    return 'Server: $remoteSummary';
  }

  @override
  String get chooseReferenceVersion => 'Wähle die Referenzversion. Sie wird anschließend auf deine anderen Geräte synchronisiert.';

  @override
  String get fetchFromServer => 'Vom Server abrufen';

  @override
  String get sendToServer => 'An den Server senden';

  @override
  String get later => 'Später';

  @override
  String get thisDeviceName => 'Name dieses Geräts';

  @override
  String get deviceNameHint => 'Z. B. Tablet oder Telefon';

  @override
  String get deviceNameSavedOnServer => 'Gerätename auf dem Server gespeichert.';

  @override
  String get deviceNameSavedLocally => 'Name auf diesem Gerät gespeichert. Er wird bei der nächsten Synchronisierung gesendet.';

  @override
  String cannotPrepareSync(Object error) {
    return 'Synchronisierung kann nicht vorbereitet werden: $error';
  }

  @override
  String get whichBackupToUse => 'Welche Sicherung verwenden?';

  @override
  String get whichBackupBody => 'Deine Wahl wird zur gemeinsamen Referenz. Die anderen Geräte erhalten sie bei ihrer nächsten Synchronisierung.';

  @override
  String get notBackedUpYet => 'Noch nicht gesichert';

  @override
  String backedUpAt(Object formatConflictDate) {
    return 'Gesichert $formatConflictDate';
  }

  @override
  String get accountAndSync => 'Konto und Synchronisierung';

  @override
  String get syncUnavailableNoFirebase => 'Die Synchronisierung ist verfügbar, sobald das Firebase-Projekt eingerichtet ist. Der Reader und deine lokalen Daten funktionieren weiterhin normal.';

  @override
  String get accountConnected => 'Angemeldet';

  @override
  String get vaultUnlockedE2e => 'Tresor entsperrt. Deine Daten sind Ende-zu-Ende-verschlüsselt.';

  @override
  String get vaultLockedOrNew => 'Tresor gesperrt oder nicht eingerichtet.';

  @override
  String get unlockVault => 'Tresor entsperren';

  @override
  String get initEncryptedVault => 'Verschlüsselten Tresor einrichten';

  @override
  String get unlockVaultBody => 'Mit diesem Konto ist ein verschlüsselter Tresor verknüpft. Gib deine Wiederherstellungsphrase ein, um die Synchronisierung auf diesem Gerät zu entsperren.';

  @override
  String get initVaultBody => 'Um deine Serverpasswörter und Daten zu schützen, wähle eine Geheimphrase (mindestens 16 Zeichen). Sie ist unerlässlich, um deine Daten auf einem neuen Gerät wiederherzustellen.';

  @override
  String get recoveryPhrase => 'Wiederherstellungsphrase';

  @override
  String get secretPhraseMin16 => 'Geheimphrase (mindestens 16 Zeichen)';

  @override
  String get enterRecoveryPhrase => 'Bitte gib deine Wiederherstellungsphrase ein.';

  @override
  String get secretPhraseTooShort => 'Die Geheimphrase muss mindestens 16 Zeichen lang sein.';

  @override
  String get secretPhrasesDoNotMatch => 'Die Geheimphrasen stimmen nicht überein.';

  @override
  String get unlockSync => 'Synchronisierung entsperren';

  @override
  String get createAndEnableVault => 'Tresor erstellen und aktivieren';

  @override
  String get forgotPhraseReset => 'Phrase vergessen? Tresor zurücksetzen';

  @override
  String get vaultUnlocked => 'Tresor entsperrt';

  @override
  String get syncActiveE2e => 'Die Synchronisierung ist aktiv und durch Ende-zu-Ende-Verschlüsselung geschützt.';

  @override
  String get syncing => 'Synchronisierung…';

  @override
  String get changePhrase => 'Phrase ändern';

  @override
  String get shownWhenChoosingBackup => 'Wird bei der Auswahl einer Sicherung angezeigt';

  @override
  String get signOut => 'Abmelden';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get signIn => 'Anmelden';

  @override
  String get passwordMin12 => 'Passwort (mindestens 12 Zeichen)';

  @override
  String get showPassword => 'Passwort anzeigen';

  @override
  String get hidePassword => 'Passwort verbergen';

  @override
  String get createTheAccount => 'Konto erstellen';

  @override
  String get alreadyHaveAccount => 'Ich habe bereits ein Konto';

  @override
  String get continueWithGoogle => 'Weiter mit Google';

  @override
  String get recoveryPhraseRequiredNote => 'Die Wiederherstellungsphrase ist nötig, um Serverpasswörter auf einem neuen Gerät wiederherzustellen. ComicStream speichert sie niemals.';

  @override
  String androidCertNotAllowed(Object hashes) {
    return 'Android-Zertifikat nicht zugelassen: $hashes';
  }

  @override
  String pendingConflicts(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Änderungen warten auf deine Entscheidung.',
      one: '1 Änderung wartet auf deine Entscheidung.',
    );
    return '$_temp0';
  }

  @override
  String upToDate(Object fullVersion) {
    return 'ComicStream ist aktuell ($fullVersion)!';
  }

  @override
  String get updateCheckError => 'Fehler bei der Suche nach Updates';

  @override
  String get clearCacheTitle => 'Cache leeren?';

  @override
  String get clearCacheBody => 'Die Cover werden automatisch neu geladen.';

  @override
  String get coverCacheCleared => 'Cover-Cache erfolgreich geleert!';

  @override
  String get deleteAllTitle => 'Alles löschen?';

  @override
  String get deleteAllBody => 'Dadurch werden alle lokal heruntergeladenen Comics und Mangas gelöscht, um Speicherplatz freizugeben. Deine Servereinstellungen bleiben erhalten.';

  @override
  String get allLocalFilesDeleted => 'Alle lokalen Dateien wurden gelöscht.';

  @override
  String get eraseAll => 'Alles löschen';

  @override
  String get commandCopied => 'Befehl kopiert!';

  @override
  String get localServerGuide => 'Anleitung lokaler Server';

  @override
  String get guideOption1 => 'Option 1: WebDAV-Server mit Docker (empfohlen)';

  @override
  String get guideOption1Body => 'Starte mit Docker in einer Zeile einen schlanken WebDAV-Server, der auf deinen Comic-Ordner zeigt:';

  @override
  String get guideOption2 => 'Option 2: Fertiges Python-Skript';

  @override
  String get guideOption2Body => 'Ein eigener Python-Server liegt unter `server_example/comic_server.py`. So startest du ihn:';

  @override
  String get guideOption3 => 'Option 3: Synology NAS / TrueNAS / Nextcloud';

  @override
  String get guideOption3Body => 'Aktiviere einfach den WebDAV-Dienst in der Verwaltung deines NAS (Port 5005 standardmäßig bei Synology) und gib deine Zugangsdaten in der App ein.';

  @override
  String get settings => 'Einstellungen';

  @override
  String get accountAndSyncShort => 'Konto & Synchronisierung';

  @override
  String get accountAndSyncSubtitle => 'Verschlüsselte Server, Fortschritt und Einstellungen';

  @override
  String get appearanceTheme => 'Darstellung & Design';

  @override
  String get appTheme => 'App-Design';

  @override
  String get readerPreferences => 'Reader-Einstellungen';

  @override
  String get defaultReadingMode => 'Standard-Lesemodus';

  @override
  String get readingModeComic => 'Comic (links nach rechts)';

  @override
  String get readingModeManga => 'Manga (rechts nach links)';

  @override
  String get readingModeWebtoon => 'Webtoon (vertikales Scrollen)';

  @override
  String get keepScreenOn => 'Bildschirm beim Lesen eingeschaltet lassen';

  @override
  String get showPageNumber => 'Seitenzahl anzeigen';

  @override
  String get autoConvertPdf => 'PDFs automatisch in CBZ umwandeln';

  @override
  String get autoConvertPdfBody => 'Wandelt jedes heruntergeladene PDF in ein besonders flüssiges Comic-Archiv für Tablets um.';

  @override
  String get comicRenderQuality => 'Comic-Darstellungsqualität';

  @override
  String get qualityAutoLong => 'Automatisch (erkennt den Bildschirm + 35 % Schärfe)';

  @override
  String get qualitySuperLong => 'Supersampling (2600px - scharfer Zoom)';

  @override
  String get qualityUltraLong => 'Ultra HD (3500px - maximale Auflösung)';

  @override
  String get qualityStandardLong => 'Standard 1:1 (1900px - schnell)';

  @override
  String get qualityAuto => 'Auto (Bildschirm + 35 %)';

  @override
  String get qualityHigh => 'Hoch (2600px)';

  @override
  String get qualityStandard => 'Standard 1:1';

  @override
  String get ebooksEpub => 'E-Books & EPUB';

  @override
  String get fontSize => 'Schriftgröße';

  @override
  String get justifiedText => 'Blocksatz';

  @override
  String get storageCache => 'Speicher & Cache';

  @override
  String get spaceUsedByBooks => 'Von Büchern belegter Speicher:';

  @override
  String booksDownloadedCount(Object length) {
    return '$length Buch/Bücher heruntergeladen';
  }

  @override
  String get clearCache => 'Cache leeren';

  @override
  String get updates => 'Updates';

  @override
  String get checkForUpdate => 'Nach Updates suchen';

  @override
  String installedVersion(Object fullVersion) {
    return 'Installierte Version: $fullVersion';
  }

  @override
  String get check => 'Prüfen';

  @override
  String get seeStoreListing => 'Offiziellen ComicStream-Eintrag ansehen';

  @override
  String get helpSetup => 'Hilfe & Einrichtung';

  @override
  String get howToSetupLocalServer => 'Wie richte ich meinen lokalen Server ein?';

  @override
  String get helpSetupSubtitle => 'Docker, Python, Synology NAS, TrueNAS...';

  @override
  String get appTagline => 'Cloud-Reader für Comics & Mangas';

  @override
  String get deleteBookTitle => 'Dieses Buch löschen?';

  @override
  String deleteBookBody(Object title) {
    return 'Möchtest du „$title“ aus deinem lokalen Speicher löschen?';
  }

  @override
  String resumeAtChapter(Object title, Object currentPage1) {
    return '„$title“ wurde bereits begonnen. Bei Kapitel $currentPage1 fortfahren?';
  }

  @override
  String resumeAtPage(Object title, Object currentPage1) {
    return '„$title“ wurde bereits begonnen. Bei Seite $currentPage1 fortfahren?';
  }

  @override
  String get myLibrary => 'Meine Bibliothek';

  @override
  String comicsCount(Object length) {
    return '$length Comics';
  }

  @override
  String get syncInProgress => 'Synchronisierung läuft';

  @override
  String get sortBy => 'Sortieren nach';

  @override
  String get lastRead => 'Zuletzt gelesen';

  @override
  String get titleAz => 'Titel (A-Z)';

  @override
  String get dateAdded => 'Hinzugefügt am';

  @override
  String seriesCount(Object length) {
    return 'Serien ($length)';
  }

  @override
  String volumesCount(Object length) {
    return 'Bände ($length)';
  }

  @override
  String get searchLibraryHint => 'Serie, Band oder Autor suchen...';

  @override
  String get recentlyOpened => 'Zuletzt geöffnet';

  @override
  String myCollectionsCount(Object length) {
    return 'Meine Sammlungen & Serien ($length)';
  }

  @override
  String get backToSeries => 'Zurück zu den Serien';

  @override
  String seriesProgress(Object completedBooks, Object totalBooks, Object progressPercent) {
    return '$completedBooks/$totalBooks Bände gelesen • $progressPercent%';
  }

  @override
  String get checkNewVolumes => 'Auf dem Server nach neuen Bänden suchen';

  @override
  String get nextVolumeToRead => 'NÄCHSTER BAND ZUM LESEN';

  @override
  String get nextVolumeOnServer => 'NÄCHSTER BAND AUF DEM SERVER';

  @override
  String get download => 'Herunterladen';

  @override
  String downloadStarted(Object name) {
    return '📥 Download gestartet: $name';
  }

  @override
  String get readNow => 'Jetzt lesen';

  @override
  String get searchingNextVolumes => 'Suche nach den nächsten Bänden auf dem Server...';

  @override
  String downloadedVolumesCount(Object totalBooks) {
    return 'Heruntergeladene Bände ($totalBooks)';
  }

  @override
  String serverVolumesCount(Object length) {
    return 'Auf dem Server verfügbare Bände ($length)';
  }

  @override
  String downloadAllCount(Object length) {
    return 'Alle herunterladen ($length)';
  }

  @override
  String volumesQueued(Object length) {
    return '📥 $length Bände zur Download-Warteschlange hinzugefügt';
  }

  @override
  String downloadingName(Object name) {
    return '📥 Download: $name';
  }

  @override
  String get libraryFilters => 'Bibliotheksfilter';

  @override
  String allCount(Object length) {
    return 'Alle ($length)';
  }

  @override
  String get inProgress => 'Begonnen';

  @override
  String get unread => 'Ungelesen';

  @override
  String get epubNovels => 'EPUB / Romane';

  @override
  String get finished => 'Beendet';

  @override
  String get continueReading => 'WEITERLESEN';

  @override
  String get libraryEmpty => 'Deine Bibliothek ist leer';

  @override
  String get libraryEmptyBody => 'Fügen Sie Ihre Comics von einem Server oder aus Dateien auf diesem Gerät hinzu.';

  @override
  String get exploreServers => 'Meine Server durchsuchen';

  @override
  String get importFromPhone => 'Von diesem Gerät importieren';

  @override
  String get noSearchResults => 'Keine Ergebnisse für diese Suche';

  @override
  String get noSearchResultsBody => 'Versuche ein anderes Stichwort oder setze die Filter zurück.';

  @override
  String chapterProgressPercent(Object current, Object total, Object percent) {
    return 'Kapitel $current/$total ($percent%)';
  }

  @override
  String pageProgressPercent(Object current, Object total, Object percent) {
    return 'Seite $current/$total ($percent%)';
  }

  @override
  String chapterOfTotal(Object current, Object total) {
    return 'Kapitel $current von $total';
  }

  @override
  String pageOfTotal(Object current, Object total) {
    return 'Seite $current von $total';
  }

  @override
  String get setupServer => 'Server einrichten';

  @override
  String connectionSucceeded(Object name) {
    return 'Verbunden mit $name!';
  }

  @override
  String connectionFailed(Object name) {
    return 'Verbindung zu $name fehlgeschlagen';
  }

  @override
  String get deleteServerTitle => 'Diesen Server löschen?';

  @override
  String deleteServerBody(Object name) {
    return 'Möchtest du „$name“ wirklich aus deinen Quellen löschen?';
  }

  @override
  String get exportConfiguration => 'Konfiguration exportieren';

  @override
  String get exportConfigurationBody => 'Hier ist die JSON-Konfigurationsdatei mit deinen Serverprofilen:';

  @override
  String get copyJson => 'JSON kopieren';

  @override
  String get configurationCopied => '✅ Konfiguration in die Zwischenablage kopiert!';

  @override
  String get importConfiguration => 'Konfiguration importieren';

  @override
  String get chooseJsonFile => '.json-Datei auswählen';

  @override
  String fileReadError(Object e) {
    return 'Fehler beim Lesen der Datei: $e';
  }

  @override
  String get orPasteJson => 'Oder füge das JSON hier ein:';

  @override
  String serversImported(Object count) {
    return '✅ $count Server erfolgreich importiert!';
  }

  @override
  String baseLocationSet(Object currentPath) {
    return '✅ Basisverzeichnis festgelegt auf: $currentPath';
  }

  @override
  String get myServers => 'Meine Server';

  @override
  String get addServer => 'Server hinzufügen';

  @override
  String get howToSetupServer => 'Server einrichten – so geht\'s';

  @override
  String get exportConfigurations => 'Konfigurationen exportieren';

  @override
  String get testConnection => 'Verbindung testen';

  @override
  String get filterFolderHint => 'Diesen Ordner filtern...';

  @override
  String get closeSearch => 'Suche schließen';

  @override
  String get folderOptions => 'Ordneroptionen';

  @override
  String get setFolderAsRoot => 'Diesen Ordner als Stamm festlegen';

  @override
  String get switchServer => 'Server wechseln';

  @override
  String get parentFolder => 'Übergeordneter Ordner';

  @override
  String everythingCount(Object length) {
    return 'Alles ($length)';
  }

  @override
  String get downloadAllTitle => 'Alles herunterladen?';

  @override
  String downloadAllBody(Object length) {
    return '$length Bände werden im Hintergrund heruntergeladen.';
  }

  @override
  String volumesQueuedCount(Object length) {
    return '📥 $length Band/Bände zur Download-Warteschlange hinzugefügt';
  }

  @override
  String foldersSeriesCount(Object length) {
    return 'Ordner & Serien ($length)';
  }

  @override
  String booksComicsCount(Object length) {
    return 'Bücher & Comics ($length)';
  }

  @override
  String downloadingNamePlain(Object name) {
    return 'Download: $name';
  }

  @override
  String get folderEmpty => 'Dieser Ordner ist leer';

  @override
  String get folderEmptyBody => 'An diesem Ort wurde kein Buch und kein Unterordner gefunden.';

  @override
  String get cannotConnectServer => 'Verbindung zum Server nicht möglich';

  @override
  String checkServerReachable(Object baseUrl) {
    return 'Prüfe, ob der Server unter $baseUrl erreichbar ist.';
  }

  @override
  String get editSettings => 'Einstellungen bearbeiten';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get googleTokenMissing => 'Google-Authentifizierungstoken nicht gefunden.';

  @override
  String get googleSignInUnavailable => 'Die Google-Anmeldung ist auf diesem Gerät nicht verfügbar.';

  @override
  String get recoveryPhraseTooShort => 'Die Wiederherstellungsphrase muss mindestens 16 Zeichen lang sein.';

  @override
  String get signInRequired => 'Anmeldung erforderlich';

  @override
  String get noSyncVaultFound => 'Kein Synchronisierungstresor gefunden.';

  @override
  String get vaultMustBeUnlocked => 'Der Tresor muss entsperrt sein, um die Geheimphrase zu ändern.';

  @override
  String get recoveryPhraseRequiredHere => 'Wiederherstellungsphrase auf diesem Gerät erforderlich.';

  @override
  String get serverConfigurations => 'Serverkonfigurationen';

  @override
  String get readingSettings => 'Leseeinstellungen';

  @override
  String get deviceNameLength => 'Der Name muss zwischen 1 und 40 Zeichen lang sein.';

  @override
  String deviceDefaultName(Object substring) {
    return 'Gerät $substring';
  }

  @override
  String get otherDevice => 'Anderes Gerät';

  @override
  String get remoteProgressGone => 'Dieser entfernte Fortschritt existiert nicht mehr.';

  @override
  String thisDeviceNamed(Object currentName) {
    return 'Dieses Gerät — $currentName';
  }

  @override
  String get deviceBackupNotFound => 'Die Sicherung dieses Geräts wurde nicht gefunden.';

  @override
  String get googleDataNotFound => 'Die aufzulösenden Google-Daten wurden nicht gefunden.';

  @override
  String get localProgressGone => 'Der zugehörige lokale Fortschritt existiert nicht mehr.';

  @override
  String get unknownSyncDocument => 'Unbekanntes Synchronisierungsdokument';

  @override
  String get readingSettingsShort => 'Leseeinstellungen';

  @override
  String get yes => 'ja';

  @override
  String get no => 'nein';

  @override
  String chapterSlash(Object current, Object total) {
    return 'Kapitel $current/$total';
  }

  @override
  String pageSlash(Object current, Object total) {
    return 'Seite $current/$total';
  }

  @override
  String progressSummary(Object location, Object favorite, Object bookmarks) {
    return '$location · Favorit: $favorite · $bookmarks';
  }

  @override
  String bookmarksCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Lesezeichen',
      one: '1 Lesezeichen',
      zero: '0 Lesezeichen',
    );
    return '$_temp0';
  }

  @override
  String serverProfilesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Serverprofile',
      one: '1 Serverprofil',
      zero: '0 Serverprofile',
    );
    return '$_temp0';
  }

  @override
  String ftpInvalidServer(Object banner) {
    return 'Ungültiger FTP-Server: $banner';
  }

  @override
  String ftpCredentialsRefused(Object passResp) {
    return 'FTP-Zugangsdaten abgelehnt: $passResp';
  }

  @override
  String ftpUsernameRefused(Object userResp) {
    return 'FTP-Benutzername abgelehnt: $userResp';
  }

  @override
  String ftpPassiveFailed(Object pasvResp) {
    return 'FTP-Passivmodus fehlgeschlagen: $pasvResp';
  }

  @override
  String ftpDownloadFailed(Object retrResp) {
    return 'FTP-Datei kann nicht heruntergeladen werden: $retrResp';
  }

  @override
  String get ftpIdleTimeout => 'FTP-Zeitlimit wegen Inaktivität überschritten';

  @override
  String ftpPasvUnrecognized(Object response) {
    return 'Unbekannte PASV-Antwort: $response';
  }

  @override
  String get guideHeroTitle => 'Lies die Comics von deinem Computer oder NAS';

  @override
  String get guideHeroBody => 'Ein Server macht Ihre Sammlung in der App verfügbar, ohne alles zu kopieren. Dauert etwa 2 Minuten.';

  @override
  String get howItWorks => 'So geht\'s';

  @override
  String get guideStep1Title => 'Teile deinen Comic-Ordner';

  @override
  String get guideStep1Body => 'Aktiviere auf deinem NAS oder Computer eine WebDAV-, FTP- oder HTTP-Freigabe für den Ordner mit deinen CBZ-, CBR-, PDF- oder EPUB-Dateien. Die Beispiele unten erklären jeden Fall.';

  @override
  String get guideStep2Title => 'Notiere die Adresse';

  @override
  String get guideStep2Body => 'Ermitteln Sie die lokale IP-Adresse des Rechners (z. B. 192.168.1.100) und den Port der Freigabe. Dieses Gerät muss im selben Netzwerk sein.';

  @override
  String get guideStep3Title => 'Fülle das Formular aus';

  @override
  String get guideStep3Body => 'Tippe auf „Server hinzufügen“, wähle den Typ und gib dann Host, Port, Ordnerpfad und bei Bedarf Benutzername und Passwort ein.';

  @override
  String get guideStep4Title => 'Testen, dann speichern';

  @override
  String get guideStep4Body => '„Testen“ prüft die Verbindung. Sobald sie klappt, öffnet „Speichern“ direkt den Server, damit du deine Bücher durchsuchen und herunterladen kannst.';

  @override
  String get configurationExamples => 'Konfigurationsbeispiele';

  @override
  String get webdavSubtitle => 'Empfohlen · Synology NAS, QNAP, Nextcloud';

  @override
  String get host => 'Host';

  @override
  String get webdavPorts => '5005 (Synology), 80 oder 443';

  @override
  String get webdavCredentials => 'die deines NAS-Kontos';

  @override
  String get webdavTip => 'Bei Synology: Installiere „WebDAV Server“ aus dem Paket-Zentrum und aktiviere HTTP oder HTTPS.';

  @override
  String get httpSubtitle => 'Am einfachsten von einem Computer aus';

  @override
  String get computerIp => 'IP des Computers';

  @override
  String get httpTip => 'Führe in deinem Comic-Ordner „python3 -m http.server 8080“ aus oder das mit ComicStream gelieferte Skript server_example/comic_server.py.';

  @override
  String get ftpSubtitle => 'Router, ältere NAS';

  @override
  String get ftpCredentials => 'FTP-Konto des Routers oder NAS';

  @override
  String get ftpTip => 'FTP ist nicht verschlüsselt: Nutze es nur in deinem Heimnetz.';

  @override
  String get cannotConnectTitle => 'Keine Verbindung?';

  @override
  String get tipSameWifi => 'Prüfen Sie, ob dieses Gerät und der Server im selben Netzwerk sind.';

  @override
  String get tipUseIp => 'Verwende die IP-Adresse statt eines Namens (nas.local).';

  @override
  String get tipFirewall => 'Prüfe, ob die Firewall des Computers den gewählten Port erlaubt.';

  @override
  String get tipVpn => 'Unterwegs nutze ein VPN (WireGuard, Tailscale…), statt den Server ins Internet zu stellen.';

  @override
  String get importExistingConfiguration => 'Vorhandene Konfiguration importieren';

  @override
  String get waiting => 'Wartet...';

  @override
  String get downloadingEllipsis => 'Wird heruntergeladen...';

  @override
  String get cancelled => 'Abgebrochen';

  @override
  String get extractingFinalizing => 'Entpacken und abschließen...';

  @override
  String get convertingHd => 'Umwandlung in HD-Comic...';

  @override
  String secondsRemaining(Object approxSec) {
    return ' ~ noch ${approxSec}s';
  }

  @override
  String convertingHdProgress(Object currentPage, Object totalPages, Object etaText) {
    return 'HD-Umwandlung ($currentPage/$totalPages Seiten)$etaText';
  }

  @override
  String get finishedStatus => 'Fertig';

  @override
  String get failed => 'Fehlgeschlagen';

  @override
  String get networkTimeout => 'Zeitüberschreitung (Netzwerk)';

  @override
  String get invalidCertificate => 'Ungültiges Sicherheitszertifikat (selbstsignierter Server?)';

  @override
  String get fileNotFound404 => 'Datei auf dem Server nicht gefunden (404)';

  @override
  String get accessDenied => 'Zugriff verweigert (falsche Zugangsdaten)';

  @override
  String get cannotReachServerLost => 'Server nicht erreichbar (Verbindung verloren)';

  @override
  String get downloadCancelled => 'Download abgebrochen';

  @override
  String get networkInterrupted => 'Netzwerkverbindung unterbrochen';

  @override
  String get notEnoughStorage => 'Nicht genügend Speicherplatz auf dem Gerät';

  @override
  String get networkError => 'Netzwerkverbindungsfehler';

  @override
  String get localFileAccessError => 'Fehler beim Zugriff auf die lokale Datei';

  @override
  String get serverError => 'Serverfehler';

  @override
  String serverErrorCode(Object code) {
    return 'Serverfehler ($code)';
  }

  @override
  String get endOfBookReached => 'Du hast das Ende des Buchs erreicht!';

  @override
  String get loadingBook => 'Buch wird geladen...';

  @override
  String get cannotLoadBook => 'Dieses Buch kann nicht geladen werden';

  @override
  String get fileMaybeCorrupted => 'Die Datei ist möglicherweise beschädigt oder hat ein nicht unterstütztes Format.';

  @override
  String get backToLibrary => 'Zurück zur Bibliothek';

  @override
  String epubProgressShort(Object value, Object currentChapterIndex1, Object length) {
    return '$value% • Kap. $currentChapterIndex1/$length';
  }

  @override
  String get tableOfContents => 'Inhaltsverzeichnis';

  @override
  String get customizeReading => 'Lesen anpassen';

  @override
  String chapterXOfY(Object currentChapterIndex1, Object length) {
    return 'Kapitel $currentChapterIndex1 / $length';
  }

  @override
  String endOfChapter(Object currentChapterIndex1) {
    return 'Ende von Kapitel $currentChapterIndex1';
  }

  @override
  String get nextChapterUpper => 'NÄCHSTES KAPITEL';

  @override
  String get bookFinished => 'Du hast dieses Buch beendet!';

  @override
  String get tableOfContentsTitle => 'Inhaltsverzeichnis';

  @override
  String get searchChapterHint => 'Kapitel suchen...';

  @override
  String noChapterFound(Object tocSearchQuery) {
    return 'Kein Kapitel gefunden für „$tocSearchQuery“';
  }

  @override
  String get bookCustomization => 'Buch anpassen';

  @override
  String get themeColorsUpper => 'DESIGN & FARBEN';

  @override
  String get sepia => 'Sepia';

  @override
  String get textSizeUpper => 'TEXTGRÖSSE';

  @override
  String get fontUpper => 'SCHRIFTART';

  @override
  String get serifBook => 'Serif (Buch)';

  @override
  String get bookMarginsUpper => 'BUCHRÄNDER';

  @override
  String get narrow => 'Schmal';

  @override
  String get connectionFailedCheck => '❌ Verbindung fehlgeschlagen. Prüfe IP-Adresse, Port und Zugangsdaten.';

  @override
  String get connectionOkFolderValid => '✅ Verbunden und Ordner bestätigt!';

  @override
  String folderMissingOnServer(Object path) {
    return '❌ Der Server antwortet, aber der Ordner „$path“ existiert dort nicht.';
  }

  @override
  String get checkingFolder => 'Ordner auf dem Server wird geprüft...';

  @override
  String get cannotReachServerCheck => '❌ Server nicht erreichbar. Prüfe die Einstellungen.';

  @override
  String cannotSaveFolderMissing(Object path) {
    return '❌ Speichern nicht möglich: Der Ordner „$path“ existiert nicht auf dem Server.';
  }

  @override
  String deleteProfileBody(Object name) {
    return 'Möchtest du das Profil „$name“ wirklich löschen?';
  }

  @override
  String serverDeleted(Object serverName) {
    return '🗑️ Server „$serverName“ gelöscht.';
  }

  @override
  String get addLocalServer => 'Lokalen Server hinzufügen';

  @override
  String get editServer => 'Server bearbeiten';

  @override
  String get deleteThisServer => 'Diesen Server löschen';

  @override
  String get serverName => 'Servername';

  @override
  String get serverNameHint => 'Z. B. NAS Wohnzimmer, Büro-PC...';

  @override
  String get enterName => 'Bitte gib einen Namen ein';

  @override
  String get ftpPort21 => 'FTP (Port 21)';

  @override
  String get hostIp => 'Host / IP';

  @override
  String get hostHint => 'z. B. 192.168.1.100 oder nas.local';

  @override
  String get hostRequired => 'IP oder Domain erforderlich';

  @override
  String get rootPath => 'Stammpfad';

  @override
  String get secureConnectionHttps => 'Sichere Verbindung (HTTPS)';

  @override
  String get authenticationOptional => 'Authentifizierung (optional)';

  @override
  String get usernameLabel => 'Benutzername';

  @override
  String get password => 'Passwort';

  @override
  String get allFilesAccessRequired => 'Zum Durchsuchen des Telefons ist Zugriff auf alle Dateien nötig.';

  @override
  String get noCompatibleBookFound => 'Kein kompatibles Buch auf diesem Gerät gefunden.';

  @override
  String alreadyPresentOrSkipped(Object skipped) {
    return ' · $skipped bereits vorhanden oder übersprungen';
  }

  @override
  String booksAddedCount(Object imported, Object skipped) {
    return '$imported Buch/Bücher hinzugefügt$skipped';
  }

  @override
  String importFailed(Object error) {
    return 'Import nicht möglich: $error';
  }

  @override
  String get permissionNotGranted => 'Berechtigung nicht erteilt: Es wurde keine Datei durchsucht.';

  @override
  String get scanPhoneTitle => 'Dieses Gerät nach Büchern durchsuchen?';

  @override
  String get scanPhoneBody => 'ComicStream fragt den Dateizugriff nur an, um Comics, PDFs und EPUBs zu finden. Danach wählst du die zu importierenden Dateien; ohne Bestätigung wird nichts kopiert.';

  @override
  String get notNow => 'Nicht jetzt';

  @override
  String get deviceFiles => 'Dateien auf dem Gerät';

  @override
  String get addComicsFromDevice => 'Comics von diesem Gerät hinzufügen';

  @override
  String get addComicsFromDeviceBody => 'Durchsuchen Sie alle kompatiblen Dateien dieses Geräts und wählen Sie dann die Bücher aus.';

  @override
  String get scanningFiles => 'Dateien werden durchsucht…';

  @override
  String get scanPhone => 'Dieses Gerät durchsuchen';

  @override
  String addedFilesCount(Object length) {
    return 'Hinzugefügte Dateien ($length)';
  }

  @override
  String get noFileAdded => 'Keine Datei hinzugefügt';

  @override
  String get scanPhoneToFindBooks => 'Durchsuchen Sie dieses Gerät, um Ihre Bücher zu finden.';

  @override
  String formatPageProgress(Object formatString, Object currentPage1, Object totalPages) {
    return '$formatString · Seite $currentPage1/$totalPages';
  }

  @override
  String pageXOfY(Object currentPage1, Object totalPages) {
    return 'Seite $currentPage1 von $totalPages';
  }

  @override
  String get removeFromFavorites => 'Aus Favoriten entfernen';

  @override
  String get addToFavorites => 'Zu Favoriten hinzufügen';

  @override
  String get pageGrid => 'Seitenraster';

  @override
  String get comicLtrShort => 'Comic (L->R)';

  @override
  String get mangaRtlShort => 'Manga (R->L)';

  @override
  String get readingDirection => 'Leserichtung';

  @override
  String get comicLtr => 'Comic (L nach R)';

  @override
  String get mangaRtl => 'Manga (R nach L)';

  @override
  String get imageFit => 'Bildanpassung';

  @override
  String get screen => 'Bildschirm';

  @override
  String get background => 'Hintergrund';

  @override
  String get keepScreenAwake => 'Bildschirm eingeschaltet lassen';

  @override
  String selectedCount(Object length) {
    return '$length ausgewählt';
  }

  @override
  String get removeAll => 'Alle entfernen';

  @override
  String get addAll => 'Alle hinzufügen';

  @override
  String get alreadyImported => 'Bereits importiert';

  @override
  String booksFoundCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bücher',
      one: '1 Buch',
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
  String get decimalSeparator => ',';

  @override
  String get convertToCbz => 'In Comic umwandeln (CBZ)';

  @override
  String get markAsUnread => 'Als ungelesen markieren';

  @override
  String get markAsRead => 'Als gelesen markieren';

  @override
  String get deleteFromDevice => 'Vom Gerät löschen';

  @override
  String get finishedUpper => 'BEENDET';

  @override
  String get cbzBenefits => 'Vorteile des CBZ-Formats:';

  @override
  String get cbzBenefit1 => '• Viel schnellere und flüssigere Darstellung';

  @override
  String get cbzBenefit2 => '• Manga-Modus (rechts nach links) verfügbar';

  @override
  String get cbzBenefit3 => '• Flüssiger Webtoon-Modus (fortlaufendes Scrollen)';

  @override
  String get cbzBenefit4 => '• Weniger Speicher- und Akkuverbrauch';

  @override
  String get converting => 'Umwandlung läuft...';

  @override
  String get conversionSucceeded => 'Umwandlung erfolgreich!';

  @override
  String get conversionSucceededBody => 'Dein Comic ist im hochauflösenden CBZ-Format verfügbar.';

  @override
  String get readAsCbz => 'Im Comic-Modus lesen (CBZ)';

  @override
  String get pleaseWait => 'Bitte warten...';

  @override
  String get downloads => 'Downloads';

  @override
  String get noDownloadInProgress => 'Keine laufenden Downloads';

  @override
  String get noDownloadInProgressBody => 'Dateien, die du von deinem lokalen Server herunterlädst, erscheinen hier mit ihrem Fortschritt.';

  @override
  String inProgressCount(Object length) {
    return 'Laufend ($length)';
  }

  @override
  String historyCount(Object length) {
    return 'Verlauf ($length)';
  }

  @override
  String doneWithSize(Object formatBytes) {
    return 'Fertig • $formatBytes';
  }

  @override
  String get deleteFromStorage => 'Aus dem Speicher löschen';

  @override
  String failedWithReason(Object reason) {
    return 'Fehlgeschlagen: $reason';
  }

  @override
  String weeksAgo(Object weeks) {
    return 'vor $weeks Wo.';
  }

  @override
  String daysAgo(Object inDays) {
    return 'vor $inDays Tagen';
  }

  @override
  String hoursAgo(Object inHours) {
    return 'vor $inHours Std.';
  }

  @override
  String minutesAgo(Object inMinutes) {
    return 'vor $inMinutes Min.';
  }

  @override
  String get justNow => 'Gerade eben';

  @override
  String pdfNotFound(Object pdfFilePath) {
    return 'PDF-Datei nicht gefunden: $pdfFilePath';
  }

  @override
  String get pdfHasNoPage => 'Die PDF-Datei enthält keine Seite.';

  @override
  String conversionInit(Object totalPages) {
    return 'Umwandlung wird gestartet ($totalPages Seiten)...';
  }

  @override
  String renderingPagesRange(Object i1, Object currentBatchEnd, Object totalPages) {
    return 'HD-Darstellung der Seiten $i1 bis $currentBatchEnd / $totalPages...';
  }

  @override
  String renderingPage(Object i1, Object totalPages) {
    return 'HD-Darstellung von Seite $i1 / $totalPages...';
  }

  @override
  String get assemblingCbz => 'CBZ-Archiv wird erstellt...';

  @override
  String get noPageGenerated => 'Aus dem PDF konnte keine Seite erzeugt werden.';

  @override
  String get cbzEncodingFailed => 'Kodierung des CBZ-Archivs fehlgeschlagen.';

  @override
  String get finalizingCover => 'Abschluss und Extraktion des Covers...';

  @override
  String get conversionDone => 'Umwandlung erfolgreich abgeschlossen!';

  @override
  String get cbzNotFound => 'CBZ-Datei auf dem Gerät nicht gefunden.';

  @override
  String get noValidImageInCbz => 'In diesem CBZ-Archiv wurde kein gültiges Bild gefunden.';

  @override
  String cbzReadError(Object sizeMb, Object e) {
    return 'Lesefehler ($sizeMb MB): $e\n\nDie Datei ist möglicherweise beschädigt oder der Download unvollständig.';
  }

  @override
  String pagesCount(Object length) {
    return 'Seiten ($length)';
  }

  @override
  String get loadingVolume => 'Band wird geladen...';

  @override
  String get volumeFinished => 'Band beendet! 🎉';

  @override
  String nextVolumeWithTitle(Object title) {
    return 'Zum nächsten Band ➔\n$title';
  }

  @override
  String bookSyncUnavailable(Object error) {
    return 'Synchronisierung für dieses Buch nicht verfügbar. Lokaler Lesestand bleibt erhalten: $error';
  }

  @override
  String get progressFoundElsewhere => 'Fortschritt auf einem anderen Gerät gefunden';

  @override
  String otherPositionOnDevice(Object remoteDeviceName) {
    return '„$remoteDeviceName“ hat eine andere Position für dieses Buch.';
  }

  @override
  String get thisDevice => 'Dieses Gerät';

  @override
  String get keepHere => 'Hier behalten';

  @override
  String continueFromDevice(Object remoteDeviceName) {
    return 'Weiter ab $remoteDeviceName';
  }

  @override
  String get downloadFailed => 'Download fehlgeschlagen';

  @override
  String get convertingHdCbz => 'HD-Umwandlung in CBZ (Comic-Modus)...';

  @override
  String get downloadingYourComic => 'Dein Comic wird heruntergeladen...';

  @override
  String get networkErrorOccurred => 'Ein Netzwerkfehler ist aufgetreten.';

  @override
  String get convertingHdInProgress => 'HD-Umwandlung läuft...';

  @override
  String get deleteFromDeviceTitle => 'Vom Gerät löschen?';

  @override
  String deleteDownloadedFileBody(Object name) {
    return 'Möchtest du die lokal heruntergeladene Datei von „$name“ löschen, um Speicherplatz freizugeben?\n\nDie Datei bleibt auf deinem Server verfügbar und herunterladbar.';
  }

  @override
  String deletedFromDevice(Object name) {
    return '„$name“ wurde von deinem Gerät gelöscht.';
  }

  @override
  String get deleteLocalCopy => 'Lokale Kopie löschen';

  @override
  String get downloadForOffline => 'Für Offline-Lesen herunterladen';

  @override
  String get updateAvailable => 'Update verfügbar!';

  @override
  String get whatsNew => 'Neuerungen:';

  @override
  String get defaultReleaseNotes => 'Leistungsverbesserungen und Fehlerbehebungen.';

  @override
  String get downloadApk => 'APK herunterladen';

  @override
  String get almostDone => 'Fast fertig...';

  @override
  String secondsLeft(Object seconds) {
    return '~ noch $seconds s';
  }

  @override
  String itemsCount(Object itemCount) {
    return '$itemCount Elemente';
  }

  @override
  String readOfTotal(Object completedBooks, Object totalBooks) {
    return '$completedBooks/$totalBooks gelesen';
  }

  @override
  String get emptyServerResponse => 'Leere Antwort vom Server';

  @override
  String chapterN(Object length1) {
    return 'Kapitel $length1';
  }

  @override
  String chapterNIdx(Object idx1) {
    return 'Kapitel $idx1';
  }

  @override
  String get pdfNotFoundOnDevice => 'PDF-Datei auf dem Gerät nicht gefunden.';

  @override
  String get convertToCbzComicMode => 'In CBZ umwandeln (Comic-Modus)';

  @override
  String get pressAgainToExit => 'Erneut drücken, um ComicStream zu beenden';

  @override
  String get downloadsTabShort => 'Offline';

  @override
  String get settingsTab => 'Optionen';

  @override
  String get invalidJsonFormat => 'Ungültiges JSON-Format';

  @override
  String cannotLoadFolder(Object e) {
    return 'Ordner kann nicht geladen werden: $e';
  }

  @override
  String get newUpdateAvailable => 'Ein neues Update ist verfügbar.';

  @override
  String get unknownEncryptionVersion => 'Unbekannte Verschlüsselungsversion';

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
    return '~ $minutes Min. $seconds s';
  }

  @override
  String volumeCountPlural(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bände',
      one: '1 Band',
    );
    return '$_temp0';
  }

  @override
  String chapterSlashPercent(Object current, Object total, Object percent) {
    return 'Kapitel $current/$total · $percent %';
  }

  @override
  String labelLocationDate(Object label, Object location, Object date, Object time) {
    return '$label: $location\n$date um $time';
  }

  @override
  String get cancel => 'Abbrechen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get continueLabel => 'Weiter';

  @override
  String get save => 'Speichern';

  @override
  String get view => 'Ansehen';

  @override
  String get synchronize => 'Synchronisieren';

  @override
  String get back => 'Zurück';

  @override
  String get none => 'Keine';

  @override
  String get all => 'Alle';

  @override
  String get importAction => 'Importieren';

  @override
  String get everyone => 'Alle';

  @override
  String get clean => 'Aufräumen';

  @override
  String get read => 'Lesen';

  @override
  String get dark => 'Dunkel';

  @override
  String get mint => 'Minze';

  @override
  String get light => 'Hell';

  @override
  String get standard => 'Standard';

  @override
  String get large => 'Breit';

  @override
  String get libraryTab => 'Bücher';

  @override
  String get serverTab => 'Server';

  @override
  String get filesTab => 'Dateien';

  @override
  String get delete => 'Löschen';

  @override
  String get resume => 'Fortsetzen';

  @override
  String get progress => 'Fortschritt';

  @override
  String get favorites => 'Favoriten';

  @override
  String get close => 'Schließen';

  @override
  String get options => 'Optionen';

  @override
  String get search => 'Suchen';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get root => 'Stamm';

  @override
  String get empty => 'Leeren';

  @override
  String get font => 'Schrift';

  @override
  String get lineSpacing => 'Zeilenabstand';

  @override
  String get compact => 'Kompakt';

  @override
  String get normal => 'Normal';

  @override
  String get relaxed => 'Weit';

  @override
  String get margin => 'Rand';

  @override
  String get narrowShort => 'Schmal';

  @override
  String get yesterday => 'Gestern';

  @override
  String get today => 'Heute';

  @override
  String get folder => 'Ordner';

  @override
  String get convert => 'Umwandeln';

  @override
  String get width => 'Breite';

  @override
  String get height => 'Höhe';

  @override
  String get black => 'Schwarz';

  @override
  String get grey => 'Grau';

  @override
  String get white => 'Weiß';

  @override
  String get downloaded => 'Heruntergeladen';

  @override
  String get serverDefaultName => 'Server';

  @override
  String get test => 'Testen';

  @override
  String get type => 'Typ';

  @override
  String get port => 'Port';

  @override
  String get path => 'Pfad';

  @override
  String get credentials => 'Zugangsdaten';

  @override
  String get ignore => 'Ignorieren';

  @override
  String get noneLower => 'keine';

  @override
  String get serverUpper => 'SERVER';

  @override
  String get bookUpper => 'BUCH';

  @override
  String get resumeUpper => 'FORTSETZEN';

  @override
  String get currentUpper => 'AKTUELL';

  @override
  String get lineSpacingUpper => 'ZEILENABSTAND';

  @override
  String get alignmentUpper => 'AUSRICHTUNG';

  @override
  String get comicsFilter => 'Comics';

  @override
  String get navLibrary => 'Bibliothek';

  @override
  String get navServers => 'Server';

  @override
  String get computerFiles => 'Dateien auf dem Computer';

  @override
  String get addComicsFromComputerBody => 'Wähle Comics (CBZ, CBR, PDF, EPUB) oder einen ganzen Ordner zum Durchsuchen. Ein Doppelklick im Explorer öffnet sie ebenfalls direkt.';

  @override
  String get openFiles => 'Dateien öffnen…';

  @override
  String get scanFolder => 'Ordner durchsuchen…';

  @override
  String get columnTitle => 'Titel';

  @override
  String get columnFormat => 'Format';

  @override
  String get columnSize => 'Größe';

  @override
  String get columnAdded => 'Hinzugefügt';

  @override
  String get doublePageTitle => 'Doppelseite auf großen Bildschirmen';

  @override
  String get doublePageBody => 'Zwei Seiten nebeneinander, wenn das Fenster breit und im Querformat ist';

  @override
  String get onePage => '1 Seite';

  @override
  String get twoPages => '2 Seiten';

  @override
  String get togglePagesPerView => '1 oder 2 Seiten anzeigen (D)';

  @override
  String get selectAll => 'Alle auswählen';

  @override
  String get clearSelection => 'Auswahl aufheben';

  @override
  String get moveToSeries => 'In Serie verschieben';

  @override
  String get seriesNameLabel => 'Name der Serie';

  @override
  String get automaticSeries => 'Automatische Serie';

  @override
  String get move => 'Verschieben';

  @override
  String deleteSelectedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bücher löschen?',
      one: '1 Buch löschen?',
    );
    return '$_temp0';
  }

  @override
  String get deleteSelectedBody => 'Die Dateien werden von diesem Gerät gelöscht. Dateien auf deinen Servern bleiben erhalten.';

  @override
  String librarySelectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ausgewählt',
      one: '1 ausgewählt',
    );
    return '$_temp0';
  }

  @override
  String get languageTitle => 'Sprache';

  @override
  String get systemLanguage => 'Systemsprache';

  @override
  String get googleBrowserDone => 'Anmeldung erfolgreich. Sie können diesen Tab schließen und zu ComicStream zurückkehren.';

  @override
  String get googleBrowserFailed => 'Die Google-Anmeldung ist fehlgeschlagen. Schließen Sie diesen Tab und versuchen Sie es in ComicStream erneut.';

  @override
  String get readAgain => 'Erneut lesen';

  @override
  String resumeVolumeNumber(int number) {
    return 'Band $number fortsetzen';
  }

  @override
  String readVolumeNumber(int number) {
    return 'Band $number lesen';
  }

  @override
  String get startReading => 'Lesen beginnen';

  @override
  String get seeVolumes => 'Bände ansehen';

  @override
  String get openSeriesSheet => 'Serienseite';

  @override
  String get consoleEmpty => 'Keine Serie in diesem Filter';

  @override
  String get consoleHintMove => 'Bewegen';

  @override
  String get consoleHintOpen => 'Öffnen';

  @override
  String get consoleHintBack => 'Zurück';

  @override
  String get consoleHintFilter => 'Filter';

  @override
  String get consoleView => 'Konsole';

  @override
  String get consoleQueue => 'Warteschlange';

  @override
  String get consoleQueueHint => 'in Startreihenfolge';

  @override
  String get consoleReady => 'Bereit zum Lesen';

  @override
  String get consoleFailed => 'Fehler · erneut';

  @override
  String get consoleCancelled => 'Abgebrochen · neu starten';

  @override
  String get consoleChooseServer => 'Wählen Sie einen Server, um seine Ordner zu durchsuchen.';

  @override
  String consoleItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Elemente',
      one: '1 Element',
    );
    return '$_temp0';
  }

  @override
  String consoleDownloadMissing(int count) {
    return 'Die $count fehlenden laden';
  }

  @override
  String get consoleHintOpenDownload => 'Öffnen / laden';

  @override
  String get consoleHintReadRetry => 'Lesen / erneut';

  @override
  String get consoleAlreadyQueued => 'Bereits in der Warteschlange';

  @override
  String get consoleNothingYet => 'Noch keine Downloads';

  @override
  String get consoleSwitchPage => 'Nächste Seite';

  @override
  String get pause => 'Pause';

  @override
  String get pausedStatus => 'Pausiert';

  @override
  String get consoleHintPause => 'Pause / fortsetzen';

  @override
  String get keySpace => 'Leertaste';

  @override
  String get downloadUpdate => 'Update herunterladen';

  @override
  String scanFoundCount(int count) {
    return 'Suche… $count gefunden';
  }

  @override
  String importProgress(int percent) {
    return 'Import… $percent %';
  }
}
