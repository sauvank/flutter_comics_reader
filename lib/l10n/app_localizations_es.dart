import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get resetVaultTitle => '¿Restablecer la bóveda?';

  @override
  String get resetVaultBody => 'Si perdiste tu frase de recuperación, el restablecimiento creará una bóveda nueva y vacía. Los datos protegidos de tus otros dispositivos deberán sincronizarse de nuevo.';

  @override
  String get reset => 'Restablecer';

  @override
  String get confirmSecretPhrase => 'Confirmar la frase secreta';

  @override
  String get secretPhraseWrittenDownBody => '¿Has anotado tu frase secreta en un lugar seguro?\n\nEs imprescindible para restaurar tus datos o sincronizar un dispositivo nuevo. ComicStream no la guarda y nunca podrá recuperarla por ti.';

  @override
  String get yourSecretPhrase => 'Tu frase secreta:';

  @override
  String get phraseNotedContinue => 'La he anotado, continuar';

  @override
  String get changeSecretPhrase => 'Cambiar la frase secreta';

  @override
  String get changeSecretPhraseBody => 'Define una nueva frase secreta (mínimo 16 caracteres) para proteger tu sincronización.';

  @override
  String get newSecretPhrase => 'Nueva frase secreta';

  @override
  String get min16Characters => 'Mínimo 16 caracteres';

  @override
  String get showPhrase => 'Mostrar la frase';

  @override
  String get hidePhrase => 'Ocultar la frase';

  @override
  String get confirmNewPhrase => 'Confirmar la nueva frase';

  @override
  String get phraseTooShort => 'La frase debe tener al menos 16 caracteres.';

  @override
  String get phrasesDoNotMatch => 'Las dos frases no coinciden.';

  @override
  String get confirmChangeTitle => '¿Confirmar el cambio?';

  @override
  String get confirmChangeBody => 'Tu bóveda se actualizará con esta nueva frase secreta.\nAsegúrate de haberla anotado:';

  @override
  String get confirmAndSave => 'Confirmar y guardar';

  @override
  String get secretPhraseUpdated => 'Frase secreta actualizada correctamente.';

  @override
  String get operationDone => 'Operación completada.';

  @override
  String cannotContinue(Object error) {
    return 'No se puede continuar: $error';
  }

  @override
  String dateAtTime(Object date, Object time) {
    return '$date a las $time';
  }

  @override
  String get syncConflict => 'Conflicto de sincronización';

  @override
  String syncConflictBody(Object label) {
    return 'Se modificaron dos versiones de «$label».';
  }

  @override
  String thisDeviceValue(Object formatConflictDate) {
    return 'Este dispositivo: $formatConflictDate';
  }

  @override
  String syncServerValue(Object formatConflictDate) {
    return 'Servidor de sincronización: $formatConflictDate';
  }

  @override
  String thisDeviceSummary(Object localSummary) {
    return 'Este dispositivo: $localSummary';
  }

  @override
  String serverSummary(Object remoteSummary) {
    return 'Servidor: $remoteSummary';
  }

  @override
  String get chooseReferenceVersion => 'Elige la versión de referencia. Después se sincronizará en tus otros dispositivos.';

  @override
  String get fetchFromServer => 'Recuperar del servidor';

  @override
  String get sendToServer => 'Enviar al servidor';

  @override
  String get later => 'Más tarde';

  @override
  String get thisDeviceName => 'Nombre de este dispositivo';

  @override
  String get deviceNameHint => 'Ej. Tableta o Teléfono';

  @override
  String get deviceNameSavedOnServer => 'Nombre del dispositivo guardado en el servidor.';

  @override
  String get deviceNameSavedLocally => 'Nombre guardado en este dispositivo. Se enviará en la próxima sincronización.';

  @override
  String cannotPrepareSync(Object error) {
    return 'No se puede preparar la sincronización: $error';
  }

  @override
  String get whichBackupToUse => '¿Qué copia de seguridad usar?';

  @override
  String get whichBackupBody => 'Tu elección se convierte en la referencia compartida. Los demás dispositivos la recibirán en su próxima sincronización.';

  @override
  String get notBackedUpYet => 'Aún sin copia de seguridad';

  @override
  String backedUpAt(Object formatConflictDate) {
    return 'Copia guardada $formatConflictDate';
  }

  @override
  String get accountAndSync => 'Cuenta y sincronización';

  @override
  String get syncUnavailableNoFirebase => 'La sincronización estará disponible tras configurar el proyecto Firebase. El lector y tus datos locales siguen funcionando con normalidad.';

  @override
  String get accountConnected => 'Sesión iniciada';

  @override
  String get vaultUnlockedE2e => 'Bóveda desbloqueada. Tus datos están cifrados de extremo a extremo.';

  @override
  String get vaultLockedOrNew => 'Bóveda bloqueada o sin inicializar.';

  @override
  String get unlockVault => 'Desbloquear la bóveda';

  @override
  String get initEncryptedVault => 'Crear tu bóveda cifrada';

  @override
  String get unlockVaultBody => 'Hay una bóveda cifrada asociada a esta cuenta. Introduce tu frase de recuperación para desbloquear la sincronización en este dispositivo.';

  @override
  String get initVaultBody => 'Para proteger las contraseñas de tus servidores y tus datos, elige una frase secreta (mínimo 16 caracteres). Es imprescindible para restaurar tus datos en un dispositivo nuevo.';

  @override
  String get recoveryPhrase => 'Frase de recuperación';

  @override
  String get secretPhraseMin16 => 'Frase secreta (mínimo 16 caracteres)';

  @override
  String get enterRecoveryPhrase => 'Introduce tu frase de recuperación.';

  @override
  String get secretPhraseTooShort => 'La frase secreta debe tener al menos 16 caracteres.';

  @override
  String get secretPhrasesDoNotMatch => 'Las frases secretas no coinciden.';

  @override
  String get unlockSync => 'Desbloquear la sincronización';

  @override
  String get createAndEnableVault => 'Crear y activar la bóveda';

  @override
  String get forgotPhraseReset => '¿Olvidaste la frase? Restablecer la bóveda';

  @override
  String get vaultUnlocked => 'Bóveda desbloqueada';

  @override
  String get syncActiveE2e => 'La sincronización está activa y protegida con cifrado de extremo a extremo.';

  @override
  String get syncing => 'Sincronizando…';

  @override
  String get changePhrase => 'Cambiar la frase';

  @override
  String get shownWhenChoosingBackup => 'Se muestra al elegir una copia de seguridad';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get createAccount => 'Crear una cuenta';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get passwordMin12 => 'Contraseña (mínimo 12 caracteres)';

  @override
  String get showPassword => 'Mostrar la contraseña';

  @override
  String get hidePassword => 'Ocultar la contraseña';

  @override
  String get createTheAccount => 'Crear la cuenta';

  @override
  String get alreadyHaveAccount => 'Ya tengo una cuenta';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get recoveryPhraseRequiredNote => 'La frase de recuperación es imprescindible para restaurar las contraseñas de los servidores en un dispositivo nuevo. ComicStream nunca la guarda.';

  @override
  String androidCertNotAllowed(Object hashes) {
    return 'Certificado Android no autorizado: $hashes';
  }

  @override
  String pendingConflicts(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cambios esperan tu elección.',
      one: '1 cambio espera tu elección.',
    );
    return '$_temp0';
  }

  @override
  String upToDate(Object fullVersion) {
    return '¡ComicStream está actualizado ($fullVersion)!';
  }

  @override
  String get updateCheckError => 'Error al buscar actualizaciones';

  @override
  String get clearCacheTitle => '¿Vaciar la caché?';

  @override
  String get clearCacheBody => 'Las portadas se recargarán automáticamente.';

  @override
  String get coverCacheCleared => '¡Caché de portadas vaciada correctamente!';

  @override
  String get deleteAllTitle => '¿Eliminar todo?';

  @override
  String get deleteAllBody => 'Esto eliminará todos los cómics y mangas descargados localmente para liberar espacio. Se conservará la configuración de tus servidores.';

  @override
  String get allLocalFilesDeleted => 'Se han eliminado todos los archivos locales.';

  @override
  String get eraseAll => 'Borrar todo';

  @override
  String get commandCopied => '¡Comando copiado!';

  @override
  String get localServerGuide => 'Guía del servidor local';

  @override
  String get guideOption1 => 'Opción 1: servidor WebDAV con Docker (recomendado)';

  @override
  String get guideOption1Body => 'Inicia un servidor WebDAV ligero con Docker en una sola línea, apuntando a tu carpeta de cómics:';

  @override
  String get guideOption2 => 'Opción 2: script de Python listo para usar';

  @override
  String get guideOption2Body => 'Se incluye un servidor Python dedicado en `server_example/comic_server.py`. Para iniciarlo:';

  @override
  String get guideOption3 => 'Opción 3: NAS Synology / TrueNAS / Nextcloud';

  @override
  String get guideOption3Body => 'Activa el servicio WebDAV en el panel de administración de tu NAS (puerto 5005 por defecto en Synology) e introduce tus credenciales en la app.';

  @override
  String get settings => 'Ajustes';

  @override
  String get accountAndSyncShort => 'Cuenta y sincronización';

  @override
  String get accountAndSyncSubtitle => 'Servidores, progreso y ajustes cifrados';

  @override
  String get appearanceTheme => 'Apariencia y tema';

  @override
  String get appTheme => 'Tema de la app';

  @override
  String get readerPreferences => 'Preferencias del lector';

  @override
  String get defaultReadingMode => 'Modo de lectura predeterminado';

  @override
  String get readingModeComic => 'Cómic (izquierda a derecha)';

  @override
  String get readingModeManga => 'Manga (derecha a izquierda)';

  @override
  String get readingModeWebtoon => 'Webtoon (desplazamiento vertical)';

  @override
  String get keepScreenOn => 'Mantener la pantalla encendida al leer';

  @override
  String get showPageNumber => 'Mostrar el número de página';

  @override
  String get autoConvertPdf => 'Convertir automáticamente los PDF a CBZ';

  @override
  String get autoConvertPdfBody => 'Convierte cada PDF descargado en un archivo de cómic muy fluido para tabletas.';

  @override
  String get comicRenderQuality => 'Calidad de renderizado de cómics';

  @override
  String get qualityAutoLong => 'Automática (detecta la pantalla + 35 % de nitidez)';

  @override
  String get qualitySuperLong => 'Supermuestreo (2600px - zoom nítido)';

  @override
  String get qualityUltraLong => 'Ultra HD (3500px - definición máxima)';

  @override
  String get qualityStandardLong => 'Estándar 1:1 (1900px - rápido)';

  @override
  String get qualityAuto => 'Auto (pantalla + 35 %)';

  @override
  String get qualityHigh => 'Alta (2600px)';

  @override
  String get qualityStandard => 'Estándar 1:1';

  @override
  String get ebooksEpub => 'E-books y EPUB';

  @override
  String get fontSize => 'Tamaño de fuente';

  @override
  String get justifiedText => 'Texto justificado';

  @override
  String get storageCache => 'Almacenamiento y caché';

  @override
  String get spaceUsedByBooks => 'Espacio ocupado por los libros:';

  @override
  String booksDownloadedCount(Object length) {
    return '$length libro(s) descargado(s)';
  }

  @override
  String get clearCache => 'Vaciar caché';

  @override
  String get updates => 'Actualizaciones';

  @override
  String get checkForUpdate => 'Buscar actualizaciones';

  @override
  String installedVersion(Object fullVersion) {
    return 'Versión instalada: $fullVersion';
  }

  @override
  String get check => 'Comprobar';

  @override
  String get seeStoreListing => 'Ver la ficha oficial de ComicStream';

  @override
  String get helpSetup => 'Ayuda y configuración';

  @override
  String get howToSetupLocalServer => '¿Cómo configuro mi servidor local?';

  @override
  String get helpSetupSubtitle => 'Docker, Python, NAS Synology, TrueNAS...';

  @override
  String get appTagline => 'Lector de cómics y mangas en la nube';

  @override
  String get deleteBookTitle => '¿Eliminar este libro?';

  @override
  String deleteBookBody(Object title) {
    return '¿Quieres eliminar \"$title\" de tu almacenamiento local?';
  }

  @override
  String resumeAtChapter(Object title, Object currentPage1) {
    return '«$title» ya estaba empezado. ¿Continuar en el capítulo $currentPage1?';
  }

  @override
  String resumeAtPage(Object title, Object currentPage1) {
    return '«$title» ya estaba empezado. ¿Continuar en la página $currentPage1?';
  }

  @override
  String get myLibrary => 'Mi biblioteca';

  @override
  String comicsCount(Object length) {
    return '$length cómics';
  }

  @override
  String get syncInProgress => 'Sincronización en curso';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get lastRead => 'Última lectura';

  @override
  String get titleAz => 'Título (A-Z)';

  @override
  String get dateAdded => 'Fecha de adición';

  @override
  String seriesCount(Object length) {
    return 'Series ($length)';
  }

  @override
  String volumesCount(Object length) {
    return 'Tomos ($length)';
  }

  @override
  String get searchLibraryHint => 'Buscar una serie, un tomo, un autor...';

  @override
  String get recentlyOpened => 'Abiertos recientemente';

  @override
  String myCollectionsCount(Object length) {
    return 'Mis colecciones y series ($length)';
  }

  @override
  String get backToSeries => 'Volver a las series';

  @override
  String seriesProgress(Object completedBooks, Object totalBooks, Object progressPercent) {
    return '$completedBooks/$totalBooks tomos leídos • $progressPercent%';
  }

  @override
  String get checkNewVolumes => 'Buscar nuevos tomos en el servidor';

  @override
  String get nextVolumeToRead => 'SIGUIENTE TOMO POR LEER';

  @override
  String get nextVolumeOnServer => 'SIGUIENTE TOMO EN EL SERVIDOR';

  @override
  String get download => 'Descargar';

  @override
  String downloadStarted(Object name) {
    return '📥 Descarga iniciada: $name';
  }

  @override
  String get readNow => 'Leer ahora';

  @override
  String get searchingNextVolumes => 'Buscando los siguientes tomos en el servidor remoto...';

  @override
  String downloadedVolumesCount(Object totalBooks) {
    return 'Tomos descargados ($totalBooks)';
  }

  @override
  String serverVolumesCount(Object length) {
    return 'Tomos disponibles en el servidor ($length)';
  }

  @override
  String downloadAllCount(Object length) {
    return 'Descargar todo ($length)';
  }

  @override
  String volumesQueued(Object length) {
    return '📥 $length tomos añadidos a la cola de descargas';
  }

  @override
  String downloadingName(Object name) {
    return '📥 Descargando: $name';
  }

  @override
  String get libraryFilters => 'Filtros de la biblioteca';

  @override
  String allCount(Object length) {
    return 'Todos ($length)';
  }

  @override
  String get inProgress => 'En curso';

  @override
  String get unread => 'No leídos';

  @override
  String get epubNovels => 'EPUB / Novelas';

  @override
  String get finished => 'Terminados';

  @override
  String get continueReading => 'CONTINUAR LEYENDO';

  @override
  String get libraryEmpty => 'Tu biblioteca está vacía';

  @override
  String get libraryEmptyBody => 'Añade tus cómics desde un servidor o desde los archivos que ya están en este dispositivo.';

  @override
  String get exploreServers => 'Explorar mis servidores';

  @override
  String get importFromPhone => 'Importar desde este dispositivo';

  @override
  String get noSearchResults => 'No hay resultados para esta búsqueda';

  @override
  String get noSearchResultsBody => 'Prueba otra palabra clave o restablece los filtros.';

  @override
  String chapterProgressPercent(Object current, Object total, Object percent) {
    return 'Capítulo $current/$total ($percent%)';
  }

  @override
  String pageProgressPercent(Object current, Object total, Object percent) {
    return 'Página $current/$total ($percent%)';
  }

  @override
  String chapterOfTotal(Object current, Object total) {
    return 'Capítulo $current de $total';
  }

  @override
  String pageOfTotal(Object current, Object total) {
    return 'Página $current de $total';
  }

  @override
  String get setupServer => 'Configurar un servidor';

  @override
  String connectionSucceeded(Object name) {
    return '¡Conectado a $name!';
  }

  @override
  String connectionFailed(Object name) {
    return 'Error de conexión con $name';
  }

  @override
  String get deleteServerTitle => '¿Eliminar este servidor?';

  @override
  String deleteServerBody(Object name) {
    return '¿Seguro que quieres eliminar \"$name\" de tus fuentes remotas?';
  }

  @override
  String get exportConfiguration => 'Exportar la configuración';

  @override
  String get exportConfigurationBody => 'Este es el archivo de configuración JSON con tus perfiles de servidor:';

  @override
  String get copyJson => 'Copiar JSON';

  @override
  String get configurationCopied => '✅ ¡Configuración copiada al portapapeles!';

  @override
  String get importConfiguration => 'Importar una configuración';

  @override
  String get chooseJsonFile => 'Elegir un archivo .json';

  @override
  String fileReadError(Object e) {
    return 'Error al leer el archivo: $e';
  }

  @override
  String get orPasteJson => 'O pega el JSON aquí:';

  @override
  String serversImported(Object count) {
    return '✅ ¡$count servidor(es) importado(s) correctamente!';
  }

  @override
  String baseLocationSet(Object currentPath) {
    return '✅ Ubicación base definida en: $currentPath';
  }

  @override
  String get myServers => 'Mis servidores';

  @override
  String get addServer => 'Añadir un servidor';

  @override
  String get howToSetupServer => 'Cómo configurar un servidor';

  @override
  String get exportConfigurations => 'Exportar las configuraciones';

  @override
  String get testConnection => 'Probar la conexión';

  @override
  String get filterFolderHint => 'Filtrar esta carpeta...';

  @override
  String get closeSearch => 'Cerrar la búsqueda';

  @override
  String get folderOptions => 'Opciones de la carpeta';

  @override
  String get setFolderAsRoot => 'Definir esta carpeta como raíz';

  @override
  String get switchServer => 'Cambiar de servidor';

  @override
  String get parentFolder => 'Carpeta superior';

  @override
  String everythingCount(Object length) {
    return 'Todo ($length)';
  }

  @override
  String get downloadAllTitle => '¿Descargar todo?';

  @override
  String downloadAllBody(Object length) {
    return 'Se descargarán $length tomos en segundo plano.';
  }

  @override
  String volumesQueuedCount(Object length) {
    return '📥 $length tomo(s) añadido(s) a la cola de descargas';
  }

  @override
  String foldersSeriesCount(Object length) {
    return 'Carpetas y series ($length)';
  }

  @override
  String booksComicsCount(Object length) {
    return 'Libros y cómics ($length)';
  }

  @override
  String downloadingNamePlain(Object name) {
    return 'Descargando: $name';
  }

  @override
  String get folderEmpty => 'Esta carpeta está vacía';

  @override
  String get folderEmptyBody => 'No se encontró ningún libro ni subcarpeta en esta ubicación.';

  @override
  String get cannotConnectServer => 'No se puede conectar al servidor';

  @override
  String checkServerReachable(Object baseUrl) {
    return 'Comprueba que el servidor sea accesible en $baseUrl.';
  }

  @override
  String get editSettings => 'Editar los ajustes';

  @override
  String get retry => 'Reintentar';

  @override
  String get googleTokenMissing => 'No se encontró el token de autenticación de Google.';

  @override
  String get googleSignInUnavailable => 'El inicio de sesión con Google no está disponible en este dispositivo.';

  @override
  String get recoveryPhraseTooShort => 'La frase de recuperación debe tener al menos 16 caracteres.';

  @override
  String get signInRequired => 'Inicio de sesión requerido';

  @override
  String get noSyncVaultFound => 'No se encontró ninguna bóveda de sincronización.';

  @override
  String get vaultMustBeUnlocked => 'La bóveda debe estar desbloqueada para cambiar la frase secreta.';

  @override
  String get recoveryPhraseRequiredHere => 'Se requiere la frase de recuperación en este dispositivo.';

  @override
  String get serverConfigurations => 'Configuraciones de servidores';

  @override
  String get readingSettings => 'Ajustes de lectura';

  @override
  String get deviceNameLength => 'El nombre debe tener entre 1 y 40 caracteres.';

  @override
  String deviceDefaultName(Object substring) {
    return 'Dispositivo $substring';
  }

  @override
  String get otherDevice => 'Otro dispositivo';

  @override
  String get remoteProgressGone => 'Este progreso remoto ya no existe.';

  @override
  String thisDeviceNamed(Object currentName) {
    return 'Este dispositivo — $currentName';
  }

  @override
  String get deviceBackupNotFound => 'No se encuentra la copia de seguridad de este dispositivo.';

  @override
  String get googleDataNotFound => 'No se encuentran los datos de Google por resolver.';

  @override
  String get localProgressGone => 'El progreso local correspondiente ya no existe.';

  @override
  String get unknownSyncDocument => 'Documento de sincronización desconocido';

  @override
  String get readingSettingsShort => 'Ajustes de lectura';

  @override
  String get yes => 'sí';

  @override
  String get no => 'no';

  @override
  String chapterSlash(Object current, Object total) {
    return 'Capítulo $current/$total';
  }

  @override
  String pageSlash(Object current, Object total) {
    return 'Página $current/$total';
  }

  @override
  String progressSummary(Object location, Object favorite, Object bookmarks) {
    return '$location · Favorito: $favorite · $bookmarks';
  }

  @override
  String bookmarksCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count marcadores',
      one: '1 marcador',
      zero: '0 marcadores',
    );
    return '$_temp0';
  }

  @override
  String serverProfilesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count perfiles de servidor',
      one: '1 perfil de servidor',
      zero: '0 perfiles de servidor',
    );
    return '$_temp0';
  }

  @override
  String ftpInvalidServer(Object banner) {
    return 'Servidor FTP no válido: $banner';
  }

  @override
  String ftpCredentialsRefused(Object passResp) {
    return 'Credenciales FTP rechazadas: $passResp';
  }

  @override
  String ftpUsernameRefused(Object userResp) {
    return 'Usuario FTP rechazado: $userResp';
  }

  @override
  String ftpPassiveFailed(Object pasvResp) {
    return 'Fallo del modo pasivo FTP: $pasvResp';
  }

  @override
  String ftpDownloadFailed(Object retrResp) {
    return 'No se puede descargar el archivo FTP: $retrResp';
  }

  @override
  String get ftpIdleTimeout => 'Tiempo de inactividad FTP agotado';

  @override
  String ftpPasvUnrecognized(Object response) {
    return 'Respuesta PASV no reconocida: $response';
  }

  @override
  String get guideHeroTitle => 'Lee los cómics de tu ordenador o NAS';

  @override
  String get guideHeroBody => 'Un servidor hace que tu colección esté disponible en la app sin copiarlo todo. Unos 2 minutos.';

  @override
  String get howItWorks => 'Cómo hacerlo';

  @override
  String get guideStep1Title => 'Comparte tu carpeta de cómics';

  @override
  String get guideStep1Body => 'En tu NAS u ordenador, activa un recurso compartido WebDAV, FTP o HTTP que apunte a la carpeta con tus archivos CBZ, CBR, PDF o EPUB. Los ejemplos de abajo detallan cada caso.';

  @override
  String get guideStep2Title => 'Anota su dirección';

  @override
  String get guideStep2Body => 'Busca la dirección IP local de la máquina (p. ej. 192.168.1.100) y el puerto del recurso compartido. Este dispositivo debe estar en la misma red.';

  @override
  String get guideStep3Title => 'Rellena el formulario';

  @override
  String get guideStep3Body => 'Toca «Añadir un servidor», elige el tipo y luego introduce el host, el puerto, la ruta de la carpeta y, si hace falta, el usuario y la contraseña.';

  @override
  String get guideStep4Title => 'Prueba y guarda';

  @override
  String get guideStep4Body => '«Probar» comprueba la conexión. Una vez validada, «Guardar» abre directamente el servidor para explorar y descargar tus libros.';

  @override
  String get configurationExamples => 'Ejemplos de configuración';

  @override
  String get webdavSubtitle => 'Recomendado · NAS Synology, QNAP, Nextcloud';

  @override
  String get host => 'Host';

  @override
  String get webdavPorts => '5005 (Synology), 80 o 443';

  @override
  String get webdavCredentials => 'las de tu cuenta del NAS';

  @override
  String get webdavTip => 'En Synology: instala «WebDAV Server» desde el Centro de paquetes y activa HTTP o HTTPS.';

  @override
  String get httpSubtitle => 'Lo más sencillo desde un ordenador';

  @override
  String get computerIp => 'IP del ordenador';

  @override
  String get httpTip => 'En tu carpeta de cómics, ejecuta «python3 -m http.server 8080» o el script server_example/comic_server.py incluido con ComicStream.';

  @override
  String get ftpSubtitle => 'Routers, NAS antiguos';

  @override
  String get ftpCredentials => 'cuenta FTP del router o del NAS';

  @override
  String get ftpTip => 'FTP no está cifrado: úsalo solo en tu red doméstica.';

  @override
  String get cannotConnectTitle => '¿No se conecta?';

  @override
  String get tipSameWifi => 'Comprueba que este dispositivo y el servidor están en la misma red.';

  @override
  String get tipUseIp => 'Prueba con la dirección IP en lugar de un nombre (nas.local).';

  @override
  String get tipFirewall => 'Comprueba que el cortafuegos del ordenador permita el puerto elegido.';

  @override
  String get tipVpn => 'Fuera de casa, usa una VPN (WireGuard, Tailscale…) en lugar de exponer el servidor a Internet.';

  @override
  String get importExistingConfiguration => 'Importar una configuración existente';

  @override
  String get waiting => 'En espera...';

  @override
  String get downloadingEllipsis => 'Descargando...';

  @override
  String get cancelled => 'Cancelado';

  @override
  String get extractingFinalizing => 'Extrayendo y finalizando...';

  @override
  String get convertingHd => 'Convirtiendo a cómic HD...';

  @override
  String secondsRemaining(Object approxSec) {
    return ' ~ ${approxSec}s restantes';
  }

  @override
  String convertingHdProgress(Object currentPage, Object totalPages, Object etaText) {
    return 'Conversión HD ($currentPage/$totalPages páginas)$etaText';
  }

  @override
  String get finishedStatus => 'Terminado';

  @override
  String get failed => 'Error';

  @override
  String get networkTimeout => 'Tiempo de espera agotado (red)';

  @override
  String get invalidCertificate => 'Certificado de seguridad no válido (¿servidor autofirmado?)';

  @override
  String get fileNotFound404 => 'Archivo no encontrado en el servidor (404)';

  @override
  String get accessDenied => 'Acceso denegado (credenciales incorrectas)';

  @override
  String get cannotReachServerLost => 'No se puede contactar con el servidor (conexión perdida)';

  @override
  String get downloadCancelled => 'Descarga cancelada';

  @override
  String get networkInterrupted => 'Conexión de red interrumpida';

  @override
  String get notEnoughStorage => 'Espacio de almacenamiento insuficiente en el dispositivo';

  @override
  String get networkError => 'Error de conexión de red';

  @override
  String get localFileAccessError => 'Error de acceso al archivo local';

  @override
  String get serverError => 'Error del servidor';

  @override
  String serverErrorCode(Object code) {
    return 'Error del servidor ($code)';
  }

  @override
  String get endOfBookReached => '¡Has llegado al final del libro!';

  @override
  String get loadingBook => 'Cargando el libro...';

  @override
  String get cannotLoadBook => 'No se puede cargar este libro';

  @override
  String get fileMaybeCorrupted => 'Puede que el archivo esté dañado o en un formato no compatible.';

  @override
  String get backToLibrary => 'Volver a la biblioteca';

  @override
  String epubProgressShort(Object value, Object currentChapterIndex1, Object length) {
    return '$value% • Cap. $currentChapterIndex1/$length';
  }

  @override
  String get tableOfContents => 'Índice';

  @override
  String get customizeReading => 'Personalizar la lectura';

  @override
  String chapterXOfY(Object currentChapterIndex1, Object length) {
    return 'Capítulo $currentChapterIndex1 / $length';
  }

  @override
  String endOfChapter(Object currentChapterIndex1) {
    return 'Fin del capítulo $currentChapterIndex1';
  }

  @override
  String get nextChapterUpper => 'SIGUIENTE CAPÍTULO';

  @override
  String get bookFinished => '¡Has terminado este libro!';

  @override
  String get tableOfContentsTitle => 'Índice';

  @override
  String get searchChapterHint => 'Buscar un capítulo...';

  @override
  String noChapterFound(Object tocSearchQuery) {
    return 'No se encontró ningún capítulo para \"$tocSearchQuery\"';
  }

  @override
  String get bookCustomization => 'Personalización del libro';

  @override
  String get themeColorsUpper => 'TEMA Y COLORES';

  @override
  String get sepia => 'Sepia';

  @override
  String get textSizeUpper => 'TAMAÑO DEL TEXTO';

  @override
  String get fontUpper => 'FUENTE';

  @override
  String get serifBook => 'Serif (libro)';

  @override
  String get bookMarginsUpper => 'MÁRGENES DEL LIBRO';

  @override
  String get narrow => 'Estrecho';

  @override
  String get connectionFailedCheck => '❌ Error de conexión. Comprueba la dirección IP, el puerto y las credenciales.';

  @override
  String get connectionOkFolderValid => '✅ ¡Conexión correcta y carpeta validada!';

  @override
  String folderMissingOnServer(Object path) {
    return '❌ El servidor responde, pero la carpeta \"$path\" no existe en el servidor.';
  }

  @override
  String get checkingFolder => 'Comprobando la carpeta en el servidor...';

  @override
  String get cannotReachServerCheck => '❌ No se puede contactar con el servidor. Comprueba los ajustes.';

  @override
  String cannotSaveFolderMissing(Object path) {
    return '❌ No se puede guardar: la carpeta \"$path\" no existe en el servidor.';
  }

  @override
  String deleteProfileBody(Object name) {
    return '¿Seguro que quieres eliminar el perfil \"$name\"?';
  }

  @override
  String serverDeleted(Object serverName) {
    return '🗑️ Servidor \"$serverName\" eliminado.';
  }

  @override
  String get addLocalServer => 'Añadir un servidor local';

  @override
  String get editServer => 'Editar el servidor';

  @override
  String get deleteThisServer => 'Eliminar este servidor';

  @override
  String get serverName => 'Nombre del servidor';

  @override
  String get serverNameHint => 'Ej.: NAS del salón, PC de la oficina...';

  @override
  String get enterName => 'Introduce un nombre';

  @override
  String get ftpPort21 => 'FTP (puerto 21)';

  @override
  String get hostIp => 'Host / IP';

  @override
  String get hostHint => 'ej. 192.168.1.100 o nas.local';

  @override
  String get hostRequired => 'IP o dominio obligatorio';

  @override
  String get rootPath => 'Ruta raíz';

  @override
  String get secureConnectionHttps => 'Conexión segura (HTTPS)';

  @override
  String get authenticationOptional => 'Autenticación (opcional)';

  @override
  String get usernameLabel => 'Usuario';

  @override
  String get password => 'Contraseña';

  @override
  String get allFilesAccessRequired => 'Se necesita acceso a todos los archivos para analizar el teléfono.';

  @override
  String get noCompatibleBookFound => 'No se encontró ningún libro compatible en este dispositivo.';

  @override
  String alreadyPresentOrSkipped(Object skipped) {
    return ' · $skipped ya presente(s) u omitido(s)';
  }

  @override
  String booksAddedCount(Object imported, Object skipped) {
    return '$imported libro(s) añadido(s)$skipped';
  }

  @override
  String importFailed(Object error) {
    return 'Importación imposible: $error';
  }

  @override
  String get permissionNotGranted => 'Permiso no concedido: no se analizó ningún archivo.';

  @override
  String get scanPhoneTitle => '¿Buscar libros en este dispositivo?';

  @override
  String get scanPhoneBody => 'ComicStream pedirá acceso a los archivos solo para encontrar cómics, PDF y EPUB. Después elegirás los archivos a importar; no se copia nada sin confirmación.';

  @override
  String get notNow => 'Ahora no';

  @override
  String get deviceFiles => 'Archivos del dispositivo';

  @override
  String get addComicsFromDevice => 'Añadir cómics desde este dispositivo';

  @override
  String get addComicsFromDeviceBody => 'Analiza todos los archivos compatibles de este dispositivo y elige los libros que quieres conservar.';

  @override
  String get scanningFiles => 'Analizando archivos…';

  @override
  String get scanPhone => 'Escanear este dispositivo';

  @override
  String addedFilesCount(Object length) {
    return 'Archivos añadidos ($length)';
  }

  @override
  String get noFileAdded => 'Ningún archivo añadido';

  @override
  String get scanPhoneToFindBooks => 'Escanea este dispositivo para encontrar tus libros.';

  @override
  String formatPageProgress(Object formatString, Object currentPage1, Object totalPages) {
    return '$formatString · Página $currentPage1/$totalPages';
  }

  @override
  String pageXOfY(Object currentPage1, Object totalPages) {
    return 'Página $currentPage1 de $totalPages';
  }

  @override
  String get removeFromFavorites => 'Quitar de favoritos';

  @override
  String get addToFavorites => 'Añadir a favoritos';

  @override
  String get pageGrid => 'Cuadrícula de páginas';

  @override
  String get comicLtrShort => 'Cómic (I->D)';

  @override
  String get mangaRtlShort => 'Manga (D->I)';

  @override
  String get readingDirection => 'Sentido de lectura';

  @override
  String get comicLtr => 'Cómic (I a D)';

  @override
  String get mangaRtl => 'Manga (D a I)';

  @override
  String get imageFit => 'Ajuste de la imagen';

  @override
  String get screen => 'Pantalla';

  @override
  String get background => 'Fondo';

  @override
  String get keepScreenAwake => 'Mantener la pantalla encendida';

  @override
  String selectedCount(Object length) {
    return '$length seleccionado(s)';
  }

  @override
  String get removeAll => 'Quitar todo';

  @override
  String get addAll => 'Añadir todo';

  @override
  String get alreadyImported => 'Ya importado';

  @override
  String booksFoundCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count libros',
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
  String get convertToCbz => 'Convertir a cómic (CBZ)';

  @override
  String get markAsUnread => 'Marcar como no leído';

  @override
  String get markAsRead => 'Marcar como leído';

  @override
  String get deleteFromDevice => 'Eliminar del dispositivo';

  @override
  String get finishedUpper => 'TERMINADO';

  @override
  String get cbzBenefits => 'Ventajas del formato CBZ:';

  @override
  String get cbzBenefit1 => '• Renderizado mucho más rápido y fluido';

  @override
  String get cbzBenefit2 => '• Modo manga (derecha a izquierda) disponible';

  @override
  String get cbzBenefit3 => '• Modo webtoon (desplazamiento continuo) fluido';

  @override
  String get cbzBenefit4 => '• Menor consumo de memoria y batería';

  @override
  String get converting => 'Convirtiendo...';

  @override
  String get conversionSucceeded => '¡Conversión correcta!';

  @override
  String get conversionSucceededBody => 'Tu cómic está disponible en formato CBZ de alta definición.';

  @override
  String get readAsCbz => 'Leer en modo cómic (CBZ)';

  @override
  String get pleaseWait => 'Espera, por favor...';

  @override
  String get downloads => 'Descargas';

  @override
  String get noDownloadInProgress => 'No hay descargas en curso';

  @override
  String get noDownloadInProgressBody => 'Los archivos que descargues de tu servidor local aparecerán aquí con su progreso.';

  @override
  String inProgressCount(Object length) {
    return 'En curso ($length)';
  }

  @override
  String historyCount(Object length) {
    return 'Historial ($length)';
  }

  @override
  String doneWithSize(Object formatBytes) {
    return 'Terminado • $formatBytes';
  }

  @override
  String get deleteFromStorage => 'Eliminar del almacenamiento';

  @override
  String failedWithReason(Object reason) {
    return 'Error: $reason';
  }

  @override
  String weeksAgo(Object weeks) {
    return 'Hace $weeks sem.';
  }

  @override
  String daysAgo(Object inDays) {
    return 'Hace $inDays días';
  }

  @override
  String hoursAgo(Object inHours) {
    return 'Hace $inHours h';
  }

  @override
  String minutesAgo(Object inMinutes) {
    return 'Hace $inMinutes min';
  }

  @override
  String get justNow => 'Ahora mismo';

  @override
  String pdfNotFound(Object pdfFilePath) {
    return 'Archivo PDF no encontrado: $pdfFilePath';
  }

  @override
  String get pdfHasNoPage => 'El archivo PDF no contiene ninguna página.';

  @override
  String conversionInit(Object totalPages) {
    return 'Iniciando la conversión ($totalPages páginas)...';
  }

  @override
  String renderingPagesRange(Object i1, Object currentBatchEnd, Object totalPages) {
    return 'Renderizado HD de las páginas $i1 a $currentBatchEnd / $totalPages...';
  }

  @override
  String renderingPage(Object i1, Object totalPages) {
    return 'Renderizado HD de la página $i1 / $totalPages...';
  }

  @override
  String get assemblingCbz => 'Montando el archivo CBZ...';

  @override
  String get noPageGenerated => 'No se pudo generar ninguna página a partir del PDF.';

  @override
  String get cbzEncodingFailed => 'Error al codificar el archivo CBZ.';

  @override
  String get finalizingCover => 'Finalizando y extrayendo la portada...';

  @override
  String get conversionDone => '¡Conversión completada correctamente!';

  @override
  String get cbzNotFound => 'Archivo CBZ no encontrado en el dispositivo.';

  @override
  String get noValidImageInCbz => 'No se encontró ninguna imagen válida en este archivo CBZ.';

  @override
  String cbzReadError(Object sizeMb, Object e) {
    return 'Error de lectura ($sizeMb MB): $e\n\nPuede que el archivo esté dañado o que la descarga esté incompleta.';
  }

  @override
  String pagesCount(Object length) {
    return 'Páginas ($length)';
  }

  @override
  String get loadingVolume => 'Cargando el tomo...';

  @override
  String get volumeFinished => '¡Tomo terminado! 🎉';

  @override
  String nextVolumeWithTitle(Object title) {
    return 'Pasar al siguiente tomo ➔\n$title';
  }

  @override
  String bookSyncUnavailable(Object error) {
    return 'Sincronización no disponible para este libro. Se mantiene la lectura local: $error';
  }

  @override
  String get progressFoundElsewhere => 'Progreso encontrado en otro dispositivo';

  @override
  String otherPositionOnDevice(Object remoteDeviceName) {
    return '«$remoteDeviceName» tiene otra posición para este libro.';
  }

  @override
  String get thisDevice => 'Este dispositivo';

  @override
  String get keepHere => 'Mantener aquí';

  @override
  String continueFromDevice(Object remoteDeviceName) {
    return 'Continuar desde $remoteDeviceName';
  }

  @override
  String get downloadFailed => 'Error en la descarga';

  @override
  String get convertingHdCbz => 'Conversión HD a CBZ (modo cómic)...';

  @override
  String get downloadingYourComic => 'Descargando tu cómic...';

  @override
  String get networkErrorOccurred => 'Se produjo un error de red.';

  @override
  String get convertingHdInProgress => 'Conversión HD en curso...';

  @override
  String get deleteFromDeviceTitle => '¿Eliminar del dispositivo?';

  @override
  String deleteDownloadedFileBody(Object name) {
    return '¿Quieres eliminar el archivo descargado localmente de \"$name\" para liberar espacio?\n\nEl archivo sigue disponible y descargable desde tu servidor.';
  }

  @override
  String deletedFromDevice(Object name) {
    return '\"$name\" se ha eliminado de tu dispositivo.';
  }

  @override
  String get deleteLocalCopy => 'Eliminar la copia local';

  @override
  String get downloadForOffline => 'Descargar para leer sin conexión';

  @override
  String get updateAvailable => '¡Actualización disponible!';

  @override
  String get whatsNew => 'Novedades:';

  @override
  String get defaultReleaseNotes => 'Mejoras de rendimiento y corrección de errores.';

  @override
  String get downloadApk => 'Descargar APK';

  @override
  String get almostDone => 'Casi terminado...';

  @override
  String secondsLeft(Object seconds) {
    return '~ $seconds s restantes';
  }

  @override
  String itemsCount(Object itemCount) {
    return '$itemCount elementos';
  }

  @override
  String readOfTotal(Object completedBooks, Object totalBooks) {
    return '$completedBooks/$totalBooks leído(s)';
  }

  @override
  String get emptyServerResponse => 'Respuesta vacía del servidor';

  @override
  String chapterN(Object length1) {
    return 'Capítulo $length1';
  }

  @override
  String chapterNIdx(Object idx1) {
    return 'Capítulo $idx1';
  }

  @override
  String get pdfNotFoundOnDevice => 'Archivo PDF no encontrado en el dispositivo.';

  @override
  String get convertToCbzComicMode => 'Convertir a CBZ (modo cómic)';

  @override
  String get pressAgainToExit => 'Pulsa de nuevo para salir de ComicStream';

  @override
  String get downloadsTabShort => 'Descarg.';

  @override
  String get settingsTab => 'Ajustes';

  @override
  String get invalidJsonFormat => 'Formato JSON no válido';

  @override
  String cannotLoadFolder(Object e) {
    return 'No se puede cargar la carpeta: $e';
  }

  @override
  String get newUpdateAvailable => 'Hay una nueva actualización disponible.';

  @override
  String get unknownEncryptionVersion => 'Versión de cifrado desconocida';

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
      other: '$count tomos',
      one: '1 tomo',
    );
    return '$_temp0';
  }

  @override
  String chapterSlashPercent(Object current, Object total, Object percent) {
    return 'Capítulo $current/$total · $percent %';
  }

  @override
  String labelLocationDate(Object label, Object location, Object date, Object time) {
    return '$label: $location\n$date a las $time';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get edit => 'Editar';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get save => 'Guardar';

  @override
  String get view => 'Ver';

  @override
  String get synchronize => 'Sincronizar';

  @override
  String get back => 'Atrás';

  @override
  String get none => 'Ninguno';

  @override
  String get all => 'Todo';

  @override
  String get importAction => 'Importar';

  @override
  String get everyone => 'Todos';

  @override
  String get clean => 'Limpiar';

  @override
  String get read => 'Leer';

  @override
  String get dark => 'Oscuro';

  @override
  String get mint => 'Menta';

  @override
  String get light => 'Claro';

  @override
  String get standard => 'Estándar';

  @override
  String get large => 'Ancho';

  @override
  String get libraryTab => 'Biblio';

  @override
  String get serverTab => 'Servidor';

  @override
  String get filesTab => 'Archivos';

  @override
  String get delete => 'Eliminar';

  @override
  String get resume => 'Continuar';

  @override
  String get progress => 'Progreso';

  @override
  String get favorites => 'Favoritos';

  @override
  String get close => 'Cerrar';

  @override
  String get options => 'Opciones';

  @override
  String get search => 'Buscar';

  @override
  String get refresh => 'Actualizar';

  @override
  String get root => 'Raíz';

  @override
  String get empty => 'Vaciar';

  @override
  String get font => 'Fuente';

  @override
  String get lineSpacing => 'Interlineado';

  @override
  String get compact => 'Compacto';

  @override
  String get normal => 'Normal';

  @override
  String get relaxed => 'Amplio';

  @override
  String get margin => 'Margen';

  @override
  String get narrowShort => 'Estrecho';

  @override
  String get yesterday => 'Ayer';

  @override
  String get today => 'Hoy';

  @override
  String get folder => 'Carpeta';

  @override
  String get convert => 'Convertir';

  @override
  String get width => 'Ancho';

  @override
  String get height => 'Alto';

  @override
  String get black => 'Negro';

  @override
  String get grey => 'Gris';

  @override
  String get white => 'Blanco';

  @override
  String get downloaded => 'Descargado';

  @override
  String get serverDefaultName => 'Servidor';

  @override
  String get test => 'Probar';

  @override
  String get type => 'Tipo';

  @override
  String get port => 'Puerto';

  @override
  String get path => 'Ruta';

  @override
  String get credentials => 'Credenciales';

  @override
  String get ignore => 'Ignorar';

  @override
  String get noneLower => 'ninguno';

  @override
  String get serverUpper => 'SERVIDOR';

  @override
  String get bookUpper => 'LIBRO';

  @override
  String get resumeUpper => 'CONTINUAR';

  @override
  String get currentUpper => 'ACTUAL';

  @override
  String get lineSpacingUpper => 'INTERLINEADO';

  @override
  String get alignmentUpper => 'ALINEACIÓN';

  @override
  String get comicsFilter => 'Cómics';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navServers => 'Servidores';

  @override
  String get computerFiles => 'Archivos del ordenador';

  @override
  String get addComicsFromComputerBody => 'Elige cómics (CBZ, CBR, PDF, EPUB) o una carpeta entera para analizar. Un doble clic en el Explorador también los abre directamente.';

  @override
  String get openFiles => 'Abrir archivos…';

  @override
  String get scanFolder => 'Analizar una carpeta…';

  @override
  String get columnTitle => 'Título';

  @override
  String get columnFormat => 'Formato';

  @override
  String get columnSize => 'Tamaño';

  @override
  String get columnAdded => 'Añadido';

  @override
  String get doublePageTitle => 'Doble página en pantallas grandes';

  @override
  String get doublePageBody => 'Dos páginas una al lado de otra cuando la ventana es ancha y horizontal';

  @override
  String get onePage => '1 página';

  @override
  String get twoPages => '2 páginas';

  @override
  String get togglePagesPerView => 'Mostrar 1 o 2 páginas (D)';

  @override
  String get selectAll => 'Seleccionar todo';

  @override
  String get clearSelection => 'Anular la selección';

  @override
  String get moveToSeries => 'Mover a una serie';

  @override
  String get seriesNameLabel => 'Nombre de la serie';

  @override
  String get automaticSeries => 'Serie automática';

  @override
  String get move => 'Mover';

  @override
  String deleteSelectedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Eliminar $count libros?',
      one: '¿Eliminar 1 libro?',
    );
    return '$_temp0';
  }

  @override
  String get deleteSelectedBody => 'Los archivos se eliminarán de este dispositivo. Los de tus servidores no se tocan.';

  @override
  String librarySelectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seleccionados',
      one: '1 seleccionado',
    );
    return '$_temp0';
  }

  @override
  String get languageTitle => 'Idioma';

  @override
  String get systemLanguage => 'Idioma del sistema';

  @override
  String get googleBrowserDone => 'Sesión iniciada. Puede cerrar esta pestaña y volver a ComicStream.';

  @override
  String get googleBrowserFailed => 'Error al iniciar sesión con Google. Cierre esta pestaña y vuelva a intentarlo desde ComicStream.';

  @override
  String get readAgain => 'Volver a leer';

  @override
  String resumeVolumeNumber(int number) {
    return 'Continuar el tomo $number';
  }

  @override
  String readVolumeNumber(int number) {
    return 'Leer el tomo $number';
  }

  @override
  String get startReading => 'Empezar';

  @override
  String get seeVolumes => 'Ver los tomos';

  @override
  String get openSeriesSheet => 'Ficha de la serie';

  @override
  String get consoleEmpty => 'Ninguna serie en este filtro';

  @override
  String get consoleHintMove => 'Moverse';

  @override
  String get consoleHintOpen => 'Abrir';

  @override
  String get consoleHintBack => 'Volver';

  @override
  String get consoleHintFilter => 'Filtro';

  @override
  String get consoleView => 'Consola';

  @override
  String get consoleQueue => 'Cola';

  @override
  String get consoleQueueHint => 'en orden de inicio';

  @override
  String get consoleReady => 'Listo para leer';

  @override
  String get consoleFailed => 'Error · reintentar';

  @override
  String get consoleCancelled => 'Cancelado · reiniciar';

  @override
  String get consoleChooseServer => 'Elige un servidor para explorar sus carpetas.';

  @override
  String consoleItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos',
      one: '1 elemento',
    );
    return '$_temp0';
  }

  @override
  String consoleDownloadMissing(int count) {
    return 'Descargar los $count que faltan';
  }

  @override
  String get consoleHintOpenDownload => 'Abrir / descargar';

  @override
  String get consoleHintReadRetry => 'Leer / reintentar';

  @override
  String get consoleAlreadyQueued => 'Ya está en la cola de descargas';

  @override
  String get consoleNothingYet => 'Aún no hay descargas';

  @override
  String get consoleSwitchPage => 'Página siguiente';

  @override
  String get pause => 'Pausa';

  @override
  String get pausedStatus => 'En pausa';

  @override
  String get consoleHintPause => 'Pausa / reanudar';

  @override
  String get keySpace => 'Espacio';

  @override
  String get downloadUpdate => 'Descargar la actualización';
}
