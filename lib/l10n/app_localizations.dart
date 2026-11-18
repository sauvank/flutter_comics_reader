import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pt')
  ];

  /// No description provided for @resetVaultTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser le coffre ?'**
  String get resetVaultTitle;

  /// No description provided for @resetVaultBody.
  ///
  /// In fr, this message translates to:
  /// **'Si vous avez perdu votre phrase de récupération, la réinitialisation créera un nouveau coffre vierge. Les données protégées de vos autres appareils devront être synchronisées à nouveau.'**
  String get resetVaultBody;

  /// No description provided for @reset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get reset;

  /// No description provided for @confirmSecretPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la phrase secrète'**
  String get confirmSecretPhrase;

  /// No description provided for @secretPhraseWrittenDownBody.
  ///
  /// In fr, this message translates to:
  /// **'Avez-vous bien noté votre phrase secrète dans un endroit sûr ?\n\nElle est indispensable pour restaurer vos données ou synchroniser un nouvel appareil. ComicStream ne la conserve pas et ne pourra jamais la récupérer pour vous.'**
  String get secretPhraseWrittenDownBody;

  /// No description provided for @yourSecretPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Votre phrase secrète :'**
  String get yourSecretPhrase;

  /// No description provided for @phraseNotedContinue.
  ///
  /// In fr, this message translates to:
  /// **'J’ai bien noté, continuer'**
  String get phraseNotedContinue;

  /// No description provided for @changeSecretPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la phrase secrète'**
  String get changeSecretPhrase;

  /// No description provided for @changeSecretPhraseBody.
  ///
  /// In fr, this message translates to:
  /// **'Définissez une nouvelle phrase secrète (16 caractères minimum) pour sécuriser votre synchronisation.'**
  String get changeSecretPhraseBody;

  /// No description provided for @newSecretPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle phrase secrète'**
  String get newSecretPhrase;

  /// No description provided for @min16Characters.
  ///
  /// In fr, this message translates to:
  /// **'16 caractères minimum'**
  String get min16Characters;

  /// No description provided for @showPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Afficher la phrase'**
  String get showPhrase;

  /// No description provided for @hidePhrase.
  ///
  /// In fr, this message translates to:
  /// **'Masquer la phrase'**
  String get hidePhrase;

  /// No description provided for @confirmNewPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la nouvelle phrase'**
  String get confirmNewPhrase;

  /// No description provided for @phraseTooShort.
  ///
  /// In fr, this message translates to:
  /// **'La phrase doit comporter au moins 16 caractères.'**
  String get phraseTooShort;

  /// No description provided for @phrasesDoNotMatch.
  ///
  /// In fr, this message translates to:
  /// **'Les deux phrases ne correspondent pas.'**
  String get phrasesDoNotMatch;

  /// No description provided for @confirmChangeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le changement ?'**
  String get confirmChangeTitle;

  /// No description provided for @confirmChangeBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre coffre va être mis à jour avec cette nouvelle phrase secrète.\nAssurez-vous de l’avoir bien notée :'**
  String get confirmChangeBody;

  /// No description provided for @confirmAndSave.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer et enregistrer'**
  String get confirmAndSave;

  /// No description provided for @secretPhraseUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Phrase secrète mise à jour avec succès.'**
  String get secretPhraseUpdated;

  /// No description provided for @operationDone.
  ///
  /// In fr, this message translates to:
  /// **'Opération terminée.'**
  String get operationDone;

  /// No description provided for @cannotContinue.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de continuer : {error}'**
  String cannotContinue(Object error);

  /// No description provided for @dateAtTime.
  ///
  /// In fr, this message translates to:
  /// **'{date} à {time}'**
  String dateAtTime(Object date, Object time);

  /// No description provided for @syncConflict.
  ///
  /// In fr, this message translates to:
  /// **'Conflit de synchronisation'**
  String get syncConflict;

  /// No description provided for @syncConflictBody.
  ///
  /// In fr, this message translates to:
  /// **'Deux versions de « {label} » ont été modifiées.'**
  String syncConflictBody(Object label);

  /// No description provided for @thisDeviceValue.
  ///
  /// In fr, this message translates to:
  /// **'Cet appareil : {formatConflictDate}'**
  String thisDeviceValue(Object formatConflictDate);

  /// No description provided for @syncServerValue.
  ///
  /// In fr, this message translates to:
  /// **'Serveur de synchronisation : {formatConflictDate}'**
  String syncServerValue(Object formatConflictDate);

  /// No description provided for @thisDeviceSummary.
  ///
  /// In fr, this message translates to:
  /// **'Cet appareil : {localSummary}'**
  String thisDeviceSummary(Object localSummary);

  /// No description provided for @serverSummary.
  ///
  /// In fr, this message translates to:
  /// **'Serveur : {remoteSummary}'**
  String serverSummary(Object remoteSummary);

  /// No description provided for @chooseReferenceVersion.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez la version de référence. Elle sera ensuite synchronisée sur vos autres appareils.'**
  String get chooseReferenceVersion;

  /// No description provided for @fetchFromServer.
  ///
  /// In fr, this message translates to:
  /// **'Récupérer du serveur'**
  String get fetchFromServer;

  /// No description provided for @sendToServer.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer vers le serveur'**
  String get sendToServer;

  /// No description provided for @later.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get later;

  /// No description provided for @thisDeviceName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de cet appareil'**
  String get thisDeviceName;

  /// No description provided for @deviceNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Tablette ou Téléphone'**
  String get deviceNameHint;

  /// No description provided for @deviceNameSavedOnServer.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l’appareil enregistré sur le serveur.'**
  String get deviceNameSavedOnServer;

  /// No description provided for @deviceNameSavedLocally.
  ///
  /// In fr, this message translates to:
  /// **'Nom enregistré sur cet appareil. Il sera envoyé à la prochaine synchronisation.'**
  String get deviceNameSavedLocally;

  /// No description provided for @cannotPrepareSync.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de préparer la synchronisation : {error}'**
  String cannotPrepareSync(Object error);

  /// No description provided for @whichBackupToUse.
  ///
  /// In fr, this message translates to:
  /// **'Quelle sauvegarde utiliser ?'**
  String get whichBackupToUse;

  /// No description provided for @whichBackupBody.
  ///
  /// In fr, this message translates to:
  /// **'Le choix devient la référence partagée. Les autres appareils la recevront à leur prochaine synchronisation.'**
  String get whichBackupBody;

  /// No description provided for @notBackedUpYet.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore sauvegardé'**
  String get notBackedUpYet;

  /// No description provided for @backedUpAt.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegardé {formatConflictDate}'**
  String backedUpAt(Object formatConflictDate);

  /// No description provided for @accountAndSync.
  ///
  /// In fr, this message translates to:
  /// **'Compte et synchronisation'**
  String get accountAndSync;

  /// No description provided for @syncUnavailableNoFirebase.
  ///
  /// In fr, this message translates to:
  /// **'La synchronisation sera disponible après la configuration du projet Firebase. Le lecteur et vos données locales continuent de fonctionner normalement.'**
  String get syncUnavailableNoFirebase;

  /// No description provided for @accountConnected.
  ///
  /// In fr, this message translates to:
  /// **'Compte connecté'**
  String get accountConnected;

  /// No description provided for @vaultUnlockedE2e.
  ///
  /// In fr, this message translates to:
  /// **'Coffre déverrouillé. Vos données sont chiffrées de bout en bout.'**
  String get vaultUnlockedE2e;

  /// No description provided for @vaultLockedOrNew.
  ///
  /// In fr, this message translates to:
  /// **'Coffre verrouillé ou non initialisé.'**
  String get vaultLockedOrNew;

  /// No description provided for @unlockVault.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller le coffre'**
  String get unlockVault;

  /// No description provided for @initEncryptedVault.
  ///
  /// In fr, this message translates to:
  /// **'Initialiser votre coffre chiffré'**
  String get initEncryptedVault;

  /// No description provided for @unlockVaultBody.
  ///
  /// In fr, this message translates to:
  /// **'Un coffre chiffré est associé à ce compte. Saisissez votre phrase de récupération pour déverrouiller la synchronisation sur cet appareil.'**
  String get unlockVaultBody;

  /// No description provided for @initVaultBody.
  ///
  /// In fr, this message translates to:
  /// **'Pour protéger vos mots de passe de serveurs et vos données, choisissez une phrase secrète (16 caractères minimum). Elle est indispensable pour restaurer vos données sur un nouvel appareil.'**
  String get initVaultBody;

  /// No description provided for @recoveryPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Phrase de récupération'**
  String get recoveryPhrase;

  /// No description provided for @secretPhraseMin16.
  ///
  /// In fr, this message translates to:
  /// **'Phrase secrète (16 caractères minimum)'**
  String get secretPhraseMin16;

  /// No description provided for @enterRecoveryPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir votre phrase de récupération.'**
  String get enterRecoveryPhrase;

  /// No description provided for @secretPhraseTooShort.
  ///
  /// In fr, this message translates to:
  /// **'La phrase secrète doit comporter au moins 16 caractères.'**
  String get secretPhraseTooShort;

  /// No description provided for @secretPhrasesDoNotMatch.
  ///
  /// In fr, this message translates to:
  /// **'Les phrases secrètes ne correspondent pas.'**
  String get secretPhrasesDoNotMatch;

  /// No description provided for @unlockSync.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller la synchronisation'**
  String get unlockSync;

  /// No description provided for @createAndEnableVault.
  ///
  /// In fr, this message translates to:
  /// **'Créer et activer le coffre'**
  String get createAndEnableVault;

  /// No description provided for @forgotPhraseReset.
  ///
  /// In fr, this message translates to:
  /// **'Phrase oubliée ? Réinitialiser le coffre'**
  String get forgotPhraseReset;

  /// No description provided for @vaultUnlocked.
  ///
  /// In fr, this message translates to:
  /// **'Coffre déverrouillé'**
  String get vaultUnlocked;

  /// No description provided for @syncActiveE2e.
  ///
  /// In fr, this message translates to:
  /// **'La synchronisation est active et protégée par chiffrement de bout en bout.'**
  String get syncActiveE2e;

  /// No description provided for @syncing.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation…'**
  String get syncing;

  /// No description provided for @changePhrase.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la phrase'**
  String get changePhrase;

  /// No description provided for @shownWhenChoosingBackup.
  ///
  /// In fr, this message translates to:
  /// **'Affiché lors du choix d’une sauvegarde'**
  String get shownWhenChoosingBackup;

  /// No description provided for @signOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get signOut;

  /// No description provided for @createAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get createAccount;

  /// No description provided for @signIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signIn;

  /// No description provided for @passwordMin12.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe (12 caractères minimum)'**
  String get passwordMin12;

  /// No description provided for @showPassword.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le mot de passe'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le mot de passe'**
  String get hidePassword;

  /// No description provided for @createTheAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer le compte'**
  String get createTheAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In fr, this message translates to:
  /// **'J’ai déjà un compte'**
  String get alreadyHaveAccount;

  /// No description provided for @continueWithGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get continueWithGoogle;

  /// No description provided for @recoveryPhraseRequiredNote.
  ///
  /// In fr, this message translates to:
  /// **'La phrase de récupération est indispensable pour restaurer les mots de passe de serveurs sur un nouvel appareil. Elle n’est jamais sauvegardée par ComicStream.'**
  String get recoveryPhraseRequiredNote;

  /// No description provided for @androidCertNotAllowed.
  ///
  /// In fr, this message translates to:
  /// **'Certificat Android non autorisé : {hashes}'**
  String androidCertNotAllowed(Object hashes);

  /// No description provided for @pendingConflicts.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 modification attend votre choix.} other{{count} modifications attendent votre choix.}}'**
  String pendingConflicts(num count);

  /// No description provided for @upToDate.
  ///
  /// In fr, this message translates to:
  /// **'ComicStream est à jour ({fullVersion}) !'**
  String upToDate(Object fullVersion);

  /// No description provided for @updateCheckError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la vérification de la mise à jour'**
  String get updateCheckError;

  /// No description provided for @clearCacheTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vider le cache ?'**
  String get clearCacheTitle;

  /// No description provided for @clearCacheBody.
  ///
  /// In fr, this message translates to:
  /// **'Les couvertures seront rechargées automatiquement.'**
  String get clearCacheBody;

  /// No description provided for @coverCacheCleared.
  ///
  /// In fr, this message translates to:
  /// **'Cache des couvertures vidé avec succès !'**
  String get coverCacheCleared;

  /// No description provided for @deleteAllTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tout supprimer ?'**
  String get deleteAllTitle;

  /// No description provided for @deleteAllBody.
  ///
  /// In fr, this message translates to:
  /// **'Cette action supprimera toutes les BDs et mangas téléchargés en local pour libérer de l\'espace. Vos paramètres de serveurs seront conservés.'**
  String get deleteAllBody;

  /// No description provided for @allLocalFilesDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Tous les fichiers locaux ont été supprimés.'**
  String get allLocalFilesDeleted;

  /// No description provided for @eraseAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout effacer'**
  String get eraseAll;

  /// No description provided for @commandCopied.
  ///
  /// In fr, this message translates to:
  /// **'Commande copiée !'**
  String get commandCopied;

  /// No description provided for @localServerGuide.
  ///
  /// In fr, this message translates to:
  /// **'Guide Serveur Local'**
  String get localServerGuide;

  /// No description provided for @guideOption1.
  ///
  /// In fr, this message translates to:
  /// **'Option 1 : Serveur WebDAV Docker (Recommandé)'**
  String get guideOption1;

  /// No description provided for @guideOption1Body.
  ///
  /// In fr, this message translates to:
  /// **'Lancez un serveur WebDAV léger avec Docker en 1 ligne en pointant vers votre dossier de BDs :'**
  String get guideOption1Body;

  /// No description provided for @guideOption2.
  ///
  /// In fr, this message translates to:
  /// **'Option 2 : Script Python prêt à l\'emploi'**
  String get guideOption2;

  /// No description provided for @guideOption2Body.
  ///
  /// In fr, this message translates to:
  /// **'Un serveur Python dédié est fourni dans le dossier `server_example/comic_server.py`. Pour le lancer :'**
  String get guideOption2Body;

  /// No description provided for @guideOption3.
  ///
  /// In fr, this message translates to:
  /// **'Option 3 : NAS Synology / TrueNAS / Nextcloud'**
  String get guideOption3;

  /// No description provided for @guideOption3Body.
  ///
  /// In fr, this message translates to:
  /// **'Activez simplement le service WebDAV dans le panneau d\'administration de votre NAS (port 5005 par défaut sur Synology) et entrez vos identifiants dans l\'application.'**
  String get guideOption3Body;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @accountAndSyncShort.
  ///
  /// In fr, this message translates to:
  /// **'Compte & synchronisation'**
  String get accountAndSyncShort;

  /// No description provided for @accountAndSyncSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Serveurs, progression et réglages chiffrés'**
  String get accountAndSyncSubtitle;

  /// No description provided for @appearanceTheme.
  ///
  /// In fr, this message translates to:
  /// **'Apparence & Thème'**
  String get appearanceTheme;

  /// No description provided for @appTheme.
  ///
  /// In fr, this message translates to:
  /// **'Thème de l\'application'**
  String get appTheme;

  /// No description provided for @readerPreferences.
  ///
  /// In fr, this message translates to:
  /// **'Préférences du lecteur'**
  String get readerPreferences;

  /// No description provided for @defaultReadingMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode de lecture par défaut'**
  String get defaultReadingMode;

  /// No description provided for @readingModeComic.
  ///
  /// In fr, this message translates to:
  /// **'BD / Franco-Belge (Gauche à Droite)'**
  String get readingModeComic;

  /// No description provided for @readingModeManga.
  ///
  /// In fr, this message translates to:
  /// **'Manga (Droite à Gauche)'**
  String get readingModeManga;

  /// No description provided for @readingModeWebtoon.
  ///
  /// In fr, this message translates to:
  /// **'Webtoon (Défilement vertical)'**
  String get readingModeWebtoon;

  /// No description provided for @keepScreenOn.
  ///
  /// In fr, this message translates to:
  /// **'Garder l\'écran actif en lecture'**
  String get keepScreenOn;

  /// No description provided for @showPageNumber.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le numéro de page'**
  String get showPageNumber;

  /// No description provided for @autoConvertPdf.
  ///
  /// In fr, this message translates to:
  /// **'Convertir automatiquement les PDF en CBZ'**
  String get autoConvertPdf;

  /// No description provided for @autoConvertPdfBody.
  ///
  /// In fr, this message translates to:
  /// **'Transforme chaque PDF téléchargé en archive BD ultra-fluide pour tablette.'**
  String get autoConvertPdfBody;

  /// No description provided for @comicRenderQuality.
  ///
  /// In fr, this message translates to:
  /// **'Qualité de rendu BD'**
  String get comicRenderQuality;

  /// No description provided for @qualityAutoLong.
  ///
  /// In fr, this message translates to:
  /// **'Automatique (Détecte l\'écran + 35% de netteté)'**
  String get qualityAutoLong;

  /// No description provided for @qualitySuperLong.
  ///
  /// In fr, this message translates to:
  /// **'Super-échantillonné (2600px - Zoom net)'**
  String get qualitySuperLong;

  /// No description provided for @qualityUltraLong.
  ///
  /// In fr, this message translates to:
  /// **'Ultra HD (3500px - Définition max)'**
  String get qualityUltraLong;

  /// No description provided for @qualityStandardLong.
  ///
  /// In fr, this message translates to:
  /// **'Standard 1:1 (1900px - Rapide)'**
  String get qualityStandardLong;

  /// No description provided for @qualityAuto.
  ///
  /// In fr, this message translates to:
  /// **'Auto (Écran + 35%)'**
  String get qualityAuto;

  /// No description provided for @qualityHigh.
  ///
  /// In fr, this message translates to:
  /// **'Élevée (2600px)'**
  String get qualityHigh;

  /// No description provided for @qualityStandard.
  ///
  /// In fr, this message translates to:
  /// **'Standard 1:1'**
  String get qualityStandard;

  /// No description provided for @ebooksEpub.
  ///
  /// In fr, this message translates to:
  /// **'E-Books & EPUB'**
  String get ebooksEpub;

  /// No description provided for @fontSize.
  ///
  /// In fr, this message translates to:
  /// **'Taille de la police'**
  String get fontSize;

  /// No description provided for @justifiedText.
  ///
  /// In fr, this message translates to:
  /// **'Texte justifié'**
  String get justifiedText;

  /// No description provided for @storageCache.
  ///
  /// In fr, this message translates to:
  /// **'Stockage & Cache'**
  String get storageCache;

  /// No description provided for @spaceUsedByBooks.
  ///
  /// In fr, this message translates to:
  /// **'Espace occupé par les livres :'**
  String get spaceUsedByBooks;

  /// No description provided for @booksDownloadedCount.
  ///
  /// In fr, this message translates to:
  /// **'{length} livre(s) téléchargé(s)'**
  String booksDownloadedCount(Object length);

  /// No description provided for @clearCache.
  ///
  /// In fr, this message translates to:
  /// **'Vider cache'**
  String get clearCache;

  /// No description provided for @updates.
  ///
  /// In fr, this message translates to:
  /// **'Mises à jour'**
  String get updates;

  /// No description provided for @checkForUpdate.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une mise à jour'**
  String get checkForUpdate;

  /// No description provided for @installedVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version installée : {fullVersion}'**
  String installedVersion(Object fullVersion);

  /// No description provided for @check.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get check;

  /// No description provided for @seeStoreListing.
  ///
  /// In fr, this message translates to:
  /// **'Voir la fiche officielle de ComicStream'**
  String get seeStoreListing;

  /// No description provided for @helpSetup.
  ///
  /// In fr, this message translates to:
  /// **'Aide & Configuration'**
  String get helpSetup;

  /// No description provided for @howToSetupLocalServer.
  ///
  /// In fr, this message translates to:
  /// **'Comment configurer mon serveur local ?'**
  String get howToSetupLocalServer;

  /// No description provided for @helpSetupSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Docker, Python, NAS Synology, TrueNAS...'**
  String get helpSetupSubtitle;

  /// No description provided for @appTagline.
  ///
  /// In fr, this message translates to:
  /// **'Lecteur de BD, Comics & Mangas Cloud'**
  String get appTagline;

  /// No description provided for @deleteBookTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce livre ?'**
  String get deleteBookTitle;

  /// No description provided for @deleteBookBody.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous supprimer \"{title}\" de votre stockage local ?'**
  String deleteBookBody(Object title);

  /// No description provided for @resumeAtChapter.
  ///
  /// In fr, this message translates to:
  /// **'« {title} » était déjà commencé. Reprendre au chapitre {currentPage1} ?'**
  String resumeAtChapter(Object title, Object currentPage1);

  /// No description provided for @resumeAtPage.
  ///
  /// In fr, this message translates to:
  /// **'« {title} » était déjà commencé. Reprendre à la page {currentPage1} ?'**
  String resumeAtPage(Object title, Object currentPage1);

  /// No description provided for @myLibrary.
  ///
  /// In fr, this message translates to:
  /// **'Ma Bibliothèque'**
  String get myLibrary;

  /// No description provided for @comicsCount.
  ///
  /// In fr, this message translates to:
  /// **'{length} BD'**
  String comicsCount(Object length);

  /// No description provided for @syncInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation en cours'**
  String get syncInProgress;

  /// No description provided for @sortBy.
  ///
  /// In fr, this message translates to:
  /// **'Trier par'**
  String get sortBy;

  /// No description provided for @lastRead.
  ///
  /// In fr, this message translates to:
  /// **'Dernière lecture'**
  String get lastRead;

  /// No description provided for @titleAz.
  ///
  /// In fr, this message translates to:
  /// **'Titre (A-Z)'**
  String get titleAz;

  /// No description provided for @dateAdded.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'ajout'**
  String get dateAdded;

  /// No description provided for @seriesCount.
  ///
  /// In fr, this message translates to:
  /// **'Séries ({length})'**
  String seriesCount(Object length);

  /// No description provided for @volumesCount.
  ///
  /// In fr, this message translates to:
  /// **'Tomes ({length})'**
  String volumesCount(Object length);

  /// No description provided for @searchLibraryHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une série, un tome, un auteur...'**
  String get searchLibraryHint;

  /// No description provided for @recentlyOpened.
  ///
  /// In fr, this message translates to:
  /// **'Récemment ouverts'**
  String get recentlyOpened;

  /// No description provided for @myCollectionsCount.
  ///
  /// In fr, this message translates to:
  /// **'Mes Collections & Séries ({length})'**
  String myCollectionsCount(Object length);

  /// No description provided for @backToSeries.
  ///
  /// In fr, this message translates to:
  /// **'Retour aux séries'**
  String get backToSeries;

  /// No description provided for @seriesProgress.
  ///
  /// In fr, this message translates to:
  /// **'{completedBooks}/{totalBooks} tomes lus • {progressPercent}%'**
  String seriesProgress(Object completedBooks, Object totalBooks, Object progressPercent);

  /// No description provided for @checkNewVolumes.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier les nouveaux tomes sur le serveur'**
  String get checkNewVolumes;

  /// No description provided for @nextVolumeToRead.
  ///
  /// In fr, this message translates to:
  /// **'TOME SUIVANT À LIRE'**
  String get nextVolumeToRead;

  /// No description provided for @nextVolumeOnServer.
  ///
  /// In fr, this message translates to:
  /// **'TOME SUIVANT SUR LE SERVEUR'**
  String get nextVolumeOnServer;

  /// No description provided for @download.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger'**
  String get download;

  /// No description provided for @downloadStarted.
  ///
  /// In fr, this message translates to:
  /// **'📥 Téléchargement lancé : {name}'**
  String downloadStarted(Object name);

  /// No description provided for @readNow.
  ///
  /// In fr, this message translates to:
  /// **'Lire direct'**
  String get readNow;

  /// No description provided for @searchingNextVolumes.
  ///
  /// In fr, this message translates to:
  /// **'Recherche des tomes suivants sur le serveur distant...'**
  String get searchingNextVolumes;

  /// No description provided for @downloadedVolumesCount.
  ///
  /// In fr, this message translates to:
  /// **'Tomes téléchargés ({totalBooks})'**
  String downloadedVolumesCount(Object totalBooks);

  /// No description provided for @serverVolumesCount.
  ///
  /// In fr, this message translates to:
  /// **'Tomes disponibles sur le serveur ({length})'**
  String serverVolumesCount(Object length);

  /// No description provided for @downloadAllCount.
  ///
  /// In fr, this message translates to:
  /// **'Tout télécharger ({length})'**
  String downloadAllCount(Object length);

  /// No description provided for @volumesQueued.
  ///
  /// In fr, this message translates to:
  /// **'📥 {length} tomes ajoutés à la file de téléchargement'**
  String volumesQueued(Object length);

  /// No description provided for @downloadingName.
  ///
  /// In fr, this message translates to:
  /// **'📥 Téléchargement : {name}'**
  String downloadingName(Object name);

  /// No description provided for @libraryFilters.
  ///
  /// In fr, this message translates to:
  /// **'Filtres de la bibliothèque'**
  String get libraryFilters;

  /// No description provided for @allCount.
  ///
  /// In fr, this message translates to:
  /// **'Tous ({length})'**
  String allCount(Object length);

  /// No description provided for @inProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get inProgress;

  /// No description provided for @unread.
  ///
  /// In fr, this message translates to:
  /// **'Non lus'**
  String get unread;

  /// No description provided for @epubNovels.
  ///
  /// In fr, this message translates to:
  /// **'EPUB / Romans'**
  String get epubNovels;

  /// No description provided for @finished.
  ///
  /// In fr, this message translates to:
  /// **'Terminés'**
  String get finished;

  /// No description provided for @continueReading.
  ///
  /// In fr, this message translates to:
  /// **'CONTINUER LA LECTURE'**
  String get continueReading;

  /// No description provided for @libraryEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Votre bibliothèque est vide'**
  String get libraryEmpty;

  /// No description provided for @libraryEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos BD depuis un serveur ou les fichiers déjà présents sur votre téléphone.'**
  String get libraryEmptyBody;

  /// No description provided for @exploreServers.
  ///
  /// In fr, this message translates to:
  /// **'Explorer mes serveurs'**
  String get exploreServers;

  /// No description provided for @importFromPhone.
  ///
  /// In fr, this message translates to:
  /// **'Importer depuis ce téléphone'**
  String get importFromPhone;

  /// No description provided for @noSearchResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat pour cette recherche'**
  String get noSearchResults;

  /// No description provided for @noSearchResultsBody.
  ///
  /// In fr, this message translates to:
  /// **'Essayez un autre mot-clé ou réinitialisez les filtres.'**
  String get noSearchResultsBody;

  /// No description provided for @chapterProgressPercent.
  ///
  /// In fr, this message translates to:
  /// **'Chapitre {current}/{total} ({percent}%)'**
  String chapterProgressPercent(Object current, Object total, Object percent);

  /// No description provided for @pageProgressPercent.
  ///
  /// In fr, this message translates to:
  /// **'Page {current}/{total} ({percent}%)'**
  String pageProgressPercent(Object current, Object total, Object percent);

  /// No description provided for @chapterOfTotal.
  ///
  /// In fr, this message translates to:
  /// **'Chapitre {current} sur {total}'**
  String chapterOfTotal(Object current, Object total);

  /// No description provided for @pageOfTotal.
  ///
  /// In fr, this message translates to:
  /// **'Page {current} sur {total}'**
  String pageOfTotal(Object current, Object total);

  /// No description provided for @setupServer.
  ///
  /// In fr, this message translates to:
  /// **'Configurer un serveur'**
  String get setupServer;

  /// No description provided for @connectionSucceeded.
  ///
  /// In fr, this message translates to:
  /// **'Connexion réussie à {name} !'**
  String connectionSucceeded(Object name);

  /// No description provided for @connectionFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la connexion à {name}'**
  String connectionFailed(Object name);

  /// No description provided for @deleteServerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce serveur ?'**
  String get deleteServerTitle;

  /// No description provided for @deleteServerBody.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer \"{name}\" de vos sources distantes ?'**
  String deleteServerBody(Object name);

  /// No description provided for @exportConfiguration.
  ///
  /// In fr, this message translates to:
  /// **'Exporter la configuration'**
  String get exportConfiguration;

  /// No description provided for @exportConfigurationBody.
  ///
  /// In fr, this message translates to:
  /// **'Voici le fichier de configuration JSON contenant vos profils serveurs :'**
  String get exportConfigurationBody;

  /// No description provided for @copyJson.
  ///
  /// In fr, this message translates to:
  /// **'Copier JSON'**
  String get copyJson;

  /// No description provided for @configurationCopied.
  ///
  /// In fr, this message translates to:
  /// **'✅ Configuration copiée dans le presse-papiers !'**
  String get configurationCopied;

  /// No description provided for @importConfiguration.
  ///
  /// In fr, this message translates to:
  /// **'Importer une configuration'**
  String get importConfiguration;

  /// No description provided for @chooseJsonFile.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un fichier .json'**
  String get chooseJsonFile;

  /// No description provided for @fileReadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la lecture du fichier : {e}'**
  String fileReadError(Object e);

  /// No description provided for @orPasteJson.
  ///
  /// In fr, this message translates to:
  /// **'Ou collez le JSON ici :'**
  String get orPasteJson;

  /// No description provided for @serversImported.
  ///
  /// In fr, this message translates to:
  /// **'✅ {count} serveur(s) importé(s) avec succès !'**
  String serversImported(Object count);

  /// No description provided for @baseLocationSet.
  ///
  /// In fr, this message translates to:
  /// **'✅ Emplacement de base défini sur : {currentPath}'**
  String baseLocationSet(Object currentPath);

  /// No description provided for @myServers.
  ///
  /// In fr, this message translates to:
  /// **'Mes Serveurs'**
  String get myServers;

  /// No description provided for @addServer.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un serveur'**
  String get addServer;

  /// No description provided for @howToSetupServer.
  ///
  /// In fr, this message translates to:
  /// **'Comment configurer un serveur'**
  String get howToSetupServer;

  /// No description provided for @exportConfigurations.
  ///
  /// In fr, this message translates to:
  /// **'Exporter les configurations'**
  String get exportConfigurations;

  /// No description provided for @testConnection.
  ///
  /// In fr, this message translates to:
  /// **'Tester la connexion'**
  String get testConnection;

  /// No description provided for @filterFolderHint.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer ce dossier...'**
  String get filterFolderHint;

  /// No description provided for @closeSearch.
  ///
  /// In fr, this message translates to:
  /// **'Fermer la recherche'**
  String get closeSearch;

  /// No description provided for @folderOptions.
  ///
  /// In fr, this message translates to:
  /// **'Options du dossier'**
  String get folderOptions;

  /// No description provided for @setFolderAsRoot.
  ///
  /// In fr, this message translates to:
  /// **'Définir ce dossier comme racine'**
  String get setFolderAsRoot;

  /// No description provided for @switchServer.
  ///
  /// In fr, this message translates to:
  /// **'Changer de serveur'**
  String get switchServer;

  /// No description provided for @parentFolder.
  ///
  /// In fr, this message translates to:
  /// **'Dossier parent'**
  String get parentFolder;

  /// No description provided for @everythingCount.
  ///
  /// In fr, this message translates to:
  /// **'Tout ({length})'**
  String everythingCount(Object length);

  /// No description provided for @downloadAllTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tout télécharger ?'**
  String get downloadAllTitle;

  /// No description provided for @downloadAllBody.
  ///
  /// In fr, this message translates to:
  /// **'{length} tomes vont être téléchargés en arrière-plan.'**
  String downloadAllBody(Object length);

  /// No description provided for @volumesQueuedCount.
  ///
  /// In fr, this message translates to:
  /// **'📥 {length} tome(s) ajouté(s) à la file de téléchargement'**
  String volumesQueuedCount(Object length);

  /// No description provided for @foldersSeriesCount.
  ///
  /// In fr, this message translates to:
  /// **'Dossiers & Séries ({length})'**
  String foldersSeriesCount(Object length);

  /// No description provided for @booksComicsCount.
  ///
  /// In fr, this message translates to:
  /// **'Livres & BD ({length})'**
  String booksComicsCount(Object length);

  /// No description provided for @downloadingNamePlain.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement : {name}'**
  String downloadingNamePlain(Object name);

  /// No description provided for @folderEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Ce dossier est vide'**
  String get folderEmpty;

  /// No description provided for @folderEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Aucun livre ou sous-dossier trouvé dans cet emplacement.'**
  String get folderEmptyBody;

  /// No description provided for @cannotConnectServer.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible au serveur'**
  String get cannotConnectServer;

  /// No description provided for @checkServerReachable.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez que le serveur est accessible sur {baseUrl}.'**
  String checkServerReachable(Object baseUrl);

  /// No description provided for @editSettings.
  ///
  /// In fr, this message translates to:
  /// **'Modifier les paramètres'**
  String get editSettings;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @googleTokenMissing.
  ///
  /// In fr, this message translates to:
  /// **'Jeton d’authentification Google introuvable.'**
  String get googleTokenMissing;

  /// No description provided for @googleSignInUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'La connexion Google n’est pas disponible sur cet appareil.'**
  String get googleSignInUnavailable;

  /// No description provided for @recoveryPhraseTooShort.
  ///
  /// In fr, this message translates to:
  /// **'La phrase de récupération doit comporter au moins 16 caractères.'**
  String get recoveryPhraseTooShort;

  /// No description provided for @signInRequired.
  ///
  /// In fr, this message translates to:
  /// **'Connexion requise'**
  String get signInRequired;

  /// No description provided for @noSyncVaultFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun coffre de synchronisation trouvé.'**
  String get noSyncVaultFound;

  /// No description provided for @vaultMustBeUnlocked.
  ///
  /// In fr, this message translates to:
  /// **'Le coffre doit être déverrouillé pour modifier la phrase secrète.'**
  String get vaultMustBeUnlocked;

  /// No description provided for @recoveryPhraseRequiredHere.
  ///
  /// In fr, this message translates to:
  /// **'Phrase de récupération requise sur cet appareil.'**
  String get recoveryPhraseRequiredHere;

  /// No description provided for @serverConfigurations.
  ///
  /// In fr, this message translates to:
  /// **'Configurations de serveurs'**
  String get serverConfigurations;

  /// No description provided for @readingSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres de lecture'**
  String get readingSettings;

  /// No description provided for @deviceNameLength.
  ///
  /// In fr, this message translates to:
  /// **'Le nom doit contenir entre 1 et 40 caractères.'**
  String get deviceNameLength;

  /// No description provided for @deviceDefaultName.
  ///
  /// In fr, this message translates to:
  /// **'Appareil {substring}'**
  String deviceDefaultName(Object substring);

  /// No description provided for @otherDevice.
  ///
  /// In fr, this message translates to:
  /// **'Autre appareil'**
  String get otherDevice;

  /// No description provided for @remoteProgressGone.
  ///
  /// In fr, this message translates to:
  /// **'Cette progression distante n’existe plus.'**
  String get remoteProgressGone;

  /// No description provided for @thisDeviceNamed.
  ///
  /// In fr, this message translates to:
  /// **'Cet appareil — {currentName}'**
  String thisDeviceNamed(Object currentName);

  /// No description provided for @deviceBackupNotFound.
  ///
  /// In fr, this message translates to:
  /// **'La sauvegarde de cet appareil est introuvable.'**
  String get deviceBackupNotFound;

  /// No description provided for @googleDataNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Les données Google à résoudre sont introuvables.'**
  String get googleDataNotFound;

  /// No description provided for @localProgressGone.
  ///
  /// In fr, this message translates to:
  /// **'La progression locale correspondante n’existe plus.'**
  String get localProgressGone;

  /// No description provided for @unknownSyncDocument.
  ///
  /// In fr, this message translates to:
  /// **'Document de synchronisation inconnu'**
  String get unknownSyncDocument;

  /// No description provided for @readingSettingsShort.
  ///
  /// In fr, this message translates to:
  /// **'Réglages de lecture'**
  String get readingSettingsShort;

  /// No description provided for @yes.
  ///
  /// In fr, this message translates to:
  /// **'oui'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In fr, this message translates to:
  /// **'non'**
  String get no;

  /// No description provided for @chapterSlash.
  ///
  /// In fr, this message translates to:
  /// **'Chapitre {current}/{total}'**
  String chapterSlash(Object current, Object total);

  /// No description provided for @pageSlash.
  ///
  /// In fr, this message translates to:
  /// **'Page {current}/{total}'**
  String pageSlash(Object current, Object total);

  /// No description provided for @progressSummary.
  ///
  /// In fr, this message translates to:
  /// **'{location} · Favori : {favorite} · {bookmarks}'**
  String progressSummary(Object location, Object favorite, Object bookmarks);

  /// No description provided for @bookmarksCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 marque-page} =1{1 marque-page} other{{count} marque-pages}}'**
  String bookmarksCount(num count);

  /// No description provided for @serverProfilesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 profil de serveur} =1{1 profil de serveur} other{{count} profils de serveur}}'**
  String serverProfilesCount(num count);

  /// No description provided for @ftpInvalidServer.
  ///
  /// In fr, this message translates to:
  /// **'Serveur FTP invalide: {banner}'**
  String ftpInvalidServer(Object banner);

  /// No description provided for @ftpCredentialsRefused.
  ///
  /// In fr, this message translates to:
  /// **'Identifiants FTP refusés: {passResp}'**
  String ftpCredentialsRefused(Object passResp);

  /// No description provided for @ftpUsernameRefused.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant FTP refusé: {userResp}'**
  String ftpUsernameRefused(Object userResp);

  /// No description provided for @ftpPassiveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Mode passif FTP échoué: {pasvResp}'**
  String ftpPassiveFailed(Object pasvResp);

  /// No description provided for @ftpDownloadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de télécharger le fichier FTP: {retrResp}'**
  String ftpDownloadFailed(Object retrResp);

  /// No description provided for @ftpIdleTimeout.
  ///
  /// In fr, this message translates to:
  /// **'Délai d\'inactivité FTP dépassé'**
  String get ftpIdleTimeout;

  /// No description provided for @ftpPasvUnrecognized.
  ///
  /// In fr, this message translates to:
  /// **'Réponse PASV non reconnue: {response}'**
  String ftpPasvUnrecognized(Object response);

  /// No description provided for @guideHeroTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lisez les BD de votre ordinateur ou NAS'**
  String get guideHeroTitle;

  /// No description provided for @guideHeroBody.
  ///
  /// In fr, this message translates to:
  /// **'Un serveur rend votre collection accessible depuis le téléphone, sans tout copier. Comptez environ 2 minutes.'**
  String get guideHeroBody;

  /// No description provided for @howItWorks.
  ///
  /// In fr, this message translates to:
  /// **'Comment faire'**
  String get howItWorks;

  /// No description provided for @guideStep1Title.
  ///
  /// In fr, this message translates to:
  /// **'Partagez votre dossier de BD'**
  String get guideStep1Title;

  /// No description provided for @guideStep1Body.
  ///
  /// In fr, this message translates to:
  /// **'Sur votre NAS ou ordinateur, activez un partage WebDAV, FTP ou HTTP qui pointe vers le dossier contenant vos fichiers CBZ, CBR, PDF ou EPUB. Les exemples ci-dessous détaillent chaque cas.'**
  String get guideStep1Body;

  /// No description provided for @guideStep2Title.
  ///
  /// In fr, this message translates to:
  /// **'Notez son adresse'**
  String get guideStep2Title;

  /// No description provided for @guideStep2Body.
  ///
  /// In fr, this message translates to:
  /// **'Repérez l’adresse IP locale de la machine (ex. 192.168.1.100) et le port du partage. Le téléphone doit être connecté au même réseau Wi-Fi.'**
  String get guideStep2Body;

  /// No description provided for @guideStep3Title.
  ///
  /// In fr, this message translates to:
  /// **'Remplissez le formulaire'**
  String get guideStep3Title;

  /// No description provided for @guideStep3Body.
  ///
  /// In fr, this message translates to:
  /// **'Touchez « Ajouter un serveur », choisissez le type, puis saisissez l’hôte, le port, le chemin du dossier et, si besoin, l’identifiant et le mot de passe.'**
  String get guideStep3Body;

  /// No description provided for @guideStep4Title.
  ///
  /// In fr, this message translates to:
  /// **'Testez puis enregistrez'**
  String get guideStep4Title;

  /// No description provided for @guideStep4Body.
  ///
  /// In fr, this message translates to:
  /// **'« Tester » vérifie la connexion. Une fois validé, « Enregistrer » ouvre directement le serveur pour parcourir et télécharger vos livres.'**
  String get guideStep4Body;

  /// No description provided for @configurationExamples.
  ///
  /// In fr, this message translates to:
  /// **'Exemples de configuration'**
  String get configurationExamples;

  /// No description provided for @webdavSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Recommandé · NAS Synology, QNAP, Nextcloud'**
  String get webdavSubtitle;

  /// No description provided for @host.
  ///
  /// In fr, this message translates to:
  /// **'Hôte'**
  String get host;

  /// No description provided for @webdavPorts.
  ///
  /// In fr, this message translates to:
  /// **'5005 (Synology), 80 ou 443'**
  String get webdavPorts;

  /// No description provided for @webdavCredentials.
  ///
  /// In fr, this message translates to:
  /// **'ceux de votre compte NAS'**
  String get webdavCredentials;

  /// No description provided for @webdavTip.
  ///
  /// In fr, this message translates to:
  /// **'Sur Synology : installez « WebDAV Server » depuis le Centre de paquets et activez HTTP ou HTTPS.'**
  String get webdavTip;

  /// No description provided for @httpSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Le plus simple depuis un ordinateur'**
  String get httpSubtitle;

  /// No description provided for @computerIp.
  ///
  /// In fr, this message translates to:
  /// **'IP de l’ordinateur'**
  String get computerIp;

  /// No description provided for @httpTip.
  ///
  /// In fr, this message translates to:
  /// **'Dans le dossier de vos BD, lancez « python3 -m http.server 8080 », ou le script server_example/comic_server.py fourni avec ComicStream.'**
  String get httpTip;

  /// No description provided for @ftpSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Box internet, anciens NAS'**
  String get ftpSubtitle;

  /// No description provided for @ftpCredentials.
  ///
  /// In fr, this message translates to:
  /// **'compte FTP de la box ou du NAS'**
  String get ftpCredentials;

  /// No description provided for @ftpTip.
  ///
  /// In fr, this message translates to:
  /// **'Le FTP n’est pas chiffré : réservez-le à votre réseau domestique.'**
  String get ftpTip;

  /// No description provided for @cannotConnectTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ça ne se connecte pas ?'**
  String get cannotConnectTitle;

  /// No description provided for @tipSameWifi.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez que le téléphone et le serveur sont sur le même Wi-Fi.'**
  String get tipSameWifi;

  /// No description provided for @tipUseIp.
  ///
  /// In fr, this message translates to:
  /// **'Essayez l’adresse IP plutôt qu’un nom (nas.local).'**
  String get tipUseIp;

  /// No description provided for @tipFirewall.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez que le pare-feu de l’ordinateur autorise le port choisi.'**
  String get tipFirewall;

  /// No description provided for @tipVpn.
  ///
  /// In fr, this message translates to:
  /// **'Hors de chez vous, passez par un VPN (WireGuard, Tailscale…) plutôt que d’exposer le serveur sur Internet.'**
  String get tipVpn;

  /// No description provided for @importExistingConfiguration.
  ///
  /// In fr, this message translates to:
  /// **'Importer une configuration existante'**
  String get importExistingConfiguration;

  /// No description provided for @waiting.
  ///
  /// In fr, this message translates to:
  /// **'En attente...'**
  String get waiting;

  /// No description provided for @downloadingEllipsis.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement...'**
  String get downloadingEllipsis;

  /// No description provided for @cancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get cancelled;

  /// No description provided for @extractingFinalizing.
  ///
  /// In fr, this message translates to:
  /// **'Extraction et finalisation...'**
  String get extractingFinalizing;

  /// No description provided for @convertingHd.
  ///
  /// In fr, this message translates to:
  /// **'Conversion BD HD en cours...'**
  String get convertingHd;

  /// No description provided for @secondsRemaining.
  ///
  /// In fr, this message translates to:
  /// **' ~ {approxSec}s restantes'**
  String secondsRemaining(Object approxSec);

  /// No description provided for @convertingHdProgress.
  ///
  /// In fr, this message translates to:
  /// **'Conversion HD ({currentPage}/{totalPages} pages){etaText}'**
  String convertingHdProgress(Object currentPage, Object totalPages, Object etaText);

  /// No description provided for @finishedStatus.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get finishedStatus;

  /// No description provided for @failed.
  ///
  /// In fr, this message translates to:
  /// **'Échec'**
  String get failed;

  /// No description provided for @networkTimeout.
  ///
  /// In fr, this message translates to:
  /// **'Délai d\'attente dépassé (timeout réseau)'**
  String get networkTimeout;

  /// No description provided for @invalidCertificate.
  ///
  /// In fr, this message translates to:
  /// **'Certificat de sécurité invalide (serveur auto-signé ?)'**
  String get invalidCertificate;

  /// No description provided for @fileNotFound404.
  ///
  /// In fr, this message translates to:
  /// **'Fichier introuvable sur le serveur (404)'**
  String get fileNotFound404;

  /// No description provided for @accessDenied.
  ///
  /// In fr, this message translates to:
  /// **'Accès refusé (identifiants incorrects)'**
  String get accessDenied;

  /// No description provided for @cannotReachServerLost.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de joindre le serveur (connexion perdue)'**
  String get cannotReachServerLost;

  /// No description provided for @downloadCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement annulé'**
  String get downloadCancelled;

  /// No description provided for @networkInterrupted.
  ///
  /// In fr, this message translates to:
  /// **'Connexion réseau interrompue'**
  String get networkInterrupted;

  /// No description provided for @notEnoughStorage.
  ///
  /// In fr, this message translates to:
  /// **'Espace de stockage insuffisant sur l\'appareil'**
  String get notEnoughStorage;

  /// No description provided for @networkError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de connexion réseau'**
  String get networkError;

  /// No description provided for @localFileAccessError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur d\'accès au fichier local'**
  String get localFileAccessError;

  /// No description provided for @serverError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur serveur'**
  String get serverError;

  /// No description provided for @serverErrorCode.
  ///
  /// In fr, this message translates to:
  /// **'Erreur serveur ({code})'**
  String serverErrorCode(Object code);

  /// No description provided for @endOfBookReached.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes arrivé à la fin du livre !'**
  String get endOfBookReached;

  /// No description provided for @loadingBook.
  ///
  /// In fr, this message translates to:
  /// **'Chargement du livre...'**
  String get loadingBook;

  /// No description provided for @cannotLoadBook.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ce livre'**
  String get cannotLoadBook;

  /// No description provided for @fileMaybeCorrupted.
  ///
  /// In fr, this message translates to:
  /// **'Le format du fichier est peut-être corrompu ou non supporté.'**
  String get fileMaybeCorrupted;

  /// No description provided for @backToLibrary.
  ///
  /// In fr, this message translates to:
  /// **'Retour à la bibliothèque'**
  String get backToLibrary;

  /// No description provided for @epubProgressShort.
  ///
  /// In fr, this message translates to:
  /// **'{value}% • Chap. {currentChapterIndex1}/{length}'**
  String epubProgressShort(Object value, Object currentChapterIndex1, Object length);

  /// No description provided for @tableOfContents.
  ///
  /// In fr, this message translates to:
  /// **'Table des matières'**
  String get tableOfContents;

  /// No description provided for @customizeReading.
  ///
  /// In fr, this message translates to:
  /// **'Personnaliser la lecture'**
  String get customizeReading;

  /// No description provided for @chapterXOfY.
  ///
  /// In fr, this message translates to:
  /// **'Chapitre {currentChapterIndex1} / {length}'**
  String chapterXOfY(Object currentChapterIndex1, Object length);

  /// No description provided for @endOfChapter.
  ///
  /// In fr, this message translates to:
  /// **'Fin du Chapitre {currentChapterIndex1}'**
  String endOfChapter(Object currentChapterIndex1);

  /// No description provided for @nextChapterUpper.
  ///
  /// In fr, this message translates to:
  /// **'CHAPITRE SUIVANT'**
  String get nextChapterUpper;

  /// No description provided for @bookFinished.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez terminé ce livre !'**
  String get bookFinished;

  /// No description provided for @tableOfContentsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Table des Matières'**
  String get tableOfContentsTitle;

  /// No description provided for @searchChapterHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un chapitre...'**
  String get searchChapterHint;

  /// No description provided for @noChapterFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun chapitre trouvé pour \"{tocSearchQuery}\"'**
  String noChapterFound(Object tocSearchQuery);

  /// No description provided for @bookCustomization.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisation du livre'**
  String get bookCustomization;

  /// No description provided for @themeColorsUpper.
  ///
  /// In fr, this message translates to:
  /// **'THÈME & COULEURS'**
  String get themeColorsUpper;

  /// No description provided for @sepia.
  ///
  /// In fr, this message translates to:
  /// **'Sépia'**
  String get sepia;

  /// No description provided for @textSizeUpper.
  ///
  /// In fr, this message translates to:
  /// **'TAILLE DU TEXTE'**
  String get textSizeUpper;

  /// No description provided for @fontUpper.
  ///
  /// In fr, this message translates to:
  /// **'POLICE DE CARACTÈRES'**
  String get fontUpper;

  /// No description provided for @serifBook.
  ///
  /// In fr, this message translates to:
  /// **'Serif (Livre)'**
  String get serifBook;

  /// No description provided for @bookMarginsUpper.
  ///
  /// In fr, this message translates to:
  /// **'MARGES DU LIVRE'**
  String get bookMarginsUpper;

  /// No description provided for @narrow.
  ///
  /// In fr, this message translates to:
  /// **'Étroite'**
  String get narrow;

  /// No description provided for @connectionFailedCheck.
  ///
  /// In fr, this message translates to:
  /// **'❌ Échec de connexion. Vérifiez l\'adresse IP, le port et les identifiants.'**
  String get connectionFailedCheck;

  /// No description provided for @connectionOkFolderValid.
  ///
  /// In fr, this message translates to:
  /// **'✅ Connexion réussie et dossier validé !'**
  String get connectionOkFolderValid;

  /// No description provided for @folderMissingOnServer.
  ///
  /// In fr, this message translates to:
  /// **'❌ Le serveur répond, mais le dossier \"{path}\" n\'existe pas sur le serveur.'**
  String folderMissingOnServer(Object path);

  /// No description provided for @checkingFolder.
  ///
  /// In fr, this message translates to:
  /// **'Vérification du dossier sur le serveur...'**
  String get checkingFolder;

  /// No description provided for @cannotReachServerCheck.
  ///
  /// In fr, this message translates to:
  /// **'❌ Impossible de joindre le serveur. Vérifiez les paramètres.'**
  String get cannotReachServerCheck;

  /// No description provided for @cannotSaveFolderMissing.
  ///
  /// In fr, this message translates to:
  /// **'❌ Impossible d\'enregistrer : le dossier \"{path}\" n\'existe pas sur le serveur.'**
  String cannotSaveFolderMissing(Object path);

  /// No description provided for @deleteProfileBody.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer le profil \"{name}\" ?'**
  String deleteProfileBody(Object name);

  /// No description provided for @serverDeleted.
  ///
  /// In fr, this message translates to:
  /// **'🗑️ Serveur \"{serverName}\" supprimé.'**
  String serverDeleted(Object serverName);

  /// No description provided for @addLocalServer.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un serveur local'**
  String get addLocalServer;

  /// No description provided for @editServer.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le serveur'**
  String get editServer;

  /// No description provided for @deleteThisServer.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce serveur'**
  String get deleteThisServer;

  /// No description provided for @serverName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du serveur'**
  String get serverName;

  /// No description provided for @serverNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: NAS Salon, PC Bureau...'**
  String get serverNameHint;

  /// No description provided for @enterName.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir un nom'**
  String get enterName;

  /// No description provided for @ftpPort21.
  ///
  /// In fr, this message translates to:
  /// **'FTP (Port 21)'**
  String get ftpPort21;

  /// No description provided for @hostIp.
  ///
  /// In fr, this message translates to:
  /// **'Hôte / IP'**
  String get hostIp;

  /// No description provided for @hostHint.
  ///
  /// In fr, this message translates to:
  /// **'ex. 192.168.1.100 ou nas.local'**
  String get hostHint;

  /// No description provided for @hostRequired.
  ///
  /// In fr, this message translates to:
  /// **'IP ou domaine requis'**
  String get hostRequired;

  /// No description provided for @rootPath.
  ///
  /// In fr, this message translates to:
  /// **'Chemin racine (Path)'**
  String get rootPath;

  /// No description provided for @secureConnectionHttps.
  ///
  /// In fr, this message translates to:
  /// **'Connexion sécurisée (HTTPS)'**
  String get secureConnectionHttps;

  /// No description provided for @authenticationOptional.
  ///
  /// In fr, this message translates to:
  /// **'Authentification (Optionnel)'**
  String get authenticationOptional;

  /// No description provided for @usernameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant / Nom d\'utilisateur'**
  String get usernameLabel;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @allFilesAccessRequired.
  ///
  /// In fr, this message translates to:
  /// **'L’accès à tous les fichiers est nécessaire pour analyser le téléphone.'**
  String get allFilesAccessRequired;

  /// No description provided for @noCompatibleBookFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun livre compatible trouvé sur le téléphone.'**
  String get noCompatibleBookFound;

  /// No description provided for @alreadyPresentOrSkipped.
  ///
  /// In fr, this message translates to:
  /// **' · {skipped} déjà présent(s) ou ignoré(s)'**
  String alreadyPresentOrSkipped(Object skipped);

  /// No description provided for @booksAddedCount.
  ///
  /// In fr, this message translates to:
  /// **'{imported} livre(s) ajouté(s){skipped}'**
  String booksAddedCount(Object imported, Object skipped);

  /// No description provided for @importFailed.
  ///
  /// In fr, this message translates to:
  /// **'Import impossible : {error}'**
  String importFailed(Object error);

  /// No description provided for @permissionNotGranted.
  ///
  /// In fr, this message translates to:
  /// **'Autorisation non accordée : aucun fichier n’a été analysé.'**
  String get permissionNotGranted;

  /// No description provided for @scanPhoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Analyser les livres du téléphone ?'**
  String get scanPhoneTitle;

  /// No description provided for @scanPhoneBody.
  ///
  /// In fr, this message translates to:
  /// **'ComicStream demandera l’accès aux fichiers uniquement pour repérer les BD, PDF et EPUB. Vous choisirez ensuite les fichiers à importer ; rien n’est copié sans confirmation.'**
  String get scanPhoneBody;

  /// No description provided for @notNow.
  ///
  /// In fr, this message translates to:
  /// **'Pas maintenant'**
  String get notNow;

  /// No description provided for @deviceFiles.
  ///
  /// In fr, this message translates to:
  /// **'Fichiers de l’appareil'**
  String get deviceFiles;

  /// No description provided for @addComicsFromDevice.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des BD depuis cet appareil'**
  String get addComicsFromDevice;

  /// No description provided for @addComicsFromDeviceBody.
  ///
  /// In fr, this message translates to:
  /// **'Analysez tous les fichiers compatibles du téléphone, puis choisissez les livres à garder.'**
  String get addComicsFromDeviceBody;

  /// No description provided for @scanningFiles.
  ///
  /// In fr, this message translates to:
  /// **'Analyse des fichiers…'**
  String get scanningFiles;

  /// No description provided for @scanPhone.
  ///
  /// In fr, this message translates to:
  /// **'Scanner le téléphone'**
  String get scanPhone;

  /// No description provided for @addedFilesCount.
  ///
  /// In fr, this message translates to:
  /// **'Fichiers ajoutés ({length})'**
  String addedFilesCount(Object length);

  /// No description provided for @noFileAdded.
  ///
  /// In fr, this message translates to:
  /// **'Aucun fichier ajouté'**
  String get noFileAdded;

  /// No description provided for @scanPhoneToFindBooks.
  ///
  /// In fr, this message translates to:
  /// **'Analysez le téléphone pour trouver vos livres.'**
  String get scanPhoneToFindBooks;

  /// No description provided for @formatPageProgress.
  ///
  /// In fr, this message translates to:
  /// **'{formatString} · Page {currentPage1}/{totalPages}'**
  String formatPageProgress(Object formatString, Object currentPage1, Object totalPages);

  /// No description provided for @pageXOfY.
  ///
  /// In fr, this message translates to:
  /// **'Page {currentPage1} sur {totalPages}'**
  String pageXOfY(Object currentPage1, Object totalPages);

  /// No description provided for @removeFromFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Retirer des favoris'**
  String get removeFromFavorites;

  /// No description provided for @addToFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter aux favoris'**
  String get addToFavorites;

  /// No description provided for @pageGrid.
  ///
  /// In fr, this message translates to:
  /// **'Grille des pages'**
  String get pageGrid;

  /// No description provided for @comicLtrShort.
  ///
  /// In fr, this message translates to:
  /// **'BD (G->D)'**
  String get comicLtrShort;

  /// No description provided for @mangaRtlShort.
  ///
  /// In fr, this message translates to:
  /// **'Manga (D->G)'**
  String get mangaRtlShort;

  /// No description provided for @readingDirection.
  ///
  /// In fr, this message translates to:
  /// **'Sens de lecture'**
  String get readingDirection;

  /// No description provided for @comicLtr.
  ///
  /// In fr, this message translates to:
  /// **'BD (G à D)'**
  String get comicLtr;

  /// No description provided for @mangaRtl.
  ///
  /// In fr, this message translates to:
  /// **'Manga (D à G)'**
  String get mangaRtl;

  /// No description provided for @imageFit.
  ///
  /// In fr, this message translates to:
  /// **'Ajustement de l\'image'**
  String get imageFit;

  /// No description provided for @screen.
  ///
  /// In fr, this message translates to:
  /// **'Écran'**
  String get screen;

  /// No description provided for @background.
  ///
  /// In fr, this message translates to:
  /// **'Arrière-plan'**
  String get background;

  /// No description provided for @keepScreenAwake.
  ///
  /// In fr, this message translates to:
  /// **'Garder l\'écran allumé'**
  String get keepScreenAwake;

  /// No description provided for @selectedCount.
  ///
  /// In fr, this message translates to:
  /// **'{length} sélectionné(s)'**
  String selectedCount(Object length);

  /// No description provided for @removeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout retirer'**
  String get removeAll;

  /// No description provided for @addAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout ajouter'**
  String get addAll;

  /// No description provided for @alreadyImported.
  ///
  /// In fr, this message translates to:
  /// **'Déjà importé'**
  String get alreadyImported;

  /// No description provided for @booksFoundCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 livre} other{{count} livres}}'**
  String booksFoundCount(num count);

  /// No description provided for @sizeGb.
  ///
  /// In fr, this message translates to:
  /// **'{value} Go'**
  String sizeGb(Object value);

  /// No description provided for @sizeMb.
  ///
  /// In fr, this message translates to:
  /// **'{value} Mo'**
  String sizeMb(Object value);

  /// No description provided for @sizeKb.
  ///
  /// In fr, this message translates to:
  /// **'{value} Ko'**
  String sizeKb(Object value);

  /// No description provided for @decimalSeparator.
  ///
  /// In fr, this message translates to:
  /// **','**
  String get decimalSeparator;

  /// No description provided for @convertToCbz.
  ///
  /// In fr, this message translates to:
  /// **'Convertir en BD (CBZ)'**
  String get convertToCbz;

  /// No description provided for @markAsUnread.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme non lu'**
  String get markAsUnread;

  /// No description provided for @markAsRead.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme lu'**
  String get markAsRead;

  /// No description provided for @deleteFromDevice.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer de l\'appareil'**
  String get deleteFromDevice;

  /// No description provided for @finishedUpper.
  ///
  /// In fr, this message translates to:
  /// **'TERMINÉ'**
  String get finishedUpper;

  /// No description provided for @cbzBenefits.
  ///
  /// In fr, this message translates to:
  /// **'Avantages du format CBZ :'**
  String get cbzBenefits;

  /// No description provided for @cbzBenefit1.
  ///
  /// In fr, this message translates to:
  /// **'• Rendu beaucoup plus rapide et fluide'**
  String get cbzBenefit1;

  /// No description provided for @cbzBenefit2.
  ///
  /// In fr, this message translates to:
  /// **'• Mode Manga (sens droit-à-gauche) disponible'**
  String get cbzBenefit2;

  /// No description provided for @cbzBenefit3.
  ///
  /// In fr, this message translates to:
  /// **'• Mode Webtoon (défilement continu) fluide'**
  String get cbzBenefit3;

  /// No description provided for @cbzBenefit4.
  ///
  /// In fr, this message translates to:
  /// **'• Moins de consommation mémoire et batterie'**
  String get cbzBenefit4;

  /// No description provided for @converting.
  ///
  /// In fr, this message translates to:
  /// **'Conversion en cours...'**
  String get converting;

  /// No description provided for @conversionSucceeded.
  ///
  /// In fr, this message translates to:
  /// **'Conversion réussie !'**
  String get conversionSucceeded;

  /// No description provided for @conversionSucceededBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre BD est disponible au format CBZ haute définition.'**
  String get conversionSucceededBody;

  /// No description provided for @readAsCbz.
  ///
  /// In fr, this message translates to:
  /// **'Lire en mode BD (CBZ)'**
  String get readAsCbz;

  /// No description provided for @pleaseWait.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez patienter...'**
  String get pleaseWait;

  /// No description provided for @downloads.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargements'**
  String get downloads;

  /// No description provided for @noDownloadInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Aucun téléchargement en cours'**
  String get noDownloadInProgress;

  /// No description provided for @noDownloadInProgressBody.
  ///
  /// In fr, this message translates to:
  /// **'Les fichiers que vous téléchargez depuis votre serveur local apparaîtront ici avec leur progression.'**
  String get noDownloadInProgressBody;

  /// No description provided for @inProgressCount.
  ///
  /// In fr, this message translates to:
  /// **'En cours ({length})'**
  String inProgressCount(Object length);

  /// No description provided for @historyCount.
  ///
  /// In fr, this message translates to:
  /// **'Historique ({length})'**
  String historyCount(Object length);

  /// No description provided for @doneWithSize.
  ///
  /// In fr, this message translates to:
  /// **'Terminé • {formatBytes}'**
  String doneWithSize(Object formatBytes);

  /// No description provided for @deleteFromStorage.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer du stockage'**
  String get deleteFromStorage;

  /// No description provided for @failedWithReason.
  ///
  /// In fr, this message translates to:
  /// **'Échec : {reason}'**
  String failedWithReason(Object reason);

  /// No description provided for @weeksAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {weeks} sem.'**
  String weeksAgo(Object weeks);

  /// No description provided for @daysAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {inDays} jours'**
  String daysAgo(Object inDays);

  /// No description provided for @hoursAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {inHours} h'**
  String hoursAgo(Object inHours);

  /// No description provided for @minutesAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {inMinutes} min'**
  String minutesAgo(Object inMinutes);

  /// No description provided for @justNow.
  ///
  /// In fr, this message translates to:
  /// **'À l\'instant'**
  String get justNow;

  /// No description provided for @pdfNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Fichier PDF introuvable : {pdfFilePath}'**
  String pdfNotFound(Object pdfFilePath);

  /// No description provided for @pdfHasNoPage.
  ///
  /// In fr, this message translates to:
  /// **'Le fichier PDF ne contient aucune page.'**
  String get pdfHasNoPage;

  /// No description provided for @conversionInit.
  ///
  /// In fr, this message translates to:
  /// **'Initialisation de la conversion ({totalPages} pages)...'**
  String conversionInit(Object totalPages);

  /// No description provided for @renderingPagesRange.
  ///
  /// In fr, this message translates to:
  /// **'Rendu HD pages {i1} à {currentBatchEnd} / {totalPages}...'**
  String renderingPagesRange(Object i1, Object currentBatchEnd, Object totalPages);

  /// No description provided for @renderingPage.
  ///
  /// In fr, this message translates to:
  /// **'Rendu HD page {i1} / {totalPages}...'**
  String renderingPage(Object i1, Object totalPages);

  /// No description provided for @assemblingCbz.
  ///
  /// In fr, this message translates to:
  /// **'Assemblage ultra-rapide de l\'archive CBZ...'**
  String get assemblingCbz;

  /// No description provided for @noPageGenerated.
  ///
  /// In fr, this message translates to:
  /// **'Aucune page n\'a pu être générée depuis le PDF.'**
  String get noPageGenerated;

  /// No description provided for @cbzEncodingFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'encodage de l\'archive CBZ.'**
  String get cbzEncodingFailed;

  /// No description provided for @finalizingCover.
  ///
  /// In fr, this message translates to:
  /// **'Finalisation et extraction de la couverture...'**
  String get finalizingCover;

  /// No description provided for @conversionDone.
  ///
  /// In fr, this message translates to:
  /// **'Conversion terminée avec succès !'**
  String get conversionDone;

  /// No description provided for @cbzNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Fichier CBZ introuvable sur l\'appareil.'**
  String get cbzNotFound;

  /// No description provided for @noValidImageInCbz.
  ///
  /// In fr, this message translates to:
  /// **'Aucune image valide trouvée dans cette archive CBZ.'**
  String get noValidImageInCbz;

  /// No description provided for @cbzReadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de lecture ({sizeMb} Mo): {e}\n\nLe fichier est peut-être corrompu ou le téléchargement est incomplet.'**
  String cbzReadError(Object sizeMb, Object e);

  /// No description provided for @pagesCount.
  ///
  /// In fr, this message translates to:
  /// **'Pages ({length})'**
  String pagesCount(Object length);

  /// No description provided for @loadingVolume.
  ///
  /// In fr, this message translates to:
  /// **'Chargement du tome...'**
  String get loadingVolume;

  /// No description provided for @volumeFinished.
  ///
  /// In fr, this message translates to:
  /// **'Tome terminé ! 🎉'**
  String get volumeFinished;

  /// No description provided for @nextVolumeWithTitle.
  ///
  /// In fr, this message translates to:
  /// **'Passer au Tome suivant ➔\n{title}'**
  String nextVolumeWithTitle(Object title);

  /// No description provided for @bookSyncUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation de ce livre indisponible. Lecture locale conservée : {error}'**
  String bookSyncUnavailable(Object error);

  /// No description provided for @progressFoundElsewhere.
  ///
  /// In fr, this message translates to:
  /// **'Progression trouvée sur un autre appareil'**
  String get progressFoundElsewhere;

  /// No description provided for @otherPositionOnDevice.
  ///
  /// In fr, this message translates to:
  /// **'« {remoteDeviceName} » possède une autre position pour ce livre.'**
  String otherPositionOnDevice(Object remoteDeviceName);

  /// No description provided for @thisDevice.
  ///
  /// In fr, this message translates to:
  /// **'Cet appareil'**
  String get thisDevice;

  /// No description provided for @keepHere.
  ///
  /// In fr, this message translates to:
  /// **'Conserver ici'**
  String get keepHere;

  /// No description provided for @continueFromDevice.
  ///
  /// In fr, this message translates to:
  /// **'Continuer depuis {remoteDeviceName}'**
  String continueFromDevice(Object remoteDeviceName);

  /// No description provided for @downloadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec du téléchargement'**
  String get downloadFailed;

  /// No description provided for @convertingHdCbz.
  ///
  /// In fr, this message translates to:
  /// **'Conversion HD en CBZ (Mode BD)...'**
  String get convertingHdCbz;

  /// No description provided for @downloadingYourComic.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement de votre BD...'**
  String get downloadingYourComic;

  /// No description provided for @networkErrorOccurred.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur réseau est survenue.'**
  String get networkErrorOccurred;

  /// No description provided for @convertingHdInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Conversion HD en cours...'**
  String get convertingHdInProgress;

  /// No description provided for @deleteFromDeviceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer de l\'appareil ?'**
  String get deleteFromDeviceTitle;

  /// No description provided for @deleteDownloadedFileBody.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous supprimer le fichier téléchargé en local de \"{name}\" pour libérer de l\'espace ?\n\nLe fichier reste toujours accessible et téléchargeable depuis votre serveur.'**
  String deleteDownloadedFileBody(Object name);

  /// No description provided for @deletedFromDevice.
  ///
  /// In fr, this message translates to:
  /// **'\"{name}\" a été supprimé de votre tablette.'**
  String deletedFromDevice(Object name);

  /// No description provided for @deleteLocalCopy.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer du local'**
  String get deleteLocalCopy;

  /// No description provided for @downloadForOffline.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger pour lecture hors-ligne'**
  String get downloadForOffline;

  /// No description provided for @updateAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour disponible !'**
  String get updateAvailable;

  /// No description provided for @whatsNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouveautés & Changements :'**
  String get whatsNew;

  /// No description provided for @defaultReleaseNotes.
  ///
  /// In fr, this message translates to:
  /// **'Améliorations de performances et corrections de bugs.'**
  String get defaultReleaseNotes;

  /// No description provided for @downloadApk.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger APK'**
  String get downloadApk;

  /// No description provided for @almostDone.
  ///
  /// In fr, this message translates to:
  /// **'Presque terminé...'**
  String get almostDone;

  /// No description provided for @secondsLeft.
  ///
  /// In fr, this message translates to:
  /// **'~ {seconds} s restantes'**
  String secondsLeft(Object seconds);

  /// No description provided for @itemsCount.
  ///
  /// In fr, this message translates to:
  /// **'{itemCount} éléments'**
  String itemsCount(Object itemCount);

  /// No description provided for @readOfTotal.
  ///
  /// In fr, this message translates to:
  /// **'{completedBooks}/{totalBooks} lu(s)'**
  String readOfTotal(Object completedBooks, Object totalBooks);

  /// No description provided for @emptyServerResponse.
  ///
  /// In fr, this message translates to:
  /// **'Réponse vide du serveur'**
  String get emptyServerResponse;

  /// No description provided for @chapterN.
  ///
  /// In fr, this message translates to:
  /// **'Chapitre {length1}'**
  String chapterN(Object length1);

  /// No description provided for @chapterNIdx.
  ///
  /// In fr, this message translates to:
  /// **'Chapitre {idx1}'**
  String chapterNIdx(Object idx1);

  /// No description provided for @pdfNotFoundOnDevice.
  ///
  /// In fr, this message translates to:
  /// **'Fichier PDF introuvable sur l\'appareil.'**
  String get pdfNotFoundOnDevice;

  /// No description provided for @convertToCbzComicMode.
  ///
  /// In fr, this message translates to:
  /// **'Convertir en CBZ (Mode BD)'**
  String get convertToCbzComicMode;

  /// No description provided for @pressAgainToExit.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez à nouveau pour quitter ComicStream'**
  String get pressAgainToExit;

  /// No description provided for @downloadsTabShort.
  ///
  /// In fr, this message translates to:
  /// **'Télécharg.'**
  String get downloadsTabShort;

  /// No description provided for @settingsTab.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settingsTab;

  /// No description provided for @invalidJsonFormat.
  ///
  /// In fr, this message translates to:
  /// **'Format JSON invalide'**
  String get invalidJsonFormat;

  /// No description provided for @cannotLoadFolder.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le dossier: {e}'**
  String cannotLoadFolder(Object e);

  /// No description provided for @newUpdateAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle mise à jour disponible.'**
  String get newUpdateAvailable;

  /// No description provided for @unknownEncryptionVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version de chiffrement inconnue'**
  String get unknownEncryptionVersion;

  /// No description provided for @speedMb.
  ///
  /// In fr, this message translates to:
  /// **'{value} Mo/s'**
  String speedMb(Object value);

  /// No description provided for @speedKb.
  ///
  /// In fr, this message translates to:
  /// **'{value} Ko/s'**
  String speedKb(Object value);

  /// No description provided for @minutesSecondsLeft.
  ///
  /// In fr, this message translates to:
  /// **'~ {minutes} min {seconds} s'**
  String minutesSecondsLeft(Object minutes, Object seconds);

  /// No description provided for @volumeCountPlural.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 tome} other{{count} tomes}}'**
  String volumeCountPlural(num count);

  /// No description provided for @chapterSlashPercent.
  ///
  /// In fr, this message translates to:
  /// **'Chapitre {current}/{total} · {percent} %'**
  String chapterSlashPercent(Object current, Object total, Object percent);

  /// No description provided for @labelLocationDate.
  ///
  /// In fr, this message translates to:
  /// **'{label} : {location}\n{date} à {time}'**
  String labelLocationDate(Object label, Object location, Object date, Object time);

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @continueLabel.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueLabel;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @view.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get view;

  /// No description provided for @synchronize.
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser'**
  String get synchronize;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @none.
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get none;

  /// No description provided for @all.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get all;

  /// No description provided for @importAction.
  ///
  /// In fr, this message translates to:
  /// **'Importer'**
  String get importAction;

  /// No description provided for @everyone.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get everyone;

  /// No description provided for @clean.
  ///
  /// In fr, this message translates to:
  /// **'Nettoyer'**
  String get clean;

  /// No description provided for @read.
  ///
  /// In fr, this message translates to:
  /// **'Lire'**
  String get read;

  /// No description provided for @dark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get dark;

  /// No description provided for @mint.
  ///
  /// In fr, this message translates to:
  /// **'Menthe'**
  String get mint;

  /// No description provided for @light.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get light;

  /// No description provided for @standard.
  ///
  /// In fr, this message translates to:
  /// **'Standard'**
  String get standard;

  /// No description provided for @large.
  ///
  /// In fr, this message translates to:
  /// **'Large'**
  String get large;

  /// No description provided for @libraryTab.
  ///
  /// In fr, this message translates to:
  /// **'Biblio'**
  String get libraryTab;

  /// No description provided for @serverTab.
  ///
  /// In fr, this message translates to:
  /// **'Serveur'**
  String get serverTab;

  /// No description provided for @filesTab.
  ///
  /// In fr, this message translates to:
  /// **'Fichiers'**
  String get filesTab;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @resume.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get resume;

  /// No description provided for @progress.
  ///
  /// In fr, this message translates to:
  /// **'Progression'**
  String get progress;

  /// No description provided for @favorites.
  ///
  /// In fr, this message translates to:
  /// **'Favoris'**
  String get favorites;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @options.
  ///
  /// In fr, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @refresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get refresh;

  /// No description provided for @root.
  ///
  /// In fr, this message translates to:
  /// **'Racine'**
  String get root;

  /// No description provided for @empty.
  ///
  /// In fr, this message translates to:
  /// **'Vider'**
  String get empty;

  /// No description provided for @font.
  ///
  /// In fr, this message translates to:
  /// **'Police'**
  String get font;

  /// No description provided for @lineSpacing.
  ///
  /// In fr, this message translates to:
  /// **'Interligne'**
  String get lineSpacing;

  /// No description provided for @compact.
  ///
  /// In fr, this message translates to:
  /// **'Compact'**
  String get compact;

  /// No description provided for @normal.
  ///
  /// In fr, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @relaxed.
  ///
  /// In fr, this message translates to:
  /// **'Relaxed'**
  String get relaxed;

  /// No description provided for @margin.
  ///
  /// In fr, this message translates to:
  /// **'Marge'**
  String get margin;

  /// No description provided for @narrowShort.
  ///
  /// In fr, this message translates to:
  /// **'Etroit'**
  String get narrowShort;

  /// No description provided for @yesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get yesterday;

  /// No description provided for @today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get today;

  /// No description provided for @folder.
  ///
  /// In fr, this message translates to:
  /// **'Dossier'**
  String get folder;

  /// No description provided for @convert.
  ///
  /// In fr, this message translates to:
  /// **'Convertir'**
  String get convert;

  /// No description provided for @width.
  ///
  /// In fr, this message translates to:
  /// **'Largeur'**
  String get width;

  /// No description provided for @height.
  ///
  /// In fr, this message translates to:
  /// **'Hauteur'**
  String get height;

  /// No description provided for @black.
  ///
  /// In fr, this message translates to:
  /// **'Noir'**
  String get black;

  /// No description provided for @grey.
  ///
  /// In fr, this message translates to:
  /// **'Gris'**
  String get grey;

  /// No description provided for @white.
  ///
  /// In fr, this message translates to:
  /// **'Blanc'**
  String get white;

  /// No description provided for @downloaded.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargé'**
  String get downloaded;

  /// No description provided for @serverDefaultName.
  ///
  /// In fr, this message translates to:
  /// **'Serveur'**
  String get serverDefaultName;

  /// No description provided for @test.
  ///
  /// In fr, this message translates to:
  /// **'Tester'**
  String get test;

  /// No description provided for @type.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @port.
  ///
  /// In fr, this message translates to:
  /// **'Port'**
  String get port;

  /// No description provided for @path.
  ///
  /// In fr, this message translates to:
  /// **'Chemin'**
  String get path;

  /// No description provided for @credentials.
  ///
  /// In fr, this message translates to:
  /// **'Identifiants'**
  String get credentials;

  /// No description provided for @ignore.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer'**
  String get ignore;

  /// No description provided for @noneLower.
  ///
  /// In fr, this message translates to:
  /// **'aucun'**
  String get noneLower;

  /// No description provided for @serverUpper.
  ///
  /// In fr, this message translates to:
  /// **'SERVEUR'**
  String get serverUpper;

  /// No description provided for @bookUpper.
  ///
  /// In fr, this message translates to:
  /// **'LIVRE'**
  String get bookUpper;

  /// No description provided for @resumeUpper.
  ///
  /// In fr, this message translates to:
  /// **'REPRENDRE'**
  String get resumeUpper;

  /// No description provided for @currentUpper.
  ///
  /// In fr, this message translates to:
  /// **'ACTUEL'**
  String get currentUpper;

  /// No description provided for @lineSpacingUpper.
  ///
  /// In fr, this message translates to:
  /// **'INTERLIGNE'**
  String get lineSpacingUpper;

  /// No description provided for @alignmentUpper.
  ///
  /// In fr, this message translates to:
  /// **'ALIGNEMENT'**
  String get alignmentUpper;

  /// No description provided for @comicsFilter.
  ///
  /// In fr, this message translates to:
  /// **'BD'**
  String get comicsFilter;

  /// No description provided for @navLibrary.
  ///
  /// In fr, this message translates to:
  /// **'Bibliothèque'**
  String get navLibrary;

  /// No description provided for @navServers.
  ///
  /// In fr, this message translates to:
  /// **'Serveurs'**
  String get navServers;

  /// No description provided for @computerFiles.
  ///
  /// In fr, this message translates to:
  /// **'Fichiers de l’ordinateur'**
  String get computerFiles;

  /// No description provided for @addComicsFromComputerBody.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez des BD (CBZ, CBR, PDF, EPUB) ou un dossier entier à analyser. Un double-clic dans l’Explorateur les ouvre aussi directement.'**
  String get addComicsFromComputerBody;

  /// No description provided for @openFiles.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir des fichiers…'**
  String get openFiles;

  /// No description provided for @scanFolder.
  ///
  /// In fr, this message translates to:
  /// **'Analyser un dossier…'**
  String get scanFolder;

  /// No description provided for @columnTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get columnTitle;

  /// No description provided for @columnFormat.
  ///
  /// In fr, this message translates to:
  /// **'Format'**
  String get columnFormat;

  /// No description provided for @columnSize.
  ///
  /// In fr, this message translates to:
  /// **'Taille'**
  String get columnSize;

  /// No description provided for @columnAdded.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté'**
  String get columnAdded;

  /// No description provided for @doublePageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Double page sur grand écran'**
  String get doublePageTitle;

  /// No description provided for @doublePageBody.
  ///
  /// In fr, this message translates to:
  /// **'Deux pages côte à côte quand la fenêtre est large et en paysage'**
  String get doublePageBody;

  /// No description provided for @onePage.
  ///
  /// In fr, this message translates to:
  /// **'1 page'**
  String get onePage;

  /// No description provided for @twoPages.
  ///
  /// In fr, this message translates to:
  /// **'2 pages'**
  String get twoPages;

  /// No description provided for @togglePagesPerView.
  ///
  /// In fr, this message translates to:
  /// **'Afficher 1 ou 2 pages (D)'**
  String get togglePagesPerView;

  /// No description provided for @selectAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout sélectionner'**
  String get selectAll;

  /// No description provided for @clearSelection.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la sélection'**
  String get clearSelection;

  /// No description provided for @moveToSeries.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer vers une série'**
  String get moveToSeries;

  /// No description provided for @seriesNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la série'**
  String get seriesNameLabel;

  /// No description provided for @automaticSeries.
  ///
  /// In fr, this message translates to:
  /// **'Série automatique'**
  String get automaticSeries;

  /// No description provided for @move.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer'**
  String get move;

  /// No description provided for @deleteSelectedTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Supprimer 1 livre ?} other{Supprimer {count} livres ?}}'**
  String deleteSelectedTitle(int count);

  /// No description provided for @deleteSelectedBody.
  ///
  /// In fr, this message translates to:
  /// **'Les fichiers seront supprimés de cet appareil. Ceux de tes serveurs ne sont pas touchés.'**
  String get deleteSelectedBody;

  /// No description provided for @librarySelectionCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 sélectionné} other{{count} sélectionnés}}'**
  String librarySelectionCount(int count);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'es', 'fr', 'it', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
    case 'it': return AppLocalizationsIt();
    case 'pt': return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
