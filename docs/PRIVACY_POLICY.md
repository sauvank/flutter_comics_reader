# Politique de confidentialité — ComicStream

**Date d'effet : 18 septembre 2026**

ComicStream est un lecteur de bandes dessinées. Cette politique décrit les
données traitées par l'application et les choix qui restent sous votre
contrôle.

## Données locales

Les fichiers lus, couvertures, progression, marque-pages, favoris et réglages
de lecture sont conservés sur l'appareil. Les identifiants de serveurs sont
enregistrés dans le coffre sécurisé fourni par le système d'exploitation ; ils
ne sont ni inclus dans un export de serveurs, ni enregistrés dans les
préférences ordinaires de l'application.

La suppression de l'application ou de ses données locales peut supprimer ces
données locales. Pensez à utiliser la synchronisation ou une sauvegarde que
vous contrôlez si vous souhaitez les conserver.

## Compte et synchronisation facultatifs

La lecture locale ne requiert aucun compte. Si vous choisissez de créer un
compte par e-mail/mot de passe ou de vous connecter avec Google, Firebase
Authentication traite l'adresse e-mail, l'identifiant du fournisseur de
connexion et les informations nécessaires à l'authentification.

Lorsque la synchronisation est activée, les réglages, profils de serveurs et
progression de lecture sont chiffrés sur l'appareil avec AES-256-GCM avant leur
envoi vers Cloud Firestore. La clé de déchiffrement reste sur vos appareils ;
la phrase de récupération sert à restaurer cette clé et n'est jamais envoyée
au serveur. Les fichiers de BD, leurs couvertures et leurs chemins locaux ne
sont jamais synchronisés.

## Réseau et sécurité

L'accès réseau sert uniquement aux serveurs explicitement configurés par
l'utilisateur, aux mises à jour de l'application et, en cas d'utilisation
d'un compte, à Firebase. HTTPS/WebDAV valide les certificats TLS du serveur.
Les connexions HTTP, FTP ou WebDAV non chiffrées dépendent du serveur choisi
par l'utilisateur et exposent potentiellement les données en transit ; utilisez
HTTPS ou SFTP lorsque votre serveur le permet.

ComicStream n'intègre ni publicité ni outil de télémétrie ou d'analyse
comportementale.

## Suppression et contact

Vous pouvez vous déconnecter à tout moment depuis l'écran Compte. Pour une
demande de suppression de compte et des données de synchronisation associées,
ouvrez une demande via le dépôt du projet :
[github.com/sauvank/flutter_comics_reader](https://github.com/sauvank/flutter_comics_reader).

## Enfants

ComicStream est un utilitaire de lecture. Il ne cible pas les enfants et ne
collecte pas sciemment de données personnelles auprès d'enfants.
