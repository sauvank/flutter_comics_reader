# 📖 Contexte & Spécifications Techniques — ComicStream

## Présentation Google Play

Le kit `marketing/play-store/` utilise la vraie interface de ComicStream avec des livres et profils serveurs fictifs. Les illustrations de démonstration restent hors des assets de production. Voir le [guide du kit](../marketing/play-store/README.md) pour les exports, leur provenance et leur régénération.

Chaque release GitHub inclut les APK installables et l’AAB signé destiné à la
publication manuelle dans la Play Console. L’AAB ne doit pas être installé
directement sur un appareil.

Ce document résume l'environnement matériel, l'infrastructure serveur, les protocoles réseau, et l'état actuel de l'application **ComicStream**.

## Workflow de versionnement

Tout commit doit créer un nouveau tag de version. Un tag existant ne doit jamais
être déplacé ni réutilisé : chaque modification finalisée passe par une nouvelle
release, avec une incrémentation `patch` par défaut via
`./scripts/bump_and_push.sh patch` (ou `minor`/`major` sur demande explicite).

## Synchronisation de compte (préparation)

Firebase Authentication et Cloud Firestore constituent le backend prévu pour
la synchronisation multi-appareils. Avant envoi, les profils de serveurs, la
progression et les réglages sont chiffrés côté client ; les mots de passe de
serveurs sont également gardés dans le coffre sécurisé de l'OS. La phrase de
récupération n'est jamais stockée par l'application : l'utilisateur dispose d'un
contrôle visuel (masquage/affichage), d'un champ de confirmation, d'une boîte de
dialogue de vérification avant enregistrement, et de la possibilité de modifier
sa phrase secrète à tout moment sur un coffre déverrouillé. Les fichiers, couvertures
et chemins locaux ne sont pas synchronisés. La configuration de projet reste
décrite dans `docs/FIREBASE_SETUP.md` et ne doit inclure aucun secret dans ce
dépôt.

Sans projet Firebase relié à l’application, l’écran Compte reste accessible et
explique que la synchronisation sera disponible après la configuration. Il ne
tente alors pas d’accéder aux services Firebase : le lecteur et les données
locales restent utilisables.

La progression de lecture est conservée séparément pour chaque couple
livre/appareil. À l’ouverture d’un livre, ainsi qu’au retour au premier plan
d’un lecteur déjà ouvert, ComicStream compare sa position locale avec la
dernière position différente d’un autre appareil. Le dialogue affiche le nom
de l’appareil, les pages ou chapitres et les dates, puis propose de continuer
depuis cet appareil, de conserver la position locale ou d’ignorer la révision.
Aucun écrasement n’est effectué sans ce choix. Une révision ignorée n’est plus
proposée tant que l’appareil distant n’a pas avancé. Ce choix ne remplace ni les
favoris ni les marque-pages.
Les conflits concernant les serveurs ou les réglages restent résolus depuis
l’écran Compte.
Un conflit de serveurs ou de réglages détecté pendant une synchronisation
automatique est signalé dans l’écran Compte avec un bouton permettant de le
résoudre ; les divergences de lecture sont traitées dans le livre concerné.
Après un choix de résolution, ce même conflit est retiré des flux automatique
et manuel afin de ne jamais demander deux fois la même décision.
Chaque appareil conserve aussi une sauvegarde globale chiffrée distincte, repérée par
un nom modifiable depuis Compte (ou un alias aléatoire par défaut). Ce nom est
placé dans l’enveloppe chiffrée et ne contient ni modèle ni identifiant matériel.
Le nouveau nom est toujours enregistré localement ; si le serveur est
momentanément indisponible, l’interface l’indique et la prochaine
synchronisation envoie la sauvegarde renommée.
Le bouton de
synchronisation manuelle demande quelle sauvegarde utiliser ; choisir un autre
appareil restaure ses données localement et en fait la nouvelle référence
partagée. La synchronisation automatique ne restaure jamais une sauvegarde
globale ; ce mécanisme reste réservé à la récupération explicite.
Une petite icône de nuage dans la barre de la bibliothèque indique uniquement
qu’une synchronisation est en cours.
Après une synchronisation, les profils de serveurs importés rechargent aussi la
liste en mémoire : ils sont visibles immédiatement dans l’onglet Serveur, sans
redémarrage de l’application.
Pendant une synchronisation manuelle, le bouton indique l’opération en cours et
une barre de progression est affichée afin d’éviter les doubles appuis.
Lorsqu’une BD déjà connue est téléchargée sur un nouvel appareil, son état
initial non lu n’écrase pas la progression chiffrée : le choix est proposé à
la première ouverture du livre.
Après le choix d’une progression distante, le pourcentage affiché est recalculé
à partir de la page et du nombre total de pages, puis la bibliothèque locale est
rechargée.
Au chargement de la bibliothèque, ce pourcentage est également toujours dérivé
de la page enregistrée afin de corriger les données issues d’anciennes versions.
Pour un EPUB, la position relative dans le chapitre est synchronisée en plus de
l’index du chapitre. Elle est rétablie proportionnellement sur l’autre écran,
sans qu’un ancien défilement local puisse écraser un chapitre plus récent reçu
du cloud. Les cartes et les propositions de reprise affichent donc un chapitre,
numéroté à partir de 1, plutôt qu’une page.
Les réglages de lecture portent leur véritable date de dernière modification :
une synchronisation sans changement ne les présente plus comme une nouvelle
version concurrente sur chaque appareil.
Les enregistrements locaux de progression (page, marque-page et favori) sont
sérialisés : un changement rapide de page dans un lecteur PDF, CBZ ou EPUB ne
peut plus finir par réécrire une position plus récente. Le processus partage
aussi un verrou entre synchronisation automatique et manuelle afin que deux
exécutions simultanées ne créent pas de conflits artificiels. Une réception
distante recharge immédiatement la bibliothèque déjà ouverte, sans générer un
nouvel envoi vers le cloud.
Les réglages distants rechargent aussi le thème visible immédiatement, sans
attendre le redémarrage de l’application.
Chaque fichier importé ou téléchargé reçoit une empreinte SHA-256 calculée en
flux. Cette empreinte devient l’identifiant prioritaire de sa progression : un
renommage ou un déplacement — y compris entre deux profils de serveur ayant
des identifiants locaux différents — n’interrompt plus le suivi, tandis que
deux éditions différentes portant un titre similaire ne sont jamais confondues.
Elle permet aussi de reprendre un EPUB, PDF ou CBZ importé localement après
l’import du même fichier sur un autre appareil, sans envoyer son chemin local.
L’ajout d’un tome, d’un favori ou d’un marque-page déclenche également une
synchronisation automatique ; leur date de modification est transmise avec la
progression. Les modifications rapprochées sont regroupées pendant cinq
secondes avant l’envoi.

L’onglet **Fichiers**, placé au même niveau que l’onglet Serveur, analyse tout
le stockage partagé du téléphone, sous-dossiers inclus. Il demande au préalable
l’autorisation Android appropriée (accès spécial sur Android 11+, permission de
lecture sur Android 8–10), uniquement après une action explicite « Scanner le
téléphone ». Il ne présente que les formats lisibles (CBZ/CBR/ZIP, PDF et EPUB),
puis permet de décocher les livres à ne pas conserver avant l’import. Les
fichiers retenus sont copiés dans le stockage de ComicStream, indexés avec leur
couverture quand elle est disponible et peuvent être lus hors ligne sans
provenance serveur.

Après le téléchargement ou l’import d’un livre déjà lu ailleurs, la décision de
reprise est présentée à l’ouverture du lecteur avec l’appareil source et les
deux positions ; elle ne modifie aucun autre livre.

Les filtres de la bibliothèque restent sur une rangée horizontalement défilable,
avec un pictogramme et un état sélectionné discret, afin de conserver les livres
et l’action de reprise visibles dès l’ouverture.
Les libellés courts de la navigation basse sont également maintenus sur une
ligne.
Pour préserver les boutons et sélecteurs horizontaux sur les téléphones étroits,
l’interface plafonne le facteur de texte Android à 115 %.

> [!CAUTION]
> **RÈGLE ABSOLUE DE SÉCURITÉ & ANONYMAT : ZÉRO DONNÉE PRIVÉE DANS LE DÉPÔT**
> Le dépôt étant public, il est **strictement interdit** de commiter la moindre information personnelle ou sensible :
> - ❌ Aucun mot de passe, token API, clé privée, fichier keystore (`.jks`, `.keystore`, `.pepk`) ou compte de service (`service_account.json`).
> - ❌ Aucun identifiant matériel unique (numéro de série ADB, adresses MAC).
> - ❌ Aucune adresse IP privée réelle, nom d'hôte ou arborescence locale personnelle (utiliser uniquement des placeholders génériques : `192.168.1.100`, `user`, `0123456789ABCDEF`, `/media/comics/...`).
> - ❌ Les notes privées doivent rester locales et être systématiquement ignorées par `.gitignore`.

---

## 🛠️ 1. Environnement Matériel & Système

* **Appareil Cible Principal** :
  * **Modèle** : Huawei MediaPad M5 Lite (`BAH2-W19`)
  * **Écran** : 10.1 pouces IPS LCD, Définition 1920 × 1200 pixels (~224 ppi)
  * **Système d'Exploitation** : Android 8.0.0 (Oreo, API level 26)
  * **Connexion ADB** : Câble USB / Réseau (`0123456789ABCDEF`)
* **Environnement de Développement** :
  * **SDK Flutter** : Flutter 3.27.4 (Dart 3.6.2)
  * **Architecture Applicative** : Provider (State Management) + SQLite/SharedPreferences (Persistance locale) + pdfrx (Moteur PDF C++) + archive (CBZ/ZIP).

---

## 🌐 2. Infrastructure Serveur & Réseau

* **Serveur de Fichiers Local (NAS)** :
  * **Hôte** : Serveur NAS (`192.168.1.100`)
  * **Protocole** : Serveur FTP Standard (Port 21, Utilisateur : `user`)
  * **Répertoire Racine des Bandes Dessinées** :
    ```
    /media/comics/BOOKS
    ```
  * **Arborescence type** :
    * `/media/comics/BOOKS/BD/` *(ex: Conquêtes, XIII, Centaures, Sillage...)*
    * `/media/comics/BOOKS/Manga/` *(ex: Planetes...)*
    * `/media/comics/BOOKS/comics/` *(ex: Red Son, V pour Vendetta, Invincible...)*
    * `/media/comics/BOOKS/Livres/`
    * `/media/comics/BOOKS/AUDIO/`

---

## 📑 3. Formats de Fichiers Pris en Charge

| Format | Extension | Traitement par l'application |
| :--- | :--- | :--- |
| **CBZ / ZIP** | `.cbz`, `.zip` | Lecture native ultra-rapide via `CbzReaderScreen` (décompression mémoire des pages). |
| **CBR / RAR** | `.cbr`, `.rar` | Décompression des archives d'images vers le lecteur de BD. |
| **PDF** | `.pdf` | **Double mode** : <br>1. **Conversion Auto en CBZ Native Sans Perte** : Extraction native directe bit à bit via `pdfimages -all` (100% qualité d'origine, zéro recompression) avec repli sur rendu matriciel Ultra HD 300 DPI pour les PDF vectoriels/textes.<br>2. **Lecture Directe Instantanée** : Rendu vectoriel C++ à la volée via `PdfReaderScreen` (0.0s d'attente). |
| **EPUB** | `.epub` | Format ebook supporté. |

---

## ⚡ 4. Fonctionnalités Implémentées & État Actuel

### 📥 Gestionnaire de Téléchargement & File d'attente
* **Téléchargements Simultanés (Multi-queue)** : Jusqu'à 2 transferts en parallèle sans bloquer la bande passante ni la mémoire de la tablette.
* **Minuteur Dynamique (ETA)** : Calcul du temps restant en direct (*ex: `~ 15s restantes`*).
* **Bouton « Tout télécharger » Intelligent** : Détecte les tomes déjà présents et ne télécharge que les nouveautés, avec affichage `Tous téléchargés ✅` si tout est complet.
* **Fonctionnement en Arrière-Plan** : Bouton « Arrière-plan » permettant de naviguer dans l'application pendant que les transferts et conversions se poursuivent en tâche de fond.
* **Gestion du Local** : Bouton 3-petits-points pour « Supprimer du local » sans toucher au serveur distant.

### 🎨 Rendu & Super-Échantillonnage Automatique
* **Adaptation Automatique à l'Écran (+35% de netteté)** : Détecte la résolution physique de la tablette et génère les pages de conversion à ~2600 pixels de hauteur pour un zoom parfait dans les bulles.
* **Extraction Automatique des Couvertures** : Extraction de la page de couverture pour toutes les BDs locales et distantes avec auto-récupération en arrière-plan.
* **Filtres d'Affichage** : Anti-aliasing et `FilterQuality.high` sur toutes les images pour éliminer tout flou.

---

## 🗂️ 5. Structure des Données Locales

* **Base de données / Métadonnées** : `SharedPreferences` stockant les profils serveurs et les listes d'objets `BookItem`.
* **Répertoires de Stockage (Documents App)** :
  * `.../app_flutter/books/` : Fichiers `.cbz`, `.pdf` téléchargés en local.
  * `.../app_flutter/covers/` : Miniatures JPEG extraites des couvertures.
  * `.../app_flutter/remote_covers_cache/` : Cache des couvertures explorées sur le serveur.
  * `.../temp/` : Répertoire temporaire de rendu éphémère nettoyé après chaque conversion.
