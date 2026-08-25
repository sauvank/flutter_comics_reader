# 📖 Contexte & Spécifications Techniques — ComicStream

Ce document résume l'environnement matériel, l'infrastructure serveur, les protocoles réseau, et l'état actuel de l'application **ComicStream**.

---

## 🛠️ 1. Environnement Matériel & Système

* **Appareil Cible Principal** :
  * **Modèle** : Huawei MediaPad M5 Lite (`BAH2-W19`)
  * **Écran** : 10.1 pouces IPS LCD, Définition 1920 × 1200 pixels (~224 ppi)
  * **Système d'Exploitation** : Android 8.0.0 (Oreo, API level 26)
  * **Connexion ADB** : Câble USB / Réseau (`2DKNU19B22107305`)
* **Environnement de Développement** :
  * **SDK Flutter** : Flutter 3.27.4 (Dart 3.6.2)
  * **Architecture Applicative** : Provider (State Management) + SQLite/SharedPreferences (Persistance locale) + pdfrx (Moteur PDF C++) + archive (CBZ/ZIP).

---

## 🌐 2. Infrastructure Serveur & Réseau

* **Serveur de Fichiers Local (NAS)** :
  * **Hôte** : Raspberry Pi (`192.168.1.12`)
  * **Protocole** : Serveur FTP Standard (Port 21, Utilisateur : `pi`)
  * **Répertoire Racine des Bandes Dessinées** :
    ```
    /home/shares/public/misc/BOOKS
    ```
  * **Arborescence type** :
    * `/home/shares/public/misc/BOOKS/BD/` *(ex: Conquêtes, XIII, Centaures, Sillage...)*
    * `/home/shares/public/misc/BOOKS/Manga/` *(ex: Planetes...)*
    * `/home/shares/public/misc/BOOKS/comics/` *(ex: Red Son, V pour Vendetta, Invincible...)*
    * `/home/shares/public/misc/BOOKS/Livres/`
    * `/home/shares/public/misc/BOOKS/AUDIO/`

---

## 📑 3. Formats de Fichiers Pris en Charge

| Format | Extension | Traitement par l'application |
| :--- | :--- | :--- |
| **CBZ / ZIP** | `.cbz`, `.zip` | Lecture native ultra-rapide via `CbzReaderScreen` (décompression mémoire des pages). |
| **CBR / RAR** | `.cbr`, `.rar` | Décompression des archives d'images vers le lecteur de BD. |
| **PDF** | `.pdf` | **Double mode** : <br>1. **Conversion Auto en CBZ** : Rend chaque page en PNG HD super-échantillonné pour le lecteur de BD.<br>2. **Lecture Directe Instantanée** : Rendu vectoriel C++ à la volée via `PdfReaderScreen` (0.0s d'attente). |
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
