# 🗺️ Feuille de Route (Roadmap) — ComicStream

Bienvenue sur la feuille de route du lecteur de BD / Manga **ComicStream**.  
Ce document détaille les phases de développement pour enrichir l'expérience sur tablette et serveur local.

---

```mermaid
gantt
    title Planning d'Évolution ComicStream
    dateFormat  YYYY-MM-DD
    section Phase 1 : Confort Tablette
    Mode Double-Page Intelligent        :active, p1_1, 2026-08-25, 2d
    Enchaînement Auto des Tomes         :p1_2, after p1_1, 2d
    Contrôle Luminosité Intégré         :p1_3, after p1_2, 1d
    section Phase 2 : Bibliothèque & UX
    Bandeau « Continuer la lecture »    :p2_1, after p1_3, 2d
    Regroupement par Séries             :p2_2, after p2_1, 3d
    Marque-pages & Favoris              :p2_3, after p2_2, 2d
    section Phase 3 : Sync & Stockage
    Auto-Sync Serveur en Arrière-plan   :p3_1, after p2_3, 3d
    Nettoyage Intelligent du Stockage   :p3_2, after p3_1, 2d
    section Phase 4 : Finitions Pro
    Support Métadonnées ComicInfo.xml   :p4_1, after p3_2, 3d
    Thèmes & Sauvegarde de Progression  :p4_2, after p4_1, 2d
```

---

## 📖 Phase 1 : Confort de Lecture & Expérience Tablette *(Priorité Immédiate)*

> **Objectif** : Exploiter à 100% l'écran 10.1 pouces (1920×1200) de la tablette pour une sensation papier authentique.

### 1.1 Mode Double-Page Intelligent (Paysage)
* **Affichage 2 pages côte à côte** en orientation paysage.
* **Gestion intelligente de la couverture** :
  * Page 1 (Couverture) affichée seule et centrée.
  * Pages suivantes (2-3, 4-5, etc.) affichées par paires.
  * Prise en charge des doubles-pages panoramiques intégrées.
* **Bascule instantanée** (1 page / 2 pages) dans la barre d'outils du lecteur.

### 1.2 Enchaînement Automatique des Tomes *(Binge-Reading)*
* **Transition fluide en fin de tome** : À la dernière page d'un album (ex: *Conquêtes T01*), proposition directe d'ouvrir le *Tome 02*.
* **Téléchargement à la volée** : Si le tome suivant est sur le serveur, téléchargement et ouverture en 1 tap.
* **Marquage automatique** du tome terminé avec badge `Lu ✅`.

### 1.3 Contrôle de Luminosité & Filtre Nuit Intégré
* Curseur de luminosité directement dans le lecteur pour la lecture nocturne.
* Mode Nuit avec fond noir pur AMOLED pour reposer les yeux.

---

## 📚 Phase 2 : Accueil & Organisation de la Bibliothèque

> **Objectif** : Retrouver ses BDs favorites en 1 seconde et reprendre sa lecture sans friction.

### 2.1 En-tête « Continuer la lecture » *(Hero Banner)*
* Affichage en tête de liste de la dernière BD en cours de lecture :
  * Grande couverture + Titre du tome.
  * Progression en pourcentage et numéro de page.
  * Gros bouton **« Reprendre »** pour replonger dans l'histoire en 1 tap.

### 2.2 Regroupement Automatique par Séries / Collections
* Vue dédiée **« Séries »** :
  * Détection automatique des sagas (*ex: « XIII (24 tomes) », « Conquêtes (10 tomes) », « Sillage (33 tomes) »*).
  * Dossier virtuel avec couverture du Tome 1 et décompte des tomes possédés vs restants sur le serveur.
  * Tri naturel des numéros de tomes (T01, T02, T03... T10).

### 2.3 Marque-pages Visuels & Favoris
* Liste rapide des pages marquées avec miniatures.
* Onglet **Favoris ❤️** pour épingler ses séries en cours.

---

## ⚡ Phase 3 : Synchronisation Serveur & Gestion du Stockage

> **Objectif** : Gérer automatiquement les transferts entre le Raspberry Pi et la mémoire de la tablette.

### 3.1 Détection & Notification des Nouveaux Tomes
* Scan silencieux du serveur FTP/WebDAV au lancement.
* Badge de notification si de nouveaux tomes ou séries ont été ajoutés sur le serveur.

### 3.2 Gestionnaire d'Espace & Nettoyage Intelligent
* Visualiseur de mémoire occupée (Mo / Go) par série.
* Option **« Supprimer les tomes lus »** en 1 clic pour libérer du stockage tout en gardant l'historique.
* Alerte automatique en cas d'espace disque faible.

---

## 💎 Phase 4 : Métadonnées & Personnalisation Pro

### 4.1 Métadonnées et Résumés (ComicInfo.xml / CBZ Info)
* Extraction automatique des synopsis, scénaristes, dessinateurs, éditeurs et années de parution.
* Fiche détaillée d'un album avec résumé avant d'ouvrir la BD.

### 4.2 Sauvegarde & Restauration de la Progression
* Export/Import des statistiques et progressions de lecture (JSON / Serveur).
* Thèmes visuels avancés (Sombre BD, Manga Minimaliste, Vintage Comics).
