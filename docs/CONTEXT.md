# 📖 Contexte & Spécifications Techniques — ComicStream

## Présentation Google Play

Le kit `marketing/play-store/` utilise la vraie interface de ComicStream avec des livres et profils serveurs fictifs. Les illustrations de démonstration restent hors des assets de production. Voir le [guide du kit](../marketing/play-store/README.md) pour les exports, leur provenance et leur régénération.

Ce document résume l'environnement matériel, l'infrastructure serveur, les protocoles réseau, et l'état actuel de l'application **ComicStream**.

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

Lorsqu’une même donnée a été modifiée localement et sur Google depuis la
dernière synchronisation, l’écran Compte demande explicitement quelle version
conserver (cet appareil ou les données Google) et affiche les deux dates. Aucun
écrasement n’est effectué sans ce choix. La version sélectionnée devient la
référence partagée afin que les autres appareils puissent l’appliquer.
Après une synchronisation, les profils de serveurs importés rechargent aussi la
liste en mémoire : ils sont visibles immédiatement dans l’onglet Serveur, sans
redémarrage de l’application.

L’interface de bibliothèque adapte ses filtres à la largeur disponible : ils
passent à la ligne plutôt que d’être masqués hors écran. Les libellés de la
navigation basse sont également maintenus sur une ligne.

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
