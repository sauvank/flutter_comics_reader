# Firebase — configuration de production

ComicStream utilise Firebase Authentication et Cloud Firestore. Aucun secret,
fichier de configuration de projet ni compte de service ne doit être ajouté au
dépôt.

## Pré-requis

1. Créer un projet Firebase séparé pour ComicStream.
2. Ajouter les applications Android, iOS, macOS, Windows, Linux et Web qui
   seront distribuées. Exécuter `flutterfire configure` localement : les
   fichiers générés contenant l'identifiant public du projet peuvent être
   intégrés après vérification, mais jamais une clé de compte de service.
3. Activer Firebase Authentication : E-mail/mot de passe et Google. Google
   requiert les empreintes de signature Android de la version distribuée.
4. Créer Cloud Firestore en mode production puis déployer
   `firebase/firestore.rules` avec la CLI Firebase.
5. Activer App Check avant publication. Il réduit l'usage abusif par des
   applications non officielles ; il ne remplace pas les règles Firestore.

## Intégration continue Android

`android/app/google-services.json` est ignoré par Git. La CI le restaure depuis
le secret de dépôt GitHub `FIREBASE_ANDROID_CONFIG` juste avant la compilation,
puis le supprime à la fin du job. Pour créer ou renouveler ce secret depuis un
poste configuré, exécuter `gh secret set FIREBASE_ANDROID_CONFIG <
android/app/google-services.json`. Ne jamais afficher le contenu du fichier
dans un journal de CI.

Les APK distribués depuis GitHub sont signés par la clé d'importation.
Pour les installations via le Google Play Store, Google ré-applique la signature
App Signing : son empreinte SHA-1 (disponible dans la console Google Play sous
Gestion des versions > Signature de l'application) doit également être enregistrée
dans le projet Firebase aux côtés de la clé d'importation et de la clé de débogage.
La connexion Google initialise le SDK natif `google_sign_in` (Credential
Manager / Google Play Services) avant d’ouvrir le sélecteur de compte Android ;
elle utilise le flux web uniquement sur le Web.

## Windows (et autres ordinateurs)

Il n'y a pas de `google-services.json` sur ordinateur : `FirebaseBootstrap`
lit la configuration de l'app **Web** Firebase « comic_reader_app (windows) »
passée à la compilation avec `--dart-define-from-file`. Le fichier JSON contient
les clés `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_PROJECT_ID`,
`FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_AUTH_DOMAIN` et
`FIREBASE_STORAGE_BUCKET` (valeurs de `firebase apps:sdkconfig WEB <appId>`).

- CI : secret `FIREBASE_DESKTOP_CONFIG` (contenu du JSON), écrit dans
  `firebase_desktop.json` avant `flutter build windows`, puis supprimé.
  Sans secret, l'app se compile mais le compte reste désactivé sur Windows.
- Compilation locale : `flutter build windows --dart-define-from-file=firebase_desktop.json`
  (fichier ignoré par Git).
- La connexion Google n'existe pas sur ordinateur (`google_sign_in` n'a pas
  d'implémentation Windows/Linux) : le bouton est masqué, la connexion se fait
  par e-mail et mot de passe.
- Linux n'est pas pris en charge par les SDK Firebase : le compte y reste
  désactivé.

## Protection des données

Les données de lecture, réglages et profils de serveurs sont chiffrés avec
AES-256-GCM dans l'application avant l'envoi. Les mots de passe de serveurs
restent aussi dans le coffre sécurisé du système local. Une phrase de
récupération permet de restaurer la clé sur un nouvel appareil ; elle n'est
jamais envoyée ni sauvegardée. La perdre impose de recréer les identifiants de
serveurs sur le nouvel appareil.

Les fichiers de BD, leurs couvertures et leurs chemins locaux ne sont jamais
synchronisés.
