# 📚 ComicStream - Lecteur BD / Manga & Client Serveur Local Flutter

## Visuels Google Play

Le [kit de présentation en français](marketing/play-store/README.md) contient six visuels téléphone, quatre captures tablette, une bannière et une vidéo Full HD de 27,9 secondes, issus de la vraie interface avec des livres fictifs. Les sources et scripts permettent de renouveler les captures et la vidéo.

Application mobile et desktop Flutter permettant de se connecter à un serveur local (WebDAV ou HTTP), d'explorer ses dossiers de bandes dessinées et mangas, de les télécharger en local sur l'appareil et de les lire hors-ligne avec un lecteur complet et optimisé.

La synchronisation de compte Firebase chiffre côté client les profils serveur,
la progression et les réglages. Elle se lance automatiquement après une
modification de lecture, de favori, de marque-page ou de bibliothèque. Les
fichiers et chemins locaux ne sont pas envoyés. La connexion nécessite encore
de rattacher un projet Firebase de production ; voir
[la configuration Firebase](docs/FIREBASE_SETUP.md).
Chaque appareil publie un instantané chiffré distinct pour chaque livre. À
l’ouverture d’un livre — et au retour dans un lecteur resté ouvert — ComicStream
compare uniquement sa position de lecture avec celle des autres appareils. Si
elles diffèrent, l’utilisateur peut continuer depuis l’appareil indiqué,
conserver la position locale ou ignorer cette révision. Une révision ignorée
n’est plus proposée tant que l’autre appareil n’a pas avancé. Les marque-pages
et favoris ne sont pas remplacés par ce choix.
Lors d’une synchronisation manuelle, l’utilisateur peut toujours choisir une
sauvegarde chiffrée globale d’un appareil pour une récupération exceptionnelle.
Chaque appareil peut être renommé depuis Compte afin d’être clairement reconnu.
Les fichiers CBZ/CBR/ZIP, PDF et EPUB déjà présents sur l’appareil peuvent être
détectés dans tout le stockage partagé depuis l’onglet **Fichiers** ; après
l’autorisation Android explicite appropriée à la version du système,
l’utilisateur coche ceux à conserver avant leur import local et leur lecture
hors ligne, sans serveur configuré.
Lorsqu’un même fichier est importé sur plusieurs appareils, sa progression est
elle aussi synchronisée grâce à son empreinte, sans transmettre son fichier ni
son chemin local.
Lorsqu’un livre téléchargé existe déjà sur plusieurs appareils, ComicStream
affiche leurs pages ou chapitres et leurs dates avant toute décision.
Pour les EPUB, la synchronisation conserve aussi la position relative dans le
chapitre, afin de reprendre au bon endroit malgré une taille d’écran ou une
police différente ; les aperçus parlent alors de « chapitre » plutôt que de
« page ».
Les mises à jour de progression sont sérialisées localement et une seule
synchronisation peut être active à la fois, y compris lorsqu’elle est demandée
depuis deux écrans différents.
Les réglages reçus du cloud sont également appliqués à l’interface ouverte,
sans attendre le prochain lancement de l’application.
L’interface limite la taille de texte système à 115 % afin que les boutons et
contrôles restent utilisables sur les téléphones étroits avec une police Android
agrandie.

---

## ✨ Fonctionnalités Principales

### 🌐 1. Connexion au Serveur Local
- **Support WebDAV complet (RFC 4918)** : Compatible avec les NAS (Synology, TrueNAS, QNAP), Nextcloud, Docker WebDAV, etc.
- **Support HTTP Auto-index / JSON** : Compatible avec les serveurs HTTP légers (Python, Apache, Nginx).
- **Multi-serveurs** : Sauvegardez plusieurs configurations de serveurs avec test de connexion instantané.
- **Explorateur distant** : Navigation par dossiers avec fil d'Ariane (*breadcrumbs*), tri et tailles de fichiers.
- **Téléchargement par lot** : Bouton *« Tout télécharger »* pour récupérer toute une série en un clic.

### 📥 2. Gestionnaire de Téléchargements & Bibliothèque Hors-Ligne
- **File de téléchargement en arrière-plan** : Suivi de progression en temps réel, vitesse en Mo/s, annulation et reprise.
- **Extraction automatique des couvertures** : Dès le téléchargement d'un fichier `.cbz`, la première page est extraite et mise en cache pour un affichage instantané dans la bibliothèque.
- **Carrousel *« Reprendre la lecture »*** : Accès direct à vos tomes en cours avec pourcentage de lecture.
- **Filtres et Recherche** : Filtrage par format (CBZ, PDF), par état (En cours, Non lu, Terminé) et recherche instantanée par titre.
- **Gestion du stockage** : Calcul de l'espace disque consommé et nettoyage du cache en un clic.

### 📖 3. Lecteur BD & Manga Ultra-Fluide
- **Formats supportés** : `.cbz`, `.cbr`, `.pdf`, `.zip`, `.epub`.
- **Modes de lecture** :
  - **Franco-Belge / Comics** : Défilement horizontal de Gauche à Droite (LTR).
  - **Manga Japonais** : Défilement horizontal de Droite à Gauche (RTL).
  - **Webtoon / Manhwa** : Défilement vertical continu ultra-fluide.
- **Zoom interactif** : Pinch-to-zoom fluide et double-tap pour zoomer/dézoomer.
- **Navigation rapide** : Curseur de scrub avec prévisualisation du numéro de page et grille de miniatures pour sauter directement à une page.
- **Sauvegarde automatique** : Mémorisation de la dernière page lue à chaque changement de page.
- **Marque-pages** : Posez et retrouvez vos signets en un clic.
- **Personnalisation** : Thèmes Sombre / OLED / Clair, couleurs d'arrière-plan du lecteur (Noir, Gris foncé, Sépia, Blanc), maintien de l'écran allumé.

---

## 🏗️ Architecture du Projet

```
lib/
├── main.dart                          # Point d'entrée, MultiProvider & initialisation
├── models/
│   ├── book_item.dart                 # Modèle de livre local (titre, progression, marque-pages, couverture)
│   ├── server_profile.dart            # Modèle de serveur (URL, type WebDAV/HTTP, authentification)
│   ├── remote_file.dart               # Modèle de fichier/dossier distant
│   └── download_task.dart             # Modèle de tâche de téléchargement avec vitesse et statut
├── services/
│   ├── database_service.dart          # Persistance locale (SharedPreferences & dossiers)
│   ├── cbz_service.dart               # Décompression ZIP/CBZ, extraction de couvertures en Isolate
│   ├── webdav_service.dart            # Client WebDAV PROPFIND, parsing XML & téléchargement Dio
│   ├── http_server_service.dart       # Client HTTP & parsing de listes de fichiers
│   └── reader_settings_service.dart   # Gestion des préférences de lecture (sens, zoom, couleurs)
├── providers/
│   ├── library_provider.dart          # State management de la bibliothèque locale
│   ├── server_provider.dart           # State management de l'explorateur distant
│   ├── download_provider.dart         # Gestionnaire de la file de téléchargement
│   └── theme_provider.dart            # Gestionnaire des thèmes (Sombre, OLED, Clair)
├── screens/
│   ├── home_screen.dart               # Barre de navigation principale (4 onglets)
│   ├── library_screen.dart            # Bibliothèque locale & carrousel de reprise
│   ├── server_screen.dart             # Explorateur de serveur local avec fil d'Ariane
│   ├── downloads_screen.dart          # Suivi des téléchargements actifs et terminés
│   ├── synced_reader_screen.dart       # Entrée commune avec vérification par appareil
│   ├── cbz_reader_screen.dart         # Lecteur CBZ/Manga avec zoom et modes LTR/RTL/Webtoon
│   ├── pdf_reader_screen.dart         # Lecteur PDF avec pagination et zoom
│   └── settings_screen.dart           # Paramètres de l'application et gestion du stockage
├── widgets/
│   ├── book_card.dart                 # Carte visuelle de livre avec badge et progression
│   ├── remote_file_tile.dart          # Ligne de fichier distant avec bouton/indicateur de téléchargement
│   ├── server_form_dialog.dart        # Fenêtre d'ajout/modification avec bouton « Tester »
│   ├── synced_reader_gate.dart         # Choix de progression avant/reprise du lecteur
│   └── reader_controls.dart           # Barres de contrôle supérieure et inférieure du lecteur
└── utils/
    ├── format_utils.dart              # Tri naturel (page2 avant page10) et formatage de tailles/dates
    └── app_theme.dart                 # Thèmes Material 3 modernes et OLED
```

---

## 🚀 Démarrage Rapide

### 1. Lancer un serveur local de test (au choix)

#### Option A : Script Python fourni (Aucune installation requise)
```bash
python3 server_example/comic_server.py --port 8080 --dir /chemin/vers/vos/bd
```

#### Option B : Docker WebDAV
```bash
cd server_example
docker compose up -d
```

### 2. Lancer l'application Flutter
```bash
cd comic_reader_app
flutter pub get
flutter run
```

---

## 📱 Plateformes Prises en Charge
- **Android** (Smartphones & Tablettes)
- **iOS** (iPhone & iPad)
- **Desktop** (Linux, Windows, macOS)
- **Web**
