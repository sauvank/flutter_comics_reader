# ComicStream — Visuels Google Play (français)

Le lot contient six visuels téléphone, quatre captures tablette et une bannière.
Ouvrir `preview.html` pour les comparer, ou `preview.jpg` pour un aperçu unique.
L’archive `ComicStream-Google-Play-FR.zip` regroupe les images à importer et ce guide.

## Fichiers à importer

| Emplacement Play Console | Fichiers | Dimensions |
| --- | --- | --- |
| Captures téléphone | `exports/phone/01-library.jpg` à `06-favorites.jpg`, dans cet ordre | 1080 × 1920 |
| Captures tablette 10 pouces | Les quatre images de `exports/tablet/` | 1200 × 1920 |
| Image de présentation | `exports/feature-graphic.jpg` | 1024 × 500 |

Les exports sont des JPEG RVB sans transparence. Les captures tablette conservent le ratio natif de l’appareil et n’ont aucun texte promotionnel ajouté. La taille de la bannière et les dimensions des captures suivent les [consignes officielles Google Play](https://support.google.com/googleplay/android-developer/answer/9866151?hl=fr). La recommandation 9:16 pour une éventuelle mise en avant est appliquée aux six visuels téléphone ; les captures tablette restent au format natif 10:16.

## Fidélité à l’application

Les captures proviennent de l’application Flutter exécutée sur une Huawei MediaPad M5 lite. Le format téléphone a été obtenu par une définition logique 1080 × 1920, densité 400 ; le format tablette utilise 1200 × 1920, densité 240. Les barres système étaient masquées pour la capture et les réglages d’affichage ont été restaurés ensuite.

Le point d’entrée `source/capture_app.dart` initialise uniquement des livres et profils serveurs fictifs, puis lance le vrai `ComicStreamApp`. Il est compilé dans un projet temporaire avec le paquet distinct `com.sauvank.comicstream.storepreview`. Le code des écrans et du lecteur n’est pas remplacé. Le build de capture porte le numéro 1.1.21 ; les écrans utilisés sont identiques à ceux de 1.1.22, vérifiés contre le code du dépôt après l’incrémentation. Aucun écran de mise à jour ne figure dans les exports.

Les couvertures ORBITE, SYLVE et MINUIT, ainsi que la planche intérieure ORBITE, sont des illustrations originales de démonstration générées avec l’outil imagegen. Elles ne représentent pas un catalogue fourni avec ComicStream. Les tomes de démonstration réutilisent ces illustrations ; aucune BD personnelle ni aucun serveur réel ne figure dans les captures. Les prompts sont conservés dans `source/art-prompts.json`.

L’habillage est produit en HTML/CSS : textes français, couleurs, ombres et disposition autour des captures. L’interface n’est pas redessinée. Les PNG bruts sont conservés dans `captures/`. En format téléphone, Android a renvoyé une surface physique de 1200 pixels avec deux bandes noires de 60 pixels ; le cadrage CSS retire uniquement ces bandes. Les exports tablette sont des conversions JPEG à taille native.

## Textes alternatifs proposés

| Image | Texte alternatif |
| --- | --- |
| Téléphone 01 | Bibliothèque ComicStream avec couvertures de BD, vue par séries, filtres et progression de lecture. |
| Téléphone 02 | Une planche de BD ouverte dans le lecteur ComicStream, avec navigation, marque-page et favoris. |
| Téléphone 03 | Défilement vertical de pages de BD dans le mode Webtoon de ComicStream. |
| Téléphone 04 | Réglages du lecteur : sens de lecture, ajustement de l’image, couleur du fond et maintien de l’écran allumé. |
| Téléphone 05 | Profils de serveurs WebDAV, HTTP et FTP dans ComicStream, avec adresses fictives de démonstration. |
| Téléphone 06 | Filtre Favoris de la bibliothèque ComicStream avec trois BD de démonstration. |
| Tablette 01 | Bibliothèque ComicStream sur tablette avec six tomes, filtres et progression de lecture. |
| Tablette 02 | Lecture d’une planche de BD sur tablette dans ComicStream, avec curseur de navigation et marque-page. |
| Tablette 03 | Panneau des réglages de lecture sur tablette, ouvert au-dessus d’une planche de BD. |
| Tablette 04 | Liste de trois profils serveurs de démonstration WebDAV, HTTP et FTP sur tablette. |
| Bannière | ComicStream : vos BD, partout avec vous. Aperçus de la bibliothèque et du lecteur de bandes dessinées. |

## Régénérer les captures

Depuis la racine du dépôt :

```sh
python3 marketing/play-store/source/prepare.py /tmp/comicstream-store
cd /tmp/comicstream-store
flutter pub get
flutter build apk --release --target lib/store_main.dart --target-platform android-arm64
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Le script de capture utilise `adb` par défaut. Pour un exécutable différent ou plusieurs appareils, placer la configuration locale hors du dépôt, par exemple dans `/tmp/comicstream-capture-config.json` :

```json
{"adb":"adb","port":5037,"serial":"0123456789ABCDEF"}
```

La variable `COMICSTREAM_CAPTURE_CONFIG` permet de choisir un autre fichier. Ne jamais versionner la configuration réelle d’un appareil.

Depuis la racine du dépôt, appeler `capture_device.py setup phone` ou `setup tablet`, redémarrer le paquet de présentation pour appliquer la densité, puis `launch`. Naviguer avec `tap`, `swipe` et `back`. Appeler par exemple `capture phone/01-library`. Fermer toute annonce de mise à jour avant les captures. Après la session, appeler **`python3 marketing/play-store/source/capture_device.py restore`** pour rétablir l’affichage initial. Les coordonnées des gestes dépendent du format choisi.

## Régénérer l’habillage

```sh
cd marketing/play-store/source
npm install
npx playwright install chromium
npm run render
python3 package.py
```

Le rendu charge la police Manrope locale, sous licence SIL OFL (fichier `source/fonts/OFL.txt`). `PLAYWRIGHT_MODULE` et `CHROMIUM_EXECUTABLE` permettent d’utiliser une installation de navigateur existante. Adapter le cadrage CSS si les nouvelles captures n’ont pas les mêmes bandes latérales.

Validation réalisée : analyse Flutter sans erreur, 32 tests réussis, inspection visuelle des onze exports, contrôle des dimensions et de l’absence de transparence. Les images sont prêtes à importer ; leur remplacement dans Play Console reste une opération distincte.
