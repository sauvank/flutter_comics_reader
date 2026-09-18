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

## Protection des données

Les données de lecture, réglages et profils de serveurs sont chiffrés avec
AES-256-GCM dans l'application avant l'envoi. Les mots de passe de serveurs
restent aussi dans le coffre sécurisé du système local. Une phrase de
récupération permet de restaurer la clé sur un nouvel appareil ; elle n'est
jamais envoyée ni sauvegardée. La perdre impose de recréer les identifiants de
serveurs sur le nouvel appareil.

Les fichiers de BD, leurs couvertures et leurs chemins locaux ne sont jamais
synchronisés.
