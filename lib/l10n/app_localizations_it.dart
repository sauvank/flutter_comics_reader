import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get resetVaultTitle => 'Reimpostare la cassaforte?';

  @override
  String get resetVaultBody => 'Se hai perso la frase di recupero, la reimpostazione creerà una nuova cassaforte vuota. I dati protetti degli altri dispositivi dovranno essere sincronizzati di nuovo.';

  @override
  String get reset => 'Reimposta';

  @override
  String get confirmSecretPhrase => 'Conferma la frase segreta';

  @override
  String get secretPhraseWrittenDownBody => 'Hai annotato la tua frase segreta in un luogo sicuro?\n\nÈ indispensabile per ripristinare i tuoi dati o sincronizzare un nuovo dispositivo. ComicStream non la conserva e non potrà mai recuperarla per te.';

  @override
  String get yourSecretPhrase => 'La tua frase segreta:';

  @override
  String get phraseNotedContinue => 'L\'ho annotata, continua';

  @override
  String get changeSecretPhrase => 'Cambia la frase segreta';

  @override
  String get changeSecretPhraseBody => 'Imposta una nuova frase segreta (almeno 16 caratteri) per proteggere la sincronizzazione.';

  @override
  String get newSecretPhrase => 'Nuova frase segreta';

  @override
  String get min16Characters => 'Almeno 16 caratteri';

  @override
  String get showPhrase => 'Mostra la frase';

  @override
  String get hidePhrase => 'Nascondi la frase';

  @override
  String get confirmNewPhrase => 'Conferma la nuova frase';

  @override
  String get phraseTooShort => 'La frase deve contenere almeno 16 caratteri.';

  @override
  String get phrasesDoNotMatch => 'Le due frasi non corrispondono.';

  @override
  String get confirmChangeTitle => 'Confermare la modifica?';

  @override
  String get confirmChangeBody => 'La tua cassaforte verrà aggiornata con questa nuova frase segreta.\nAssicurati di averla annotata:';

  @override
  String get confirmAndSave => 'Conferma e salva';

  @override
  String get secretPhraseUpdated => 'Frase segreta aggiornata correttamente.';

  @override
  String get operationDone => 'Operazione completata.';

  @override
  String cannotContinue(Object error) {
    return 'Impossibile continuare: $error';
  }

  @override
  String dateAtTime(Object date, Object time) {
    return '$date alle $time';
  }

  @override
  String get syncConflict => 'Conflitto di sincronizzazione';

  @override
  String syncConflictBody(Object label) {
    return 'Sono state modificate due versioni di «$label».';
  }

  @override
  String thisDeviceValue(Object formatConflictDate) {
    return 'Questo dispositivo: $formatConflictDate';
  }

  @override
  String syncServerValue(Object formatConflictDate) {
    return 'Server di sincronizzazione: $formatConflictDate';
  }

  @override
  String thisDeviceSummary(Object localSummary) {
    return 'Questo dispositivo: $localSummary';
  }

  @override
  String serverSummary(Object remoteSummary) {
    return 'Server: $remoteSummary';
  }

  @override
  String get chooseReferenceVersion => 'Scegli la versione di riferimento. Verrà poi sincronizzata sugli altri dispositivi.';

  @override
  String get fetchFromServer => 'Recupera dal server';

  @override
  String get sendToServer => 'Invia al server';

  @override
  String get later => 'Più tardi';

  @override
  String get thisDeviceName => 'Nome di questo dispositivo';

  @override
  String get deviceNameHint => 'Es. Tablet o Telefono';

  @override
  String get deviceNameSavedOnServer => 'Nome del dispositivo salvato sul server.';

  @override
  String get deviceNameSavedLocally => 'Nome salvato su questo dispositivo. Verrà inviato alla prossima sincronizzazione.';

  @override
  String cannotPrepareSync(Object error) {
    return 'Impossibile preparare la sincronizzazione: $error';
  }

  @override
  String get whichBackupToUse => 'Quale backup usare?';

  @override
  String get whichBackupBody => 'La tua scelta diventa il riferimento condiviso. Gli altri dispositivi la riceveranno alla prossima sincronizzazione.';

  @override
  String get notBackedUpYet => 'Nessun backup ancora';

  @override
  String backedUpAt(Object formatConflictDate) {
    return 'Backup del $formatConflictDate';
  }

  @override
  String get accountAndSync => 'Account e sincronizzazione';

  @override
  String get syncUnavailableNoFirebase => 'La sincronizzazione sarà disponibile dopo la configurazione del progetto Firebase. Il lettore e i tuoi dati locali continuano a funzionare normalmente.';

  @override
  String get accountConnected => 'Accesso effettuato';

  @override
  String get vaultUnlockedE2e => 'Cassaforte sbloccata. I tuoi dati sono crittografati end-to-end.';

  @override
  String get vaultLockedOrNew => 'Cassaforte bloccata o non inizializzata.';

  @override
  String get unlockVault => 'Sblocca la cassaforte';

  @override
  String get initEncryptedVault => 'Crea la tua cassaforte crittografata';

  @override
  String get unlockVaultBody => 'A questo account è associata una cassaforte crittografata. Inserisci la frase di recupero per sbloccare la sincronizzazione su questo dispositivo.';

  @override
  String get initVaultBody => 'Per proteggere le password dei server e i tuoi dati, scegli una frase segreta (almeno 16 caratteri). È indispensabile per ripristinare i dati su un nuovo dispositivo.';

  @override
  String get recoveryPhrase => 'Frase di recupero';

  @override
  String get secretPhraseMin16 => 'Frase segreta (almeno 16 caratteri)';

  @override
  String get enterRecoveryPhrase => 'Inserisci la frase di recupero.';

  @override
  String get secretPhraseTooShort => 'La frase segreta deve contenere almeno 16 caratteri.';

  @override
  String get secretPhrasesDoNotMatch => 'Le frasi segrete non corrispondono.';

  @override
  String get unlockSync => 'Sblocca la sincronizzazione';

  @override
  String get createAndEnableVault => 'Crea e attiva la cassaforte';

  @override
  String get forgotPhraseReset => 'Frase dimenticata? Reimposta la cassaforte';

  @override
  String get vaultUnlocked => 'Cassaforte sbloccata';

  @override
  String get syncActiveE2e => 'La sincronizzazione è attiva e protetta da crittografia end-to-end.';

  @override
  String get syncing => 'Sincronizzazione…';

  @override
  String get changePhrase => 'Cambia la frase';

  @override
  String get shownWhenChoosingBackup => 'Mostrato quando si sceglie un backup';

  @override
  String get signOut => 'Esci';

  @override
  String get createAccount => 'Crea un account';

  @override
  String get signIn => 'Accedi';

  @override
  String get passwordMin12 => 'Password (almeno 12 caratteri)';

  @override
  String get showPassword => 'Mostra la password';

  @override
  String get hidePassword => 'Nascondi la password';

  @override
  String get createTheAccount => 'Crea l\'account';

  @override
  String get alreadyHaveAccount => 'Ho già un account';

  @override
  String get continueWithGoogle => 'Continua con Google';

  @override
  String get recoveryPhraseRequiredNote => 'La frase di recupero è indispensabile per ripristinare le password dei server su un nuovo dispositivo. ComicStream non la salva mai.';

  @override
  String androidCertNotAllowed(Object hashes) {
    return 'Certificato Android non autorizzato: $hashes';
  }

  @override
  String pendingConflicts(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifiche attendono la tua scelta.',
      one: '1 modifica attende la tua scelta.',
    );
    return '$_temp0';
  }

  @override
  String upToDate(Object fullVersion) {
    return 'ComicStream è aggiornato ($fullVersion)!';
  }

  @override
  String get updateCheckError => 'Errore durante la verifica degli aggiornamenti';

  @override
  String get clearCacheTitle => 'Svuotare la cache?';

  @override
  String get clearCacheBody => 'Le copertine verranno ricaricate automaticamente.';

  @override
  String get coverCacheCleared => 'Cache delle copertine svuotata!';

  @override
  String get deleteAllTitle => 'Eliminare tutto?';

  @override
  String get deleteAllBody => 'Verranno eliminati tutti i fumetti e manga scaricati in locale per liberare spazio. Le impostazioni dei server verranno conservate.';

  @override
  String get allLocalFilesDeleted => 'Tutti i file locali sono stati eliminati.';

  @override
  String get eraseAll => 'Cancella tutto';

  @override
  String get commandCopied => 'Comando copiato!';

  @override
  String get localServerGuide => 'Guida al server locale';

  @override
  String get guideOption1 => 'Opzione 1: server WebDAV con Docker (consigliato)';

  @override
  String get guideOption1Body => 'Avvia un server WebDAV leggero con Docker in una sola riga, puntando alla cartella dei tuoi fumetti:';

  @override
  String get guideOption2 => 'Opzione 2: script Python pronto all\'uso';

  @override
  String get guideOption2Body => 'Un server Python dedicato è disponibile in `server_example/comic_server.py`. Per avviarlo:';

  @override
  String get guideOption3 => 'Opzione 3: NAS Synology / TrueNAS / Nextcloud';

  @override
  String get guideOption3Body => 'Attiva il servizio WebDAV nel pannello di amministrazione del tuo NAS (porta 5005 predefinita su Synology) e inserisci le credenziali nell\'app.';

  @override
  String get settings => 'Impostazioni';

  @override
  String get accountAndSyncShort => 'Account e sincronizzazione';

  @override
  String get accountAndSyncSubtitle => 'Server, progressi e impostazioni crittografati';

  @override
  String get appearanceTheme => 'Aspetto e tema';

  @override
  String get appTheme => 'Tema dell\'app';

  @override
  String get readerPreferences => 'Preferenze del lettore';

  @override
  String get defaultReadingMode => 'Modalità di lettura predefinita';

  @override
  String get readingModeComic => 'Fumetto (da sinistra a destra)';

  @override
  String get readingModeManga => 'Manga (da destra a sinistra)';

  @override
  String get readingModeWebtoon => 'Webtoon (scorrimento verticale)';

  @override
  String get keepScreenOn => 'Mantieni lo schermo acceso durante la lettura';

  @override
  String get showPageNumber => 'Mostra il numero di pagina';

  @override
  String get autoConvertPdf => 'Converti automaticamente i PDF in CBZ';

  @override
  String get autoConvertPdfBody => 'Trasforma ogni PDF scaricato in un archivio fumetto fluidissimo per tablet.';

  @override
  String get comicRenderQuality => 'Qualità di rendering dei fumetti';

  @override
  String get qualityAutoLong => 'Automatica (rileva lo schermo + 35% di nitidezza)';

  @override
  String get qualitySuperLong => 'Supercampionata (2600px - zoom nitido)';

  @override
  String get qualityUltraLong => 'Ultra HD (3500px - definizione massima)';

  @override
  String get qualityStandardLong => 'Standard 1:1 (1900px - veloce)';

  @override
  String get qualityAuto => 'Auto (schermo + 35%)';

  @override
  String get qualityHigh => 'Alta (2600px)';

  @override
  String get qualityStandard => 'Standard 1:1';

  @override
  String get ebooksEpub => 'E-book ed EPUB';

  @override
  String get fontSize => 'Dimensione del carattere';

  @override
  String get justifiedText => 'Testo giustificato';

  @override
  String get storageCache => 'Archiviazione e cache';

  @override
  String get spaceUsedByBooks => 'Spazio occupato dai libri:';

  @override
  String booksDownloadedCount(Object length) {
    return '$length libro/i scaricato/i';
  }

  @override
  String get clearCache => 'Svuota cache';

  @override
  String get updates => 'Aggiornamenti';

  @override
  String get checkForUpdate => 'Cerca aggiornamenti';

  @override
  String installedVersion(Object fullVersion) {
    return 'Versione installata: $fullVersion';
  }

  @override
  String get check => 'Verifica';

  @override
  String get seeStoreListing => 'Vedi la scheda ufficiale di ComicStream';

  @override
  String get helpSetup => 'Aiuto e configurazione';

  @override
  String get howToSetupLocalServer => 'Come configuro il mio server locale?';

  @override
  String get helpSetupSubtitle => 'Docker, Python, NAS Synology, TrueNAS...';

  @override
  String get appTagline => 'Lettore cloud di fumetti e manga';

  @override
  String get deleteBookTitle => 'Eliminare questo libro?';

  @override
  String deleteBookBody(Object title) {
    return 'Vuoi eliminare \"$title\" dalla memoria locale?';
  }

  @override
  String resumeAtChapter(Object title, Object currentPage1) {
    return '«$title» era già iniziato. Riprendere dal capitolo $currentPage1?';
  }

  @override
  String resumeAtPage(Object title, Object currentPage1) {
    return '«$title» era già iniziato. Riprendere da pagina $currentPage1?';
  }

  @override
  String get myLibrary => 'La mia libreria';

  @override
  String comicsCount(Object length) {
    return '$length fumetti';
  }

  @override
  String get syncInProgress => 'Sincronizzazione in corso';

  @override
  String get sortBy => 'Ordina per';

  @override
  String get lastRead => 'Ultima lettura';

  @override
  String get titleAz => 'Titolo (A-Z)';

  @override
  String get dateAdded => 'Data di aggiunta';

  @override
  String seriesCount(Object length) {
    return 'Serie ($length)';
  }

  @override
  String volumesCount(Object length) {
    return 'Volumi ($length)';
  }

  @override
  String get searchLibraryHint => 'Cerca una serie, un volume, un autore...';

  @override
  String get recentlyOpened => 'Aperti di recente';

  @override
  String myCollectionsCount(Object length) {
    return 'Le mie collezioni e serie ($length)';
  }

  @override
  String get backToSeries => 'Torna alle serie';

  @override
  String seriesProgress(Object completedBooks, Object totalBooks, Object progressPercent) {
    return '$completedBooks/$totalBooks volumi letti • $progressPercent%';
  }

  @override
  String get checkNewVolumes => 'Cerca nuovi volumi sul server';

  @override
  String get nextVolumeToRead => 'PROSSIMO VOLUME DA LEGGERE';

  @override
  String get nextVolumeOnServer => 'PROSSIMO VOLUME SUL SERVER';

  @override
  String get download => 'Scarica';

  @override
  String downloadStarted(Object name) {
    return '📥 Download avviato: $name';
  }

  @override
  String get readNow => 'Leggi subito';

  @override
  String get searchingNextVolumes => 'Ricerca dei volumi successivi sul server remoto...';

  @override
  String downloadedVolumesCount(Object totalBooks) {
    return 'Volumi scaricati ($totalBooks)';
  }

  @override
  String serverVolumesCount(Object length) {
    return 'Volumi disponibili sul server ($length)';
  }

  @override
  String downloadAllCount(Object length) {
    return 'Scarica tutto ($length)';
  }

  @override
  String volumesQueued(Object length) {
    return '📥 $length volumi aggiunti alla coda di download';
  }

  @override
  String downloadingName(Object name) {
    return '📥 Download: $name';
  }

  @override
  String get libraryFilters => 'Filtri della libreria';

  @override
  String allCount(Object length) {
    return 'Tutti ($length)';
  }

  @override
  String get inProgress => 'In corso';

  @override
  String get unread => 'Non letti';

  @override
  String get epubNovels => 'EPUB / Romanzi';

  @override
  String get finished => 'Finiti';

  @override
  String get continueReading => 'CONTINUA A LEGGERE';

  @override
  String get libraryEmpty => 'La tua libreria è vuota';

  @override
  String get libraryEmptyBody => 'Aggiungi fumetti da un server o dai file già presenti sul telefono.';

  @override
  String get exploreServers => 'Esplora i miei server';

  @override
  String get importFromPhone => 'Importa da questo telefono';

  @override
  String get noSearchResults => 'Nessun risultato per questa ricerca';

  @override
  String get noSearchResultsBody => 'Prova un\'altra parola chiave o reimposta i filtri.';

  @override
  String chapterProgressPercent(Object current, Object total, Object percent) {
    return 'Capitolo $current/$total ($percent%)';
  }

  @override
  String pageProgressPercent(Object current, Object total, Object percent) {
    return 'Pagina $current/$total ($percent%)';
  }

  @override
  String chapterOfTotal(Object current, Object total) {
    return 'Capitolo $current di $total';
  }

  @override
  String pageOfTotal(Object current, Object total) {
    return 'Pagina $current di $total';
  }

  @override
  String get setupServer => 'Configura un server';

  @override
  String connectionSucceeded(Object name) {
    return 'Connesso a $name!';
  }

  @override
  String connectionFailed(Object name) {
    return 'Connessione a $name non riuscita';
  }

  @override
  String get deleteServerTitle => 'Eliminare questo server?';

  @override
  String deleteServerBody(Object name) {
    return 'Vuoi davvero eliminare \"$name\" dalle tue fonti remote?';
  }

  @override
  String get exportConfiguration => 'Esporta la configurazione';

  @override
  String get exportConfigurationBody => 'Ecco il file di configurazione JSON con i tuoi profili server:';

  @override
  String get copyJson => 'Copia JSON';

  @override
  String get configurationCopied => '✅ Configurazione copiata negli appunti!';

  @override
  String get importConfiguration => 'Importa una configurazione';

  @override
  String get chooseJsonFile => 'Scegli un file .json';

  @override
  String fileReadError(Object e) {
    return 'Errore durante la lettura del file: $e';
  }

  @override
  String get orPasteJson => 'Oppure incolla il JSON qui:';

  @override
  String serversImported(Object count) {
    return '✅ $count server importato/i correttamente!';
  }

  @override
  String baseLocationSet(Object currentPath) {
    return '✅ Posizione di base impostata su: $currentPath';
  }

  @override
  String get myServers => 'I miei server';

  @override
  String get addServer => 'Aggiungi un server';

  @override
  String get howToSetupServer => 'Come configurare un server';

  @override
  String get exportConfigurations => 'Esporta le configurazioni';

  @override
  String get testConnection => 'Prova la connessione';

  @override
  String get filterFolderHint => 'Filtra questa cartella...';

  @override
  String get closeSearch => 'Chiudi la ricerca';

  @override
  String get folderOptions => 'Opzioni della cartella';

  @override
  String get setFolderAsRoot => 'Imposta questa cartella come radice';

  @override
  String get switchServer => 'Cambia server';

  @override
  String get parentFolder => 'Cartella superiore';

  @override
  String everythingCount(Object length) {
    return 'Tutto ($length)';
  }

  @override
  String get downloadAllTitle => 'Scaricare tutto?';

  @override
  String downloadAllBody(Object length) {
    return '$length volumi verranno scaricati in background.';
  }

  @override
  String volumesQueuedCount(Object length) {
    return '📥 $length volume/i aggiunto/i alla coda di download';
  }

  @override
  String foldersSeriesCount(Object length) {
    return 'Cartelle e serie ($length)';
  }

  @override
  String booksComicsCount(Object length) {
    return 'Libri e fumetti ($length)';
  }

  @override
  String downloadingNamePlain(Object name) {
    return 'Download: $name';
  }

  @override
  String get folderEmpty => 'Questa cartella è vuota';

  @override
  String get folderEmptyBody => 'Nessun libro o sottocartella trovato in questa posizione.';

  @override
  String get cannotConnectServer => 'Impossibile connettersi al server';

  @override
  String checkServerReachable(Object baseUrl) {
    return 'Verifica che il server sia raggiungibile su $baseUrl.';
  }

  @override
  String get editSettings => 'Modifica le impostazioni';

  @override
  String get retry => 'Riprova';

  @override
  String get googleTokenMissing => 'Token di autenticazione Google non trovato.';

  @override
  String get googleSignInUnavailable => 'L\'accesso con Google non è disponibile su questo dispositivo.';

  @override
  String get recoveryPhraseTooShort => 'La frase di recupero deve contenere almeno 16 caratteri.';

  @override
  String get signInRequired => 'Accesso richiesto';

  @override
  String get noSyncVaultFound => 'Nessuna cassaforte di sincronizzazione trovata.';

  @override
  String get vaultMustBeUnlocked => 'La cassaforte deve essere sbloccata per cambiare la frase segreta.';

  @override
  String get recoveryPhraseRequiredHere => 'Frase di recupero richiesta su questo dispositivo.';

  @override
  String get serverConfigurations => 'Configurazioni dei server';

  @override
  String get readingSettings => 'Impostazioni di lettura';

  @override
  String get deviceNameLength => 'Il nome deve contenere da 1 a 40 caratteri.';

  @override
  String deviceDefaultName(Object substring) {
    return 'Dispositivo $substring';
  }

  @override
  String get otherDevice => 'Altro dispositivo';

  @override
  String get remoteProgressGone => 'Questo progresso remoto non esiste più.';

  @override
  String thisDeviceNamed(Object currentName) {
    return 'Questo dispositivo — $currentName';
  }

  @override
  String get deviceBackupNotFound => 'Backup di questo dispositivo non trovato.';

  @override
  String get googleDataNotFound => 'Dati Google da risolvere non trovati.';

  @override
  String get localProgressGone => 'Il progresso locale corrispondente non esiste più.';

  @override
  String get unknownSyncDocument => 'Documento di sincronizzazione sconosciuto';

  @override
  String get readingSettingsShort => 'Impostazioni di lettura';

  @override
  String get yes => 'sì';

  @override
  String get no => 'no';

  @override
  String chapterSlash(Object current, Object total) {
    return 'Capitolo $current/$total';
  }

  @override
  String pageSlash(Object current, Object total) {
    return 'Pagina $current/$total';
  }

  @override
  String progressSummary(Object location, Object favorite, Object bookmarks) {
    return '$location · Preferito: $favorite · $bookmarks';
  }

  @override
  String bookmarksCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count segnalibri',
      one: '1 segnalibro',
      zero: '0 segnalibri',
    );
    return '$_temp0';
  }

  @override
  String serverProfilesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count profili server',
      one: '1 profilo server',
      zero: '0 profili server',
    );
    return '$_temp0';
  }

  @override
  String ftpInvalidServer(Object banner) {
    return 'Server FTP non valido: $banner';
  }

  @override
  String ftpCredentialsRefused(Object passResp) {
    return 'Credenziali FTP rifiutate: $passResp';
  }

  @override
  String ftpUsernameRefused(Object userResp) {
    return 'Nome utente FTP rifiutato: $userResp';
  }

  @override
  String ftpPassiveFailed(Object pasvResp) {
    return 'Modalità passiva FTP non riuscita: $pasvResp';
  }

  @override
  String ftpDownloadFailed(Object retrResp) {
    return 'Impossibile scaricare il file FTP: $retrResp';
  }

  @override
  String get ftpIdleTimeout => 'Timeout di inattività FTP superato';

  @override
  String ftpPasvUnrecognized(Object response) {
    return 'Risposta PASV non riconosciuta: $response';
  }

  @override
  String get guideHeroTitle => 'Leggi i fumetti del tuo computer o NAS';

  @override
  String get guideHeroBody => 'Un server rende la tua collezione accessibile dal telefono senza copiare tutto. Servono circa 2 minuti.';

  @override
  String get howItWorks => 'Come fare';

  @override
  String get guideStep1Title => 'Condividi la cartella dei fumetti';

  @override
  String get guideStep1Body => 'Sul NAS o sul computer, attiva una condivisione WebDAV, FTP o HTTP che punti alla cartella con i tuoi file CBZ, CBR, PDF o EPUB. Gli esempi qui sotto descrivono ogni caso.';

  @override
  String get guideStep2Title => 'Annota il suo indirizzo';

  @override
  String get guideStep2Body => 'Trova l\'indirizzo IP locale della macchina (es. 192.168.1.100) e la porta della condivisione. Il telefono deve essere connesso alla stessa rete Wi-Fi.';

  @override
  String get guideStep3Title => 'Compila il modulo';

  @override
  String get guideStep3Body => 'Tocca «Aggiungi un server», scegli il tipo, poi inserisci host, porta, percorso della cartella e, se serve, nome utente e password.';

  @override
  String get guideStep4Title => 'Prova e salva';

  @override
  String get guideStep4Body => '«Prova» verifica la connessione. Una volta riuscita, «Salva» apre direttamente il server per sfogliare e scaricare i tuoi libri.';

  @override
  String get configurationExamples => 'Esempi di configurazione';

  @override
  String get webdavSubtitle => 'Consigliato · NAS Synology, QNAP, Nextcloud';

  @override
  String get host => 'Host';

  @override
  String get webdavPorts => '5005 (Synology), 80 o 443';

  @override
  String get webdavCredentials => 'quelle del tuo account NAS';

  @override
  String get webdavTip => 'Su Synology: installa «WebDAV Server» dal Centro pacchetti e attiva HTTP o HTTPS.';

  @override
  String get httpSubtitle => 'La soluzione più semplice da un computer';

  @override
  String get computerIp => 'IP del computer';

  @override
  String get httpTip => 'Nella cartella dei fumetti, esegui «python3 -m http.server 8080» oppure lo script server_example/comic_server.py fornito con ComicStream.';

  @override
  String get ftpSubtitle => 'Router, NAS meno recenti';

  @override
  String get ftpCredentials => 'account FTP del router o del NAS';

  @override
  String get ftpTip => 'FTP non è crittografato: usalo solo sulla rete di casa.';

  @override
  String get cannotConnectTitle => 'Non si connette?';

  @override
  String get tipSameWifi => 'Verifica che telefono e server siano sulla stessa Wi-Fi.';

  @override
  String get tipUseIp => 'Prova l\'indirizzo IP invece di un nome (nas.local).';

  @override
  String get tipFirewall => 'Verifica che il firewall del computer consenta la porta scelta.';

  @override
  String get tipVpn => 'Fuori casa, usa una VPN (WireGuard, Tailscale…) invece di esporre il server su Internet.';

  @override
  String get importExistingConfiguration => 'Importa una configurazione esistente';

  @override
  String get waiting => 'In attesa...';

  @override
  String get downloadingEllipsis => 'Download in corso...';

  @override
  String get cancelled => 'Annullato';

  @override
  String get extractingFinalizing => 'Estrazione e completamento...';

  @override
  String get convertingHd => 'Conversione in fumetto HD...';

  @override
  String secondsRemaining(Object approxSec) {
    return ' ~ ${approxSec}s rimanenti';
  }

  @override
  String convertingHdProgress(Object currentPage, Object totalPages, Object etaText) {
    return 'Conversione HD ($currentPage/$totalPages pagine)$etaText';
  }

  @override
  String get finishedStatus => 'Completato';

  @override
  String get failed => 'Non riuscito';

  @override
  String get networkTimeout => 'Tempo scaduto (timeout di rete)';

  @override
  String get invalidCertificate => 'Certificato di sicurezza non valido (server autofirmato?)';

  @override
  String get fileNotFound404 => 'File non trovato sul server (404)';

  @override
  String get accessDenied => 'Accesso negato (credenziali errate)';

  @override
  String get cannotReachServerLost => 'Impossibile raggiungere il server (connessione persa)';

  @override
  String get downloadCancelled => 'Download annullato';

  @override
  String get networkInterrupted => 'Connessione di rete interrotta';

  @override
  String get notEnoughStorage => 'Spazio di archiviazione insufficiente sul dispositivo';

  @override
  String get networkError => 'Errore di connessione di rete';

  @override
  String get localFileAccessError => 'Errore di accesso al file locale';

  @override
  String get serverError => 'Errore del server';

  @override
  String serverErrorCode(Object code) {
    return 'Errore del server ($code)';
  }

  @override
  String get endOfBookReached => 'Sei arrivato alla fine del libro!';

  @override
  String get loadingBook => 'Caricamento del libro...';

  @override
  String get cannotLoadBook => 'Impossibile caricare questo libro';

  @override
  String get fileMaybeCorrupted => 'Il file potrebbe essere danneggiato o in un formato non supportato.';

  @override
  String get backToLibrary => 'Torna alla libreria';

  @override
  String epubProgressShort(Object value, Object currentChapterIndex1, Object length) {
    return '$value% • Cap. $currentChapterIndex1/$length';
  }

  @override
  String get tableOfContents => 'Indice';

  @override
  String get customizeReading => 'Personalizza la lettura';

  @override
  String chapterXOfY(Object currentChapterIndex1, Object length) {
    return 'Capitolo $currentChapterIndex1 / $length';
  }

  @override
  String endOfChapter(Object currentChapterIndex1) {
    return 'Fine del capitolo $currentChapterIndex1';
  }

  @override
  String get nextChapterUpper => 'CAPITOLO SUCCESSIVO';

  @override
  String get bookFinished => 'Hai finito questo libro!';

  @override
  String get tableOfContentsTitle => 'Indice';

  @override
  String get searchChapterHint => 'Cerca un capitolo...';

  @override
  String noChapterFound(Object tocSearchQuery) {
    return 'Nessun capitolo trovato per \"$tocSearchQuery\"';
  }

  @override
  String get bookCustomization => 'Personalizzazione del libro';

  @override
  String get themeColorsUpper => 'TEMA E COLORI';

  @override
  String get sepia => 'Seppia';

  @override
  String get textSizeUpper => 'DIMENSIONE DEL TESTO';

  @override
  String get fontUpper => 'CARATTERE';

  @override
  String get serifBook => 'Serif (libro)';

  @override
  String get bookMarginsUpper => 'MARGINI DEL LIBRO';

  @override
  String get narrow => 'Stretto';

  @override
  String get connectionFailedCheck => '❌ Connessione non riuscita. Verifica indirizzo IP, porta e credenziali.';

  @override
  String get connectionOkFolderValid => '✅ Connessione riuscita e cartella verificata!';

  @override
  String folderMissingOnServer(Object path) {
    return '❌ Il server risponde, ma la cartella \"$path\" non esiste sul server.';
  }

  @override
  String get checkingFolder => 'Verifica della cartella sul server...';

  @override
  String get cannotReachServerCheck => '❌ Impossibile raggiungere il server. Verifica le impostazioni.';

  @override
  String cannotSaveFolderMissing(Object path) {
    return '❌ Impossibile salvare: la cartella \"$path\" non esiste sul server.';
  }

  @override
  String deleteProfileBody(Object name) {
    return 'Vuoi davvero eliminare il profilo \"$name\"?';
  }

  @override
  String serverDeleted(Object serverName) {
    return '🗑️ Server \"$serverName\" eliminato.';
  }

  @override
  String get addLocalServer => 'Aggiungi un server locale';

  @override
  String get editServer => 'Modifica il server';

  @override
  String get deleteThisServer => 'Elimina questo server';

  @override
  String get serverName => 'Nome del server';

  @override
  String get serverNameHint => 'Es.: NAS salotto, PC ufficio...';

  @override
  String get enterName => 'Inserisci un nome';

  @override
  String get ftpPort21 => 'FTP (porta 21)';

  @override
  String get hostIp => 'Host / IP';

  @override
  String get hostHint => 'es. 192.168.1.100 o nas.local';

  @override
  String get hostRequired => 'IP o dominio obbligatorio';

  @override
  String get rootPath => 'Percorso radice';

  @override
  String get secureConnectionHttps => 'Connessione sicura (HTTPS)';

  @override
  String get authenticationOptional => 'Autenticazione (facoltativa)';

  @override
  String get usernameLabel => 'Nome utente';

  @override
  String get password => 'Password';

  @override
  String get allFilesAccessRequired => 'Per analizzare il telefono serve l\'accesso a tutti i file.';

  @override
  String get noCompatibleBookFound => 'Nessun libro compatibile trovato sul telefono.';

  @override
  String alreadyPresentOrSkipped(Object skipped) {
    return ' · $skipped già presente/i o ignorato/i';
  }

  @override
  String booksAddedCount(Object imported, Object skipped) {
    return '$imported libro/i aggiunto/i$skipped';
  }

  @override
  String importFailed(Object error) {
    return 'Importazione impossibile: $error';
  }

  @override
  String get permissionNotGranted => 'Autorizzazione non concessa: nessun file è stato analizzato.';

  @override
  String get scanPhoneTitle => 'Analizzare i libri del telefono?';

  @override
  String get scanPhoneBody => 'ComicStream chiederà l\'accesso ai file solo per trovare fumetti, PDF ed EPUB. Poi sceglierai i file da importare; nulla viene copiato senza conferma.';

  @override
  String get notNow => 'Non ora';

  @override
  String get deviceFiles => 'File del dispositivo';

  @override
  String get addComicsFromDevice => 'Aggiungi fumetti da questo dispositivo';

  @override
  String get addComicsFromDeviceBody => 'Analizza tutti i file compatibili del telefono, poi scegli i libri da tenere.';

  @override
  String get scanningFiles => 'Analisi dei file…';

  @override
  String get scanPhone => 'Analizza il telefono';

  @override
  String addedFilesCount(Object length) {
    return 'File aggiunti ($length)';
  }

  @override
  String get noFileAdded => 'Nessun file aggiunto';

  @override
  String get scanPhoneToFindBooks => 'Analizza il telefono per trovare i tuoi libri.';

  @override
  String formatPageProgress(Object formatString, Object currentPage1, Object totalPages) {
    return '$formatString · Pagina $currentPage1/$totalPages';
  }

  @override
  String pageXOfY(Object currentPage1, Object totalPages) {
    return 'Pagina $currentPage1 di $totalPages';
  }

  @override
  String get removeFromFavorites => 'Rimuovi dai preferiti';

  @override
  String get addToFavorites => 'Aggiungi ai preferiti';

  @override
  String get pageGrid => 'Griglia delle pagine';

  @override
  String get comicLtrShort => 'Fumetto (S->D)';

  @override
  String get mangaRtlShort => 'Manga (D->S)';

  @override
  String get readingDirection => 'Senso di lettura';

  @override
  String get comicLtr => 'Fumetto (da S a D)';

  @override
  String get mangaRtl => 'Manga (da D a S)';

  @override
  String get imageFit => 'Adattamento immagine';

  @override
  String get screen => 'Schermo';

  @override
  String get background => 'Sfondo';

  @override
  String get keepScreenAwake => 'Mantieni lo schermo acceso';

  @override
  String selectedCount(Object length) {
    return '$length selezionati';
  }

  @override
  String get removeAll => 'Rimuovi tutto';

  @override
  String get addAll => 'Aggiungi tutto';

  @override
  String get alreadyImported => 'Già importato';

  @override
  String booksFoundCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count libri',
      one: '1 libro',
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
  String get convertToCbz => 'Converti in fumetto (CBZ)';

  @override
  String get markAsUnread => 'Segna come non letto';

  @override
  String get markAsRead => 'Segna come letto';

  @override
  String get deleteFromDevice => 'Elimina dal dispositivo';

  @override
  String get finishedUpper => 'FINITO';

  @override
  String get cbzBenefits => 'Vantaggi del formato CBZ:';

  @override
  String get cbzBenefit1 => '• Rendering molto più veloce e fluido';

  @override
  String get cbzBenefit2 => '• Modalità manga (da destra a sinistra) disponibile';

  @override
  String get cbzBenefit3 => '• Modalità webtoon (scorrimento continuo) fluida';

  @override
  String get cbzBenefit4 => '• Minor consumo di memoria e batteria';

  @override
  String get converting => 'Conversione in corso...';

  @override
  String get conversionSucceeded => 'Conversione riuscita!';

  @override
  String get conversionSucceededBody => 'Il tuo fumetto è disponibile in formato CBZ ad alta definizione.';

  @override
  String get readAsCbz => 'Leggi in modalità fumetto (CBZ)';

  @override
  String get pleaseWait => 'Attendere...';

  @override
  String get downloads => 'Download';

  @override
  String get noDownloadInProgress => 'Nessun download in corso';

  @override
  String get noDownloadInProgressBody => 'I file che scarichi dal tuo server locale appariranno qui con il loro avanzamento.';

  @override
  String inProgressCount(Object length) {
    return 'In corso ($length)';
  }

  @override
  String historyCount(Object length) {
    return 'Cronologia ($length)';
  }

  @override
  String doneWithSize(Object formatBytes) {
    return 'Completato • $formatBytes';
  }

  @override
  String get deleteFromStorage => 'Elimina dalla memoria';

  @override
  String failedWithReason(Object reason) {
    return 'Non riuscito: $reason';
  }

  @override
  String weeksAgo(Object weeks) {
    return '$weeks sett. fa';
  }

  @override
  String daysAgo(Object inDays) {
    return '$inDays giorni fa';
  }

  @override
  String hoursAgo(Object inHours) {
    return '$inHours h fa';
  }

  @override
  String minutesAgo(Object inMinutes) {
    return '$inMinutes min fa';
  }

  @override
  String get justNow => 'Proprio ora';

  @override
  String pdfNotFound(Object pdfFilePath) {
    return 'File PDF non trovato: $pdfFilePath';
  }

  @override
  String get pdfHasNoPage => 'Il file PDF non contiene pagine.';

  @override
  String conversionInit(Object totalPages) {
    return 'Avvio della conversione ($totalPages pagine)...';
  }

  @override
  String renderingPagesRange(Object i1, Object currentBatchEnd, Object totalPages) {
    return 'Rendering HD pagine da $i1 a $currentBatchEnd / $totalPages...';
  }

  @override
  String renderingPage(Object i1, Object totalPages) {
    return 'Rendering HD pagina $i1 / $totalPages...';
  }

  @override
  String get assemblingCbz => 'Assemblaggio dell\'archivio CBZ...';

  @override
  String get noPageGenerated => 'Impossibile generare pagine dal PDF.';

  @override
  String get cbzEncodingFailed => 'Codifica dell\'archivio CBZ non riuscita.';

  @override
  String get finalizingCover => 'Completamento ed estrazione della copertina...';

  @override
  String get conversionDone => 'Conversione completata!';

  @override
  String get cbzNotFound => 'File CBZ non trovato sul dispositivo.';

  @override
  String get noValidImageInCbz => 'Nessuna immagine valida trovata in questo archivio CBZ.';

  @override
  String cbzReadError(Object sizeMb, Object e) {
    return 'Errore di lettura ($sizeMb MB): $e\n\nIl file potrebbe essere danneggiato o il download incompleto.';
  }

  @override
  String pagesCount(Object length) {
    return 'Pagine ($length)';
  }

  @override
  String get loadingVolume => 'Caricamento del volume...';

  @override
  String get volumeFinished => 'Volume finito! 🎉';

  @override
  String nextVolumeWithTitle(Object title) {
    return 'Passa al volume successivo ➔\n$title';
  }

  @override
  String bookSyncUnavailable(Object error) {
    return 'Sincronizzazione non disponibile per questo libro. Lettura locale mantenuta: $error';
  }

  @override
  String get progressFoundElsewhere => 'Progresso trovato su un altro dispositivo';

  @override
  String otherPositionOnDevice(Object remoteDeviceName) {
    return '«$remoteDeviceName» ha un\'altra posizione per questo libro.';
  }

  @override
  String get thisDevice => 'Questo dispositivo';

  @override
  String get keepHere => 'Mantieni qui';

  @override
  String continueFromDevice(Object remoteDeviceName) {
    return 'Continua da $remoteDeviceName';
  }

  @override
  String get downloadFailed => 'Download non riuscito';

  @override
  String get convertingHdCbz => 'Conversione HD in CBZ (modalità fumetto)...';

  @override
  String get downloadingYourComic => 'Download del tuo fumetto...';

  @override
  String get networkErrorOccurred => 'Si è verificato un errore di rete.';

  @override
  String get convertingHdInProgress => 'Conversione HD in corso...';

  @override
  String get deleteFromDeviceTitle => 'Eliminare dal dispositivo?';

  @override
  String deleteDownloadedFileBody(Object name) {
    return 'Vuoi eliminare il file scaricato in locale di \"$name\" per liberare spazio?\n\nIl file resta disponibile e scaricabile dal tuo server.';
  }

  @override
  String deletedFromDevice(Object name) {
    return '\"$name\" è stato eliminato dal tuo dispositivo.';
  }

  @override
  String get deleteLocalCopy => 'Elimina copia locale';

  @override
  String get downloadForOffline => 'Scarica per la lettura offline';

  @override
  String get updateAvailable => 'Aggiornamento disponibile!';

  @override
  String get whatsNew => 'Novità:';

  @override
  String get defaultReleaseNotes => 'Miglioramenti delle prestazioni e correzioni di bug.';

  @override
  String get downloadApk => 'Scarica APK';

  @override
  String get almostDone => 'Quasi finito...';

  @override
  String secondsLeft(Object seconds) {
    return '~ $seconds s rimanenti';
  }

  @override
  String itemsCount(Object itemCount) {
    return '$itemCount elementi';
  }

  @override
  String readOfTotal(Object completedBooks, Object totalBooks) {
    return '$completedBooks/$totalBooks letti';
  }

  @override
  String get emptyServerResponse => 'Risposta vuota dal server';

  @override
  String chapterN(Object length1) {
    return 'Capitolo $length1';
  }

  @override
  String chapterNIdx(Object idx1) {
    return 'Capitolo $idx1';
  }

  @override
  String get pdfNotFoundOnDevice => 'File PDF non trovato sul dispositivo.';

  @override
  String get convertToCbzComicMode => 'Converti in CBZ (modalità fumetto)';

  @override
  String get pressAgainToExit => 'Premi di nuovo per uscire da ComicStream';

  @override
  String get downloadsTabShort => 'Download';

  @override
  String get settingsTab => 'Opzioni';

  @override
  String get invalidJsonFormat => 'Formato JSON non valido';

  @override
  String cannotLoadFolder(Object e) {
    return 'Impossibile caricare la cartella: $e';
  }

  @override
  String get newUpdateAvailable => 'È disponibile un nuovo aggiornamento.';

  @override
  String get unknownEncryptionVersion => 'Versione di crittografia sconosciuta';

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
      other: '$count volumi',
      one: '1 volume',
    );
    return '$_temp0';
  }

  @override
  String chapterSlashPercent(Object current, Object total, Object percent) {
    return 'Capitolo $current/$total · $percent%';
  }

  @override
  String labelLocationDate(Object label, Object location, Object date, Object time) {
    return '$label: $location\n$date alle $time';
  }

  @override
  String get cancel => 'Annulla';

  @override
  String get edit => 'Modifica';

  @override
  String get continueLabel => 'Continua';

  @override
  String get save => 'Salva';

  @override
  String get view => 'Vedi';

  @override
  String get synchronize => 'Sincronizza';

  @override
  String get back => 'Indietro';

  @override
  String get none => 'Nessuno';

  @override
  String get all => 'Tutto';

  @override
  String get importAction => 'Importa';

  @override
  String get everyone => 'Tutti';

  @override
  String get clean => 'Pulisci';

  @override
  String get read => 'Leggi';

  @override
  String get dark => 'Scuro';

  @override
  String get mint => 'Menta';

  @override
  String get light => 'Chiaro';

  @override
  String get standard => 'Standard';

  @override
  String get large => 'Ampio';

  @override
  String get libraryTab => 'Libreria';

  @override
  String get serverTab => 'Server';

  @override
  String get filesTab => 'File';

  @override
  String get delete => 'Elimina';

  @override
  String get resume => 'Riprendi';

  @override
  String get progress => 'Avanzamento';

  @override
  String get favorites => 'Preferiti';

  @override
  String get close => 'Chiudi';

  @override
  String get options => 'Opzioni';

  @override
  String get search => 'Cerca';

  @override
  String get refresh => 'Aggiorna';

  @override
  String get root => 'Radice';

  @override
  String get empty => 'Svuota';

  @override
  String get font => 'Carattere';

  @override
  String get lineSpacing => 'Interlinea';

  @override
  String get compact => 'Compatta';

  @override
  String get normal => 'Normale';

  @override
  String get relaxed => 'Ampia';

  @override
  String get margin => 'Margine';

  @override
  String get narrowShort => 'Stretto';

  @override
  String get yesterday => 'Ieri';

  @override
  String get today => 'Oggi';

  @override
  String get folder => 'Cartella';

  @override
  String get convert => 'Converti';

  @override
  String get width => 'Larghezza';

  @override
  String get height => 'Altezza';

  @override
  String get black => 'Nero';

  @override
  String get grey => 'Grigio';

  @override
  String get white => 'Bianco';

  @override
  String get downloaded => 'Scaricato';

  @override
  String get serverDefaultName => 'Server';

  @override
  String get test => 'Prova';

  @override
  String get type => 'Tipo';

  @override
  String get port => 'Porta';

  @override
  String get path => 'Percorso';

  @override
  String get credentials => 'Credenziali';

  @override
  String get ignore => 'Ignora';

  @override
  String get noneLower => 'nessuna';

  @override
  String get serverUpper => 'SERVER';

  @override
  String get bookUpper => 'LIBRO';

  @override
  String get resumeUpper => 'RIPRENDI';

  @override
  String get currentUpper => 'ATTUALE';

  @override
  String get lineSpacingUpper => 'INTERLINEA';

  @override
  String get alignmentUpper => 'ALLINEAMENTO';

  @override
  String get comicsFilter => 'Fumetti';

  @override
  String get navLibrary => 'Libreria';

  @override
  String get navServers => 'Server';

  @override
  String get computerFiles => 'File del computer';

  @override
  String get addComicsFromComputerBody => 'Scegli fumetti (CBZ, CBR, PDF, EPUB) o un’intera cartella da analizzare. Anche un doppio clic in Esplora file li apre direttamente.';

  @override
  String get openFiles => 'Apri file…';

  @override
  String get scanFolder => 'Analizza una cartella…';

  @override
  String get columnTitle => 'Titolo';

  @override
  String get columnFormat => 'Formato';

  @override
  String get columnSize => 'Dimensione';

  @override
  String get columnAdded => 'Aggiunto';

  @override
  String get doublePageTitle => 'Doppia pagina su schermi grandi';

  @override
  String get doublePageBody => 'Due pagine affiancate quando la finestra è larga e orizzontale';

  @override
  String get onePage => '1 pagina';

  @override
  String get twoPages => '2 pagine';

  @override
  String get togglePagesPerView => 'Mostra 1 o 2 pagine (D)';

  @override
  String get selectAll => 'Seleziona tutto';

  @override
  String get clearSelection => 'Annulla selezione';

  @override
  String get moveToSeries => 'Sposta in una serie';

  @override
  String get seriesNameLabel => 'Nome della serie';

  @override
  String get automaticSeries => 'Serie automatica';

  @override
  String get move => 'Sposta';

  @override
  String deleteSelectedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Eliminare $count libri?',
      one: 'Eliminare 1 libro?',
    );
    return '$_temp0';
  }

  @override
  String get deleteSelectedBody => 'I file verranno eliminati da questo dispositivo. Quelli sui tuoi server restano intatti.';

  @override
  String librarySelectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selezionati',
      one: '1 selezionato',
    );
    return '$_temp0';
  }

  @override
  String get languageTitle => 'Lingua';

  @override
  String get systemLanguage => 'Lingua di sistema';

  @override
  String get googleBrowserDone => 'Accesso effettuato. Puoi chiudere questa scheda e tornare a ComicStream.';

  @override
  String get googleBrowserFailed => 'Accesso con Google non riuscito. Chiudi questa scheda e riprova da ComicStream.';
}
