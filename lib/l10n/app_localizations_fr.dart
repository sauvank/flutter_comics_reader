import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get resetVaultTitle => 'Réinitialiser le coffre ?';

  @override
  String get resetVaultBody => 'Si vous avez perdu votre phrase de récupération, la réinitialisation créera un nouveau coffre vierge. Les données protégées de vos autres appareils devront être synchronisées à nouveau.';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get confirmSecretPhrase => 'Confirmer la phrase secrète';

  @override
  String get secretPhraseWrittenDownBody => 'Avez-vous bien noté votre phrase secrète dans un endroit sûr ?\n\nElle est indispensable pour restaurer vos données ou synchroniser un nouvel appareil. ComicStream ne la conserve pas et ne pourra jamais la récupérer pour vous.';

  @override
  String get yourSecretPhrase => 'Votre phrase secrète :';

  @override
  String get phraseNotedContinue => 'J’ai bien noté, continuer';

  @override
  String get changeSecretPhrase => 'Modifier la phrase secrète';

  @override
  String get changeSecretPhraseBody => 'Définissez une nouvelle phrase secrète (16 caractères minimum) pour sécuriser votre synchronisation.';

  @override
  String get newSecretPhrase => 'Nouvelle phrase secrète';

  @override
  String get min16Characters => '16 caractères minimum';

  @override
  String get showPhrase => 'Afficher la phrase';

  @override
  String get hidePhrase => 'Masquer la phrase';

  @override
  String get confirmNewPhrase => 'Confirmer la nouvelle phrase';

  @override
  String get phraseTooShort => 'La phrase doit comporter au moins 16 caractères.';

  @override
  String get phrasesDoNotMatch => 'Les deux phrases ne correspondent pas.';

  @override
  String get confirmChangeTitle => 'Confirmer le changement ?';

  @override
  String get confirmChangeBody => 'Votre coffre va être mis à jour avec cette nouvelle phrase secrète.\nAssurez-vous de l’avoir bien notée :';

  @override
  String get confirmAndSave => 'Confirmer et enregistrer';

  @override
  String get secretPhraseUpdated => 'Phrase secrète mise à jour avec succès.';

  @override
  String get operationDone => 'Opération terminée.';

  @override
  String cannotContinue(Object error) {
    return 'Impossible de continuer : $error';
  }

  @override
  String dateAtTime(Object date, Object time) {
    return '$date à $time';
  }

  @override
  String get syncConflict => 'Conflit de synchronisation';

  @override
  String syncConflictBody(Object label) {
    return 'Deux versions de « $label » ont été modifiées.';
  }

  @override
  String thisDeviceValue(Object formatConflictDate) {
    return 'Cet appareil : $formatConflictDate';
  }

  @override
  String syncServerValue(Object formatConflictDate) {
    return 'Serveur de synchronisation : $formatConflictDate';
  }

  @override
  String thisDeviceSummary(Object localSummary) {
    return 'Cet appareil : $localSummary';
  }

  @override
  String serverSummary(Object remoteSummary) {
    return 'Serveur : $remoteSummary';
  }

  @override
  String get chooseReferenceVersion => 'Choisissez la version de référence. Elle sera ensuite synchronisée sur vos autres appareils.';

  @override
  String get fetchFromServer => 'Récupérer du serveur';

  @override
  String get sendToServer => 'Envoyer vers le serveur';

  @override
  String get later => 'Plus tard';

  @override
  String get thisDeviceName => 'Nom de cet appareil';

  @override
  String get deviceNameHint => 'Ex. Tablette ou Téléphone';

  @override
  String get deviceNameSavedOnServer => 'Nom de l’appareil enregistré sur le serveur.';

  @override
  String get deviceNameSavedLocally => 'Nom enregistré sur cet appareil. Il sera envoyé à la prochaine synchronisation.';

  @override
  String cannotPrepareSync(Object error) {
    return 'Impossible de préparer la synchronisation : $error';
  }

  @override
  String get whichBackupToUse => 'Quelle sauvegarde utiliser ?';

  @override
  String get whichBackupBody => 'Le choix devient la référence partagée. Les autres appareils la recevront à leur prochaine synchronisation.';

  @override
  String get notBackedUpYet => 'Pas encore sauvegardé';

  @override
  String backedUpAt(Object formatConflictDate) {
    return 'Sauvegardé $formatConflictDate';
  }

  @override
  String get accountAndSync => 'Compte et synchronisation';

  @override
  String get syncUnavailableNoFirebase => 'La synchronisation sera disponible après la configuration du projet Firebase. Le lecteur et vos données locales continuent de fonctionner normalement.';

  @override
  String get accountConnected => 'Compte connecté';

  @override
  String get vaultUnlockedE2e => 'Coffre déverrouillé. Vos données sont chiffrées de bout en bout.';

  @override
  String get vaultLockedOrNew => 'Coffre verrouillé ou non initialisé.';

  @override
  String get unlockVault => 'Déverrouiller le coffre';

  @override
  String get initEncryptedVault => 'Initialiser votre coffre chiffré';

  @override
  String get unlockVaultBody => 'Un coffre chiffré est associé à ce compte. Saisissez votre phrase de récupération pour déverrouiller la synchronisation sur cet appareil.';

  @override
  String get initVaultBody => 'Pour protéger vos mots de passe de serveurs et vos données, choisissez une phrase secrète (16 caractères minimum). Elle est indispensable pour restaurer vos données sur un nouvel appareil.';

  @override
  String get recoveryPhrase => 'Phrase de récupération';

  @override
  String get secretPhraseMin16 => 'Phrase secrète (16 caractères minimum)';

  @override
  String get enterRecoveryPhrase => 'Veuillez saisir votre phrase de récupération.';

  @override
  String get secretPhraseTooShort => 'La phrase secrète doit comporter au moins 16 caractères.';

  @override
  String get secretPhrasesDoNotMatch => 'Les phrases secrètes ne correspondent pas.';

  @override
  String get unlockSync => 'Déverrouiller la synchronisation';

  @override
  String get createAndEnableVault => 'Créer et activer le coffre';

  @override
  String get forgotPhraseReset => 'Phrase oubliée ? Réinitialiser le coffre';

  @override
  String get vaultUnlocked => 'Coffre déverrouillé';

  @override
  String get syncActiveE2e => 'La synchronisation est active et protégée par chiffrement de bout en bout.';

  @override
  String get syncing => 'Synchronisation…';

  @override
  String get changePhrase => 'Modifier la phrase';

  @override
  String get shownWhenChoosingBackup => 'Affiché lors du choix d’une sauvegarde';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get signIn => 'Se connecter';

  @override
  String get passwordMin12 => 'Mot de passe (12 caractères minimum)';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get createTheAccount => 'Créer le compte';

  @override
  String get alreadyHaveAccount => 'J’ai déjà un compte';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get recoveryPhraseRequiredNote => 'La phrase de récupération est indispensable pour restaurer les mots de passe de serveurs sur un nouvel appareil. Elle n’est jamais sauvegardée par ComicStream.';

  @override
  String androidCertNotAllowed(Object hashes) {
    return 'Certificat Android non autorisé : $hashes';
  }

  @override
  String pendingConflicts(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifications attendent votre choix.',
      one: '1 modification attend votre choix.',
    );
    return '$_temp0';
  }

  @override
  String upToDate(Object fullVersion) {
    return 'ComicStream est à jour ($fullVersion) !';
  }

  @override
  String get updateCheckError => 'Erreur lors de la vérification de la mise à jour';

  @override
  String get clearCacheTitle => 'Vider le cache ?';

  @override
  String get clearCacheBody => 'Les couvertures seront rechargées automatiquement.';

  @override
  String get coverCacheCleared => 'Cache des couvertures vidé avec succès !';

  @override
  String get deleteAllTitle => 'Tout supprimer ?';

  @override
  String get deleteAllBody => 'Cette action supprimera toutes les BDs et mangas téléchargés en local pour libérer de l\'espace. Vos paramètres de serveurs seront conservés.';

  @override
  String get allLocalFilesDeleted => 'Tous les fichiers locaux ont été supprimés.';

  @override
  String get eraseAll => 'Tout effacer';

  @override
  String get commandCopied => 'Commande copiée !';

  @override
  String get localServerGuide => 'Guide Serveur Local';

  @override
  String get guideOption1 => 'Option 1 : Serveur WebDAV Docker (Recommandé)';

  @override
  String get guideOption1Body => 'Lancez un serveur WebDAV léger avec Docker en 1 ligne en pointant vers votre dossier de BDs :';

  @override
  String get guideOption2 => 'Option 2 : Script Python prêt à l\'emploi';

  @override
  String get guideOption2Body => 'Un serveur Python dédié est fourni dans le dossier `server_example/comic_server.py`. Pour le lancer :';

  @override
  String get guideOption3 => 'Option 3 : NAS Synology / TrueNAS / Nextcloud';

  @override
  String get guideOption3Body => 'Activez simplement le service WebDAV dans le panneau d\'administration de votre NAS (port 5005 par défaut sur Synology) et entrez vos identifiants dans l\'application.';

  @override
  String get settings => 'Paramètres';

  @override
  String get accountAndSyncShort => 'Compte & synchronisation';

  @override
  String get accountAndSyncSubtitle => 'Serveurs, progression et réglages chiffrés';

  @override
  String get appearanceTheme => 'Apparence & Thème';

  @override
  String get appTheme => 'Thème de l\'application';

  @override
  String get readerPreferences => 'Préférences du lecteur';

  @override
  String get defaultReadingMode => 'Mode de lecture par défaut';

  @override
  String get readingModeComic => 'BD / Franco-Belge (Gauche à Droite)';

  @override
  String get readingModeManga => 'Manga (Droite à Gauche)';

  @override
  String get readingModeWebtoon => 'Webtoon (Défilement vertical)';

  @override
  String get keepScreenOn => 'Garder l\'écran actif en lecture';

  @override
  String get showPageNumber => 'Afficher le numéro de page';

  @override
  String get autoConvertPdf => 'Convertir automatiquement les PDF en CBZ';

  @override
  String get autoConvertPdfBody => 'Transforme chaque PDF téléchargé en archive BD ultra-fluide pour tablette.';

  @override
  String get comicRenderQuality => 'Qualité de rendu BD';

  @override
  String get qualityAutoLong => 'Automatique (Détecte l\'écran + 35% de netteté)';

  @override
  String get qualitySuperLong => 'Super-échantillonné (2600px - Zoom net)';

  @override
  String get qualityUltraLong => 'Ultra HD (3500px - Définition max)';

  @override
  String get qualityStandardLong => 'Standard 1:1 (1900px - Rapide)';

  @override
  String get qualityAuto => 'Auto (Écran + 35%)';

  @override
  String get qualityHigh => 'Élevée (2600px)';

  @override
  String get qualityStandard => 'Standard 1:1';

  @override
  String get ebooksEpub => 'E-Books & EPUB';

  @override
  String get fontSize => 'Taille de la police';

  @override
  String get justifiedText => 'Texte justifié';

  @override
  String get storageCache => 'Stockage & Cache';

  @override
  String get spaceUsedByBooks => 'Espace occupé par les livres :';

  @override
  String booksDownloadedCount(Object length) {
    return '$length livre(s) téléchargé(s)';
  }

  @override
  String get clearCache => 'Vider cache';

  @override
  String get updates => 'Mises à jour';

  @override
  String get checkForUpdate => 'Rechercher une mise à jour';

  @override
  String installedVersion(Object fullVersion) {
    return 'Version installée : $fullVersion';
  }

  @override
  String get check => 'Vérifier';

  @override
  String get seeStoreListing => 'Voir la fiche officielle de ComicStream';

  @override
  String get helpSetup => 'Aide & Configuration';

  @override
  String get howToSetupLocalServer => 'Comment configurer mon serveur local ?';

  @override
  String get helpSetupSubtitle => 'Docker, Python, NAS Synology, TrueNAS...';

  @override
  String get appTagline => 'Lecteur de BD, Comics & Mangas Cloud';

  @override
  String get deleteBookTitle => 'Supprimer ce livre ?';

  @override
  String deleteBookBody(Object title) {
    return 'Voulez-vous supprimer \"$title\" de votre stockage local ?';
  }

  @override
  String resumeAtChapter(Object title, Object currentPage1) {
    return '« $title » était déjà commencé. Reprendre au chapitre $currentPage1 ?';
  }

  @override
  String resumeAtPage(Object title, Object currentPage1) {
    return '« $title » était déjà commencé. Reprendre à la page $currentPage1 ?';
  }

  @override
  String get myLibrary => 'Ma Bibliothèque';

  @override
  String comicsCount(Object length) {
    return '$length BD';
  }

  @override
  String get syncInProgress => 'Synchronisation en cours';

  @override
  String get sortBy => 'Trier par';

  @override
  String get lastRead => 'Dernière lecture';

  @override
  String get titleAz => 'Titre (A-Z)';

  @override
  String get dateAdded => 'Date d\'ajout';

  @override
  String seriesCount(Object length) {
    return 'Séries ($length)';
  }

  @override
  String volumesCount(Object length) {
    return 'Tomes ($length)';
  }

  @override
  String get searchLibraryHint => 'Rechercher une série, un tome, un auteur...';

  @override
  String get recentlyOpened => 'Récemment ouverts';

  @override
  String myCollectionsCount(Object length) {
    return 'Mes Collections & Séries ($length)';
  }

  @override
  String get backToSeries => 'Retour aux séries';

  @override
  String seriesProgress(Object completedBooks, Object totalBooks, Object progressPercent) {
    return '$completedBooks/$totalBooks tomes lus • $progressPercent%';
  }

  @override
  String get checkNewVolumes => 'Vérifier les nouveaux tomes sur le serveur';

  @override
  String get nextVolumeToRead => 'TOME SUIVANT À LIRE';

  @override
  String get nextVolumeOnServer => 'TOME SUIVANT SUR LE SERVEUR';

  @override
  String get download => 'Télécharger';

  @override
  String downloadStarted(Object name) {
    return '📥 Téléchargement lancé : $name';
  }

  @override
  String get readNow => 'Lire direct';

  @override
  String get searchingNextVolumes => 'Recherche des tomes suivants sur le serveur distant...';

  @override
  String downloadedVolumesCount(Object totalBooks) {
    return 'Tomes téléchargés ($totalBooks)';
  }

  @override
  String serverVolumesCount(Object length) {
    return 'Tomes disponibles sur le serveur ($length)';
  }

  @override
  String downloadAllCount(Object length) {
    return 'Tout télécharger ($length)';
  }

  @override
  String volumesQueued(Object length) {
    return '📥 $length tomes ajoutés à la file de téléchargement';
  }

  @override
  String downloadingName(Object name) {
    return '📥 Téléchargement : $name';
  }

  @override
  String get libraryFilters => 'Filtres de la bibliothèque';

  @override
  String allCount(Object length) {
    return 'Tous ($length)';
  }

  @override
  String get inProgress => 'En cours';

  @override
  String get unread => 'Non lus';

  @override
  String get epubNovels => 'EPUB / Romans';

  @override
  String get finished => 'Terminés';

  @override
  String get continueReading => 'CONTINUER LA LECTURE';

  @override
  String get libraryEmpty => 'Votre bibliothèque est vide';

  @override
  String get libraryEmptyBody => 'Ajoutez vos BD depuis un serveur ou les fichiers déjà présents sur cet appareil.';

  @override
  String get exploreServers => 'Explorer mes serveurs';

  @override
  String get importFromPhone => 'Importer depuis cet appareil';

  @override
  String get noSearchResults => 'Aucun résultat pour cette recherche';

  @override
  String get noSearchResultsBody => 'Essayez un autre mot-clé ou réinitialisez les filtres.';

  @override
  String chapterProgressPercent(Object current, Object total, Object percent) {
    return 'Chapitre $current/$total ($percent%)';
  }

  @override
  String pageProgressPercent(Object current, Object total, Object percent) {
    return 'Page $current/$total ($percent%)';
  }

  @override
  String chapterOfTotal(Object current, Object total) {
    return 'Chapitre $current sur $total';
  }

  @override
  String pageOfTotal(Object current, Object total) {
    return 'Page $current sur $total';
  }

  @override
  String get setupServer => 'Configurer un serveur';

  @override
  String connectionSucceeded(Object name) {
    return 'Connexion réussie à $name !';
  }

  @override
  String connectionFailed(Object name) {
    return 'Échec de la connexion à $name';
  }

  @override
  String get deleteServerTitle => 'Supprimer ce serveur ?';

  @override
  String deleteServerBody(Object name) {
    return 'Voulez-vous vraiment supprimer \"$name\" de vos sources distantes ?';
  }

  @override
  String get exportConfiguration => 'Exporter la configuration';

  @override
  String get exportConfigurationBody => 'Voici le fichier de configuration JSON contenant vos profils serveurs :';

  @override
  String get copyJson => 'Copier JSON';

  @override
  String get configurationCopied => '✅ Configuration copiée dans le presse-papiers !';

  @override
  String get importConfiguration => 'Importer une configuration';

  @override
  String get chooseJsonFile => 'Choisir un fichier .json';

  @override
  String fileReadError(Object e) {
    return 'Erreur lors de la lecture du fichier : $e';
  }

  @override
  String get orPasteJson => 'Ou collez le JSON ici :';

  @override
  String serversImported(Object count) {
    return '✅ $count serveur(s) importé(s) avec succès !';
  }

  @override
  String baseLocationSet(Object currentPath) {
    return '✅ Emplacement de base défini sur : $currentPath';
  }

  @override
  String get myServers => 'Mes Serveurs';

  @override
  String get addServer => 'Ajouter un serveur';

  @override
  String get howToSetupServer => 'Comment configurer un serveur';

  @override
  String get exportConfigurations => 'Exporter les configurations';

  @override
  String get testConnection => 'Tester la connexion';

  @override
  String get filterFolderHint => 'Filtrer ce dossier...';

  @override
  String get closeSearch => 'Fermer la recherche';

  @override
  String get folderOptions => 'Options du dossier';

  @override
  String get setFolderAsRoot => 'Définir ce dossier comme racine';

  @override
  String get switchServer => 'Changer de serveur';

  @override
  String get parentFolder => 'Dossier parent';

  @override
  String everythingCount(Object length) {
    return 'Tout ($length)';
  }

  @override
  String get downloadAllTitle => 'Tout télécharger ?';

  @override
  String downloadAllBody(Object length) {
    return '$length tomes vont être téléchargés en arrière-plan.';
  }

  @override
  String volumesQueuedCount(Object length) {
    return '📥 $length tome(s) ajouté(s) à la file de téléchargement';
  }

  @override
  String foldersSeriesCount(Object length) {
    return 'Dossiers & Séries ($length)';
  }

  @override
  String booksComicsCount(Object length) {
    return 'Livres & BD ($length)';
  }

  @override
  String downloadingNamePlain(Object name) {
    return 'Téléchargement : $name';
  }

  @override
  String get folderEmpty => 'Ce dossier est vide';

  @override
  String get folderEmptyBody => 'Aucun livre ou sous-dossier trouvé dans cet emplacement.';

  @override
  String get cannotConnectServer => 'Connexion impossible au serveur';

  @override
  String checkServerReachable(Object baseUrl) {
    return 'Vérifiez que le serveur est accessible sur $baseUrl.';
  }

  @override
  String get editSettings => 'Modifier les paramètres';

  @override
  String get retry => 'Réessayer';

  @override
  String get googleTokenMissing => 'Jeton d’authentification Google introuvable.';

  @override
  String get googleSignInUnavailable => 'La connexion Google n’est pas disponible sur cet appareil.';

  @override
  String get recoveryPhraseTooShort => 'La phrase de récupération doit comporter au moins 16 caractères.';

  @override
  String get signInRequired => 'Connexion requise';

  @override
  String get noSyncVaultFound => 'Aucun coffre de synchronisation trouvé.';

  @override
  String get vaultMustBeUnlocked => 'Le coffre doit être déverrouillé pour modifier la phrase secrète.';

  @override
  String get recoveryPhraseRequiredHere => 'Phrase de récupération requise sur cet appareil.';

  @override
  String get serverConfigurations => 'Configurations de serveurs';

  @override
  String get readingSettings => 'Paramètres de lecture';

  @override
  String get deviceNameLength => 'Le nom doit contenir entre 1 et 40 caractères.';

  @override
  String deviceDefaultName(Object substring) {
    return 'Appareil $substring';
  }

  @override
  String get otherDevice => 'Autre appareil';

  @override
  String get remoteProgressGone => 'Cette progression distante n’existe plus.';

  @override
  String thisDeviceNamed(Object currentName) {
    return 'Cet appareil — $currentName';
  }

  @override
  String get deviceBackupNotFound => 'La sauvegarde de cet appareil est introuvable.';

  @override
  String get googleDataNotFound => 'Les données Google à résoudre sont introuvables.';

  @override
  String get localProgressGone => 'La progression locale correspondante n’existe plus.';

  @override
  String get unknownSyncDocument => 'Document de synchronisation inconnu';

  @override
  String get readingSettingsShort => 'Réglages de lecture';

  @override
  String get yes => 'oui';

  @override
  String get no => 'non';

  @override
  String chapterSlash(Object current, Object total) {
    return 'Chapitre $current/$total';
  }

  @override
  String pageSlash(Object current, Object total) {
    return 'Page $current/$total';
  }

  @override
  String progressSummary(Object location, Object favorite, Object bookmarks) {
    return '$location · Favori : $favorite · $bookmarks';
  }

  @override
  String bookmarksCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count marque-pages',
      one: '1 marque-page',
      zero: '0 marque-page',
    );
    return '$_temp0';
  }

  @override
  String serverProfilesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count profils de serveur',
      one: '1 profil de serveur',
      zero: '0 profil de serveur',
    );
    return '$_temp0';
  }

  @override
  String ftpInvalidServer(Object banner) {
    return 'Serveur FTP invalide: $banner';
  }

  @override
  String ftpCredentialsRefused(Object passResp) {
    return 'Identifiants FTP refusés: $passResp';
  }

  @override
  String ftpUsernameRefused(Object userResp) {
    return 'Identifiant FTP refusé: $userResp';
  }

  @override
  String ftpPassiveFailed(Object pasvResp) {
    return 'Mode passif FTP échoué: $pasvResp';
  }

  @override
  String ftpDownloadFailed(Object retrResp) {
    return 'Impossible de télécharger le fichier FTP: $retrResp';
  }

  @override
  String get ftpIdleTimeout => 'Délai d\'inactivité FTP dépassé';

  @override
  String ftpPasvUnrecognized(Object response) {
    return 'Réponse PASV non reconnue: $response';
  }

  @override
  String get guideHeroTitle => 'Lisez les BD de votre ordinateur ou NAS';

  @override
  String get guideHeroBody => 'Un serveur rend votre collection accessible depuis l’app, sans tout copier. Comptez environ 2 minutes.';

  @override
  String get howItWorks => 'Comment faire';

  @override
  String get guideStep1Title => 'Partagez votre dossier de BD';

  @override
  String get guideStep1Body => 'Sur votre NAS ou ordinateur, activez un partage WebDAV, FTP ou HTTP qui pointe vers le dossier contenant vos fichiers CBZ, CBR, PDF ou EPUB. Les exemples ci-dessous détaillent chaque cas.';

  @override
  String get guideStep2Title => 'Notez son adresse';

  @override
  String get guideStep2Body => 'Repérez l’adresse IP locale de la machine (ex. 192.168.1.100) et le port du partage. Cet appareil doit être connecté au même réseau.';

  @override
  String get guideStep3Title => 'Remplissez le formulaire';

  @override
  String get guideStep3Body => 'Touchez « Ajouter un serveur », choisissez le type, puis saisissez l’hôte, le port, le chemin du dossier et, si besoin, l’identifiant et le mot de passe.';

  @override
  String get guideStep4Title => 'Testez puis enregistrez';

  @override
  String get guideStep4Body => '« Tester » vérifie la connexion. Une fois validé, « Enregistrer » ouvre directement le serveur pour parcourir et télécharger vos livres.';

  @override
  String get configurationExamples => 'Exemples de configuration';

  @override
  String get webdavSubtitle => 'Recommandé · NAS Synology, QNAP, Nextcloud';

  @override
  String get host => 'Hôte';

  @override
  String get webdavPorts => '5005 (Synology), 80 ou 443';

  @override
  String get webdavCredentials => 'ceux de votre compte NAS';

  @override
  String get webdavTip => 'Sur Synology : installez « WebDAV Server » depuis le Centre de paquets et activez HTTP ou HTTPS.';

  @override
  String get httpSubtitle => 'Le plus simple depuis un ordinateur';

  @override
  String get computerIp => 'IP de l’ordinateur';

  @override
  String get httpTip => 'Dans le dossier de vos BD, lancez « python3 -m http.server 8080 », ou le script server_example/comic_server.py fourni avec ComicStream.';

  @override
  String get ftpSubtitle => 'Box internet, anciens NAS';

  @override
  String get ftpCredentials => 'compte FTP de la box ou du NAS';

  @override
  String get ftpTip => 'Le FTP n’est pas chiffré : réservez-le à votre réseau domestique.';

  @override
  String get cannotConnectTitle => 'Ça ne se connecte pas ?';

  @override
  String get tipSameWifi => 'Vérifiez que cet appareil et le serveur sont sur le même réseau.';

  @override
  String get tipUseIp => 'Essayez l’adresse IP plutôt qu’un nom (nas.local).';

  @override
  String get tipFirewall => 'Vérifiez que le pare-feu de l’ordinateur autorise le port choisi.';

  @override
  String get tipVpn => 'Hors de chez vous, passez par un VPN (WireGuard, Tailscale…) plutôt que d’exposer le serveur sur Internet.';

  @override
  String get importExistingConfiguration => 'Importer une configuration existante';

  @override
  String get waiting => 'En attente...';

  @override
  String get downloadingEllipsis => 'Téléchargement...';

  @override
  String get cancelled => 'Annulé';

  @override
  String get extractingFinalizing => 'Extraction et finalisation...';

  @override
  String get convertingHd => 'Conversion BD HD en cours...';

  @override
  String secondsRemaining(Object approxSec) {
    return ' ~ ${approxSec}s restantes';
  }

  @override
  String convertingHdProgress(Object currentPage, Object totalPages, Object etaText) {
    return 'Conversion HD ($currentPage/$totalPages pages)$etaText';
  }

  @override
  String get finishedStatus => 'Terminé';

  @override
  String get failed => 'Échec';

  @override
  String get networkTimeout => 'Délai d\'attente dépassé (timeout réseau)';

  @override
  String get invalidCertificate => 'Certificat de sécurité invalide (serveur auto-signé ?)';

  @override
  String get fileNotFound404 => 'Fichier introuvable sur le serveur (404)';

  @override
  String get accessDenied => 'Accès refusé (identifiants incorrects)';

  @override
  String get cannotReachServerLost => 'Impossible de joindre le serveur (connexion perdue)';

  @override
  String get downloadCancelled => 'Téléchargement annulé';

  @override
  String get networkInterrupted => 'Connexion réseau interrompue';

  @override
  String get notEnoughStorage => 'Espace de stockage insuffisant sur l\'appareil';

  @override
  String get networkError => 'Erreur de connexion réseau';

  @override
  String get localFileAccessError => 'Erreur d\'accès au fichier local';

  @override
  String get serverError => 'Erreur serveur';

  @override
  String serverErrorCode(Object code) {
    return 'Erreur serveur ($code)';
  }

  @override
  String get endOfBookReached => 'Vous êtes arrivé à la fin du livre !';

  @override
  String get loadingBook => 'Chargement du livre...';

  @override
  String get cannotLoadBook => 'Impossible de charger ce livre';

  @override
  String get fileMaybeCorrupted => 'Le format du fichier est peut-être corrompu ou non supporté.';

  @override
  String get backToLibrary => 'Retour à la bibliothèque';

  @override
  String epubProgressShort(Object value, Object currentChapterIndex1, Object length) {
    return '$value% • Chap. $currentChapterIndex1/$length';
  }

  @override
  String get tableOfContents => 'Table des matières';

  @override
  String get customizeReading => 'Personnaliser la lecture';

  @override
  String chapterXOfY(Object currentChapterIndex1, Object length) {
    return 'Chapitre $currentChapterIndex1 / $length';
  }

  @override
  String endOfChapter(Object currentChapterIndex1) {
    return 'Fin du Chapitre $currentChapterIndex1';
  }

  @override
  String get nextChapterUpper => 'CHAPITRE SUIVANT';

  @override
  String get bookFinished => 'Vous avez terminé ce livre !';

  @override
  String get tableOfContentsTitle => 'Table des Matières';

  @override
  String get searchChapterHint => 'Rechercher un chapitre...';

  @override
  String noChapterFound(Object tocSearchQuery) {
    return 'Aucun chapitre trouvé pour \"$tocSearchQuery\"';
  }

  @override
  String get bookCustomization => 'Personnalisation du livre';

  @override
  String get themeColorsUpper => 'THÈME & COULEURS';

  @override
  String get sepia => 'Sépia';

  @override
  String get textSizeUpper => 'TAILLE DU TEXTE';

  @override
  String get fontUpper => 'POLICE DE CARACTÈRES';

  @override
  String get serifBook => 'Serif (Livre)';

  @override
  String get bookMarginsUpper => 'MARGES DU LIVRE';

  @override
  String get narrow => 'Étroite';

  @override
  String get connectionFailedCheck => '❌ Échec de connexion. Vérifiez l\'adresse IP, le port et les identifiants.';

  @override
  String get connectionOkFolderValid => '✅ Connexion réussie et dossier validé !';

  @override
  String folderMissingOnServer(Object path) {
    return '❌ Le serveur répond, mais le dossier \"$path\" n\'existe pas sur le serveur.';
  }

  @override
  String get checkingFolder => 'Vérification du dossier sur le serveur...';

  @override
  String get cannotReachServerCheck => '❌ Impossible de joindre le serveur. Vérifiez les paramètres.';

  @override
  String cannotSaveFolderMissing(Object path) {
    return '❌ Impossible d\'enregistrer : le dossier \"$path\" n\'existe pas sur le serveur.';
  }

  @override
  String deleteProfileBody(Object name) {
    return 'Êtes-vous sûr de vouloir supprimer le profil \"$name\" ?';
  }

  @override
  String serverDeleted(Object serverName) {
    return '🗑️ Serveur \"$serverName\" supprimé.';
  }

  @override
  String get addLocalServer => 'Ajouter un serveur local';

  @override
  String get editServer => 'Modifier le serveur';

  @override
  String get deleteThisServer => 'Supprimer ce serveur';

  @override
  String get serverName => 'Nom du serveur';

  @override
  String get serverNameHint => 'Ex: NAS Salon, PC Bureau...';

  @override
  String get enterName => 'Veuillez saisir un nom';

  @override
  String get ftpPort21 => 'FTP (Port 21)';

  @override
  String get hostIp => 'Hôte / IP';

  @override
  String get hostHint => 'ex. 192.168.1.100 ou nas.local';

  @override
  String get hostRequired => 'IP ou domaine requis';

  @override
  String get rootPath => 'Chemin racine (Path)';

  @override
  String get secureConnectionHttps => 'Connexion sécurisée (HTTPS)';

  @override
  String get authenticationOptional => 'Authentification (Optionnel)';

  @override
  String get usernameLabel => 'Identifiant / Nom d\'utilisateur';

  @override
  String get password => 'Mot de passe';

  @override
  String get allFilesAccessRequired => 'L’accès à tous les fichiers est nécessaire pour analyser le téléphone.';

  @override
  String get noCompatibleBookFound => 'Aucun livre compatible trouvé sur cet appareil.';

  @override
  String alreadyPresentOrSkipped(Object skipped) {
    return ' · $skipped déjà présent(s) ou ignoré(s)';
  }

  @override
  String booksAddedCount(Object imported, Object skipped) {
    return '$imported livre(s) ajouté(s)$skipped';
  }

  @override
  String importFailed(Object error) {
    return 'Import impossible : $error';
  }

  @override
  String get permissionNotGranted => 'Autorisation non accordée : aucun fichier n’a été analysé.';

  @override
  String get scanPhoneTitle => 'Analyser les livres de cet appareil ?';

  @override
  String get scanPhoneBody => 'ComicStream demandera l’accès aux fichiers uniquement pour repérer les BD, PDF et EPUB. Vous choisirez ensuite les fichiers à importer ; rien n’est copié sans confirmation.';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get deviceFiles => 'Fichiers de l’appareil';

  @override
  String get addComicsFromDevice => 'Ajouter des BD depuis cet appareil';

  @override
  String get addComicsFromDeviceBody => 'Analysez tous les fichiers compatibles de cet appareil, puis choisissez les livres à garder.';

  @override
  String get scanningFiles => 'Analyse des fichiers…';

  @override
  String get scanPhone => 'Scanner cet appareil';

  @override
  String addedFilesCount(Object length) {
    return 'Fichiers ajoutés ($length)';
  }

  @override
  String get noFileAdded => 'Aucun fichier ajouté';

  @override
  String get scanPhoneToFindBooks => 'Analysez cet appareil pour trouver vos livres.';

  @override
  String formatPageProgress(Object formatString, Object currentPage1, Object totalPages) {
    return '$formatString · Page $currentPage1/$totalPages';
  }

  @override
  String pageXOfY(Object currentPage1, Object totalPages) {
    return 'Page $currentPage1 sur $totalPages';
  }

  @override
  String get removeFromFavorites => 'Retirer des favoris';

  @override
  String get addToFavorites => 'Ajouter aux favoris';

  @override
  String get pageGrid => 'Grille des pages';

  @override
  String get comicLtrShort => 'BD (G->D)';

  @override
  String get mangaRtlShort => 'Manga (D->G)';

  @override
  String get readingDirection => 'Sens de lecture';

  @override
  String get comicLtr => 'BD (G à D)';

  @override
  String get mangaRtl => 'Manga (D à G)';

  @override
  String get imageFit => 'Ajustement de l\'image';

  @override
  String get screen => 'Écran';

  @override
  String get background => 'Arrière-plan';

  @override
  String get keepScreenAwake => 'Garder l\'écran allumé';

  @override
  String selectedCount(Object length) {
    return '$length sélectionné(s)';
  }

  @override
  String get removeAll => 'Tout retirer';

  @override
  String get addAll => 'Tout ajouter';

  @override
  String get alreadyImported => 'Déjà importé';

  @override
  String booksFoundCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count livres',
      one: '1 livre',
    );
    return '$_temp0';
  }

  @override
  String sizeGb(Object value) {
    return '$value Go';
  }

  @override
  String sizeMb(Object value) {
    return '$value Mo';
  }

  @override
  String sizeKb(Object value) {
    return '$value Ko';
  }

  @override
  String get decimalSeparator => ',';

  @override
  String get convertToCbz => 'Convertir en BD (CBZ)';

  @override
  String get markAsUnread => 'Marquer comme non lu';

  @override
  String get markAsRead => 'Marquer comme lu';

  @override
  String get deleteFromDevice => 'Supprimer de l\'appareil';

  @override
  String get finishedUpper => 'TERMINÉ';

  @override
  String get cbzBenefits => 'Avantages du format CBZ :';

  @override
  String get cbzBenefit1 => '• Rendu beaucoup plus rapide et fluide';

  @override
  String get cbzBenefit2 => '• Mode Manga (sens droit-à-gauche) disponible';

  @override
  String get cbzBenefit3 => '• Mode Webtoon (défilement continu) fluide';

  @override
  String get cbzBenefit4 => '• Moins de consommation mémoire et batterie';

  @override
  String get converting => 'Conversion en cours...';

  @override
  String get conversionSucceeded => 'Conversion réussie !';

  @override
  String get conversionSucceededBody => 'Votre BD est disponible au format CBZ haute définition.';

  @override
  String get readAsCbz => 'Lire en mode BD (CBZ)';

  @override
  String get pleaseWait => 'Veuillez patienter...';

  @override
  String get downloads => 'Téléchargements';

  @override
  String get noDownloadInProgress => 'Aucun téléchargement en cours';

  @override
  String get noDownloadInProgressBody => 'Les fichiers que vous téléchargez depuis votre serveur local apparaîtront ici avec leur progression.';

  @override
  String inProgressCount(Object length) {
    return 'En cours ($length)';
  }

  @override
  String historyCount(Object length) {
    return 'Historique ($length)';
  }

  @override
  String doneWithSize(Object formatBytes) {
    return 'Terminé • $formatBytes';
  }

  @override
  String get deleteFromStorage => 'Supprimer du stockage';

  @override
  String failedWithReason(Object reason) {
    return 'Échec : $reason';
  }

  @override
  String weeksAgo(Object weeks) {
    return 'Il y a $weeks sem.';
  }

  @override
  String daysAgo(Object inDays) {
    return 'Il y a $inDays jours';
  }

  @override
  String hoursAgo(Object inHours) {
    return 'Il y a $inHours h';
  }

  @override
  String minutesAgo(Object inMinutes) {
    return 'Il y a $inMinutes min';
  }

  @override
  String get justNow => 'À l\'instant';

  @override
  String pdfNotFound(Object pdfFilePath) {
    return 'Fichier PDF introuvable : $pdfFilePath';
  }

  @override
  String get pdfHasNoPage => 'Le fichier PDF ne contient aucune page.';

  @override
  String conversionInit(Object totalPages) {
    return 'Initialisation de la conversion ($totalPages pages)...';
  }

  @override
  String renderingPagesRange(Object i1, Object currentBatchEnd, Object totalPages) {
    return 'Rendu HD pages $i1 à $currentBatchEnd / $totalPages...';
  }

  @override
  String renderingPage(Object i1, Object totalPages) {
    return 'Rendu HD page $i1 / $totalPages...';
  }

  @override
  String get assemblingCbz => 'Assemblage ultra-rapide de l\'archive CBZ...';

  @override
  String get noPageGenerated => 'Aucune page n\'a pu être générée depuis le PDF.';

  @override
  String get cbzEncodingFailed => 'Échec de l\'encodage de l\'archive CBZ.';

  @override
  String get finalizingCover => 'Finalisation et extraction de la couverture...';

  @override
  String get conversionDone => 'Conversion terminée avec succès !';

  @override
  String get cbzNotFound => 'Fichier CBZ introuvable sur l\'appareil.';

  @override
  String get noValidImageInCbz => 'Aucune image valide trouvée dans cette archive CBZ.';

  @override
  String cbzReadError(Object sizeMb, Object e) {
    return 'Erreur de lecture ($sizeMb Mo): $e\n\nLe fichier est peut-être corrompu ou le téléchargement est incomplet.';
  }

  @override
  String pagesCount(Object length) {
    return 'Pages ($length)';
  }

  @override
  String get loadingVolume => 'Chargement du tome...';

  @override
  String get volumeFinished => 'Tome terminé ! 🎉';

  @override
  String nextVolumeWithTitle(Object title) {
    return 'Passer au Tome suivant ➔\n$title';
  }

  @override
  String bookSyncUnavailable(Object error) {
    return 'Synchronisation de ce livre indisponible. Lecture locale conservée : $error';
  }

  @override
  String get progressFoundElsewhere => 'Progression trouvée sur un autre appareil';

  @override
  String otherPositionOnDevice(Object remoteDeviceName) {
    return '« $remoteDeviceName » possède une autre position pour ce livre.';
  }

  @override
  String get thisDevice => 'Cet appareil';

  @override
  String get keepHere => 'Conserver ici';

  @override
  String continueFromDevice(Object remoteDeviceName) {
    return 'Continuer depuis $remoteDeviceName';
  }

  @override
  String get downloadFailed => 'Échec du téléchargement';

  @override
  String get convertingHdCbz => 'Conversion HD en CBZ (Mode BD)...';

  @override
  String get downloadingYourComic => 'Téléchargement de votre BD...';

  @override
  String get networkErrorOccurred => 'Une erreur réseau est survenue.';

  @override
  String get convertingHdInProgress => 'Conversion HD en cours...';

  @override
  String get deleteFromDeviceTitle => 'Supprimer de l\'appareil ?';

  @override
  String deleteDownloadedFileBody(Object name) {
    return 'Voulez-vous supprimer le fichier téléchargé en local de \"$name\" pour libérer de l\'espace ?\n\nLe fichier reste toujours accessible et téléchargeable depuis votre serveur.';
  }

  @override
  String deletedFromDevice(Object name) {
    return '\"$name\" a été supprimé de votre tablette.';
  }

  @override
  String get deleteLocalCopy => 'Supprimer du local';

  @override
  String get downloadForOffline => 'Télécharger pour lecture hors-ligne';

  @override
  String get updateAvailable => 'Mise à jour disponible !';

  @override
  String get whatsNew => 'Nouveautés & Changements :';

  @override
  String get defaultReleaseNotes => 'Améliorations de performances et corrections de bugs.';

  @override
  String get downloadApk => 'Télécharger APK';

  @override
  String get almostDone => 'Presque terminé...';

  @override
  String secondsLeft(Object seconds) {
    return '~ $seconds s restantes';
  }

  @override
  String itemsCount(Object itemCount) {
    return '$itemCount éléments';
  }

  @override
  String readOfTotal(Object completedBooks, Object totalBooks) {
    return '$completedBooks/$totalBooks lu(s)';
  }

  @override
  String get emptyServerResponse => 'Réponse vide du serveur';

  @override
  String chapterN(Object length1) {
    return 'Chapitre $length1';
  }

  @override
  String chapterNIdx(Object idx1) {
    return 'Chapitre $idx1';
  }

  @override
  String get pdfNotFoundOnDevice => 'Fichier PDF introuvable sur l\'appareil.';

  @override
  String get convertToCbzComicMode => 'Convertir en CBZ (Mode BD)';

  @override
  String get pressAgainToExit => 'Appuyez à nouveau pour quitter ComicStream';

  @override
  String get downloadsTabShort => 'Télécharg.';

  @override
  String get settingsTab => 'Réglages';

  @override
  String get invalidJsonFormat => 'Format JSON invalide';

  @override
  String cannotLoadFolder(Object e) {
    return 'Impossible de charger le dossier: $e';
  }

  @override
  String get newUpdateAvailable => 'Nouvelle mise à jour disponible.';

  @override
  String get unknownEncryptionVersion => 'Version de chiffrement inconnue';

  @override
  String speedMb(Object value) {
    return '$value Mo/s';
  }

  @override
  String speedKb(Object value) {
    return '$value Ko/s';
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
      other: '$count tomes',
      one: '1 tome',
    );
    return '$_temp0';
  }

  @override
  String chapterSlashPercent(Object current, Object total, Object percent) {
    return 'Chapitre $current/$total · $percent %';
  }

  @override
  String labelLocationDate(Object label, Object location, Object date, Object time) {
    return '$label : $location\n$date à $time';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get edit => 'Modifier';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get save => 'Enregistrer';

  @override
  String get view => 'Voir';

  @override
  String get synchronize => 'Synchroniser';

  @override
  String get back => 'Retour';

  @override
  String get none => 'Aucun';

  @override
  String get all => 'Tout';

  @override
  String get importAction => 'Importer';

  @override
  String get everyone => 'Tous';

  @override
  String get clean => 'Nettoyer';

  @override
  String get read => 'Lire';

  @override
  String get dark => 'Sombre';

  @override
  String get mint => 'Menthe';

  @override
  String get light => 'Clair';

  @override
  String get standard => 'Standard';

  @override
  String get large => 'Large';

  @override
  String get libraryTab => 'Biblio';

  @override
  String get serverTab => 'Serveur';

  @override
  String get filesTab => 'Fichiers';

  @override
  String get delete => 'Supprimer';

  @override
  String get resume => 'Reprendre';

  @override
  String get progress => 'Progression';

  @override
  String get favorites => 'Favoris';

  @override
  String get close => 'Fermer';

  @override
  String get options => 'Options';

  @override
  String get search => 'Rechercher';

  @override
  String get refresh => 'Actualiser';

  @override
  String get root => 'Racine';

  @override
  String get empty => 'Vider';

  @override
  String get font => 'Police';

  @override
  String get lineSpacing => 'Interligne';

  @override
  String get compact => 'Compact';

  @override
  String get normal => 'Normal';

  @override
  String get relaxed => 'Relaxed';

  @override
  String get margin => 'Marge';

  @override
  String get narrowShort => 'Etroit';

  @override
  String get yesterday => 'Hier';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get folder => 'Dossier';

  @override
  String get convert => 'Convertir';

  @override
  String get width => 'Largeur';

  @override
  String get height => 'Hauteur';

  @override
  String get black => 'Noir';

  @override
  String get grey => 'Gris';

  @override
  String get white => 'Blanc';

  @override
  String get downloaded => 'Téléchargé';

  @override
  String get serverDefaultName => 'Serveur';

  @override
  String get test => 'Tester';

  @override
  String get type => 'Type';

  @override
  String get port => 'Port';

  @override
  String get path => 'Chemin';

  @override
  String get credentials => 'Identifiants';

  @override
  String get ignore => 'Ignorer';

  @override
  String get noneLower => 'aucun';

  @override
  String get serverUpper => 'SERVEUR';

  @override
  String get bookUpper => 'LIVRE';

  @override
  String get resumeUpper => 'REPRENDRE';

  @override
  String get currentUpper => 'ACTUEL';

  @override
  String get lineSpacingUpper => 'INTERLIGNE';

  @override
  String get alignmentUpper => 'ALIGNEMENT';

  @override
  String get comicsFilter => 'BD';

  @override
  String get navLibrary => 'Bibliothèque';

  @override
  String get navServers => 'Serveurs';

  @override
  String get computerFiles => 'Fichiers de l’ordinateur';

  @override
  String get addComicsFromComputerBody => 'Choisissez des BD (CBZ, CBR, PDF, EPUB) ou un dossier entier à analyser. Un double-clic dans l’Explorateur les ouvre aussi directement.';

  @override
  String get openFiles => 'Ouvrir des fichiers…';

  @override
  String get scanFolder => 'Analyser un dossier…';

  @override
  String get columnTitle => 'Titre';

  @override
  String get columnFormat => 'Format';

  @override
  String get columnSize => 'Taille';

  @override
  String get columnAdded => 'Ajouté';

  @override
  String get doublePageTitle => 'Double page sur grand écran';

  @override
  String get doublePageBody => 'Deux pages côte à côte quand la fenêtre est large et en paysage';

  @override
  String get onePage => '1 page';

  @override
  String get twoPages => '2 pages';

  @override
  String get togglePagesPerView => 'Afficher 1 ou 2 pages (D)';

  @override
  String get selectAll => 'Tout sélectionner';

  @override
  String get clearSelection => 'Annuler la sélection';

  @override
  String get moveToSeries => 'Déplacer vers une série';

  @override
  String get seriesNameLabel => 'Nom de la série';

  @override
  String get automaticSeries => 'Série automatique';

  @override
  String get move => 'Déplacer';

  @override
  String deleteSelectedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Supprimer $count livres ?',
      one: 'Supprimer 1 livre ?',
    );
    return '$_temp0';
  }

  @override
  String get deleteSelectedBody => 'Les fichiers seront supprimés de cet appareil. Ceux de tes serveurs ne sont pas touchés.';

  @override
  String librarySelectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sélectionnés',
      one: '1 sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get languageTitle => 'Langue';

  @override
  String get systemLanguage => 'Langue du système';

  @override
  String get googleBrowserDone => 'Connexion réussie. Vous pouvez fermer cet onglet et revenir dans ComicStream.';

  @override
  String get googleBrowserFailed => 'La connexion Google a échoué. Fermez cet onglet et réessayez depuis ComicStream.';

  @override
  String get readAgain => 'Relire';

  @override
  String resumeVolumeNumber(int number) {
    return 'Reprendre le tome $number';
  }

  @override
  String readVolumeNumber(int number) {
    return 'Lire le tome $number';
  }

  @override
  String get startReading => 'Commencer';

  @override
  String get seeVolumes => 'Voir les tomes';

  @override
  String get openSeriesSheet => 'Fiche de la série';

  @override
  String get consoleEmpty => 'Aucune série dans ce filtre';

  @override
  String get shelfAll => 'Tous les rayons';

  @override
  String get shelfOther => 'Autres';

  @override
  String get consoleHintMove => 'Se déplacer';

  @override
  String get consoleHintOpen => 'Ouvrir';

  @override
  String get consoleHintBack => 'Retour';

  @override
  String get consoleHintFilter => 'Filtre';

  @override
  String get consoleView => 'Console';

  @override
  String get consoleQueue => 'File d\'attente';

  @override
  String get consoleQueueHint => 'dans l\'ordre de démarrage';

  @override
  String get consoleReady => 'Prêt à lire';

  @override
  String get consoleFailed => 'Échec · réessayer';

  @override
  String get consoleCancelled => 'Annulé · relancer';

  @override
  String get consoleChooseServer => 'Choisissez un serveur pour parcourir ses dossiers.';

  @override
  String consoleItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments',
      one: '1 élément',
    );
    return '$_temp0';
  }

  @override
  String consoleDownloadMissing(int count) {
    return 'Télécharger les $count manquants';
  }

  @override
  String get consoleHintOpenDownload => 'Ouvrir / télécharger';

  @override
  String get consoleHintReadRetry => 'Lire / réessayer';

  @override
  String get consoleAlreadyQueued => 'Déjà dans la file de téléchargement';

  @override
  String get consoleNothingYet => 'Aucun téléchargement pour l\'instant';

  @override
  String get consoleSwitchPage => 'Page suivante';

  @override
  String get pause => 'Pause';

  @override
  String get pausedStatus => 'En pause';

  @override
  String get consoleHintPause => 'Pause / reprendre';

  @override
  String get keySpace => 'Espace';

  @override
  String get downloadUpdate => 'Télécharger la mise à jour';

  @override
  String scanFoundCount(int count) {
    return 'Analyse… $count trouvé(s)';
  }

  @override
  String importProgress(int percent) {
    return 'Import… $percent %';
  }
}
