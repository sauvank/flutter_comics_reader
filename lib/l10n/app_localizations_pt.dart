import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get resetVaultTitle => 'Redefinir o cofre?';

  @override
  String get resetVaultBody => 'Se perdeu a sua frase de recuperação, a redefinição criará um cofre novo e vazio. Os dados protegidos dos seus outros dispositivos terão de ser sincronizados novamente.';

  @override
  String get reset => 'Redefinir';

  @override
  String get confirmSecretPhrase => 'Confirmar a frase secreta';

  @override
  String get secretPhraseWrittenDownBody => 'Anotou a sua frase secreta num local seguro?\n\nEla é indispensável para restaurar os seus dados ou sincronizar um novo dispositivo. O ComicStream não a guarda e nunca a poderá recuperar por si.';

  @override
  String get yourSecretPhrase => 'A sua frase secreta:';

  @override
  String get phraseNotedContinue => 'Já anotei, continuar';

  @override
  String get changeSecretPhrase => 'Alterar a frase secreta';

  @override
  String get changeSecretPhraseBody => 'Defina uma nova frase secreta (mínimo 16 caracteres) para proteger a sua sincronização.';

  @override
  String get newSecretPhrase => 'Nova frase secreta';

  @override
  String get min16Characters => 'Mínimo 16 caracteres';

  @override
  String get showPhrase => 'Mostrar a frase';

  @override
  String get hidePhrase => 'Ocultar a frase';

  @override
  String get confirmNewPhrase => 'Confirmar a nova frase';

  @override
  String get phraseTooShort => 'A frase deve ter pelo menos 16 caracteres.';

  @override
  String get phrasesDoNotMatch => 'As duas frases não coincidem.';

  @override
  String get confirmChangeTitle => 'Confirmar a alteração?';

  @override
  String get confirmChangeBody => 'O seu cofre será atualizado com esta nova frase secreta.\nCertifique-se de que a anotou:';

  @override
  String get confirmAndSave => 'Confirmar e guardar';

  @override
  String get secretPhraseUpdated => 'Frase secreta atualizada com sucesso.';

  @override
  String get operationDone => 'Operação concluída.';

  @override
  String cannotContinue(Object error) {
    return 'Não é possível continuar: $error';
  }

  @override
  String dateAtTime(Object date, Object time) {
    return '$date às $time';
  }

  @override
  String get syncConflict => 'Conflito de sincronização';

  @override
  String syncConflictBody(Object label) {
    return 'Foram modificadas duas versões de «$label».';
  }

  @override
  String thisDeviceValue(Object formatConflictDate) {
    return 'Este dispositivo: $formatConflictDate';
  }

  @override
  String syncServerValue(Object formatConflictDate) {
    return 'Servidor de sincronização: $formatConflictDate';
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
  String get chooseReferenceVersion => 'Escolha a versão de referência. Ela será depois sincronizada nos seus outros dispositivos.';

  @override
  String get fetchFromServer => 'Obter do servidor';

  @override
  String get sendToServer => 'Enviar para o servidor';

  @override
  String get later => 'Mais tarde';

  @override
  String get thisDeviceName => 'Nome deste dispositivo';

  @override
  String get deviceNameHint => 'Ex.: Tablet ou Telemóvel';

  @override
  String get deviceNameSavedOnServer => 'Nome do dispositivo guardado no servidor.';

  @override
  String get deviceNameSavedLocally => 'Nome guardado neste dispositivo. Será enviado na próxima sincronização.';

  @override
  String cannotPrepareSync(Object error) {
    return 'Não é possível preparar a sincronização: $error';
  }

  @override
  String get whichBackupToUse => 'Que cópia de segurança usar?';

  @override
  String get whichBackupBody => 'A sua escolha torna-se a referência partilhada. Os outros dispositivos recebê-la-ão na próxima sincronização.';

  @override
  String get notBackedUpYet => 'Ainda sem cópia de segurança';

  @override
  String backedUpAt(Object formatConflictDate) {
    return 'Cópia guardada $formatConflictDate';
  }

  @override
  String get accountAndSync => 'Conta e sincronização';

  @override
  String get syncUnavailableNoFirebase => 'A sincronização estará disponível após a configuração do projeto Firebase. O leitor e os seus dados locais continuam a funcionar normalmente.';

  @override
  String get accountConnected => 'Sessão iniciada';

  @override
  String get vaultUnlockedE2e => 'Cofre desbloqueado. Os seus dados estão encriptados de ponta a ponta.';

  @override
  String get vaultLockedOrNew => 'Cofre bloqueado ou não inicializado.';

  @override
  String get unlockVault => 'Desbloquear o cofre';

  @override
  String get initEncryptedVault => 'Criar o seu cofre encriptado';

  @override
  String get unlockVaultBody => 'Existe um cofre encriptado associado a esta conta. Introduza a sua frase de recuperação para desbloquear a sincronização neste dispositivo.';

  @override
  String get initVaultBody => 'Para proteger as palavras-passe dos servidores e os seus dados, escolha uma frase secreta (mínimo 16 caracteres). Ela é indispensável para restaurar os seus dados num novo dispositivo.';

  @override
  String get recoveryPhrase => 'Frase de recuperação';

  @override
  String get secretPhraseMin16 => 'Frase secreta (mínimo 16 caracteres)';

  @override
  String get enterRecoveryPhrase => 'Introduza a sua frase de recuperação.';

  @override
  String get secretPhraseTooShort => 'A frase secreta deve ter pelo menos 16 caracteres.';

  @override
  String get secretPhrasesDoNotMatch => 'As frases secretas não coincidem.';

  @override
  String get unlockSync => 'Desbloquear a sincronização';

  @override
  String get createAndEnableVault => 'Criar e ativar o cofre';

  @override
  String get forgotPhraseReset => 'Esqueceu a frase? Redefinir o cofre';

  @override
  String get vaultUnlocked => 'Cofre desbloqueado';

  @override
  String get syncActiveE2e => 'A sincronização está ativa e protegida por encriptação de ponta a ponta.';

  @override
  String get syncing => 'A sincronizar…';

  @override
  String get changePhrase => 'Alterar a frase';

  @override
  String get shownWhenChoosingBackup => 'Mostrado ao escolher uma cópia de segurança';

  @override
  String get signOut => 'Terminar sessão';

  @override
  String get createAccount => 'Criar uma conta';

  @override
  String get signIn => 'Iniciar sessão';

  @override
  String get passwordMin12 => 'Palavra-passe (mínimo 12 caracteres)';

  @override
  String get showPassword => 'Mostrar a palavra-passe';

  @override
  String get hidePassword => 'Ocultar a palavra-passe';

  @override
  String get createTheAccount => 'Criar a conta';

  @override
  String get alreadyHaveAccount => 'Já tenho uma conta';

  @override
  String get continueWithGoogle => 'Continuar com o Google';

  @override
  String get recoveryPhraseRequiredNote => 'A frase de recuperação é indispensável para restaurar as palavras-passe dos servidores num novo dispositivo. Nunca é guardada pelo ComicStream.';

  @override
  String androidCertNotAllowed(Object hashes) {
    return 'Certificado Android não autorizado: $hashes';
  }

  @override
  String pendingConflicts(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alterações aguardam a sua escolha.',
      one: '1 alteração aguarda a sua escolha.',
    );
    return '$_temp0';
  }

  @override
  String upToDate(Object fullVersion) {
    return 'O ComicStream está atualizado ($fullVersion)!';
  }

  @override
  String get updateCheckError => 'Erro ao procurar atualizações';

  @override
  String get clearCacheTitle => 'Limpar a cache?';

  @override
  String get clearCacheBody => 'As capas serão recarregadas automaticamente.';

  @override
  String get coverCacheCleared => 'Cache das capas limpa com sucesso!';

  @override
  String get deleteAllTitle => 'Eliminar tudo?';

  @override
  String get deleteAllBody => 'Isto eliminará todas as BD e mangás transferidos localmente para libertar espaço. As definições dos seus servidores serão mantidas.';

  @override
  String get allLocalFilesDeleted => 'Todos os ficheiros locais foram eliminados.';

  @override
  String get eraseAll => 'Apagar tudo';

  @override
  String get commandCopied => 'Comando copiado!';

  @override
  String get localServerGuide => 'Guia do servidor local';

  @override
  String get guideOption1 => 'Opção 1: servidor WebDAV com Docker (recomendado)';

  @override
  String get guideOption1Body => 'Inicie um servidor WebDAV leve com Docker numa só linha, apontando para a sua pasta de BD:';

  @override
  String get guideOption2 => 'Opção 2: script Python pronto a usar';

  @override
  String get guideOption2Body => 'Está incluído um servidor Python dedicado em `server_example/comic_server.py`. Para o iniciar:';

  @override
  String get guideOption3 => 'Opção 3: NAS Synology / TrueNAS / Nextcloud';

  @override
  String get guideOption3Body => 'Basta ativar o serviço WebDAV no painel de administração do seu NAS (porta 5005 por predefinição no Synology) e introduzir as suas credenciais na app.';

  @override
  String get settings => 'Definições';

  @override
  String get accountAndSyncShort => 'Conta e sincronização';

  @override
  String get accountAndSyncSubtitle => 'Servidores, progresso e definições encriptados';

  @override
  String get appearanceTheme => 'Aparência e tema';

  @override
  String get appTheme => 'Tema da app';

  @override
  String get readerPreferences => 'Preferências do leitor';

  @override
  String get defaultReadingMode => 'Modo de leitura predefinido';

  @override
  String get readingModeComic => 'BD (esquerda para a direita)';

  @override
  String get readingModeManga => 'Mangá (direita para a esquerda)';

  @override
  String get readingModeWebtoon => 'Webtoon (deslocamento vertical)';

  @override
  String get keepScreenOn => 'Manter o ecrã ligado durante a leitura';

  @override
  String get showPageNumber => 'Mostrar o número da página';

  @override
  String get autoConvertPdf => 'Converter automaticamente PDF em CBZ';

  @override
  String get autoConvertPdfBody => 'Transforma cada PDF transferido num arquivo de BD muito fluido para tablets.';

  @override
  String get comicRenderQuality => 'Qualidade de renderização das BD';

  @override
  String get qualityAutoLong => 'Automática (deteta o ecrã + 35% de nitidez)';

  @override
  String get qualitySuperLong => 'Sobreamostragem (2600px - zoom nítido)';

  @override
  String get qualityUltraLong => 'Ultra HD (3500px - definição máxima)';

  @override
  String get qualityStandardLong => 'Padrão 1:1 (1900px - rápido)';

  @override
  String get qualityAuto => 'Auto (ecrã + 35%)';

  @override
  String get qualityHigh => 'Alta (2600px)';

  @override
  String get qualityStandard => 'Padrão 1:1';

  @override
  String get ebooksEpub => 'E-books e EPUB';

  @override
  String get fontSize => 'Tamanho da letra';

  @override
  String get justifiedText => 'Texto justificado';

  @override
  String get storageCache => 'Armazenamento e cache';

  @override
  String get spaceUsedByBooks => 'Espaço ocupado pelos livros:';

  @override
  String booksDownloadedCount(Object length) {
    return '$length livro(s) transferido(s)';
  }

  @override
  String get clearCache => 'Limpar cache';

  @override
  String get updates => 'Atualizações';

  @override
  String get checkForUpdate => 'Procurar atualizações';

  @override
  String installedVersion(Object fullVersion) {
    return 'Versão instalada: $fullVersion';
  }

  @override
  String get check => 'Verificar';

  @override
  String get seeStoreListing => 'Ver a página oficial do ComicStream';

  @override
  String get helpSetup => 'Ajuda e configuração';

  @override
  String get howToSetupLocalServer => 'Como configuro o meu servidor local?';

  @override
  String get helpSetupSubtitle => 'Docker, Python, NAS Synology, TrueNAS...';

  @override
  String get appTagline => 'Leitor de BD e mangás na nuvem';

  @override
  String get deleteBookTitle => 'Eliminar este livro?';

  @override
  String deleteBookBody(Object title) {
    return 'Quer eliminar \"$title\" do seu armazenamento local?';
  }

  @override
  String resumeAtChapter(Object title, Object currentPage1) {
    return '«$title» já tinha sido iniciado. Retomar no capítulo $currentPage1?';
  }

  @override
  String resumeAtPage(Object title, Object currentPage1) {
    return '«$title» já tinha sido iniciado. Retomar na página $currentPage1?';
  }

  @override
  String get myLibrary => 'A minha biblioteca';

  @override
  String comicsCount(Object length) {
    return '$length BD';
  }

  @override
  String get syncInProgress => 'Sincronização em curso';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get lastRead => 'Última leitura';

  @override
  String get titleAz => 'Título (A-Z)';

  @override
  String get dateAdded => 'Data de adição';

  @override
  String seriesCount(Object length) {
    return 'Séries ($length)';
  }

  @override
  String volumesCount(Object length) {
    return 'Volumes ($length)';
  }

  @override
  String get searchLibraryHint => 'Procurar uma série, um volume, um autor...';

  @override
  String get recentlyOpened => 'Abertos recentemente';

  @override
  String myCollectionsCount(Object length) {
    return 'As minhas coleções e séries ($length)';
  }

  @override
  String get backToSeries => 'Voltar às séries';

  @override
  String seriesProgress(Object completedBooks, Object totalBooks, Object progressPercent) {
    return '$completedBooks/$totalBooks volumes lidos • $progressPercent%';
  }

  @override
  String get checkNewVolumes => 'Procurar novos volumes no servidor';

  @override
  String get nextVolumeToRead => 'PRÓXIMO VOLUME A LER';

  @override
  String get nextVolumeOnServer => 'PRÓXIMO VOLUME NO SERVIDOR';

  @override
  String get download => 'Transferir';

  @override
  String downloadStarted(Object name) {
    return '📥 Transferência iniciada: $name';
  }

  @override
  String get readNow => 'Ler já';

  @override
  String get searchingNextVolumes => 'A procurar os próximos volumes no servidor remoto...';

  @override
  String downloadedVolumesCount(Object totalBooks) {
    return 'Volumes transferidos ($totalBooks)';
  }

  @override
  String serverVolumesCount(Object length) {
    return 'Volumes disponíveis no servidor ($length)';
  }

  @override
  String downloadAllCount(Object length) {
    return 'Transferir tudo ($length)';
  }

  @override
  String volumesQueued(Object length) {
    return '📥 $length volumes adicionados à fila de transferências';
  }

  @override
  String downloadingName(Object name) {
    return '📥 A transferir: $name';
  }

  @override
  String get libraryFilters => 'Filtros da biblioteca';

  @override
  String allCount(Object length) {
    return 'Todos ($length)';
  }

  @override
  String get inProgress => 'Em curso';

  @override
  String get unread => 'Não lidos';

  @override
  String get epubNovels => 'EPUB / Romances';

  @override
  String get finished => 'Terminados';

  @override
  String get continueReading => 'CONTINUAR A LER';

  @override
  String get libraryEmpty => 'A sua biblioteca está vazia';

  @override
  String get libraryEmptyBody => 'Adicione BD a partir de um servidor ou de ficheiros já presentes no seu telemóvel.';

  @override
  String get exploreServers => 'Explorar os meus servidores';

  @override
  String get importFromPhone => 'Importar deste telemóvel';

  @override
  String get noSearchResults => 'Sem resultados para esta pesquisa';

  @override
  String get noSearchResultsBody => 'Experimente outra palavra-chave ou reponha os filtros.';

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
  String get setupServer => 'Configurar um servidor';

  @override
  String connectionSucceeded(Object name) {
    return 'Ligado a $name!';
  }

  @override
  String connectionFailed(Object name) {
    return 'Falha na ligação a $name';
  }

  @override
  String get deleteServerTitle => 'Eliminar este servidor?';

  @override
  String deleteServerBody(Object name) {
    return 'Quer mesmo eliminar \"$name\" das suas fontes remotas?';
  }

  @override
  String get exportConfiguration => 'Exportar a configuração';

  @override
  String get exportConfigurationBody => 'Eis o ficheiro de configuração JSON com os seus perfis de servidor:';

  @override
  String get copyJson => 'Copiar JSON';

  @override
  String get configurationCopied => '✅ Configuração copiada para a área de transferência!';

  @override
  String get importConfiguration => 'Importar uma configuração';

  @override
  String get chooseJsonFile => 'Escolher um ficheiro .json';

  @override
  String fileReadError(Object e) {
    return 'Erro ao ler o ficheiro: $e';
  }

  @override
  String get orPasteJson => 'Ou cole o JSON aqui:';

  @override
  String serversImported(Object count) {
    return '✅ $count servidor(es) importado(s) com sucesso!';
  }

  @override
  String baseLocationSet(Object currentPath) {
    return '✅ Localização base definida para: $currentPath';
  }

  @override
  String get myServers => 'Os meus servidores';

  @override
  String get addServer => 'Adicionar um servidor';

  @override
  String get howToSetupServer => 'Como configurar um servidor';

  @override
  String get exportConfigurations => 'Exportar as configurações';

  @override
  String get testConnection => 'Testar a ligação';

  @override
  String get filterFolderHint => 'Filtrar esta pasta...';

  @override
  String get closeSearch => 'Fechar a pesquisa';

  @override
  String get folderOptions => 'Opções da pasta';

  @override
  String get setFolderAsRoot => 'Definir esta pasta como raiz';

  @override
  String get switchServer => 'Mudar de servidor';

  @override
  String get parentFolder => 'Pasta superior';

  @override
  String everythingCount(Object length) {
    return 'Tudo ($length)';
  }

  @override
  String get downloadAllTitle => 'Transferir tudo?';

  @override
  String downloadAllBody(Object length) {
    return '$length volumes serão transferidos em segundo plano.';
  }

  @override
  String volumesQueuedCount(Object length) {
    return '📥 $length volume(s) adicionado(s) à fila de transferências';
  }

  @override
  String foldersSeriesCount(Object length) {
    return 'Pastas e séries ($length)';
  }

  @override
  String booksComicsCount(Object length) {
    return 'Livros e BD ($length)';
  }

  @override
  String downloadingNamePlain(Object name) {
    return 'A transferir: $name';
  }

  @override
  String get folderEmpty => 'Esta pasta está vazia';

  @override
  String get folderEmptyBody => 'Nenhum livro ou subpasta encontrado nesta localização.';

  @override
  String get cannotConnectServer => 'Não é possível ligar ao servidor';

  @override
  String checkServerReachable(Object baseUrl) {
    return 'Verifique se o servidor está acessível em $baseUrl.';
  }

  @override
  String get editSettings => 'Editar as definições';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get googleTokenMissing => 'Token de autenticação Google não encontrado.';

  @override
  String get googleSignInUnavailable => 'O início de sessão com o Google não está disponível neste dispositivo.';

  @override
  String get recoveryPhraseTooShort => 'A frase de recuperação deve ter pelo menos 16 caracteres.';

  @override
  String get signInRequired => 'Início de sessão obrigatório';

  @override
  String get noSyncVaultFound => 'Nenhum cofre de sincronização encontrado.';

  @override
  String get vaultMustBeUnlocked => 'O cofre tem de estar desbloqueado para alterar a frase secreta.';

  @override
  String get recoveryPhraseRequiredHere => 'Frase de recuperação necessária neste dispositivo.';

  @override
  String get serverConfigurations => 'Configurações dos servidores';

  @override
  String get readingSettings => 'Definições de leitura';

  @override
  String get deviceNameLength => 'O nome deve ter entre 1 e 40 caracteres.';

  @override
  String deviceDefaultName(Object substring) {
    return 'Dispositivo $substring';
  }

  @override
  String get otherDevice => 'Outro dispositivo';

  @override
  String get remoteProgressGone => 'Este progresso remoto já não existe.';

  @override
  String thisDeviceNamed(Object currentName) {
    return 'Este dispositivo — $currentName';
  }

  @override
  String get deviceBackupNotFound => 'A cópia de segurança deste dispositivo não foi encontrada.';

  @override
  String get googleDataNotFound => 'Os dados Google a resolver não foram encontrados.';

  @override
  String get localProgressGone => 'O progresso local correspondente já não existe.';

  @override
  String get unknownSyncDocument => 'Documento de sincronização desconhecido';

  @override
  String get readingSettingsShort => 'Definições de leitura';

  @override
  String get yes => 'sim';

  @override
  String get no => 'não';

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
      other: '$count perfis de servidor',
      one: '1 perfil de servidor',
      zero: '0 perfis de servidor',
    );
    return '$_temp0';
  }

  @override
  String ftpInvalidServer(Object banner) {
    return 'Servidor FTP inválido: $banner';
  }

  @override
  String ftpCredentialsRefused(Object passResp) {
    return 'Credenciais FTP recusadas: $passResp';
  }

  @override
  String ftpUsernameRefused(Object userResp) {
    return 'Utilizador FTP recusado: $userResp';
  }

  @override
  String ftpPassiveFailed(Object pasvResp) {
    return 'Falha do modo passivo FTP: $pasvResp';
  }

  @override
  String ftpDownloadFailed(Object retrResp) {
    return 'Não é possível transferir o ficheiro FTP: $retrResp';
  }

  @override
  String get ftpIdleTimeout => 'Tempo de inatividade FTP excedido';

  @override
  String ftpPasvUnrecognized(Object response) {
    return 'Resposta PASV não reconhecida: $response';
  }

  @override
  String get guideHeroTitle => 'Leia as BD do seu computador ou NAS';

  @override
  String get guideHeroBody => 'Um servidor torna a sua coleção acessível a partir do telemóvel, sem copiar tudo. Demora cerca de 2 minutos.';

  @override
  String get howItWorks => 'Como fazer';

  @override
  String get guideStep1Title => 'Partilhe a sua pasta de BD';

  @override
  String get guideStep1Body => 'No seu NAS ou computador, ative uma partilha WebDAV, FTP ou HTTP que aponte para a pasta com os seus ficheiros CBZ, CBR, PDF ou EPUB. Os exemplos abaixo detalham cada caso.';

  @override
  String get guideStep2Title => 'Anote o endereço';

  @override
  String get guideStep2Body => 'Encontre o endereço IP local da máquina (ex.: 192.168.1.100) e a porta da partilha. O telemóvel tem de estar ligado à mesma rede Wi-Fi.';

  @override
  String get guideStep3Title => 'Preencha o formulário';

  @override
  String get guideStep3Body => 'Toque em «Adicionar um servidor», escolha o tipo e introduza o anfitrião, a porta, o caminho da pasta e, se necessário, o utilizador e a palavra-passe.';

  @override
  String get guideStep4Title => 'Teste e guarde';

  @override
  String get guideStep4Body => '«Testar» verifica a ligação. Depois de validada, «Guardar» abre diretamente o servidor para explorar e transferir os seus livros.';

  @override
  String get configurationExamples => 'Exemplos de configuração';

  @override
  String get webdavSubtitle => 'Recomendado · NAS Synology, QNAP, Nextcloud';

  @override
  String get host => 'Anfitrião';

  @override
  String get webdavPorts => '5005 (Synology), 80 ou 443';

  @override
  String get webdavCredentials => 'as da sua conta do NAS';

  @override
  String get webdavTip => 'No Synology: instale «WebDAV Server» a partir do Centro de pacotes e ative HTTP ou HTTPS.';

  @override
  String get httpSubtitle => 'O mais simples a partir de um computador';

  @override
  String get computerIp => 'IP do computador';

  @override
  String get httpTip => 'Na sua pasta de BD, execute «python3 -m http.server 8080» ou o script server_example/comic_server.py incluído no ComicStream.';

  @override
  String get ftpSubtitle => 'Routers, NAS mais antigos';

  @override
  String get ftpCredentials => 'conta FTP do router ou do NAS';

  @override
  String get ftpTip => 'O FTP não é encriptado: use-o apenas na sua rede doméstica.';

  @override
  String get cannotConnectTitle => 'Não liga?';

  @override
  String get tipSameWifi => 'Verifique se o telemóvel e o servidor estão na mesma Wi-Fi.';

  @override
  String get tipUseIp => 'Experimente o endereço IP em vez de um nome (nas.local).';

  @override
  String get tipFirewall => 'Verifique se a firewall do computador permite a porta escolhida.';

  @override
  String get tipVpn => 'Fora de casa, use uma VPN (WireGuard, Tailscale…) em vez de expor o servidor na Internet.';

  @override
  String get importExistingConfiguration => 'Importar uma configuração existente';

  @override
  String get waiting => 'Em espera...';

  @override
  String get downloadingEllipsis => 'A transferir...';

  @override
  String get cancelled => 'Cancelado';

  @override
  String get extractingFinalizing => 'A extrair e finalizar...';

  @override
  String get convertingHd => 'A converter em BD HD...';

  @override
  String secondsRemaining(Object approxSec) {
    return ' ~ ${approxSec}s restantes';
  }

  @override
  String convertingHdProgress(Object currentPage, Object totalPages, Object etaText) {
    return 'Conversão HD ($currentPage/$totalPages páginas)$etaText';
  }

  @override
  String get finishedStatus => 'Concluído';

  @override
  String get failed => 'Falhou';

  @override
  String get networkTimeout => 'Tempo esgotado (rede)';

  @override
  String get invalidCertificate => 'Certificado de segurança inválido (servidor autoassinado?)';

  @override
  String get fileNotFound404 => 'Ficheiro não encontrado no servidor (404)';

  @override
  String get accessDenied => 'Acesso negado (credenciais incorretas)';

  @override
  String get cannotReachServerLost => 'Não é possível contactar o servidor (ligação perdida)';

  @override
  String get downloadCancelled => 'Transferência cancelada';

  @override
  String get networkInterrupted => 'Ligação de rede interrompida';

  @override
  String get notEnoughStorage => 'Espaço de armazenamento insuficiente no dispositivo';

  @override
  String get networkError => 'Erro de ligação de rede';

  @override
  String get localFileAccessError => 'Erro de acesso ao ficheiro local';

  @override
  String get serverError => 'Erro do servidor';

  @override
  String serverErrorCode(Object code) {
    return 'Erro do servidor ($code)';
  }

  @override
  String get endOfBookReached => 'Chegou ao fim do livro!';

  @override
  String get loadingBook => 'A carregar o livro...';

  @override
  String get cannotLoadBook => 'Não é possível carregar este livro';

  @override
  String get fileMaybeCorrupted => 'O ficheiro pode estar danificado ou num formato não suportado.';

  @override
  String get backToLibrary => 'Voltar à biblioteca';

  @override
  String epubProgressShort(Object value, Object currentChapterIndex1, Object length) {
    return '$value% • Cap. $currentChapterIndex1/$length';
  }

  @override
  String get tableOfContents => 'Índice';

  @override
  String get customizeReading => 'Personalizar a leitura';

  @override
  String chapterXOfY(Object currentChapterIndex1, Object length) {
    return 'Capítulo $currentChapterIndex1 / $length';
  }

  @override
  String endOfChapter(Object currentChapterIndex1) {
    return 'Fim do capítulo $currentChapterIndex1';
  }

  @override
  String get nextChapterUpper => 'PRÓXIMO CAPÍTULO';

  @override
  String get bookFinished => 'Terminou este livro!';

  @override
  String get tableOfContentsTitle => 'Índice';

  @override
  String get searchChapterHint => 'Procurar um capítulo...';

  @override
  String noChapterFound(Object tocSearchQuery) {
    return 'Nenhum capítulo encontrado para \"$tocSearchQuery\"';
  }

  @override
  String get bookCustomization => 'Personalização do livro';

  @override
  String get themeColorsUpper => 'TEMA E CORES';

  @override
  String get sepia => 'Sépia';

  @override
  String get textSizeUpper => 'TAMANHO DO TEXTO';

  @override
  String get fontUpper => 'TIPO DE LETRA';

  @override
  String get serifBook => 'Serif (livro)';

  @override
  String get bookMarginsUpper => 'MARGENS DO LIVRO';

  @override
  String get narrow => 'Estreito';

  @override
  String get connectionFailedCheck => '❌ Falha na ligação. Verifique o endereço IP, a porta e as credenciais.';

  @override
  String get connectionOkFolderValid => '✅ Ligação estabelecida e pasta validada!';

  @override
  String folderMissingOnServer(Object path) {
    return '❌ O servidor responde, mas a pasta \"$path\" não existe no servidor.';
  }

  @override
  String get checkingFolder => 'A verificar a pasta no servidor...';

  @override
  String get cannotReachServerCheck => '❌ Não é possível contactar o servidor. Verifique as definições.';

  @override
  String cannotSaveFolderMissing(Object path) {
    return '❌ Não é possível guardar: a pasta \"$path\" não existe no servidor.';
  }

  @override
  String deleteProfileBody(Object name) {
    return 'Tem a certeza de que quer eliminar o perfil \"$name\"?';
  }

  @override
  String serverDeleted(Object serverName) {
    return '🗑️ Servidor \"$serverName\" eliminado.';
  }

  @override
  String get addLocalServer => 'Adicionar um servidor local';

  @override
  String get editServer => 'Editar o servidor';

  @override
  String get deleteThisServer => 'Eliminar este servidor';

  @override
  String get serverName => 'Nome do servidor';

  @override
  String get serverNameHint => 'Ex.: NAS da sala, PC do escritório...';

  @override
  String get enterName => 'Introduza um nome';

  @override
  String get ftpPort21 => 'FTP (porta 21)';

  @override
  String get hostIp => 'Anfitrião / IP';

  @override
  String get hostHint => 'ex.: 192.168.1.100 ou nas.local';

  @override
  String get hostRequired => 'IP ou domínio obrigatório';

  @override
  String get rootPath => 'Caminho raiz';

  @override
  String get secureConnectionHttps => 'Ligação segura (HTTPS)';

  @override
  String get authenticationOptional => 'Autenticação (opcional)';

  @override
  String get usernameLabel => 'Utilizador';

  @override
  String get password => 'Palavra-passe';

  @override
  String get allFilesAccessRequired => 'É necessário acesso a todos os ficheiros para analisar o telemóvel.';

  @override
  String get noCompatibleBookFound => 'Nenhum livro compatível encontrado no telemóvel.';

  @override
  String alreadyPresentOrSkipped(Object skipped) {
    return ' · $skipped já presente(s) ou ignorado(s)';
  }

  @override
  String booksAddedCount(Object imported, Object skipped) {
    return '$imported livro(s) adicionado(s)$skipped';
  }

  @override
  String importFailed(Object error) {
    return 'Importação impossível: $error';
  }

  @override
  String get permissionNotGranted => 'Permissão não concedida: nenhum ficheiro foi analisado.';

  @override
  String get scanPhoneTitle => 'Analisar os livros do telemóvel?';

  @override
  String get scanPhoneBody => 'O ComicStream pedirá acesso aos ficheiros apenas para encontrar BD, PDF e EPUB. Depois escolherá os ficheiros a importar; nada é copiado sem confirmação.';

  @override
  String get notNow => 'Agora não';

  @override
  String get deviceFiles => 'Ficheiros do dispositivo';

  @override
  String get addComicsFromDevice => 'Adicionar BD a partir deste dispositivo';

  @override
  String get addComicsFromDeviceBody => 'Analise todos os ficheiros compatíveis do telemóvel e escolha os livros a manter.';

  @override
  String get scanningFiles => 'A analisar ficheiros…';

  @override
  String get scanPhone => 'Analisar o telemóvel';

  @override
  String addedFilesCount(Object length) {
    return 'Ficheiros adicionados ($length)';
  }

  @override
  String get noFileAdded => 'Nenhum ficheiro adicionado';

  @override
  String get scanPhoneToFindBooks => 'Analise o telemóvel para encontrar os seus livros.';

  @override
  String formatPageProgress(Object formatString, Object currentPage1, Object totalPages) {
    return '$formatString · Página $currentPage1/$totalPages';
  }

  @override
  String pageXOfY(Object currentPage1, Object totalPages) {
    return 'Página $currentPage1 de $totalPages';
  }

  @override
  String get removeFromFavorites => 'Remover dos favoritos';

  @override
  String get addToFavorites => 'Adicionar aos favoritos';

  @override
  String get pageGrid => 'Grelha de páginas';

  @override
  String get comicLtrShort => 'BD (E->D)';

  @override
  String get mangaRtlShort => 'Mangá (D->E)';

  @override
  String get readingDirection => 'Sentido de leitura';

  @override
  String get comicLtr => 'BD (E para D)';

  @override
  String get mangaRtl => 'Mangá (D para E)';

  @override
  String get imageFit => 'Ajuste da imagem';

  @override
  String get screen => 'Ecrã';

  @override
  String get background => 'Fundo';

  @override
  String get keepScreenAwake => 'Manter o ecrã ligado';

  @override
  String selectedCount(Object length) {
    return '$length selecionado(s)';
  }

  @override
  String get removeAll => 'Remover tudo';

  @override
  String get addAll => 'Adicionar tudo';

  @override
  String get alreadyImported => 'Já importado';

  @override
  String booksFoundCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count livros',
      one: '1 livro',
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
  String get convertToCbz => 'Converter em BD (CBZ)';

  @override
  String get markAsUnread => 'Marcar como não lido';

  @override
  String get markAsRead => 'Marcar como lido';

  @override
  String get deleteFromDevice => 'Eliminar do dispositivo';

  @override
  String get finishedUpper => 'TERMINADO';

  @override
  String get cbzBenefits => 'Vantagens do formato CBZ:';

  @override
  String get cbzBenefit1 => '• Renderização muito mais rápida e fluida';

  @override
  String get cbzBenefit2 => '• Modo mangá (direita para a esquerda) disponível';

  @override
  String get cbzBenefit3 => '• Modo webtoon (deslocamento contínuo) fluido';

  @override
  String get cbzBenefit4 => '• Menor consumo de memória e bateria';

  @override
  String get converting => 'A converter...';

  @override
  String get conversionSucceeded => 'Conversão concluída!';

  @override
  String get conversionSucceededBody => 'A sua BD está disponível em formato CBZ de alta definição.';

  @override
  String get readAsCbz => 'Ler em modo BD (CBZ)';

  @override
  String get pleaseWait => 'Aguarde...';

  @override
  String get downloads => 'Transferências';

  @override
  String get noDownloadInProgress => 'Nenhuma transferência em curso';

  @override
  String get noDownloadInProgressBody => 'Os ficheiros que transferir do seu servidor local aparecerão aqui com o respetivo progresso.';

  @override
  String inProgressCount(Object length) {
    return 'Em curso ($length)';
  }

  @override
  String historyCount(Object length) {
    return 'Histórico ($length)';
  }

  @override
  String doneWithSize(Object formatBytes) {
    return 'Concluído • $formatBytes';
  }

  @override
  String get deleteFromStorage => 'Eliminar do armazenamento';

  @override
  String failedWithReason(Object reason) {
    return 'Falhou: $reason';
  }

  @override
  String weeksAgo(Object weeks) {
    return 'Há $weeks sem.';
  }

  @override
  String daysAgo(Object inDays) {
    return 'Há $inDays dias';
  }

  @override
  String hoursAgo(Object inHours) {
    return 'Há $inHours h';
  }

  @override
  String minutesAgo(Object inMinutes) {
    return 'Há $inMinutes min';
  }

  @override
  String get justNow => 'Agora mesmo';

  @override
  String pdfNotFound(Object pdfFilePath) {
    return 'Ficheiro PDF não encontrado: $pdfFilePath';
  }

  @override
  String get pdfHasNoPage => 'O ficheiro PDF não contém nenhuma página.';

  @override
  String conversionInit(Object totalPages) {
    return 'A iniciar a conversão ($totalPages páginas)...';
  }

  @override
  String renderingPagesRange(Object i1, Object currentBatchEnd, Object totalPages) {
    return 'Renderização HD das páginas $i1 a $currentBatchEnd / $totalPages...';
  }

  @override
  String renderingPage(Object i1, Object totalPages) {
    return 'Renderização HD da página $i1 / $totalPages...';
  }

  @override
  String get assemblingCbz => 'A montar o arquivo CBZ...';

  @override
  String get noPageGenerated => 'Não foi possível gerar nenhuma página a partir do PDF.';

  @override
  String get cbzEncodingFailed => 'Falha na codificação do arquivo CBZ.';

  @override
  String get finalizingCover => 'A finalizar e extrair a capa...';

  @override
  String get conversionDone => 'Conversão concluída com sucesso!';

  @override
  String get cbzNotFound => 'Ficheiro CBZ não encontrado no dispositivo.';

  @override
  String get noValidImageInCbz => 'Nenhuma imagem válida encontrada neste arquivo CBZ.';

  @override
  String cbzReadError(Object sizeMb, Object e) {
    return 'Erro de leitura ($sizeMb MB): $e\n\nO ficheiro pode estar danificado ou a transferência incompleta.';
  }

  @override
  String pagesCount(Object length) {
    return 'Páginas ($length)';
  }

  @override
  String get loadingVolume => 'A carregar o volume...';

  @override
  String get volumeFinished => 'Volume terminado! 🎉';

  @override
  String nextVolumeWithTitle(Object title) {
    return 'Passar ao volume seguinte ➔\n$title';
  }

  @override
  String bookSyncUnavailable(Object error) {
    return 'Sincronização indisponível para este livro. Leitura local mantida: $error';
  }

  @override
  String get progressFoundElsewhere => 'Progresso encontrado noutro dispositivo';

  @override
  String otherPositionOnDevice(Object remoteDeviceName) {
    return '«$remoteDeviceName» tem outra posição para este livro.';
  }

  @override
  String get thisDevice => 'Este dispositivo';

  @override
  String get keepHere => 'Manter aqui';

  @override
  String continueFromDevice(Object remoteDeviceName) {
    return 'Continuar a partir de $remoteDeviceName';
  }

  @override
  String get downloadFailed => 'Falha na transferência';

  @override
  String get convertingHdCbz => 'Conversão HD em CBZ (modo BD)...';

  @override
  String get downloadingYourComic => 'A transferir a sua BD...';

  @override
  String get networkErrorOccurred => 'Ocorreu um erro de rede.';

  @override
  String get convertingHdInProgress => 'Conversão HD em curso...';

  @override
  String get deleteFromDeviceTitle => 'Eliminar do dispositivo?';

  @override
  String deleteDownloadedFileBody(Object name) {
    return 'Quer eliminar o ficheiro transferido localmente de \"$name\" para libertar espaço?\n\nO ficheiro continua disponível e transferível a partir do seu servidor.';
  }

  @override
  String deletedFromDevice(Object name) {
    return '\"$name\" foi eliminado do seu dispositivo.';
  }

  @override
  String get deleteLocalCopy => 'Eliminar cópia local';

  @override
  String get downloadForOffline => 'Transferir para ler offline';

  @override
  String get updateAvailable => 'Atualização disponível!';

  @override
  String get whatsNew => 'Novidades:';

  @override
  String get defaultReleaseNotes => 'Melhorias de desempenho e correções de erros.';

  @override
  String get downloadApk => 'Transferir APK';

  @override
  String get almostDone => 'Quase concluído...';

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
    return '$completedBooks/$totalBooks lido(s)';
  }

  @override
  String get emptyServerResponse => 'Resposta vazia do servidor';

  @override
  String chapterN(Object length1) {
    return 'Capítulo $length1';
  }

  @override
  String chapterNIdx(Object idx1) {
    return 'Capítulo $idx1';
  }

  @override
  String get pdfNotFoundOnDevice => 'Ficheiro PDF não encontrado no dispositivo.';

  @override
  String get convertToCbzComicMode => 'Converter em CBZ (modo BD)';

  @override
  String get pressAgainToExit => 'Prima novamente para sair do ComicStream';

  @override
  String get downloadsTabShort => 'Transf.';

  @override
  String get settingsTab => 'Opções';

  @override
  String get invalidJsonFormat => 'Formato JSON inválido';

  @override
  String cannotLoadFolder(Object e) {
    return 'Não é possível carregar a pasta: $e';
  }

  @override
  String get newUpdateAvailable => 'Está disponível uma nova atualização.';

  @override
  String get unknownEncryptionVersion => 'Versão de encriptação desconhecida';

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
    return 'Capítulo $current/$total · $percent%';
  }

  @override
  String labelLocationDate(Object label, Object location, Object date, Object time) {
    return '$label: $location\n$date às $time';
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
  String get back => 'Voltar';

  @override
  String get none => 'Nenhum';

  @override
  String get all => 'Tudo';

  @override
  String get importAction => 'Importar';

  @override
  String get everyone => 'Todos';

  @override
  String get clean => 'Limpar';

  @override
  String get read => 'Ler';

  @override
  String get dark => 'Escuro';

  @override
  String get mint => 'Menta';

  @override
  String get light => 'Claro';

  @override
  String get standard => 'Padrão';

  @override
  String get large => 'Largo';

  @override
  String get libraryTab => 'Biblio';

  @override
  String get serverTab => 'Servidor';

  @override
  String get filesTab => 'Arquivos';

  @override
  String get delete => 'Eliminar';

  @override
  String get resume => 'Retomar';

  @override
  String get progress => 'Progresso';

  @override
  String get favorites => 'Favoritos';

  @override
  String get close => 'Fechar';

  @override
  String get options => 'Opções';

  @override
  String get search => 'Pesquisar';

  @override
  String get refresh => 'Atualizar';

  @override
  String get root => 'Raiz';

  @override
  String get empty => 'Esvaziar';

  @override
  String get font => 'Tipo de letra';

  @override
  String get lineSpacing => 'Entrelinha';

  @override
  String get compact => 'Compacto';

  @override
  String get normal => 'Normal';

  @override
  String get relaxed => 'Amplo';

  @override
  String get margin => 'Margem';

  @override
  String get narrowShort => 'Estreito';

  @override
  String get yesterday => 'Ontem';

  @override
  String get today => 'Hoje';

  @override
  String get folder => 'Pasta';

  @override
  String get convert => 'Converter';

  @override
  String get width => 'Largura';

  @override
  String get height => 'Altura';

  @override
  String get black => 'Preto';

  @override
  String get grey => 'Cinzento';

  @override
  String get white => 'Branco';

  @override
  String get downloaded => 'Transferido';

  @override
  String get serverDefaultName => 'Servidor';

  @override
  String get test => 'Testar';

  @override
  String get type => 'Tipo';

  @override
  String get port => 'Porta';

  @override
  String get path => 'Caminho';

  @override
  String get credentials => 'Credenciais';

  @override
  String get ignore => 'Ignorar';

  @override
  String get noneLower => 'nenhum';

  @override
  String get serverUpper => 'SERVIDOR';

  @override
  String get bookUpper => 'LIVRO';

  @override
  String get resumeUpper => 'RETOMAR';

  @override
  String get currentUpper => 'ATUAL';

  @override
  String get lineSpacingUpper => 'ENTRELINHA';

  @override
  String get alignmentUpper => 'ALINHAMENTO';

  @override
  String get comicsFilter => 'BD';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navServers => 'Servidores';

  @override
  String get computerFiles => 'Ficheiros do computador';

  @override
  String get addComicsFromComputerBody => 'Escolha BD (CBZ, CBR, PDF, EPUB) ou uma pasta inteira para analisar. Um duplo clique no Explorador também os abre diretamente.';

  @override
  String get openFiles => 'Abrir ficheiros…';

  @override
  String get scanFolder => 'Analisar uma pasta…';

  @override
  String get columnTitle => 'Título';

  @override
  String get columnFormat => 'Formato';

  @override
  String get columnSize => 'Tamanho';

  @override
  String get columnAdded => 'Adicionado';

  @override
  String get doublePageTitle => 'Página dupla em ecrãs grandes';

  @override
  String get doublePageBody => 'Duas páginas lado a lado quando a janela é larga e na horizontal';

  @override
  String get onePage => '1 página';

  @override
  String get twoPages => '2 páginas';

  @override
  String get togglePagesPerView => 'Mostrar 1 ou 2 páginas (D)';

  @override
  String get selectAll => 'Selecionar tudo';

  @override
  String get clearSelection => 'Cancelar seleção';

  @override
  String get moveToSeries => 'Mover para uma série';

  @override
  String get seriesNameLabel => 'Nome da série';

  @override
  String get automaticSeries => 'Série automática';

  @override
  String get move => 'Mover';

  @override
  String deleteSelectedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Excluir $count livros?',
      one: 'Excluir 1 livro?',
    );
    return '$_temp0';
  }

  @override
  String get deleteSelectedBody => 'Os arquivos serão removidos deste dispositivo. Os dos seus servidores não são afetados.';

  @override
  String librarySelectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selecionados',
      one: '1 selecionado',
    );
    return '$_temp0';
  }

  @override
  String get languageTitle => 'Idioma';

  @override
  String get systemLanguage => 'Idioma do sistema';

  @override
  String get googleBrowserDone => 'Sessão iniciada. Pode fechar este separador e voltar ao ComicStream.';

  @override
  String get googleBrowserFailed => 'O início de sessão com o Google falhou. Feche este separador e tente novamente no ComicStream.';
}
