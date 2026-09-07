# Vérification du lecteur CBZ sur Huawei MediaPad M5 lite

Essais du 7 septembre 2026, sur une BAH2-W19 sous Android 8.0, avec 3 Go de RAM
et un écran de 1200 × 1920 pixels. Référence du code avant correction : `143fd55`.

## Problèmes constatés

La version 1.1.21 installée affichait temporairement « Tome terminé » lors de la
reprise d'un livre de 68 pages à la page 3, puis la couverture avec le compteur
resté à 3. Deux relevés mémoire du processus ont donné 1 126 654 puis 741 665 Kio
de PSS. Ces valeurs sont des observations ponctuelles, pas des maxima mesurés.

Le lecteur pouvait construire des images sans hauteur pendant leur décodage.
En mode vertical, cela lançait le chargement de nombreuses pages, puis modifiait
leurs positions à mesure de leur apparition. Les contrôleurs de zoom conservés
sur les anciennes pages pouvaient aussi empêcher le défilement au retour.

## Corrections

- Index ZIP conservé et réutilisé entre les extractions ; une seule extraction
  en cours, avec priorité aux pages demandées devant les miniatures et anticipations.
- Demandes simultanées d'une même page regroupées ; publication du fichier cache
  par renommage après écriture complète ; récupération après éviction par Android.
- Image affichée et préchargée avec la même clé de cache ; largeur et hauteur
  décodées bornées à 1800 pixels, en conservant les proportions.
- Hauteurs verticales conservées même après destruction des widgets ; correction
  de la position de défilement quand une hauteur estimée devient connue.
- Zone de préchargement verticale réduite à un demi-écran ; zoom vertical porté
  par la vue entière ; remise à zéro cohérente lors des changements de mode,
  depuis la barre inférieure comme depuis les paramètres.
- À taille normale, le zoom ne capture plus le déplacement d'un seul doigt.
  `panEnabled: false` ne suffisait pas : lorsque le premier déplacement reçu
  dépassait les seuils des deux détecteurs, celui du zoom gagnait avant celui
  du défilement. Le seuil de déplacement du zoom est désactivé à taille normale,
  tout en conservant son seuil indépendant de pincement et les seuils ordinaires
  de la liste verticale. Ils sont rétablis pour déplacer une image zoomée.
- Sauvegarde après 650 ms sans changement de page, avec sauvegarde immédiate à
  la fermeture ou au passage en arrière-plan ; annulation du travail devenu inutile.
- Indicateur conservé pendant le décodage de l'image, après son extraction,
  pour éviter un écran noir lors du premier affichage d'une grande page.

## Essai sur Conquêtes tome 10

Le fichier exact présent sur la tablette fait 743 017 515 octets et contient
68 PNG dans une archive DEFLATE. Les trois premières images mesurent
5975 × 8001 pixels : une seule image RGBA à cette définition représente
191 223 900 octets, soit 182,4 Mio, avant toute autre allocation.

Le même lanceur de mesure a ouvert ce fichier à la page 3. Les relevés PSS
du lecteur corrigé sont les suivants :

| Étape | PSS |
| --- | ---: |
| Pendant le premier chargement | 318,9 Mio |
| Après stabilisation à l'ouverture | 155,2 Mio |
| Après six gestes verticaux vers le bas | 159,3 Mio |
| Après six gestes verticaux vers le haut | 176,1 Mio |
| Après navigation horizontale | 187,9 Mio |

Les captures montrent un parcours vertical de la page 3 à la page 9, puis un
retour jusqu'à la couverture avec le compteur à 1. Le changement vers le mode
horizontal conserve cette page. Le saut direct à la page 50 affiche bien la
page demandée après décodage. Aucun arrêt du processus n'a été constaté pendant
cette séquence.

Un diagnostic complémentaire a isolé le conflit de gestes en mode horizontal.
Avant correction de ce conflit, cinq balayages ADB de 350 ms, espacés de 700 ms,
ne déclenchaient que deux changements de page ; les trois autres étaient captés
par le détecteur de zoom alors que la page était à taille normale. Après correction,
les traces montrent les cinq changements successifs 3 → 4 → 5 → 6 → 7 → 8,
puis cinq gestes inverses donnent 8 → 7 → 6 → 5 → 4 → 3. Les relevés PSS après
l'aller et le retour sont respectivement 149,6 et 184,5 Mio. Le test automatique
avec un premier déplacement important échouait avant correction et passe après.

Pendant le défilement vertical, les P95 de rendu par fenêtre de cinq secondes
allaient de 7,4 à 12,1 ms. Des frames dépassent encore 16,67 ms, notamment lors
de l'ouverture. Le premier décodage de ces gros PNG peut encore demander une
attente ; les relevés ne mesurent pas sa durée ni le pic mémoire maximal.

Les observations de la version installée décrites plus haut concernent ce
même tome, mais l'application complète et le lanceur de mesure n'ont pas les
mêmes écrans et services actifs. Elles ne constituent donc pas une comparaison
contrôlée de pourcentages de gain. La comparaison contrôlée ci-dessous porte
sur le CBZ JPEG de 22 pages.

## Comparaison sur le même fichier

Deux APK ARM64 en mode release, avec Flutter 3.27.4, ont exécuté le même lanceur
temporaire ouvrant un CBZ STORE de 22 JPEG (14 828 584 octets). Le fichier a été
constitué à partir d'images déjà présentes sur la tablette ; il n'est pas inclus
dans le dépôt. Les APK de mesure utilisaient un identifiant d'application séparé.

Séquence : ouverture en mode vertical à la page 3, huit gestes vers le bas, puis
huit vers le haut. Chaque geste ADB allait de y=1650 à y=400, ou inversement,
à x=600, sur 350 ms. La mémoire a été relevée avec `dumpsys meminfo`.

| PSS du processus | Ancien lecteur | Lecteur corrigé |
| --- | ---: | ---: |
| Après ouverture | 324,4 Mio | 106,8 Mio |
| Après les gestes vers le bas | 358,6 Mio | 201,4 Mio |
| Après les gestes vers le haut | 348,9 Mio | 211,7 Mio |

Les captures du lecteur corrigé montrent la page 3 à l'ouverture, la page 13
après la descente, puis la page 3 au retour. L'ancien lecteur ne suivait pas
correctement la même séquence : sa progression et les pages affichées divergeaient.

Une instrumentation temporaire par `addTimingsCallback` a relevé, pendant le
défilement corrigé, des P95 de rendu compris entre 6,9 et 7,9 ms par fenêtre de
cinq secondes, avec trois images actives. Les frames de démarrage sont exclues
de cette plage et comportent des dépassements de 16,67 ms. Ce n'est pas une
garantie de 60 images/s ni une comparaison de FPS : l'ancien lecteur ne réagissait
pas à tous les gestes, et les essais ne constituent pas une campagne statistique.

## Validation automatisée

`flutter analyze --no-pub` sans anomalie, `flutter test --no-pub` avec 32 tests
réussis et compilation APK release.
Les tests couvrent STORE/DEFLATE, tri naturel, concurrence, priorité et annulation,
éviction du cache et réaffichage, stabilité des hauteurs, navigation dans les deux
sens, balayages avec premier déplacement important, reprise, pincement à deux
doigts, déplacement zoomé, dézoom, changements de mode et sauvegarde à la fermeture.

Pour prolonger les mesures : répéter avec d'autres gros CBZ, images panoramiques
et longues sessions. Les mesures ci-dessus portent sur deux fichiers et quelques
séquences, pas sur tous les usages.

## Installation sur la tablette

Les essais utilisent `com.sauvank.comicstream.perftest`, affiché sous le nom
« ComicStream Test ». L'application initiale et sa bibliothèque sont conservées.
La signature de l'APK local diffère de celle de l'application initiale ; Android
refuse donc une mise à jour directe de celle-ci. La copie de test possède son
propre exemplaire de Conquêtes tome 10. Aucun fichier du livre ni donnée privée
de la tablette n'est inclus dans le dépôt.

Après les mesures, le lanceur instrumenté a été remplacé par l'application
complète corrigée dans « ComicStream Test ». Sa bibliothèque reprend bien le
tome à la page 3 ; le lecteur et les services CBZ compilés sont identiques aux
fichiers du dépôt. L'APK standard est également compilé en mode release.
Un dernier aller-retour vertical dans cette application complète donne un
relevé de 195 263 Kio de PSS, soit 190,7 Mio, après stabilisation.
