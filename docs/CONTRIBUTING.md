# 📋 Guide des Bonnes Pratiques Git & Commits — ComicStream

Ce document consigne les règles et conventions de commit obligatoires pour le développement de **ComicStream**.

---

## 🎯 1. Principes Fondamentaux

1. **Commits Atomiques** : Un commit ne doit traiter qu'un seul sujet bien défini (une fonctionnalité, une correction ou une optimisation).
2. **Zéro Secrets / Sécurité Stricte** : Le dépôt étant public, vérifier systématiquement l'absence de tokens, clés privées, mots de passe ou chemins absolus privés avant tout commit.
3. **Validation Pré-commit** : Chaque lot de commits doit être précédé de l'exécution réussie de :
   ```bash
   flutter analyze
   flutter test
   ```

---

## 🏷️ 2. Convention des Messages de Commit (Conventional Commits)

Les messages de commit doivent adopter le format standardisé suivant :

```
<type>(<portée>): <description courte et claire>

[description détaillée optionnelle expliquant le pourquoi]
```

### Types Autorisés :

| Type | Utilisation | Exemple |
| :--- | :--- | :--- |
| **`feat`** | Nouvelle fonctionnalité | `feat(reader): ajout du mode double-page paysage pour tablette` |
| **`fix`** | Correction d'un bug | `fix(download): correction du filtrage des doublons sur le bouton tout télécharger` |
| **`perf`** | Optimisation de performance | `perf(converter): super-échantillonnage calibré à la résolution physique de l'écran` |
| **`docs`** | Documentation | `docs(roadmap): ajout de la feuille de route et du guide d'architecture` |
| **`refactor`** | Refactorisation sans changement de comportement | `refactor(services): découpage du service de gestion des couvertures distantes` |
| **`test`** | Ajout ou mise à jour de tests | `test(format): ajout des tests de tri naturel sur les numéros de tomes` |
| **`style`** | Formatage, lint, nettoyage de code | `style: nettoyage des imports inutilisés et alignement des thèmes` |

---

## 📦 3. Organisation en Lots de Commits

* Découper les développements complexes en étapes logiques successives (par exemple : Service ➔ Provider ➔ Interface UI ➔ Documentation).
* Faire des commits réguliers par étape plutôt qu'un gros commit monolithique en fin de journée.
